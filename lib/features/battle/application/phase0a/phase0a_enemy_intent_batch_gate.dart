import '../../domain/phase0a/phase0a_combat_intent.dart';

/// 敌方 intent 批次筛选闸：位于逐 intent gate 之后、
/// observer/reducer 之前。
///
/// 实现只能返回 [enemyIntents] 中原对象 identity 的稳定、
/// 无重复子序列，不得注入、替换、重复或重排。CombatSession
/// 在 observer/reducer 前独立验证该合同，不依赖 intent 的 `==`。
/// 输入由 session 作防御性不可修改包装。
abstract interface class Phase0aEnemyIntentBatchGate {
  List<Phase0aIntent> gateEnemyIntents({
    required List<Phase0aIntent> enemyIntents,
  });
}
