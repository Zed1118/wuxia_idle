import '../../domain/phase0a/phase0a_combat_events.dart';
import '../../domain/phase0a/phase0a_combat_intent.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_combat_reducer.dart';
import 'phase0a_enemy_ai_adapter.dart';
import 'phase0a_enemy_intent_observer.dart';
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
    this.enemySkillDamageResolver,
    this.enemyIntentObserver,
  }) : _state = initialState;

  final Phase0aPlayerInputAdapter playerAdapter;
  final Phase0aEnemyAiAdapter enemyAiAdapter;
  final Phase0aDamageResolver damageResolver;
  final Phase0aEnemySkillDamageResolver? enemySkillDamageResolver;

  /// 可选的敌方 intent 只读观察器;为 null 时不构造任何观测对象。
  final Phase0aEnemyIntentObserver? enemyIntentObserver;

  Phase0aArenaState _state;
  Phase0aEnemyIntentObservation? _lastEnemyIntentObservation;

  Phase0aArenaState get state => _state;

  /// 最近一拍交付给观察器的只读快照;未配置观察器时为 null。
  Phase0aEnemyIntentObservation? get lastEnemyIntentObservation =>
      _lastEnemyIntentObservation;

  /// 推进一拍:玩家指令与敌方 AI 各产 intent,合并后经同一 reducer 结算。
  /// 返回本拍语义事件(已按 seq 排好)。
  ///
  /// 若配置了 [enemyIntentObserver],先交付敌方 intents 的不可修改副本;
  /// 观察器只读,不影响后续进入 reducer 的 intents 与其顺序。
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) {
    final playerIntents = playerAdapter.intentsFor(
      state: _state,
      command: command,
    );
    final enemyIntents = enemyAiAdapter.intentsFor(state: _state);
    final observer = enemyIntentObserver;
    if (observer != null) {
      final observation = Phase0aEnemyIntentObservation(
        tick: _state.tick,
        enemyIntents: enemyIntents,
      );
      observer.observe(observation);
      // 只在 observer 成功返回后公布快照；mapper/director
      // fail closed 时会话状态与诊断状态均不提前提交。
      _lastEnemyIntentObservation = observation;
    }
    final intents = <Phase0aIntent>[...playerIntents, ...enemyIntents];
    final result = reducePhase0aTick(
      state: _state,
      intents: intents,
      deltaSeconds: deltaSeconds,
      damageResolver: damageResolver,
      enemySkillDamageResolver: enemySkillDamageResolver,
    );
    _state = result.state;
    return result.events;
  }
}
