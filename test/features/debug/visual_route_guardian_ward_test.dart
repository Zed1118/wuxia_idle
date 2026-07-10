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
}
