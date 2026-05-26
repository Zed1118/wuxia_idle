import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/domain/attributes.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/defs/sect_candidate_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../../../shared/utils/rng_provider.dart';
import '../../festival/application/festival_service_providers.dart';
import '../../jianghu/application/jianghu_providers.dart';
import '../../sect/application/sect_member_service.dart';
import '../../sect/domain/sect.dart';
import '../application/encounter_service.dart';
import '../domain/encounter_def.dart';
import '../domain/encounter_event_loader.dart';
import 'encounter_dialog.dart';
import 'sect_recruit_confirm_dialog.dart';

/// 战斗 victory 后的奇遇触发统一 hook(Phase 4 W14-2)。
///
/// stage_entry_flow / tower_entry_flow victory 路径都调一次,共享同一逻辑:
///   1. recordKill:按敌人 school +1
///   2. evaluateTriggers:取主角 fortune,base * (1 + fortune/20) 软概率
///   3. roll 中 → markTriggered + load events 文案 + 弹 dialog
///   4. 玩家选 outcome → applyOutcome + SnackBar 摘要
///
/// 任何异常(Isar 未 ready / 无 character / 空 encounters)静默返回 +
/// debugPrint(W13 教训),不破坏 victory narrative 流。
Future<void> runEncounterHookAfterVictory({
  required BuildContext context,
  required WidgetRef ref,
  required List<TechniqueSchool> defeatedSchools,
}) async {
  final isar = IsarSetup.instanceOrNull;
  if (isar == null) return;
  if (defeatedSchools.isEmpty) return;

  final encounters = GameRepository.instance.allEncounters;
  if (encounters.isEmpty) return;

  final svc = EncounterService(isar: isar);
  // W13 教训:race 防御,ensure getOrCreate
  await svc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
  try {
    await svc.recordKill(
      saveDataId: IsarSetup.currentSlotId,
      defeatedSchools: defeatedSchools,
    );
  } catch (e, st) {
    debugPrint('EncounterService.recordKill 失败:$e\n$st');
    return;
  }

  // 取主角(slot 0,SaveData.activeCharacterIds.first)的 fortune
  final save = await isar.saveDatas.get(0);
  final founderId = save?.activeCharacterIds.isNotEmpty == true
      ? save!.activeCharacterIds.first
      : null;
  if (founderId == null) return;
  final founder = await isar.characters.get(founderId);
  if (founder == null) return;

  EncounterDef? triggered;
  try {
    triggered = await svc.evaluateTriggers(
      saveDataId: IsarSetup.currentSlotId,
      attributes: founder.attributes,
      encounters: encounters,
      rng: ref.read(rngProvider),
      festivalToday: ref.read(todayFestivalProvider),
    );
  } catch (e, st) {
    debugPrint('EncounterService.evaluateTriggers 失败:$e\n$st');
    return;
  }
  if (triggered == null) return;

  // P4.1 1.1 Q6A spec §3 R2 修:sect 类 encounter markTriggered 延后到
  // accept + recruit success 之后(让玩家可重遇 cap 满 / 取消路径)。
  // 非 sect 类沿 W14 原路径立即 mark。
  if (triggered.affectsSectMembership == null) {
    await svc.markTriggered(
      saveDataId: IsarSetup.currentSlotId,
      encounterId: triggered.id,
    );
  }

  if (!context.mounted) return;
  final content = await EncounterEventLoader.load(triggered.id);
  if (!context.mounted) return;
  final outcomeId = await showEncounterDialog(
    context: context,
    def: triggered,
    content: content,
  );
  if (outcomeId == null) return;

  // T24 · P1.2 §3 EncounterIntegration:reputation hook 接 caller。
  // reputationService null(Isar / GameRepository 未 ready)→ 不传 applier,
  // service 端 null guard 跳过 reputation 应用(向后兼容老路径)。
  final reputationService = ref.read(reputationServiceProvider);
  final applied = await svc.applyOutcome(
    saveDataId: IsarSetup.currentSlotId,
    encounter: triggered,
    outcomeId: outcomeId,
    // P1 #42 Phase 2:GameEvent 写入 caller-provided 上下文。
    founderCharacterId: founderId,
    encounterTitle: content.title ?? triggered.id,
    skillNameLookup: (sid) =>
        GameRepository.instance.skillDefs[sid]?.name ?? sid,
    reputationApplier:
        reputationService?.deltaApplierFromRng(ref.read(rngProvider)),
    reputationPlayerId: reputationService == null ? null : 1,
  );
  if (!context.mounted) return;

  // P4.1 1.1 Q6A spec §3:sect 类 encounter 分支处理。
  final asm = triggered.affectsSectMembership;
  if (asm != null) {
    if (outcomeId != 'accept_recruit') {
      // sect 类 decline_meet / skip outcome → markTriggered 立即 + banner
      // (玩家明确选 decline,encounter resolve · 沿 W14 体例)
      await svc.markTriggered(
        saveDataId: IsarSetup.currentSlotId,
        encounterId: triggered.id,
      );
      if (!context.mounted) return;
      showEncounterOutcomeBanner(context: context, applied: applied);
      return;
    }
    // outcomeId == 'accept_recruit' → 走 sect wire(confirm dialog + recruit)
    final candidate = GameRepository.instance.sectCandidates[asm.candidateRef];
    if (candidate == null) {
      // 红线已校 candidateRef 必在 sectCandidates · 此处保险 fallback
      debugPrint('sect candidate not loaded: ${asm.candidateRef}');
      showEncounterOutcomeBanner(context: context, applied: applied);
      return;
    }
    await _handleSectRecruit(
      context: context,
      ref: ref,
      isar: isar,
      svc: svc,
      triggered: triggered,
      asm: asm,
      candidate: candidate,
      founderCharacterId: founderId,
      encounterTitle: content.title ?? triggered.id,
      banner: applied,
    );
    return;
  }

  showEncounterOutcomeBanner(context: context, applied: applied);
}

/// P4.1 1.1 Q6A · encounter accept_recruit outcome 后的 sect 招收处理。
///
/// 流程(spec §3 + §4):
///   1. Sect lazy-init(get(1)==null → put 默认 sect,沿 sect_providers
///      `_defaultSect:45-53` 体例)
///   2. confirm dialog 二次确认(Q4=C · 沿 RecruitmentDialog._onAccept 体例)
///   3. 玩家取消 → fallback applyOutcome · **不 markTriggered**(玩家可重遇)
///   4. 玩家确认 → isar.writeTxn { Character.create + SectMemberService.recruit }
///      - RecruitResult.success → markTriggered + SnackBar 招收成功
///      - RecruitResult.fullCap → 回滚 newChar.delete + fallback applyOutcome +
///        SnackBar cap full · **不 markTriggered**(玩家可重遇)
///      - 其他 fail(unexpected)→ debugPrint + 回滚
Future<void> _handleSectRecruit({
  required BuildContext context,
  required WidgetRef ref,
  required Isar isar,
  required EncounterService svc,
  required EncounterDef triggered,
  required AffectsSectMembership asm,
  required SectCandidateDef candidate,
  required int founderCharacterId,
  required String encounterTitle,
  required dynamic banner, // OutcomeApplied (类型推断)
}) async {
  final repo = GameRepository.instance;

  // 1. Sect lazy-init(spec §3 R3 修)
  var sect = await isar.sects.get(1);
  if (sect == null) {
    final freshSect = Sect()
      ..id = 1
      ..name = '无名宗'
      ..founderId = 1
      ..sectLevel = 1
      ..sectReputation = 50
      ..totalWins = 0
      ..createdAt = DateTime.now()
      ..lastEventAt = null;
    await isar.writeTxn(() => isar.sects.put(freshSect));
    sect = await isar.sects.get(1);
  }
  if (sect == null) {
    // 极端 race · lazy-init 失败 → fallback SnackBar · 不 markTriggered
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(UiStrings.sectEncounterRecruitNoSect(candidate.name))),
    );
    return;
  }
  final playerSectId = sect.id;

  // 2. confirm dialog
  if (!context.mounted) return;
  final confirmed = await showSectRecruitConfirmDialog(context, candidate);

  if (!confirmed) {
    // 玩家取消 → fallback applyOutcome · 不 markTriggered(spec §3 R2 修)
    final fallbackId = asm.fallbackOutcomeId;
    if (fallbackId != null) {
      final reputationService = ref.read(reputationServiceProvider);
      final fallbackApplied = await svc.applyOutcome(
        saveDataId: IsarSetup.currentSlotId,
        encounter: triggered,
        outcomeId: fallbackId,
        founderCharacterId: founderCharacterId,
        encounterTitle: encounterTitle,
        skillNameLookup: (sid) =>
            GameRepository.instance.skillDefs[sid]?.name ?? sid,
        reputationApplier: reputationService
            ?.deltaApplierFromRng(ref.read(rngProvider)),
        reputationPlayerId: reputationService == null ? null : 1,
      );
      if (!context.mounted) return;
      showEncounterOutcomeBanner(context: context, applied: fallbackApplied);
    }
    return;
  }

  // 3. 招收 isar.writeTxn(caller 持锁体例)
  final realmDef =
      repo.getRealm(candidate.defaultRealm, candidate.defaultLayer);
  final now = DateTime.now();
  RecruitResult? result;
  int? newCharId;
  await isar.writeTxn(() async {
    final newChar = Character.create(
      name: candidate.name,
      realmTier: candidate.defaultRealm,
      realmLayer: candidate.defaultLayer,
      attributes: Attributes()
        ..constitution = candidate.attributeProfile.constitution
        ..enlightenment = candidate.attributeProfile.enlightenment
        ..agility = candidate.attributeProfile.agility
        ..fortune = candidate.attributeProfile.fortune,
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.disciple,
      isFounder: false,
      isActive: false,
      createdAt: now,
      school: candidate.school,
      internalForce: realmDef.internalForceMax,
      internalForceMax: realmDef.internalForceMax,
      experienceToNextLayer: realmDef.experienceToNext,
    );
    await isar.characters.put(newChar);
    newCharId = newChar.id;

    final memberSvc = SectMemberService(isar);
    result = await memberSvc.recruit(
      targetCharacterId: newChar.id,
      sectId: playerSectId,
      numbers: repo.numbers,
    );
  });

  // 4. result 处理
  if (result == RecruitResult.success) {
    // 招收成功 → markTriggered 延后(spec §3 R2 修)
    await svc.markTriggered(
      saveDataId: IsarSetup.currentSlotId,
      encounterId: triggered.id,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(UiStrings.sectEncounterRecruitSuccess(candidate.name))),
    );
    return;
  }

  // 失败路径:回滚 newChar(SectMemberService.recruit 失败时未设字段,但 Character
  // 已 put · cap_full 等 case 需删 newChar 避免孤儿 record)
  if (newCharId != null) {
    await isar.writeTxn(() => isar.characters.delete(newCharId!));
  }

  if (result == RecruitResult.fullCap) {
    // cap 满 → fallback applyOutcome(玩家拿 attributeBonus)+ SnackBar · 不 markTriggered
    final fallbackId = asm.fallbackOutcomeId;
    if (fallbackId != null) {
      final reputationService = ref.read(reputationServiceProvider);
      final fallbackApplied = await svc.applyOutcome(
        saveDataId: IsarSetup.currentSlotId,
        encounter: triggered,
        outcomeId: fallbackId,
        founderCharacterId: founderCharacterId,
        encounterTitle: encounterTitle,
        skillNameLookup: (sid) =>
            GameRepository.instance.skillDefs[sid]?.name ?? sid,
        reputationApplier: reputationService
            ?.deltaApplierFromRng(ref.read(rngProvider)),
        reputationPlayerId: reputationService == null ? null : 1,
      );
      if (!context.mounted) return;
      showEncounterOutcomeBanner(context: context, applied: fallbackApplied);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(UiStrings.sectEncounterRecruitCapFull(candidate.name))),
    );
    return;
  }

  // 其他 fail(unexpected · targetNotFound / alreadyInSect / sectNotFound)
  debugPrint('sect recruit unexpected fail: $result');
}
