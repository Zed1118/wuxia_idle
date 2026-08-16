import '../../domain/phase0a/phase0a_combat_events.dart';
import '../../domain/phase0a/phase0a_combat_intent.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_combat_reducer.dart';
import 'phase0a_enemy_ai_adapter.dart';
import 'phase0a_player_input_adapter.dart';

/// Phase 0A 战斗会话:编排 adapter → resolver → reducer 的薄层。
///
/// 本层不复制移动、命中、扣血、CD 或胜负规则——全部结算只发生在
/// [reducePhase0aTick];伤害结算经显式注入的 [damageResolver]
/// (本片测试用固定实现,未来生产接 DamageCalculator)。
final class Phase0aCombatSession {
  Phase0aCombatSession({
    required Phase0aArenaState initialState,
    required this.playerAdapter,
    required this.enemyAiAdapter,
    required this.damageResolver,
  }) : _state = initialState;

  final Phase0aPlayerInputAdapter playerAdapter;
  final Phase0aEnemyAiAdapter enemyAiAdapter;
  final Phase0aDamageResolver damageResolver;

  Phase0aArenaState _state;

  Phase0aArenaState get state => _state;

  /// 推进一拍:玩家指令与敌方 AI 各产 intent,合并后经同一 reducer 结算。
  /// 返回本拍语义事件(已按 seq 排好)。
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) {
    final intents = <Phase0aIntent>[
      ...playerAdapter.intentsFor(state: _state, command: command),
      ...enemyAiAdapter.intentsFor(state: _state),
    ];
    final result = reducePhase0aTick(
      state: _state,
      intents: intents,
      deltaSeconds: deltaSeconds,
      damageResolver: damageResolver,
    );
    _state = result.state;
    return result.events;
  }
}
