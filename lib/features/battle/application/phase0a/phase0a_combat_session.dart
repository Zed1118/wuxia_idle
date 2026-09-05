import '../../domain/phase0a/attack_token_lease_runtime.dart';
import '../../domain/phase0a/arena_vector.dart';
import '../../domain/phase0a/phase0a_combat_events.dart';
import '../../domain/phase0a/phase0a_combat_intent.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_combat_reducer.dart';
import 'phase0a_attack_token_lease_batch_gate.dart';
import 'phase0a_attack_token_lease_batch_receipt.dart';
import 'phase0a_enemy_ai_adapter.dart';
import 'phase0a_enemy_intent_batch_gate.dart';
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
    required Phase0aPlayerInputAdapter playerAdapter,
    required Phase0aEnemyAiAdapter enemyAiAdapter,
    required Phase0aDamageResolver damageResolver,
    Phase0aEnemySkillDamageResolver? enemySkillDamageResolver,
    Phase0aEnemyIntentObserver? enemyIntentObserver,
    Phase0aEnemyIntentGate? enemyIntentGate,
    Phase0aEnemyIntentBatchGate? enemyIntentBatchGate,
    Phase0aAttackTokenLeaseBatchGate? attackTokenLeaseBatchGate,
    AttackTokenLeaseRuntime? attackTokenLeaseRuntime,
  }) : this._(
         initialState: initialState,
         playerAdapter: playerAdapter,
         enemyAiAdapter: enemyAiAdapter,
         damageResolver: damageResolver,
         enemySkillDamageResolver: enemySkillDamageResolver,
         enemyIntentObserver: enemyIntentObserver,
         enemyIntentGate: enemyIntentGate,
         enemyIntentBatchGate: enemyIntentBatchGate,
         attackTokenLeaseBatchGate: attackTokenLeaseBatchGate,
         attackTokenLeaseRuntime: attackTokenLeaseRuntime,
         lastAttackTokenLeaseBatchReceipt: null,
       );

  Phase0aCombatSession._({
    required Phase0aArenaState initialState,
    required this.playerAdapter,
    required this.enemyAiAdapter,
    required this.damageResolver,
    required this.enemySkillDamageResolver,
    required this.enemyIntentObserver,
    required this.enemyIntentGate,
    required this.enemyIntentBatchGate,
    required this.attackTokenLeaseBatchGate,
    required AttackTokenLeaseRuntime? attackTokenLeaseRuntime,
    required Phase0aAttackTokenLeaseBatchReceipt?
    lastAttackTokenLeaseBatchReceipt,
  }) : _state = initialState,
       _attackTokenLeaseRuntime = attackTokenLeaseRuntime,
       _lastAttackTokenLeaseBatchReceipt = lastAttackTokenLeaseBatchReceipt {
    if ((attackTokenLeaseBatchGate == null) !=
        (attackTokenLeaseRuntime == null)) {
      throw ArgumentError(
        'attackTokenLeaseBatchGate and attackTokenLeaseRuntime must be '
        'configured together',
      );
    }
    if (enemyIntentBatchGate != null && attackTokenLeaseBatchGate != null) {
      throw ArgumentError(
        'enemyIntentBatchGate and attackTokenLeaseBatchGate are mutually '
        'exclusive',
      );
    }
  }

  final Phase0aPlayerInputAdapter playerAdapter;
  final Phase0aEnemyAiAdapter enemyAiAdapter;
  final Phase0aDamageResolver damageResolver;
  final Phase0aEnemySkillDamageResolver? enemySkillDamageResolver;

  /// 可选的敌方 intent 只读观察器;为 null 时不构造任何观测对象。
  final Phase0aEnemyIntentObserver? enemyIntentObserver;

  /// 可选的逐拍敌方 intent 筛选闸;为 null 时 adapter 输出原样进入
  /// observer 与 reducer(与现有路径完全一致)。
  final Phase0aEnemyIntentGate? enemyIntentGate;

  /// 可选的批次筛选闸；在逐 intent gate 之后执行，输出必须
  /// 是输入对象 identity 的稳定、无重复子序列。为 null 时不增加
  /// 任何批次处理，保持旧路径。
  final Phase0aEnemyIntentBatchGate? enemyIntentBatchGate;

  /// Optional transactional lease batch gate. The paired immutable runtime
  /// belongs to this session value and is copied into candidate forks. It is
  /// deliberately mutually exclusive with [enemyIntentBatchGate].
  final Phase0aAttackTokenLeaseBatchGate? attackTokenLeaseBatchGate;

  Phase0aArenaState _state;
  AttackTokenLeaseRuntime? _attackTokenLeaseRuntime;
  Phase0aEnemyIntentObservation? _lastEnemyIntentObservation;
  Phase0aAttackTokenLeaseBatchReceipt? _lastAttackTokenLeaseBatchReceipt;

  Phase0aArenaState get state => _state;

  /// 最近一拍交付给观察器的只读快照;未配置观察器时为 null。
  Phase0aEnemyIntentObservation? get lastEnemyIntentObservation =>
      _lastEnemyIntentObservation;

  /// Current immutable lease snapshot, or null when transactional lease
  /// plumbing is not configured. The owning runtime is never exposed.
  AttackTokenLeaseSnapshot? get attackTokenLeaseSnapshot =>
      _attackTokenLeaseRuntime?.snapshot;

  Phase0aAttackTokenLeaseBatchReceipt? get lastAttackTokenLeaseBatchReceipt =>
      _lastAttackTokenLeaseBatchReceipt;

  /// Exact displacement contributed by the player's normal move intent for
  /// this frame. Attack lunges and defense displacement are deliberately
  /// excluded so encounter objectives can attribute checkpoint crossings.
  ArenaVector playerMovementDeltaFor({
    required double deltaSeconds,
    required Phase0aPlayerCommand command,
  }) {
    final before = _state.player;
    final after = resolvePhase0aMovement(
      actor: before,
      direction: playerAdapter.movementDirectionFor(command),
      deltaSeconds: deltaSeconds,
      bounds: playerAdapter.movementArenaBounds,
    );
    return after.position - before.position;
  }

  /// 返回仅替换 state 的候选会话:复用同一 player adapter、enemy AI
  /// adapter、damage resolver、enemy-skill resolver、enemy-intent
  /// observer 与 gate 实例,不创建 RNG、不推进 tick/seq、不产生事件。
  Phase0aCombatSession forkWithState(Phase0aArenaState nextState) {
    return forkWithStateAndEnemyIntentGate(
      nextState,
      enemyIntentGate: enemyIntentGate,
    );
  }

  /// 原子替换 state 与逐拍 gate，其他依赖 identity 全部保留。
  /// EncounterFlow 用此方法在不手工重建 session 的前提下
  /// 跟随 SpawnDirector 的宽限快照逐拍更新 gate。
  Phase0aCombatSession forkWithStateAndEnemyIntentGate(
    Phase0aArenaState nextState, {
    required Phase0aEnemyIntentGate? enemyIntentGate,
  }) {
    return Phase0aCombatSession._(
      initialState: nextState,
      playerAdapter: playerAdapter,
      enemyAiAdapter: enemyAiAdapter,
      damageResolver: damageResolver,
      enemySkillDamageResolver: enemySkillDamageResolver,
      enemyIntentObserver: enemyIntentObserver,
      enemyIntentGate: enemyIntentGate,
      enemyIntentBatchGate: enemyIntentBatchGate,
      attackTokenLeaseBatchGate: attackTokenLeaseBatchGate,
      attackTokenLeaseRuntime: _attackTokenLeaseRuntime,
      lastAttackTokenLeaseBatchReceipt: _lastAttackTokenLeaseBatchReceipt,
    );
  }

  /// 推进一拍:玩家指令与敌方 AI 各产 intent,经逐 intent gate
  /// 与批次 gate 筛选后合并,
  /// 由同一 reducer 结算。返回本拍语义事件(已按 seq 排好)。
  ///
  /// 若配置了 [enemyIntentGate],敌方 intents 先经 gate 筛选;再配置了
  /// [enemyIntentBatchGate] 再只能返回前段输入的 identity 稳定子序列。
  /// 再配置 [enemyIntentObserver] 时,交付观察器的是最终要交给 reducer 的
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
    final perIntentGatedEnemyIntents = gate != null
        ? List<Phase0aIntent>.unmodifiable(enemyIntents.where(gate.allows))
        : enemyIntents;
    final batchGate = enemyIntentBatchGate;
    final leaseBatchGate = attackTokenLeaseBatchGate;
    Phase0aPreparedAttackTokenLeaseBatch? preparedLeaseBatch;
    late final List<Phase0aIntent> gatedEnemyIntents;
    if (leaseBatchGate != null) {
      final leaseInput = List<Phase0aIntent>.unmodifiable(
        List<Phase0aIntent>.of(perIntentGatedEnemyIntents),
      );
      preparedLeaseBatch = leaseBatchGate.prepare(
        runtime: _attackTokenLeaseRuntime!,
        enemyIntents: leaseInput,
      );
      gatedEnemyIntents = _validateBatchGateOutput(
        enemyIntents: leaseInput,
        proposed: preparedLeaseBatch.enemyIntents,
      );
    } else if (batchGate != null) {
      gatedEnemyIntents = _applyBatchGate(
        enemyIntents: gate == null
            ? List<Phase0aIntent>.unmodifiable(
                List<Phase0aIntent>.of(perIntentGatedEnemyIntents),
              )
            : perIntentGatedEnemyIntents,
        batchGate: batchGate,
      );
    } else {
      gatedEnemyIntents = perIntentGatedEnemyIntents;
    }
    final observer = enemyIntentObserver;
    Phase0aEnemyIntentObservation? nextObservation;
    if (observer != null) {
      nextObservation = Phase0aEnemyIntentObservation(
        tick: _state.tick,
        enemyIntents: gatedEnemyIntents,
      );
      observer.observe(nextObservation);
    }
    final intents = <Phase0aIntent>[...playerIntents, ...gatedEnemyIntents];
    final result = reducePhase0aTick(
      state: _state,
      intents: intents,
      deltaSeconds: deltaSeconds,
      damageResolver: damageResolver,
      enemySkillDamageResolver: enemySkillDamageResolver,
      playerMovementBounds: playerAdapter.movementArenaBounds,
    );
    final leaseRuntimeBefore = preparedLeaseBatch == null
        ? null
        : _attackTokenLeaseRuntime!;
    final nextLeaseRuntime = preparedLeaseBatch?.commit(leaseRuntimeBefore!);
    final nextLeaseReceipt = nextLeaseRuntime == null
        ? null
        : Phase0aAttackTokenLeaseBatchReceipt(
            before: leaseRuntimeBefore!.snapshot,
            mutations: preparedLeaseBatch!.mutations,
            after: nextLeaseRuntime.snapshot,
          );

    // No throwing work follows these assignments. Arena state, immutable
    // lease runtime and diagnostic therefore publish as one session-owned
    // tail after planner, observer, reducer and lease commit all succeed.
    _state = result.state;
    if (nextLeaseRuntime != null) {
      _attackTokenLeaseRuntime = nextLeaseRuntime;
    }
    if (nextObservation != null) {
      _lastEnemyIntentObservation = nextObservation;
    }
    if (nextLeaseReceipt != null) {
      _lastAttackTokenLeaseBatchReceipt = nextLeaseReceipt;
    }
    return result.events;
  }

  static List<Phase0aIntent> _applyBatchGate({
    required List<Phase0aIntent> enemyIntents,
    required Phase0aEnemyIntentBatchGate batchGate,
  }) {
    final proposed = batchGate.gateEnemyIntents(enemyIntents: enemyIntents);
    return _validateBatchGateOutput(
      enemyIntents: enemyIntents,
      proposed: proposed,
    );
  }

  static List<Phase0aIntent> _validateBatchGateOutput({
    required List<Phase0aIntent> enemyIntents,
    required Iterable<Phase0aIntent> proposed,
  }) {
    final accepted = <Phase0aIntent>[];
    var inputCursor = 0;
    for (final intent in proposed) {
      if (accepted.any((acceptedIntent) => identical(acceptedIntent, intent))) {
        throw StateError(
          'enemy intent batch gate output must not repeat an input identity',
        );
      }
      while (inputCursor < enemyIntents.length &&
          !identical(enemyIntents[inputCursor], intent)) {
        inputCursor++;
      }
      if (inputCursor >= enemyIntents.length) {
        throw StateError(
          'enemy intent batch gate output must be an identity-stable '
          'subsequence of its input',
        );
      }
      accepted.add(intent);
      inputCursor++;
    }
    return List<Phase0aIntent>.unmodifiable(accepted);
  }
}
