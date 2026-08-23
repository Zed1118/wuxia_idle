import 'dart:math';

import '../../../../data/defs/skill_def.dart';
import '../../../../data/numbers_config.dart';
import '../../domain/phase0a/encounter_enemy_roster.dart';
import '../../domain/phase0a/attack_token_director.dart';
import '../../domain/phase0a/attack_token_lease_runtime.dart';
import '../../domain/phase0a/phase0a_combat_model.dart';
import '../../domain/phase0a/phase0a_combat_reducer.dart';
import '../../domain/phase0a/phase0a_wave.dart';
import '../../domain/phase0a/spawn_director.dart';
import 'phase0a_attack_token_lease_batch_gate.dart';
import 'phase0a_battle_snapshot_factory.dart';
import 'attack_token_enforcing_batch_gate.dart';
import 'phase0a_combat_session.dart';
import 'phase0a_damage_calculator_adapter.dart';
import 'phase0a_enemy_ai_adapter.dart';
import 'phase0a_encounter_flow.dart';
import 'phase0a_encounter_mapping.dart';
import 'phase0a_encounter_objective_event_source.dart';
import 'phase0a_enemy_intent_batch_gate.dart';
import 'phase0a_enemy_intent_observer.dart';
import 'phase0a_objective_runtime_tracker.dart';
import 'phase0a_migrated_encounter_plan_builder.dart';
import 'phase0a_player_input_adapter.dart';
import 'phase0a_wave_battle_flow.dart';

/// Phase 0A 生产 flow 装配器(第六批派单):唯一生产装配入口。
///
/// 把既有 `Phase0aBattleSnapshotFactory` → `Phase0aDamageCalculatorAdapter`
/// → `Phase0aCombatSession` → `Phase0aWaveBattleFlow` 一次性装配为已接好
/// 真实伤害的 [Phase0aWaveBattleFlow],消除调用方手工接线与「配置错误延迟到
/// 首击才暴露」的缺口。本类只做组合与启动期结构校验,不复制其中任何伤害、
/// 移动、AI、CD、真气、波次或终局规则。
///
/// 冻结契约(第六批协调计划 + 派单):
/// - 结构校验全部不消费 RNG,且先于一切伤害组件构造:全场 actor 精确覆盖 →
///   playerId 一致 → 招式 kind 绑定完整;任何结构错误不得推进 RNG。
/// - 全场 expected actor ids = `initialState.player.id` + 每一波 `enemy.id`;
///   [combatants] 的显式 actor ids 必须精确覆盖,missing/extra 均 fail-fast,
///   错误信息列出稳定排序后的 id。
/// - `playerAdapter.playerId` 必须等于 `initialState.player.id`。
/// - [moveBindings] 必须显式覆盖 basic/gather/clear；数字技能只在真实槽
///   非空时出现，并与 player Adapter 的 skill id 精确一致。
/// - 结构校验完成后才调快照工厂;其动态机制/吸血 fail-fast 原样穿透,
///   不包装、不延迟到首击。
/// - 只创建一个伤害 adapter,并把同一个显式 [rng] 实例交给它;换波重建
///   session 由 flow 复用同一 resolver 实例,保证 RNG 连续、不按波重置。
/// - 首态/波次 side、首波一致性、跨波 actor id 唯一继续交给
///   [Phase0aWaveBattleFlow] 既有构造期校验,本类不复制其规则。
/// - 防御性副本沿既有体例(工厂 bundle / adapter / flow 均已不可修改化):
///   装配完成后外部 combatants/waves/moveBindings mutation 不影响 flow。
final class Phase0aProductionFlowAssembler {
  const Phase0aProductionFlowAssembler._();

  /// 唯一装配入口:返回已接好真实伤害的 [Phase0aWaveBattleFlow]。
  static Phase0aWaveBattleFlow assemble({
    required Phase0aArenaState initialState,
    required List<Phase0aWave> waves,
    required List<Phase0aCombatantInput> combatants,
    required Map<Phase0aDamageKind, SkillDef?> moveBindings,
    required NumbersConfig numbers,
    required Random rng,
    required Phase0aPlayerInputAdapter playerAdapter,
    required Phase0aEnemyAiAdapter enemyAiAdapter,
    Phase0aWaveTransitionPolicy? waveTransitionPolicy,
  }) {
    // —— 结构校验(零 RNG 消费,先于一切伤害组件构造)——
    _checkActorCoverage(
      initialState: initialState,
      waves: waves,
      combatants: combatants,
    );
    _checkPlayerAdapterId(playerAdapter, initialState);
    _checkMoveBindings(moveBindings, playerAdapter);

    // —— 组合既有组件(工厂动态机制 fail-fast 原样穿透)——
    final bundle = Phase0aBattleSnapshotFactory(
      numbers: numbers,
    ).create(combatants: combatants, moveBindings: moveBindings);
    final damageResolver = Phase0aDamageCalculatorAdapter(
      combatants: bundle.combatants,
      moveBindings: bundle.moveBindings,
      numbers: numbers,
      rng: rng,
    );
    return Phase0aWaveBattleFlow(
      session: Phase0aCombatSession(
        initialState: initialState,
        playerAdapter: playerAdapter,
        enemyAiAdapter: enemyAiAdapter,
        damageResolver: damageResolver,
        enemySkillDamageResolver: damageResolver,
      ),
      waves: waves,
      waveTransitionPolicy: waveTransitionPolicy,
    );
  }

  /// 动态遭遇装配入口(D07 派单):返回已接好真实伤害的
  /// [Phase0aEncounterFlow],把 Batch4 动态 runtime 接入同一套生产快照/
  /// 伤害 adapter 与单一 caller RNG 所有权。
  ///
  /// 与 [assemble] 同一层纪律:本方法只做组合与启动期结构校验,不复制任何
  /// 伤害、移动、AI、CD、真气、生成或终局规则。expected actor ids =
  /// `initialState.player.id` + roster 全部敌人 actor id;missing/extra 稳定
  /// 排序后 fail closed(消息格式与 [assemble] 同体例)。playerId / move-binding
  /// 校验复用既有口径([_checkPlayerAdapterId] / [_checkMoveBindings])。
  /// 只创建一个 damage adapter 与一个 session,同一 caller [rng] 跨所有
  /// 敌人与拍连续消费(换敌由 flow 每拍 fork 保留同一 resolver 实例)。
  /// director/roster identity、tick、active arena 与 side/alive 的 fail-closed
  /// 校验继续由 [Phase0aEncounterFlow.runtime] 构造器负责,本方法不复制也不
  /// 吞掉;显式 objective runtime 也只允许 tracker/event source 成对透传,
  /// assembler 不创建 controller、objective event 或默认 mapper。一切结构错误
  /// 均在首拍前失败、不推进 RNG。
  /// Transactional attack-token lease gate/runtime 同样只允许 caller 成对
  /// 显式透传；本层不默认构造，不推断 action identity 或 acquire/
  /// release 生命周期。它与 stateless batch gate 的互斥继续由
  /// [Phase0aCombatSession] 单一校验。
  static Phase0aEncounterFlow assembleEncounter({
    required Phase0aArenaState initialState,
    required SpawnDirector director,
    required Phase0aEncounterRoster roster,
    required List<Phase0aCombatantInput> combatants,
    required Map<Phase0aDamageKind, SkillDef?> moveBindings,
    required NumbersConfig numbers,
    required Random rng,
    required Phase0aPlayerInputAdapter playerAdapter,
    required Phase0aEnemyAiAdapter enemyAiAdapter,
    Phase0aEnemyIntentObserver? enemyIntentObserver,
    Phase0aEnemyIntentBatchGate? enemyIntentBatchGate,
    Phase0aAttackTokenLeaseBatchGate? attackTokenLeaseBatchGate,
    AttackTokenLeaseRuntime? attackTokenLeaseRuntime,
    Phase0aObjectiveRuntimeTracker? objectiveTracker,
    Phase0aEncounterObjectiveEventSource? objectiveEventSource,
  }) {
    // —— 结构校验(零 RNG 消费,先于一切伤害组件构造)——
    _checkEncounterActorCoverage(
      initialState: initialState,
      roster: roster,
      combatants: combatants,
    );
    _checkPlayerAdapterId(playerAdapter, initialState);
    _checkMoveBindings(moveBindings, playerAdapter);

    // —— 组合既有组件(工厂动态机制 fail-fast 原样穿透)——
    final bundle = Phase0aBattleSnapshotFactory(
      numbers: numbers,
    ).create(combatants: combatants, moveBindings: moveBindings);
    final damageResolver = Phase0aDamageCalculatorAdapter(
      combatants: bundle.combatants,
      moveBindings: bundle.moveBindings,
      numbers: numbers,
      rng: rng,
    );
    final session = Phase0aCombatSession(
      initialState: initialState,
      playerAdapter: playerAdapter,
      enemyAiAdapter: enemyAiAdapter,
      damageResolver: damageResolver,
      enemySkillDamageResolver: damageResolver,
      enemyIntentObserver: enemyIntentObserver,
      enemyIntentBatchGate: enemyIntentBatchGate,
      attackTokenLeaseBatchGate: attackTokenLeaseBatchGate,
      attackTokenLeaseRuntime: attackTokenLeaseRuntime,
    );
    // runtime 构造继续校验 director/roster identity、tick、active arena 与
    // side/alive;校验失败在首拍前 fail closed,不推进 RNG。
    return Phase0aEncounterFlow.runtime(
      session: session,
      director: director,
      roster: roster,
      objectiveTracker: objectiveTracker,
      objectiveEventSource: objectiveEventSource,
    );
  }

  /// Dynamic encounter typed bridge (D09 dispatch): delegates a frozen
  /// [Phase0aEncounterMapping] back to [assembleEncounter], copying no
  /// damage, AI, movement, spawn, terminal or RNG rules.
  ///
  /// The caller still passes [numbers] and the single [rng] explicitly (the
  /// mapping holds neither, keeping tuning and RNG ownership continuous); an
  /// optional observe-only [Phase0aEnemyIntentObserver] and optional caller-
  /// supplied [Phase0aEnemyIntentBatchGate] are likewise explicit here rather
  /// than frozen into the mapping. A transactional lease gate/runtime pair is
  /// also forwarded only when supplied explicitly; this bridge constructs no
  /// default and infers no action lifecycle. An objective tracker and event
  /// source may only be supplied as the same explicit pair accepted by the
  /// runtime flow; this bridge constructs neither. The mapping constructor has
  /// already validated director/roster identity, player id consistency and
  /// duplicate combatant actor ids; full actor coverage, player adapter id and
  /// move-
  /// binding validation stay fail-closed in [assembleEncounter], so this
  /// bridge behaves identically to a direct call.
  static Phase0aEncounterFlow assembleEncounterFromMapping({
    required Phase0aEncounterMapping mapping,
    required NumbersConfig numbers,
    required Random rng,
    Phase0aEnemyIntentObserver? enemyIntentObserver,
    Phase0aEnemyIntentBatchGate? enemyIntentBatchGate,
    Phase0aAttackTokenLeaseBatchGate? attackTokenLeaseBatchGate,
    AttackTokenLeaseRuntime? attackTokenLeaseRuntime,
    Phase0aObjectiveRuntimeTracker? objectiveTracker,
    Phase0aEncounterObjectiveEventSource? objectiveEventSource,
  }) {
    return assembleEncounter(
      initialState: mapping.initialState,
      director: mapping.director,
      roster: mapping.roster,
      combatants: mapping.combatants,
      moveBindings: mapping.moveBindings,
      numbers: numbers,
      rng: rng,
      playerAdapter: mapping.playerAdapter,
      enemyAiAdapter: mapping.enemyAiAdapter,
      enemyIntentObserver: enemyIntentObserver,
      enemyIntentBatchGate: enemyIntentBatchGate,
      attackTokenLeaseBatchGate: attackTokenLeaseBatchGate,
      attackTokenLeaseRuntime: attackTokenLeaseRuntime,
      objectiveTracker: objectiveTracker,
      objectiveEventSource: objectiveEventSource,
    );
  }

  /// Explicit opt-in bridge for one typed migrated encounter plan.
  ///
  /// The plan owns the exact mapping, token budgets and objective controller.
  /// This bridge creates a stateless enforcing gate and a fresh objective
  /// tracker from those contracts, while the request mapper, objective event
  /// source, numbers and single RNG remain required caller dependencies. It
  /// does not select a route, read production data or install a host default.
  static Phase0aEncounterFlow assembleMigratedEncounterPlan({
    required Phase0aMigratedEncounterPlan plan,
    required NumbersConfig numbers,
    required Random rng,
    required Phase0aAttackTokenEnforcementRequestMapper tokenRequestMapper,
    required Phase0aEncounterObjectiveEventSource objectiveEventSource,
    Phase0aEnemyIntentObserver? enemyIntentObserver,
  }) {
    final contracts = plan.runtimeContracts;
    return assembleEncounterFromMapping(
      mapping: plan.mapping,
      numbers: numbers,
      rng: rng,
      enemyIntentObserver: enemyIntentObserver,
      enemyIntentBatchGate: AttackTokenEnforcingBatchGate(
        director: const AttackTokenDirector(),
        budgets: contracts.attackTokenBudgets,
        requestMapper: tokenRequestMapper,
      ),
      objectiveTracker: Phase0aObjectiveRuntimeTracker(
        controller: contracts.objectiveController,
      ),
      objectiveEventSource: objectiveEventSource,
    );
  }

  /// 全场 actor 精确覆盖:expected = 首态玩家 + 每一波敌人;missing/extra
  /// 均 fail-fast,错误 id 稳定排序。
  static void _checkActorCoverage({
    required Phase0aArenaState initialState,
    required List<Phase0aWave> waves,
    required List<Phase0aCombatantInput> combatants,
  }) {
    final expected = <String>{initialState.player.id};
    for (final wave in waves) {
      for (final enemy in wave.enemies) {
        expected.add(enemy.id);
      }
    }
    final actual = combatants.map((combatant) => combatant.actorId).toSet();
    final missing = expected.difference(actual).toList()..sort();
    final extra = actual.difference(expected).toList()..sort();
    if (missing.isNotEmpty || extra.isNotEmpty) {
      throw ArgumentError(
        'Phase0a 装配 actor 覆盖错误: missing=$missing, extra=$extra',
      );
    }
  }

  /// 玩家 adapter 的 playerId 必须等于首态玩家 id(两个装配入口共用)。
  static void _checkPlayerAdapterId(
    Phase0aPlayerInputAdapter playerAdapter,
    Phase0aArenaState initialState,
  ) {
    if (playerAdapter.playerId != initialState.player.id) {
      throw ArgumentError.value(
        playerAdapter.playerId,
        'playerAdapter',
        'playerId 必须等于首态玩家 id(${initialState.player.id})',
      );
    }
  }

  /// 动态遭遇全场 actor 精确覆盖:expected = 首态玩家 + roster 全部敌人
  /// actor id;missing/extra 均 fail-fast,错误 id 稳定排序。
  static void _checkEncounterActorCoverage({
    required Phase0aArenaState initialState,
    required Phase0aEncounterRoster roster,
    required List<Phase0aCombatantInput> combatants,
  }) {
    final expected = <String>{initialState.player.id};
    for (final binding in roster.bindings) {
      expected.add(binding.actorId);
    }
    final actual = combatants.map((combatant) => combatant.actorId).toSet();
    final missing = expected.difference(actual).toList()..sort();
    final extra = actual.difference(expected).toList()..sort();
    if (missing.isNotEmpty || extra.isNotEmpty) {
      throw ArgumentError(
        'Phase0a 装配 encounter actor 覆盖错误: missing=$missing, extra=$extra',
      );
    }
  }

  /// 招式绑定完整覆盖:每个 kind 必须显式 containsKey;null 为合法
  /// control-only,缺 key 才 fail-fast。
  static void _checkMoveBindings(
    Map<Phase0aDamageKind, SkillDef?> moveBindings,
    Phase0aPlayerInputAdapter playerAdapter,
  ) {
    const requiredKinds = [
      Phase0aDamageKind.basic,
      Phase0aDamageKind.gather,
      Phase0aDamageKind.clear,
    ];
    final missing = <String>[
      for (final kind in requiredKinds)
        if (!moveBindings.containsKey(kind)) kind.name,
    ];
    if (missing.isNotEmpty) {
      throw ArgumentError(
        'Phase0a 装配招式绑定缺失(按 enum 序): $missing;'
        'null 为合法 control-only 绑定,缺 key 不允许',
      );
    }
    final gatherBinding = playerAdapter.gatherSkillBinding;
    final clearBinding = playerAdapter.clearSkillBinding;
    if ((gatherBinding == null) != (clearBinding == null)) {
      throw ArgumentError(
        'Phase0a tactical adapter bindings must be both present or both absent',
      );
    }
    if (gatherBinding != null && clearBinding != null) {
      final gatherDamageSkill = moveBindings[Phase0aDamageKind.gather];
      final clearDamageSkill = moveBindings[Phase0aDamageKind.clear];
      if (gatherDamageSkill?.id != gatherBinding.skill.id ||
          clearDamageSkill?.id != clearBinding.skill.id) {
        throw ArgumentError(
          'Phase0a tactical skill binding mismatch: '
          'adapter=${gatherBinding.skill.id}/${clearBinding.skill.id}, '
          'damage=${gatherDamageSkill?.id}/${clearDamageSkill?.id}',
        );
      }
    }
    for (final binding in playerAdapter.numericSkillBindings.equipped) {
      final kind = phase0aDamageKindForSkillHotkey(binding.hotkey);
      final bound = moveBindings[kind];
      if (bound?.id != binding.skill.id) {
        throw ArgumentError(
          'Phase0a 数字技能绑定不一致: hotkey=${binding.hotkey}, '
          'adapter=${binding.skill.id}, damage=${bound?.id}',
        );
      }
    }
  }
}
