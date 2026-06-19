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
    //
    // bigHitter 配置:内力 15000 / 装攻 2000 / 修炼度 jiJing(×3.0) / 刚猛流派
    // 公式:base = 15000×0.4 + 2000×1.0 + 500 = 8500
    //       最终 = 8500 × 3.0 × 1.0(中性) × 1.0(无暴击) × 1.0(无防御) = 25500
    // Boss maxHp=30000:阈值 60%=18000 / 20%=6000
    //   一击 25500 → 残血 4500(15% maxHp) — 同时跌破两阈值且 Boss 存活。
    //   这迫使 _advancePhases while-loop 单结算内连续推进 phase0→1→2。
    const boss = BattleCharacter(
      characterId: -1,
      name: '魔头',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 30000,
      currentHp: 30000,
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
    // bigHitter:单击约 25500 伤(无防御/无暴击/同境界)。
    // maxHp=30000 → 30000-25500=4500(15%)<20% 阈值,单结算跨越两阈值,Boss 存活。
    // speed=1000:第一个 tick 内 AP += 1000 → 恰好达到 1000,玩家首 tick 即出手。
    final bigHitter = player(eqAtk: 2000).copyWith(
      currentInternalForce: 15000,
      mainCultivationLayer: CultivationLayer.jiJing,
      speed: 1000,
    );
    // 只推进一个 tick:bigHitter speed=1000 第一个 tick 即出手,Boss speed=1 不出手。
    // 一击后 Boss 必须同时跨越两个阈值,验证单结算多阈值路径(_advancePhases loop)。
    var s = BattleState.initial(leftTeam: [bigHitter], rightTeam: [boss]);
    s = strategy.tick(s, numbers, rng: Random(42));
    final after = bossOf(s);
    // Boss 必须存活才能验证多阶段推进机制。
    expect(after.isAlive, isTrue,
        reason: 'Boss 必须存活才能验证多阈值推进(hp=${after.currentHp})');
    expect(after.bossPhaseIndex, 2,
        reason: '单结算应推进到末阶段 2(hp=${after.currentHp})');
    final transitions =
        s.actionLog.where((a) => a.bossPhaseTransitionTo != null).toList();
    expect(transitions.map((a) => a.bossPhaseTransitionTo), [1, 2],
        reason: '应按顺序记录两条转阶段事件(1 then 2),且均在同一结算中产生');
  });
}
