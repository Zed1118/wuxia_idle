import '../../domain/phase0a/attack_token_director.dart';
import '../../domain/phase0a/phase0a_combat_intent.dart';
import 'phase0a_enemy_intent_observer.dart';

/// 把单个 enemy intent 映射为 token 请求;返回 null = 调用方明确标记
/// 该 intent 非攻击 token 候选。kind/offscreen/highImpact/telegraph/
/// grace 等语义全部由调用方在 mapper 内显式给出,观察器与会话不做推断。
typedef Phase0aAttackTokenRequestMapper =
    AttackTokenRequest? Function(Phase0aIntent intent);

/// P2-G2-D04 observe-only 接缝:用注入的 budgets 与 mapper 把本拍
/// enemy intents 交给 [director] 生成诊断性 allocation,结果只记录在
/// [lastAllocation];绝不改写、过滤、重排或拦截传入的 intents。
final class AttackTokenObserveOnlyObserver
    implements Phase0aEnemyIntentObserver {
  AttackTokenObserveOnlyObserver({
    required this.director,
    required this.budgets,
    required this.requestMapper,
  });

  final AttackTokenDirector director;
  final AttackTokenBudgets budgets;
  final Phase0aAttackTokenRequestMapper requestMapper;

  AttackTokenAllocation? _lastAllocation;

  /// 最近一拍诊断分配;尚未观测过为 null。
  AttackTokenAllocation? get lastAllocation => _lastAllocation;

  @override
  void observe(Phase0aEnemyIntentObservation observation) {
    final requests = <AttackTokenRequest>[];
    for (final intent in observation.enemyIntents) {
      final request = requestMapper(intent);
      if (request == null) continue;
      if (request.actorId != intent.actorId) {
        throw ArgumentError(
          'request actorId "${request.actorId}" must equal intent actorId '
          '"${intent.actorId}" (observe-only fail closed before reducer)',
        );
      }
      requests.add(request);
    }
    final allocation = director.allocate(budgets: budgets, requests: requests);
    _lastAllocation = allocation;
  }
}
