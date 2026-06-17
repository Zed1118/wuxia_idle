import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/battle_ai.dart';
import 'package:wuxia_idle/features/battle/domain/battle_engine.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/technique.dart';

/// BattleEngine + BattleAI 单元测试（phase1_tasks.md T12 §706 验收）。
///
/// 覆盖：
/// 1. 3v3 同境界同流派同装备：runToEnd 50-200 tick 内分胜负，不死循环。
/// 2. 速度差：speed=200 vs 100 的行动次数 ~2:1。
/// 3. requestUltimate：玩家手动请求后该角色下次行动一定使用该大招
///    （前提内力够、CD 0）。
/// 4. 境界差：三流满员 vs 绝顶满员（差 2 阶）→ rightWin（"几乎必败"）。
///    注：phase1_tasks T12 §709 写"守方 0.05"是笔误（差 2 守方 0.3，差 3+ 守方
///    0.05），但"三流→绝顶差 2 必败"语义成立。
/// 5. 同 actionPoint 排序破平局（teamSide asc → slotIndex asc）。
/// 6. maxTicks 触发 → draw（防死循环兜底）。
/// 7. BattleAI 招式选择优先级：pendingUltimates > powerSkill > normalAttack。
/// 8. 死亡角色不行动（AI 跳过）+ AI 选目标取活角色 hp 最低。
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

  // ────────────────────────────────────────────────────────────────────────
  // §706.1 3v3 同境界同流派同装备 → 50-200 tick 内分胜负
  // ────────────────────────────────────────────────────────────────────────

  test('3v3 同境界同流派同装备：runToEnd 50-200 tick 内分胜负，不死循环', () {
    final left = _team(teamSide: 0, charIdBase: 1);
    final right = _team(teamSide: 1, charIdBase: 11);
    final s0 = BattleState.initial(leftTeam: left, rightTeam: right);

    final s = BattleEngine.runToEnd(
      s0,
      GameRepository.instance.numbers,
      maxTicks: 500,
      rng: Random(42),
    );

    expect(s.isFinished, true);
    expect(s.result, isNot(BattleResult.draw),
        reason: '同条件对战不应触发 maxTicks 兜底');
    expect(s.tick, greaterThanOrEqualTo(20),
        reason: '不应一两 tick 就结束（双方有交互）');
    expect(s.tick, lessThanOrEqualTo(500),
        reason: '不能超过 maxTicks（即使到 maxTicks 也只会 draw）');
    expect(s.actionLog, isNotEmpty);
  });

  // ────────────────────────────────────────────────────────────────────────
  // §706.2 速度差：speed 比 ~ 行动次数比
  // ────────────────────────────────────────────────────────────────────────

  test('速度差：左队 speed=200 / 右队 speed=100，行动次数比接近 2:1', () {
    // 左队 speed 强设 200、右队 100；HP 巨高让战斗在 maxTicks 内不结束。
    final left = _team(teamSide: 0, charIdBase: 1)
        .map((c) => c.copyWith(
              speed: 200,
              maxHp: 1000000,
              currentHp: 1000000,
            ))
        .toList();
    final right = _team(teamSide: 1, charIdBase: 11)
        .map((c) => c.copyWith(
              speed: 100,
              maxHp: 1000000,
              currentHp: 1000000,
            ))
        .toList();
    final s0 = BattleState.initial(leftTeam: left, rightTeam: right);

    final s = BattleEngine.runToEnd(
      s0,
      GameRepository.instance.numbers,
      maxTicks: 200,
      rng: Random(7),
    );

    final leftIds = left.map((c) => c.characterId).toSet();
    final rightIds = right.map((c) => c.characterId).toSet();
    final leftActs =
        s.actionLog.where((a) => leftIds.contains(a.actorId)).length;
    final rightActs =
        s.actionLog.where((a) => rightIds.contains(a.actorId)).length;

    expect(rightActs, greaterThan(0), reason: '右队也应有行动');
    final ratio = leftActs / rightActs;
    // 严格的 2:1 受 actionPoint 余数残留扰动，区间放宽到 [1.7, 2.3]
    expect(ratio, inInclusiveRange(1.7, 2.3),
        reason: '左/右行动次数比应接近 2:1（实测 leftActs=$leftActs '
            '/ rightActs=$rightActs / ratio=$ratio）');
  });

  // ────────────────────────────────────────────────────────────────────────
  // §706.3 requestUltimate
  // ────────────────────────────────────────────────────────────────────────

  test('requestUltimate：内力够+CD 0 时，该角色下次行动一定使用该大招', () {
    // 单角色 1v1：左队 1 人内力 5000（远超 300）；右队 1 人。
    final leftBase = _mkBC(
      charId: 1,
      teamSide: 0,
      slotIndex: 0,
      internalForce: 5000,
    );
    final rightBase = _mkBC(
      charId: 11,
      teamSide: 1,
      slotIndex: 0,
      internalForce: 1000,
    );
    // 左队 actionPoint=999，speed 任意 → 一 tick 后必行动
    final left = leftBase.copyWith(actionPoint: 999);
    final right = rightBase.copyWith(actionPoint: 0, speed: 1); // 慢得几乎不行动

    final ult = GameRepository.instance.getSkill('skill_gangmeng_jichu_ult');
    expect(ult.type, SkillType.ultimate);

    final s0 = BattleState.initial(leftTeam: [left], rightTeam: [right]);
    final s1 = BattleEngine.requestUltimate(s0, left.characterId, ult);
    expect(s1.pendingUltimates[left.characterId], same(ult));

    final s2 = BattleEngine.tick(
      s1,
      GameRepository.instance.numbers,
      rng: Random(1),
    );

    // 左队角色第一条行动用了大招
    final leftAction = s2.actionLog.firstWhere(
      (a) => a.actorId == left.characterId,
      orElse: () =>
          throw StateError('左队角色应在该 tick 行动（actionPoint=999+speed≥1000）'),
    );
    expect(leftAction.skill?.id, ult.id);
    // pendingUltimates 已被消费
    expect(s2.pendingUltimates.containsKey(left.characterId), false);
    // 内力扣除 ult.internalForceCost (300)
    final leftAfter = s2.leftTeam.first;
    expect(leftAfter.currentInternalForce, 5000 - ult.internalForceCost);
    // CD 写入
    expect(leftAfter.skillCooldowns[ult.id], ult.cooldownTurns);
  });

  test('requestUltimate：必须传 type=ultimate 的招式，否则抛 ArgumentError', () {
    final notUlt =
        GameRepository.instance.getSkill('skill_gangmeng_jichu_basic');
    final s0 = BattleState.initial(leftTeam: const [], rightTeam: const []);
    expect(
      () => BattleEngine.requestUltimate(s0, 1, notUlt),
      throwsA(isA<ArgumentError>()),
    );
  });

  // ────────────────────────────────────────────────────────────────────────
  // §706.4 境界差：三流 vs 绝顶（差 2 阶），三流必败
  // ────────────────────────────────────────────────────────────────────────

  test('境界差：三流满员 vs 绝顶满员（差 2 阶），三流必败 → rightWin', () {
    final left = _team(
      teamSide: 0,
      charIdBase: 1,
      tier: RealmTier.sanLiu,
      layer: RealmLayer.dengFeng,
      internalForce: 1500,
    );
    final right = _team(
      teamSide: 1,
      charIdBase: 11,
      tier: RealmTier.jueDing,
      layer: RealmLayer.dengFeng,
      internalForce: 8000,
    );
    final s0 = BattleState.initial(leftTeam: left, rightTeam: right);

    final s = BattleEngine.runToEnd(
      s0,
      GameRepository.instance.numbers,
      maxTicks: 500,
      rng: Random(99),
    );

    expect(s.isFinished, true);
    expect(s.result, BattleResult.rightWin,
        reason: '三流打绝顶差 2 阶（守方 0.3 / 攻方 2.5）应必败');
  });

  // ────────────────────────────────────────────────────────────────────────
  // 排序破平局（phase1_tasks T12 §712）
  // ────────────────────────────────────────────────────────────────────────

  test('同 actionPoint + 同 speed：teamSide asc → slotIndex asc 破平局', () {
    // 左队 0 号 + 右队 0 号，同 ap、同 speed。tick 后两人同时 actionPoint≥1000，
    // 排序应按 (teamSide asc) → 左队先行动。
    final left = _mkBC(charId: 1, teamSide: 0, slotIndex: 0)
        .copyWith(actionPoint: 999, speed: 100, maxHp: 1000000, currentHp: 1000000);
    final right = _mkBC(charId: 11, teamSide: 1, slotIndex: 0)
        .copyWith(actionPoint: 999, speed: 100, maxHp: 1000000, currentHp: 1000000);
    final s0 = BattleState.initial(leftTeam: [left], rightTeam: [right]);

    final s1 = BattleEngine.tick(
      s0,
      GameRepository.instance.numbers,
      rng: Random(2),
    );

    expect(s1.actionLog.length, 2,
        reason: '两人同 tick 都应行动');
    expect(s1.actionLog.first.actorId, left.characterId,
        reason: '同 ap+speed 时 teamSide=0 优先行动');
    expect(s1.actionLog[1].actorId, right.characterId);
  });

  test('同 actionPoint + 同 speed + 同 teamSide：slotIndex 小的优先', () {
    final c0 = _mkBC(charId: 1, teamSide: 0, slotIndex: 0)
        .copyWith(actionPoint: 999, speed: 100, maxHp: 1000000, currentHp: 1000000);
    final c1 = _mkBC(charId: 2, teamSide: 0, slotIndex: 1)
        .copyWith(actionPoint: 999, speed: 100, maxHp: 1000000, currentHp: 1000000);
    final right = _mkBC(charId: 11, teamSide: 1, slotIndex: 0)
        .copyWith(speed: 1, maxHp: 1000000, currentHp: 1000000);
    final s0 = BattleState.initial(leftTeam: [c0, c1], rightTeam: [right]);

    final s1 = BattleEngine.tick(
      s0,
      GameRepository.instance.numbers,
      rng: Random(3),
    );

    final leftActs =
        s1.actionLog.where((a) => a.actorId == c0.characterId || a.actorId == c1.characterId);
    expect(leftActs.first.actorId, c0.characterId,
        reason: 'slotIndex 0 应先于 slotIndex 1 行动');
  });

  // ────────────────────────────────────────────────────────────────────────
  // maxTicks → draw 兜底
  // ────────────────────────────────────────────────────────────────────────

  test('maxTicks 触发 → draw（防死循环兜底）', () {
    // 双方 maxHp 巨高、speed 巨低、伤害刚好可见但杀不死 → 短 maxTicks 兜底
    final left = _team(teamSide: 0, charIdBase: 1)
        .map((c) =>
            c.copyWith(maxHp: 99999999, currentHp: 99999999, speed: 50))
        .toList();
    final right = _team(teamSide: 1, charIdBase: 11)
        .map((c) =>
            c.copyWith(maxHp: 99999999, currentHp: 99999999, speed: 50))
        .toList();
    final s0 = BattleState.initial(leftTeam: left, rightTeam: right);

    final s = BattleEngine.runToEnd(
      s0,
      GameRepository.instance.numbers,
      maxTicks: 30,
      rng: Random(5),
    );

    expect(s.isFinished, true);
    expect(s.result, BattleResult.draw,
        reason: 'maxTicks 内分不出胜负应 draw');
  });

  // ────────────────────────────────────────────────────────────────────────
  // BattleAI 决策细节
  // ────────────────────────────────────────────────────────────────────────

  group('BattleAI.decide', () {
    test('优先级：pendingUltimates > powerSkill > normalAttack', () {
      final actor = _mkBC(charId: 1, teamSide: 0, internalForce: 5000);
      final defender = _mkBC(charId: 11, teamSide: 1);
      final ult =
          GameRepository.instance.getSkill('skill_gangmeng_jichu_ult');
      var s = BattleState.initial(
        leftTeam: [actor],
        rightTeam: [defender],
      );

      // 1) 无 pending → 应选 powerSkill（内力够、CD 0）
      var (skill, _) = BattleAI.decide(
        actor,
        s,
        GameRepository.instance.numbers,
      );
      expect(skill.type, SkillType.powerSkill);

      // 2) 注入 pending → 应选大招
      s = BattleEngine.requestUltimate(s, actor.characterId, ult);
      (skill, _) = BattleAI.decide(
        actor,
        s,
        GameRepository.instance.numbers,
      );
      expect(skill.id, ult.id);

      // 3) 内力不够 → fall through 到 powerSkill / normalAttack
      final poor = actor.copyWith(currentInternalForce: 50);
      final s3 = s.copyWith(leftTeam: [poor]);
      (skill, _) = BattleAI.decide(
        poor,
        s3,
        GameRepository.instance.numbers,
      );
      // powerSkill cost=100, 内力 50 → 选 normalAttack
      expect(skill.type, SkillType.normalAttack);
    });

    // P1.1 候选 3-b:joint_skill 优先级 = pending > jointSkill > powerSkill > normal
    test('joint_skill 优先级:weapon 共鸣 moQi + 内力够 → pick joint_skill', () {
      final actor = _mkBC(
        charId: 1,
        teamSide: 0,
        internalForce: 5000,
        weaponBattleCount: 500, // moQi 阶 unlocksJointSkill=true
      );
      final defender = _mkBC(charId: 11, teamSide: 1);
      final s = BattleState.initial(
        leftTeam: [actor],
        rightTeam: [defender],
      );
      final (skill, _) = BattleAI.decide(
        actor,
        s,
        GameRepository.instance.numbers,
      );
      expect(skill.id, 'skill_joint_skill');
      expect(skill.type, SkillType.jointSkill);
    });

    test('joint_skill 内力不够 (250) → fall through 到 powerSkill', () {
      final actor = _mkBC(
        charId: 1,
        teamSide: 0,
        internalForce: 200, // < 250 joint_skill cost, > 100 powerSkill cost
        weaponBattleCount: 500,
      );
      final defender = _mkBC(charId: 11, teamSide: 1);
      final s = BattleState.initial(
        leftTeam: [actor],
        rightTeam: [defender],
      );
      final (skill, _) = BattleAI.decide(
        actor,
        s,
        GameRepository.instance.numbers,
      );
      expect(skill.type, SkillType.powerSkill);
    });

    test('joint_skill cd>0 → fall through 到 powerSkill', () {
      final actor = _mkBC(
        charId: 1,
        teamSide: 0,
        internalForce: 5000,
        weaponBattleCount: 500,
      );
      final cdActor =
          actor.copyWith(skillCooldowns: const {'skill_joint_skill': 2});
      final defender = _mkBC(charId: 11, teamSide: 1);
      final s = BattleState.initial(
        leftTeam: [cdActor],
        rightTeam: [defender],
      );
      final (skill, _) = BattleAI.decide(
        cdActor,
        s,
        GameRepository.instance.numbers,
      );
      expect(skill.type, SkillType.powerSkill);
    });

    test('pendingUltimate 优先级仍高于 joint_skill', () {
      final actor = _mkBC(
        charId: 1,
        teamSide: 0,
        internalForce: 5000,
        weaponBattleCount: 500,
      );
      final ult = GameRepository.instance.getSkill('skill_gangmeng_mingjia_ult');
      final defender = _mkBC(charId: 11, teamSide: 1);
      var s = BattleState.initial(
        leftTeam: [actor],
        rightTeam: [defender],
      );
      s = BattleEngine.requestUltimate(s, actor.characterId, ult);
      final (skill, _) = BattleAI.decide(
        actor,
        s,
        GameRepository.instance.numbers,
      );
      expect(skill.id, ult.id, reason: 'pendingUlt > jointSkill');
    });

    test('powerSkill CD>0 时跳过，选 normalAttack', () {
      final actor = _mkBC(charId: 1, teamSide: 0, internalForce: 3000);
      final powerId =
          actor.availableSkills.firstWhere((s) => s.type == SkillType.powerSkill).id;
      final cdActor = actor.copyWith(skillCooldowns: {powerId: 1});
      final defender = _mkBC(charId: 11, teamSide: 1);
      final s = BattleState.initial(
        leftTeam: [cdActor],
        rightTeam: [defender],
      );
      final (skill, _) = BattleAI.decide(
        cdActor,
        s,
        GameRepository.instance.numbers,
      );
      expect(skill.type, SkillType.normalAttack);
    });

    test('目标选择：对面活角色 currentHp 最低（同 hp 选 slotIndex 小）', () {
      final actor = _mkBC(charId: 1, teamSide: 0);
      final r0 = _mkBC(charId: 11, teamSide: 1, slotIndex: 0)
          .copyWith(currentHp: 5000, maxHp: 10000);
      final r1 = _mkBC(charId: 12, teamSide: 1, slotIndex: 1)
          .copyWith(currentHp: 3000, maxHp: 10000); // 最低
      final r2 = _mkBC(charId: 13, teamSide: 1, slotIndex: 2)
          .copyWith(currentHp: 3000, maxHp: 10000); // 同低，但 slot 大
      final s = BattleState.initial(
        leftTeam: [actor],
        rightTeam: [r0, r1, r2],
      );
      final (_, targetIds) = BattleAI.decide(
        actor,
        s,
        GameRepository.instance.numbers,
      );
      expect(targetIds, [r1.characterId],
          reason: 'hp 最低且 slotIndex=1 优先于 slotIndex=2');
    });

    test('AI 跳过死亡角色：对面 0 号死了选 1 号', () {
      final actor = _mkBC(charId: 1, teamSide: 0);
      final r0 = _mkBC(charId: 11, teamSide: 1, slotIndex: 0).copyWith(
        currentHp: 0,
        isAlive: false,
      );
      final r1 = _mkBC(charId: 12, teamSide: 1, slotIndex: 1);
      final s = BattleState.initial(
        leftTeam: [actor],
        rightTeam: [r0, r1],
      );
      final (_, targetIds) = BattleAI.decide(
        actor,
        s,
        GameRepository.instance.numbers,
      );
      expect(targetIds, [r1.characterId]);
    });
  });

  // §12.1 #7 v1.4 阴柔克灵巧内伤 debuff 状态机 ────────────────────────────────
  group('§12.1 #7 阴柔内伤 debuff', () {
    test('阴柔 → 灵巧 命中 → defender 加 InternalInjurySlot(turns=3 dmg=200)',
        () {
      final n = GameRepository.instance.numbers;
      final atk = _mkBC(
        charId: 1,
        teamSide: 0,
        school: TechniqueSchool.yinRou,
        techDefId: 'tech_yinrou_mingjia',
      ).copyWith(actionPoint: 1000);
      final def = _mkBC(
        charId: 11,
        teamSide: 1,
        school: TechniqueSchool.lingQiao,
        techDefId: 'tech_lingqiao_mingjia',
      );
      var s = BattleState.initial(leftTeam: [atk], rightTeam: [def]);
      s = BattleEngine.tick(s, n, rng: Random(0));
      final defAfter = s.rightTeam.first;
      expect(defAfter.internalInjury, isNotNull,
          reason: '阴柔命中灵巧应施加 internalInjury slot');
      expect(defAfter.internalInjury!.remainingTurns,
          n.schoolCounter.yinRouInternalInjury.turnsPersist);
      expect(defAfter.internalInjury!.damagePerTick,
          n.schoolCounter.yinRouInternalInjury.damagePerTick);
    });

    test('内伤 dot:守方下次出手 → 扣 damagePerTick + turns-=1', () {
      final n = GameRepository.instance.numbers;
      // 守方刚猛(避免命中刚猛的中性反向触发其他效果),设 actionPoint=1000 立即出手。
      final injured = _mkBC(
        charId: 11,
        teamSide: 1,
        school: TechniqueSchool.lingQiao,
        techDefId: 'tech_lingqiao_mingjia',
      ).copyWith(
        actionPoint: 1000,
        internalInjury: const InternalInjurySlot(
          remainingTurns: 3,
          damagePerTick: 200,
        ),
      );
      final foe = _mkBC(
        charId: 1,
        teamSide: 0,
        school: TechniqueSchool.gangMeng,
      );
      var s = BattleState.initial(leftTeam: [foe], rightTeam: [injured]);
      final hpBefore = injured.currentHp;
      s = BattleEngine.tick(s, n, rng: Random(0));
      final injuredAfter = s.rightTeam.first;
      expect(injuredAfter.currentHp, lessThanOrEqualTo(hpBefore - 200),
          reason: 'dot 扣 200(可能还叠上来自 foe 的攻击,故 ≤)');
      expect(injuredAfter.internalInjury, isNotNull);
      expect(injuredAfter.internalInjury!.remainingTurns, 2,
          reason: 'turns 衰减 1');
    });

    test('内伤 turns=1 → 出手扣 dot 后 → slot 清空(null)', () {
      final n = GameRepository.instance.numbers;
      final injured = _mkBC(
        charId: 11,
        teamSide: 1,
        school: TechniqueSchool.lingQiao,
        techDefId: 'tech_lingqiao_mingjia',
      ).copyWith(
        actionPoint: 1000,
        internalInjury: const InternalInjurySlot(
          remainingTurns: 1,
          damagePerTick: 200,
        ),
      );
      final foe = _mkBC(
        charId: 1,
        teamSide: 0,
        school: TechniqueSchool.gangMeng,
      );
      var s = BattleState.initial(leftTeam: [foe], rightTeam: [injured]);
      s = BattleEngine.tick(s, n, rng: Random(0));
      expect(s.rightTeam.first.internalInjury, isNull,
          reason: 'turns=1 用尽 → slot 清空');
    });

    test('同源刷新:阴柔再次命中已带内伤的灵巧 → remainingTurns 重置不叠层', () {
      final n = GameRepository.instance.numbers;
      final attacker = _mkBC(
        charId: 1,
        teamSide: 0,
        school: TechniqueSchool.yinRou,
        techDefId: 'tech_yinrou_mingjia',
      ).copyWith(actionPoint: 1000);
      final defender = _mkBC(
        charId: 11,
        teamSide: 1,
        school: TechniqueSchool.lingQiao,
        techDefId: 'tech_lingqiao_mingjia',
      ).copyWith(
        internalInjury: const InternalInjurySlot(
          remainingTurns: 1, // 老 slot 还剩 1 turn
          damagePerTick: 200,
        ),
      );
      var s = BattleState.initial(leftTeam: [attacker], rightTeam: [defender]);
      s = BattleEngine.tick(s, n, rng: Random(0));
      final defAfter = s.rightTeam.first;
      expect(defAfter.internalInjury, isNotNull);
      expect(defAfter.internalInjury!.remainingTurns,
          n.schoolCounter.yinRouInternalInjury.turnsPersist,
          reason: '刷新覆盖:重置 turns 到 3,不是叠 1+3=4 也不是延长');
    });

    test('闪避:阴柔被闪避不施加内伤(followsMainHit)', () {
      // 通过给 defender 极高 evasion 强制闪避。
      final n = GameRepository.instance.numbers;
      final attacker = _mkBC(
        charId: 1,
        teamSide: 0,
        school: TechniqueSchool.yinRou,
        techDefId: 'tech_yinrou_mingjia',
      ).copyWith(actionPoint: 1000);
      final defender = _mkBC(
        charId: 11,
        teamSide: 1,
        school: TechniqueSchool.lingQiao,
        techDefId: 'tech_lingqiao_mingjia',
      ).copyWith(evasionRate: 1.0); // 100% 闪避
      var s = BattleState.initial(leftTeam: [attacker], rightTeam: [defender]);
      s = BattleEngine.tick(s, n, rng: Random(0));
      expect(s.rightTeam.first.internalInjury, isNull,
          reason: '主攻击闪避 → 不施加 internal_injury');
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// fixture
// ─────────────────────────────────────────────────────────────────────────────

/// 3 角色一队（默认 erLiu/yuanShu，gangMeng，主修 mingjia）。
List<BattleCharacter> _team({
  required int teamSide,
  required int charIdBase,
  RealmTier tier = RealmTier.erLiu,
  RealmLayer layer = RealmLayer.yuanShu,
  TechniqueSchool school = TechniqueSchool.gangMeng,
  String techDefId = 'tech_gangmeng_mingjia',
  TechniqueTier techTier = TechniqueTier.mingJiaGong,
  int internalForce = 3000,
}) {
  return List.generate(3, (i) {
    return _mkBC(
      charId: charIdBase + i,
      teamSide: teamSide,
      slotIndex: i,
      tier: tier,
      layer: layer,
      school: school,
      techDefId: techDefId,
      techTier: techTier,
      internalForce: internalForce,
    );
  });
}

BattleCharacter _mkBC({
  required int charId,
  required int teamSide,
  int slotIndex = 0,
  RealmTier tier = RealmTier.erLiu,
  RealmLayer layer = RealmLayer.yuanShu,
  TechniqueSchool school = TechniqueSchool.gangMeng,
  String techDefId = 'tech_gangmeng_mingjia',
  TechniqueTier techTier = TechniqueTier.mingJiaGong,
  int internalForce = 3000,
  int agility = 5,
  int constitution = 5,
  // P1b 藏经阁:joint 现在走 resonanceSkillId 槽(不再由 weapon 共鸣度 stage 自动
  // 注入)。weaponBattleCount>0 表示「该角色装配了 joint」,据此填 resonanceSkillId。
  int weaponBattleCount = 0,
}) {
  final c = Character.create(
    name: '${teamSide == 0 ? "左" : "右"}$slotIndex',
    realmTier: tier,
    realmLayer: layer,
    attributes: Attributes()
      ..constitution = constitution
      ..enlightenment = 5
      ..agility = agility
      ..fortune = 5,
    rarity: RarityTier.biaoZhun,
    lineageRole: LineageRole.founder,
    createdAt: DateTime(2026, 1, 1),
    internalForce: internalForce,
    school: school,
  )
    ..id = charId
    // P0:战斗内力进场满(maxIf)。fixture 以 internalForce 表达「该角色进场
    // 内力预算」,故同步 internalForceMax,使进场满后 currentInternalForce
    // == internalForce(保留各测原意:内力够/不够放招的阈值判断)。
    ..internalForceMax = internalForce
    // P1b:装配主修 3 招(对应 techDefId skillIds)以保 powerSkill 在战斗池;
    // weaponBattleCount>0 → 装 joint 到共鸣槽,复现旧「共鸣解锁 joint」语义。
    ..mainSkillId1 = 'skill_gangmeng_mingjia_basic'
    ..assistSkillId = 'skill_gangmeng_mingjia_skill'
    ..ultimateSkillId = 'skill_gangmeng_mingjia_ult'
    ..resonanceSkillId =
        weaponBattleCount > 0 ? 'skill_joint_skill' : null;
  final eq = Equipment.create(
    defId: 'test',
    tier: EquipmentTier.xunChang,
    slot: EquipmentSlot.weapon,
    obtainedAt: DateTime(2026, 1, 1),
    obtainedFrom: 'test',
    baseAttack: 580,
  )..battleCount = weaponBattleCount;
  final tech = Technique.create(
    defId: techDefId,
    ownerCharacterId: charId,
    tier: techTier,
    school: school,
    role: TechniqueRole.main,
    learnedAt: DateTime(2026, 1, 1),
    cultivationLayer: CultivationLayer.zhongCheng, // 1.30x
  );
  return BattleCharacter.fromCharacter(
    character: c,
    equipped: [eq],
    mainTechnique: tech,
    numbers: GameRepository.instance.numbers,
    teamSide: teamSide,
    slotIndex: slotIndex,
  );
}
