import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';

import '../support/test_data.dart';

void main() {
  setUpAll(loadTestGameRepository);

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

  test('主线 6 个章末 Boss 一周目均有背水一击阶段机制', () {
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
        boss.bossPhases,
        isNotNull,
        reason: '$stageId first clear should have visible boss phase cadence',
      );
      expect(
        boss.bossPhases!.map((p) => p.hpThresholdPct),
        [1.0, 0.5],
        reason: '$stageId first clear should use a readable two-phase boss',
      );
      final desperate = boss.bossPhases![1];
      expect(desperate.aiMode.name, 'aggressive');
      expect(desperate.onEnterMechanic?.name, 'chargeCounter');
      expect(desperate.titleKey, 'bossPhase_desperate');
      expect(desperate.unlockSkillIds, isNotEmpty);
    }
  });

  test('塔 14/32/49 基础 bossPhases 保持第一梯队阈值，高周目走覆盖', () {
    // 批 A 塔重排:武林霸主 20→14 / 绝顶剑魔 25→32 / 九霄魔尊 30→49,
    // 相位阈值随 Boss 原样迁移(机制不变,只挪位置)。
    final floor14 = GameRepository.instance
        .getTowerFloor(14)
        .enemyTeam
        .singleWhere((e) => e.id == 'enemy_tower_boss_14');
    final floor32 = GameRepository.instance
        .getTowerFloor(32)
        .enemyTeam
        .singleWhere((e) => e.id == 'enemy_tower_boss_32');
    final floor49 = GameRepository.instance
        .getTowerFloor(49)
        .enemyTeam
        .singleWhere((e) => e.id == 'enemy_tower_boss_49');

    expect(floor14.bossPhases!.map((p) => p.hpThresholdPct), [1.0, 0.65, 0.35]);
    expect(floor32.bossPhases!.map((p) => p.hpThresholdPct), [1.0, 0.80, 0.5]);
    expect(floor49.bossPhases!.map((p) => p.hpThresholdPct), [1.0, 0.90, 0.50]);

    expect(floor14.bossPhasesForCycle(2)!.map((p) => p.hpThresholdPct), [
      1.0,
      0.80,
      0.45,
    ]);
    expect(floor32.bossPhasesForCycle(2)!.map((p) => p.hpThresholdPct), [
      1.0,
      0.82,
      0.42,
    ]);
    expect(floor49.bossPhasesForCycle(2)!.map((p) => p.hpThresholdPct), [
      1.0,
      0.92,
      0.60,
    ]);
  });
}
