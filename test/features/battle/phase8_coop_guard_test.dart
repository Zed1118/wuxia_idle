import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';

import '../../support/test_data.dart';

/// 第八阶段(spec 2026-08-05 敌方协同):掩护重定向(§2.1)+ 护法合击(§2.2)。
///
/// fixture 约定(确定性):全员 evasionRate/criticalRate = 0 → 闪避/暴击 roll
/// 恒不触发,伤害为定值;全员同境界同流派 → 无差距修正/克制;defenseRate=0。
/// Boss speed=1 恒不行动(蓄力态由构造预置,不递减),护法/玩家 speed 按测试
/// 组反转控制先手。
void main() {
  late NumbersConfig numbers;
  const strategy = DefaultGroundStrategy();
  setUpAll(() async {
    await loadTestGameRepository();
    numbers = GameRepository.instance.numbers;
  });

  // Boss 招牌蓄力技(powerSkill;蓄力中内容,测试窗口内不放出)。
  const bossSig = SkillDef(
    id: 'skill_p8_boss_sig',
    name: '灭岳崩山',
    description: '第八阶段协同 Boss 招牌技',
    type: SkillType.powerSkill,
    powerMultiplier: 3000,
    internalForceCost: 100,
    cooldownTurns: 3,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  // 玩家破招技(canInterrupt + saveForInterrupt:敌蓄力时 AI 自动选用)。
  const breakSkill = SkillDef(
    id: 'skill_p8_break',
    name: '断势指',
    description: '第八阶段玩家破招技',
    type: SkillType.powerSkill,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 2,
    requiresManualTrigger: false,
    visualEffect: 'stub',
    canInterrupt: true,
    aiUsePolicy: AiUsePolicy.saveForInterrupt,
    style: TechniqueSchool.gangMeng,
  );

  // 玩家普攻。
  const playerNormal = SkillDef(
    id: 'skill_p8_player_normal',
    name: '普攻',
    description: '第八阶段玩家普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 100,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  // 护法普攻(合击用同一公式伤害)。
  const guardNormal = SkillDef(
    id: 'skill_p8_guard_normal',
    name: '护法拳',
    description: '第八阶段护法普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 1000,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  BattleCharacter makeGuard({
    required int id,
    required int slot,
    required String defId,
    required int hp,
    required int speed,
    bool alive = true,
    int stagger = 0,
  }) {
    return BattleCharacter(
      characterId: id,
      name: '护法$id',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: hp,
      currentHp: alive ? hp : 0,
      internalForce: 2000,
      maxQi: 10000,
      currentQi: 10000,
      speed: speed,
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.0,
      totalEquipmentAttack: 0,
      mainCultivationLayer: CultivationLayer.chuKui,
      availableSkills: const <SkillDef>[guardNormal],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: alive,
      teamSide: 1,
      slotIndex: slot,
      enemyDefId: defId,
      staggerTicksRemaining: stagger,
    );
  }

  /// 左=玩家 1 人,右=协同 Boss(slot0)+ 护法A(slot1,血更低=代吃/tie 锚)
  /// + 护法B(slot2)。Boss 默认已在蓄力态(掩护相位)。
  BattleState makeState({
    required int playerSpeed,
    required int guardSpeed,
    bool interceptOn = true,
    bool guardAAlive = true,
    bool guardBAlive = true,
    int guardBStagger = 0,
    bool coopUsed = false,
    bool bossCharging = true,
    int bossSpeed = 1,
    int guardAHp = 8000,
    int guardBHp = 9000,
  }) {
    final player = BattleCharacter(
      characterId: 1,
      name: '玩家',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 30000,
      currentHp: 30000,
      internalForce: 1000,
      maxQi: 10000,
      currentQi: 10000,
      speed: playerSpeed,
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.0,
      totalEquipmentAttack: 0,
      mainCultivationLayer: CultivationLayer.chuKui,
      availableSkills: const <SkillDef>[playerNormal, breakSkill],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 0,
      slotIndex: 0,
    );
    final boss = BattleCharacter(
      characterId: 10,
      name: '协同魔帅',
      realmTier: RealmTier.yiLiu,
      realmLayer: RealmLayer.qiMeng,
      school: TechniqueSchool.gangMeng,
      maxHp: 50000,
      currentHp: 50000,
      internalForce: 3000,
      maxQi: 10000,
      currentQi: 10000,
      speed: bossSpeed,
      criticalRate: 0.0,
      evasionRate: 0.0,
      defenseRate: 0.0,
      totalEquipmentAttack: 0,
      mainCultivationLayer: CultivationLayer.chuKui,
      availableSkills: const <SkillDef>[bossSig, guardNormal],
      skillCooldowns: const {},
      activeBuffs: const [],
      actionPoint: 0,
      isAlive: true,
      teamSide: 1,
      slotIndex: 0,
      isBoss: true,
      enemyDefId: 'p8_boss',
      chargeSkillId: bossSig.id,
      chargingSkill: bossCharging ? bossSig : null,
      chargeTicksRemaining: bossCharging ? 5 : 0,
      guardianWardMult: 0.15,
      guardianDefIds: const ['p8_guard_a', 'p8_guard_b'],
      guardInterceptsInterrupt: interceptOn,
      coopStrikeUsedInCharge: coopUsed,
    );
    final guardA = makeGuard(
      id: 11,
      slot: 1,
      defId: 'p8_guard_a',
      hp: guardAHp,
      speed: guardSpeed,
      alive: guardAAlive,
    );
    final guardB = makeGuard(
      id: 12,
      slot: 2,
      defId: 'p8_guard_b',
      hp: guardBHp,
      speed: guardSpeed,
      alive: guardBAlive,
      stagger: guardBStagger,
    );
    return BattleState.initial(
      leftTeam: [player],
      rightTeam: [boss, guardA, guardB],
    );
  }

  group('§2.1 掩护重定向', () {
    test('破招命中掩护 Boss → 重定向护法A(血最低)+代吃踉跄+Boss 蓄力不断', () {
      final s0 = makeState(playerSpeed: 1000, guardSpeed: 1);
      final s1 = strategy.tick(s0, numbers, rng: Random(42));
      final atk = s1.actionLog.lastWhere(
        (a) => a.actorId == 1 && a.attackResult != null,
      );
      expect(atk.skill!.id, breakSkill.id, reason: 'AI 应选破招技(敌蓄力中)');
      expect(atk.guardIntercepted, isTrue);
      expect(atk.targetId, 11, reason: '代吃者=存活护法中血最低(A 8000<B 9000)');
      expect(atk.interrupted, isFalse, reason: '护法未在蓄力,无打断语义');
      final boss = s1.rightTeam.firstWhere((c) => c.characterId == 10);
      expect(boss.chargingSkill, isNotNull, reason: 'Boss 蓄力不断(§2.1 第 1 步)');
      expect(boss.chargeTicksRemaining, 5, reason: 'Boss 未行动,蓄力计数不动');
      expect(boss.currentHp, 50000, reason: 'Boss 本次不作 target,零掉血');
      final ga = s1.rightTeam.firstWhere((c) => c.characterId == 11);
      expect(ga.staggerTicksRemaining, greaterThan(0), reason: '代吃强制踉跄');
      expect(ga.currentHp, lessThan(8000), reason: '护法真吃下这发伤害');
    });

    test('代吃踉跄 → 下一拍我方集火踉跄护法(§2.1 第 2 步,零新代码)', () {
      var s = makeState(playerSpeed: 1000, guardSpeed: 1);
      s = strategy.tick(s, numbers, rng: Random(42));
      s = strategy.tick(s, numbers, rng: Random(43));
      final atk2 = s.actionLog.lastWhere(
        (a) => a.actorId == 1 && a.attackResult != null,
      );
      expect(atk2.skill!.id, isNot(breakSkill.id), reason: '破招 CD 中');
      expect(atk2.targetId, 11, reason: '_pickFocusTargetId 集火踉跄护法');
      expect(atk2.guardIntercepted, isFalse, reason: '非破招技无重定向');
    });

    test('护法死光 → 掩护解除,破招走既有真打断路径(§2.1 第 3 步)', () {
      final s0 = makeState(
        playerSpeed: 1000,
        guardSpeed: 1,
        guardAAlive: false,
        guardBAlive: false,
      );
      final s1 = strategy.tick(s0, numbers, rng: Random(42));
      final atk = s1.actionLog.lastWhere(
        (a) => a.actorId == 1 && a.attackResult != null,
      );
      expect(atk.targetId, 10, reason: '无护法可代吃,破招直击 Boss');
      expect(atk.interrupted, isTrue);
      expect(atk.guardIntercepted, isFalse);
      final boss = s1.rightTeam.firstWhere((c) => c.characterId == 10);
      expect(boss.chargingSkill, isNull, reason: '真打断清蓄力');
    });

    test('手动指定破招目标=被掩护 Boss → 结算层统一重定向(手动路径同拦截)', () {
      var s0 = makeState(playerSpeed: 1000, guardSpeed: 1);
      s0 = strategy.requestUltimate(s0, 1, breakSkill, targetId: 10);
      final s1 = strategy.tick(s0, numbers, rng: Random(42));
      final atk = s1.actionLog.lastWhere(
        (a) => a.actorId == 1 && a.attackResult != null,
      );
      expect(atk.guardIntercepted, isTrue);
      expect(atk.targetId, 11, reason: '手动指定 Boss 仍被护法代吃');
      final boss = s1.rightTeam.firstWhere((c) => c.characterId == 10);
      expect(boss.chargingSkill, isNotNull);
    });

    test('零配置回归:开关不配 → 破招直接真打断(既有护法层现行为)', () {
      final s0 = makeState(
        playerSpeed: 1000,
        guardSpeed: 1,
        interceptOn: false,
      );
      final s1 = strategy.tick(s0, numbers, rng: Random(42));
      final atk = s1.actionLog.lastWhere(
        (a) => a.actorId == 1 && a.attackResult != null,
      );
      expect(atk.targetId, 10, reason: '现状:破招锁定有意不排除被护 Boss');
      expect(atk.interrupted, isTrue);
      expect(atk.guardIntercepted, isFalse);
      final boss = s1.rightTeam.firstWhere((c) => c.characterId == 10);
      expect(boss.chargingSkill, isNull);
    });
  });

  group('§2.2 护法合击', () {
    test('掩护相位双护法 → 合击一次结算:总伤扣血/partner 拍消费/相位标记', () {
      final s0 = makeState(playerSpeed: 1, guardSpeed: 1000);
      final s1 = strategy.tick(s0, numbers, rng: Random(42));
      final coops = s1.actionLog
          .where((a) => a.coopStrikePartnerId != null)
          .toList();
      expect(coops, hasLength(1), reason: '本相位恰一次合击');
      final coop = coops.single;
      expect(coop.actorId, 11, reason: '同速同 AP,slotIndex 小的 A 先行动主发起');
      expect(coop.coopStrikePartnerId, 12);
      expect(coop.targetId, 1, reason: '目标=对面血最低(唯一玩家)');
      final total = coop.coopStrikeTotalDamage!;
      expect(total, greaterThan(0));
      final player = s1.leftTeam.single;
      expect(player.currentHp, 30000 - total, reason: '合并一次扣血恰=总伤');
      expect(
        s1.actionLog.where((a) => a.actorId == 12),
        isEmpty,
        reason: 'partner 本 tick 拍已被合击消费,不再独立出手(防双花)',
      );
      final boss = s1.rightTeam.firstWhere((c) => c.characterId == 10);
      expect(boss.coopStrikeUsedInCharge, isTrue);
      final gb = s1.rightTeam.firstWhere((c) => c.characterId == 12);
      expect(gb.actionPoint, 0, reason: 'partner AP 被预支扣除(1000-1000)');
    });

    test('守恒:合击总伤=两护法普攻公式伤害之和(同构护法=恰 2×单发,零独立倍率)', () {
      // 对照组:B 阵亡 → A 正常单发普攻(无合击),取单发公式伤害。
      final sSolo = makeState(
        playerSpeed: 1,
        guardSpeed: 1000,
        guardBAlive: false,
      );
      final r1 = strategy.tick(sSolo, numbers, rng: Random(42));
      final solo = r1.actionLog.lastWhere(
        (a) => a.actorId == 11 && a.attackResult != null,
      );
      expect(solo.coopStrikePartnerId, isNull, reason: '单护法无合击');
      final singleDamage = solo.attackResult!.finalDamage;
      expect(singleDamage, greaterThan(0));
      // 合击组:两护法除 hp/槽位外全同构 → 各自公式伤害与单发逐值相同。
      final sCoop = makeState(playerSpeed: 1, guardSpeed: 1000);
      final r2 = strategy.tick(sCoop, numbers, rng: Random(42));
      final coop = r2.actionLog.singleWhere(
        (a) => a.coopStrikePartnerId != null,
      );
      expect(
        coop.coopStrikeTotalDamage,
        2 * singleDamage,
        reason: '合并=求和,无任何独立倍率字段(spec §0 零膨胀拍板)',
      );
      expect(
        coop.attackResult!.finalDamage,
        singleDamage,
        reason: 'attackResult 保真=主发起者那一份',
      );
    });

    test('每相位一次:本蓄力已合击 → 两护法回落正常单独出手', () {
      final s0 = makeState(playerSpeed: 1, guardSpeed: 1000, coopUsed: true);
      final s1 = strategy.tick(s0, numbers, rng: Random(42));
      expect(s1.actionLog.where((a) => a.coopStrikePartnerId != null), isEmpty);
      expect(
        s1.actionLog.where((a) => a.actorId == 11 && a.attackResult != null),
        hasLength(1),
      );
      expect(
        s1.actionLog.where((a) => a.actorId == 12 && a.attackResult != null),
        hasLength(1),
        reason: '未合击时 partner 正常独立行动',
      );
    });

    test('击破退化:一护法阵亡 → 合击不可用(单护法仍掩护,正常出手)', () {
      final s0 = makeState(
        playerSpeed: 1,
        guardSpeed: 1000,
        guardBAlive: false,
      );
      final s1 = strategy.tick(s0, numbers, rng: Random(42));
      expect(s1.actionLog.where((a) => a.coopStrikePartnerId != null), isEmpty);
    });

    test('搭档踉跄中 → 合击被压制(踉跄=硬直不能协同)', () {
      final s0 = makeState(
        playerSpeed: 1,
        guardSpeed: 1000,
        guardBStagger: 3,
      );
      final s1 = strategy.tick(s0, numbers, rng: Random(42));
      expect(s1.actionLog.where((a) => a.coopStrikePartnerId != null), isEmpty);
    });

    test('Boss 未蓄力(无掩护相位)→ 无合击', () {
      final s0 = makeState(
        playerSpeed: 1,
        guardSpeed: 1000,
        bossCharging: false,
      );
      final s1 = strategy.tick(s0, numbers, rng: Random(42));
      expect(s1.actionLog.where((a) => a.coopStrikePartnerId != null), isEmpty);
    });

    test('新相位重置:Boss 重新起手蓄力 → 合击标记清零,同 tick 可再合击', () {
      final s0 = makeState(
        playerSpeed: 1,
        guardSpeed: 1000,
        bossSpeed: 1000,
        bossCharging: false,
        coopUsed: true,
      );
      final s1 = strategy.tick(s0, numbers, rng: Random(42));
      final chargeStarts = s1.actionLog.where(
        (a) => a.actorId == 10 && a.description.contains('凝气蓄势'),
      );
      expect(chargeStarts, hasLength(1), reason: 'Boss 本 tick 起手蓄力(新相位)');
      expect(
        s1.actionLog.where((a) => a.coopStrikePartnerId != null),
        hasLength(1),
        reason: '标记随进蓄力重置,slot 序在 Boss 之后的护法 A 触发合击',
      );
    });

    test('零配置回归:开关不配 → 双护法存活+Boss 蓄力也不合击', () {
      final s0 = makeState(
        playerSpeed: 1,
        guardSpeed: 1000,
        interceptOn: false,
      );
      final s1 = strategy.tick(s0, numbers, rng: Random(42));
      expect(s1.actionLog.where((a) => a.coopStrikePartnerId != null), isEmpty);
    });
  });
}
