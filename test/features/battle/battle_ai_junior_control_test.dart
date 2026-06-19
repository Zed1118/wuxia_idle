import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_ai.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

/// 第七阶段批三 Task 11:二弟子(junior)控场目标偏好。
///
/// **不变量**:
///   - 当 actor.lineageRole == junior 且本拍不用破招技(普攻)时,优先 TARGET 对面
///     正在蓄力(chargingSkill!=null)的活敌(压制要放大招的威胁),即使其 HP 非最低。
///   - 非 junior(senior/founder/null/敌人)保持原默认级联(无破绽→血最低)。
///   - junior 在无蓄力敌时回落默认(破绽窗口→血最低),不崩。
///
/// **测 A**:junior + 蓄力敌(HP高) vs 血最低非蓄力敌 → 锁定蓄力敌(控场)。
/// **测 B(对照)**:同 state 但 actor=senior → 默认血最低(证 junior 专属)。
/// **测 C(对照)**:同 state 但 actor=founder → 默认血最低。
/// **测 D(对照)**:同 state 但 actor lineageRole=null → 默认血最低。
/// **测 E(边)**:junior + 无蓄力敌 → 回落血最低,不崩。
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

  // NON-canInterrupt 普攻:不进 canInterrupt 锁定蓄力分支,落到 junior/血最低分支。
  const normalAttack = SkillDef(
    id: 'skill_junior_normal',
    name: '普攻(控场测stub)',
    description: '批三控场测普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
    canInterrupt: false,
  );

  // 给敌人蓄力用的招(只作 chargingSkill 标记,不参与 actor 决策)。
  const enemyChargeSkill = SkillDef(
    id: 'skill_enemy_charge',
    name: '蓄力大招(stub)',
    description: '批三敌蓄力 stub',
    type: SkillType.powerSkill,
    powerMultiplier: 2500,
    internalForceCost: 100,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  BattleCharacter makeActor({LineageRole? lineageRole}) => BattleCharacter(
        characterId: 100,
        name: '玩家(控场测)',
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
        availableSkills: const <SkillDef>[normalAttack],
        skillCooldowns: const <String, int>{},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: 0,
        slotIndex: 0,
        lineageRole: lineageRole,
      );

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
        speed: 150,
        criticalRate: 0.10,
        evasionRate: 0.05,
        defenseRate: 0.20,
        totalEquipmentAttack: 1000,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const <SkillDef>[],
        skillCooldowns: const <String, int>{},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: 1,
        slotIndex: slotIndex,
      );

  // 血最低非蓄力敌(charId=11) vs 蓄力但血更高的敌(charId=12)。
  BattleState scenarioWithCharger(LineageRole? actorRole) {
    final actor = makeActor(lineageRole: actorRole);
    final lowHpEnemy = makeEnemy(charId: 11, slotIndex: 0, currentHp: 2000);
    final chargingEnemy = makeEnemy(charId: 12, slotIndex: 1, currentHp: 9000)
        .copyWith(chargingSkill: enemyChargeSkill, chargeTicksRemaining: 2);
    return BattleState.initial(
      leftTeam: [actor],
      rightTeam: [lowHpEnemy, chargingEnemy],
    );
  }

  test('测 A:junior 普攻 + 蓄力敌(HP高) → 锁定蓄力敌(控场),非血最低', () {
    final state = scenarioWithCharger(LineageRole.junior);
    final actor = state.leftTeam.first;

    final (skill, targetIds) =
        BattleAI.decide(actor, state, GameRepository.instance.numbers);

    expect(skill.id, normalAttack.id, reason: '应用普攻(唯一可用技)');
    expect(
      targetIds.first,
      12,
      reason: '二弟子控场:应盯蓄力敌(charId=12,HP=9000),'
          '而非血最低非蓄力敌(charId=11,HP=2000)',
    );
  });

  test('测 B(对照):senior 同 state → 默认血最低(证 junior 专属)', () {
    final state = scenarioWithCharger(LineageRole.senior);
    final actor = state.leftTeam.first;
    final (_, targetIds) =
        BattleAI.decide(actor, state, GameRepository.instance.numbers);
    expect(
      targetIds.first,
      11,
      reason: '大弟子非 junior 分支 → 默认血最低(charId=11),不盯蓄力敌',
    );
  });

  test('测 C(对照):founder 同 state → 默认血最低', () {
    final state = scenarioWithCharger(LineageRole.founder);
    final actor = state.leftTeam.first;
    final (_, targetIds) =
        BattleAI.decide(actor, state, GameRepository.instance.numbers);
    expect(targetIds.first, 11, reason: '祖师非 junior → 默认血最低');
  });

  test('测 D(对照):lineageRole=null 同 state → 默认血最低', () {
    final state = scenarioWithCharger(null);
    final actor = state.leftTeam.first;
    final (_, targetIds) =
        BattleAI.decide(actor, state, GameRepository.instance.numbers);
    expect(targetIds.first, 11, reason: '无师徒定位 → 默认血最低');
  });

  test('测 E(边):junior 无蓄力敌 → 回落血最低,不崩', () {
    final actor = makeActor(lineageRole: LineageRole.junior);
    final e0 = makeEnemy(charId: 21, slotIndex: 0, currentHp: 2000);
    final e1 = makeEnemy(charId: 22, slotIndex: 1, currentHp: 9000);
    final state = BattleState.initial(
      leftTeam: [actor],
      rightTeam: [e0, e1],
    );
    final (_, targetIds) =
        BattleAI.decide(actor, state, GameRepository.instance.numbers);
    expect(
      targetIds.first,
      21,
      reason: 'junior 无蓄力敌时回落血最低(charId=21,HP=2000)',
    );
  });
}
