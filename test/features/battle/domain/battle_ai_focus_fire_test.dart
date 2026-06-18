import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_ai.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

/// 第六阶段 Task 3:AI 集火破绽窗口敌目标优先级测试。
///
/// **不变量**:
///   - 当对面有处于破绽窗口(staggerTicksRemaining>0)的活角色时,
///     decide 优先集火该角色,即使其 HP 高于普通敌人。
///   - 当无破绽敌时,回落到 HP 最低逻辑(_pickTargetId)。
///   - 多个破绽敌时,在破绽敌集合内按 HP 最低→slotIndex 最小选目标。
///
/// **测试 A**:e0(HP低,stagger=0) vs e1(HP高,stagger=3) → 应集火 e1。
/// **测试 B**:无破绽窗口敌 → 回落 HP 最低(e0)。
/// **测试 C**:多个破绽敌中选 HP 最低/slotIndex 最小的。
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

  // NON-canInterrupt 普攻:不会走破招锁定蓄力逻辑,直接落到集火/血最低分支。
  const normalAttack = SkillDef(
    id: 'skill_ff_normal',
    name: '普攻(集火测stub)',
    description: '第六阶段集火测普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
    canInterrupt: false, // 明确:不能破招,不进 canInterrupt 分支
  );

  BattleCharacter makeActor() => const BattleCharacter(
        characterId: 100,
        name: '玩家(集火测)',
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
        availableSkills: <SkillDef>[normalAttack],
        skillCooldowns: <String, int>{},
        activeBuffs: [],
        actionPoint: 0,
        isAlive: true,
        teamSide: 0,
        slotIndex: 0,
      );

  BattleCharacter makeEnemy({
    required int charId,
    required int slotIndex,
    required int currentHp,
    int staggerTicksRemaining = 0,
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
        staggerTicksRemaining: staggerTicksRemaining,
      );

  test(
    '测 A:有破绽窗口敌(HP高) → 集火破绽窗口敌,忽略血更低的普通敌',
    () {
      final actor = makeActor();
      // e0:HP 低(3000),无破绽窗口 → 默认血最低逻辑会选它。
      final e0 = makeEnemy(charId: 11, slotIndex: 0, currentHp: 3000, staggerTicksRemaining: 0);
      // e1:HP 高(8000),破绽窗口 stagger=3 → 集火应选它。
      final e1 = makeEnemy(charId: 12, slotIndex: 1, currentHp: 8000, staggerTicksRemaining: 3);

      final state = BattleState.initial(
        leftTeam: [actor],
        rightTeam: [e0, e1],
      );

      final (skill, targetIds) =
          BattleAI.decide(actor, state, GameRepository.instance.numbers);

      expect(skill.id, normalAttack.id, reason: '应用普攻(唯一可用技)');
      expect(
        targetIds.first,
        e1.characterId,
        reason: '第六阶段集火:应优先攻击破绽窗口敌(e1,stagger=3),'
            '而非血最低敌(e0,HP=3000)',
      );
    },
  );

  test(
    '测 B:无破绽窗口敌 → 回落 HP 最低逻辑(e0)',
    () {
      final actor = makeActor();
      // 所有敌人 stagger=0 → 无破绽窗口,应回落到血最低。
      final e0 = makeEnemy(charId: 21, slotIndex: 0, currentHp: 2000, staggerTicksRemaining: 0);
      final e1 = makeEnemy(charId: 22, slotIndex: 1, currentHp: 9000, staggerTicksRemaining: 0);

      final state = BattleState.initial(
        leftTeam: [actor],
        rightTeam: [e0, e1],
      );

      final (_, targetIds) =
          BattleAI.decide(actor, state, GameRepository.instance.numbers);

      expect(
        targetIds.first,
        e0.characterId,
        reason: '无破绽窗口敌时回落血最低逻辑,应选 e0(HP=2000)',
      );
    },
  );

  test(
    '测 C:多个破绽窗口敌 → 在破绽敌集合内选 HP 最低;HP 相等时选 slotIndex 小',
    () {
      final actor = makeActor();
      // e0:破绽窗口,HP=5000,slot=0
      final e0 = makeEnemy(charId: 31, slotIndex: 0, currentHp: 5000, staggerTicksRemaining: 2);
      // e1:破绽窗口,HP=3000,slot=1 → HP 最低,应选
      final e1 = makeEnemy(charId: 32, slotIndex: 1, currentHp: 3000, staggerTicksRemaining: 4);
      // e2:无破绽窗口,HP=1000 → HP 最低但无破绽,不应选
      final e2 = makeEnemy(charId: 33, slotIndex: 2, currentHp: 1000, staggerTicksRemaining: 0);

      final state = BattleState.initial(
        leftTeam: [actor],
        rightTeam: [e0, e1, e2],
      );

      final (_, targetIds) =
          BattleAI.decide(actor, state, GameRepository.instance.numbers);

      expect(
        targetIds.first,
        e1.characterId,
        reason: '多破绽敌中应选 HP 最低(e1,HP=3000),而非全局 HP 最低(e2,HP=1000,无破绽)',
      );

      // 子测:HP 相等时选 slotIndex 小
      final eqA = makeEnemy(charId: 41, slotIndex: 1, currentHp: 4000, staggerTicksRemaining: 3);
      final eqB = makeEnemy(charId: 42, slotIndex: 0, currentHp: 4000, staggerTicksRemaining: 3);
      final actor2 = makeActor().copyWith(characterId: 101);
      final state2 = BattleState.initial(
        leftTeam: [actor2],
        rightTeam: [eqA, eqB],
      );
      final (_, targetIds2) =
          BattleAI.decide(actor2, state2, GameRepository.instance.numbers);
      expect(
        targetIds2.first,
        eqB.characterId,
        reason: 'HP 相等时 slotIndex 小者(eqB,slot=0)优先',
      );
    },
  );
}
