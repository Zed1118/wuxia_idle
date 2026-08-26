import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_mapping.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_intent_observer.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_enemy_roster.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_damage_kind.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

/// D09: observe-only 敌方 intent 观察器(只收集,不消费 RNG、不改状态)。
class _CapturingObserver implements Phase0aEnemyIntentObserver {
  final List<Phase0aEnemyIntentObservation> observations = [];

  @override
  void observe(Phase0aEnemyIntentObservation observation) {
    observations.add(observation);
  }
}

/// D09:不可变 [Phase0aEncounterMapping] 与 production assembler typed bridge
/// 红测(第六批派单 §必测证伪点):
/// ① 构造期三校验:director/roster identity、player id 一致性、combatant
///    actor id 重复(missing/extra 覆盖与 move binding 留给 assembler);
/// ② 列表与映射防御性不可修改:外部 mutation 不污染已冻结 mapping,
///    mapping 自身集合不可变;
/// ③ bridge 与直接 assembleEncounter 同 seed 三拍回放全等(events/state/
///    outcome/records/RNG 尾值),证明 bridge 只委托不复制;
/// ④ bridge 上 assembler 既有 fail-closed(actor 覆盖 / playerAdapter id /
///    move binding)原样透传且零 RNG 消费;
/// ⑤ observe-only observer 经 bridge 透传:宽限 gate 先于 observer,不改变
///    events/state/RNG。
void main() {
  setUp(() async {
    await loadTestGameRepository();
  });

  tearDown(GameRepository.resetForTest);

  NumbersConfig numbers() => GameRepository.instance.numbers;

  final basicSkill = const SkillDef(
    id: 'phase0a_map_basic',
    name: 'basic',
    description: 'basic',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    qiDelta: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: '',
    proficiency: SkillProficiencyEffects({'shuLian': 0.10}, {}, {}, {}),
  );

  const otherSkill = SkillDef(
    id: 'phase0a_map_other',
    name: 'other',
    description: 'other',
    type: SkillType.normalAttack,
    powerMultiplier: 1500,
    qiDelta: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: '',
  );

  /// 完整 binding:gather/clear 显式 null(control-only),与缺 key 可区分。
  Map<Phase0aDamageKind, SkillDef?> fullBindings() => {
    Phase0aDamageKind.basic: basicSkill,
    Phase0aDamageKind.gather: null,
    Phase0aDamageKind.clear: null,
  };

  CombatantSnapshot makeCharacter({
    int characterId = 1,
    TechniqueSchool school = TechniqueSchool.gangMeng,
    int internalForce = 600,
    int totalEquipmentAttack = 130,
    double defenseRate = 0.05,
    double criticalRate = 0.0,
    Map<String, int> skillUses = const {},
    double forgingPiercePct = 0.0,
  }) {
    return testCombatantSnapshot(
      characterId: characterId,
      name: 'c$characterId',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.ruMen,
      school: school,
      maxHp: 1000,
      internalForce: internalForce,
      maxQi: 100,
      speed: 100,
      criticalRate: criticalRate,
      defenseRate: defenseRate,
      totalEquipmentAttack: totalEquipmentAttack,
      skillUses: skillUses,
      forgingPiercePct: forgingPiercePct,
    );
  }

  /// player + e1 + e2 三个真实快照源(与 D07 fixture 同体例)。
  Map<String, CombatantSnapshot> encounterCharacters() => {
    'player': makeCharacter(
      criticalRate: 0.5,
      skillUses: {basicSkill.id: 150},
      forgingPiercePct: 0.1,
    ),
    'e1': makeCharacter(
      characterId: 2,
      school: TechniqueSchool.yinRou,
      internalForce: 400,
      totalEquipmentAttack: 90,
      criticalRate: 0.5,
    ),
    'e2': makeCharacter(
      characterId: 3,
      school: TechniqueSchool.yinRou,
      internalForce: 450,
      totalEquipmentAttack: 95,
      defenseRate: 0.08,
      criticalRate: 0.25,
    ),
  };

  List<Phase0aCombatantInput> combatantsFrom(
    Map<String, CombatantSnapshot> characters,
  ) {
    return [
      for (final entry in characters.entries)
        Phase0aCombatantInput(actorId: entry.key, snapshot: entry.value),
    ];
  }

  Phase0aActor arenaActor({
    required String id,
    required Phase0aSide side,
    required ArenaVector position,
    int currentHealth = 100000,
  }) {
    return Phase0aActor(
      id: id,
      side: side,
      position: position,
      facing: side == Phase0aSide.player
          ? const ArenaVector(1, 0)
          : const ArenaVector(-1, 0),
      maxHealth: 100000,
      currentHealth: currentHealth,
      moveSpeed: 100,
      qiCurrent: 100,
      qiMax: 100,
      attackCooldownRemaining: 0,
      defeatKind: Phase0aDefeatKind.normal,
    );
  }

  SpawnDirector encounterDirector({
    int activeLimit = 2,
    int entryWarningTicks = 0,
    int attackGraceTicks = 0,
  }) {
    return SpawnDirector(
      config: SpawnDirectorConfig(
        activeLimit: activeLimit,
        reinforcementThreshold: 0,
        entryWarningTicks: entryWarningTicks,
        attackGraceTicks: attackGraceTicks,
      ),
      entries: [
        SpawnEntry(entryId: 'entry_e1', enemyId: 'e1'),
        SpawnEntry(entryId: 'entry_e2', enemyId: 'e2'),
      ],
    );
  }

  Phase0aEncounterRoster encounterRoster(
    SpawnDirector director, {
    int e1Health = 100000,
    int e2Health = 100000,
    String playerId = 'player',
  }) {
    return Phase0aEncounterRoster(
      director: director,
      playerId: playerId,
      bindings: [
        Phase0aEncounterRosterBinding(
          entryId: 'entry_e1',
          actor: arenaActor(
            id: 'e1',
            side: Phase0aSide.enemy,
            position: const ArenaVector(50, 0),
            currentHealth: e1Health,
          ),
        ),
        Phase0aEncounterRosterBinding(
          entryId: 'entry_e2',
          actor: arenaActor(
            id: 'e2',
            side: Phase0aSide.enemy,
            position: const ArenaVector(60, 0),
            currentHealth: e2Health,
          ),
        ),
      ],
    );
  }

  /// 初始 arena:director tick0 无 active 单位 → enemies 必须为空,
  /// 一致性由 [Phase0aEncounterFlow.runtime] 构造器校验穿透。
  Phase0aArenaState encounterInitialState() {
    return Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: arenaActor(
        id: 'player',
        side: Phase0aSide.player,
        position: ArenaVector.zero,
      ),
      enemies: const [],
      skillSlots: const [],
    );
  }

  Phase0aPlayerInputAdapter makePlayerAdapter({String playerId = 'player'}) {
    return Phase0aPlayerInputAdapter(
      playerId: playerId,
      attackRange: 120,
      attackHalfArcRadians: math.pi / 4,
      attackCooldownSeconds: 0.5,
      attackQiDelta: 0,
      postureBasicPowerMultiplier: 1,
      attackPowerMultiplier: 1,
      gatherPowerMultiplier: 1,
      clearPowerMultiplier: 1,
      gatherSlot: 'gather',
      gatherRingRadius: 90,
      gatherEffectRadius: 500,
      gatherQiCost: 20,
      gatherCooldownSeconds: 3,
      clearSlot: 'clear',
      clearEffectRadius: 500,
      clearQiCost: 30,
      clearCooldownSeconds: 4,
    );
  }

  Phase0aEnemyAiAdapter makeEnemyAdapter() {
    return const Phase0aEnemyAiAdapter(
      attackRange: 70,
      attackHalfArcRadians: math.pi / 3,
      attackCooldownSeconds: 0.5,
      postureBasicPowerMultiplier: 1,
      uniformBasicPowerMultiplier: 1,
    );
  }

  /// 构造合法 mapping;个别入参可覆盖以测构造校验与 fail-closed 透传。
  Phase0aEncounterMapping makeMapping({
    Phase0aArenaState? initialState,
    SpawnDirector? director,
    Phase0aEncounterRoster? roster,
    List<Phase0aCombatantInput>? combatants,
    Map<Phase0aDamageKind, SkillDef?>? moveBindings,
    Phase0aPlayerInputAdapter? playerAdapter,
    Phase0aEnemyAiAdapter? enemyAiAdapter,
  }) {
    final resolvedDirector = director ?? encounterDirector();
    return Phase0aEncounterMapping(
      initialState: initialState ?? encounterInitialState(),
      director: resolvedDirector,
      roster: roster ?? encounterRoster(resolvedDirector),
      combatants: combatants ?? combatantsFrom(encounterCharacters()),
      moveBindings: moveBindings ?? fullBindings(),
      playerAdapter: playerAdapter ?? makePlayerAdapter(),
      enemyAiAdapter: enemyAiAdapter ?? makeEnemyAdapter(),
    );
  }

  List<Phase0aEvent> advanceTicks(Phase0aEncounterFlow flow, int ticks) {
    final events = <Phase0aEvent>[];
    for (var i = 0; i < ticks; i++) {
      events.addAll(
        flow.advance(
          deltaSeconds: 0.5,
          command: const Phase0aPlayerCommand(attack: true),
        ),
      );
    }
    return events;
  }

  /// 直接 assembleEncounter(对照路径):同 fixture 同 seed。
  (List<Phase0aEvent>, Phase0aEncounterFlow, math.Random) runDirect(
    int seed,
    int ticks,
  ) {
    final rng = math.Random(seed);
    final director = encounterDirector();
    final flow = Phase0aProductionFlowAssembler.assembleEncounter(
      initialState: encounterInitialState(),
      director: director,
      roster: encounterRoster(director),
      combatants: combatantsFrom(encounterCharacters()),
      moveBindings: fullBindings(),
      numbers: numbers(),
      rng: rng,
      playerAdapter: makePlayerAdapter(),
      enemyAiAdapter: makeEnemyAdapter(),
    );
    return (advanceTicks(flow, ticks), flow, rng);
  }

  /// bridge 路径:同 seed,observer 可选。
  (List<Phase0aEvent>, Phase0aEncounterFlow, math.Random) runBridged(
    int seed,
    int ticks, {
    Phase0aEnemyIntentObserver? enemyIntentObserver,
  }) {
    final rng = math.Random(seed);
    final flow = Phase0aProductionFlowAssembler.assembleEncounterFromMapping(
      mapping: makeMapping(),
      numbers: numbers(),
      rng: rng,
      enemyIntentObserver: enemyIntentObserver,
    );
    return (advanceTicks(flow, ticks), flow, rng);
  }

  /// 结构校验不得消费 RNG:失败后下一值仍等于同 seed 未消费对照首值。
  void expectRngUntouched(math.Random rng, int seed) {
    expect(
      rng.nextDouble(),
      math.Random(seed).nextDouble(),
      reason: '装配期结构校验/fail-fast 不得消费 RNG',
    );
  }

  group('构造期校验:director/roster identity、player id、combatant 重复', () {
    test('合法映射构造成功,全部冻结输入原样透出', () {
      final director = encounterDirector();
      final roster = encounterRoster(director);
      final mapping = makeMapping(director: director, roster: roster);
      expect(mapping.initialState.player.id, 'player');
      expect(mapping.director, same(director));
      expect(mapping.roster, same(roster));
      expect(mapping.combatants.map((c) => c.actorId).toSet(), {
        'player',
        'e1',
        'e2',
      });
      expect(mapping.moveBindings, fullBindings());
      expect(mapping.playerAdapter.playerId, 'player');
      expect(mapping.enemyAiAdapter.attackRange, 70);
    });

    test('roster 与 director 非同一实例即拒绝(identity)', () {
      final director = encounterDirector();
      final foreignRoster = encounterRoster(encounterDirector());
      expect(
        () => makeMapping(director: director, roster: foreignRoster),
        throwsArgumentError,
        reason: 'roster 必须绑定与 mapping 同一 director 实例',
      );
    });

    test('roster.playerId 与首态玩家 id 不一致即拒绝', () {
      final director = encounterDirector();
      final mismatchedRoster = encounterRoster(director, playerId: 'other');
      expect(
        () => makeMapping(director: director, roster: mismatchedRoster),
        throwsArgumentError,
        reason: 'roster playerId 必须等于 initialState.player.id',
      );
    });

    test('combatant actor id 重复即拒绝,错误文本列稳定排序重复 id', () {
      final combatants = combatantsFrom(encounterCharacters());
      final duplicated = [
        combatants[0], // player
        combatants[1], // e1
        combatants[1], // e1 重复
        combatants[2], // e2
        combatants[0], // player 重复
      ];
      expect(
        () => makeMapping(combatants: duplicated),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            allOf(contains('duplicate'), contains('[e1, player]')),
          ),
        ),
      );
    });
  });

  group('防御性不可修改:列表与映射', () {
    test('mapping.combatants 自身不可修改', () {
      final mapping = makeMapping();
      expect(
        () => mapping.combatants.add(
          Phase0aCombatantInput(
            actorId: 'e9',
            snapshot: makeCharacter(characterId: 9),
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('mapping.moveBindings 自身不可修改', () {
      final mapping = makeMapping();
      expect(
        () => mapping.moveBindings.remove(Phase0aDamageKind.basic),
        throwsUnsupportedError,
      );
      expect(
        () => mapping.moveBindings[Phase0aDamageKind.basic] = otherSkill,
        throwsUnsupportedError,
      );
    });

    test('外部 combatants 列表构造后 mutation 不污染 mapping', () {
      final combatants = combatantsFrom(encounterCharacters());
      final mapping = makeMapping(combatants: combatants);
      combatants.add(
        Phase0aCombatantInput(
          actorId: 'e9',
          snapshot: makeCharacter(characterId: 9),
        ),
      );
      expect(mapping.combatants, hasLength(3));
      expect(mapping.combatants.map((c) => c.actorId), isNot(contains('e9')));
    });

    test('外部 moveBindings 映射构造后 mutation 不污染 mapping', () {
      final bindings = fullBindings();
      final mapping = makeMapping(moveBindings: bindings);
      bindings[Phase0aDamageKind.basic] = otherSkill;
      bindings.remove(Phase0aDamageKind.clear);
      expect(mapping.moveBindings[Phase0aDamageKind.basic], basicSkill);
      expect(mapping.moveBindings, containsPair(Phase0aDamageKind.clear, null));
    });
  });

  group('typed bridge:委托 assembleEncounter,同 seed 回放全等', () {
    test('三拍 events/state/outcome/records 全等,后续 RNG 尾值相等', () {
      const seed = 42;
      final (eventsDirect, flowDirect, rngDirect) = runDirect(seed, 3);
      final (eventsBridged, flowBridged, rngBridged) = runBridged(seed, 3);

      // 事件骨架与 D07 同 fixture:首拍两敌同时进场,三拍共 9 击。
      expect(
        eventsBridged.whereType<Phase0aEnemyEntered>().map((e) => e.enemyId),
        ['e1', 'e2'],
      );
      expect(eventsBridged, eventsDirect);
      expect(flowBridged.state, flowDirect.state);
      expect(flowBridged.outcome, flowDirect.outcome);
      expect(
        flowBridged.lastOrderedEventRecords,
        flowDirect.lastOrderedEventRecords,
      );
      // 消费序列一致 → 后续 RNG 值相等(bridge 不新建也不重置 RNG)。
      expect(rngBridged.nextDouble(), rngDirect.nextDouble());
    });

    test('bridge 消费 mapping 内实际值:1HP 敌人经 bridge 快速终局', () {
      final director = encounterDirector();
      final flow = Phase0aProductionFlowAssembler.assembleEncounterFromMapping(
        mapping: makeMapping(
          director: director,
          roster: encounterRoster(director, e1Health: 1, e2Health: 1),
        ),
        numbers: numbers(),
        rng: math.Random(7),
      );
      var guard = 0;
      while (flow.outcome == Phase0aBattleOutcome.ongoing && guard < 10) {
        flow.advance(
          deltaSeconds: 0.5,
          command: const Phase0aPlayerCommand(attack: true),
        );
        guard++;
      }
      expect(flow.outcome, Phase0aBattleOutcome.victory);
      expect(
        guard,
        lessThan(10),
        reason: '两敌 1HP 应数拍内终局,证明 bridge 用 mapping 值',
      );
    });
  });

  group('typed bridge:assembler 既有 fail-closed 原样透传且零 RNG 消费', () {
    test('mapping 构造合法但 actor 覆盖 missing:装配期拒绝,RNG 未消费', () {
      // 覆盖检查不属于 mapping 构造期;缺 e2 的 mapping 仍可构造。
      final combatants = combatantsFrom(encounterCharacters())
        ..removeWhere((c) => c.actorId == 'e2');
      final mapping = makeMapping(combatants: combatants);
      final rng = math.Random(99);
      expect(
        () => Phase0aProductionFlowAssembler.assembleEncounterFromMapping(
          mapping: mapping,
          numbers: numbers(),
          rng: rng,
        ),
        throwsArgumentError,
      );
      expectRngUntouched(rng, 99);
    });

    test('playerAdapter.playerId 与首态玩家不一致:装配期拒绝,RNG 未消费', () {
      final mapping = makeMapping(
        playerAdapter: makePlayerAdapter(playerId: 'otherPlayer'),
      );
      final rng = math.Random(99);
      expect(
        () => Phase0aProductionFlowAssembler.assembleEncounterFromMapping(
          mapping: mapping,
          numbers: numbers(),
          rng: rng,
        ),
        throwsArgumentError,
      );
      expectRngUntouched(rng, 99);
    });

    test('缺 basic binding:mapping 构造合法,装配期 fail closed,RNG 未消费', () {
      final bindings = fullBindings()..remove(Phase0aDamageKind.basic);
      final mapping = makeMapping(moveBindings: bindings);
      final rng = math.Random(99);
      expect(
        () => Phase0aProductionFlowAssembler.assembleEncounterFromMapping(
          mapping: mapping,
          numbers: numbers(),
          rng: rng,
        ),
        throwsArgumentError,
      );
      expectRngUntouched(rng, 99);
    });
  });

  group('typed bridge:observe-only observer 透传生效', () {
    test('宽限期内观察为空,到期当拍放行攻击', () {
      final observer = _CapturingObserver();
      final director = encounterDirector(
        activeLimit: 1,
        entryWarningTicks: 0,
        attackGraceTicks: 1,
      );
      final flow = Phase0aProductionFlowAssembler.assembleEncounterFromMapping(
        mapping: makeMapping(director: director),
        numbers: numbers(),
        rng: math.Random(31),
        enemyIntentObserver: observer,
      );

      final first = flow.advance(
        deltaSeconds: 0.5,
        command: const Phase0aPlayerCommand(attack: true),
      );
      expect(first.whereType<Phase0aEnemyEntered>(), hasLength(1));
      // 宽限拍:攻击被 gate 过滤 → 观察列表为空,玩家不掉血。
      expect(observer.observations, hasLength(1));
      expect(observer.observations.single.enemyIntents, isEmpty);
      expect(flow.state.player.currentHealth, 100000);

      final second = flow.advance(
        deltaSeconds: 0.5,
        command: const Phase0aPlayerCommand(attack: true),
      );
      expect(second.whereType<Phase0aSpawnGraceExpired>(), hasLength(1));
      // 到期当拍:攻击放行 → 观察器收到 attack intent,玩家掉血。
      expect(observer.observations, hasLength(2));
      final secondObservation = observer.observations[1].enemyIntents;
      expect(secondObservation, hasLength(1));
      expect(secondObservation.single.actorId, 'e1');
      expect(secondObservation.single, isA<Phase0aAttackIntent>());
      expect(flow.state.player.currentHealth, lessThan(100000));
    });

    test('observer 不改 events/state/RNG:同 seed 有/无观察器全等', () {
      const seed = 43;
      final (eventsA, flowA, rngA) = runBridged(seed, 3);
      final (eventsB, flowB, rngB) = runBridged(
        seed,
        3,
        enemyIntentObserver: _CapturingObserver(),
      );
      expect(eventsB, eventsA);
      expect(flowB.state, flowA.state);
      expect(flowB.outcome, flowA.outcome);
      // 消费序列一致 → 后续 RNG 值相等(observer 不消费也不改 RNG)。
      expect(rngA.nextDouble(), rngB.nextDouble());
    });
  });
}
