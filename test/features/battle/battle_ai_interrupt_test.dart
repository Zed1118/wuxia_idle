import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_ai.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

/// P0 破招(Task 6):battle_ai aiUsePolicy 跳过 + 蓄力时破招 + 破招技锁定蓄力敌。
///
///   测 A(无人蓄力):对面无人 chargingSkill → decide 选 normal 技(非 saveForInterrupt)。
///   测 B(有人蓄力 + targeting):对面某敌蓄力 → decide 选 saveForInterrupt 技,
///     且 targetId == 该 charging 敌人(即使它非血最低,验证 targeting 锁定蓄力敌)。
void main() {
  Future<String> fileLoader(String path) async {
    final f = File(path);
    if (!await f.exists()) throw FileSystemException('不存在', path);
    return f.readAsString();
  }

  setUp(() async {
    await GameRepository.loadAllDefs(loader: fileLoader);
  });

  tearDown(GameRepository.resetForTest);

  // 破招技:saveForInterrupt + canInterrupt,倍率较低,CD0 cost 低。
  const interruptSkill = SkillDef(
    id: 'skill_p0_interrupt_stub',
    name: '破招技(stub)',
    description: 'Task6 saveForInterrupt',
    type: SkillType.powerSkill,
    powerMultiplier: 1500,
    internalForceCost: 100,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
    canInterrupt: true,
    aiUsePolicy: AiUsePolicy.saveForInterrupt,
  );

  // 普通强力技:normal,倍率更高,CD0。平时 AI 应优先它。
  const normalPower = SkillDef(
    id: 'skill_p0_normal_power_stub',
    name: '普通强力技(stub)',
    description: 'Task6 normal',
    type: SkillType.powerSkill,
    powerMultiplier: 2500,
    internalForceCost: 100,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
    aiUsePolicy: AiUsePolicy.normal,
  );

  const normalAttack = SkillDef(
    id: 'skill_p0_attack_stub',
    name: '普攻(stub)',
    description: 'Task6 兜底普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  BattleCharacter makeActor() => const BattleCharacter(
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
        availableSkills: <SkillDef>[
          interruptSkill,
          normalPower,
          normalAttack,
        ],
        skillCooldowns: <String, int>{},
        activeBuffs: [],
        actionPoint: 0,
        isAlive: true,
        teamSide: 0,
        slotIndex: 0,
      );

  // charId=11 血更低(故意让它血最低,验证 targeting 不挑它);charId=12 是蓄力敌。
  BattleCharacter makeEnemy({
    required int charId,
    required int slotIndex,
    required int currentHp,
  }) =>
      BattleCharacter(
        characterId: charId,
        name: '敌$charId',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: 12000,
        currentHp: currentHp,
        maxInternalForce: 10000,
        currentInternalForce: 10000,
        speed: 200,
        criticalRate: 0.15,
        evasionRate: 0.05,
        defenseRate: 0.35,
        totalEquipmentAttack: 1500,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const <SkillDef>[],
        skillCooldowns: const <String, int>{},
        activeBuffs: [],
        actionPoint: 0,
        isAlive: true,
        teamSide: 1,
        slotIndex: slotIndex,
      );

  test('测 A:无人蓄力 → 选 normal 技,不选 saveForInterrupt 技', () {
    final actor = makeActor();
    final lowHpEnemy = makeEnemy(charId: 11, slotIndex: 0, currentHp: 3000);
    final otherEnemy = makeEnemy(charId: 12, slotIndex: 1, currentHp: 9000);
    final state = BattleState.initial(
      leftTeam: [actor],
      rightTeam: [lowHpEnemy, otherEnemy],
    );

    final (skill, _) =
        BattleAI.decide(actor, state, GameRepository.instance.numbers);

    expect(
      skill.id,
      normalPower.id,
      reason: '无人蓄力时平时不放破招技,应选倍率更高的 normal 强力技',
    );
    expect(skill.aiUsePolicy, AiUsePolicy.normal);
  });

  test('测 B:对面有人蓄力 → 选 saveForInterrupt 技 + targetId 锁定蓄力敌', () {
    final actor = makeActor();
    // 血最低的敌人(charId=11)不蓄力;蓄力敌(charId=12)血更高。
    final lowHpEnemy = makeEnemy(charId: 11, slotIndex: 0, currentHp: 3000);
    final chargingEnemy = makeEnemy(charId: 12, slotIndex: 1, currentHp: 9000)
        .copyWith(chargingSkill: normalPower, chargeTicksRemaining: 2);
    final state = BattleState.initial(
      leftTeam: [actor],
      rightTeam: [lowHpEnemy, chargingEnemy],
    );

    final (skill, targetIds) =
        BattleAI.decide(actor, state, GameRepository.instance.numbers);

    expect(
      skill.id,
      interruptSkill.id,
      reason: '对面有人蓄力 + 有可用 saveForInterrupt 破招技 → 应保守破招',
    );
    expect(skill.aiUsePolicy, AiUsePolicy.saveForInterrupt);
    expect(
      targetIds,
      [chargingEnemy.characterId],
      reason: '破招技应锁定蓄力敌(12),即使它非血最低(11 血更低)',
    );
  });
}
