import 'battle_state.dart';

/// 本场最高输出玩家(从 [BattleState.actionLog] 派生,纯函数)。
/// 用于战后英雄镜头出镜角色。仅计玩家方(teamSide==0)。
class TopDamageContributor {
  final int actorId; // == BattleCharacter.characterId == Character.id
  final int totalDamage;

  const TopDamageContributor({
    required this.actorId,
    required this.totalDamage,
  });

  static TopDamageContributor? from(BattleState state) {
    // 收集玩家方 characterId → slotIndex 映射(分队遍历不 spread,
    // 对齐 BattleStatsSummary.from 体例;teamSide==0 守卫天然排除跨队重号敌方)。
    final playerSlot = <int, int>{};
    for (final c in state.leftTeam) {
      if (c.teamSide == 0) playerSlot[c.characterId] = c.slotIndex;
    }
    for (final c in state.rightTeam) {
      if (c.teamSide == 0) playerSlot[c.characterId] = c.slotIndex;
    }
    if (playerSlot.isEmpty) return null;

    // 累计玩家方各 actor 的总伤害。
    final byActor = <int, int>{};
    for (final a in state.actionLog) {
      final r = a.attackResult;
      if (r == null || !playerSlot.containsKey(a.actorId)) continue;
      byActor[a.actorId] = (byActor[a.actorId] ?? 0) + r.finalDamage;
    }
    if (byActor.isEmpty) return null;

    // 选最高输出者；平局取 slotIndex 最小的。
    // bestDmg 初值 -1 作哨兵:finalDamage ≥ 0(含 0 伤闪避),首条必入选。
    int? bestId;
    var bestDmg = -1;
    byActor.forEach((id, dmg) {
      if (bestId == null ||
          dmg > bestDmg ||
          (dmg == bestDmg && playerSlot[id]! < playerSlot[bestId]!)) {
        bestId = id;
        bestDmg = dmg;
      }
    });
    return TopDamageContributor(actorId: bestId!, totalDamage: bestDmg);
  }
}
