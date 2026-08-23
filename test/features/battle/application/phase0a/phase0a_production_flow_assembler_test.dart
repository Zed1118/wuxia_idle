import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_encounter_flow.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_intent_observer.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_wave_battle_flow.dart';
import 'package:wuxia_idle/features/combat_shared/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/encounter_enemy_roster.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_intent.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/spawn_director.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_proficiency.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

/// D07:observe-only 敌方 intent 观察器(只收集,不消费 RNG、不改状态)。
class _CapturingObserver implements Phase0aEnemyIntentObserver {
  final List<Phase0aEnemyIntentObservation> observations = [];

  @override
  void observe(Phase0aEnemyIntentObservation observation) {
    observations.add(observation);
  }
}

/// Phase 0A 生产 flow 装配器红测(第六批派单 §必测证伪点):
/// ① 两波真实穿透(装配器→工厂→adapter→session→wave flow),与 direct
///    `calculateResolved` 同 seed 连续序列逐击同值;含「第二波重置 RNG」
///    反例对照,实现若按波重置本测必红;
/// ② missing/extra actor、playerId mismatch、缺 basic/gather/clear 任一
///    binding 装配期 fail-fast 且 RNG 下一值等于未消费对照;
/// ③ null control-only 完整 binding 合法;外部 combatants/waves/bindings
///    mutation 不污染已装配 flow;
/// ④ 非零吸血经装配入口立即 fail-fast；guardian/vulnerability 由运行态处理。
void main() {
  setUp(() async {
    await loadTestGameRepository();
  });

  tearDown(GameRepository.resetForTest);

  NumbersConfig numbers() => GameRepository.instance.numbers;

  final basicSkill = const SkillDef(
    id: 'phase0a_asm_basic',
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
    id: 'phase0a_asm_other',
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
    CultivationLayer mainCultivationLayer = CultivationLayer.chuKui,
    RealmTier realmTier = RealmTier.xueTu,
    RealmLayer realmLayer = RealmLayer.ruMen,
    double defenseRate = 0.05,
    double evasionRate = 0.0,
    double criticalRate = 0.0,
    double attackPowerMultiplier = 1.0,
    double outputMultiplier = 1.0,
    Map<String, int> skillUses = const {},
    List<String> activeBuffs = const [],
    Map<TechniqueSchool, double> schoolDamageTakenMult = const {},
    double forgingPiercePct = 0.0,
    double forgingLifestealPct = 0.0,
    double? guardianWardMult,
    List<String> guardianDefIds = const [],
    double? vulnerabilityMult,
  }) {
    return testCombatantSnapshot(
      characterId: characterId,
      name: 'c$characterId',
      realmTier: realmTier,
      realmLayer: realmLayer,
      school: school,
      maxHp: 1000,
      internalForce: internalForce,
      maxQi: 100,
      speed: 100,
      criticalRate: criticalRate,
      evasionRate: evasionRate,
      defenseRate: defenseRate,
      totalEquipmentAttack: totalEquipmentAttack,
      mainCultivationLayer: mainCultivationLayer,
      skillUses: skillUses,
      activeBuffs: activeBuffs,
      attackPowerMultiplier: attackPowerMultiplier,
      outputMultiplier: outputMultiplier,
      schoolDamageTakenMult: schoolDamageTakenMult,
      forgingPiercePct: forgingPiercePct,
      forgingLifestealPct: forgingLifestealPct,
      guardianWardMult: guardianWardMult,
      guardianDefIds: guardianDefIds,
      vulnerabilityMult: vulnerabilityMult,
    );
  }

  /// 全场四个角色的生产快照源:玩家带 150 次普攻使用记录(熟练度非 1.0),
  /// 敌三各不同内力/装备/防御/暴击,保证逐击数值可区分。
  Map<String, CombatantSnapshot> defaultCharacters() => {
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
    'e3': makeCharacter(
      characterId: 4,
      school: TechniqueSchool.yinRou,
      internalForce: 500,
      totalEquipmentAttack: 100,
      defenseRate: 0.03,
      criticalRate: 0.75,
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

  /// e1 一滴血:首拍玩家普攻必收掉,第二波当拍进场。
  List<Phase0aActor> wave1Enemies() => [
    arenaActor(
      id: 'e1',
      side: Phase0aSide.enemy,
      position: const ArenaVector(50, 0),
      currentHealth: 1,
    ),
  ];

  List<Phase0aActor> wave2Enemies() => [
    arenaActor(
      id: 'e2',
      side: Phase0aSide.enemy,
      position: const ArenaVector(50, 0),
    ),
    arenaActor(
      id: 'e3',
      side: Phase0aSide.enemy,
      position: const ArenaVector(60, 0),
    ),
  ];

  List<Phase0aWave> defaultWaves() => [
    Phase0aWave(enemies: wave1Enemies()),
    Phase0aWave(enemies: wave2Enemies()),
  ];

  Phase0aArenaState defaultInitialState({
    List<Phase0aSkillSlot> skillSlots = const [],
  }) {
    return Phase0aArenaState(
      tick: 0,
      nextSeq: 1,
      player: arenaActor(
        id: 'player',
        side: Phase0aSide.player,
        position: const ArenaVector(0, 0),
      ),
      enemies: wave1Enemies(),
      skillSlots: skillSlots,
    );
  }

  Phase0aPlayerInputAdapter makePlayerAdapter({String playerId = 'player'}) {
    return Phase0aPlayerInputAdapter(
      playerId: playerId,
      attackRange: 120,
      attackHalfArcRadians: math.pi / 4,
      attackCooldownSeconds: 0.5,
      attackQiDelta: 0,
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
    );
  }

  Phase0aWaveBattleFlow assemble({
    Phase0aArenaState? initialState,
    List<Phase0aWave>? waves,
    List<Phase0aCombatantInput>? combatants,
    Map<Phase0aDamageKind, SkillDef?>? moveBindings,
    math.Random? rng,
    Phase0aPlayerInputAdapter? playerAdapter,
  }) {
    return Phase0aProductionFlowAssembler.assemble(
      initialState: initialState ?? defaultInitialState(),
      waves: waves ?? defaultWaves(),
      combatants: combatants ?? combatantsFrom(defaultCharacters()),
      moveBindings: moveBindings ?? fullBindings(),
      numbers: numbers(),
      rng: rng ?? math.Random(99),
      playerAdapter: playerAdapter ?? makePlayerAdapter(),
      enemyAiAdapter: makeEnemyAdapter(),
    );
  }

  // —— D07:动态遭遇装配 helper(沿 legacy 体例,roster actor 与快照分离)——
  /// player + e1 + e2 三个真实快照源(defaultCharacters 去掉 e3)。
  Map<String, CombatantSnapshot> encounterCharacters() {
    return defaultCharacters()..remove('e3');
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
  }) {
    return Phase0aEncounterRoster(
      director: director,
      playerId: 'player',
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

  Phase0aEncounterFlow assembleEncounter({
    Phase0aArenaState? initialState,
    SpawnDirector? director,
    Phase0aEncounterRoster? roster,
    List<Phase0aCombatantInput>? combatants,
    Map<Phase0aDamageKind, SkillDef?>? moveBindings,
    math.Random? rng,
    Phase0aPlayerInputAdapter? playerAdapter,
    Phase0aEnemyIntentObserver? enemyIntentObserver,
  }) {
    final resolvedDirector = director ?? encounterDirector();
    return Phase0aProductionFlowAssembler.assembleEncounter(
      initialState: initialState ?? encounterInitialState(),
      director: resolvedDirector,
      roster: roster ?? encounterRoster(resolvedDirector),
      combatants: combatants ?? combatantsFrom(encounterCharacters()),
      moveBindings: moveBindings ?? fullBindings(),
      numbers: numbers(),
      rng: rng ?? math.Random(99),
      playerAdapter: playerAdapter ?? makePlayerAdapter(),
      enemyAiAdapter: makeEnemyAdapter(),
      enemyIntentObserver: enemyIntentObserver,
    );
  }

  /// 同 seed 驱动 encounter flow 推进 [ticks] 拍,返回事件/flow/显式 rng
  /// (供终局后 RNG 零消费对照与 observer 不改 RNG 对照)。
  (List<Phase0aEvent>, Phase0aEncounterFlow, math.Random) runEncounterTicks(
    int seed,
    int ticks,
  ) {
    final rng = math.Random(seed);
    final flow = assembleEncounter(rng: rng);
    final events = <Phase0aEvent>[];
    for (var i = 0; i < ticks; i++) {
      events.addAll(
        flow.advance(
          deltaSeconds: 0.5,
          command: const Phase0aPlayerCommand(attack: true),
        ),
      );
    }
    return (events, flow, rng);
  }

  /// 同 seed 驱动带 observer 的 encounter flow 推进 [ticks] 拍。
  (List<Phase0aEvent>, Phase0aEncounterFlow, math.Random) runEncounterObserved(
    int seed,
    int ticks,
  ) {
    final rng = math.Random(seed);
    final flow = assembleEncounter(
      rng: rng,
      enemyIntentObserver: _CapturingObserver(),
    );
    final events = <Phase0aEvent>[];
    for (var i = 0; i < ticks; i++) {
      events.addAll(
        flow.advance(
          deltaSeconds: 0.5,
          command: const Phase0aPlayerCommand(attack: true),
        ),
      );
    }
    return (events, flow, rng);
  }

  /// 结构校验不得消费 RNG:失败后下一值仍等于同 seed 未消费对照首值。
  void expectRngUntouched(math.Random rng, int seed) {
    expect(
      rng.nextDouble(),
      math.Random(seed).nextDouble(),
      reason: '装配期结构校验/fail-fast 不得消费 RNG',
    );
  }

  /// direct 对照:与 adapter 冻结映射逐项同口径(内力/装备/修炼/流派/境界/
  /// 防闪暴/双乘子/破甲/弱点表),熟练度经同一 SkillProficiency 调用复算。
  (int, bool) directResolve({
    required CombatantSnapshot attacker,
    required CombatantSnapshot defender,
    required math.Random rng,
  }) {
    final cfg = numbers().skillProficiency;
    final uses = attacker.skillUses[basicSkill.id] ?? 0;
    final perSkillPct =
        basicSkill.proficiency?.damagePctAt(
          SkillProficiency.stageFor(uses, cfg).id,
        ) ??
        0.0;
    final profMult = SkillProficiency.combinedMult(uses, perSkillPct, cfg);
    final result = DamageCalculator.calculateResolved(
      attackerInternalForce: attacker.internalForce,
      attackerEquipmentAttack: attacker.totalEquipmentAttack,
      attackerCultivationLayer: attacker.mainCultivationLayer,
      attackerSchool: attacker.school,
      defenderSchool: defender.school,
      attackerRealmTier: attacker.realmTier,
      attackerRealmLayer: attacker.realmLayer,
      defenderRealmTier: defender.realmTier,
      defenderRealmLayer: defender.realmLayer,
      defenderDefenseRate: defender.defenseRate,
      defenderEvasionRate: defender.evasionRate,
      attackerCriticalRate: attacker.criticalRate,
      attackPowerMultiplier: attacker.attackPowerMultiplier,
      skill: basicSkill,
      n: numbers(),
      rng: rng,
      proficiencyDamageMult: profMult,
      defenderCritDamageTakenMult: 1.0,
      outputMultiplier: attacker.outputMultiplier,
      defenderSchoolDamageMult:
          defender.schoolDamageTakenMult[attacker.school] ?? 1.0,
      defenderWardMult: 1.0,
      attackerPiercePct: attacker.forgingPiercePct,
      attackerLifestealPct: 0.0,
    );
    return (result.finalDamage, result.isCritical);
  }

  group('两波穿透:同 seed 连续序列逐击同值,第二波不重置 RNG', () {
    /// 固定结构(全场闪避 0 → 每次 resolve 必产 hit 事件,事件序即结算序):
    /// tick1 = [e1→player, player→e1(击杀,换波)],tick2..5 各 =
    /// [e2→player, e3→player, player→目标];两波各 ≥2 次随机判定命中。
    (List<Phase0aEvent>, Phase0aWaveBattleFlow) runFiveTicks(int seed) {
      final flow = assemble(rng: math.Random(seed));
      final events = <Phase0aEvent>[];
      for (var i = 0; i < 5; i++) {
        events.addAll(
          flow.advance(
            deltaSeconds: 0.5,
            command: const Phase0aPlayerCommand(attack: true),
          ),
        );
      }
      return (events, flow);
    }

    test('两波 14 击与同 seed direct 连续序列逐击同值,重置反例可判别', () {
      const seed = 42;
      final characters = defaultCharacters();
      final (events, flow) = runFiveTicks(seed);

      // 波次事件骨架:首波 started → e1 死亡拍 cleared(1)→started(2)。
      expect(events.first, isA<Phase0aWaveStarted>());
      expect((events.first as Phase0aWaveStarted).waveIndex, 1);
      final cleared = events.whereType<Phase0aWaveCleared>().single;
      expect(cleared.waveIndex, 1);
      final started = events.whereType<Phase0aWaveStarted>().toList();
      expect(started.map((e) => e.waveIndex), [1, 2]);
      // e2/e3 满血存活,5 拍后仍在第二波(未终局)。
      expect(flow.outcome, Phase0aBattleOutcome.ongoing);
      expect(flow.state.enemies.map((e) => e.id), ['e2', 'e3']);

      final hits = events.whereType<Phase0aHitLanded>().toList();
      final expectedActors = <String>[
        'e1',
        'player',
        for (var i = 0; i < 4; i++) ...['e2', 'e3', 'player'],
      ];
      expect(
        hits.map((h) => h.actor).toList(),
        expectedActors,
        reason: '两波命中序结构:wave1 两击 + wave2 每拍三击',
      );
      expect(hits[1].target, 'e1');

      // 连续序列:同 seed 单条 RNG 流按事件序复算,逐击同值(damage+crit)。
      final directRng = math.Random(seed);
      for (final hit in hits) {
        final expected = directResolve(
          attacker: characters[hit.actor]!,
          defender: characters[hit.target]!,
          rng: directRng,
        );
        expect(
          (hit.resolvedDamage, hit.isCritical),
          expected,
          reason:
              '${hit.actor}→${hit.target} @tick${hit.tick} 须等于 '
              'direct 连续序列',
        );
      }

      // 重置反例:若实现按波重建 RNG,第二波命中序列必等于「同 seed 新流」
      // 复算结果;两者实测不同 → 本测试对「第二波重置 RNG」具有判别力。
      final wave2Hits = hits.sublist(2);
      expect(wave2Hits, hasLength(12));
      final wave2Actual = [
        for (final hit in wave2Hits) (hit.resolvedDamage, hit.isCritical),
      ];
      final resetRng = math.Random(seed);
      final resetExpected = [
        for (final hit in wave2Hits)
          directResolve(
            attacker: characters[hit.actor]!,
            defender: characters[hit.target]!,
            rng: resetRng,
          ),
      ];
      expect(
        wave2Actual,
        isNot(equals(resetExpected)),
        reason: '第二波实测序列与「重置 RNG」假设序列必须不同,否则本测试无判别力',
      );
      // 暴击流确实参与判定:第二波命中伤害不止一个取值。
      expect(
        wave2Actual.map((hit) => hit.$1).toSet().length,
        greaterThan(1),
        reason: '第二波命中须含随机判定分支(暴击与否改变伤害)',
      );
    });

    test('同 seed 两装配实例回放:事件/state/outcome 全等', () {
      final (eventsA, flowA) = runFiveTicks(7);
      final (eventsB, flowB) = runFiveTicks(7);
      expect(eventsB, eventsA);
      expect(flowB.state, flowA.state);
      expect(flowB.outcome, flowA.outcome);
    });
  });

  group('端到端唯一终局与终局后零 RNG 消费', () {
    /// 第二波双敌各一滴血:玩家每拍收一个,tick3 末敌死亡直达胜利。
    List<Phase0aWave> lowHpWaves() => [
      Phase0aWave(enemies: wave1Enemies()),
      Phase0aWave(
        enemies: [
          arenaActor(
            id: 'e2',
            side: Phase0aSide.enemy,
            position: const ArenaVector(50, 0),
            currentHealth: 1,
          ),
          arenaActor(
            id: 'e3',
            side: Phase0aSide.enemy,
            position: const ArenaVector(60, 0),
            currentHealth: 1,
          ),
        ],
      ),
    ];

    (List<Phase0aEvent>, Phase0aWaveBattleFlow, math.Random) runToVictory(
      int seed,
    ) {
      final rng = math.Random(seed);
      final flow = assemble(waves: lowHpWaves(), rng: rng);
      final events = <Phase0aEvent>[];
      var guard = 0;
      while (flow.outcome == Phase0aBattleOutcome.ongoing && guard < 20) {
        events.addAll(
          flow.advance(
            deltaSeconds: 0.5,
            command: const Phase0aPlayerCommand(attack: true),
          ),
        );
        guard++;
      }
      return (events, flow, rng);
    }

    test('清空第二波:唯一 victory 紧邻末波 cleared,终局幂等且 RNG 零消费', () {
      const seed = 13;
      final (eventsA, flowA, rngA) = runToVictory(seed);
      expect(flowA.outcome, Phase0aBattleOutcome.victory);
      expect(flowA.state.enemies, isEmpty);

      // 全场唯一终局:victory 恰一条且为最后一个事件,无 defeat。
      expect(eventsA.whereType<Phase0aBattleVictory>(), hasLength(1));
      expect(eventsA.last, isA<Phase0aBattleVictory>());
      expect(eventsA.whereType<Phase0aBattleDefeat>(), isEmpty);

      // 末波 cleared 紧邻 victory:同拍、seq 相邻、各自 1-based 波序完整。
      final cleared = eventsA.whereType<Phase0aWaveCleared>().toList();
      expect(cleared.map((e) => e.waveIndex), [1, 2]);
      expect(eventsA.last.tick, cleared.last.tick);
      expect(eventsA.last.seq, cleared.last.seq + 1);

      // 终局后两次 advance 完全幂等:空事件、state/tick/seq/outcome 不变。
      final terminalState = flowA.state;
      for (var i = 0; i < 2; i++) {
        expect(
          flowA.advance(
            deltaSeconds: 0.5,
            command: const Phase0aPlayerCommand(attack: true, gather: true),
          ),
          isEmpty,
        );
      }
      expect(flowA.state, terminalState);
      expect(flowA.state.tick, terminalState.tick);
      expect(flowA.state.nextSeq, terminalState.nextSeq);
      expect(flowA.outcome, Phase0aBattleOutcome.victory);

      // 终局后零 RNG 消费:flowA 终局后又空转两拍,其显式 rng 下一值必须
      // 等于同 seed 对照流「跑到终局即取」的下一值;两流事件/state 全等
      // 保证此前消费序列一致,故相等 ⇔ 终局后空转拍未消费 RNG。
      final (eventsB, flowB, rngB) = runToVictory(seed);
      expect(eventsB, eventsA);
      expect(flowB.state, terminalState);
      expect(rngA.nextDouble(), rngB.nextDouble());
    });
  });

  group('启动期结构校验:fail-fast 且零 RNG 消费', () {
    test('missing actor:错误信息列稳定排序 id,RNG 未消费', () {
      const seed = 3;
      final rng = math.Random(seed);
      final missing = defaultCharacters()..remove('e2');
      expect(
        () => assemble(combatants: combatantsFrom(missing), rng: rng),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('missing=[e2]'),
          ),
        ),
      );
      expectRngUntouched(rng, seed);
    });

    test('extra actor:多余 id 稳定排序列出,RNG 未消费', () {
      const seed = 4;
      final rng = math.Random(seed);
      final extra = defaultCharacters()
        ..['a9'] = makeCharacter(characterId: 9)
        ..['z1'] = makeCharacter(characterId: 10);
      expect(
        () => assemble(combatants: combatantsFrom(extra), rng: rng),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('extra=[a9, z1]'),
          ),
        ),
      );
      expectRngUntouched(rng, seed);
    });

    test('playerAdapter.playerId 与首态玩家不一致 fail-fast,RNG 未消费', () {
      const seed = 5;
      final rng = math.Random(seed);
      expect(
        () => assemble(
          rng: rng,
          playerAdapter: makePlayerAdapter(playerId: 'other'),
        ),
        throwsArgumentError,
      );
      expectRngUntouched(rng, seed);
    });

    test('缺 basic/gather/clear 任一 binding 均 fail-fast,RNG 未消费', () {
      for (final (kind, bindings) in [
        (
          Phase0aDamageKind.basic,
          <Phase0aDamageKind, SkillDef?>{
            Phase0aDamageKind.gather: null,
            Phase0aDamageKind.clear: null,
          },
        ),
        (
          Phase0aDamageKind.gather,
          <Phase0aDamageKind, SkillDef?>{
            Phase0aDamageKind.basic: basicSkill,
            Phase0aDamageKind.clear: null,
          },
        ),
        (
          Phase0aDamageKind.clear,
          <Phase0aDamageKind, SkillDef?>{
            Phase0aDamageKind.basic: basicSkill,
            Phase0aDamageKind.gather: null,
          },
        ),
      ]) {
        const seed = 6;
        final rng = math.Random(seed);
        expect(
          () => assemble(moveBindings: bindings, rng: rng),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains(kind.name),
            ),
          ),
          reason: '缺 ${kind.name} binding 必须 fail-fast',
        );
        expectRngUntouched(rng, seed);
      }
    });
  });

  group('合法装配与防御性副本', () {
    test('null control-only 完整 binding 合法,gather 经装配链路零伤害', () {
      const gatherSlots = [
        Phase0aSkillSlot(
          slot: 'gather',
          cooldownRemaining: 0,
          qiCost: 20,
          availability: Phase0aSkillAvailability.ready,
        ),
      ];
      final flow = assemble(
        initialState: defaultInitialState(skillSlots: gatherSlots),
      );
      final events = flow.advance(
        deltaSeconds: 0.5,
        command: const Phase0aPlayerCommand(gather: true),
      );
      final applied = events.whereType<Phase0aGatherApplied>().single;
      expect(applied.outcomes, isNotEmpty);
      for (final outcome in applied.outcomes) {
        expect(outcome.resolvedDamage, 0);
      }
      // 真实伤害链路同场仍工作:e1 普攻命中玩家。
      expect(
        events.whereType<Phase0aHitLanded>().any((h) => h.actor == 'e1'),
        isTrue,
      );
    });

    test('外部 combatants/waves/moveBindings 装配后 mutation 不污染 flow', () {
      const seed = 11;
      final characters = defaultCharacters();
      final combatants = combatantsFrom(characters);
      final waves = defaultWaves();
      final bindings = fullBindings();
      final flowA = assemble(
        combatants: combatants,
        waves: waves,
        moveBindings: bindings,
        rng: math.Random(seed),
      );

      // 装配后污染外部容器:加 actor、加第三波、换 basic 技能。
      combatants.add(
        Phase0aCombatantInput(
          actorId: 'e9',
          snapshot: makeCharacter(characterId: 9),
        ),
      );
      waves.add(
        Phase0aWave(
          enemies: [
            arenaActor(
              id: 'e8',
              side: Phase0aSide.enemy,
              position: const ArenaVector(80, 0),
            ),
          ],
        ),
      );
      bindings[Phase0aDamageKind.basic] = otherSkill;

      final flowB = assemble(rng: math.Random(seed));
      expect(flowA.waves, hasLength(2));
      final eventsA = <Phase0aEvent>[];
      final eventsB = <Phase0aEvent>[];
      for (var i = 0; i < 3; i++) {
        const command = Phase0aPlayerCommand(attack: true);
        eventsA.addAll(flowA.advance(deltaSeconds: 0.5, command: command));
        eventsB.addAll(flowB.advance(deltaSeconds: 0.5, command: command));
      }
      expect(eventsA, eventsB);
      expect(flowA.state, flowB.state);
      expect(flowA.outcome, flowB.outcome);
    });

    test('非零吸血经装配入口立即 fail-fast,RNG 未消费', () {
      const seed = 8;
      final rng = math.Random(seed);
      final characters = defaultCharacters();
      characters['e1'] = makeCharacter(forgingLifestealPct: 0.05);
      expect(
        () => assemble(combatants: combatantsFrom(characters), rng: rng),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', contains('吸血')),
        ),
      );
      expectRngUntouched(rng, seed);
    });

    test('脆弱窗口经装配入口支持:不再构造期拒绝(2026-08-22)', () {
      // 窗口开合是运行态事实(蓄招/踉跄),由结算期折入;装配只冻结乘子,
      // 乘子进快照的逐项断言在快照工厂测。此处钉装配入口翻转为放行。
      const seed = 8;
      final rng = math.Random(seed);
      final characters = defaultCharacters();
      characters['e1'] = makeCharacter(vulnerabilityMult: 0.4);
      expect(
        () => assemble(combatants: combatantsFrom(characters), rng: rng),
        returnsNormally,
      );
    });
  });

  group('D07 encounter:actor 覆盖与装配校验 fail-fast 且零 RNG 消费', () {
    test('missing actor:错误信息列稳定排序 id,RNG 未消费', () {
      const seed = 23;
      final rng = math.Random(seed);
      final missing = encounterCharacters()..remove('e2');
      expect(
        () => assembleEncounter(combatants: combatantsFrom(missing), rng: rng),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('missing=[e2]'),
          ),
        ),
      );
      expectRngUntouched(rng, seed);
    });

    test('extra actor:多余 id 稳定排序列出,RNG 未消费', () {
      const seed = 24;
      final rng = math.Random(seed);
      final extra = encounterCharacters()
        ..['a9'] = makeCharacter(characterId: 9)
        ..['z1'] = makeCharacter(characterId: 10);
      expect(
        () => assembleEncounter(combatants: combatantsFrom(extra), rng: rng),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('extra=[a9, z1]'),
          ),
        ),
      );
      expectRngUntouched(rng, seed);
    });

    test('playerAdapter.playerId 与首态玩家不一致 fail-fast,RNG 未消费', () {
      const seed = 25;
      final rng = math.Random(seed);
      expect(
        () => assembleEncounter(
          rng: rng,
          playerAdapter: makePlayerAdapter(playerId: 'other'),
        ),
        throwsArgumentError,
      );
      expectRngUntouched(rng, seed);
    });

    test('缺 basic/gather/clear 任一 binding 均 fail-fast,RNG 未消费', () {
      for (final (kind, bindings) in [
        (
          Phase0aDamageKind.basic,
          <Phase0aDamageKind, SkillDef?>{
            Phase0aDamageKind.gather: null,
            Phase0aDamageKind.clear: null,
          },
        ),
        (
          Phase0aDamageKind.gather,
          <Phase0aDamageKind, SkillDef?>{
            Phase0aDamageKind.basic: basicSkill,
            Phase0aDamageKind.clear: null,
          },
        ),
        (
          Phase0aDamageKind.clear,
          <Phase0aDamageKind, SkillDef?>{
            Phase0aDamageKind.basic: basicSkill,
            Phase0aDamageKind.gather: null,
          },
        ),
      ]) {
        const seed = 26;
        final rng = math.Random(seed);
        expect(
          () => assembleEncounter(moveBindings: bindings, rng: rng),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains(kind.name),
            ),
          ),
          reason: '缺 ${kind.name} binding 必须 fail-fast',
        );
        expectRngUntouched(rng, seed);
      }
    });

    test('runtime 校验穿透:roster 与 director 非同一实例即拒绝,RNG 未消费', () {
      const seed = 27;
      final rng = math.Random(seed);
      final director = encounterDirector();
      final otherDirector = encounterDirector();
      expect(
        () => Phase0aProductionFlowAssembler.assembleEncounter(
          initialState: encounterInitialState(),
          director: otherDirector,
          roster: encounterRoster(director),
          combatants: combatantsFrom(encounterCharacters()),
          moveBindings: fullBindings(),
          numbers: numbers(),
          rng: rng,
          playerAdapter: makePlayerAdapter(),
          enemyAiAdapter: makeEnemyAdapter(),
        ),
        throwsArgumentError,
      );
      expectRngUntouched(rng, seed);
    });

    test('initialState 敌人与 director active 不一致由 runtime 拒绝,RNG 未消费', () {
      const seed = 28;
      final rng = math.Random(seed);
      final director = encounterDirector();
      final inconsistent = Phase0aArenaState(
        tick: 0,
        nextSeq: 1,
        player: arenaActor(
          id: 'player',
          side: Phase0aSide.player,
          position: ArenaVector.zero,
        ),
        enemies: [
          arenaActor(
            id: 'e1',
            side: Phase0aSide.enemy,
            position: const ArenaVector(50, 0),
          ),
        ],
        skillSlots: const [],
      );
      expect(
        () => Phase0aProductionFlowAssembler.assembleEncounter(
          initialState: inconsistent,
          director: director,
          roster: encounterRoster(director),
          combatants: combatantsFrom(encounterCharacters()),
          moveBindings: fullBindings(),
          numbers: numbers(),
          rng: rng,
          playerAdapter: makePlayerAdapter(),
          enemyAiAdapter: makeEnemyAdapter(),
        ),
        throwsArgumentError,
      );
      expectRngUntouched(rng, seed);
    });
  });

  group('D07 encounter:真实伤害穿透与同 seed direct 连续序列逐击同值', () {
    test('三拍 9 击逐击同值,按拍/按敌重置 RNG 反例可判别', () {
      const seed = 42;
      final (events, flow, _) = runEncounterTicks(seed, 3);

      // 事件骨架:首拍两敌同时进场(activeLimit 2 / 无 warning / 无 grace)。
      expect(
        events.whereType<Phase0aEnemyEntered>().map((e) => e.enemyId).toList(),
        ['e1', 'e2'],
      );
      expect(events.whereType<Phase0aSpawnWarningStarted>(), isEmpty);
      expect(events.whereType<Phase0aSpawnGraceExpired>(), isEmpty);
      expect(flow.outcome, Phase0aBattleOutcome.ongoing);
      expect(flow.state.enemies.map((e) => e.id), ['e1', 'e2']);

      final hits = events.whereType<Phase0aHitLanded>().toList();
      expect(hits, hasLength(9), reason: '三拍×每拍 player/e1/e2 各一击');

      // 连续序列:同 seed 单条 RNG 流按事件序复算,逐击同值(damage+crit)。
      final characters = encounterCharacters();
      final directRng = math.Random(seed);
      for (final hit in hits) {
        final expected = directResolve(
          attacker: characters[hit.actor]!,
          defender: characters[hit.target]!,
          rng: directRng,
        );
        expect(
          (hit.resolvedDamage, hit.isCritical),
          expected,
          reason: '${hit.actor}→${hit.target} @tick${hit.tick} 须等于 direct 连续序列',
        );
      }

      // 重置反例:若实现按拍/按敌重建 RNG,后两拍命中序列必等于「同 seed
      // 新流从头复算」;实测不同 → 本测试对「RNG 跨敌跨拍连续」有判别力。
      final lateHits = hits.where((h) => h.tick >= 2).toList();
      expect(lateHits, isNotEmpty);
      final lateActual = [
        for (final h in lateHits) (h.resolvedDamage, h.isCritical),
      ];
      final resetRng = math.Random(seed);
      final resetExpected = [
        for (final h in lateHits)
          directResolve(
            attacker: characters[h.actor]!,
            defender: characters[h.target]!,
            rng: resetRng,
          ),
      ];
      expect(
        lateActual,
        isNot(equals(resetExpected)),
        reason: '「按拍/按敌重置 RNG」假设序列必须与实测不同,否则本测试无判别力',
      );
      // 随机分支确实参与:命中伤害不止一个取值。
      expect(
        hits.map((h) => h.resolvedDamage).toSet().length,
        greaterThan(1),
        reason: '命中须含随机判定分支(暴击与否改变伤害)',
      );
    });

    test('同 seed 两装配实例回放:事件/state/outcome 全等', () {
      final (eventsA, flowA, _) = runEncounterTicks(7, 3);
      final (eventsB, flowB, _) = runEncounterTicks(7, 3);
      expect(eventsB, eventsA);
      expect(flowB.state, flowA.state);
      expect(flowB.outcome, flowA.outcome);
    });
  });

  group('D07 encounter:完整生命周期经 assembler 入口完成', () {
    test('warning→entry→grace→kill→reinforcement→terminal 全链', () {
      // 低血敌人:玩家一击必杀;activeLimit 1 + warning 1 + grace 1 逐敌补入。
      // e1/e2 各 1 HP → 上场当拍被秒;grace 语义由「上场当拍玩家不掉血」
      // 断言钉死(敌人攻击 intent 被 gate 过滤)。
      final director = encounterDirector(
        activeLimit: 1,
        entryWarningTicks: 1,
        attackGraceTicks: 1,
      );
      final rng = math.Random(13);
      final flow = Phase0aProductionFlowAssembler.assembleEncounter(
        initialState: encounterInitialState(),
        director: director,
        roster: encounterRoster(director, e1Health: 1, e2Health: 1),
        combatants: combatantsFrom(encounterCharacters()),
        moveBindings: fullBindings(),
        numbers: numbers(),
        rng: rng,
        playerAdapter: makePlayerAdapter(),
        enemyAiAdapter: makeEnemyAdapter(),
      );

      final allEvents = <Phase0aEvent>[];
      var guard = 0;
      while (flow.outcome == Phase0aBattleOutcome.ongoing && guard < 10) {
        allEvents.addAll(
          flow.advance(
            deltaSeconds: 0.5,
            command: const Phase0aPlayerCommand(attack: true),
          ),
        );
        guard++;
      }

      expect(flow.outcome, Phase0aBattleOutcome.victory);
      expect(flow.state.enemies, isEmpty);
      // warning→entry→kill 骨架(按敌序):
      final warnings = allEvents
          .whereType<Phase0aSpawnWarningStarted>()
          .map((e) => e.enemyId)
          .toList();
      expect(warnings, ['e1', 'e2']);
      final entered = allEvents
          .whereType<Phase0aEnemyEntered>()
          .map((e) => e.enemyId)
          .toList();
      expect(entered, ['e1', 'e2']);
      final defeated = allEvents
          .whereType<Phase0aEnemyDefeated>()
          .map((e) => e.target)
          .toList();
      expect(defeated, ['e1', 'e2']);
      // 唯一终局 + 严格递增连续 seq:
      expect(allEvents.whereType<Phase0aBattleVictory>(), hasLength(1));
      expect(allEvents.last, isA<Phase0aBattleVictory>());
      expect(allEvents.whereType<Phase0aBattleDefeat>(), isEmpty);
      final seqs = allEvents.map((e) => e.seq).toList();
      for (var i = 1; i < seqs.length; i++) {
        expect(seqs[i], greaterThan(seqs[i - 1]));
      }
      // grace gate 生效:敌人上场当拍(宽限内)攻击被过滤,玩家整场不掉血。
      expect(flow.state.player.currentHealth, 100000);
    });
  });

  group('D07 encounter:observe-only observer 只观察 grace gate 后 intents', () {
    test('宽限期内攻击被过滤为空观察,到期当拍放行攻击', () {
      final observer = _CapturingObserver();
      final director = encounterDirector(
        activeLimit: 1,
        entryWarningTicks: 0,
        attackGraceTicks: 1,
      );
      final flow = Phase0aProductionFlowAssembler.assembleEncounter(
        initialState: encounterInitialState(),
        director: director,
        roster: encounterRoster(director),
        combatants: combatantsFrom(encounterCharacters()),
        moveBindings: fullBindings(),
        numbers: numbers(),
        rng: math.Random(31),
        playerAdapter: makePlayerAdapter(),
        enemyAiAdapter: makeEnemyAdapter(),
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
      // 观察快照只读:observe-only 边界。
      expect(
        () => secondObservation.add(
          const Phase0aMoveIntent(actorId: 'e9', direction: ArenaVector(1, 0)),
        ),
        throwsUnsupportedError,
      );
    });

    test('连续多拍跨击杀/补员存活,每拍都观察 gate 后列表', () {
      final observer = _CapturingObserver();
      final director = encounterDirector(
        activeLimit: 1,
        entryWarningTicks: 0,
        attackGraceTicks: 1,
      );
      final flow = Phase0aProductionFlowAssembler.assembleEncounter(
        initialState: encounterInitialState(),
        director: director,
        roster: encounterRoster(director, e1Health: 1, e2Health: 1),
        combatants: combatantsFrom(encounterCharacters()),
        moveBindings: fullBindings(),
        numbers: numbers(),
        rng: math.Random(37),
        playerAdapter: makePlayerAdapter(),
        enemyAiAdapter: makeEnemyAdapter(),
        enemyIntentObserver: observer,
      );

      final allEvents = <Phase0aEvent>[];
      var guard = 0;
      while (flow.outcome == Phase0aBattleOutcome.ongoing && guard < 10) {
        allEvents.addAll(
          flow.advance(
            deltaSeconds: 0.5,
            command: const Phase0aPlayerCommand(attack: true),
          ),
        );
        guard++;
      }
      expect(flow.outcome, Phase0aBattleOutcome.victory);
      // 有敌人的 combat 拍观察器每拍都被调用;敌人均在宽限内被秒 →
      // 观察列表恒为空(gate 过滤后交付),观察器跨击杀/补员存活不丢。
      expect(observer.observations, isNotEmpty);
      for (final observation in observer.observations) {
        expect(observation.enemyIntents, isEmpty);
      }
    });

    test('observer 不改 events/state/RNG:同 seed 有/无观察器全等', () {
      const seed = 43;
      final (eventsA, flowA, rngA) = runEncounterTicks(seed, 3);
      final (eventsB, flowB, rngB) = runEncounterObserved(seed, 3);
      expect(eventsB, eventsA);
      expect(flowB.state, flowA.state);
      expect(flowB.outcome, flowA.outcome);
      // 消费序列一致 → 后续 RNG 值相等(observer 不消费也不改 RNG)。
      expect(rngA.nextDouble(), rngB.nextDouble());
    });
  });
}
