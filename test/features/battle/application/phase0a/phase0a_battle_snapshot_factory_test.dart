import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_battle_snapshot_factory.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_combat_session.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_damage_calculator_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
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

/// Phase 0A 中立 CombatantSnapshot 生产快照工厂红测(第五批派单 §必测):
/// ① 稳定字段与 `_calculateInBattle` 口径逐项同值;凝甲/弱点/破甲精确;
/// ② 熟练度只复用 SkillProficiency(多 bound skill / 无使用记录 1.0 /
///    null control-only 不产条目);
/// ③ 重复/空 actorId、外部 mutation、非零吸血与 guardian
///    构造期 fail-fast(动态机制禁止冻结成中性常量);脆弱窗口乘子构造期
///    支持(窗口开合由结算期运行态折入,2026-08-22 纵切);
/// ④ 工厂 → Phase0aDamageCalculatorAdapter → Phase0aWaveBattleFlow →
///    session/reducer 真实穿透,与 direct `calculateResolved` 同 seed 同值。
void main() {
  setUp(() async {
    await loadTestGameRepository();
  });

  tearDown(GameRepository.resetForTest);

  NumbersConfig numbers() => GameRepository.instance.numbers;

  Phase0aBattleSnapshotFactory makeFactory() =>
      Phase0aBattleSnapshotFactory(numbers: numbers());

  const basicSkill = SkillDef(
    id: 'phase0a_test_basic',
    name: 'basic',
    description: 'basic',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    qiDelta: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: '',
  );

  final profSkillA = const SkillDef(
    id: 'phase0a_test_prof_a',
    name: 'profA',
    description: 'profA',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    qiDelta: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: '',
    proficiency: SkillProficiencyEffects({'shuLian': 0.10}, {}, {}, {}),
  );

  final profSkillB = const SkillDef(
    id: 'phase0a_test_prof_b',
    name: 'profB',
    description: 'profB',
    type: SkillType.powerSkill,
    powerMultiplier: 1500,
    qiDelta: -20,
    cooldownTurns: 3,
    requiresManualTrigger: false,
    visualEffect: '',
    proficiency: SkillProficiencyEffects({'huaJing': 0.20}, {}, {}, {}),
  );

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

  Phase0aCombatantInput input(String actorId, CombatantSnapshot character) =>
      Phase0aCombatantInput(actorId: actorId, snapshot: character);

  group('稳定字段逐项映射(与 _calculateInBattle 口径同值)', () {
    test('永久内力/装备攻击/修炼层/流派/境界/防闪暴/双乘子/破甲逐项同值', () {
      final bundle = makeFactory().create(
        combatants: [
          input(
            'attacker',
            makeCharacter(
              internalForce: 777,
              totalEquipmentAttack: 234,
              mainCultivationLayer: CultivationLayer.zhongCheng,
              school: TechniqueSchool.lingQiao,
              realmTier: RealmTier.erLiu,
              realmLayer: RealmLayer.shuLian,
              defenseRate: 0.21,
              evasionRate: 0.07,
              criticalRate: 0.09,
              attackPowerMultiplier: 1.15,
              outputMultiplier: 0.8,
              forgingPiercePct: 0.12,
            ),
          ),
        ],
        moveBindings: const {Phase0aDamageKind.basic: basicSkill},
      );
      final s = bundle.combatants['attacker']!;
      expect(s.internalForce, 777);
      expect(s.equipmentAttack, 234);
      expect(s.cultivationLayer, CultivationLayer.zhongCheng);
      expect(s.school, TechniqueSchool.lingQiao);
      expect(s.realmTier, RealmTier.erLiu);
      expect(s.realmLayer, RealmLayer.shuLian);
      expect(s.defenseRate, 0.21);
      expect(s.evasionRate, 0.07);
      expect(s.criticalRate, 0.09);
      expect(s.attackPowerMultiplier, 1.15);
      expect(s.outputMultiplier, 0.8);
      expect(s.piercePct, 0.12);
      expect(s.lifestealPct, 0.0);
      expect(s.wardMult, 1.0);
    });

    test('凝甲词条映射 numbers 承伤乘子,无词条为中性 1.0', () {
      final ningjiaMult =
          numbers().cycleEvolution.traits.ningjia.critDamageTakenMult;
      final bundle = makeFactory().create(
        combatants: [
          input('ningjia', makeCharacter(activeBuffs: const ['cycle_ningjia'])),
          input('plain', makeCharacter(characterId: 2)),
        ],
        moveBindings: const {Phase0aDamageKind.basic: basicSkill},
      );
      expect(bundle.combatants['ningjia']!.critDamageTakenMult, ningjiaMult);
      expect(bundle.combatants['plain']!.critDamageTakenMult, 1.0);
    });

    test('弱点/抗性表透传且为防御副本,外部 mutation 不污染快照', () {
      final weakness = <TechniqueSchool, double>{
        TechniqueSchool.gangMeng: 1.25,
        TechniqueSchool.yinRou: 0.8,
      };
      final bundle = makeFactory().create(
        combatants: [
          input('defender', makeCharacter(schoolDamageTakenMult: weakness)),
        ],
        moveBindings: const {Phase0aDamageKind.basic: basicSkill},
      );
      // 构造后污染外部 map。
      weakness[TechniqueSchool.gangMeng] = 9.9;
      weakness[TechniqueSchool.lingQiao] = 3.3;
      final s = bundle.combatants['defender']!;
      expect(s.schoolDamageTakenMults, hasLength(2));
      expect(s.schoolDamageTakenMults[TechniqueSchool.gangMeng], 1.25);
      expect(s.schoolDamageTakenMults[TechniqueSchool.yinRou], 0.8);
      expect(
        () => s.schoolDamageTakenMults[TechniqueSchool.gangMeng] = 1.0,
        throwsUnsupportedError,
      );
    });

    test('skillUses 外部 map 构造后 mutation 不影响已解析熟练度', () {
      final uses = <String, int>{profSkillA.id: 150};
      final bundle = makeFactory().create(
        combatants: [input('attacker', makeCharacter(skillUses: uses))],
        moveBindings: {Phase0aDamageKind.basic: profSkillA},
      );
      uses[profSkillA.id] = 99999;
      expect(
        bundle.combatants['attacker']!.proficiencyDamageMults[profSkillA.id],
        SkillProficiency.combinedMult(
          150,
          profSkillA.proficiency!.damagePctAt(
            SkillProficiency.stageFor(150, numbers().skillProficiency).id,
          ),
          numbers().skillProficiency,
        ),
      );
    });
  });

  group('熟练度复用 SkillProficiency,不复制公式', () {
    test('多 bound skill 逐技能生成 per-skill 倍率(含 130% cap 路径)', () {
      final bundle = makeFactory().create(
        combatants: [
          input(
            'attacker',
            makeCharacter(skillUses: {profSkillA.id: 150, profSkillB.id: 900}),
          ),
        ],
        moveBindings: {
          Phase0aDamageKind.basic: profSkillA,
          Phase0aDamageKind.gather: profSkillB,
        },
      );
      final mults = bundle.combatants['attacker']!.proficiencyDamageMults;
      expect(mults.keys, unorderedEquals([profSkillA.id, profSkillB.id]));
      final cfg = numbers().skillProficiency;
      // A:uses 150 → shuLian 阶(1.12)×(1+0.10)。
      final expectedA = SkillProficiency.combinedMult(
        150,
        profSkillA.proficiency!.damagePctAt(
          SkillProficiency.stageFor(150, cfg).id,
        ),
        cfg,
      );
      expect(mults[profSkillA.id], expectedA);
      expect(mults[profSkillA.id], closeTo(1.12 * 1.1, 1e-9));
      // B:uses 900 → huaJing 阶(1.30)×(1+0.20) 超 cap → 收 1.30。
      final expectedB = SkillProficiency.combinedMult(
        900,
        profSkillB.proficiency!.damagePctAt(
          SkillProficiency.stageFor(900, cfg).id,
        ),
        cfg,
      );
      expect(mults[profSkillB.id], expectedB);
      expect(mults[profSkillB.id], closeTo(1.3, 1e-9));
    });

    test('无使用记录恰好 1.0(首阶 × 无 per-skill 增量)', () {
      final bundle = makeFactory().create(
        combatants: [input('attacker', makeCharacter())],
        moveBindings: {Phase0aDamageKind.basic: profSkillA},
      );
      expect(
        bundle.combatants['attacker']!.proficiencyDamageMults[profSkillA.id],
        1.0,
      );
    });

    test('null control-only binding 不产熟练度条目,工厂不猜技能', () {
      final bundle = makeFactory().create(
        combatants: [input('attacker', makeCharacter())],
        moveBindings: const {
          Phase0aDamageKind.basic: basicSkill,
          Phase0aDamageKind.gather: null,
          Phase0aDamageKind.clear: null,
        },
      );
      expect(bundle.combatants['attacker']!.proficiencyDamageMults.keys, [
        basicSkill.id,
      ]);
      expect(bundle.moveBindings[Phase0aDamageKind.gather], isNull);
      expect(
        bundle.moveBindings.containsKey(Phase0aDamageKind.gather),
        isTrue,
        reason: 'null control-only 与缺绑定必须可区分',
      );
    });
  });

  group('构造期 fail-fast 与防御性副本', () {
    test('空 actorId fail-fast', () {
      expect(() => input('', makeCharacter()), throwsArgumentError);
    });

    test('重复 actorId fail-fast', () {
      expect(
        () => makeFactory().create(
          combatants: [
            input('dup', makeCharacter()),
            input('dup', makeCharacter(characterId: 2)),
          ],
          moveBindings: const {Phase0aDamageKind.basic: basicSkill},
        ),
        throwsArgumentError,
      );
    });

    test('空 combatants 列表 fail-fast', () {
      expect(
        () => makeFactory().create(
          combatants: const [],
          moveBindings: const {Phase0aDamageKind.basic: basicSkill},
        ),
        throwsArgumentError,
      );
    });

    test('非零吸血构造期 fail-fast 且错误信息指明机制', () {
      expect(
        () => makeFactory().create(
          combatants: [
            input('attacker', makeCharacter(forgingLifestealPct: 0.05)),
          ],
          moveBindings: const {Phase0aDamageKind.basic: basicSkill},
        ),
        throwsA(
          isA<StateError>().having((e) => e.message, 'message', contains('吸血')),
        ),
      );
    });

    test('护法结界配置放行且静态 damage snapshot 保持中性 ward', () {
      final bundle = makeFactory().create(
        combatants: [
          input(
            'boss',
            makeCharacter(
              guardianWardMult: 0.5,
              guardianDefIds: const ['guard_a'],
            ),
          ),
        ],
        moveBindings: const {Phase0aDamageKind.basic: basicSkill},
      );
      expect(bundle.combatants['boss']!.wardMult, 1.0);
    });

    test('脆弱窗口 vulnerabilityMult 构造期支持:乘子原样进快照(2026-08-22)', () {
      // 窗口开合是运行态事实(蓄招/踉跄),由结算期折入,静态快照只承载乘子。
      final bundle = makeFactory().create(
        combatants: [input('boss', makeCharacter(vulnerabilityMult: 0.4))],
        moveBindings: const {Phase0aDamageKind.basic: basicSkill},
      );
      expect(bundle.combatants['boss']!.vulnerabilityOutMult, 0.4);
      // 无机制仍为 null(与 1.0 语义区分,保 fail-closed 可读性)。
      final neutral = makeFactory().create(
        combatants: [input('boss', makeCharacter())],
        moveBindings: const {Phase0aDamageKind.basic: basicSkill},
      );
      expect(neutral.combatants['boss']!.vulnerabilityOutMult, isNull);
    });

    test('外部 combatants 列表与 moveBindings map 构造后 mutation 不影响 bundle', () {
      final combatants = [input('attacker', makeCharacter())];
      final bindings = <Phase0aDamageKind, SkillDef?>{
        Phase0aDamageKind.basic: basicSkill,
      };
      final bundle = makeFactory().create(
        combatants: combatants,
        moveBindings: bindings,
      );
      combatants.add(input('e9', makeCharacter(characterId: 9)));
      bindings[Phase0aDamageKind.gather] = profSkillA;
      expect(bundle.combatants, hasLength(1));
      expect(bundle.moveBindings, hasLength(1));
      expect(
        () => bundle.combatants['x'] = bundle.combatants['attacker']!,
        throwsUnsupportedError,
      );
      expect(
        () => bundle.moveBindings[Phase0aDamageKind.clear] = null,
        throwsUnsupportedError,
      );
    });
  });

  group('穿透:工厂 → adapter → wave flow → session/reducer', () {
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

    /// 真实链路:工厂产 bundle → 既有 Phase0aDamageCalculatorAdapter →
    /// Phase0aWaveBattleFlow(内含 session → reducer)。
    Phase0aWaveBattleFlow makeProductionFlow({required int seed}) {
      final waveEnemies = [
        arenaActor(
          id: 'e1',
          side: Phase0aSide.enemy,
          position: const ArenaVector(50, 0),
          currentHealth: 1,
        ),
      ];
      final playerBc = makeCharacter(
        internalForce: 600,
        totalEquipmentAttack: 130,
        skillUses: {profSkillA.id: 150},
        forgingPiercePct: 0.1,
      );
      final enemyBc = makeCharacter(
        characterId: 2,
        school: TechniqueSchool.yinRou,
        internalForce: 400,
        totalEquipmentAttack: 90,
        realmLayer: RealmLayer.qiMeng,
        schoolDamageTakenMult: const {TechniqueSchool.gangMeng: 1.2},
        activeBuffs: const ['cycle_ningjia'],
      );
      final bundle = makeFactory().create(
        combatants: [input('player', playerBc), input('e1', enemyBc)],
        moveBindings: {
          Phase0aDamageKind.basic: profSkillA,
          Phase0aDamageKind.gather: null,
          Phase0aDamageKind.clear: null,
        },
      );
      return Phase0aWaveBattleFlow(
        session: Phase0aCombatSession(
          initialState: Phase0aArenaState(
            tick: 0,
            nextSeq: 1,
            player: arenaActor(
              id: 'player',
              side: Phase0aSide.player,
              position: const ArenaVector(0, 0),
            ),
            enemies: waveEnemies,
            skillSlots: const [],
          ),
          playerAdapter: const Phase0aPlayerInputAdapter(
            playerId: 'player',
            attackRange: 120,
            attackHalfArcRadians: math.pi / 4,
            attackCooldownSeconds: 1,
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
          ),
          enemyAiAdapter: const Phase0aEnemyAiAdapter(
            attackRange: 70,
            attackHalfArcRadians: math.pi / 3,
            attackCooldownSeconds: 1.2,
          ),
          damageResolver: Phase0aDamageCalculatorAdapter(
            combatants: bundle.combatants,
            moveBindings: bundle.moveBindings,
            numbers: numbers(),
            rng: math.Random(seed),
          ),
        ),
        waves: [Phase0aWave(enemies: waveEnemies)],
      );
    }

    test('单拍穿透:命中数值与 direct calculateResolved 同 seed 同值', () {
      const seed = 7;
      final flow = makeProductionFlow(seed: seed);
      final events = flow.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );

      expect(events.first, isA<Phase0aWaveStarted>());
      expect(events[events.length - 3], isA<Phase0aEnemyDefeated>());
      expect(events[events.length - 2], isA<Phase0aWaveCleared>());
      expect(events.last, isA<Phase0aBattleVictory>());

      // direct 对照:reducer intent 按 actorId 稳定排序,'e1' 先 'player' 后;
      // 熟练度按工厂同源 SkillProficiency 调用手算,凝甲/弱点/破甲逐项对应。
      final cfg = numbers().skillProficiency;
      final profMult = SkillProficiency.combinedMult(
        150,
        profSkillA.proficiency!.damagePctAt(
          SkillProficiency.stageFor(150, cfg).id,
        ),
        cfg,
      );
      final ningjiaMult =
          numbers().cycleEvolution.traits.ningjia.critDamageTakenMult;
      final directRng = math.Random(seed);
      final enemyDirect = DamageCalculator.calculateResolved(
        attackerInternalForce: 400,
        attackerEquipmentAttack: 90,
        attackerCultivationLayer: CultivationLayer.chuKui,
        attackerSchool: TechniqueSchool.yinRou,
        defenderSchool: TechniqueSchool.gangMeng,
        attackerRealmTier: RealmTier.xueTu,
        attackerRealmLayer: RealmLayer.qiMeng,
        defenderRealmTier: RealmTier.xueTu,
        defenderRealmLayer: RealmLayer.ruMen,
        defenderDefenseRate: 0.05,
        defenderEvasionRate: 0.0,
        attackerCriticalRate: 0.0,
        attackPowerMultiplier: 1.0,
        skill: profSkillA,
        n: numbers(),
        rng: directRng,
        proficiencyDamageMult: 1.0,
        defenderCritDamageTakenMult: 1.0,
        outputMultiplier: 1.0,
        defenderSchoolDamageMult: 1.0,
        defenderWardMult: 1.0,
        attackerPiercePct: 0.0,
        attackerLifestealPct: 0.0,
      );
      final playerDirect = DamageCalculator.calculateResolved(
        attackerInternalForce: 600,
        attackerEquipmentAttack: 130,
        attackerCultivationLayer: CultivationLayer.chuKui,
        attackerSchool: TechniqueSchool.gangMeng,
        defenderSchool: TechniqueSchool.yinRou,
        attackerRealmTier: RealmTier.xueTu,
        attackerRealmLayer: RealmLayer.ruMen,
        defenderRealmTier: RealmTier.xueTu,
        defenderRealmLayer: RealmLayer.qiMeng,
        defenderDefenseRate: 0.05,
        defenderEvasionRate: 0.0,
        attackerCriticalRate: 0.0,
        attackPowerMultiplier: 1.0,
        skill: profSkillA,
        n: numbers(),
        rng: directRng,
        proficiencyDamageMult: profMult,
        defenderCritDamageTakenMult: ningjiaMult,
        outputMultiplier: 1.0,
        defenderSchoolDamageMult: 1.2,
        defenderWardMult: 1.0,
        attackerPiercePct: 0.1,
        attackerLifestealPct: 0.0,
      );

      final hits = events.whereType<Phase0aHitLanded>().toList();
      final enemyHit = hits.singleWhere((h) => h.actor == 'e1');
      expect(enemyHit.resolvedDamage, enemyDirect.finalDamage);
      final playerHit = hits.singleWhere((h) => h.actor == 'player');
      expect(playerHit.resolvedDamage, playerDirect.finalDamage);
      expect(playerHit.resolvedDamage, greaterThan(0));
      expect(flow.state.player.currentHealth, 100000 - enemyDirect.finalDamage);
      expect(flow.outcome, Phase0aBattleOutcome.victory);
    });
  });
}
