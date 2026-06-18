import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';

/// 第六阶段 Task 2:破防开窗 - 统一破招/破防窗口字段 + 刷新不叠加 + 减防上限 clamp。
///
/// 覆盖三个场景:
/// A. 破防技命中存活非蓄力目标 → 开窗(staggerTicks = windowTicks, override = breakPct,
///    BattleAction.openedBreakWindow == true)。
/// B. 刷新不叠加:已有更强 override(0.4)时,较弱 0.2 破防命中 → 取 max(0.4),
///    staggerTicks 刷新到 windowTicks。
/// C. 普通技(defenseBreakPct == 0)命中非蓄力目标 → 不开窗(openedBreakWindow == false,
///    stagger 不变)。
void main() {
  late NumbersConfig numbers;

  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
    numbers = GameRepository.instance.numbers;
  });

  // ─── 共用 SkillDef 常量 ───────────────────────────────────────────────────

  /// 破防技:defenseBreakPct = 0.3。
  const breakSkill = SkillDef(
    id: 'skill_t2_break',
    name: '破防斩',
    description: '第六阶段 Task2 破防测试技',
    type: SkillType.powerSkill,
    powerMultiplier: 1000,
    internalForceCost: 50,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
    defenseBreakPct: 0.3,
  );

  /// 弱破防技:defenseBreakPct = 0.2(用于刷新不叠加场景)。
  const weakBreakSkill = SkillDef(
    id: 'skill_t2_weak_break',
    name: '破防刺',
    description: '第六阶段 Task2 弱破防测试技',
    type: SkillType.powerSkill,
    powerMultiplier: 1000,
    internalForceCost: 50,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
    defenseBreakPct: 0.2,
  );

  /// 普通攻击:defenseBreakPct = 0.0(默认)。
  const normalSkill = SkillDef(
    id: 'skill_t2_normal',
    name: '普攻',
    description: '第六阶段 Task2 普通技',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  // ─── 辅助:构造 BattleState ─────────────────────────────────────────────────

  /// 攻方(左,高速先手)+守方(右,极慢不先手)。
  /// [defenderStaggerTicks] / [defenderStaggerDef] 允许预设踉跄状态测刷新场景。
  BattleState makeState({
    required SkillDef attackerSkill,
    int defenderStaggerTicks = 0,
    double? defenderStaggerDef,
  }) {
    final attacker = BattleCharacter(
      characterId: 1,
      name: '攻方',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 12000,
      currentHp: 12000,
      maxInternalForce: 10000,
      currentInternalForce: 10000,
      speed: 400, // 先手
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.0,
      totalEquipmentAttack: 1500,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: <SkillDef>[attackerSkill],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 0,
      slotIndex: 0,
    );
    final defender = BattleCharacter(
      characterId: 2,
      name: '守方',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 50000,
      currentHp: 50000,
      maxInternalForce: 10000,
      currentInternalForce: 10000,
      speed: 1, // 极慢,本轮不先手
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.3,
      totalEquipmentAttack: 500,
      mainCultivationLayer: CultivationLayer.chuKui,
      availableSkills: const <SkillDef>[normalSkill],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 1,
      slotIndex: 0,
      // 预设踉跄(刷新场景)
      staggerTicksRemaining: defenderStaggerTicks,
      staggerDefenseDownOverride: defenderStaggerDef,
    );
    return BattleState.initial(leftTeam: [attacker], rightTeam: [defender]);
  }

  const strategy = DefaultGroundStrategy();

  BattleCharacter defenderOf(BattleState s) =>
      s.rightTeam.firstWhere((c) => c.characterId == 2);

  // ─── 场景 A:破防技命中非蓄力存活目标 → 开窗 ──────────────────────────────

  test('A 破防技命中非蓄力存活目标 → 开窗', () {
    var s = makeState(attackerSkill: breakSkill);
    // 确认守方不在蓄力状态。
    expect(defenderOf(s).staggerTicksRemaining, 0);
    expect(defenderOf(s).chargingSkill, isNull,
        reason: '守方初始不蓄力');

    final rng = Random(42);
    // 推进直到攻方完成第一次命中(守方 HP 下降)。
    final hpBefore = defenderOf(s).currentHp;
    var guard = 0;
    while (guard < 50 && defenderOf(s).currentHp >= hpBefore && !s.isFinished) {
      s = strategy.tick(s, numbers, rng: rng);
      guard++;
    }
    expect(defenderOf(s).currentHp, lessThan(hpBefore),
        reason: '守方应被命中掉血');

    // 破防开窗断言。
    expect(
      defenderOf(s).staggerTicksRemaining,
      numbers.combat.defenseBreak.windowTicks,
      reason: 'staggerTicksRemaining 应 == defenseBreak.windowTicks',
    );
    expect(
      defenderOf(s).staggerDefenseDownOverride,
      closeTo(0.3, 1e-9),
      reason: 'staggerDefenseDownOverride 应 == skill.defenseBreakPct(0.3)',
    );

    // BattleAction 标记断言。
    final breakActions =
        s.actionLog.where((a) => a.openedBreakWindow).toList();
    expect(
      breakActions,
      isNotEmpty,
      reason: '至少一条 BattleAction.openedBreakWindow == true',
    );
  });

  // ─── 场景 B:刷新不叠加 ─────────────────────────────────────────────────────

  test('B 刷新不叠加:较弱破防命中已有更强 override → 取 max,ticks 刷新', () {
    // 守方已有较强减防 override = 0.4,staggerTicks = 1(窗口快结束)。
    var s = makeState(
      attackerSkill: weakBreakSkill, // defenseBreakPct = 0.2
      defenderStaggerTicks: 1,
      defenderStaggerDef: 0.4, // 已有更强 override
    );

    final rng = Random(42);
    final hpBefore = defenderOf(s).currentHp;
    var guard = 0;
    while (guard < 50 && defenderOf(s).currentHp >= hpBefore && !s.isFinished) {
      s = strategy.tick(s, numbers, rng: rng);
      guard++;
    }
    expect(defenderOf(s).currentHp, lessThan(hpBefore),
        reason: '守方应被命中');

    // max(0.4, 0.2) = 0.4 保留,不被弱覆盖。
    expect(
      defenderOf(s).staggerDefenseDownOverride,
      closeTo(0.4, 1e-9),
      reason: '刷新不叠加:max(旧=0.4, 新=0.2) = 0.4',
    );
    // ticks 刷新到 windowTicks(不再是 1)。
    expect(
      defenderOf(s).staggerTicksRemaining,
      numbers.combat.defenseBreak.windowTicks,
      reason: 'staggerTicksRemaining 应刷新至 windowTicks',
    );
  });

  // ─── 场景 D:超额破防 clamp 到 interruptPowerCap ─────────────────────────────

  test('D 破防 pct=0.8 命中非蓄力目标 → staggerDefenseDownOverride clamp 到 cap(0.5)', () {
    // defenseBreakPct = 0.8 超过 interruptPowerCap(0.5) → clamp 到 0.5。
    const overpowerBreakSkill = SkillDef(
      id: 'skill_t2_overpower_break',
      name: '强力破防斩',
      description: '第六阶段 Task2 clamp 测试技',
      type: SkillType.powerSkill,
      powerMultiplier: 1000,
      internalForceCost: 50,
      cooldownTurns: 0,
      requiresManualTrigger: false,
      visualEffect: 'stub',
      defenseBreakPct: 0.8,
    );
    var s = makeState(attackerSkill: overpowerBreakSkill);
    expect(defenderOf(s).chargingSkill, isNull, reason: '守方初始不蓄力');

    final rng = Random(42);
    final hpBefore = defenderOf(s).currentHp;
    var guard = 0;
    while (guard < 50 && defenderOf(s).currentHp >= hpBefore && !s.isFinished) {
      s = strategy.tick(s, numbers, rng: rng);
      guard++;
    }
    expect(defenderOf(s).currentHp, lessThan(hpBefore), reason: '守方应被命中掉血');

    // clamp 断言:0.8 被上限截到 interruptPowerCap = 0.5。
    expect(
      defenderOf(s).staggerDefenseDownOverride,
      closeTo(0.5, 1e-9),
      reason: 'defenseBreakPct(0.8) > cap(0.5) → clamp 到 interruptPowerCap ceiling(§5.4)',
    );
  });

  // ─── 场景 C:普通技不开窗 ──────────────────────────────────────────────────

  test('C 普通技(defenseBreakPct==0)不开窗', () {
    var s = makeState(attackerSkill: normalSkill);
    final rng = Random(42);
    final hpBefore = defenderOf(s).currentHp;
    var guard = 0;
    while (guard < 50 && defenderOf(s).currentHp >= hpBefore && !s.isFinished) {
      s = strategy.tick(s, numbers, rng: rng);
      guard++;
    }
    expect(defenderOf(s).currentHp, lessThan(hpBefore),
        reason: '普攻应命中');

    // 不开窗。
    expect(defenderOf(s).staggerTicksRemaining, 0,
        reason: '普攻不开破防窗口,stagger 维持 0');
    final breakActions =
        s.actionLog.where((a) => a.openedBreakWindow).toList();
    expect(breakActions, isEmpty,
        reason: '普攻无 openedBreakWindow=true 的动作');
  });
}
