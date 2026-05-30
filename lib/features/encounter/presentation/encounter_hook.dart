import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/save_data.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../shared/strings.dart';
import '../../../shared/utils/rng_provider.dart';
import '../../festival/application/festival_service_providers.dart';
import '../../jianghu/application/jianghu_providers.dart';
import '../../sect/presentation/sect_recruit_handler.dart';
import '../application/encounter_service.dart';
import '../domain/encounter_def.dart';
import '../domain/encounter_event_loader.dart';
import 'encounter_dialog.dart';

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

  final n = GameRepository.instance.numbers;
  final svc = EncounterService(
    isar: isar,
    attributeGainCap: n.adventureAttributeLifetimeCap,
    fortuneSensitivity: n.encounterFortuneSensitivity,
  );
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
  // closure 内 promotion 失效 · 将 `triggered` 存 local final 让闭包安全访问。
  final triggeredDef = triggered;
  final asm = triggeredDef.affectsSectMembership;
  if (asm != null) {
    if (outcomeId != 'accept_recruit') {
      // sect 类 decline_meet / skip outcome → markTriggered 立即 + banner
      // (玩家明确选 decline,encounter resolve · 沿 W14 体例)
      await svc.markTriggered(
        saveDataId: IsarSetup.currentSlotId,
        encounterId: triggeredDef.id,
      );
      if (!context.mounted) return;
      showEncounterOutcomeBanner(context: context, applied: applied);
      return;
    }
    // outcomeId == 'accept_recruit' → 走 sect wire(B2 抽公共 helper)
    final candidate = GameRepository.instance.sectCandidates[asm.candidateRef];
    if (candidate == null) {
      // 红线已校 candidateRef 必在 sectCandidates · 此处保险 fallback
      debugPrint('sect candidate not loaded: ${asm.candidateRef}');
      showEncounterOutcomeBanner(context: context, applied: applied);
      return;
    }
    // P4.1 1.1 Q6B B2 抽:`_handleSectRecruit` → `runSectRecruitFlow` 共用
    // (`lib/features/sect/presentation/sect_recruit_handler.dart`)。Q6A 语义保持:
    // onMarkTriggered = EncounterService.markTriggered;onFallback = 应用 fallback
    // outcome(reputation + banner)· 三 SnackBar 沿 sectEncounterRecruit*。
    await runSectRecruitFlow(
      context: context,
      ref: ref,
      isar: isar,
      candidate: candidate,
      onMarkTriggered: () => svc.markTriggered(
        saveDataId: IsarSetup.currentSlotId,
        encounterId: triggeredDef.id,
      ),
      onFallback: () async {
        final fallbackId = asm.fallbackOutcomeId;
        if (fallbackId == null) return;
        final reputationService = ref.read(reputationServiceProvider);
        final fallbackApplied = await svc.applyOutcome(
          saveDataId: IsarSetup.currentSlotId,
          encounter: triggeredDef,
          outcomeId: fallbackId,
          founderCharacterId: founderId,
          encounterTitle: content.title ?? triggeredDef.id,
          skillNameLookup: (sid) =>
              GameRepository.instance.skillDefs[sid]?.name ?? sid,
          reputationApplier: reputationService
              ?.deltaApplierFromRng(ref.read(rngProvider)),
          reputationPlayerId: reputationService == null ? null : 1,
        );
        if (!context.mounted) return;
        showEncounterOutcomeBanner(context: context, applied: fallbackApplied);
      },
      successSnackBar: UiStrings.sectEncounterRecruitSuccess(candidate.name),
      capFullSnackBar: UiStrings.sectEncounterRecruitCapFull(candidate.name),
      noSectSnackBar: UiStrings.sectEncounterRecruitNoSect(candidate.name),
    );
    return;
  }

  showEncounterOutcomeBanner(context: context, applied: applied);
}
