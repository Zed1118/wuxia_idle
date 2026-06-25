import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/defs/stage_def.dart';
import '../../../data/isar_setup.dart';
import '../../../core/application/battle_providers.dart';
import '../../../shared/audio/audio_assets.dart';
import '../../../shared/strings.dart';
import '../../battle/application/stage_battle_setup.dart';
import '../../tower/domain/tower_floor_def.dart';
import '../domain/sweep_recap.dart';
import 'sweep_settlement.dart';

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

/// 主线一关扫荡单位。
class MainlineSweepUnit implements SweepUnit {
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
    final (left, right) = await StageBattleSetup(isar: IsarSetup.instance)
        .buildTeams(stage, cycleIndex: cycle);
    ref.read(battleProvider.notifier).startBattle(left, right);
  }

  @override
  Future<SweepBattleOutcome?> settle(WidgetRef ref) =>
      settleMainlineSweepVictory(ref: ref, stage: stage, cycle: cycle);
}

/// 爬塔一层扫荡单位。
class TowerSweepUnit implements SweepUnit {
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
    final (left, right) = await StageBattleSetup(isar: IsarSetup.instance)
        .buildTeamsForTower(floor, cycleIndex: cycleIndex);
    ref.read(battleProvider.notifier).startBattle(left, right);
  }

  @override
  Future<SweepBattleOutcome?> settle(WidgetRef ref) =>
      settleTowerSweepVictory(ref: ref, floor: floor);
}
