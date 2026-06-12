import 'battle_state.dart';

/// 战斗统计汇总(总伤害 / 暴击数 / 回合数),从 [BattleState.actionLog] 派生。
///
/// 抽出供 [VictoryOverlay](battle_screen 弹)与结算 dialog(stage/tower flow)
/// 共用,避免两处各算一遍 fold 公式(时序重排 spec 2026-06-12)。
class BattleStatsSummary {
  final int totalDamage;
  final int critCount;
  final int totalTicks;

  const BattleStatsSummary({
    required this.totalDamage,
    required this.critCount,
    required this.totalTicks,
  });

  factory BattleStatsSummary.from(BattleState state) {
    var totalDamage = 0;
    var critCount = 0;
    for (final a in state.actionLog) {
      final r = a.attackResult;
      if (r == null) continue;
      totalDamage += r.finalDamage;
      if (r.isCritical) critCount += 1;
    }
    return BattleStatsSummary(
      totalDamage: totalDamage,
      critCount: critCount,
      totalTicks: state.tick,
    );
  }
}
