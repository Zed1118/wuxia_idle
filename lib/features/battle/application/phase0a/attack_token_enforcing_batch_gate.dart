import 'dart:collection';

import '../../domain/phase0a/attack_token_director.dart';
import '../../domain/phase0a/phase0a_combat_intent.dart';
import 'phase0a_enemy_intent_batch_gate.dart';

/// 把单个 enemy intent 显式映射为 token 请求。
///
/// 返回 null = 该 intent 不参与 attack-token 分配，原对象原样
/// 放行（例如移动）。kind/priority/offscreen/highImpact/telegraph/
/// grace 等语义全部由调用方显式给出，本 gate 不做推断。
typedef Phase0aAttackTokenEnforcementRequestMapper =
    AttackTokenRequest? Function(Phase0aIntent intent);

/// 用 [AttackTokenDirector] 实际筛选本拍敌方攻击 intent。
///
/// budgets、director 和 mapper 都是显式依赖；不提供 tuning 默认值，
/// 不根据 intent 类型或 actor 角色猜 token kind。director 拒绝的
/// token intent 被过滤，获准 token 与非 token intent 保持输入顺序。
final class AttackTokenEnforcingBatchGate
    implements Phase0aEnemyIntentBatchGate {
  AttackTokenEnforcingBatchGate({
    required this.director,
    required this.budgets,
    required this.requestMapper,
  });

  final AttackTokenDirector director;
  final AttackTokenBudgets budgets;
  final Phase0aAttackTokenEnforcementRequestMapper requestMapper;

  @override
  List<Phase0aIntent> gateEnemyIntents({
    required List<Phase0aIntent> enemyIntents,
  }) {
    final candidates = List<Phase0aIntent>.unmodifiable(
      List<Phase0aIntent>.of(enemyIntents),
    );
    final requests = <AttackTokenRequest>[];
    final requestByIntent =
        HashMap<Phase0aIntent, AttackTokenRequest>.identity();

    for (final intent in candidates) {
      final request = requestMapper(intent);
      if (request == null) continue;
      if (request.actorId != intent.actorId) {
        throw ArgumentError(
          'request actorId "${request.actorId}" must equal intent actorId '
          '"${intent.actorId}" (attack-token enforcement fails closed)',
        );
      }
      requests.add(request);
      requestByIntent[intent] = request;
    }

    final allocation = director.allocate(budgets: budgets, requests: requests);
    final grantedActorIds = allocation.grantedActorIds.toSet();
    final gated = <Phase0aIntent>[];
    for (final intent in candidates) {
      final request = requestByIntent[intent];
      if (request == null || grantedActorIds.contains(request.actorId)) {
        gated.add(intent);
      }
    }
    return List<Phase0aIntent>.unmodifiable(gated);
  }
}
