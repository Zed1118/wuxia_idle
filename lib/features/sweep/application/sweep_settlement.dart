import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart' show isTechniqueScrollDefId;
import '../../../shared/utils/math_random.dart';
import '../../combat_shared/application/combat_content_providers.dart';
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../combat_shared/application/post_combat_invalidation.dart';
import '../../cultivation/domain/skill_unlock_service.dart';
import '../../cultivation/presentation/stage_skill_drop_hook.dart';
import '../../mainline/application/mainline_progress_service.dart';
import '../../mainline/presentation/stage_entry_flow.dart'
    show applyVictoryResolution;
import '../../mainline/application/mainline_providers.dart';
import '../../tower/application/tower_progress_service.dart';
import '../../../data/defs/tower_floor_def.dart';
import '../../tower/presentation/tower_entry_flow.dart'
    show applyTowerCombatResolution;
import '../../tutorial/application/tutorial_providers.dart';
import '../domain/sweep_recap.dart';
import 'sweep_readiness_providers.dart';
import 'sweep_readiness_service.dart';
import '../../../shared/battle_shared/combat_settlement_snapshot.dart';

/// 扫荡结算（复用既有 victory 数据路径，跳过全部 UI 仪式/剧情/弹窗）。
///
/// 设计：扫荡恒为「本周目已首通」的重打 → 走重打掉落规则（主线秘籍不补、
/// 爬塔装备/银两/经验不发只掉残页，守 §5.1 防刷）。这些 gate 由复用的
/// [applyVictoryResolution] / [applyTowerCombatResolution] 内部维持，本层不另设。

/// 主线一关扫荡结算。失败兜底返回 null（caller 视为该关结算异常）。
Future<SweepBattleOutcome?> settleMainlineSweepVictory({
  required WidgetRef ref,
  required StageDef stage,
  required int cycle,
  CombatSettlementSnapshot? settlementSnapshot,
  int? expectedParticipantId,
}) async {
  _validateExpectedMainlineSettlement(
    settlementSnapshot: settlementSnapshot,
    expectedParticipantId: expectedParticipantId,
  );
  final readinessSpent = await SweepReadinessService(
    isar: IsarSetup.instance,
    config: ref.read(numbersConfigProvider).sweepReadiness,
  ).trySpendMainlineStages(1);
  ref.invalidate(sweepReadinessStatusProvider);
  if (!readinessSpent) {
    return const SweepBattleOutcome(ignoredDrops: 1);
  }

  return _settleMainlineReplayVictory(
    ref: ref,
    stage: stage,
    cycle: cycle,
    settlementSnapshot: settlementSnapshot,
    expectedParticipantId: expectedParticipantId,
  );
}

/// One already-cleared mainline stage replayed through the existing headless
/// kernel. Unlike sweep this does not spend readiness; all repeat reward,
/// progress, injury, and actual-participant settlement semantics stay shared.
Future<SweepBattleOutcome?> settleMainlineHeadlessReplayVictory({
  required WidgetRef ref,
  required StageDef stage,
  required int cycle,
  required CombatSettlementSnapshot settlementSnapshot,
  required int expectedParticipantId,
}) async {
  _validateExpectedMainlineSettlement(
    settlementSnapshot: settlementSnapshot,
    expectedParticipantId: expectedParticipantId,
  );
  return _settleMainlineReplayVictory(
    ref: ref,
    stage: stage,
    cycle: cycle,
    settlementSnapshot: settlementSnapshot,
    expectedParticipantId: expectedParticipantId,
  );
}

void _validateExpectedMainlineSettlement({
  required CombatSettlementSnapshot? settlementSnapshot,
  required int? expectedParticipantId,
}) {
  if (settlementSnapshot == null) return;
  if (expectedParticipantId == null ||
      !settlementSnapshot.isFinished ||
      settlementSnapshot.participantCharacterIds.toSet().length != 1 ||
      !settlementSnapshot.participantCharacterIds.contains(
        expectedParticipantId,
      )) {
    throw StateError(
      'Mainline headless settlement participant does not match the request',
    );
  }
}

Future<SweepBattleOutcome?> _settleMainlineReplayVictory({
  required WidgetRef ref,
  required StageDef stage,
  required int cycle,
  required CombatSettlementSnapshot? settlementSnapshot,
  required int? expectedParticipantId,
}) async {
  // 周目平衡 2026-06-26:扫荡透传 cycle → 二周目起提高稀有彩头概率 + 材料加成。
  final outcome = await applyVictoryResolution(
    ref: ref,
    stage: stage,
    cycle: cycle,
    settlementSnapshot: settlementSnapshot,
    expectedParticipantId: expectedParticipantId,
  );
  if (outcome == null) return null;

  // 进度记录（幂等 cycleKey append）+ 残页 hook（重打可掉，非首通限定）。
  // 战绩册 hook 是首通档案语义，重打不重记 → 跳过。
  var skillFragments = 0;
  final svc = MainlineProgressService(isar: IsarSetup.instance);
  final progress = await svc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
  final clearedBefore = progress.clearedStageIds.toSet();
  await svc.recordVictory(
    stageId: stage.id,
    now: DateTime.now(),
    tutorialService: ref.read(tutorialServiceProvider),
    cycle: cycle,
  );
  ref.invalidate(mainlineProgressProvider);
  // 体检批3 P1-6:扫荡同样改 battleCount / cultivationProgress + 掉落入库,
  // 须同战斗结算路径失效角色 family + 主菜单门控,否则扫荡后面板读旧值。
  invalidateAfterCombatSettlement(ref.invalidate);

  final skillDrop = await runStageSkillDropHookAfterVictory(
    stage: stage,
    svc: SkillUnlockService(
      IsarSetup.instance,
      fragmentThreshold:
          GameRepository.instance.numbers.skillUnlock.fragmentThreshold,
    ),
    clearedStageIds: clearedBefore,
    towerFragmentDropProb:
        GameRepository.instance.numbers.skillUnlock.towerFragmentDropProb,
    rng: ref.read(mathRandomProvider),
  );
  if (skillDrop.fragmentSkillId != null) skillFragments = 1;

  final items = <String, int>{};
  var ignoredDrops = 0;
  for (final item in outcome.drops.items) {
    // 扫荡恒重打：秘籍重打不补，不计入 recap。
    if (isTechniqueScrollDefId(item.defId)) {
      ignoredDrops += 1;
      continue;
    }
    items[item.defId] = (items[item.defId] ?? 0) + item.quantity;
  }
  final advances = outcome.advancements
      .where((e) => e.result.didAdvance)
      .length;
  return SweepBattleOutcome(
    equipmentDrops: outcome.drops.equipments.length,
    itemsByDefId: items,
    expGained: stage.baseExpReward,
    realmAdvances: advances,
    skillFragments: skillFragments,
    ignoredDrops: ignoredDrops,
  );
}

/// 爬塔一层扫荡结算。重打：装备/银两/经验不发（防刷），仅残页 hook 生效。
Future<SweepBattleOutcome?> settleTowerSweepVictory({
  required WidgetRef ref,
  required TowerFloorDef floor,
  CombatSettlementSnapshot? settlementSnapshot,
}) async {
  // recordClear 幂等：重打 floor ≤ highestClearedFloor → isFirstClear=false。
  final svc = TowerProgressService(isar: IsarSetup.instance);
  await svc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
  final clearResult = await svc.recordClear(
    floorIndex: floor.floorIndex,
    now: DateTime.now(),
    elapsedMs: 0,
    maxFloor: GameRepository.instance.towerMaxFloor,
  );

  // 战斗结算（battleCount/skillUsage in-place；drops 不在此 roll，下方 gate 控）。
  await applyTowerCombatResolution(
    ref: ref,
    floor: floor,
    grantsFirstClearExperience: clearResult.isFirstClear,
    settlementSnapshot: settlementSnapshot,
  );
  // 体检批3 P1-6:塔扫荡同样累 battleCount / skillUsage,失效角色 family + 门控。
  invalidateAfterCombatSettlement(ref.invalidate);

  // 残页 hook：重打可掉（非首通限定），守 §5.1 仅此项。
  var skillFragments = 0;
  if (floor.dropSkillFragmentId != null && GameRepository.isLoaded) {
    final skillDrop = await runTowerSkillDropHookAfterVictory(
      floor: floor,
      svc: SkillUnlockService(
        IsarSetup.instance,
        fragmentThreshold:
            GameRepository.instance.numbers.skillUnlock.fragmentThreshold,
      ),
      towerFragmentDropProb:
          GameRepository.instance.numbers.skillUnlock.towerFragmentDropProb,
      rng: ref.read(mathRandomProvider),
    );
    if (skillDrop.fragmentSkillId != null) skillFragments = 1;
  }

  // 爬塔重打：drops 恒空（§5.1 防刷），exp/升层不计。recap 只反映残页。
  return SweepBattleOutcome(skillFragments: skillFragments);
}
