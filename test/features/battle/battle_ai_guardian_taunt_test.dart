
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_ai.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';
import '../../support/test_data.dart';

/// 终局机制型 Boss 批次2 Task 3 · 模块 A:护法墙 taunt。
///
/// **不变量**:
///   - 护法(左使/右使)存活时,被其保护的 floor30 Boss(guardianDefIds 非空 且
///     同队有 enemyDefId ∈ guardianDefIds 的护法存活)从**目标池排除**——即使
///     Boss 血最低(修自动战斗按最低血集火先清护法致减伤 no-op 的核心缺陷)。
///   - 护法全灭 → Boss 恢复可选(进池)。
///   - taunt 判定 (BattleAI.isGuardedBoss) 与伤害闸 DefaultGroundStrategy.wardMultOf
///     的护法存活判定口径一致(drift 守卫)。
///
/// **测 A**:护法存活 → Boss(血最低)被排除,选中护法。
/// **测 B**:护法全灭 → Boss 进池(可选)。
/// **测 C**:drift 守卫 —— isGuardedBoss 与 wardMultOf<1.0 同步。
void main() {
  setUp(() async {
    await loadTestGameRepository();
  });

  tearDown(GameRepository.resetForTest);

  // 非 canInterrupt 普攻:不进破招锁定分支,落到默认 _pickFocusTargetId ?? _pickTargetId。
  const normalAttack = SkillDef(
    id: 'skill_taunt_normal',
    name: '普攻(taunt测stub)',
    description: 'Task3 taunt 测普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
    canInterrupt: false,
  );

  // aoe 技(可选测 aoe 分支排除)。
  const aoeAttack = SkillDef(
    id: 'skill_taunt_aoe',
    name: '群攻(taunt测stub)',
    description: 'Task3 taunt aoe 测',
    type: SkillType.powerSkill,
    powerMultiplier: 800,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
    targetType: TargetType.aoe,
  );

  BattleCharacter makeActor({List<SkillDef>? skills}) => BattleCharacter(
        characterId: 100,
        name: '玩家(taunt测)',
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
        availableSkills: skills ?? const <SkillDef>[normalAttack],
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
    String? enemyDefId,
    double? guardianWardMult,
    List<String> guardianDefIds = const [],
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
        enemyDefId: enemyDefId,
        guardianWardMult: guardianWardMult,
        guardianDefIds: guardianDefIds,
      );

  const bossCharId = 30;
  const guardianCharId = 31;

  // Boss(被护法 g1 保护, 血最低) + 护法 g1(血高存活)。
  BattleState scenario({required bool guardianAlive}) {
    final actor = makeActor();
    final boss = makeEnemy(
      charId: bossCharId,
      slotIndex: 0,
      currentHp: 2000, // 血最低:无 taunt 时 _pickTargetId 本会选它
      enemyDefId: 'boss',
      guardianWardMult: 0.15,
      guardianDefIds: const ['g1'],
    );
    final guardian = makeEnemy(
      charId: guardianCharId,
      slotIndex: 1,
      currentHp: guardianAlive ? 9000 : 0,
      enemyDefId: 'g1',
    );
    return BattleState.initial(
      leftTeam: [actor],
      rightTeam: [boss, guardian.copyWith(isAlive: guardianAlive)],
    );
  }

  test('测 A:护法存活时 Boss(血最低)被排除,选中护法', () {
    final state = scenario(guardianAlive: true);
    final actor = state.leftTeam.first;

    final (_, targetIds) =
        BattleAI.decide(actor, state, GameRepository.instance.numbers);

    expect(
      targetIds,
      isNot(contains(bossCharId)),
      reason: '护法存活 → 被保护 Boss 从目标池排除(taunt)',
    );
    expect(
      targetIds,
      contains(guardianCharId),
      reason: '护法存活 → 只能选护法',
    );
  });

  test('测 B:护法全灭后 Boss 恢复可选', () {
    final state = scenario(guardianAlive: false);
    final actor = state.leftTeam.first;

    final (_, targetIds) =
        BattleAI.decide(actor, state, GameRepository.instance.numbers);

    expect(
      targetIds,
      contains(bossCharId),
      reason: '护法全灭 → Boss 进池,血最低被选中',
    );
  });

  test('测 C:drift 守卫 —— isGuardedBoss 与 wardMultOf 存活判定口径一致', () {
    final aliveState = scenario(guardianAlive: true);
    final aliveBoss =
        aliveState.rightTeam.firstWhere((c) => c.characterId == bossCharId);
    expect(BattleAI.isGuardedBoss(aliveBoss, aliveState), isTrue);
    expect(
      DefaultGroundStrategy.wardMultOf(aliveBoss, aliveState) < 1.0,
      isTrue,
      reason: '护法存活 → 减伤生效',
    );

    final deadState = scenario(guardianAlive: false);
    final deadBoss =
        deadState.rightTeam.firstWhere((c) => c.characterId == bossCharId);
    expect(BattleAI.isGuardedBoss(deadBoss, deadState), isFalse);
    expect(
      DefaultGroundStrategy.wardMultOf(deadBoss, deadState) < 1.0,
      isFalse,
      reason: '护法全灭 → 减伤失效(两侧口径同步)',
    );
  });

  test('测 D(可选):aoe 技也排除被保护 Boss,含护法', () {
    final actor = makeActor(skills: const <SkillDef>[aoeAttack]);
    final boss = makeEnemy(
      charId: bossCharId,
      slotIndex: 0,
      currentHp: 2000,
      enemyDefId: 'boss',
      guardianWardMult: 0.15,
      guardianDefIds: const ['g1'],
    );
    final guardian =
        makeEnemy(charId: guardianCharId, slotIndex: 1, currentHp: 9000, enemyDefId: 'g1');
    final state = BattleState.initial(
      leftTeam: [actor],
      rightTeam: [boss, guardian],
    );

    final (_, targetIds) =
        BattleAI.decide(actor, state, GameRepository.instance.numbers);

    expect(targetIds, isNot(contains(bossCharId)),
        reason: 'aoe 分支也排除被保护 Boss');
    expect(targetIds, contains(guardianCharId), reason: 'aoe 命中护法');
  });
}
