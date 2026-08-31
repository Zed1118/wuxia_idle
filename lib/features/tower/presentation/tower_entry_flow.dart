import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/experimental/scope.dart';

import 'package:isar_community/isar.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/inventory_item.dart';
import '../../../core/domain/save_data.dart';
import '../../../core/domain/technique.dart';
import '../../../data/narrative_loader.dart';
import '../../../data/isar_provider.dart';
import '../../../shared/audio/audio_assets.dart';
import '../../../shared/audio/sound_manager.dart';
import '../../combat_shared/application/combat_resolution_service.dart'
    show CombatResolutionService;
import '../../combat_shared/application/combat_content_providers.dart';
import '../../combat_shared/application/combat_progression_settlement_service.dart';
import '../../combat_shared/application/post_combat_invalidation.dart';
import '../../../shared/battle_shared/derived_stats.dart';
import '../../../shared/battle_shared/combat_settlement_snapshot.dart';
import '../../../shared/battle_shared/enum_localizations.dart';
import '../../../features/equipment/application/drop_service.dart';
import '../../../features/equipment/application/first_acquisition_tiers.dart';
import '../../equipment/domain/resonance_upgrade_notice.dart';
import '../../cultivation/domain/advancement_entry.dart';
import '../../cultivation/presentation/advancement_summary.dart';
import '../../cultivation/domain/skill_drop_result.dart';
import '../../cultivation/domain/skill_unlock_service.dart';
import '../../cultivation/presentation/skill_treasure_overlay.dart';
import '../../battle_record/application/boss_memory_hook.dart';
import '../../battle_record/domain/boss_memory_key.dart';
import '../../battle_record/domain/boss_memory_source.dart';
import '../../cultivation/presentation/stage_skill_drop_hook.dart';
import '../../encounter/presentation/encounter_hook.dart';
import '../../event/application/game_event_service.dart';
import '../../mainline/domain/mainline_progress.dart';
import '../../combat_shared/domain/combat_stats_summary.dart';
import '../../combat_shared/presentation/hero_camera_overlay.dart'
    show HeroCameraData;
import '../../combat_shared/presentation/victory_ceremony.dart';
import '../../mainline/presentation/stage_victory_dialog.dart'
    show FirstClearBanner, ResonanceUpgradeBanner;
import '../../inventory/presentation/post_battle_healing_panel.dart';
import '../../narrative/presentation/narrative_reader_screen.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../../../shared/widgets/wuxia_ui/plaque_button.dart';
import '../../../shared/utils/math_random.dart';
import '../../../shared/utils/rng_provider.dart';
import '../application/tower_progress_service.dart';
import '../application/tower_providers.dart';
import '../../../data/defs/tower_floor_def.dart';
import '../../weapon_codex/application/equipment_catalog_hook.dart';
import '../../weapon_codex/application/equipment_catalog_service.dart';
import '../../reward/application/durable_reward_claim_service.dart';
import '../../reward/application/reward_claim_plan.dart';
import '../../../shared/battle_shared/reward_claim_key.dart';
import 'phase0a_tower_battle_host.dart';

typedef TowerBattleExit = ({
  bool won,
  bool surrendered,
  CombatSettlementSnapshot? settlement,
});

typedef TowerDefeatFacts = ({
  String participantName,
  int lightInjuryStacksAdded,
  double heavyInjuryHoursAdded,
});

typedef TowerCombatResolution = ({
  List<AdvancementEntry> advancements,
  List<ResonanceUpgradeNotice> resonanceUpgrades,
  CombatStatsSummary stats,
  HeroCameraData? heroCamera,
  String? participantName,
  int lightInjuryStacksAdded,
  double heavyInjuryHoursAdded,
});

typedef TowerVictorySettlement = ({
  TowerClearResult clearResult,
  TowerCombatResolution resolution,
  SkillDropResult skillDrop,
  DropResult drops,
});

/// Phase 3 T43 爬塔进入流程串联。
///
/// 状态机（async 串联）：
///   1. opening（仅 Boss 层且 narrativeOpeningId 非空）→ NarrativeReaderScreen
///   2. battle → push Phase0aBattleScreen → wait onVictory / onDefeat
///   3a. victory → recordClear(isFirstClear) → invalidate provider
///       → T44 接入：isFirstClear true 才发奖
///       → Boss + victoryNarrative → NarrativeReaderScreen
///   3b. defeat → settle exact participant → recordDefeat（unawaited）
///       → pop 回层列表
///
/// [battleRunnerForTest] / [clearRecorderForTest] / [defeatRecorderForTest]
/// 仅供 widget test 注入，生产端勿传（[@visibleForTesting]）。
@Dependencies([towerProgress])
Future<void> runTowerFlow({
  required BuildContext context,
  required WidgetRef ref,
  required TowerFloorDef floor,
  required int participantId,
  @visibleForTesting Future<bool> Function()? battleRunnerForTest,
  @visibleForTesting
  Future<({bool won, bool surrendered})> Function()? battleOutcomeForTest,
  @visibleForTesting
  Future<TowerBattleExit> Function()? phase0aBattleOutcomeForTest,
  @visibleForTesting
  Future<TowerClearResult> Function(int floorIndex, int elapsedMs)?
  clearRecorderForTest,
  @visibleForTesting Future<void> Function()? defeatRecorderForTest,
  @visibleForTesting
  Future<void> Function(TowerDefeatFacts facts)? defeatFactPresenterForTest,
}) async {
  // ── opening（仅 Boss 层）──
  if (floor.isBoss && floor.narrativeOpeningId != null) {
    final opening = await NarrativeLoader.load(floor.narrativeOpeningId!);
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NarrativeReaderScreen(
          content: opening,
          fallbackTitle: UiStrings.towerFloorLabel(floor.floorIndex),
        ),
      ),
    );
  }

  // ── battle ──
  if (!context.mounted) return;
  // P0.2 #40 Phase 2:计时本次战斗耗时(从战斗屏 push 起到 onVictory/Defeat
  // 回调触发,含 push/pop 动画 ≈ 600ms 误差,可接受;不为 test 注入路径计时)
  final stopwatch = Stopwatch()..start();
  final TowerBattleExit battleExit;
  if (battleOutcomeForTest != null) {
    final legacyExit = await battleOutcomeForTest();
    battleExit = (
      won: legacyExit.won,
      surrendered: legacyExit.surrendered,
      settlement: null,
    );
  } else if (battleRunnerForTest != null) {
    battleExit = (
      won: await battleRunnerForTest(),
      surrendered: false,
      settlement: null,
    );
  } else {
    battleExit = await _runTowerBattle(
      context: context,
      floor: floor,
      participantId: participantId,
      phase0aBattleOutcomeForTest: phase0aBattleOutcomeForTest,
    );
  }
  stopwatch.stop();
  final elapsedMs = stopwatch.elapsedMilliseconds;

  // ── surrender ── H3:投降,host 已 pop;跳过 recordDefeat 统计直接返回,不计战绩。
  if (battleExit.surrendered) {
    return;
  }
  final won = battleExit.won;
  final settlement = battleExit.settlement;
  if (settlement != null) {
    if (settlement.playerCharacterId != participantId) {
      throw StateError('Tower settlement participant mismatch');
    }
  }

  // ── defeat ──
  if (!won) {
    // Phase0A Host 已形成终局快照；塔败北与主线共享战斗账本/伤势真相源，
    // 但不发塔经验、掉落或首通事件。必须在记录塔败绩前同步落地，避免实际
    // 参战门人的装备/心法/伤势被旧提前 return 丢弃。
    if (settlement != null) {
      final resolution = await applyTowerCombatResolution(
        ref: ref,
        floor: floor,
        grantsFirstClearExperience: false,
        expectedParticipantId: participantId,
        settlementSnapshot: settlement,
      );
      invalidateAfterCombatSettlement(ref.invalidate);
      final participantName = resolution.participantName;
      if (participantName == null || participantName.trim().isEmpty) {
        throw StateError('Tower defeat report participant is unavailable');
      }
      final facts = (
        participantName: participantName,
        lightInjuryStacksAdded: resolution.lightInjuryStacksAdded,
        heavyInjuryHoursAdded: resolution.heavyInjuryHoursAdded,
      );
      if (defeatFactPresenterForTest != null) {
        await defeatFactPresenterForTest(facts);
      } else {
        if (!context.mounted) return;
        await _showTowerDefeatFacts(context, facts);
      }
    }
    // 不退层，只增统计；unawaited 不阻 UI
    if (defeatRecorderForTest != null) {
      // 审查批E(2026-07-18):test hook 路径原裸吞错误,补与下方生产路径同款日志,
      // 保留「不阻 UI / 不抛出」语义。
      unawaited(
        defeatRecorderForTest().catchError((Object e, StackTrace st) {
          debugPrint('runTowerFlow defeatRecorderForTest failed: $e\n$st');
        }),
      );
    } else {
      // W12 fix: provider 副作用 getOrCreate 与 record* 存在 race（W6 重构遗留），
      // 主动 ensure 避免 recordDefeat 抛 StateError 后被 catchError 静默吞掉
      unawaited(
        () async {
          final svc = TowerProgressService(isar: IsarSetup.instance);
          await svc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
          await svc.recordDefeat(now: DateTime.now());
        }().catchError((Object e, StackTrace st) {
          debugPrint('runTowerFlow recordDefeat failed: $e\n$st');
        }),
      );
    }
    return;
  }

  // ── victory ──
  late TowerClearResult clearResult;
  late TowerCombatResolution victoryRes;
  var skillDrop = SkillDropResult.none;
  var drops = const DropResult(equipments: [], items: []);
  Set<EquipmentTier> extraDisplayTiers = const {};
  if (clearRecorderForTest == null) {
    final atomic = await applyTowerVictorySettlement(
      ref: ref,
      floor: floor,
      participantId: participantId,
      elapsedMs: elapsedMs,
      settlementSnapshot: battleExit.settlement,
    );
    clearResult = atomic.clearResult;
    victoryRes = atomic.resolution;
    skillDrop = atomic.skillDrop;
    drops = atomic.drops;
    final isar = ref.read(isarProvider);
    if (isar != null && drops.equipments.isNotEmpty) {
      extraDisplayTiers = await computeFirstAcquisitionTiers(isar, drops);
    }
  } else {
    try {
      clearResult = await clearRecorderForTest(floor.floorIndex, elapsedMs);
    } catch (e, st) {
      debugPrint('runTowerFlow clearRecorderForTest failed: $e\n$st');
      clearResult = (isFirstClear: false, highestAfter: 0);
    }
    victoryRes = await applyTowerCombatResolution(
      ref: ref,
      floor: floor,
      grantsFirstClearExperience: clearResult.isFirstClear,
      expectedParticipantId: participantId,
      settlementSnapshot: battleExit.settlement,
    );
    if (clearResult.isFirstClear && GameRepository.isLoaded) {
      final towerDropSvc = DropService(
        equipmentDefLookup: GameRepository.instance.getEquipment,
        defaultObtainedFrom: UiStrings.towerDropSource,
      );
      final towerRng = ref.read(rngProvider);
      drops = towerDropSvc.rollTowerRewards(floor, towerRng);
      final towerBonus = towerDropSvc.rollRareBonus(
        baseTier: RealmUtils.equipmentTierCapOf(floor.requiredRealm),
        config: GameRepository.instance.numbers.rareBonusDrop,
        rng: towerRng,
        poolForTier: (tier) => GameRepository.instance.equipmentDefs.values
            .where((equipment) => equipment.tier == tier)
            .toList(growable: false),
        obtainedFrom: UiStrings.dropSourceRareBonus,
      );
      if (towerBonus != null) {
        drops = DropResult(
          equipments: [...drops.equipments, towerBonus],
          items: drops.items,
        );
      }
      await _persistDrops(ref, drops, floor: floor);
    }
  }
  final advancements = victoryRes.advancements;
  final resonanceUpgrades = victoryRes.resonanceUpgrades;
  final heroCamera = victoryRes.heroCamera;
  final participantName = victoryRes.participantName;
  // W13-v3 fix: invalidate character/equipment/technique family,否则下次进
  // 角色面板看到 Riverpod 缓存的旧 battleCount / cultivationProgress
  // + 主菜单隐藏入口门控 / 银两(体检批3 P0-5),统一走共享 helper。
  invalidateAfterCombatSettlement(ref.invalidate);

  // P4 战绩册:爬塔 Boss 层胜利 → 留档(纯数据写;test stub 路径跳过,同 recordClear/skillDrop)。
  // 普通层 bossKind == null,守卫确保只有 Boss 层才记。
  if (clearRecorderForTest == null && floor.bossKind != null) {
    final bossName = floor.enemyTeam.isNotEmpty
        ? floor.enemyTeam.last.name
        : UiStrings.towerFloorLabel(floor.floorIndex);
    await runBossMemoryHookAfterVictory(
      source: BossMemorySource.tower,
      bossKey: towerBossKey(floor.floorIndex),
      groupIndex: floor.floorIndex,
      bossName: bossName,
      stats: victoryRes.stats,
      drops: drops,
      topContributorName: heroCamera?.heroName,
      topContributorDamage: heroCamera?.topDamage,
    );
  }

  // ── leaderboard sync(P0.2 #40 Phase 3,D 方案 Noop placeholder)──
  // 仅 isFirstClear 触发(GDD §5.1 反主流防刷,与 drops 同纪律);
  // 整段 try-catch 兜底(IsarSetup 未 init / progress 读失败时降级,
  // unawaited reportClear 内再 catchError 防 Future 飘错);
  // memory feedback_layered_bugs 警示:留 log 不静默吞 + 下层 bug 不掩盖主流程。
  // 接 Supabase 时只换 leaderboardSyncProvider 注入,本 hook 0 改动。
  if (clearResult.isFirstClear) {
    try {
      final sync = ref.read(leaderboardSyncProvider);
      final svc = TowerProgressService(isar: IsarSetup.instance);
      final progress = await svc.getOrCreate(
        saveDataId: IsarSetup.currentSlotId,
      );
      unawaited(
        sync
            .reportClear(
              highestFloor: progress.highestClearedFloor,
              bestClearTimeMs: progress.bestClearTime,
              totalAttempts: progress.totalAttempts,
              clearedAt: progress.lastClearedAt ?? DateTime.now(),
            )
            .catchError((Object e, StackTrace st) {
              debugPrint(
                'runTowerFlow leaderboardSync reportClear failed: $e\n$st',
              );
            }),
      );
    } catch (e, st) {
      debugPrint('runTowerFlow leaderboardSync setup failed: $e\n$st');
    }
  }

  if (context.mounted) ref.invalidate(towerProgressProvider);

  // ── victory dialog ──
  if (context.mounted) {
    await _showVictoryDialog(
      context: context,
      floor: floor,
      isFirstClear: clearResult.isFirstClear,
      drops: drops,
      advancements: advancements,
      resonanceUpgrades: resonanceUpgrades,
      stats: victoryRes.stats,
      heroCamera: heroCamera,
      participantName: participantName,
      extraDisplayTiers: extraDisplayTiers,
      skillDrop: skillDrop,
    );
  }

  // 胜利仪式 + 结算在战斗界面之上播完,退回塔层列表。
  if (context.mounted && Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  }

  // victory narrative（仅 Boss 层）
  if (floor.isBoss && floor.narrativeVictoryId != null) {
    if (!context.mounted) return;
    final victory = await NarrativeLoader.load(floor.narrativeVictoryId!);
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => NarrativeReaderScreen(
          content: victory,
          fallbackTitle: UiStrings.towerFloorVictoryTitle(floor.floorIndex),
        ),
      ),
    );
  }

  // Phase 4 W14-2:爬塔 victory 也接奇遇 hook(与主线共享 encounter_hook)。
  // 放在 victory narrative 之后,与 stage_entry_flow 体例一致。
  if (!context.mounted) return;
  await runEncounterHookAfterVictory(
    context: context,
    ref: ref,
    defeatedSchools: floor.enemyTeam
        .map((e) => e.school)
        .toList(growable: false),
  );

  // 塔首通掉落、Boss 留档、奇遇 hook 都发生在前面的主结算刷新之后。
  // 离开塔战流程前再刷新一次最终态，避免仓库 / 资源数量 / 战绩册门控缓存旧。
  invalidateAfterCombatSettlement(ref.invalidate);
}

/// 推 Phase 0A 塔战并等待引擎中立结算；系统返回按中途退出处理。
Future<TowerBattleExit> _runTowerBattle({
  required BuildContext context,
  required TowerFloorDef floor,
  required int participantId,
  Future<TowerBattleExit> Function()? phase0aBattleOutcomeForTest,
}) async {
  if (phase0aBattleOutcomeForTest != null) {
    return phase0aBattleOutcomeForTest();
  }
  return _runPhase0aTowerBattle(
    context: context,
    floor: floor,
    participantId: participantId,
  );
}

Future<TowerBattleExit> _runPhase0aTowerBattle({
  required BuildContext context,
  required TowerFloorDef floor,
  required int participantId,
}) async {
  final completer = Completer<TowerBattleExit>();
  Navigator.of(context)
      .push<void>(
        MaterialPageRoute(
          builder: (_) => Phase0aTowerBattleHost(
            floor: floor,
            participantId: participantId,
            onVictory: (settlement) {
              if (!completer.isCompleted) {
                completer.complete((
                  won: true,
                  surrendered: false,
                  settlement: settlement,
                ));
              }
            },
            onDefeat: (settlement) {
              if (!completer.isCompleted) {
                completer.complete((
                  won: false,
                  surrendered: false,
                  settlement: settlement,
                ));
              }
            },
          ),
        ),
      )
      .then((_) {
        if (!completer.isCompleted) {
          completer.complete((won: false, surrendered: true, settlement: null));
        }
      });
  return completer.future;
}

/// U09 九霄塔胜利的单一原子结算边界。
///
/// 塔进度、首通掉落、重打残页、战斗成长与 receipt 共享
/// 同一 write transaction；任一写入失败都整体回滚。
Future<TowerVictorySettlement> applyTowerVictorySettlement({
  required WidgetRef ref,
  required TowerFloorDef floor,
  required int participantId,
  required int elapsedMs,
  CombatSettlementSnapshot? settlementSnapshot,
  String? rewardOccurrenceId,
  @visibleForTesting Future<void> Function()? afterProgressInTxnForTest,
}) async {
  final isar = ref.read(isarProvider);
  if (isar == null) {
    throw StateError('Tower reward settlement storage is unavailable');
  }
  final progressService = TowerProgressService(isar: isar);
  final progress = await progressService.getOrCreate(
    saveDataId: IsarSetup.currentSlotId,
  );
  final maxFloor = GameRepository.instance.towerMaxFloor;
  final isFirstClear =
      floor.floorIndex == progress.highestClearedFloor + 1 &&
      floor.floorIndex >= 1 &&
      floor.floorIndex <= maxFloor;
  final cycle = progress.currentCycleIndex;
  final now = DateTime.now();
  final occurrenceId = rewardOccurrenceId?.trim().isNotEmpty == true
      ? rewardOccurrenceId!.trim()
      : 'tower:$cycle:${floor.floorIndex}:$participantId:'
            '${now.microsecondsSinceEpoch}';

  var drops = const DropResult(equipments: <Equipment>[], items: []);
  if (isFirstClear && GameRepository.isLoaded) {
    final dropService = DropService(
      equipmentDefLookup: GameRepository.instance.getEquipment,
      defaultObtainedFrom: UiStrings.towerDropSource,
    );
    final rng = ref.read(rngProvider);
    drops = dropService.rollTowerRewards(floor, rng);
    final bonus = dropService.rollRareBonus(
      baseTier: RealmUtils.equipmentTierCapOf(floor.requiredRealm),
      config: GameRepository.instance.numbers.rareBonusDrop,
      rng: rng,
      poolForTier: (tier) => GameRepository.instance.equipmentDefs.values
          .where((equipment) => equipment.tier == tier)
          .toList(growable: false),
      obtainedFrom: UiStrings.dropSourceRareBonus,
    );
    if (bonus != null) {
      drops = DropResult(
        equipments: [...drops.equipments, bonus],
        items: drops.items,
      );
    }
  }

  final keys = RewardClaimPlan.forSettlement(
    contentKind: RewardContentKind.tower,
    contentId: 'tower_floor_${floor.floorIndex}_cycle_$cycle',
    saveDataId: IsarSetup.currentSlotId,
    participantId: participantId,
    occurrenceId: occurrenceId,
    includesFirstClear: isFirstClear,
  );
  late TowerClearResult clearResult;
  late TowerCombatResolution resolution;
  var skillDrop = SkillDropResult.none;
  final disposition = await DurableRewardClaimService(isar).claimBatch(
    keys: keys,
    sourceSettlementId: occurrenceId,
    at: now,
    applyInTxn: () async {
      clearResult = await progressService.recordClearInTxn(
        floorIndex: floor.floorIndex,
        now: now,
        elapsedMs: elapsedMs,
        maxFloor: maxFloor,
      );
      if (clearResult.isFirstClear != isFirstClear) {
        throw StateError(
          'Tower first-clear snapshot changed during settlement',
        );
      }
      await afterProgressInTxnForTest?.call();
      resolution = await applyTowerCombatResolution(
        ref: ref,
        floor: floor,
        grantsFirstClearExperience: isFirstClear,
        expectedParticipantId: participantId,
        settlementSnapshot: settlementSnapshot,
        transactionOwned: true,
      );
      if (floor.dropSkillFragmentId != null && GameRepository.isLoaded) {
        skillDrop = await runTowerSkillDropHookAfterVictoryInTxn(
          floor: floor,
          svc: SkillUnlockService(
            isar,
            fragmentThreshold:
                GameRepository.instance.numbers.skillUnlock.fragmentThreshold,
          ),
          towerFragmentDropProb:
              GameRepository.instance.numbers.skillUnlock.towerFragmentDropProb,
          rng: ref.read(mathRandomProvider),
        );
      }
      await _persistTowerDropsInTxn(
        isar: isar,
        drops: drops,
        floor: floor,
        now: now,
      );
      await EquipmentCatalogService(isar: isar).recordAcquisitionsInTxn(
        saveDataId: IsarSetup.currentSlotId,
        defIds: [for (final equipment in drops.equipments) equipment.defId],
        from: UiStrings.weaponCodexSourceTowerFloor(floor.floorIndex),
        now: now,
      );
    },
  );
  if (disposition != RewardClaimDisposition.applied) {
    throw StateError('Tower reward settlement was already applied');
  }
  return (
    clearResult: clearResult,
    resolution: resolution,
    skillDrop: skillDrop,
    drops: drops,
  );
}

/// 九霄塔单人战斗结算（in-place 副作用 + 写回 Isar）。
///
/// 与主线 `_applyVictoryResolution` 体例对齐，但传 `stageDef: null` 让
/// [BattleResolutionService.resolve] 不内部 roll drops（爬塔走 rollTowerRewards
/// + 首通发奖控制，落地在 _persistDrops；此函数只消费真实参战者的
/// battleCount / skillUsage / cultivationEvents 副作用）。
///
/// [grantsFirstClearExperience] 只在首通胜利为 true；重打与败北均不发经验。
///
/// **错误兜底**：Isar 未 ready / 角色为空 / finalState 异常 → 返回空 list，
/// caller dialog 仅显 drop 部分不显升层 banner（不阻塞 victory dialog / narrative）。
///
/// W15 #30 P3 后续 A:返回升层结果 list 供 caller push `_showVictoryDialog`
/// 时显多角色升层 banner。
/// P1.1 候选 3-a:record 加 `resonanceUpgrades` 供 dialog 显共鸣度晋阶 sub-row。
Future<TowerCombatResolution> applyTowerCombatResolution({
  required WidgetRef ref,
  required TowerFloorDef floor,
  required bool grantsFirstClearExperience,
  int? expectedParticipantId,
  CombatSettlementSnapshot? settlementSnapshot,
  @visibleForTesting bool transactionOwned = false,
}) async {
  const empty = (
    advancements: <AdvancementEntry>[],
    resonanceUpgrades: <ResonanceUpgradeNotice>[],
    stats: CombatStatsSummary(totalDamage: 0, critCount: 0, totalTicks: 0),
    heroCamera: null as HeroCameraData?,
    participantName: null as String?,
    lightInjuryStacksAdded: 0,
    heavyInjuryHoursAdded: 0.0,
  );
  final isar = ref.read(isarProvider);
  if (isar == null) return empty;
  if (settlementSnapshot == null) return empty;
  final combatSettlement = settlementSnapshot;
  if (!combatSettlement.isFinished) return empty;
  final stats = CombatStatsSummary.fromSettlement(combatSettlement);

  final resolvedParticipantId =
      expectedParticipantId ?? combatSettlement.playerCharacterId;
  if (combatSettlement.playerCharacterId != resolvedParticipantId) {
    return empty;
  }
  final ids = [resolvedParticipantId];
  final save = await isar.saveDatas.get(0);

  final characters = <Character>[];
  final equipsByCh = <int, List<Equipment>>{};
  final techsByCh = <int, List<Technique>>{};
  for (final cid in ids) {
    final c = await isar.characters.get(cid);
    if (c == null) continue;
    characters.add(c);

    final eqs = <Equipment>[];
    for (final eqId in [
      c.equippedWeaponId,
      c.equippedArmorId,
      c.equippedAccessoryId,
    ]) {
      if (eqId == null) continue;
      final e = await isar.equipments.get(eqId);
      if (e != null) eqs.add(e);
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
  if (characters.isEmpty) return empty;

  final participant = characters.single;
  final lightInjuryStacksBefore = participant.lightInjuryStacks;
  final heavyInjuryHoursBefore = participant.injuryHoursRemaining;

  final numbers = ref.read(numbersConfigProvider);
  final dropSvc = ref.read(dropServiceProvider);

  final battleResult = CombatResolutionService.resolveSnapshot(
    settlement: combatSettlement,
    participatingCharacters: characters,
    equipmentsByCharacter: equipsByCh,
    techniquesByCharacter: techsByCh,
    // 同主线结算:随机源走 rngProvider,保持可注入。
    rng: ref.read(rngProvider),
    progressToNextMap: numbers.cultivationProgressToNext,
    techniqueDefLookup: GameRepository.instance.getTechnique,
    dropService: dropSvc,
    numbersConfig: numbers,
    // stageDef: null —— 爬塔不走 service 内部 roll drops；drops 在外层
    // rollTowerRewards + _persistDrops 单独控制（首通才发奖）
    // 双层伤势：Boss/小 Boss 楼层(bossKind != null,即 5/10/15/20/25/30)算硬仗,
    // 用语义 floor.isBoss 而非 magic %5 防 drift。resolve 内部据此判定伤势 mutate
    // character；经下方 writeTxn putAll(characters) 落库。
    isHardFight: floor.isBoss,
  );

  final progress = await IsarSetup.instance.mainlineProgress
      .filter()
      .saveDataIdEqualTo(IsarSetup.currentSlotId)
      .findFirst();
  final settlement = CombatProgressionSettlementService(
    GameRepository.instance,
  );
  // 爬塔经验只在首通发放，重打保持零经验。
  final advancements = settlement.applyExperience(
    characters: characters,
    experienceReward: grantsFirstClearExperience ? floor.baseExpReward : 0,
    clearedStageIds: progress?.clearedStageIds.toSet() ?? <String>{},
  );

  final founderId = save?.founderCharacterId;
  // P1.1 候选 3-a:writeTxn 内 push notice,函数末 return 给 caller 传 dialog。
  var resonanceUpgrades = const <ResonanceUpgradeNotice>[];
  Future<void> persistInTxn() async {
    await isar.characters.putAll(characters);
    for (final list in techsByCh.values) {
      if (list.isNotEmpty) await isar.techniques.putAll(list);
    }
    for (final list in equipsByCh.values) {
      if (list.isNotEmpty) await isar.equipments.putAll(list);
    }

    resonanceUpgrades = await settlement.recordCommonEvents(
      isar: isar,
      characters: characters,
      equipmentsByCharacter: equipsByCh,
      resonanceUpgradedEquipmentIds: battleResult.resonanceUpgradedEquipmentIds,
      advancements: advancements,
      founderId: founderId,
      bossVictory: floor.isBoss && grantsFirstClearExperience
          ? BossVictoryEventContext(
              stageId: 'tower_floor_${floor.floorIndex}',
              stageName: UiStrings.towerFloorLabel(floor.floorIndex),
              bossName: floor.enemyTeam.isNotEmpty
                  ? floor.enemyTeam.last.name
                  : UiStrings.towerFloorLabel(floor.floorIndex),
              warbornEquipment: founderId == null
                  ? const []
                  : equipsByCh[founderId] ?? const [],
            )
          : null,
    );
  }

  if (transactionOwned) {
    await persistInTxn();
  } else {
    await isar.writeTxn(persistInTxn);
  }

  // 第七阶段 批一:派生英雄镜头数据（本场最高输出玩家）。纯展示，不改数值。
  final bossName = floor.enemyTeam.isNotEmpty
      ? floor.enemyTeam.last.name
      : UiStrings.towerFloorLabel(floor.floorIndex);
  final heroCamera = deriveHeroCameraDataFromDamageTotals(
    damageByCharacterId: combatSettlement.damageByCharacterId,
    characters: characters,
    bossName: bossName,
  );

  return (
    advancements: advancements,
    resonanceUpgrades: resonanceUpgrades,
    stats: stats,
    heroCamera: heroCamera,
    participantName: characters.single.name,
    lightInjuryStacksAdded: math.max(
      0,
      participant.lightInjuryStacks - lightInjuryStacksBefore,
    ),
    heavyInjuryHoursAdded: math.max(
      0.0,
      participant.injuryHoursRemaining - heavyInjuryHoursBefore,
    ),
  );
}

Future<void> _showTowerDefeatFacts(
  BuildContext context,
  TowerDefeatFacts facts,
) async {
  await PaperDialog.show<void>(
    context,
    title: UiStrings.defeatFactTitle,
    showSeal: false,
    barrierDismissible: false,
    body: TowerDefeatFactBody(facts: facts),
    actions: [
      Builder(
        builder: (dialogContext) => TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text(UiStrings.mainlineDefeatLossAcknowledge),
        ),
      ),
    ],
  );
}

class TowerDefeatFactBody extends StatelessWidget {
  const TowerDefeatFactBody({super.key, required this.facts});

  final TowerDefeatFacts facts;

  @override
  Widget build(BuildContext context) {
    final injury = UiStrings.defeatInjuryFacts(
      lightStacks: facts.lightInjuryStacksAdded,
      heavyHours: facts.heavyInjuryHoursAdded,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(UiStrings.stageReportParticipant(facts.participantName)),
        const SizedBox(height: 8),
        Text(injury),
      ],
    );
  }
}

/// Isar 持久化爬塔掉落（W6 nullable propagation：isarProvider 为 null 时短路，测试安全）。
///
/// P1 #42 Phase 2:加 [floor] 入参,内部同事务写入 #3 equipmentObtained GameEvent。
Future<void> _persistDrops(
  WidgetRef ref,
  DropResult drops, {
  TowerFloorDef? floor,
}) async {
  if (drops.isEmpty) return;
  final isar = ref.read(isarProvider);
  if (isar == null) return;
  final now = DateTime.now();
  await isar.writeTxn(
    () => _persistTowerDropsInTxn(
      isar: isar,
      drops: drops,
      floor: floor,
      now: now,
    ),
  );

  // 兵器谱：新掉落装备已落库(上方 writeTxn putAll(drops.equipments) 已 commit),
  // 留册图鉴(best-effort)。
  if (drops.equipments.isNotEmpty && floor != null) {
    await runEquipmentCatalogHookAfterObtain(
      defIds: [for (final e in drops.equipments) e.defId],
      from: UiStrings.weaponCodexSourceTowerFloor(floor.floorIndex),
    );
  }
}

Future<void> _persistTowerDropsInTxn({
  required Isar isar,
  required DropResult drops,
  required TowerFloorDef? floor,
  required DateTime now,
}) async {
  final save = await isar.saveDatas.get(0);
  final founderId = save?.founderCharacterId;
  if (drops.equipments.isNotEmpty) {
    await isar.equipments.putAll(drops.equipments);
  }
  for (final item in drops.items) {
    final existing = await isar.inventoryItems.getByDefId(item.defId);
    if (existing != null) {
      existing.quantity += item.quantity;
      existing.lastObtainedAt = now;
      await isar.inventoryItems.put(existing);
    } else {
      await isar.inventoryItems.put(
        InventoryItem()
          ..defId = item.defId
          ..itemType = ItemType.fromDefId(item.defId)
          ..quantity = item.quantity
          ..firstObtainedAt = now
          ..lastObtainedAt = now,
      );
    }
  }

  if (drops.equipments.isNotEmpty && floor != null) {
    final events = GameEventService(isar);
    final source = UiStrings.towerFloorLabel(floor.floorIndex);
    for (final drop in drops.equipments) {
      final def = GameRepository.instance.getEquipment(drop.defId);
      await events.recordEquipmentObtained(
        characterId: founderId,
        equipmentId: drop.id,
        equipmentDefId: drop.defId,
        equipmentName: def.name,
        source: source,
        equipment: drop,
      );
    }
  }
}

/// 胜利奖励弹窗：首通显示掉落清单，重打显示「重打不发奖」。
///
/// W15 #30 P3 后续 A:加 advancements 参数,首通时在 drop 列后追升层 banner。
/// 第七阶段 批一 Task 6:加 extraDisplayTiers,透传给 presentVictoryCeremony。
Future<void> _showVictoryDialog({
  required BuildContext context,
  required TowerFloorDef floor,
  required bool isFirstClear,
  required DropResult drops,
  required List<AdvancementEntry> advancements,
  List<ResonanceUpgradeNotice> resonanceUpgrades = const [],
  CombatStatsSummary? stats,
  HeroCameraData? heroCamera,
  String? participantName,
  Set<EquipmentTier> extraDisplayTiers = const {},
  SkillDropResult skillDrop = SkillDropResult.none,
}) async {
  // 第七阶段 批一:大Boss 首胜先弹英雄镜头，再走胜利仪式。
  // 用户拍板「爬塔大Boss」= major(10/20/30),小Boss(5/15/25)不弹(高光不滥)。
  if (shouldShowHeroCamera(
    isBoss: floor.bossKind == TowerBossKind.major,
    isFirstClear: isFirstClear,
    data: heroCamera,
  )) {
    await presentHeroCamera(context, heroCamera!);
    if (!context.mounted) return;
  }
  // 第七阶段批二④:技能珍稀重仪式(爬塔仅残页集齐 → isMajor)夹在英雄镜头与装备
  // treasure 之间。非重仪式(isMajor=false)时 presentSkillTreasure no-op。
  if (skillDrop.isMajor && context.mounted) {
    await presentSkillTreasure(context, skillDrop);
    if (!context.mounted) return;
  }
  // 胜利仪式分档:首通有重器→爆品镜头;首次利器→爆品镜头;否则(普通/重打)→简版勝。
  // realmAdvance 在仪式之后、随 dialog 出现时响,避免 fanfare 早响 1.3s。
  await presentVictoryCeremony(
    context,
    drops,
    treasureGate: isFirstClear,
    extraDisplayTiers: extraDisplayTiers,
  );
  if (!context.mounted) return;
  // 结算 jingle:跨 tier 大境界突破响 realmAdvance(首通限定)。
  if (isFirstClear && advancements.any((e) => e.result.crossedTier)) {
    SoundManager.instance.playSfx(SfxId.realmAdvance);
  }
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PaperDialog(
      title: UiStrings.towerFloorLabel(floor.floorIndex),
      body: TowerVictoryContent(
        floor: floor,
        isFirstClear: isFirstClear,
        drops: drops,
        advancements: advancements,
        resonanceUpgrades: resonanceUpgrades,
        stats: stats,
        participantName: participantName,
        skillFragmentLine: skillFragmentLineFor(skillDrop),
      ),
      actions: [
        PlaqueButton(
          label: UiStrings.towerVictoryConfirm,
          primary: true,
          autofocus: true,
          onTap: () => Navigator.of(ctx).pop(),
        ),
      ],
    ),
  );
}

/// 爬塔 victory dialog 内容(公开便于 widget test 直接 pump)。
///
/// 首通 → [_FirstClearContent](掉落清单 + 升层 + 共鸣度 banner);
/// 重打 → 「重打不发奖」一行。两者后均可追:残页轻提示行([skillFragmentLine]
/// 非空时)+ 战斗统计段([stats] 非空时)。
class TowerVictoryContent extends StatelessWidget {
  const TowerVictoryContent({
    super.key,
    required this.floor,
    required this.isFirstClear,
    required this.drops,
    required this.advancements,
    this.resonanceUpgrades = const [],
    this.stats,
    this.participantName,
    this.skillFragmentLine,
  });

  final TowerFloorDef floor;
  final bool isFirstClear;
  final DropResult drops;
  final List<AdvancementEntry> advancements;
  final List<ResonanceUpgradeNotice> resonanceUpgrades;
  final CombatStatsSummary? stats;

  /// Exact participant resolved by the shared tower settlement. This is an
  /// identity report, not the optional highest-output hero camera.
  final String? participantName;

  /// 残页轻提示行(掉残页未集齐 → 小字一行);null=本场未掉残页或已走重仪式。
  final String? skillFragmentLine;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (participantName != null) ...[
          Text(
            UiStrings.stageReportParticipant(participantName!),
            style: const TextStyle(
              color: WuxiaUi.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        isFirstClear
            ? _FirstClearContent(
                floor: floor,
                drops: drops,
                advancements: advancements,
                resonanceUpgrades: resonanceUpgrades,
              )
            : const Text(UiStrings.towerReplayNoReward),
        // 第七阶段批二④:残页轻提示行(首通/重打均可掉残页,故两路都追)。
        if (skillFragmentLine != null) ...[
          const SizedBox(height: 8),
          Text(
            skillFragmentLine!,
            style: const TextStyle(color: WuxiaColors.resultHighlight),
          ),
        ],
        if (stats != null) ...[
          const SizedBox(height: 12),
          Text(
            UiStrings.battleSummary(
              stats!.totalDamage,
              stats!.critCount,
              stats!.totalTicks,
            ),
            style: const TextStyle(
              color: WuxiaUi.ink2,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const PostBattleHealingPanel(),
      ],
    );
  }
}

/// 首通奖励清单（DropResult 非空时列条目，空则显示「无固定奖励」）。
///
/// W15 #30 P3 后续 A:drop 列后追多角色升层 banner([AdvancementSummary])。
class _FirstClearContent extends StatelessWidget {
  const _FirstClearContent({
    required this.floor,
    required this.drops,
    required this.advancements,
    this.resonanceUpgrades = const [],
  });

  final TowerFloorDef floor;
  final DropResult drops;
  final List<AdvancementEntry> advancements;
  final List<ResonanceUpgradeNotice> resonanceUpgrades;

  @override
  Widget build(BuildContext context) {
    final hasCultivationProgress = advancements.any(
      (e) => e.result.experienceGained > 0 || e.result.didAdvance,
    );
    final hasResonance = resonanceUpgrades.isNotEmpty;
    final lines = <String>[
      for (final eq in drops.equipments)
        GameRepository.isLoaded
            ? GameRepository.instance.getEquipment(eq.defId).name
            : eq.defId,
      for (final item in drops.items)
        '${EnumL10n.itemType(ItemType.fromDefId(item.defId))} ×${item.quantity}',
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FirstClearBanner(
          title: UiStrings.towerFirstClearCeremony(
            floor.floorIndex,
            isBoss: floor.isBoss,
          ),
        ),
        const SizedBox(height: 12),
        if (drops.isEmpty)
          const Text(UiStrings.towerFirstClearNoReward)
        else ...[
          const Text(UiStrings.towerFirstClearLabel),
          const SizedBox(height: 4),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('· $line'),
            ),
        ],
        if (hasCultivationProgress) ...[
          const SizedBox(height: 12),
          AdvancementSummary(entries: advancements),
        ],
        if (hasResonance) ...[
          const SizedBox(height: 12),
          ResonanceUpgradeBanner(notices: resonanceUpgrades),
        ],
      ],
    );
  }
}
