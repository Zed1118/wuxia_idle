import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';

/// 第五阶段 · aoe 群体技全体伤害结算红线(Task 3)。
///
/// **不变量**:aoe 群体技对全体存活敌人各造成完整单体伤害(无衰减)——
/// 不是只打 `targetIds.first`。各目标基于行动前快照独立结算(同时命中),
/// 前一个被打死不改变后一个的输入;rng 按 targetIds(slotIndex 升序)顺序消费。
///
/// **场景**:主控带 aoe powerSkill(AI 自动挑最高倍率) + 3 活敌不同 hp/slotIndex。
/// criticalRate=0 / evasionRate=0 → 伤害全确定(无 rng 分支),便于断言「aoe 对
/// 某敌扣血 == 同条件 single 技对该敌单体伤害」证各目标 = 完整单体值。
void main() {
  setUpAll(() async {
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(
        loader: (path) => File(path).readAsString(),
      );
    }
  });

  // 普攻兜底(cost=0 / cd=0)。
  const normal = SkillDef(
    id: 'skill_aoe_test_normal',
    name: '普攻',
    description: 'aoe 测普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  // aoe 群体强力技(powerSkill → AI 自动挑;倍率高于普攻 → 优先)。
  const aoePower = SkillDef(
    id: 'skill_aoe_test_power',
    name: '群体技',
    description: 'aoe 测群体技',
    type: SkillType.powerSkill,
    targetType: TargetType.aoe,
    powerMultiplier: 1500,
    internalForceCost: 100,
    cooldownTurns: 2,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  // 同倍率/同 cost 的单体技(对照组,证 aoe 各目标 = 单体值无衰减)。
  const singlePower = SkillDef(
    id: 'skill_aoe_test_single',
    name: '单体技',
    description: 'aoe 测单体对照',
    type: SkillType.powerSkill,
    powerMultiplier: 1500,
    internalForceCost: 100,
    cooldownTurns: 2,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  /// 主控攻击者:actionPoint=1000 立即出手;criticalRate/evasion 全 0 → 确定性。
  BattleCharacter attacker({required List<SkillDef> skills}) => BattleCharacter(
        characterId: 1,
        name: '主控',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: 20000,
        currentHp: 20000,
        maxInternalForce: 3000,
        currentInternalForce: 3000,
        speed: 130,
        criticalRate: 0.0,
        evasionRate: 0.0,
        defenseRate: 0.1,
        totalEquipmentAttack: 800,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: skills,
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 1000,
        isAlive: true,
        teamSide: 0,
        slotIndex: 0,
      );

  /// 敌人:evasionRate=0 必中,actionPoint=0 不会在主控之前出手。
  BattleCharacter enemy({
    required int charId,
    required int slot,
    required int hp,
  }) =>
      BattleCharacter(
        characterId: charId,
        name: '敌$slot',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng, // 同流派 → 克制 1.0,无随机
        maxHp: hp,
        currentHp: hp,
        maxInternalForce: 1000,
        currentInternalForce: 1000,
        speed: 50,
        criticalRate: 0.0,
        evasionRate: 0.0,
        defenseRate: 0.1,
        totalEquipmentAttack: 300,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const [normal],
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: 1,
        slotIndex: slot,
      );

  test('aoe 命中全体:3 活敌全部扣血(各 currentHp 下降),不只打 first', () {
    final n = GameRepository.instance.numbers;
    const strategy = DefaultGroundStrategy();
    final left = [attacker(skills: const [aoePower, normal])];
    final right = [
      enemy(charId: 11, slot: 0, hp: 9000),
      enemy(charId: 12, slot: 1, hp: 12000),
      enemy(charId: 13, slot: 2, hp: 15000),
    ];
    var s = BattleState.initial(leftTeam: left, rightTeam: right);
    s = strategy.tick(s, n, rng: Random(7));

    // 主控用的应该是 aoe 技。
    final firstAttack =
        s.actionLog.firstWhere((a) => a.actorId == 1 && a.skill != null);
    expect(firstAttack.skill!.id, aoePower.id,
        reason: 'AI 应自动挑 aoe powerSkill(倍率 > 普攻)');

    for (final orig in right) {
      final after = s.rightTeam.firstWhere((c) => c.characterId == orig.characterId);
      expect(after.currentHp, lessThan(orig.currentHp),
          reason: 'aoe 应对全体敌人(charId=${orig.characterId})各造成伤害,'
              '当前只打 first → 本断言对非 first 敌人 FAIL');
    }
  });

  test('aoe 无衰减:对某敌扣血 == 同条件 single 技对该敌单体伤害', () {
    final n = GameRepository.instance.numbers;
    const strategy = DefaultGroundStrategy();

    // ── aoe 跑:打全体,取对 slot1 敌人(charId 12)的扣血 ──
    final aoeRight = [
      enemy(charId: 11, slot: 0, hp: 9000),
      enemy(charId: 12, slot: 1, hp: 12000),
      enemy(charId: 13, slot: 2, hp: 15000),
    ];
    var aoeState = BattleState.initial(
      leftTeam: [attacker(skills: const [aoePower, normal])],
      rightTeam: aoeRight,
    );
    aoeState = strategy.tick(aoeState, n, rng: Random(7));
    final aoeEnemy12 = aoeState.rightTeam.firstWhere((c) => c.characterId == 12);
    final aoeDamageOn12 = 12000 - aoeEnemy12.currentHp;

    // ── single 跑:同攻击者/同倍率单体技,只有 charId 12 一个敌人(AI 必选它)──
    var singleState = BattleState.initial(
      leftTeam: [attacker(skills: const [singlePower, normal])],
      rightTeam: [enemy(charId: 12, slot: 1, hp: 12000)],
    );
    singleState = strategy.tick(singleState, n, rng: Random(7));
    final singleEnemy12 =
        singleState.rightTeam.firstWhere((c) => c.characterId == 12);
    final singleDamageOn12 = 12000 - singleEnemy12.currentHp;

    expect(singleDamageOn12, greaterThan(0), reason: '对照 single 必须真扣血');
    expect(aoeDamageOn12, equals(singleDamageOn12),
        reason: 'aoe 对该敌扣血应 == 单体技对该敌伤害(各目标 = 完整单体值,无衰减)');
  });

  // ── Task 4.1 确定性测:aoe loop 不破坏 rng 确定性 ──
  //
  // 关注点:Task 3 的 aoe 结算「对全体存活敌人各结算一次」是一个 rng-消费 loop。
  // 必须证明:同 seed 跑含 aoe 大招的完整战斗两遍,逐 tick / 逐 action 结果全等
  // (rng 消费顺序不被 aoe loop 引入的额外结算次数破坏)。
  //
  // 与上面「无衰减」测的区别:这里 criticalRate > 0(每次攻击都有 rng 暴击 roll),
  // 让 rng 真分歧——否则伤害全确定,确定性无从证伪。沿 battle_seed_determinism /
  // battle_step_one 测体例:固定 Random(seed) 跑两个独立 strategy 实例到结束,
  // 逐 action 摘要(tick|actor|target|skill|finalDamage|interrupted)+ 终态血量
  // + 胜负全等。

  // 暴击版主控(带 aoe 大招;criticalRate 0.5 → 每次攻击 rng 真分歧)。
  BattleCharacter critAttacker() => const BattleCharacter(
        characterId: 1,
        name: '主控',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: 20000,
        currentHp: 20000,
        maxInternalForce: 3000,
        currentInternalForce: 3000,
        speed: 130,
        criticalRate: 0.5, // rng 暴击 roll 每次攻击都发生
        evasionRate: 0.0,
        defenseRate: 0.1,
        totalEquipmentAttack: 800,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: [aoePower, normal],
        skillCooldowns: {},
        activeBuffs: [],
        actionPoint: 0,
        isAlive: true,
        teamSide: 0,
        slotIndex: 0,
      );

  // 暴击版敌人(会还手 → 拉长战斗 / 增加 rng 消费;criticalRate 0.4)。
  BattleCharacter critEnemy({
    required int charId,
    required int slot,
    required int hp,
  }) =>
      BattleCharacter(
        characterId: charId,
        name: '敌$slot',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: hp,
        currentHp: hp,
        maxInternalForce: 1000,
        currentInternalForce: 1000,
        speed: 90,
        criticalRate: 0.4,
        evasionRate: 0.0,
        defenseRate: 0.1,
        totalEquipmentAttack: 400,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const [normal],
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: 1,
        slotIndex: slot,
      );

  String summarize(BattleState s) =>
      '${s.result}'
      '#L:${s.leftTeam.map((c) => c.currentHp).join(',')}'
      '#R:${s.rightTeam.map((c) => c.currentHp).join(',')}'
      '#${s.actionLog.map((a) => '${a.tick}|${a.actorId}|${a.targetId}|${a.skill?.id}|${a.attackResult?.finalDamage}|${a.interrupted}').join(';')}';

  String runOnce(int seed) {
    const strategy = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    var s = BattleState.initial(
      leftTeam: [critAttacker()],
      rightTeam: [
        critEnemy(charId: 11, slot: 0, hp: 9000),
        critEnemy(charId: 12, slot: 1, hp: 12000),
        critEnemy(charId: 13, slot: 2, hp: 15000),
      ],
    );
    final rng = Random(seed);
    var guard = 0;
    while (!s.isFinished && guard < 3000) {
      s = strategy.tick(s, n, rng: rng);
      guard++;
    }
    return summarize(s);
  }

  test('aoe 确定性:同 seed 跑含 aoe 大招的完整战斗两遍逐 action + 终态全等', () {
    final first = runOnce(424242);
    final second = runOnce(424242);

    // 防空过:场景必须真产生足够多 action(含 aoe 多目标结算 + 暴击 roll),
    // 否则 aoe loop 的 rng 顺序确定性无从证伪。
    expect(first.split(';').length, greaterThan(8),
        reason: '场景应产生足够多 action(aoe 多目标 + 暴击 roll)以暴露 rng 不确定性');
    expect(first, equals(second),
        reason: 'aoe 多目标结算 loop 不得破坏 rng 确定性:同 seed 两次跑应逐 action'
            '(含伤害/暴击/破招)+ 终态血量 + 胜负全等');
  });
}
