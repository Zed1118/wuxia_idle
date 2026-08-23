import '../../domain/phase0a/phase0a_combat_intent.dart';

/// 敌方 intent 逐拍筛选闸:位于 enemy AI adapter 之后、observer/reducer
/// 之前。默认 null 路径与基线完全一致;显式 gate 先筛选 enemy intents,
/// observer 只观察最终要交给 reducer 的不可修改列表。
///
/// 接口只能对单个原 intent 做 allow/deny；稳定子序列的
/// 构造和不可变化由 CombatSession 唯一负责，因此 gate
/// 无法注入、替换或重排 intent。
abstract interface class Phase0aEnemyIntentGate {
  bool allows(Phase0aIntent enemyIntent);
}

/// 出生宽限 gate:调用方显式传入可攻击 actor id 集合,集合外的 actor
/// 仅允许 [Phase0aMoveIntent](宽限期可移动),普攻、enemy skill 与
/// 未来未显式分类的 enemy intent 均 fail closed。
///
/// 冻结语义(D05 计划):
/// - actor 在集合内:允许其原始 intent。
/// - actor 不在集合内:仅 [Phase0aMoveIntent] 放行,其余全部丢弃。
/// - [canAttackActorIds] 构造时防御性复制,外部后续 mutation 不影响。
/// - 宽限到期由调用方以包含该 actor 的新 gate(或移除 gate)表达:
///   该 actor 恢复全部原始 intent。
final class Phase0aSpawnGraceIntentGate implements Phase0aEnemyIntentGate {
  Phase0aSpawnGraceIntentGate({required Set<String> canAttackActorIds})
    : _canAttackActorIds = Set.unmodifiable(Set.of(canAttackActorIds));

  final Set<String> _canAttackActorIds;

  @override
  bool allows(Phase0aIntent enemyIntent) =>
      _canAttackActorIds.contains(enemyIntent.actorId) ||
      enemyIntent is Phase0aMoveIntent;

  /// 便于纯合同测试的稳定过滤；生产 session 使用 [allows]
  /// 自行构造不可修改子序列。
  List<Phase0aIntent> gateEnemyIntents({
    required List<Phase0aIntent> enemyIntents,
  }) => List.unmodifiable(enemyIntents.where(allows));
}
