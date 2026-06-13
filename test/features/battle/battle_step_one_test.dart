import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';

/// 半手动战斗 P0 步骤3b:逐 actor 单步推进(intra-tick actor 队列)红线。
///
/// **不变量**:把一个 tick 的「全员行动」拆成「边界步(填队列/推进 AP+CD,
/// 不结算)+ 逐 actor 单步结算」后,rng 消费顺序必须与一次性 `tick()` 完全
/// 一致——否则手动单步通关记录的 `{seed+操作}` 自动重放无法复刻
/// (spec `2026-06-13-semi-manual-battle-seed-replay-cycle-design.md` §七)。
///
/// **架构(用户拍板 2026-06-13)**:intra-tick 队列入 [BattleState.actorQueue]
/// (瞬态,不落盘);`tick()` 重构为「边界 stepOne + 循环 drain」,`stepOne`
/// 成唯一 actor 结算真相源;边界(AP 填充无人行动)单独成一步。
///
/// **场景**:criticalRate 0.5 → 每次攻击都有 rng 分歧,确保等价性测真有可
/// 证伪内容(沿 battle_seed_determinism_test 体例)。
void main() {
  setUpAll(() async {
    await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  const normal = SkillDef(
    id: 'skill_step_one_normal',
    name: '普攻',
    description: 'stepOne 测普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  const power = SkillDef(
    id: 'skill_step_one_power',
    name: '强力技',
    description: 'stepOne 测强力技',
    type: SkillType.powerSkill,
    powerMultiplier: 1500,
    internalForceCost: 100,
    cooldownTurns: 2,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  BattleCharacter unit({
    required int charId,
    required int teamSide,
    required int slot,
    required int speed,
    required int equipAttack,
  }) =>
      BattleCharacter(
        characterId: charId,
        name: '$charId',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: 12000,
        currentHp: 12000,
        maxInternalForce: 2000,
        currentInternalForce: 2000,
        speed: speed,
        criticalRate: 0.5,
        evasionRate: 0.0,
        defenseRate: 0.1,
        totalEquipmentAttack: equipAttack,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: const <SkillDef>[power, normal],
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: teamSide,
        slotIndex: slot,
      );

  List<BattleCharacter> leftTeam() => [
        unit(charId: 1, teamSide: 0, slot: 0, speed: 130, equipAttack: 700),
        unit(charId: 2, teamSide: 0, slot: 1, speed: 120, equipAttack: 700),
        unit(charId: 3, teamSide: 0, slot: 2, speed: 110, equipAttack: 700),
      ];
  List<BattleCharacter> rightTeam() => [
        unit(charId: -1, teamSide: 1, slot: 0, speed: 105, equipAttack: 450),
        unit(charId: -2, teamSide: 1, slot: 1, speed: 100, equipAttack: 450),
        unit(charId: -3, teamSide: 1, slot: 2, speed: 95, equipAttack: 450),
      ];

  String summarize(BattleState s) =>
      '${s.result}#${s.actionLog.map((a) => '${a.tick}|${a.actorId}|${a.targetId}|${a.skill?.id}|${a.attackResult?.finalDamage}|${a.interrupted}').join(';')}';

  test('stepOne 边界步填充 actorQueue + tick++ 且不结算 actor', () {
    const strategy = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;
    final rng = Random(1);
    var s = BattleState.initial(leftTeam: leftTeam(), rightTeam: rightTeam());
    expect(s.actorQueue, isEmpty);

    // 推进到第一个有人 actionPoint ≥ 1000 的 tick 边界。每个空队列边界步:
    // tick 必 +1、actionLog 不增长(只推进 AP/CD,不结算 actor)。
    var safety = 0;
    while (s.actorQueue.isEmpty && !s.isFinished && safety < 100) {
      final before = s;
      s = strategy.stepOne(s, n, rng: rng);
      expect(s.tick, before.tick + 1, reason: '边界步推进一个 tick');
      expect(s.actionLog.length, before.actionLog.length,
          reason: '空队列边界步只推进 AP/CD,不结算任何 actor');
      safety++;
    }
    expect(s.actorQueue, isNotEmpty, reason: '应到达有人行动的 tick 边界,队列被填充');

    // 下一步:恰好弹出/结算队首一个 actor → 队列长度 -1。
    final queueLenBefore = s.actorQueue.length;
    final afterOne = strategy.stepOne(s, n, rng: rng);
    expect(afterOne.actorQueue.length, queueLenBefore - 1,
        reason: '一步恰好处理一个 actor(spec §八#3 一步=一 actor)');
  });

  test('红线:同 seed 下 stepOne 逐步跑完 == tick 整 tick 跑完(actionLog+胜负+血量全等)',
      () {
    const strategy = DefaultGroundStrategy();
    final n = GameRepository.instance.numbers;

    // path A:tick() 整 tick 驱动(现有自动路径)。
    var sa = BattleState.initial(leftTeam: leftTeam(), rightTeam: rightTeam());
    final rngA = Random(777);
    var guardA = 0;
    while (!sa.isFinished && guardA < 3000) {
      sa = strategy.tick(sa, n, rng: rngA);
      guardA++;
    }

    // path B:stepOne 逐步驱动(半手动单步路径)。
    var sb = BattleState.initial(leftTeam: leftTeam(), rightTeam: rightTeam());
    final rngB = Random(777);
    var guardB = 0;
    while (!sb.isFinished && guardB < 30000) {
      sb = strategy.stepOne(sb, n, rng: rngB);
      guardB++;
    }

    expect(sa.actionLog.length, greaterThan(10),
        reason: '防空过:场景需足够多 action(含暴击 roll)才能证伪 rng 顺序发散');
    expect(summarize(sb), equals(summarize(sa)),
        reason: 'stepOne 逐 actor 驱动与 tick 整 tick 驱动 rng 消费顺序必须一致 → '
            '逐 action(含伤害/暴击/破招)与胜负全等');
    expect(sb.leftTeam.map((c) => c.currentHp).toList(),
        equals(sa.leftTeam.map((c) => c.currentHp).toList()),
        reason: '左队终态血量全等');
    expect(sb.rightTeam.map((c) => c.currentHp).toList(),
        equals(sa.rightTeam.map((c) => c.currentHp).toList()),
        reason: '右队终态血量全等');
  });

  /// 经 ProviderContainer 驱动 notifier 跑完整场,返回逐 action 摘要 + 胜负。
  /// [useStep] true 走逐 actor 的 step();false 走整 tick 的 advance()。
  String runViaNotifier(int seed, {required bool useStep}) {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub =
        container.listen(battleProvider, (_, _) {}, fireImmediately: true);
    addTearDown(sub.close);

    final notifier = container.read(battleProvider.notifier);
    notifier.startBattle(leftTeam(), rightTeam(), seed: seed);

    var guard = 0;
    final cap = useStep ? 30000 : 3000;
    while (!container.read(battleProvider).isFinished && guard < cap) {
      if (useStep) {
        notifier.step();
      } else {
        notifier.advance();
      }
      guard++;
    }
    return summarize(container.read(battleProvider));
  }

  test('红线:同 seed 经 BattleNotifier.step 逐步跑完 == advance 整 tick 跑完', () {
    final viaStep = runViaNotifier(2468, useStep: true);
    final viaAdvance = runViaNotifier(2468, useStep: false);

    expect(viaStep.split(';').length, greaterThan(10),
        reason: '防空过:需足够多 action 暴露 rng 顺序不一致');
    expect(viaStep, equals(viaAdvance),
        reason: 'notifier 单一 seeded rng 下,逐 actor step 与整 tick advance '
            '必须复刻同一场战斗');
  });
}
