import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/boss_phase_def.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';

/// 第七阶段批二 ① Task 3:Boss 转阶段运行时状态机。
///
/// 验：血量跌破下一阶段 hpThresholdPct → 推进 bossPhaseIndex + 并入解锁招 +
/// 写一条 bossPhaseTransitionTo 的 BattleAction。**纯机制无属性 buff(§5.4)**。
void main() {
  late NumbersConfig numbers;
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
    numbers = GameRepository.instance.numbers;
  });

  // 玩家高伤普攻(确保一击能打 Boss 跌破 50% 阈值)。
  const playerHit = SkillDef(
    id: 'skill_phase_player_hit',
    name: '猛击',
    description: 'Task3 测试玩家普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  // 第二阶段解锁的招(进入 phase 1 时并入 Boss availableSkills)。
  const skillRage = SkillDef(
    id: 'skill_phase_boss_rage',
    name: '怒涛',
    description: 'Task3 phase1 解锁招',
    type: SkillType.powerSkill,
    powerMultiplier: 2000,
    internalForceCost: 100,
    cooldownTurns: 3,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  const bossNormal = SkillDef(
    id: 'skill_phase_boss_normal',
    name: 'Boss普攻',
    description: 'Task3 Boss 起手普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 50,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  const strategy = DefaultGroundStrategy();

  BattleCharacter player({int eqAtk = 1500}) => BattleCharacter(
        characterId: 1,
        name: '玩家',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: 12000,
        currentHp: 12000,
        maxInternalForce: 10000,
        currentInternalForce: 10000,
        speed: 400,
        criticalRate: 0.0,
        evasionRate: 0.0,
        defenseRate: 0.0,
        totalEquipmentAttack: eqAtk,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const <SkillDef>[playerHit],
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: 0,
        slotIndex: 0,
      );

  /// 两阶段 Boss:phase0 满血起始(无解锁),phase1 在 50% 解锁 skillRage。
  BattleCharacter twoPhaseBoss({required int maxHp, required int currentHp}) =>
      BattleCharacter(
        characterId: -1,
        name: '青衫剑客',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: maxHp,
        currentHp: currentHp,
        maxInternalForce: 10000,
        currentInternalForce: 10000,
        speed: 1, // 极慢,本窗口内不还手,只观察玩家命中后转阶段
        criticalRate: 0.0,
        evasionRate: 0.0,
        defenseRate: 0.0,
        totalEquipmentAttack: 500,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const <SkillDef>[bossNormal],
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: 1,
        slotIndex: 0,
        isBoss: true,
        bossPhaseIndex: 0,
        bossPhases: const [
          BossPhaseDef(hpThresholdPct: 1.0),
          BossPhaseDef(
            hpThresholdPct: 0.5,
            unlockSkillIds: ['skill_phase_boss_rage'],
            titleKey: 'boss_phase_rage',
          ),
        ],
        bossPhaseUnlockSkills: const [
          <SkillDef>[],
          <SkillDef>[skillRage],
        ],
      );

  BattleCharacter bossOf(BattleState s) =>
      s.rightTeam.firstWhere((c) => c.characterId == -1);

  test('血量跌破 50% → 进入 phase1:index++ + 并入解锁招 + 写转阶段事件', () {
    // Boss 起始血 = maxHp 的 51%,玩家一击(>1% maxHp)即跌破 50%。
    var s = BattleState.initial(
      leftTeam: [player(eqAtk: 1500)],
      rightTeam: [twoPhaseBoss(maxHp: 50000, currentHp: 25500)],
    );
    final rng = Random(42);
    var guard = 0;
    while (guard < 50 && !s.isFinished && bossOf(s).bossPhaseIndex == 0) {
      s = strategy.tick(s, numbers, rng: rng);
      guard++;
    }
    final boss = bossOf(s);
    expect(boss.bossPhaseIndex, 1, reason: '跌破 50% 应进入 phase1');
    expect(
      boss.availableSkills.any((sk) => sk.id == 'skill_phase_boss_rage'),
      isTrue,
      reason: 'phase1 解锁招应并入 availableSkills',
    );
    final transitions =
        s.actionLog.where((a) => a.bossPhaseTransitionTo != null).toList();
    expect(transitions, hasLength(1),
        reason: '应恰好记录一条转阶段事件');
    expect(transitions.single.bossPhaseTransitionTo, 1);
    expect(transitions.single.bossPhaseTitleKey, 'boss_phase_rage');
    expect(transitions.single.actorId, -1);
  });

  test('非 Boss 敌人(bossPhases==null)永不转阶段:零回归', () {
    const nonBoss = BattleCharacter(
      characterId: -1,
      name: '山贼',
      realmTier: RealmTier.sanLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 8000,
      currentHp: 8000,
      maxInternalForce: 5000,
      currentInternalForce: 5000,
      speed: 1,
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.0,
      totalEquipmentAttack: 300,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: <SkillDef>[bossNormal],
      skillCooldowns: {},
      activeBuffs: [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 1,
      slotIndex: 0,
    );
    var s = BattleState.initial(
      leftTeam: [player(eqAtk: 1000)],
      rightTeam: [nonBoss],
    );
    final rng = Random(42);
    var guard = 0;
    while (guard < 30 && !s.isFinished) {
      s = strategy.tick(s, numbers, rng: rng);
      guard++;
    }
    expect(bossOf(s).bossPhaseIndex, 0, reason: '非 Boss 永远停在 index 0');
    expect(
      s.actionLog.where((a) => a.bossPhaseTransitionTo != null),
      isEmpty,
      reason: '非 Boss 不产生转阶段事件',
    );
  });

  test('单次大伤跨越两个阈值 → 一次结算推进到末阶段(不停在中间)', () {
    // 三阶段 Boss:phase0(1.0) / phase1(0.6) / phase2(0.2)。
    // Boss maxHp=250000:一击约 204000 伤害落在 60% 阈值(150000)与 0 之间,
    // 残血约 46000 ≈ 18.4% maxHp < 20%,跨越 phase1+phase2 两个阈值但 Boss 存活。
    const boss = BattleCharacter(
      characterId: -1,
      name: '魔头',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 250000,
      currentHp: 250000,
      maxInternalForce: 10000,
      currentInternalForce: 10000,
      speed: 1,
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.0,
      totalEquipmentAttack: 500,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: <SkillDef>[bossNormal],
      skillCooldowns: {},
      activeBuffs: [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 1,
      slotIndex: 0,
      isBoss: true,
      bossPhaseIndex: 0,
      bossPhases: [
        BossPhaseDef(hpThresholdPct: 1.0),
        BossPhaseDef(
            hpThresholdPct: 0.6,
            unlockSkillIds: ['skill_phase_boss_rage'],
            titleKey: 'boss_phase_p1'),
        BossPhaseDef(hpThresholdPct: 0.2, titleKey: 'boss_phase_p2'),
      ],
      bossPhaseUnlockSkills: [
        <SkillDef>[],
        <SkillDef>[skillRage],
        <SkillDef>[],
      ],
    );
    // 玩家高内力 + 高装攻 → 一击约 204000 伤害。
    // 250000 - 204000 ≈ 46000(~18% maxHp),跨越两阈值(60%/20%)但 Boss 存活。
    final bigHitter = player(eqAtk: 2000).copyWith(
      currentInternalForce: 15000,
      mainCultivationLayer: CultivationLayer.jiJing,
    );
    var s = BattleState.initial(leftTeam: [bigHitter], rightTeam: [boss]);
    final rng = Random(42);
    var guard = 0;
    while (guard < 20 && !s.isFinished && bossOf(s).bossPhaseIndex < 2) {
      s = strategy.tick(s, numbers, rng: rng);
      guard++;
    }
    final after = bossOf(s);
    // Boss 必须存活才能验证多阶段推进机制。
    expect(after.isAlive, isTrue,
        reason: 'Boss 必须存活才能验证多阈值推进(hp=${after.currentHp})');
    expect(after.bossPhaseIndex, 2,
        reason: '一击跨越两阈值应推进到末阶段(hp=${after.currentHp})');
    final transitions =
        s.actionLog.where((a) => a.bossPhaseTransitionTo != null).toList();
    expect(transitions.map((a) => a.bossPhaseTransitionTo), [1, 2],
        reason: '应按顺序记录两条转阶段事件(1 then 2)');
  });
}
