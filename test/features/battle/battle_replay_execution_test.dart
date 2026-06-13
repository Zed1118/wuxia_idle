import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_replay.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

/// 半手动战斗 P0 步骤4:重放执行(spec §五 P0#4)。
///
/// **不变量**:手动单步通关一次(记 `{seed + 操作序列}`)后,用同 seed + 同
/// 操作序列经 `BattleNotifier.replay` 重演,逐 action(tick/actor/target/skill/
/// 伤害/破招)序列与最终胜负**全等**——确保「手动打过的关,自动重放确定性复刻
/// 通关」。
///
/// **驱动粒度**:重放走 `step()`(与步骤3c 手动录制同粒度,每个整数 tick 都落
/// 点),在 `state.tick == op.anchor` 时注入 `requestUltimate`,与录制时机一致。
/// rng 走 startBattle 注入的单一 seeded 实例(地基 = 步骤1 确定性链 +
/// battle_seed_determinism_test)。
void main() {
  setUpAll(() async {
    await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  const normal = SkillDef(
    id: 'skill_replay_exec_normal',
    name: '普攻',
    description: '重放执行测普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );
  const power = SkillDef(
    id: 'skill_replay_exec_power',
    name: '强力技',
    description: '重放执行测强力技',
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
        criticalRate: 0.5, // 高暴击 → 每攻击都有 rng 分歧,重放不忠实即发散
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

  String summary(BattleState s) {
    final ops = s.actionLog
        .map((a) =>
            '${a.tick}|${a.actorId}|${a.targetId}|${a.skill?.id}|${a.attackResult?.finalDamage}|${a.interrupted}')
        .join(';');
    return '${s.result}#$ops';
  }

  ({ProviderContainer container, BattleNotifier notifier}) fresh() {
    final container = ProviderContainer();
    final sub =
        container.listen(battleProvider, (_, _) {}, fireImmediately: true);
    addTearDown(sub.close);
    addTearDown(container.dispose);
    return (container: container, notifier: container.read(battleProvider.notifier));
  }

  /// 模拟步骤3c 手动单步通关:step() 驱动,在指定 tick 注入玩家手动指令
  /// (带 targetId),返回逐 action 摘要 + 记录的操作序列。
  ({String summary, List<BattleReplayOp> ops}) manualPlaythrough(int seed) {
    final b = fresh();
    b.notifier.startBattle(leftTeam(), rightTeam(), seed: seed);
    var injected1 = false;
    var injected2 = false;
    var guard = 0;
    while (!b.container.read(battleProvider).isFinished && guard < 3000) {
      final tick = b.container.read(battleProvider).tick;
      if (!injected1 && tick == 1) {
        b.notifier.requestUltimate(1, power, targetId: -2);
        injected1 = true;
      }
      if (!injected2 && tick == 3) {
        b.notifier.requestUltimate(2, power, targetId: -1);
        injected2 = true;
      }
      b.notifier.step();
      guard++;
    }
    return (
      summary: summary(b.container.read(battleProvider)),
      ops: List.of(b.notifier.recordedOps),
    );
  }

  test('红线:手动通关(记 seed+ops)→ 同 seed+ops 重放,actionLog + 胜负全等',
      () {
    const seed = 24680;
    final manual = manualPlaythrough(seed);

    // 防空过:操作序列非平凡 + 战斗足够长,确保有暴击 roll 暴露不忠实重放。
    expect(manual.ops, isNotEmpty,
        reason: '手动 playthrough 应记录到至少 1 条玩家指令');
    expect(manual.summary.split(';').length, greaterThan(10),
        reason: '场景应产生 >10 个 action');

    // 重放:全新 notifier,同 seed + 同 ops。
    final r = fresh();
    r.notifier.replay(leftTeam(), rightTeam(), seed: seed, ops: manual.ops);
    final replaySummary = summary(r.container.read(battleProvider));

    expect(replaySummary, equals(manual.summary),
        reason: 'replay 必须确定性复刻手动通关:同 seed 重建 rng + 相同锚点回放 '
            'requestUltimate,逐 action(含伤害/暴击)与胜负全等');
  });

  test('重放在相同锚点回放,recordedOps 重新派生 = 原操作序列', () {
    const seed = 24680;
    final manual = manualPlaythrough(seed);

    final r = fresh();
    r.notifier.replay(leftTeam(), rightTeam(), seed: seed, ops: manual.ops);

    expect(r.notifier.recordedOps, equals(manual.ops),
        reason: 'replay 内部走同一 requestUltimate 路径,在相同锚点(tick)回放 → '
            '重新记录的操作序列应与原序列逐字段全等(幂等可溯)');
  });

  test('空操作序列重放 = 纯自动(同 seed)确定性通关', () {
    const seed = 13579;
    // 纯 advance 自动跑一遍作基准。
    final a = fresh();
    a.notifier.startBattle(leftTeam(), rightTeam(), seed: seed);
    var guard = 0;
    while (!a.container.read(battleProvider).isFinished && guard < 3000) {
      a.notifier.advance();
      guard++;
    }
    final autoSummary = summary(a.container.read(battleProvider));

    // 空 ops 重放应等价(无手动注入,纯 seed 决定)。
    final r = fresh();
    r.notifier.replay(leftTeam(), rightTeam(), seed: seed, ops: const []);
    expect(summary(r.container.read(battleProvider)), equals(autoSummary),
        reason: '空 ops → 重放退化为纯自动战斗,同 seed 与 advance 路径全等');
  });
}
