import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/defs/stage_def.dart';
import '../../../data/isar_setup.dart';
import '../../battle/application/battle_providers.dart';
import '../../../shared/audio/audio_assets.dart';
import '../../../shared/strings.dart';
import '../../battle/application/stage_battle_setup.dart';
import '../../../data/defs/tower_floor_def.dart';
import '../domain/sweep_recap.dart';
import 'sweep_settlement.dart';
import '../../../shared/battle_shared/combat_settlement_snapshot.dart';
import '../../../shared/battle_shared/battle_result.dart';
import '../../../shared/utils/math_random.dart';
import 'phase0a_sweep_headless_runner.dart';
import 'phase0a_sweep_gate.dart';

/// 扫荡一个单位（主线一关 / 爬塔一层）。SweepScreen 逐个：
/// [startBattle] 装配并起手战斗（强制 auto 连播）→ 战斗到 terminal →
/// 胜利 [settle] 得 [SweepBattleOutcome]。
abstract class SweepUnit {
  /// 进度展示用短标签（如「第3关 · 风波渡」「第5层」）。
  String get label;

  /// BattleScreen 顶部提示。
  String get battleHint;

  /// 战斗场景背景图（null 走兜底底色）。
  String? get sceneBackgroundPath;

  /// 战斗 BGM 轨。
  BgmTrack get bgmTrack;

  /// 装配队伍并起手战斗（写入 battleProvider）。
  Future<void> startBattle(WidgetRef ref);

  /// 胜利结算，返回战果（null=结算异常）。
  Future<SweepBattleOutcome?> settle(WidgetRef ref);
}

/// 可由 Phase 0A 同核 headless 直结的扫荡单位附加能力。
///
/// 与 [SweepUnit] 分离，保证旧假单位/第三方实现无需为默认关闭的灰度能力改签名。
abstract interface class Phase0aHeadlessSweepUnit {
  /// 本单位是否具备 production Phase 0A headless 映射资格。
  bool get supportsPhase0aHeadless;

  /// 同核 headless 跑至终局；预算耗尽由结果显式标记。
  Future<Phase0aSweepRunResult> runPhase0aHeadless(WidgetRef ref);

  /// 把 headless 终局接回既有重打结算。
  Future<SweepBattleOutcome?> settlePhase0a(
    WidgetRef ref,
    CombatSettlementSnapshot settlement,
  );
}

/// 主线一关扫荡单位。
class MainlineSweepUnit implements SweepUnit, Phase0aHeadlessSweepUnit {
  MainlineSweepUnit({required this.stage, required this.cycle});

  final StageDef stage;
  final int cycle;

  @override
  String get label => stage.name;

  @override
  String get battleHint => stage.name;

  @override
  String? get sceneBackgroundPath => stage.sceneBackgroundPath;

  @override
  BgmTrack get bgmTrack =>
      bgmTrackForStage(stage.stageType, isBoss: stage.isBossStage);

  @override
  Future<void> startBattle(WidgetRef ref) async {
    final (left, right) = await StageBattleSetup(
      isar: IsarSetup.instance,
    ).buildTeams(stage, cycleIndex: cycle);
    ref.read(battleProvider.notifier).startBattle(left, right);
  }

  @override
  Future<SweepBattleOutcome?> settle(WidgetRef ref) =>
      settleMainlineSweepVictory(ref: ref, stage: stage, cycle: cycle);

  @override
  bool get supportsPhase0aHeadless =>
      Phase0aSweepGate.shouldUseMainline(stage, cycle: cycle);

  @override
  Future<Phase0aSweepRunResult> runPhase0aHeadless(WidgetRef ref) =>
      Phase0aSweepHeadlessRunner(
        isar: IsarSetup.instance,
        numbers: ref.read(numbersConfigProvider),
        rng: ref.read(mathRandomProvider),
      ).runMainline(stage: stage, cycleIndex: cycle);

  @override
  Future<SweepBattleOutcome?> settlePhase0a(
    WidgetRef ref,
    CombatSettlementSnapshot settlement,
  ) {
    if (settlement.result != BattleResult.leftWin) return Future.value(null);
    return settleMainlineSweepVictory(
      ref: ref,
      stage: stage,
      cycle: cycle,
      settlementSnapshot: settlement,
    );
  }
}

/// 爬塔一层扫荡单位。
class TowerSweepUnit implements SweepUnit, Phase0aHeadlessSweepUnit {
  TowerSweepUnit({required this.floor, required this.cycleIndex});

  final TowerFloorDef floor;
  final int cycleIndex;

  @override
  String get label => UiStrings.towerFloorLabel(floor.floorIndex);

  @override
  String get battleHint => UiStrings.towerFloorLabel(floor.floorIndex);

  @override
  String? get sceneBackgroundPath => floor.sceneBackgroundPath;

  @override
  BgmTrack get bgmTrack => BgmTrack.tower;

  @override
  Future<void> startBattle(WidgetRef ref) async {
    final (left, right) = await StageBattleSetup(
      isar: IsarSetup.instance,
    ).buildTeamsForTower(floor, cycleIndex: cycleIndex);
    ref.read(battleProvider.notifier).startBattle(left, right);
  }

  @override
  Future<SweepBattleOutcome?> settle(WidgetRef ref) =>
      settleTowerSweepVictory(ref: ref, floor: floor);

  @override
  bool get supportsPhase0aHeadless => Phase0aSweepGate.shouldUseTower(floor);

  @override
  Future<Phase0aSweepRunResult> runPhase0aHeadless(WidgetRef ref) =>
      Phase0aSweepHeadlessRunner(
        isar: IsarSetup.instance,
        numbers: ref.read(numbersConfigProvider),
        rng: ref.read(mathRandomProvider),
      ).runTower(floor: floor, cycleIndex: cycleIndex);

  @override
  Future<SweepBattleOutcome?> settlePhase0a(
    WidgetRef ref,
    CombatSettlementSnapshot settlement,
  ) {
    if (settlement.result != BattleResult.leftWin) return Future.value(null);
    return settleTowerSweepVictory(
      ref: ref,
      floor: floor,
      settlementSnapshot: settlement,
    );
  }
}
