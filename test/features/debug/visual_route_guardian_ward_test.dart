/// battle_guardian_ward VISUAL_ROUTE scenario 接线守卫。
///
/// `scenarioGuardianWard()` 复用**真 floor30 塔队**(towers.yaml),Boss 护法结界
/// 随 EnemyDef 经 buildEnemyTeam 原样接线。验:
/// - 右队 = Boss(九霄魔尊)+ 左使/右使,护罩字段透传正确
/// - frame-0(两护法存活)→ 护罩生效(验收路由起手冻结帧确显「护法结界」pill)
/// - 两护法全灭 → 护罩失效(破界)
/// 纯 scenario 接线守卫,不跑真实战斗结算。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/guardian_ward_presentation.dart';
import 'package:wuxia_idle/features/debug/presentation/battle_test_menu.dart';
import '../../support/test_data.dart';

void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  test('右队 = 真 floor30 塔队(Boss + 双护法),护罩字段透传', () {
    final (left, right) = BattleScenarioData.scenarioGuardianWard();
    expect(right.length, 3, reason: 'floor30 终局塔队 = Boss + 左使 + 右使');
    final boss = right.first;
    expect(boss.isBoss, isTrue);
    expect(boss.enemyDefId, 'enemy_tower_boss_30');
    expect(boss.guardianWardMult, 0.15);
    expect(boss.guardianDefIds, [
      'enemy_tower_30_cultist_a',
      'enemy_tower_30_cultist_b',
    ]);
    expect(right.every((c) => c.isAlive), isTrue, reason: '起手三敌全存活');
    expect(left.length, 3, reason: '宗师 on-level 3v3');
  });

  test('frame-0 两护法存活 → Boss 护罩生效(验收冻结帧显 pill)', () {
    final (left, right) = BattleScenarioData.scenarioGuardianWard();
    final state = BattleState.initial(leftTeam: left, rightTeam: right);
    expect(isGuardianWardActive(right.first, state), isTrue);
  });

  test('两护法全灭 → 护罩失效(破界)', () {
    final (left, right) = BattleScenarioData.scenarioGuardianWard();
    final boss = right.first;
    final broken = [
      boss,
      for (final c in right.skip(1)) c.copyWith(currentHp: 0, isAlive: false),
    ];
    final state = BattleState.initial(leftTeam: left, rightTeam: broken);
    expect(isGuardianWardActive(boss, state), isFalse);
  });

  test('高复用敌人验收路由读取真 13/14/19/22 层队伍', () {
    final cases = [
      (BattleScenarioData.scenarioTowerFloor13, {'assets/enemies/anye.png'}),
      (
        BattleScenarioData.scenarioTowerFloor14,
        {'assets/enemies/jianghu_qianbei.png', 'assets/enemies/shiye.png'},
      ),
      (
        BattleScenarioData.scenarioTowerFloor19,
        {
          'assets/enemies/wulin_bazhu.png',
          'assets/enemies/jianghu_qianbei.png',
        },
      ),
      (
        BattleScenarioData.scenarioTowerFloor22,
        {'assets/enemies/wulin_bazhu.png', 'assets/enemies/fu_zhaizhu.png'},
      ),
    ];

    for (final (factory, expectedPaths) in cases) {
      final (left, right) = factory();
      expect(left.length, 3);
      expect(
        right.map((character) => character.iconPath).toSet(),
        containsAll(expectedPaths),
      );
    }
  });

  test('早期主线过渡覆盖验收路由读取真关卡与低层塔队伍', () {
    final cases = [
      (BattleScenarioData.scenarioStage0102, {'assets/enemies/ruffian_a.png'}),
      (
        BattleScenarioData.scenarioStage0103,
        {'assets/enemies/bandit_head.png'},
      ),
      (BattleScenarioData.scenarioStage0104, {'assets/enemies/qingshan.png'}),
      (BattleScenarioData.scenarioTowerFloor02, {'assets/enemies/thug_b.png'}),
      (BattleScenarioData.scenarioTowerFloor03, {'assets/enemies/thug_c.png'}),
      (
        BattleScenarioData.scenarioTowerFloor08,
        {'assets/enemies/bandit_head.png'},
      ),
      (BattleScenarioData.scenarioStage0401, {'assets/enemies/liukou_a.png'}),
      (BattleScenarioData.scenarioStage0402, {'assets/enemies/guard_a.png'}),
      (BattleScenarioData.scenarioStage0403, {'assets/enemies/shafei_a.png'}),
      (
        BattleScenarioData.scenarioStage0404,
        {'assets/enemies/xiliangboss.png'},
      ),
      (
        BattleScenarioData.scenarioStage0405,
        {'assets/enemies/xiliangbazhu.png'},
      ),
      (
        BattleScenarioData.scenarioStage0501,
        {'assets/enemies/tongguan_shoujiang.png'},
      ),
      (
        BattleScenarioData.scenarioStage0502,
        {'assets/enemies/songshan_daozong_dizi.png'},
      ),
      (
        BattleScenarioData.scenarioStage0503,
        {'assets/enemies/caobang_duozhu.png'},
      ),
      (
        BattleScenarioData.scenarioStage0504,
        {'assets/enemies/zhongzhou_lunjian_xianfeng.png'},
      ),
      (
        BattleScenarioData.scenarioStage0505,
        {'assets/enemies/xiliang_sandizi.png'},
      ),
      (
        BattleScenarioData.scenarioStage0601,
        {'assets/enemies/lunjian_sanchang_xunluo.png'},
      ),
      (
        BattleScenarioData.scenarioStage0602,
        {'assets/enemies/songshan_shouguan.png'},
      ),
      (
        BattleScenarioData.scenarioStage0603,
        {'assets/enemies/huanghe_yuantou_yufu.png'},
      ),
      (
        BattleScenarioData.scenarioStage0604,
        {'assets/enemies/kunlun_waimen_shouguan.png'},
      ),
      (
        BattleScenarioData.scenarioStage0605,
        {'assets/enemies/xiliang_bazhu.png'},
      ),
      (
        BattleScenarioData.scenarioTowerFloor06,
        {'assets/enemies/bandit_b.png'},
      ),
      (
        BattleScenarioData.scenarioTowerFloor07,
        {'assets/enemies/bandit_c.png'},
      ),
      (
        BattleScenarioData.scenarioTowerFloor12,
        {'assets/enemies/jianghu_a.png', 'assets/enemies/jianghu_b.png'},
      ),
    ];

    for (final (factory, expectedPaths) in cases) {
      final (left, right) = factory();
      expect(left.length, 3);
      expect(
        right.map((character) => character.iconPath).toSet(),
        containsAll(expectedPaths),
      );
    }
  });
}
