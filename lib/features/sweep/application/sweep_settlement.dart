import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart' show isTechniqueScrollDefId;
import '../../../data/defs/stage_def.dart';
import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../cultivation/domain/skill_unlock_service.dart';
import '../../cultivation/presentation/stage_skill_drop_hook.dart';
import '../../mainline/application/mainline_progress_service.dart';
import '../../mainline/presentation/stage_entry_flow.dart'
    show applyVictoryResolution;
import '../../mainline/application/mainline_providers.dart';
import '../../tower/application/tower_progress_service.dart';
import '../../tower/domain/tower_floor_def.dart';
import '../../tower/presentation/tower_entry_flow.dart'
    show applyTowerVictoryResolution;
import '../../tutorial/application/tutorial_providers.dart';
import '../domain/sweep_recap.dart';

/// 扫荡结算（复用既有 victory 数据路径，跳过全部 UI 仪式/剧情/弹窗）。
///
/// 设计：扫荡恒为「本周目已首通」的重打 → 走重打掉落规则（主线秘籍不补、
/// 爬塔装备/银两/经验不发只掉残页，守 §5.1 防刷）。这些 gate 由复用的
/// [applyVictoryResolution] / [applyTowerVictoryResolution] 内部维持，本层不另设。

/// 主线一关扫荡结算。失败兜底返回 null（caller 视为该关结算异常）。
Future<SweepBattleOutcome?> settleMainlineSweepVictory({
  required WidgetRef ref,
  required StageDef stage,
  required int cycle,
}) async {
  final outcome = await applyVictoryResolution(ref: ref, stage: stage);
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
    rng: Random(),
  );
  if (skillDrop.fragmentSkillId != null) skillFragments = 1;

  final items = <String, int>{};
  for (final item in outcome.drops.items) {
    // 扫荡恒重打：秘籍重打不补，不计入 recap。
    if (isTechniqueScrollDefId(item.defId)) continue;
    items[item.defId] = (items[item.defId] ?? 0) + item.quantity;
  }
  final advances =
      outcome.advancements.where((e) => e.result.didAdvance).length;
  return SweepBattleOutcome(
    equipmentDrops: outcome.drops.equipments.length,
    itemsByDefId: items,
    expGained: stage.baseExpReward,
    realmAdvances: advances,
    skillFragments: skillFragments,
  );
}

/// 爬塔一层扫荡结算。重打：装备/银两/经验不发（防刷），仅残页 hook 生效。
Future<SweepBattleOutcome?> settleTowerSweepVictory({
  required WidgetRef ref,
  required TowerFloorDef floor,
}) async {
  // recordClear 幂等：重打 floor ≤ highestClearedFloor → isFirstClear=false。
  final svc = TowerProgressService(isar: IsarSetup.instance);
  await svc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
  final clearResult = await svc.recordClear(
    floorIndex: floor.floorIndex,
    now: DateTime.now(),
    elapsedMs: 0,
  );

  // 战斗结算（battleCount/skillUsage in-place；drops 不在此 roll，下方 gate 控）。
  await applyTowerVictoryResolution(
    ref: ref,
    floor: floor,
    isFirstClear: clearResult.isFirstClear,
  );

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
      rng: Random(),
    );
    if (skillDrop.fragmentSkillId != null) skillFragments = 1;
  }

  // 爬塔重打：drops 恒空（§5.1 防刷），exp/升层不计。recap 只反映残页。
  return SweepBattleOutcome(skillFragments: skillFragments);
}
