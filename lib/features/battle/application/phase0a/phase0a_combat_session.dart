import '../../domain/phase0a/phase0a_combat_events.dart';
import '../../domain/phase0a/phase0a_combat_intent.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_combat_reducer.dart';
import 'phase0a_enemy_ai_adapter.dart';
import 'phase0a_enemy_intent_gate.dart';
import 'phase0a_enemy_intent_observer.dart';
import 'phase0a_player_input_adapter.dart';

/// Phase 0A 战斗会话:编排 adapter → gate → resolver → reducer 的薄层。
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
    this.enemyIntentGate,
  }) : _state = initialState;

  final Phase0aPlayerInputAdapter playerAdapter;
  final Phase0aEnemyAiAdapter enemyAiAdapter;
  final Phase0aDamageResolver damageResolver;
  final Phase0aEnemySkillDamageResolver? enemySkillDamageResolver;

  /// 可选的敌方 intent 只读观察器;为 null 时不构造任何观测对象。
  final Phase0aEnemyIntentObserver? enemyIntentObserver;

  /// 可选的逐拍敌方 intent 筛选闸;为 null 时 adapter 输出原样进入
  /// observer 与 reducer(与现有路径完全一致)。
  final Phase0aEnemyIntentGate? enemyIntentGate;

  Phase0aArenaState _state;
  Phase0aEnemyIntentObservation? _lastEnemyIntentObservation;

  Phase0aArenaState get state => _state;

  /// 最近一拍交付给观察器的只读快照;未配置观察器时为 null。
  Phase0aEnemyIntentObservation? get lastEnemyIntentObservation =>
      _lastEnemyIntentObservation;

  /// 返回仅替换 state 的候选会话:复用同一 player adapter、enemy AI
  /// adapter、damage resolver、enemy-skill resolver、enemy-intent
  /// observer 与 gate 实例,不创建 RNG、不推进 tick/seq、不产生事件。
  Phase0aCombatSession forkWithState(Phase0aArenaState nextState) {
    return Phase0aCombatSession(
      initialState: nextState,
      playerAdapter: playerAdapter,
      enemyAiAdapter: enemyAiAdapter,
      damageResolver: damageResolver,
      enemySkillDamageResolver: enemySkillDamageResolver,
      enemyIntentObserver: enemyIntentObserver,
      enemyIntentGate: enemyIntentGate,
    );
  }

  /// 推进一拍:玩家指令与敌方 AI 各产 intent,经 gate 筛选后合并,
  /// 由同一 reducer 结算。返回本拍语义事件(已按 seq 排好)。
  ///
  /// 若配置了 [enemyIntentGate],敌方 intents 先经 gate 筛选;再配置了
  /// [enemyIntentObserver] 时,交付观察器的是最终要交给 reducer 的
  /// 不可修改列表。观察器只读,不影响后续进入 reducer 的 intents 与其顺序。
  List<Phase0aEvent> advance({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) {
    final playerIntents = playerAdapter.intentsFor(
      state: _state,
      command: command,
    );
    final enemyIntents = enemyAiAdapter.intentsFor(state: _state);
    final gate = enemyIntentGate;
    final gatedEnemyIntents = gate != null
        ? gate.gateEnemyIntents(enemyIntents: enemyIntents)
        : enemyIntents;
    final observer = enemyIntentObserver;
    if (observer != null) {
      final observation = Phase0aEnemyIntentObservation(
        tick: _state.tick,
        enemyIntents: gatedEnemyIntents,
      );
      observer.observe(observation);
      // 只在 observer 成功返回后公布快照；mapper/director
      // fail closed 时会话状态与诊断状态均不提前提交。
      _lastEnemyIntentObservation = observation;
    }
    final intents = <Phase0aIntent>[...playerIntents, ...gatedEnemyIntents];
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
