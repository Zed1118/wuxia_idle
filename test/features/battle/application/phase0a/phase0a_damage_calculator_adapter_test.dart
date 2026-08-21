import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/phase0a_skill_behavior.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_combat_session.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_damage_calculator_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_enemy_ai_adapter.dart';
import 'package:wuxia_idle/features/battle/application/phase0a/phase0a_player_input_adapter.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/arena_vector.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_events.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_model.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/phase0a_combat_reducer.dart';
import 'package:wuxia_idle/features/cultivation/domain/skill_proficiency.dart';
import '../../../../support/test_data.dart';

/// Phase 0A 生产 DamageCalculator 适配器红测(第三批派单 §必测):
/// ① 真实 numbers fixture 下 adapter 与 direct `calculateResolved` 精确同值;
/// ② 同 seed 回放相等、control-only 零伤且不耗 RNG;
/// ③ missing actor/binding、非法快照、非零吸血 fail-fast;
/// ④ `Phase0aCombatSession.advance` 穿透生产 adapter → reducer。
///
/// 执行前拍板(2026-08-16 用户补充):
/// Ⓐ control-only 也必须先验证 attacker/target 两快照完整合法性
///   (只是不调 calculator、不推进 RNG),否则非法生产配置会被控制技静默掩盖;
/// Ⓑ 熟练度倍率按当前 binding 的 SkillDef.id 查调用方预解析表
///   (`proficiencyDamageMults[skill.id] ?? 1.0` 纯查表,不复制推导公式),
///   缺条目回落 1.0;缺 kind 绑定与 null control-only 用 containsKey 区分。
void main() {
  setUp(() async {
    await loadTestGameRepository();
  });

  tearDown(GameRepository.resetForTest);

  NumbersConfig numbers() => GameRepository.instance.numbers;

  // 普攻招式 fixture:倍率 500 基准,与 numbers.yaml 普攻口径同族。
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

  const powerSkill = SkillDef(
    id: 'phase0a_test_power',
    name: 'power',
    description: 'power',
    type: SkillType.powerSkill,
    powerMultiplier: 1500,
    qiDelta: -20,
    cooldownTurns: 3,
    requiresManualTrigger: false,
    visualEffect: '',
  );

  Phase0aDamageSnapshot makePlayerSnapshot({
    int internalForce = 600,
    int equipmentAttack = 130,
    double evasionRate = 0.05,
    double criticalRate = 0.075,
    double lifestealPct = 0.0,
    Map<String, double> proficiencyDamageMults = const {},
  }) {
    return Phase0aDamageSnapshot(
      internalForce: internalForce,
      equipmentAttack: equipmentAttack,
      cultivationLayer: CultivationLayer.chuKui,
      school: TechniqueSchool.gangMeng,
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.ruMen,
      defenseRate: 0.05,
      evasionRate: evasionRate,
      criticalRate: criticalRate,
      attackPowerMultiplier: 1.0,
      proficiencyDamageMults: proficiencyDamageMults,
      outputMultiplier: 1.0,
      schoolDamageTakenMults: const {},
      wardMult: 1.0,
      piercePct: 0.0,
      lifestealPct: lifestealPct,
      critDamageTakenMult: 1.0,
    );
  }

  Phase0aDamageSnapshot makeEnemySnapshot({
    int internalForce = 400,
    int equipmentAttack = 90,
    double defenseRate = 0.05,
    double evasionRate = 0.05,
    double criticalRate = 0.05,
    Map<TechniqueSchool, double> schoolDamageTakenMults = const {},
  }) {
    return Phase0aDamageSnapshot(
      internalForce: internalForce,
      equipmentAttack: equipmentAttack,
      cultivationLayer: CultivationLayer.chuKui,
      school: TechniqueSchool.yinRou,
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      defenseRate: defenseRate,
      evasionRate: evasionRate,
      criticalRate: criticalRate,
      attackPowerMultiplier: 1.0,
      proficiencyDamageMults: const {},
      outputMultiplier: 1.0,
      schoolDamageTakenMults: schoolDamageTakenMults,
      wardMult: 1.0,
      piercePct: 0.0,
      lifestealPct: 0.0,
      critDamageTakenMult: 1.0,
    );
  }

  Phase0aDamageCalculatorAdapter makeAdapter({
    required int seed,
    Map<String, Phase0aDamageSnapshot>? combatants,
    Map<Phase0aDamageKind, SkillDef?>? moveBindings,
  }) {
    return Phase0aDamageCalculatorAdapter(
      combatants:
          combatants ??
          {'player': makePlayerSnapshot(), 'e1': makeEnemySnapshot()},
      moveBindings: moveBindings ?? const {Phase0aDamageKind.basic: basicSkill},
      numbers: numbers(),
      rng: math.Random(seed),
    );
  }

  /// direct 对照调用:与 adapter 内部逐字段同一口径,公式走同一
  /// `calculateResolved`,本测试锁死「adapter 不得产生第二套公式」。
  AttackResult directResolve({
    required Phase0aDamageSnapshot attacker,
    required Phase0aDamageSnapshot defender,
    required SkillDef skill,
    required math.Random rng,
  }) {
    return DamageCalculator.calculateResolved(
      attackerInternalForce: attacker.internalForce,
      attackerEquipmentAttack: attacker.equipmentAttack,
      attackerCultivationLayer: attacker.cultivationLayer,
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
      skill: skill,
      n: numbers(),
      rng: rng,
      // 拍板Ⓑ:熟练度按 binding 的 skill.id 查调用方预解析表,缺条目 1.0。
      proficiencyDamageMult: attacker.proficiencyDamageMults[skill.id] ?? 1.0,
      defenderCritDamageTakenMult: defender.critDamageTakenMult,
      outputMultiplier: attacker.outputMultiplier,
      defenderSchoolDamageMult:
          defender.schoolDamageTakenMults[attacker.school] ?? 1.0,
      defenderWardMult: defender.wardMult,
      attackerPiercePct: attacker.piercePct,
      attackerLifestealPct: attacker.lifestealPct,
    );
  }

  void expectResolvedEqualsDirect(
    Phase0aResolvedHit resolved,
    AttackResult direct,
  ) {
    // 冻结映射:!isDodged → isHit,isCritical 原样,finalDamage → damage。
    expect(resolved.isHit, !direct.isDodged);
    expect(resolved.isCritical, direct.isCritical);
    expect(resolved.damage, direct.finalDamage);
  }

  group('与 direct calculateResolved 精确同值(真实 numbers fixture)', () {
    test('多 seed 序列:命中/暴击/闪避/finalDamage 逐拍一致', () {
      // evasion 0.15 / crit 0.3 让闪避与暴击分支在多 seed 下都被真实踩到,
      // 不只测恒命中路径。
      final attacker = makePlayerSnapshot(criticalRate: 0.3);
      final defender = makeEnemySnapshot(evasionRate: 0.15);
      var sawDodge = false;
      var sawCrit = false;
      for (var seed = 1; seed <= 12; seed++) {
        final adapter = makeAdapter(
          seed: seed,
          combatants: {'player': attacker, 'e1': defender},
        );
        final directRng = math.Random(seed);
        for (var i = 0; i < 4; i++) {
          final resolved = adapter.resolve(
            attackerId: 'player',
            targetId: 'e1',
            kind: Phase0aDamageKind.basic,
          );
          final direct = directResolve(
            attacker: attacker,
            defender: defender,
            skill: basicSkill,
            rng: directRng,
          );
          expectResolvedEqualsDirect(resolved, direct);
          sawDodge = sawDodge || direct.isDodged;
          sawCrit = sawCrit || direct.isCritical;
        }
      }
      expect(sawDodge, isTrue, reason: '12 seed × 4 拍应踩到闪避分支');
      expect(sawCrit, isTrue, reason: '12 seed × 4 拍应踩到暴击分支');
    });

    test('恒暴击(criticalRate=1)与恒闪避(evasionRate=1)边界同值', () {
      final critAdapter = makeAdapter(
        seed: 7,
        combatants: {
          'player': makePlayerSnapshot(criticalRate: 1.0),
          'e1': makeEnemySnapshot(evasionRate: 0.0),
        },
      );
      final critResolved = critAdapter.resolve(
        attackerId: 'player',
        targetId: 'e1',
        kind: Phase0aDamageKind.basic,
      );
      expect(critResolved.isHit, isTrue);
      expect(critResolved.isCritical, isTrue);
      expect(
        critResolved.damage,
        directResolve(
          attacker: makePlayerSnapshot(criticalRate: 1.0),
          defender: makeEnemySnapshot(evasionRate: 0.0),
          skill: basicSkill,
          rng: math.Random(7),
        ).finalDamage,
      );

      final dodgeAdapter = makeAdapter(
        seed: 7,
        combatants: {
          'player': makePlayerSnapshot(),
          'e1': makeEnemySnapshot(evasionRate: 1.0),
        },
      );
      final dodgeResolved = dodgeAdapter.resolve(
        attackerId: 'player',
        targetId: 'e1',
        kind: Phase0aDamageKind.basic,
      );
      // 闪避映射:isHit=false,暴击 false,damage = finalDamage(0),不重算。
      expect(dodgeResolved.isHit, isFalse);
      expect(dodgeResolved.isCritical, isFalse);
      expect(dodgeResolved.damage, 0);
    });

    test('熟练度倍率按 binding 的 SkillDef.id 取值,缺条目回落 1.0', () {
      // 拍板Ⓑ:同 attacker 对 basic/power 两招用各自 id 的预解析倍率,
      // 不是 actor 全局单值。
      final attacker = makePlayerSnapshot(
        criticalRate: 0.0,
        proficiencyDamageMults: const {
          'phase0a_test_basic': 1.2,
          'phase0a_test_power': 1.05,
        },
      );
      final defender = makeEnemySnapshot(evasionRate: 0.0);
      final adapter = makeAdapter(
        seed: 3,
        combatants: {'player': attacker, 'e1': defender},
        moveBindings: const {
          Phase0aDamageKind.basic: basicSkill,
          Phase0aDamageKind.clear: powerSkill,
        },
      );
      final directRng = math.Random(3);

      final basicResolved = adapter.resolve(
        attackerId: 'player',
        targetId: 'e1',
        kind: Phase0aDamageKind.basic,
      );
      expectResolvedEqualsDirect(
        basicResolved,
        directResolve(
          attacker: attacker,
          defender: defender,
          skill: basicSkill,
          rng: directRng,
        ),
      );
      // 两招 powerMultiplier 不同且倍率表按 id 区分 → damage 必然不同,
      // 断言 direct 对照即锁死「按 id 查表」而非全局单值。
      final powerResolved = adapter.resolve(
        attackerId: 'player',
        targetId: 'e1',
        kind: Phase0aDamageKind.clear,
      );
      expectResolvedEqualsDirect(
        powerResolved,
        directResolve(
          attacker: attacker,
          defender: defender,
          skill: powerSkill,
          rng: directRng,
        ),
      );

      // 缺条目回落 1.0:无表 attacker 走默认倍率。
      final noProf = makePlayerSnapshot(criticalRate: 0.0);
      final fallbackAdapter = makeAdapter(
        seed: 3,
        combatants: {'player': noProf, 'e1': defender},
      );
      final fallbackResolved = fallbackAdapter.resolve(
        attackerId: 'player',
        targetId: 'e1',
        kind: Phase0aDamageKind.basic,
      );
      expectResolvedEqualsDirect(
        fallbackResolved,
        directResolve(
          attacker: noProf,
          defender: defender,
          skill: basicSkill,
          rng: math.Random(3),
        ),
      );
    });

    test('缺条目回落 1.0 与零使用(chuShi)既有熟练度语义一致', () {
      // 语义锁定:既有路径(calculate / _calculateInBattle)对零使用招式
      // 得 stageFor(0)=chuShi、combinedMult=1.00(numbers.yaml 实测),
      // adapter 缺条目回落 1.0 与之同义,不是新造默认值。
      final zeroUseMult = SkillProficiency.combinedMult(
        0,
        0.0,
        numbers().skillProficiency,
      );
      expect(
        zeroUseMult,
        1.0,
        reason: 'numbers.yaml skill_proficiency chuShi damage_mult=1.00',
      );
      final attacker = makePlayerSnapshot(criticalRate: 0.0);
      final defender = makeEnemySnapshot(evasionRate: 0.0);
      final adapter = makeAdapter(
        seed: 8,
        combatants: {'player': attacker, 'e1': defender},
      );
      final resolved = adapter.resolve(
        attackerId: 'player',
        targetId: 'e1',
        kind: Phase0aDamageKind.basic,
      );
      // 空表 adapter 结果 == direct 显式传零使用既有倍率。
      final direct = DamageCalculator.calculateResolved(
        attackerInternalForce: attacker.internalForce,
        attackerEquipmentAttack: attacker.equipmentAttack,
        attackerCultivationLayer: attacker.cultivationLayer,
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
        rng: math.Random(8),
        proficiencyDamageMult: zeroUseMult,
      );
      expectResolvedEqualsDirect(resolved, direct);
    });
  });

  group('快照不可变性(防御性副本)', () {
    test('外部 map 构造后 mutation 不影响快照与 seed 回放', () {
      // 复核拍板:快照承诺不可变,两个乘子表必须做防御性不可修改副本,
      // 否则 caller 构造后改外部 map 会静默污染同 seed 回放。
      final profMap = <String, double>{'phase0a_test_basic': 1.2};
      final weakMap = <TechniqueSchool, double>{TechniqueSchool.gangMeng: 1.5};
      final attacker = makePlayerSnapshot(
        criticalRate: 0.0,
        proficiencyDamageMults: profMap,
      );
      final defender = makeEnemySnapshot(
        evasionRate: 0.0,
        schoolDamageTakenMults: weakMap,
      );

      // 构造后污染外部 map:若快照只持引用,回放结果会被改变。
      profMap['phase0a_test_basic'] = 9.9;
      profMap['phase0a_test_power'] = 9.9;
      weakMap[TechniqueSchool.gangMeng] = 0.01;

      // 快照内容不受外部 mutation 影响。
      expect(attacker.proficiencyDamageMults['phase0a_test_basic'], 1.2);
      expect(
        attacker.proficiencyDamageMults.containsKey('phase0a_test_power'),
        isFalse,
      );
      expect(defender.schoolDamageTakenMults[TechniqueSchool.gangMeng], 1.5);
      // 副本自身不可写。
      expect(
        () => attacker.proficiencyDamageMults['x'] = 2.0,
        throwsUnsupportedError,
      );
      expect(
        () => defender.schoolDamageTakenMults[TechniqueSchool.yinRou] = 2.0,
        throwsUnsupportedError,
      );

      // 回放仍与未污染口径的 direct 对照一致(directResolve 读快照副本)。
      final adapter = makeAdapter(
        seed: 42,
        combatants: {'player': attacker, 'e1': defender},
      );
      final resolved = adapter.resolve(
        attackerId: 'player',
        targetId: 'e1',
        kind: Phase0aDamageKind.basic,
      );
      expectResolvedEqualsDirect(
        resolved,
        directResolve(
          attacker: attacker,
          defender: defender,
          skill: basicSkill,
          rng: math.Random(42),
        ),
      );
    });
  });

  group('seed 回放与稳定顺序', () {
    test('同 seed 两实例、多次调用序列完全相等', () {
      Map<String, Phase0aDamageSnapshot> combatants() => {
        'player': makePlayerSnapshot(criticalRate: 0.3),
        'e1': makeEnemySnapshot(),
        'e2': makeEnemySnapshot(internalForce: 350, evasionRate: 0.1),
      };
      final adapterA = makeAdapter(seed: 99, combatants: combatants());
      final adapterB = makeAdapter(seed: 99, combatants: combatants());
      const sequence = [
        ('player', 'e1'),
        ('player', 'e2'),
        ('e1', 'player'),
        ('player', 'e1'),
        ('e2', 'player'),
      ];
      for (final (attackerId, targetId) in sequence) {
        final a = adapterA.resolve(
          attackerId: attackerId,
          targetId: targetId,
          kind: Phase0aDamageKind.basic,
        );
        final b = adapterB.resolve(
          attackerId: attackerId,
          targetId: targetId,
          kind: Phase0aDamageKind.basic,
        );
        expect(b.isHit, a.isHit);
        expect(b.isCritical, a.isCritical);
        expect(b.damage, a.damage);
      }
    });
  });

  group('control-only 零伤绑定', () {
    test('真实 pull SkillDef 无 damage effect 时仍零伤且不耗 RNG', () {
      final gatherSkill = SkillDef(
        id: 'phase0a_test_gather',
        name: 'gather',
        description: 'gather',
        type: SkillType.powerSkill,
        powerMultiplier: 0,
        qiDelta: -10,
        cooldownTurns: 3,
        requiresManualTrigger: true,
        visualEffect: '',
        phase0aBehavior: Phase0aSkillBehavior.fromYaml({
          'geometry': {'shape': 'radial', 'anchor': 'caster', 'radius': 10},
          'effects': [
            {'type': 'pull', 'destinationRadius': 2},
          ],
        }),
      );
      final adapter = makeAdapter(
        seed: 42,
        moveBindings: {
          Phase0aDamageKind.basic: basicSkill,
          Phase0aDamageKind.gather: gatherSkill,
        },
      );

      final control = adapter.resolve(
        attackerId: 'player',
        targetId: 'e1',
        kind: Phase0aDamageKind.gather,
      );
      expect(control.damage, 0);
      final after = adapter.resolve(
        attackerId: 'player',
        targetId: 'e1',
        kind: Phase0aDamageKind.basic,
      );
      final controlFree = directResolve(
        attacker: makePlayerSnapshot(),
        defender: makeEnemySnapshot(),
        skill: basicSkill,
        rng: math.Random(42),
      );
      expectResolvedEqualsDirect(after, controlFree);
    });

    test('返回 hit=true/critical=false/damage=0 且不消费 RNG', () {
      final adapter = makeAdapter(
        seed: 42,
        moveBindings: const {
          Phase0aDamageKind.basic: basicSkill,
          Phase0aDamageKind.gather: null, // control-only 显式绑定
        },
      );
      final control = adapter.resolve(
        attackerId: 'player',
        targetId: 'e1',
        kind: Phase0aDamageKind.gather,
      );
      expect(control.isHit, isTrue);
      expect(control.isCritical, isFalse);
      expect(control.damage, 0);

      // control 调用若消费了 RNG,随后 basic 的结果会偏离 fresh-seed 对照。
      final after = adapter.resolve(
        attackerId: 'player',
        targetId: 'e1',
        kind: Phase0aDamageKind.basic,
      );
      final controlFree = directResolve(
        attacker: makePlayerSnapshot(),
        defender: makeEnemySnapshot(),
        skill: basicSkill,
        rng: math.Random(42),
      );
      expectResolvedEqualsDirect(after, controlFree);
    });

    test('control-only 同样先验快照合法性:非法快照 fail-fast 且不耗 RNG', () {
      // 拍板Ⓐ:control-only 不得静默掩盖非法生产配置。
      // e2 带 NaN 闪避;gather(null 绑定)指向 e2 必须抛,且不推进 RNG——
      // 随后对合法 e1 的 basic 调用仍与 fresh-seed 对照相等。
      final adapter = makeAdapter(
        seed: 42,
        combatants: {
          'player': makePlayerSnapshot(),
          'e1': makeEnemySnapshot(),
          'e2': makeEnemySnapshot(evasionRate: double.nan),
        },
        moveBindings: const {
          Phase0aDamageKind.basic: basicSkill,
          Phase0aDamageKind.gather: null,
        },
      );
      expect(
        () => adapter.resolve(
          attackerId: 'player',
          targetId: 'e2',
          kind: Phase0aDamageKind.gather,
        ),
        throwsA(isA<ArgumentError>()),
      );
      final after = adapter.resolve(
        attackerId: 'player',
        targetId: 'e1',
        kind: Phase0aDamageKind.basic,
      );
      final controlFree = directResolve(
        attacker: makePlayerSnapshot(),
        defender: makeEnemySnapshot(),
        skill: basicSkill,
        rng: math.Random(42),
      );
      expectResolvedEqualsDirect(after, controlFree);
    });

    test('control-only 缺 actor 仍 fail-fast', () {
      final adapter = makeAdapter(
        seed: 1,
        moveBindings: const {Phase0aDamageKind.gather: null},
      );
      expect(
        () => adapter.resolve(
          attackerId: 'ghost',
          targetId: 'e1',
          kind: Phase0aDamageKind.gather,
        ),
        throwsStateError,
      );
    });
  });

  group('fail-fast(计算前拒绝)', () {
    test('缺 attacker 快照抛 StateError', () {
      final adapter = makeAdapter(seed: 1);
      expect(
        () => adapter.resolve(
          attackerId: 'ghost',
          targetId: 'e1',
          kind: Phase0aDamageKind.basic,
        ),
        throwsStateError,
      );
    });

    test('缺 target 快照抛 StateError', () {
      final adapter = makeAdapter(seed: 1);
      expect(
        () => adapter.resolve(
          attackerId: 'player',
          targetId: 'ghost',
          kind: Phase0aDamageKind.basic,
        ),
        throwsStateError,
      );
    });

    test('缺 kind 绑定抛 StateError(containsKey 区分 null control-only)', () {
      final adapter = makeAdapter(
        seed: 1,
        moveBindings: const {Phase0aDamageKind.basic: basicSkill},
      );
      expect(
        () => adapter.resolve(
          attackerId: 'player',
          targetId: 'e1',
          kind: Phase0aDamageKind.clear,
        ),
        throwsStateError,
      );
    });

    test('负值快照 fail-fast(内力/防御率)', () {
      final negativeForce = makeAdapter(
        seed: 1,
        combatants: {
          'player': makePlayerSnapshot(internalForce: -1),
          'e1': makeEnemySnapshot(),
        },
      );
      expect(
        () => negativeForce.resolve(
          attackerId: 'player',
          targetId: 'e1',
          kind: Phase0aDamageKind.basic,
        ),
        throwsA(isA<ArgumentError>()),
      );

      final negativeDefRate = makeEnemySnapshot(defenseRate: -0.5);
      final badDefender = makeAdapter(
        seed: 1,
        combatants: {'player': makePlayerSnapshot(), 'e1': negativeDefRate},
      );
      expect(
        () => badDefender.resolve(
          attackerId: 'player',
          targetId: 'e1',
          kind: Phase0aDamageKind.basic,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('NaN/Infinity 快照 fail-fast', () {
      final nanEvasion = makeAdapter(
        seed: 1,
        combatants: {
          'player': makePlayerSnapshot(),
          'e1': makeEnemySnapshot(evasionRate: double.nan),
        },
      );
      expect(
        () => nanEvasion.resolve(
          attackerId: 'player',
          targetId: 'e1',
          kind: Phase0aDamageKind.basic,
        ),
        throwsA(isA<ArgumentError>()),
      );

      final infiniteCrit = makeAdapter(
        seed: 1,
        combatants: {
          'player': makePlayerSnapshot(criticalRate: double.infinity),
          'e1': makeEnemySnapshot(),
        },
      );
      expect(
        () => infiniteCrit.resolve(
          attackerId: 'player',
          targetId: 'e1',
          kind: Phase0aDamageKind.basic,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('非零吸血在计算前拒绝且不消费 RNG', () {
      final adapter = makeAdapter(
        seed: 42,
        combatants: {
          'player': makePlayerSnapshot(lifestealPct: 0.1),
          'e1': makeEnemySnapshot(),
        },
      );
      expect(
        () => adapter.resolve(
          attackerId: 'player',
          targetId: 'e1',
          kind: Phase0aDamageKind.basic,
        ),
        throwsStateError,
      );
      // fail-fast 必须发生在计算前:随后合法调用仍与 fresh-seed 对照相等。
      final legal = makeAdapter(seed: 42);
      final viaAdapter = legal.resolve(
        attackerId: 'player',
        targetId: 'e1',
        kind: Phase0aDamageKind.basic,
      );
      final direct = directResolve(
        attacker: makePlayerSnapshot(),
        defender: makeEnemySnapshot(),
        skill: basicSkill,
        rng: math.Random(42),
      );
      expectResolvedEqualsDirect(viaAdapter, direct);
    });
  });

  group('Phase0aCombatSession 穿透生产 adapter', () {
    Phase0aActor makeActor({
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

    Phase0aCombatSession makeProductionSession({
      required int seed,
      required Map<String, Phase0aDamageSnapshot> combatants,
      List<Phase0aActor>? enemies,
    }) {
      return Phase0aCombatSession(
        initialState: Phase0aArenaState(
          tick: 0,
          nextSeq: 1,
          player: makeActor(
            id: 'player',
            side: Phase0aSide.player,
            position: const ArenaVector(0, 0),
          ),
          enemies:
              enemies ??
              [
                makeActor(
                  id: 'e1',
                  side: Phase0aSide.enemy,
                  position: const ArenaVector(50, 0),
                ),
              ],
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
        damageResolver: makeAdapter(seed: seed, combatants: combatants),
      );
    }

    test('命中/暴击事件携带真实 resolved damage,与 direct 序列逐拍一致', () {
      final combatants = {
        'player': makePlayerSnapshot(criticalRate: 0.3, evasionRate: 0.0),
        'e1': makeEnemySnapshot(evasionRate: 0.0),
      };
      final session = makeProductionSession(seed: 5, combatants: combatants);
      final events = session.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );
      final hits = events.whereType<Phase0aHitLanded>().toList();
      expect(hits.map((h) => h.actor).toSet(), {'e1', 'player'});

      // reducer intent 按 actorId 稳定排序:'e1' 先 'player' 后;
      // direct 对照用同 seed 同顺序复算,锁死穿透链路无第二套公式。
      final directRng = math.Random(5);
      final enemyDirect = directResolve(
        attacker: combatants['e1']!,
        defender: combatants['player']!,
        skill: basicSkill,
        rng: directRng,
      );
      final playerDirect = directResolve(
        attacker: combatants['player']!,
        defender: combatants['e1']!,
        skill: basicSkill,
        rng: directRng,
      );

      final enemyHit = hits.singleWhere((h) => h.actor == 'e1');
      expect(enemyHit.target, 'player');
      expect(enemyHit.resolvedDamage, enemyDirect.finalDamage);
      expect(enemyHit.isCritical, enemyDirect.isCritical);
      final playerHit = hits.singleWhere((h) => h.actor == 'player');
      expect(playerHit.target, 'e1');
      expect(playerHit.resolvedDamage, playerDirect.finalDamage);
      expect(playerHit.isCritical, playerDirect.isCritical);
      expect(playerHit.remainingHealth, 100000 - playerDirect.finalDamage);
      expect(
        session.state.player.currentHealth,
        100000 - enemyDirect.finalDamage,
      );
    });

    test('闪避不产生 HitLanded,守方血量不变', () {
      final combatants = {
        'player': makePlayerSnapshot(evasionRate: 0.0),
        'e1': makeEnemySnapshot(evasionRate: 1.0), // 玩家攻击必被闪避
      };
      final session = makeProductionSession(seed: 5, combatants: combatants);
      final events = session.advance(
        deltaSeconds: 0.1,
        command: const Phase0aPlayerCommand(attack: true),
      );
      expect(
        events.whereType<Phase0aAttackStarted>().map((e) => e.actor).toSet(),
        {'e1', 'player'},
      );
      final hits = events.whereType<Phase0aHitLanded>().toList();
      // 只有 e1 → player 命中;player → e1 被闪避,无事件、不掉血。
      expect(hits, hasLength(1));
      expect(hits.single.actor, 'e1');
      expect(session.state.enemies.single.currentHealth, 100000);

      // direct 对照:同 seed 同顺序,'e1' 先行动命中,player 后被闪避。
      final directRng = math.Random(5);
      final enemyDirect = directResolve(
        attacker: combatants['e1']!,
        defender: combatants['player']!,
        skill: basicSkill,
        rng: directRng,
      );
      final playerDirect = directResolve(
        attacker: combatants['player']!,
        defender: combatants['e1']!,
        skill: basicSkill,
        rng: directRng,
      );
      expect(enemyDirect.isDodged, isFalse);
      expect(playerDirect.isDodged, isTrue);
      expect(hits.single.resolvedDamage, enemyDirect.finalDamage);
      expect(
        session.state.player.currentHealth,
        100000 - enemyDirect.finalDamage,
      );
    });

    test('同 seed 两会话同指令序列回放相等', () {
      Map<String, Phase0aDamageSnapshot> combatants() => {
        'player': makePlayerSnapshot(criticalRate: 0.3, evasionRate: 0.05),
        'e1': makeEnemySnapshot(evasionRate: 0.1),
      };
      List<Phase0aEvent> run(Phase0aCombatSession session) {
        final all = <Phase0aEvent>[];
        for (var i = 0; i < 6; i++) {
          all.addAll(
            session.advance(
              deltaSeconds: 0.5,
              command: const Phase0aPlayerCommand(attack: true),
            ),
          );
        }
        return all;
      }

      final sessionA = makeProductionSession(
        seed: 11,
        combatants: combatants(),
      );
      final sessionB = makeProductionSession(
        seed: 11,
        combatants: combatants(),
      );
      final eventsA = run(sessionA);
      final eventsB = run(sessionB);
      expect(eventsA, isNotEmpty);
      expect(eventsB, eventsA);
      expect(sessionB.state, sessionA.state);
    });
  });
}
