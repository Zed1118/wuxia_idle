import '../../domain/phase0a/phase0a_combat_intent.dart';

/// 敌方 AI intents 的只读观测快照:会话在 reducer 之前、按本拍原样
/// 交付防御性不可修改副本;observer 无法替换、过滤或重排 intents。
final class Phase0aEnemyIntentObservation {
  Phase0aEnemyIntentObservation({
    required this.tick,
    required List<Phase0aIntent> enemyIntents,
  }) : enemyIntents = List.unmodifiable(enemyIntents);

  /// 观测发生时 reducer 尚未推进,取的是本拍起始 tick。
  final int tick;
  final List<Phase0aIntent> enemyIntents;
}

/// 敌方 intent 只读观察器合同:[observe] 不返回任何可替换输入的值,
/// 实现方不得持有或回写会话状态。
abstract interface class Phase0aEnemyIntentObserver {
  void observe(Phase0aEnemyIntentObservation observation);
}
