import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_production_flow_assembler.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_wave_battle_flow.dart';
import 'package:wuxia_idle/features/combat_shared/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_wave.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_proficiency.dart';
import 'package:wuxia_idle/shared/battle_shared/combatant_snapshot.dart';
import '../../../../support/combatant_snapshot_fixture.dart';
import '../../../../support/test_data.dart';

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
}
