import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/boss_phase_def.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_ai.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';

/// 第七阶段批二 ① Task 4:转阶段 telegraphed 蓄力反扑(A) + aiMode 接 BattleAI(B/C)。
///
/// A. onEnterMechanic==chargeCounter:进阶时立即把 Boss 推入蓄力态,蓄招 = 该阶段
///    解锁招里 powerMultiplier 最高者,蓄力 tick 复用 bossCharge.defaultChargeTicks。
/// B. aiMode==aggressive:_pickSkill 优先打本阶段解锁招(可用里 powerMultiplier 最高)。
/// C. aiMode==focus:decide 选目标恒走血最低(不偏好破绽窗口目标)。
/// 全程纯机制无属性 buff(§5.4)。
void main() {
  late NumbersConfig numbers;
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
    numbers = GameRepository.instance.numbers;
  });

  const playerHit = SkillDef(
    id: 'skill_ai_player_hit',
    name: '猛击',
    description: '玩家普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  // Boss 普攻(起手默认招)。
  const bossNormal = SkillDef(
    id: 'skill_ai_boss_normal',
    name: 'Boss普攻',
    description: 'Boss 起手普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 50,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  // 阶段解锁招:低威力强力技。
  const skillLow = SkillDef(
    id: 'skill_ai_boss_low',
    name: '轻击',
    description: '低威力阶段招',
    type: SkillType.powerSkill,
    powerMultiplier: 800,
    internalForceCost: 100,
    cooldownTurns: 3,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  // 阶段解锁招:高威力强力技(招牌)。
  const skillHigh = SkillDef(
    id: 'skill_ai_boss_high',
    name: '怒涛',
    description: '高威力阶段招(招牌)',
    type: SkillType.powerSkill,
    powerMultiplier: 2500,
    internalForceCost: 100,
    cooldownTurns: 3,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  const strategy = DefaultGroundStrategy();

  BattleCharacter player({int eqAtk = 1500, int slotIndex = 0, int id = 1}) =>
      BattleCharacter(
        characterId: id,
        name: '玩家$id',
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
        slotIndex: slotIndex,
      );

  // ── A. chargeCounter ──
  test('A: 进入 chargeCounter 阶段 → Boss 立即蓄招(蓄解锁招里最高威力的招)', () {
    // 两阶段 Boss:phase1 在 50% onEnterMechanic=chargeCounter,解锁 [低, 高] 两招。
    // 起始血 51% → 玩家一击跌破 50% 进阶。
    const boss = BattleCharacter(
      characterId: -1,
      name: '青衫剑客',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 50000,
      currentHp: 25500,
      maxInternalForce: 10000,
      currentInternalForce: 10000,
      speed: 1, // 极慢,本窗口不还手
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
          hpThresholdPct: 0.5,
          unlockSkillIds: ['skill_ai_boss_low', 'skill_ai_boss_high'],
          onEnterMechanic: BossPhaseMechanic.chargeCounter,
          titleKey: 'boss_phase_charge',
        ),
      ],
      bossPhaseUnlockSkills: [
        <SkillDef>[],
        <SkillDef>[skillLow, skillHigh],
      ],
    );
    var s = BattleState.initial(
      leftTeam: [player(eqAtk: 1500)],
      rightTeam: [boss],
    );
    final rng = Random(42);
    var guard = 0;
    BattleCharacter bossOf(BattleState st) =>
        st.rightTeam.firstWhere((c) => c.characterId == -1);
    while (guard < 50 && !s.isFinished && bossOf(s).bossPhaseIndex == 0) {
      s = strategy.tick(s, numbers, rng: rng);
      guard++;
    }
    final after = bossOf(s);
    expect(after.bossPhaseIndex, 1, reason: '应进入 phase1');
    expect(after.chargingSkill, isNotNull, reason: '进 chargeCounter 阶段应立即蓄力');
    expect(after.chargingSkill!.id, 'skill_ai_boss_high',
        reason: '蓄招应为解锁招里 powerMultiplier 最高者');
    expect(after.chargeTicksRemaining, numbers.combat.bossCharge.defaultChargeTicks,
        reason: '蓄力 tick 应复用 bossCharge.defaultChargeTicks');
  });

  test('A: chargeCounter 阶段解锁招为空 → 不蓄力不崩', () {
    const boss = BattleCharacter(
      characterId: -1,
      name: '无招Boss',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 50000,
      currentHp: 25500,
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
          hpThresholdPct: 0.5,
          onEnterMechanic: BossPhaseMechanic.chargeCounter,
        ),
      ],
      bossPhaseUnlockSkills: [<SkillDef>[], <SkillDef>[]],
    );
    var s = BattleState.initial(
      leftTeam: [player(eqAtk: 1500)],
      rightTeam: [boss],
    );
    final rng = Random(42);
    var guard = 0;
    BattleCharacter bossOf(BattleState st) =>
        st.rightTeam.firstWhere((c) => c.characterId == -1);
    while (guard < 50 && !s.isFinished && bossOf(s).bossPhaseIndex == 0) {
      s = strategy.tick(s, numbers, rng: rng);
      guard++;
    }
    final after = bossOf(s);
    expect(after.bossPhaseIndex, 1);
    expect(after.chargingSkill, isNull, reason: '无解锁招不蓄力(no-op)');
  });

  // ── B. aggressive ──
  // 蓄到一阶段中 phase 已解锁 skillHigh + skillLow 的 Boss,直接调 BattleAI.decide。
  BattleCharacter aggressiveBoss({required BossAiMode aiMode}) =>
      BattleCharacter(
        characterId: -1,
        name: '狂暴Boss',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: 50000,
        currentHp: 25000,
        maxInternalForce: 10000,
        currentInternalForce: 10000,
        speed: 300,
        criticalRate: 0.0,
        evasionRate: 0.0,
        defenseRate: 0.0,
        totalEquipmentAttack: 500,
        mainCultivationLayer: CultivationLayer.daCheng,
        // 当前已在 phase1:availableSkills 含普攻 + 两阶段招(已 merge)。
        availableSkills: const <SkillDef>[bossNormal, skillLow, skillHigh],
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: 1,
        slotIndex: 0,
        isBoss: true,
        bossPhaseIndex: 1,
        bossPhases: [
          const BossPhaseDef(hpThresholdPct: 1.0),
          BossPhaseDef(
            hpThresholdPct: 0.5,
            unlockSkillIds: const ['skill_ai_boss_low', 'skill_ai_boss_high'],
            aiMode: aiMode,
          ),
        ],
        bossPhaseUnlockSkills: const [
          <SkillDef>[],
          <SkillDef>[skillLow, skillHigh],
        ],
      );

  test('B: aggressive 阶段 → decide 返回本阶段最高威力解锁招', () {
    final s = BattleState.initial(
      leftTeam: [player(eqAtk: 1500)],
      rightTeam: [aggressiveBoss(aiMode: BossAiMode.aggressive)],
    );
    final boss = s.rightTeam.first;
    final (skill, _) = BattleAI.decide(boss, s, numbers);
    expect(skill.id, 'skill_ai_boss_high',
        reason: 'aggressive 应优先放本阶段最高威力解锁招');
  });

  test('B: normal 阶段(对照) → decide 返回默认 powerSkill 选择(仍最高威力,但走默认路径)', () {
    // 对照:normal 模式走默认 _pickSkill。默认 powerSkill 也会挑最高威力,
    // 所以结果同为 high;关键对照点在 aggressive 即便默认排序埋了招也能挑出。
    // 为真正区分,给 normal Boss 一个高威力 NON-phase 强力技占位,验证默认仍走全局挑选。
    const globalHigh = SkillDef(
      id: 'skill_ai_boss_global_high',
      name: '全局强招',
      description: '非阶段解锁的更高威力强力技',
      type: SkillType.powerSkill,
      powerMultiplier: 3000,
      internalForceCost: 100,
      cooldownTurns: 3,
      requiresManualTrigger: false,
      visualEffect: 'stub',
    );
    final normalBoss = aggressiveBoss(aiMode: BossAiMode.normal).copyWith(
      availableSkills: const <SkillDef>[
        bossNormal,
        skillLow,
        skillHigh,
        globalHigh,
      ],
    );
    final aggBoss = aggressiveBoss(aiMode: BossAiMode.aggressive).copyWith(
      availableSkills: const <SkillDef>[
        bossNormal,
        skillLow,
        skillHigh,
        globalHigh,
      ],
    );
    final sNormal =
        BattleState.initial(leftTeam: [player()], rightTeam: [normalBoss]);
    final sAgg =
        BattleState.initial(leftTeam: [player()], rightTeam: [aggBoss]);
    final (normalSkill, _) = BattleAI.decide(sNormal.rightTeam.first, sNormal, numbers);
    final (aggSkill, _) = BattleAI.decide(sAgg.rightTeam.first, sAgg, numbers);
    // normal 走默认 → 全局最高威力 globalHigh(3000)。
    expect(normalSkill.id, 'skill_ai_boss_global_high',
        reason: 'normal 默认路径挑全局最高威力,即便它不是本阶段招');
    // aggressive 优先本阶段解锁招里最高(skillHigh 2500),不碰非阶段 globalHigh。
    expect(aggSkill.id, 'skill_ai_boss_high',
        reason: 'aggressive 限定本阶段解锁招,挑其中最高(忽略更高的非阶段招)');
  });

  test('B: aggressive 但本阶段招都不可用 → 回落默认选择', () {
    // 两阶段招都 CD 中 → aggressive 回落默认 _pickSkill(普攻兜底)。
    final boss = aggressiveBoss(aiMode: BossAiMode.aggressive).copyWith(
      skillCooldowns: const {'skill_ai_boss_low': 2, 'skill_ai_boss_high': 2},
    );
    final s = BattleState.initial(leftTeam: [player()], rightTeam: [boss]);
    final (skill, _) = BattleAI.decide(s.rightTeam.first, s, numbers);
    expect(skill.id, 'skill_ai_boss_normal',
        reason: '阶段招全 CD → 回落默认(无其它强力技 → 普攻兜底)');
  });

  // ── C. focus ──
  BattleCharacter focusBoss({required BossAiMode aiMode}) => BattleCharacter(
        characterId: -1,
        name: '专注Boss',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: 50000,
        currentHp: 25000,
        maxInternalForce: 10000,
        currentInternalForce: 10000,
        speed: 300,
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
        bossPhaseIndex: 1,
        bossPhases: [
          const BossPhaseDef(hpThresholdPct: 1.0),
          BossPhaseDef(hpThresholdPct: 0.5, aiMode: aiMode),
        ],
        bossPhaseUnlockSkills: const [<SkillDef>[], <SkillDef>[]],
      );

  test('C: focus vs normal 目标选择差异(破绽窗口 高血 vs 无破绽 低血)', () {
    // enemy A(slot0):高血 + 破绽窗口(staggerTicksRemaining>0)。
    // enemy B(slot1):低血 + 无破绽。
    final enemyA = player(id: 10, slotIndex: 0).copyWith(
      currentHp: 11000,
      staggerTicksRemaining: 2,
    );
    final enemyB = player(id: 11, slotIndex: 1).copyWith(
      currentHp: 3000,
      staggerTicksRemaining: 0,
    );

    final sNormal = BattleState.initial(
      leftTeam: [enemyA, enemyB],
      rightTeam: [focusBoss(aiMode: BossAiMode.normal)],
    );
    final sFocus = BattleState.initial(
      leftTeam: [enemyA, enemyB],
      rightTeam: [focusBoss(aiMode: BossAiMode.focus)],
    );
    final (_, normalTargets) =
        BattleAI.decide(sNormal.rightTeam.first, sNormal, numbers);
    final (_, focusTargets) =
        BattleAI.decide(sFocus.rightTeam.first, sFocus, numbers);
    expect(normalTargets.single, 10,
        reason: 'normal 偏好破绽窗口目标(enemyA,即便血更高)');
    expect(focusTargets.single, 11,
        reason: 'focus 恒打血最低(enemyB),不偏好破绽窗口');
    expect(normalTargets.single != focusTargets.single, isTrue,
        reason: '两模式目标必须不同');
  });

  // ── D. 零回归 ──
  test('D: 无 bossPhases 普通敌人 → decide 与改动前一致(默认路径)', () {
    const plainEnemy = BattleCharacter(
      characterId: -1,
      name: '山贼',
      realmTier: RealmTier.sanLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 8000,
      currentHp: 8000,
      maxInternalForce: 5000,
      currentInternalForce: 5000,
      speed: 200,
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.0,
      totalEquipmentAttack: 300,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: <SkillDef>[bossNormal, skillHigh],
      skillCooldowns: {},
      activeBuffs: [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 1,
      slotIndex: 0,
    );
    final lowHp = player(id: 20, slotIndex: 0).copyWith(currentHp: 2000);
    final highHp = player(id: 21, slotIndex: 1).copyWith(currentHp: 11000);
    final s = BattleState.initial(
      leftTeam: [highHp, lowHp],
      rightTeam: [plainEnemy],
    );
    final (skill, targets) = BattleAI.decide(s.rightTeam.first, s, numbers);
    // 默认 _pickSkill:有可用 powerSkill(skillHigh,内力 5000>=100,CD 0)→ 挑它。
    expect(skill.id, 'skill_ai_boss_high', reason: '默认挑最高威力 powerSkill');
    // 默认目标:无破绽 → _pickTargetId 血最低 = lowHp(id 20)。
    expect(targets.single, 20, reason: '默认走血最低目标');
  });
}
