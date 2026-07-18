import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';

/// P0 破招:requestUltimate 放宽接受关键技(Task 5)。
///
///   测 A: powerSkill 型 → 不抛 + pendingUltimates 写入该 skill。
///   测 B: normalAttack 型 → 抛 ArgumentError。
void main() {
  const powerSkill = SkillDef(
    id: 'skill_p0_powerskill_stub',
    name: '破招强力技(stub)',
    description: 'P0 Task5 测 A',
    type: SkillType.powerSkill,
    powerMultiplier: 2000,
    internalForceCost: 150,
    cooldownTurns: 3,
    requiresManualTrigger: true,
    visualEffect: 'stub',
    canInterrupt: true,
  );
  const normalAttack = SkillDef(
    id: 'skill_p0_normal_stub',
    name: '普攻(stub)',
    description: 'P0 Task5 测 B',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );
  const foreignSkill = SkillDef(
    id: 'skill_foreign',
    name: '未装备秘式',
    description: '不应进入 pending',
    type: SkillType.powerSkill,
    powerMultiplier: 8000,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: true,
    visualEffect: 'stub',
  );
  const aoeSkill = SkillDef(
    id: 'skill_p0_aoe_stub',
    name: '群攻(stub)',
    description: 'AOE 不保留单体目标',
    type: SkillType.ultimate,
    powerMultiplier: 3000,
    internalForceCost: 300,
    cooldownTurns: 4,
    requiresManualTrigger: true,
    visualEffect: 'stub',
    targetType: TargetType.aoe,
  );

  // ── 最小化 BattleState:两队各 1 角色,只测 requestUltimate 写入语义 ──
  BattleState makeState({bool playerAlive = true}) {
    final char = BattleCharacter(
      characterId: 1,
      name: '玩家',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 12000,
      currentHp: 12000,
      maxInternalForce: 10000,
      currentInternalForce: 10000,
      speed: 200,
      criticalRate: 0.15,
      evasionRate: 0.05,
      defenseRate: 0.35,
      totalEquipmentAttack: 1500,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: const <SkillDef>[powerSkill, aoeSkill, normalAttack],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: playerAlive,
      teamSide: 0,
      slotIndex: 0,
    );
    const enemy = BattleCharacter(
      characterId: -1,
      name: '敌',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 12000,
      currentHp: 12000,
      maxInternalForce: 10000,
      currentInternalForce: 10000,
      speed: 200,
      criticalRate: 0.15,
      evasionRate: 0.05,
      defenseRate: 0.35,
      totalEquipmentAttack: 1500,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: <SkillDef>[],
      skillCooldowns: {},
      activeBuffs: [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 1,
      slotIndex: 0,
    );
    return BattleState.initial(leftTeam: [char], rightTeam: [enemy]);
  }

  const strategy = DefaultGroundStrategy();

  group('requestUltimate P0 放宽:接受 powerSkill/ultimate/jointSkill', () {
    test('测 A:powerSkill 型不抛 + pendingUltimates 写入该 skill', () {
      final state = makeState();

      late BattleState result;
      expect(
        () => result = strategy.requestUltimate(state, 1, powerSkill),
        returnsNormally,
        reason: 'powerSkill 应被接受,不抛',
      );
      expect(
        result.pendingUltimates[1],
        same(powerSkill),
        reason: 'pendingUltimates[charId] 应指向该 powerSkill',
      );
    });

    test('测 B:normalAttack 型 → 抛 ArgumentError', () {
      final state = makeState();

      expect(
        () => strategy.requestUltimate(state, 1, normalAttack),
        throwsA(isA<ArgumentError>()),
        reason: 'normalAttack 手动请求不合语义,应抛 ArgumentError',
      );
    });

    test('未装备技能请求 → noop', () {
      final state = makeState();
      final result = strategy.requestUltimate(state, 1, foreignSkill);

      expect(result, same(state));
      expect(result.pendingUltimates, isEmpty);
    });

    test('同 id 伪造倍率时写入角色已装备的规范对象', () {
      final state = makeState();
      const forged = SkillDef(
        id: 'skill_p0_powerskill_stub',
        name: '伪造秘式',
        description: '同 id 伪造倍率',
        type: SkillType.powerSkill,
        powerMultiplier: 8000,
        internalForceCost: 0,
        cooldownTurns: 0,
        requiresManualTrigger: true,
        visualEffect: 'stub',
      );

      final result = strategy.requestUltimate(state, 1, forged);

      expect(result.pendingUltimates[1], same(powerSkill));
    });

    test('阵亡角色请求 → noop', () {
      final state = makeState(playerAlive: false);
      final result = strategy.requestUltimate(state, 1, powerSkill);

      expect(result, same(state));
      expect(result.pendingUltimates, isEmpty);
    });

    test('敌方角色请求 → noop', () {
      final state = makeState();
      final result = strategy.requestUltimate(state, -1, powerSkill);

      expect(result, same(state));
      expect(result.pendingUltimates, isEmpty);
    });

    test('普通单体指定受护法保护 Boss → noop；指定护法 → 正常写入', () {
      final base = makeState();
      final boss = base.rightTeam.single.copyWith(
        isBoss: true,
        enemyDefId: 'ward_boss',
        guardianWardMult: 0.15,
        guardianDefIds: const ['ward_guardian'],
      );
      final guardian = base.rightTeam.single.copyWith(
        characterId: -2,
        enemyDefId: 'ward_guardian',
        slotIndex: 1,
      );
      final state = base.copyWith(rightTeam: [boss, guardian]);

      final rejected = strategy.requestUltimate(
        state,
        1,
        powerSkill,
        targetId: boss.characterId,
      );
      expect(rejected, same(state));

      final accepted = strategy.requestUltimate(
        state,
        1,
        powerSkill,
        targetId: guardian.characterId,
      );
      expect(accepted.pendingUltimates[1], same(powerSkill));
      expect(accepted.pendingTargets[1], guardian.characterId);
    });

    test('AOE 即使传入 targetId 也不写单体 pendingTargets', () {
      final state = makeState();

      final result = strategy.requestUltimate(state, 1, aoeSkill, targetId: -1);

      expect(result.pendingUltimates[1], same(aoeSkill));
      expect(result.pendingTargets, isEmpty);
    });
  });
}
