import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/stage_def.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_unit.dart';
import 'package:wuxia_idle/features/tower/domain/tower_floor_def.dart';
import 'package:wuxia_idle/shared/audio/audio_assets.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  test('主线扫荡单位透传关卡展示信息并按 Boss 路由 BGM', () {
    final normal = MainlineSweepUnit(stage: _normalStage, cycle: 2);
    final boss = MainlineSweepUnit(stage: _bossStage, cycle: 3);

    expect(normal.label, _normalStage.name);
    expect(normal.battleHint, _normalStage.name);
    expect(normal.sceneBackgroundPath, _normalStage.sceneBackgroundPath);
    expect(normal.bgmTrack, BgmTrack.mainline);
    expect(normal.cycle, 2);

    expect(boss.bgmTrack, BgmTrack.boss);
    expect(boss.cycle, 3);
  });

  test('爬塔扫荡单位使用层号、塔背景和塔 BGM', () {
    final unit = TowerSweepUnit(floor: _floor, cycleIndex: 4);

    expect(unit.label, UiStrings.towerFloorLabel(_floor.floorIndex));
    expect(unit.battleHint, UiStrings.towerFloorLabel(_floor.floorIndex));
    expect(unit.sceneBackgroundPath, _floor.sceneBackgroundPath);
    expect(unit.bgmTrack, BgmTrack.tower);
    expect(unit.cycleIndex, 4);
  });
}

const _normalStage = StageDef(
  id: 'stage_sweep_normal',
  name: 'normal stage',
  stageType: StageType.mainline,
  requiredRealm: RealmTier.xueTu,
  enemyTeam: [],
  isBossStage: false,
  baseExpReward: 0,
  difficultyMultiplier: 1,
  sceneBackgroundPath: 'assets/scenes/test.png',
);

const _bossStage = StageDef(
  id: 'stage_sweep_boss',
  name: 'boss stage',
  stageType: StageType.mainline,
  requiredRealm: RealmTier.xueTu,
  enemyTeam: [],
  isBossStage: true,
  baseExpReward: 0,
  difficultyMultiplier: 1,
);

const _floor = TowerFloorDef(
  floorIndex: 5,
  requiredRealm: RealmTier.xueTu,
  enemyTeam: [],
  sceneBackgroundPath: 'assets/scenes/tower_test.png',
);
