import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_ai.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

/// Task 1(phase5 aoe):BattleAI.decide 返回 `(SkillDef, List<int> targetIds)`。
///
///   single 技 → targetIds 长度 1 == [原 _pickTargetId 结果]。
///   aoe 技   → targetIds == 全体存活敌人 charId,按 slotIndex 升序。
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

  // 单体强力技(targetType 默认 single)。
  const singlePower = SkillDef(
    id: 'skill_aoe_test_single_power',
    name: '单体强力(stub)',
    description: 'Task1 single',
    type: SkillType.powerSkill,
    powerMultiplier: 2500,
    internalForceCost: 100,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  // 群体强力技(targetType aoe),倍率更高确保被 _pickSkill 选中。
  const aoePower = SkillDef(
    id: 'skill_aoe_test_aoe_power',
    name: '群体强力(stub)',
    description: 'Task1 aoe',
    type: SkillType.powerSkill,
    powerMultiplier: 2800,
    internalForceCost: 100,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
    targetType: TargetType.aoe,
  );

  const normalAttack = SkillDef(
    id: 'skill_aoe_test_attack',
    name: '普攻(stub)',
    description: 'Task1 兜底普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  BattleCharacter makeActor({required List<SkillDef> skills}) => BattleCharacter(
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
        availableSkills: skills,
        skillCooldowns: const <String, int>{},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: 0,
        slotIndex: 0,
      );

  BattleCharacter makeEnemy({
    required int charId,
    required int slotIndex,
    required int currentHp,
    bool isAlive = true,
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
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: isAlive,
        teamSide: 1,
        slotIndex: slotIndex,
      );

  test('single 技 → targetIds 长度 1 == 血最低(_pickTargetId)目标', () {
    final actor = makeActor(skills: const [singlePower, normalAttack]);
    final r0 = makeEnemy(charId: 11, slotIndex: 0, currentHp: 5000);
    final r1 = makeEnemy(charId: 12, slotIndex: 1, currentHp: 3000); // 最低
    final r2 = makeEnemy(charId: 13, slotIndex: 2, currentHp: 8000);
    final state = BattleState.initial(
      leftTeam: [actor],
      rightTeam: [r0, r1, r2],
    );

    final (skill, targetIds) =
        BattleAI.decide(actor, state, GameRepository.instance.numbers);

    expect(skill.id, singlePower.id);
    expect(skill.targetType, TargetType.single);
    expect(targetIds, [r1.characterId],
        reason: 'single 技应返回单元素 list == 血最低敌人 charId');
  });

  test('aoe 技 → targetIds == 全体存活敌人 charId 按 slotIndex 升序', () {
    final actor = makeActor(skills: const [aoePower, normalAttack]);
    // 故意乱序传入,验证按 slotIndex 升序而非传入顺序。
    final r2 = makeEnemy(charId: 13, slotIndex: 2, currentHp: 8000);
    final r0 = makeEnemy(charId: 11, slotIndex: 0, currentHp: 5000);
    final r1 = makeEnemy(charId: 12, slotIndex: 1, currentHp: 3000);
    final state = BattleState.initial(
      leftTeam: [actor],
      rightTeam: [r2, r0, r1],
    );

    final (skill, targetIds) =
        BattleAI.decide(actor, state, GameRepository.instance.numbers);

    expect(skill.id, aoePower.id);
    expect(skill.targetType, TargetType.aoe);
    expect(targetIds, [r0.characterId, r1.characterId, r2.characterId],
        reason: 'aoe 技应返回全体存活敌人按 slotIndex 升序(11,12,13)');
  });

  test('aoe 技 → 跳过死亡敌人,只含存活的按 slotIndex 升序', () {
    final actor = makeActor(skills: const [aoePower, normalAttack]);
    final r0 = makeEnemy(charId: 11, slotIndex: 0, currentHp: 0, isAlive: false);
    final r1 = makeEnemy(charId: 12, slotIndex: 1, currentHp: 3000);
    final r2 = makeEnemy(charId: 13, slotIndex: 2, currentHp: 8000);
    final state = BattleState.initial(
      leftTeam: [actor],
      rightTeam: [r0, r1, r2],
    );

    final (skill, targetIds) =
        BattleAI.decide(actor, state, GameRepository.instance.numbers);

    expect(skill.id, aoePower.id);
    expect(targetIds, [r1.characterId, r2.characterId],
        reason: 'aoe 应排除死亡敌(11),只含 12,13');
  });
}
