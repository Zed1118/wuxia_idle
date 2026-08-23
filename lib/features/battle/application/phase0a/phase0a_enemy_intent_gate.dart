import '../../domain/phase0a/phase0a_combat_intent.dart';

/// 敌方 intent 逐拍筛选闸:位于 enemy AI adapter 之后、observer/reducer
/// 之前。默认 null 路径与基线完全一致;显式 gate 先筛选 enemy intents,
/// observer 只观察最终要交给 reducer 的不可修改列表。
///
/// 实现合同:
/// - 不得修改 [enemyIntents] 原列表(只读消费)。
/// - 返回列表必须不可修改(最终交给 observer/reducer 的列表不可变)。
abstract interface class Phase0aEnemyIntentGate {
  List<Phase0aIntent> gateEnemyIntents({
    required List<Phase0aIntent> enemyIntents,
  });
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
  List<Phase0aIntent> gateEnemyIntents({
    required List<Phase0aIntent> enemyIntents,
  }) {
    if (enemyIntents.every(
      (intent) => _canAttackActorIds.contains(intent.actorId),
    )) {
      return List.unmodifiable(List.of(enemyIntents));
    }
    final gated = <Phase0aIntent>[
      for (final intent in enemyIntents)
        if (_canAttackActorIds.contains(intent.actorId))
          intent
        else if (intent is Phase0aMoveIntent)
          intent,
    ];
    return List.unmodifiable(gated);
  }
}
