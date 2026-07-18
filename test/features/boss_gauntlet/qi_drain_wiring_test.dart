import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';

import '../../support/test_data.dart';

/// C1.3.1 断魂庄 qi_drain 引擎接线:蓄力技完成且未破招(`forcedSkill != null`)、
/// 配了 `qiDrainPct` → 对存活对方队施 `QiDrainEffect`(苏无咎锁脉针 §5.2)。
/// 纯资源剥夺、不消费 rng、不膨胀伤害(守 §5.4);破招者走 stagger 路径不达此处。
void main() {
  late NumbersConfig numbers;
  setUpAll(() async {
    await loadTestGameRepository();
    numbers = GameRepository.instance.numbers;
  });

  // 锁脉针:蓄力招牌技,完成时夺敌 30% 最大真气(qiDrainPct 0.30)。
  // 低 powerMultiplier 保证放招不在此拍打死玩家(只验真气剥夺)。
  const lockMeridian = SkillDef(
    id: 'skill_c131_lock_meridian',
    name: '锁脉针',
    description: 'C1.3.1 qi_drain 接线测试用',
    type: SkillType.powerSkill,
    powerMultiplier: 100,
    internalForceCost: 0,
    cooldownTurns: 3,
    requiresManualTrigger: false,
    visualEffect: 'stub',
    qiDrainPct: 0.30,
  );

  // 同款蓄力招但不配 qiDrainPct(默认 0)→ gate 负向验证。
  const plainCharge = SkillDef(
    id: 'skill_c131_plain_charge',
    name: '寻常蓄力',
    description: 'C1.3.1 gate 负向测试用(无 qiDrainPct)',
    type: SkillType.powerSkill,
    powerMultiplier: 100,
    internalForceCost: 0,
    cooldownTurns: 3,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  const playerNormal = SkillDef(
    id: 'skill_c131_player_normal',
    name: '普攻',
    description: 'C1.3.1 玩家普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 50,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  const playerA = BattleCharacter(
    characterId: 1,
    name: '玩家甲',
    realmTier: RealmTier.yiLiu,
    realmLayer: RealmLayer.qiMeng,
    school: TechniqueSchool.gangMeng,
    maxHp: 12000,
    currentHp: 12000,
    maxInternalForce: 10000,
    currentInternalForce: 0,
    maxQi: 100,
    currentQi: 80,
    speed: 1,
    criticalRate: 0.0,
    evasionRate: 0.0,
    defenseRate: 0.0,
    totalEquipmentAttack: 0,
    mainCultivationLayer: CultivationLayer.chuKui,
    availableSkills: <SkillDef>[playerNormal],
    skillCooldowns: {},
    activeBuffs: [],
    actionPoint: 0,
    isAlive: true,
    teamSide: 0,
    slotIndex: 0,
  );

  const playerB = BattleCharacter(
    characterId: 2,
    name: '玩家乙',
    realmTier: RealmTier.yiLiu,
    realmLayer: RealmLayer.qiMeng,
    school: TechniqueSchool.gangMeng,
    maxHp: 12000,
    currentHp: 12000,
    maxInternalForce: 10000,
    currentInternalForce: 0,
    maxQi: 100,
    currentQi: 80,
    speed: 1,
    criticalRate: 0.0,
    evasionRate: 0.0,
    defenseRate: 0.0,
    totalEquipmentAttack: 0,
    mainCultivationLayer: CultivationLayer.chuKui,
    availableSkills: <SkillDef>[playerNormal],
    skillCooldowns: {},
    activeBuffs: [],
    actionPoint: 0,
    isAlive: true,
    teamSide: 0,
    slotIndex: 1,
  );

  /// 左=两名玩家(极慢·真气 80/最大 100),右=敌(极快·已处 charging=chargeSkill、
  /// `chargeTicksRemaining=1` → 首次行动即完成蓄力放招)。玩家极慢,蓄力完成窗口内
  /// 不出手 → 真气仅受敌方剥夺影响(隔离确定性,精确断言非目标 80→50)。
  BattleState makeState(SkillDef chargeSkill) {
    final enemy = BattleCharacter(
      characterId: -1,
      name: '苏无咎',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.lingQiao,
      maxHp: 50000,
      currentHp: 50000,
      maxInternalForce: 10000,
      currentInternalForce: 10000,
      maxQi: 140,
      currentQi: 140,
      speed: 1000,
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.0,
      totalEquipmentAttack: 500,
      mainCultivationLayer: CultivationLayer.daCheng,
      availableSkills: <SkillDef>[chargeSkill, playerNormal],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 1,
      slotIndex: 0,
      isBoss: true,
      chargingSkill: chargeSkill,
      chargeTicksRemaining: 1,
    );
    return BattleState.initial(
      leftTeam: const [playerA, playerB],
      rightTeam: [enemy],
    );
  }

  const strategy = DefaultGroundStrategy();

  BattleCharacter enemyOf(BattleState s) =>
      s.rightTeam.firstWhere((c) => c.characterId == -1);
  BattleCharacter memberOf(BattleState s, int id) =>
      s.leftTeam.firstWhere((c) => c.characterId == id);

  /// 推进至敌方蓄力完成(chargingSkill 清空)或 guard 上限。
  BattleState advanceUntilChargeFires(BattleState s0) {
    var s = s0;
    final rng = Random(11);
    var guard = 0;
    while (guard < 20 && enemyOf(s).chargingSkill != null && !s.isFinished) {
      s = strategy.tick(s, numbers, rng: rng);
      guard++;
    }
    return s;
  }

  test('未破招蓄力完成 → 对方队全体真气被夺(非目标精确扣 30% 最大真气)', () {
    final s = advanceUntilChargeFires(makeState(lockMeridian));
    expect(enemyOf(s).chargingSkill, isNull, reason: '蓄力应已放招');
    // 玩家乙非招式目标(单体招打玩家甲 slot0),真气仅受锁脉针剥夺:
    // 80 - round(0.30 * 100) = 80 - 30 = 50。
    expect(memberOf(s, 2).currentQi, 50, reason: '非目标同队成员真气按 30% 最大真气(=30)被夺');
    // 玩家甲(招式目标)真气也被夺(叠加承伤 schoolBonus,只断言下降)。
    expect(memberOf(s, 1).currentQi, lessThan(80), reason: '招式目标真气亦被夺');
  });

  test('无 qiDrainPct 的蓄力技完成 → 真气不被夺(gate)', () {
    final s = advanceUntilChargeFires(makeState(plainCharge));
    expect(enemyOf(s).chargingSkill, isNull, reason: '蓄力应已放招');
    // 玩家乙非目标、无剥夺 → 真气不变(80)。
    expect(memberOf(s, 2).currentQi, 80, reason: '无 qiDrainPct → 非目标真气不变');
  });

  test('SkillDef.qiDrainPct 默认 0、可显式配置', () {
    expect(playerNormal.qiDrainPct, 0.0);
    expect(lockMeridian.qiDrainPct, 0.30);
  });
}
