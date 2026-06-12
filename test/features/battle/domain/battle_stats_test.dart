import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/battle_stats.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';

AttackResult _atk({required int dmg, bool crit = false}) => AttackResult(
      finalDamage: dmg,
      mainDamage: dmg,
      quakeDamage: 0,
      isCritical: crit,
      isDodged: false,
      schoolCounterMultiplier: 1.0,
      realmDiffAttackerMod: 1.0,
      realmDiffDefenderMod: 1.0,
      cultivationMultiplier: 1.0,
      criticalMultiplier: crit ? 1.5 : 1.0,
      defenseRate: 0.0,
      evasionRate: 0.0,
      appliedEffects: const [],
      formulaBreakdown: '',
    );

void main() {
  test('BattleStatsSummary.from 汇总伤害/暴击/回合,跳过无 attackResult 的行动', () {
    final state = BattleState(
      leftTeam: const [],
      rightTeam: const [],
      tick: 7,
      result: BattleResult.leftWin,
      actionLog: [
        BattleAction(
            tick: 1, actorId: 1, description: '', attackResult: _atk(dmg: 100, crit: true)),
        BattleAction(
            tick: 2, actorId: 1, description: '', attackResult: _atk(dmg: 50)),
        const BattleAction(tick: 3, actorId: 1, description: ''),
      ],
    );

    final stats = BattleStatsSummary.from(state);

    expect(stats.totalDamage, 150);
    expect(stats.critCount, 1);
    expect(stats.totalTicks, 7);
  });

  test('空 actionLog → 全 0', () {
    final state = BattleState.initial(leftTeam: const [], rightTeam: const []);
    final stats = BattleStatsSummary.from(state);
    expect(stats.totalDamage, 0);
    expect(stats.critCount, 0);
    expect(stats.totalTicks, 0);
  });
}
