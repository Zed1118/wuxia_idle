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
  // ── 最小化 BattleState:两队各 1 角色,只测 requestUltimate 写入语义 ──
  BattleState _makeState() {
    const char = BattleCharacter(
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
      availableSkills: <SkillDef>[],
      skillCooldowns: {},
      activeBuffs: [],
      actionPoint: 0,
      isAlive: true,
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
      final state = _makeState();

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
      final state = _makeState();

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

      expect(
        () => strategy.requestUltimate(state, 1, normalAttack),
        throwsA(isA<ArgumentError>()),
        reason: 'normalAttack 手动请求不合语义,应抛 ArgumentError',
      );
    });
  });
}
