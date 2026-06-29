import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  test('主线 6 个章末 Boss 均配置二周目阶段覆盖', () {
    const stageIds = [
      'stage_01_05',
      'stage_02_05',
      'stage_03_05',
      'stage_04_05',
      'stage_05_05',
      'stage_06_05',
    ];

    for (final stageId in stageIds) {
      final stage = GameRepository.instance.stageDefs[stageId]!;
      final boss = stage.enemyTeam.singleWhere((e) => e.isBoss);
      expect(
        boss.cycleBossPhases[2],
        isNotNull,
        reason: '$stageId should have cycle 2 boss phase override',
      );
      expect(boss.bossPhasesForCycle(2), same(boss.cycleBossPhases[2]));
      expect(
        boss.bossPhasesForCycle(2)!.length,
        greaterThanOrEqualTo(2),
        reason: '$stageId cycle 2 should alter phase cadence/skill order',
      );
    }
  });

  test('塔 20/25/30 基础 bossPhases 保持第一梯队阈值，高周目走覆盖', () {
    final floor20 = GameRepository.instance
        .getTowerFloor(20)
        .enemyTeam
        .singleWhere((e) => e.id == 'enemy_tower_boss_20');
    final floor25 = GameRepository.instance
        .getTowerFloor(25)
        .enemyTeam
        .singleWhere((e) => e.id == 'enemy_tower_boss_25');
    final floor30 = GameRepository.instance
        .getTowerFloor(30)
        .enemyTeam
        .singleWhere((e) => e.id == 'enemy_tower_boss_30');

    expect(floor20.bossPhases!.map((p) => p.hpThresholdPct), [1.0, 0.65, 0.35]);
    expect(floor25.bossPhases!.map((p) => p.hpThresholdPct), [1.0, 0.70, 0.5]);
    expect(floor30.bossPhases!.map((p) => p.hpThresholdPct), [1.0, 0.90, 0.50]);

    expect(floor20.bossPhasesForCycle(2)!.map((p) => p.hpThresholdPct), [
      1.0,
      0.80,
      0.45,
    ]);
    expect(floor25.bossPhasesForCycle(2)!.map((p) => p.hpThresholdPct), [
      1.0,
      0.82,
      0.42,
    ]);
    expect(floor30.bossPhasesForCycle(2)!.map((p) => p.hpThresholdPct), [
      1.0,
      0.92,
      0.60,
    ]);
  });
}
