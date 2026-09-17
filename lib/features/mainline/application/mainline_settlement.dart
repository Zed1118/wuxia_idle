import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

import '../../../core/application/system_clock_provider.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/save_data.dart';
import '../../../core/domain/technique.dart';
import '../../../data/defs/encounter_def.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../data/numbers_config.dart';
import '../../../shared/battle_shared/combat_settlement_snapshot.dart';
import '../../../shared/battle_shared/derived_stats.dart';
import '../../../shared/battle_shared/enum_localizations.dart' show EnumL10n;
import '../../../shared/battle_shared/reward_claim_key.dart';
import '../../../shared/utils/rng.dart';
import '../../activity/application/durable_activity_automation_service.dart';
import '../../activity/domain/durable_activity_combat_run.dart';
import '../../battle_record/application/boss_memory_service.dart';
import '../../battle_record/domain/boss_memory_key.dart';
import '../../battle_record/domain/boss_memory_source.dart';
import '../../combat_shared/application/combat_progression_settlement_service.dart';
import '../../combat_shared/application/combat_resolution_service.dart';
import '../../combat_shared/domain/combat_stats_summary.dart';
import '../../combat_shared/domain/hero_camera_data.dart';
import '../../cultivation/application/stage_skill_drop_hook.dart';
import '../../cultivation/domain/advancement_entry.dart';
import '../../cultivation/domain/skill_drop_result.dart';
import '../../cultivation/domain/skill_unlock_service.dart';
import '../../encounter/application/encounter_service.dart';
import '../../equipment/application/drop_service.dart';
import '../../equipment/application/first_acquisition_tiers.dart';
import '../../equipment/application/milestone_grant_hook.dart';
import '../../equipment/domain/resonance_upgrade_notice.dart';
import '../../event/application/game_event_service.dart';
import '../../expedition/application/expedition_timeline.dart';
import '../../jianghu/application/reputation_service.dart';
import '../../reward/application/durable_reward_claim_service.dart';
import '../../reward/application/reward_claim_plan.dart';
import '../../seclusion/application/offline_passive_service.dart';
import '../../sect/domain/stage_boss_recruit_probability.dart';
import '../../tutorial/application/tutorial_service.dart';
import '../../weapon_codex/application/equipment_catalog_service.dart';
import '../domain/mainline_pending_jianghu_affair.dart';
import '../domain/mainline_progress.dart';
import '../domain/mainline_settlement_journal.dart';
import 'mainline_pending_jianghu_affair_service.dart';
import 'mainline_progress_service.dart';
import 'mainline_settlement_journal_service.dart';

typedef MainlineDurableSettlementContext = ({
  MainlineSettlementJournalService service,
  MainlineSettlementIdentity identity,
});

/// 持久活动结算的显式值依赖包，供无组件的应用层消费者使用。
final class DurableActivityCombatSettlementDependencies {
  const DurableActivityCombatSettlementDependencies({
    required this.numbers,
    required this.dropService,
    required this.rng,
    required this.skillDropRng,
    required this.tutorialService,
    required this.reputationService,
    this.clock = const SystemClock(),
    this.eventRandom,
    this.milestoneRng,
  });

  final NumbersConfig numbers;
  final DropService dropService;
  final Rng rng;
  final math.Random skillDropRng;
  final TutorialService? tutorialService;
  final ReputationService? reputationService;
  final SystemClock clock;
  final math.Random? eventRandom;
  final Rng? milestoneRng;

  MainlineSettlementDependencies asMainlineDependencies({
    Rng Function()? readPendingAffairRng,
    Festival? Function()? readFestivalToday,
  }) => MainlineSettlementDependencies(
    readClock: () => clock,
    readEventRandom: () => eventRandom,
    readMilestoneRng: () => milestoneRng,
    readNumbers: () => numbers,
    readDropService: () => dropService,
    readRng: () => rng,
    readMathRandom: () => skillDropRng,
    readTutorialService: () => tutorialService,
    readReputationService: () => reputationService,
    readPendingAffairRng: readPendingAffairRng,
    readFestivalToday: readFestivalToday ?? () => null,
  );
}

/// 结算依赖保持惰性读取，未通过存储、快照或参与者校验时不触发依赖解析。
final class MainlineSettlementDependencies {
  const MainlineSettlementDependencies({
    required NumbersConfig Function() readNumbers,
    required DropService Function() readDropService,
    required Rng Function() readRng,
    required math.Random Function() readMathRandom,
    SystemClock Function()? readClock,
    math.Random? Function()? readEventRandom,
    Rng? Function()? readMilestoneRng,
    required TutorialService? Function() readTutorialService,
    required ReputationService? Function() readReputationService,
    required Festival? Function() readFestivalToday,
    Rng Function()? readPendingAffairRng,
  }) : _readNumbers = readNumbers,
       _readDropService = readDropService,
       _readRng = readRng,
       _readClock = readClock,
       _readEventRandom = readEventRandom,
       _readMilestoneRng = readMilestoneRng,
       _readMathRandom = readMathRandom,
       _readTutorialService = readTutorialService,
       _readReputationService = readReputationService,
       _readFestivalToday = readFestivalToday,
       _readPendingAffairRng = readPendingAffairRng ?? readRng;

  final NumbersConfig Function() _readNumbers;
  final DropService Function() _readDropService;
  final Rng Function() _readRng;
  final math.Random Function() _readMathRandom;
  final SystemClock Function()? _readClock;
  final math.Random? Function()? _readEventRandom;
  final Rng? Function()? _readMilestoneRng;
  final TutorialService? Function() _readTutorialService;
  final ReputationService? Function() _readReputationService;
  final Festival? Function() _readFestivalToday;
  final Rng Function() _readPendingAffairRng;

  NumbersConfig get numbers => _readNumbers();
  DropService get dropService => _readDropService();
  Rng get rng => _readRng();
  math.Random get mathRandom => _readMathRandom();
  SystemClock get clock => _readClock?.call() ?? const SystemClock();

  /// 事件文案单独注入，默认保持旧随机源，不消耗技能残页的随机序列。
  math.Random? get eventRandom => _readEventRandom?.call();

  /// 里程碑属性使用独立随机源；未注入时保留授予服务原有默认行为。
  Rng? get milestoneRng => _readMilestoneRng?.call();
  TutorialService? get tutorialService => _readTutorialService();
  ReputationService? get reputationService => _readReputationService();
  Festival? get festivalToday => _readFestivalToday();
  Rng get pendingAffairRng => _readPendingAffairRng();
}

typedef MainlineVictorySettlement = ({
  DropResult drops,
  List<AdvancementEntry> advancements,
  List<ResonanceUpgradeNotice> resonanceUpgrades,
  CombatStatsSummary stats,
  HeroCameraData? heroCamera,
  Set<EquipmentTier> extraDisplayTiers,
  List<Character> characters,
  SkillDropResult skillDrop,
});

/// 在主结算事务内决定本关待处理江湖事。
///
/// caller 必须持有 `isar.writeTxn`；返回的 typed refs 由结算
/// journal 与核心结算同事务持久化。顺序与旧生产链一致：
/// 奇遇在前，Boss 招降在后。
@visibleForTesting
Future<List<MainlinePendingJianghuAffairRef>>
planMainlinePendingJianghuAffairsInTxn({
  required Isar isar,
  required MainlineSettlementIdentity identity,
  required StageDef stage,
  required int saveDataId,
  required EncounterService encounterService,
  required List<EncounterDef> encounters,
  required Rng rng,
  Festival? festivalToday,
}) async {
  final refs = <MainlinePendingJianghuAffairRef>[];
  final save = await isar.saveDatas.get(0);
  final founder = await isar.characters.get(identity.participantId);

  if (stage.enemyTeam.isNotEmpty && founder != null && encounters.isNotEmpty) {
    final encounter = await encounterService.evaluateTriggers(
      saveDataId: saveDataId,
      attributes: founder.attributes,
      encounters: encounters,
      rng: rng,
      festivalToday: festivalToday,
    );
    if (encounter != null) {
      final sourceId = 'encounter:${encounter.id}';
      refs.add(
        MainlinePendingJianghuAffairRef.encounterChoice(
          settlementId: identity.canonical,
          encounterId: encounter.id,
          ordinal: refs.length + 1,
          resolutionSeed: _stablePendingAffairSeed(
            '${identity.canonical}|$sourceId',
          ),
        ),
      );
    }
  }

  final bossRecruit = stage.bossRecruit;
  final bossAlreadyTriggered =
      save?.triggeredBossRecruitStageIds.contains(stage.id) ?? false;
  if (stage.isBossStage &&
      bossRecruit != null &&
      save != null &&
      !bossAlreadyTriggered &&
      GameRepository.instance.sectCandidates.containsKey(
        bossRecruit.candidateRef,
      ) &&
      rng.nextDouble() <
          resolveStageBossRecruitProbability(
            config: bossRecruit,
            numbers: GameRepository.instance.numbers,
          )) {
    final sourceId =
        'stage-boss-recruit:${stage.id}:${bossRecruit.candidateRef}';
    refs.add(
      MainlinePendingJianghuAffairRef.stageBossRecruit(
        settlementId: identity.canonical,
        stageId: stage.id,
        candidateRef: bossRecruit.candidateRef,
        ordinal: refs.length + 1,
        resolutionSeed: _stablePendingAffairSeed(
          '${identity.canonical}|$sourceId',
        ),
      ),
    );
  }
  return List.unmodifiable(refs);
}

int _stablePendingAffairSeed(String value) {
  var hash = 0x811c9dc5;
  for (final byte in value.codeUnits) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  final positive = hash & 0x7fffffff;
  return positive == 0 ? 1 : positive;
}

/// 损失摘要条目：供展示层渲染单角色一行。
class DefeatLossEntry {
  final String characterName;
  final int internalForceBefore;
  final int internalForceAfter;
  final String? techniqueName;
  final String? oldLayerLabel;
  final String? newLayerLabel;
  final int layersRolledBack;

  /// 心魔惩罚标记：true 表示角色遭受心魔失败后的内息紊乱，
  /// UI 仅陈述角色名与该状态。
  /// Boss 散功 entry 默认 false。
  final bool residueApplied;

  /// 双层伤势重伤标记（Task 9）：战败后该角色是否获得重伤（injuryHoursRemaining>0）。
  /// 供展示层汇总显示受伤弟子数量。
  final bool injuryApplied;

  /// 只记本次结算相对入场前新增的伤势，避免把既有伤势冒充战败后果。
  final int lightInjuryStacksAdded;
  final double heavyInjuryHoursAdded;

  /// false 表示该行只是参与者/伤势事实，不得渲染散功文案。
  final bool hasDefeatPenalty;

  const DefeatLossEntry({
    required this.characterName,
    required this.internalForceBefore,
    required this.internalForceAfter,
    this.techniqueName,
    this.oldLayerLabel,
    this.newLayerLabel,
    this.layersRolledBack = 0,
    this.residueApplied = false,
    this.injuryApplied = false,
    this.lightInjuryStacksAdded = 0,
    this.heavyInjuryHoursAdded = 0,
    this.hasDefeatPenalty = true,
  });
}

typedef InjuryBeforeSnapshot = ({double heavyHours, int lightStacks});

/// 从 [BattleResolutionResult] 构造损失摘要 entry 列表（纯函数，不访问 Isar）。
///
/// 处理两类惩罚（互斥但共享同一函数以便测试）：
///   1. Boss 散功（[BattleResolutionResult.defeatPenaltyByCharacter]）→
///      显示内力回退 + 层数回退，residueApplied=false。
///   2. 心魔惩罚（[BattleResolutionResult.innerDemonPenaltyByCharacter]）→
///      保留领域结算证据，摘要仅显示角色名与内息紊乱，
///      不声称内力区间或修炼度回退，residueApplied=true。
///   3. 双层伤势重伤（Task 9）：仅普通 Boss entry 投影本次伤势；
///      心魔 entry 不把入场前既有伤势算成本次后果。
@visibleForTesting
List<DefeatLossEntry> buildDefeatLossEntries({
  required List<Character> characters,
  required Map<int, List<Technique>> techsByCh,
  required BattleResolutionResult result,
  Map<int, InjuryBeforeSnapshot> injuryBeforeByCharacterId = const {},
}) {
  final entries = <DefeatLossEntry>[];
  final representedCharacterIds = <int>{};

  ({double heavyHoursAdded, int lightStacksAdded}) injuryDelta(Character ch) {
    final before = injuryBeforeByCharacterId[ch.id];
    if (before == null) {
      return (heavyHoursAdded: 0, lightStacksAdded: 0);
    }
    return (
      heavyHoursAdded: math.max(
        0.0,
        ch.injuryHoursRemaining - before.heavyHours,
      ),
      lightStacksAdded: math.max(0, ch.lightInjuryStacks - before.lightStacks),
    );
  }

  // Boss 散功 entries
  for (final ch in characters) {
    final p = result.defeatPenaltyByCharacter[ch.id];
    if (p == null) continue;
    final injury = injuryDelta(ch);
    final techName = _resolveTechName(ch, techsByCh);
    entries.add(
      DefeatLossEntry(
        characterName: ch.name,
        internalForceBefore: p.internalForceBefore,
        internalForceAfter: p.internalForceAfter,
        techniqueName: techName,
        oldLayerLabel: p.didRollback
            ? EnumL10n.cultivationLayer(p.oldLayer)
            : null,
        newLayerLabel: p.didRollback
            ? EnumL10n.cultivationLayer(p.newLayer)
            : null,
        layersRolledBack: p.layersRolledBack,
        residueApplied: false,
        injuryApplied:
            injury.heavyHoursAdded > 0 || injury.lightStacksAdded > 0,
        heavyInjuryHoursAdded: injury.heavyHoursAdded,
        lightInjuryStacksAdded: injury.lightStacksAdded,
      ),
    );
    representedCharacterIds.add(ch.id);
  }

  // 心魔惩罚 entries（不掉层，仅陈述本次新增的内息紊乱）
  for (final ch in characters) {
    final ip = result.innerDemonPenaltyByCharacter[ch.id];
    if (ip == null) continue;
    final techName = _resolveTechName(ch, techsByCh);
    entries.add(
      DefeatLossEntry(
        characterName: ch.name,
        internalForceBefore: ip.internalForceBefore,
        internalForceAfter: ip.internalForceAfter,
        techniqueName: techName,
        oldLayerLabel: null,
        newLayerLabel: null,
        layersRolledBack: 0,
        residueApplied: true,
        // 心魔失败不会新增伤势。角色入场前已有的伤势不能被误报为
        // 本次失败后果；普通 Boss 的伤势投影仍由上方独立分支处理。
        injuryApplied: false,
      ),
    );
    representedCharacterIds.add(ch.id);
  }

  // 无散功/心魔惩罚的普通败北仍返回一条事实行，用于轻功、
  // 守城与普通主线在放弃重试后显示实际参与者和本次新增伤势。
  if (injuryBeforeByCharacterId.isNotEmpty) {
    for (final ch in characters) {
      if (representedCharacterIds.contains(ch.id)) continue;
      final injury = injuryDelta(ch);
      entries.add(
        DefeatLossEntry(
          characterName: ch.name,
          internalForceBefore: ch.internalForce,
          internalForceAfter: ch.internalForce,
          injuryApplied:
              injury.heavyHoursAdded > 0 || injury.lightStacksAdded > 0,
          heavyInjuryHoursAdded: injury.heavyHoursAdded,
          lightInjuryStacksAdded: injury.lightStacksAdded,
          hasDefeatPenalty: false,
        ),
      );
    }
  }

  return entries;
}

/// 从 [techsByCh] 中解析角色主修心法的 defId 对应名称。
/// 找不到或 GameRepository 未载入时返回 null（安全兜底）。
String? _resolveTechName(Character ch, Map<int, List<Technique>> techsByCh) {
  final mainTechId = ch.mainTechniqueId;
  if (mainTechId == null) return null;
  final techs = techsByCh[ch.id];
  if (techs == null || techs.isEmpty) return null;
  final mainTech = techs.firstWhere(
    (t) => t.id == mainTechId,
    orElse: () => techs.first,
  );
  try {
    return GameRepository.instance.getTechnique(mainTech.defId).name;
  } catch (e, st) {
    debugPrint('resolve main technique name failed: $e\n$st');
    return null;
  }
}

/// Phase 4 W11 #32 销账：主线 victory 路径战斗结算。
///
/// 从 Isar 拉玩家方角色 + 心法 + 装备 → 跑 [BattleResolutionService.resolve]
/// （胜负由 `finalState.result` 派生）→ in-place battleCount/skillUsage/cultivationProgress 累积 +
/// stage.dropTable roll 出装备/物品 → writeTxn putAll + 装备 owner=null 入背包 +
/// items 写/更新 inventoryItems。
///
/// **错误兜底**：Isar 未 ready / 角色为空 / finalState 异常 → 返回 null，
/// caller 跳过 victory dialog（与战败结算一致风格）。
///
/// W15 #30 P3 后续 A:返回 `(drops, advancements)` 供 caller push
/// [showStageVictoryDialog] 显 drop + 升层 banner。
/// P1.1 候选 3-a:record 加 `resonanceUpgrades` 供 dialog 显共鸣度晋阶 sub-row。
List<int> _requireExactSettlementParticipant({
  required int playerCharacterId,
  required int expectedParticipantId,
}) {
  if (playerCharacterId != expectedParticipantId) {
    throw StateError(
      'Combat settlement participant does not match the selected character',
    );
  }
  return [expectedParticipantId];
}

Future<MainlineVictorySettlement?> applyVictoryResolution({
  required MainlineSettlementDependencies dependencies,
  required StageDef stage,
  int cycle = 1,
  CombatSettlementSnapshot? settlementSnapshot,
  MainlineDurableSettlementContext? durableSettlement,
  DurableActivitySettlementContext? durableActivitySettlement,
  int? expectedParticipantId,
  String? rewardOccurrenceId,
  DateTime? settlementAt,
  Future<void> Function()? afterRewardWritesInTxn,
}) async {
  if (durableSettlement != null && durableActivitySettlement != null) {
    throw ArgumentError(
      'Mainline and activity durable settlement contexts are exclusive',
    );
  }
  final isar = IsarSetup.instanceOrNull;
  if (isar == null) {
    if (expectedParticipantId != null) {
      throw StateError('Expected settlement storage is unavailable');
    }
    return null;
  }
  final combatSettlement = settlementSnapshot;
  if (combatSettlement == null || !combatSettlement.isFinished) {
    if (expectedParticipantId != null) {
      throw StateError('Expected participant settlement is incomplete');
    }
    return null;
  }
  final now = settlementAt ?? dependencies.clock.now();
  return ExpeditionTimeline.runAfterCatchUp(
    isar: isar,
    now: now,
    action: () async {
      final stats = CombatStatsSummary.fromSettlement(combatSettlement);

      final participantIds = combatSettlement.participantCharacterIds;
      final save = await isar.saveDatas.get(0);
      final ids = expectedParticipantId == null
          ? (save?.activeCharacterIds ?? const <int>[])
                .where(participantIds.contains)
                .toList(growable: false)
          : _requireExactSettlementParticipant(
              playerCharacterId: combatSettlement.playerCharacterId,
              expectedParticipantId: expectedParticipantId,
            );
      if (ids.isEmpty) return null;
      if (expectedParticipantId == null &&
          (await isar.characters.getAll(
            ids,
          )).every((character) => character == null)) {
        return null;
      }

      final characters = <Character>[];
      final equipsByCh = <int, List<Equipment>>{};
      final techsByCh = <int, List<Technique>>{};
      final numbers = dependencies.numbers;
      final dropSvc = dependencies.dropService;
      final settlementRng = dependencies.rng;

      await MainlineProgressService(
        isar: isar,
      ).getOrCreate(saveDataId: IsarSetup.currentSlotId);
      if (durableSettlement != null || durableActivitySettlement != null) {
        await EncounterService(
          isar: isar,
          attributeGainCap: numbers.adventureAttributeLifetimeCap,
          attributeEffects: numbers.attributeEffects,
        ).getOrCreate(
          saveDataId: IsarSetup.currentSlotId,
          clock: SystemClock.fixed(now),
        );
      }

      // P1 #42 Phase 2:isFirstClear snapshot(writeTxn 之前 read MainlineProgress,
      // 含 stageId 即 repeat,不含即首通 → bossDefeated 防刷)。
      final mainlineProgressSnapshot = await isar.mainlineProgress
          .filter()
          .saveDataIdEqualTo(IsarSetup.currentSlotId)
          .findFirst();
      final settlement = CombatProgressionSettlementService(
        GameRepository.instance,
      );
      final isFirstClearStage =
          !(mainlineProgressSnapshot?.clearedStageIds.contains(stage.id) ??
              false);
      // P1.1 候选 3-a:writeTxn 内 push notice,函数末 return 给 caller 传 dialog。
      var resonanceUpgrades = const <ResonanceUpgradeNotice>[];
      var skillDrop = SkillDropResult.none;

      final bossName = stage.enemyTeam.isNotEmpty
          ? stage.enemyTeam.last.name
          : stage.name;
      final rewardContentKind = switch (stage.stageType) {
        StageType.mainline => RewardContentKind.mainline,
        StageType.tower => RewardContentKind.tower,
        StageType.innerDemon => RewardContentKind.innerDemon,
        StageType.lightFoot => RewardContentKind.lightFoot,
        StageType.massBattle => RewardContentKind.massBattle,
        StageType.pvp => throw StateError(
          'Legacy PVP cannot produce U09 rewards',
        ),
      };
      final occurrenceId = switch ((
        durableSettlement,
        durableActivitySettlement,
      )) {
        (final mainline?, _) => mainline.identity.canonical,
        (_, final activity?) => 'durable-activity:${activity.runId}',
        _ =>
          rewardOccurrenceId?.trim().isNotEmpty == true
              ? rewardOccurrenceId!.trim()
              : 'ephemeral:${stage.id}:${combatSettlement.playerCharacterId}:'
                    '${now.microsecondsSinceEpoch}',
      };
      final rewardClaimPlan = RewardClaimPlan.forSettlement(
        contentKind: rewardContentKind,
        contentId: stage.id,
        saveDataId: IsarSetup.currentSlotId,
        participantId: combatSettlement.playerCharacterId,
        occurrenceId: occurrenceId,
        includesFirstClear: isFirstClearStage,
      );
      final rewardClaims = DurableRewardClaimService(isar);
      final settlementTutorialService = dependencies.tutorialService;
      final math.Random settlementSkillDropRng = dependencies.mathRandom;
      final durableReputation =
          durableSettlement == null && durableActivitySettlement == null
          ? null
          : dependencies.reputationService;
      late BattleResolutionResult result;
      late List<AdvancementEntry> advancements;
      late HeroCameraData? heroCamera;
      late DropResult grantedDrops;
      Future<void> persistResolutionInTxn(bool grantsFirstClear) async {
        await OfflinePassiveService.settleWithinTxn(
          settleIslandBeforeGrowth: true,
          isar: isar,
          now: now,
          updatePresence: true,
        );
        for (final cid in ids) {
          final c = await isar.characters.get(cid);
          if (c == null) {
            if (expectedParticipantId != null) {
              throw StateError(
                'Expected settlement participant disappeared: $cid',
              );
            }
            continue;
          }
          characters.add(c);

          final eqs = <Equipment>[];
          for (final eqId in [
            c.equippedWeaponId,
            c.equippedArmorId,
            c.equippedAccessoryId,
          ]) {
            if (eqId == null) continue;
            final e = await isar.equipments.get(eqId);
            if (e == null || e.ownerCharacterId != c.id) {
              if (expectedParticipantId != null) {
                throw StateError(
                  'Expected settlement participant equipment invalid',
                );
              }
              continue;
            }
            eqs.add(e);
          }
          equipsByCh[c.id] = eqs;

          final ts = await isar.techniques
              .where()
              .filter()
              .ownerCharacterIdEqualTo(c.id)
              .findAll();
          // W13 fix: Isar @embedded list 反序列化为 fixed-length,
          // skillUsageCount.increment 走 add 分支会抛 UnsupportedError。
          // 转 growable copy 让后续 _accumulateSkillUsage 可写。
          for (final t in ts) {
            t.skillUsageCount = List.of(t.skillUsageCount);
          }
          techsByCh[c.id] = ts;
        }
        if (characters.isEmpty) {
          throw StateError('Settlement participants disappeared');
        }

        result = CombatResolutionService.resolveSnapshot(
          settlement: combatSettlement,
          participatingCharacters: characters,
          equipmentsByCharacter: equipsByCh,
          techniquesByCharacter: techsByCh,
          stageDef: stage,
          // 随机源走 rngProvider(不 inline new):稀有彩头 roll 在此链路上,
          // inline 的 DefaultRng 测试 override 不到,会把精确掉落数断言打成随机红。
          rng: settlementRng,
          progressToNextMap: numbers.cultivationProgressToNext,
          techniqueDefLookup: GameRepository.instance.getTechnique,
          dropService: dropSvc,
          numbersConfig: numbers,
          // 双层伤势：Boss/心魔关算硬仗，resolve 内部据此判定伤势 mutate character。
          // 受影响 character 经下方 writeTxn putAll(characters) 自然落库，无需额外 txn。
          isHardFight: stage.isBossStage,
          // 第八阶段 E·稀有彩头:阶池 + realm→装备阶映射注入(本关固定掉落外额外 roll)。
          equipmentPoolByTier: (tier) => GameRepository
              .instance
              .equipmentDefs
              .values
              .where((e) => e.tier == tier)
              .toList(growable: false),
          equipmentTierForRealm: RealmUtils.equipmentTierCapOf,
          // 周目平衡 2026-06-26:二周目起提高稀有彩头概率 + 普通掉落材料加成。
          cycle: cycle,
        );

        final currentProgress = await isar.mainlineProgress
            .filter()
            .saveDataIdEqualTo(IsarSetup.currentSlotId)
            .findFirst();
        final clearedSet =
            currentProgress?.clearedStageIds.toSet() ?? <String>{};
        // 主线重打仍发经验；首通门控只约束掉落与 Boss 事件。
        advancements = settlement.applyExperience(
          characters: characters,
          experienceReward: stage.baseExpReward,
          clearedStageIds: clearedSet,
        );

        final founderId = save?.founderCharacterId;
        final battleEventOwnerId = characters.length == 1
            ? characters.single.id
            : founderId;

        heroCamera = deriveHeroCameraDataFromDamageTotals(
          damageByCharacterId: combatSettlement.damageByCharacterId,
          characters: characters,
          bossName: bossName,
        );

        grantedDrops = DropResult(
          equipments: result.dropResult.equipments,
          items: result.dropResult.items
              .where(
                (item) => !shouldSkipScrollDrop(
                  item.defId,
                  isFirstClear: grantsFirstClear,
                ),
              )
              .toList(growable: false),
        );
        // in-place 副作用（battleCount / skillUsage / 主修 progress + layer + EXP）
        await isar.characters.putAll(characters);
        for (final list in techsByCh.values) {
          if (list.isNotEmpty) await isar.techniques.putAll(list);
        }
        for (final list in equipsByCh.values) {
          if (list.isNotEmpty) await isar.equipments.putAll(list);
        }
        // drops：装备 owner=null 入背包 + items 写/更新 inventoryItems
        if (grantedDrops.equipments.isNotEmpty) {
          await isar.equipments.putAll(grantedDrops.equipments);
        }
        for (final item in grantedDrops.items) {
          final existing = await isar.inventoryItems.getByDefId(item.defId);
          if (existing != null) {
            existing.quantity += item.quantity;
            existing.lastObtainedAt = now;
            await isar.inventoryItems.put(existing);
          } else {
            await isar.inventoryItems.put(
              InventoryItem()
                ..defId = item.defId
                ..itemType = _itemTypeOfMainline(item.defId)
                ..quantity = item.quantity
                ..firstObtainedAt = now
                ..lastObtainedAt = now,
            );
          }
        }

        // 主线专属 equipmentObtained 与公共成长事件在同一事务写入。
        final events = GameEventService(
          isar,
          clock: SystemClock.fixed(now),
          random: dependencies.eventRandom,
        );
        for (final drop in grantedDrops.equipments) {
          final def = GameRepository.instance.getEquipment(drop.defId);
          await events.recordEquipmentObtained(
            characterId: battleEventOwnerId,
            equipmentId: drop.id,
            equipmentDefId: drop.defId,
            equipmentName: def.name,
            source: stage.name,
            equipment: drop,
          );
        }
        resonanceUpgrades = await settlement.recordCommonEvents(
          isar: isar,
          clock: SystemClock.fixed(now),
          random: dependencies.eventRandom,
          characters: characters,
          equipmentsByCharacter: equipsByCh,
          resonanceUpgradedEquipmentIds: result.resonanceUpgradedEquipmentIds,
          advancements: advancements,
          founderId: founderId,
          bossVictory: stage.isBossStage && grantsFirstClear
              ? BossVictoryEventContext(
                  stageId: stage.id,
                  stageName: stage.name,
                  bossName: stage.enemyTeam.isNotEmpty
                      ? stage.enemyTeam.last.name
                      : stage.name,
                  warbornEquipment: founderId == null
                      ? const []
                      : equipsByCh[founderId] ?? const [],
                )
              : null,
        );

        await MainlineProgressService(isar: isar).recordVictoryInTxn(
          saveDataId: IsarSetup.currentSlotId,
          stageId: stage.id,
          now: now,
          tutorialService: settlementTutorialService,
          cycle: cycle,
        );
        skillDrop = await runStageSkillDropHookAfterVictoryInTxn(
          stage: stage,
          svc: SkillUnlockService(
            isar,
            fragmentThreshold: numbers.skillUnlock.fragmentThreshold,
          ),
          clearedStageIds: clearedSet,
          grantsFirstClear: grantsFirstClear,
          towerFragmentDropProb: numbers.skillUnlock.towerFragmentDropProb,
          rng: settlementSkillDropRng,
        );
        await EquipmentCatalogService(isar: isar).recordAcquisitionsInTxn(
          saveDataId: IsarSetup.currentSlotId,
          defIds: [
            for (final equipment in grantedDrops.equipments) equipment.defId,
          ],
          from: stage.name,
          now: now,
        );
        final currentSave = await isar.saveDatas.get(0);
        if (currentSave != null) {
          await grantMilestoneForClearedStageInTxn(
            isar: isar,
            clock: SystemClock.fixed(now),
            rng: dependencies.milestoneRng,
            save: currentSave,
            clearedStageId: stage.id,
          );
        }

        if (durableSettlement == null && durableActivitySettlement == null) {
          await afterRewardWritesInTxn?.call();
          return;
        }

        await EncounterService(
          isar: isar,
          attributeGainCap: numbers.adventureAttributeLifetimeCap,
          attributeEffects: numbers.attributeEffects,
        ).recordKillInTxn(
          saveDataId: IsarSetup.currentSlotId,
          defeatedSchools: stage.enemyTeam
              .map((enemy) => enemy.school)
              .toList(growable: false),
        );

        if (stage.isBossStage) {
          final rosterNames = <String>[];
          final rosterPortraits = <String>[];
          for (final characterId in save?.activeCharacterIds ?? const <int>[]) {
            final character = await isar.characters.get(characterId);
            if (character == null) continue;
            rosterNames.add(character.name);
            rosterPortraits.add(character.portraitPath ?? '');
          }
          String? treasureName;
          EquipmentTier? treasureTier;
          if (grantedDrops.equipments.isNotEmpty) {
            final best = grantedDrops.equipments.reduce(
              (left, right) =>
                  left.tier.index >= right.tier.index ? left : right,
            );
            treasureTier = best.tier;
            treasureName =
                GameRepository.instance.equipmentDefs[best.defId]?.name ??
                best.defId;
          }
          await BossMemoryService(isar: isar).recordBossVictoryInTxn(
            saveDataId: IsarSetup.currentSlotId,
            bossKey: mainlineBossKey(stage.id),
            source: BossMemorySource.mainline,
            groupIndex: mainlineGroupIndex(stage.id),
            bossName: bossName,
            totalDamage: stats.totalDamage,
            critCount: stats.critCount,
            totalTicks: stats.totalTicks,
            topContributorName: heroCamera?.heroName,
            topContributorDamage: heroCamera?.topDamage,
            treasureName: treasureName,
            treasureTier: treasureTier,
            rosterNames: rosterNames,
            rosterPortraits: rosterPortraits,
            now: now,
          );
        }

        final reputation = durableReputation;
        if (stage.isBossStage &&
            stage.factionId != null &&
            reputation != null) {
          final triggers = numbers.jianghu.triggers;
          await reputation.applyDeltaInTxn(
            1,
            stage.factionId!,
            -triggers.stageBossKillDelta,
            now: now,
          );
          for (final rival in GameRepository.instance.rivalFactionIds(
            stage.factionId!,
          )) {
            await reputation.applyDeltaInTxn(
              1,
              rival,
              triggers.stageBossKillRivalDelta,
              now: now,
            );
          }
        }
        await afterRewardWritesInTxn?.call();
      }

      if (durableSettlement == null && durableActivitySettlement == null) {
        final disposition = await rewardClaims.claimSettlement(
          plan: rewardClaimPlan,
          sourceSettlementId: occurrenceId,
          at: now,
          applyInTxn: persistResolutionInTxn,
        );
        if (disposition == RewardClaimDisposition.alreadyApplied) return null;
      } else if (durableSettlement != null) {
        final disposition =
            await MainlinePendingJianghuAffairService(
              durableSettlement.service,
            ).commitCore(
              identity: durableSettlement.identity,
              now: now,
              applyInTxn: () async {
                final rewardDisposition = await rewardClaims
                    .claimSettlementInTxn(
                      plan: rewardClaimPlan,
                      sourceSettlementId: occurrenceId,
                      at: now,
                      applyInTxn: persistResolutionInTxn,
                    );
                if (rewardDisposition != RewardClaimDisposition.applied) {
                  throw StateError(
                    'Mainline reward settlement was already applied',
                  );
                }
                return planMainlinePendingJianghuAffairsInTxn(
                  isar: isar,
                  identity: durableSettlement.identity,
                  stage: stage,
                  saveDataId: IsarSetup.currentSlotId,
                  encounterService: EncounterService(
                    isar: isar,
                    attributeGainCap: numbers.adventureAttributeLifetimeCap,
                    attributeEffects: numbers.attributeEffects,
                  ),
                  encounters: GameRepository.instance.allEncounters,
                  rng: dependencies.pendingAffairRng,
                  festivalToday: dependencies.festivalToday,
                );
              },
            );
        if (disposition != MainlineCoreCommitDisposition.applied) {
          throw StateError('Mainline settlement core was already applied');
        }
      } else {
        final disposition = await durableActivitySettlement!.service
            .commitSettlement(
              runId: durableActivitySettlement.runId,
              outcome: DurableActivityOutcome.victory,
              now: now,
              applyInTxn: () async {
                final rewardDisposition = await rewardClaims
                    .claimSettlementInTxn(
                      plan: rewardClaimPlan,
                      sourceSettlementId: occurrenceId,
                      at: now,
                      applyInTxn: persistResolutionInTxn,
                    );
                if (rewardDisposition != RewardClaimDisposition.applied) {
                  throw StateError(
                    'Activity reward settlement was already applied',
                  );
                }
              },
            );
        if (disposition != DurableActivitySettlementDisposition.applied) {
          throw StateError('Durable activity settlement was already applied');
        }
      }

      // 第七阶段 批一 Task 6:计算利器首次获得的 extraDisplayTiers
      // (须在 putAll 入库后调用,判据:库存总数 ≤ 本次掉落件数)。
      final extraDisplayTiers = await computeFirstAcquisitionTiers(
        isar,
        grantedDrops,
      );

      return (
        drops: grantedDrops,
        advancements: advancements,
        resonanceUpgrades: resonanceUpgrades,
        stats: stats,
        heroCamera: heroCamera,
        extraDisplayTiers: extraDisplayTiers,
        characters: List<Character>.unmodifiable(characters),
        skillDrop: skillDrop,
      );
    },
  );
}

/// 主线 victory drop items 的 ItemType 推断。
/// 委托 [ItemType.fromDefId]，避免双真相源；新增 defId 只需在 fromDefId 维护。
ItemType _itemTypeOfMainline(String defId) => ItemType.fromDefId(defId);

/// 战败：从 Isar 拉玩家方角色 + 心法 + 装备，跑
/// [BattleResolutionService.resolve]（败北由 `finalState.result` 派生），写回 Isar，返回
/// 用于 UI 损失摘要展示的轻量结构。
///
/// 旧流程在 Isar 未 ready / 角色为空 / finalState 异常时返回空 list；轻功
/// exact participant 流程必须 fail closed，避免跳过真实参与者的最终败北账本。
Future<List<DefeatLossEntry>> applyParticipantDefeatResolution({
  required MainlineSettlementDependencies dependencies,
  required StageDef stage,
  CombatSettlementSnapshot? settlementSnapshot,
  int? expectedParticipantId,
  DateTime? settlementAt,
  DurableActivitySettlementContext? durableActivitySettlement,
}) async {
  final isar = IsarSetup.instanceOrNull;
  if (isar == null) {
    if (expectedParticipantId != null) {
      throw StateError('Expected defeat settlement storage is unavailable');
    }
    return const [];
  }
  final combatSettlement = settlementSnapshot;
  if (combatSettlement == null || !combatSettlement.isFinished) {
    if (expectedParticipantId != null) {
      throw StateError('Expected participant defeat settlement is incomplete');
    }
    return const [];
  }

  final now = settlementAt ?? dependencies.clock.now();
  return ExpeditionTimeline.runAfterCatchUp(
    isar: isar,
    now: now,
    action: () async {
      final participantIds = combatSettlement.participantCharacterIds;
      final save = await isar.saveDatas.get(0);
      final ids = expectedParticipantId == null
          ? (save?.activeCharacterIds ?? const <int>[])
                .where(participantIds.contains)
                .toList(growable: false)
          : _requireExactSettlementParticipant(
              playerCharacterId: combatSettlement.playerCharacterId,
              expectedParticipantId: expectedParticipantId,
            );
      if (ids.isEmpty) return const [];

      final characters = <Character>[];
      final equipsByCh = <int, List<Equipment>>{};
      final techsByCh = <int, List<Technique>>{};
      final numbers = dependencies.numbers;
      final dropSvc = dependencies.dropService;
      final settlementRng = dependencies.rng;
      var injuryBeforeByCharacterId = <int, InjuryBeforeSnapshot>{};
      BattleResolutionResult? result;

      // 写回 Isar：受影响的 character + 所有 technique + 所有装备。
      // durable activity 把这些业务写入与 receipt 同事务提交，恢复不重放。
      Future<void> persistDefeatInTxn() async {
        await OfflinePassiveService.settleWithinTxn(
          settleIslandBeforeGrowth: true,
          isar: isar,
          now: now,
          updatePresence: true,
        );
        for (final cid in ids) {
          final c = await isar.characters.get(cid);
          if (c == null) {
            if (expectedParticipantId != null) {
              throw StateError('Expected defeat participant disappeared: $cid');
            }
            continue;
          }
          characters.add(c);

          final eqs = <Equipment>[];
          for (final eqId in [
            c.equippedWeaponId,
            c.equippedArmorId,
            c.equippedAccessoryId,
          ]) {
            if (eqId == null) continue;
            final e = await isar.equipments.get(eqId);
            if (e == null || e.ownerCharacterId != c.id) {
              if (expectedParticipantId != null) {
                throw StateError(
                  'Expected defeat participant equipment invalid',
                );
              }
              continue;
            }
            eqs.add(e);
          }
          equipsByCh[c.id] = eqs;

          final ts = await isar.techniques
              .where()
              .filter()
              .ownerCharacterIdEqualTo(c.id)
              .findAll();
          // W13 fix: Isar @embedded list 反序列化为 fixed-length（同 _applyVictoryResolution）
          for (final t in ts) {
            t.skillUsageCount = List.of(t.skillUsageCount);
          }
          techsByCh[c.id] = ts;
        }
        if (characters.isEmpty) return;

        injuryBeforeByCharacterId = <int, InjuryBeforeSnapshot>{
          for (final character in characters)
            character.id: (
              heavyHours: character.injuryHoursRemaining,
              lightStacks: character.lightInjuryStacks,
            ),
        };

        result = CombatResolutionService.resolveSnapshot(
          settlement: combatSettlement,
          participatingCharacters: characters,
          equipmentsByCharacter: equipsByCh,
          techniquesByCharacter: techsByCh,
          stageDef: stage,
          // 同胜利路径:随机源走 rngProvider,保持可注入(战败结算亦有 rng 消费)。
          rng: settlementRng,
          progressToNextMap: numbers.cultivationProgressToNext,
          techniqueDefLookup: GameRepository.instance.getTechnique,
          dropService: dropSvc,
          numbersConfig: numbers,
          // 双层伤势：Boss/心魔关算硬仗，战败同样可累伤势。
          // 受影响 character 经下方 writeTxn putAll(characters) 自然落库。
          isHardFight: stage.isBossStage,
        );

        await isar.characters.putAll(characters);
        for (final list in techsByCh.values) {
          if (list.isNotEmpty) await isar.techniques.putAll(list);
        }
        for (final list in equipsByCh.values) {
          if (list.isNotEmpty) await isar.equipments.putAll(list);
        }
      }

      if (durableActivitySettlement == null) {
        await isar.writeTxn(persistDefeatInTxn);
      } else {
        final disposition = await durableActivitySettlement.service
            .commitSettlement(
              runId: durableActivitySettlement.runId,
              outcome: DurableActivityOutcome.defeat,
              now: now,
              applyInTxn: persistDefeatInTxn,
            );
        if (disposition != DurableActivitySettlementDisposition.applied) {
          throw StateError('Durable activity defeat was already applied');
        }
      }

      if (result == null) return const [];

      // 构造损失摘要（Boss 散功 + 心魔惩罚）
      return buildDefeatLossEntries(
        characters: characters,
        techsByCh: techsByCh,
        result: result!,
        injuryBeforeByCharacterId: injuryBeforeByCharacterId,
      );
    },
  );
}

/// 秘籍(item_scroll_*)首通必得：重打(非首通)跳过写入，避免重复掉。
/// 银两/装备/经验丹不受此 gate 影响（前缀不匹配，返回 false）。
@visibleForTesting
bool shouldSkipScrollDrop(String defId, {required bool isFirstClear}) =>
    isTechniqueScrollDefId(defId) && !isFirstClear;
