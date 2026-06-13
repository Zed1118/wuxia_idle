import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

/// 半手动战斗 P0 步骤1:确定性 seed 链红线。
///
/// **不变量**:`BattleNotifier.startBattle(seed:)` 注入种子后,经
/// `advance()` 全程推进的战斗必须 100% 确定性——同 seed 两次跑,逐 action
/// 的 (tick, actor, target, skill, 伤害, 破招标记) 序列与最终胜负全等。
///
/// 这是「手动通关记 seed+操作 → 同 seed 重演确保复刻」整套闭环的地基
/// (spec `2026-06-13-semi-manual-battle-seed-replay-cycle-design.md` §3.1)。
///
/// **为何走 BattleNotifier.advance 而非 strategy.tick**:strategy 层早已
/// 确定性(`runToEnd`/`tick` 接 seeded rng)。bug 只在 notifier 的
/// `advance()` 循环——它不传 rng,导致 `default_ground_strategy` 每个 action
/// `rng ?? Random()` 新建无种子实例,UI/自动播放路径不可复现。
///
/// **场景设计**:3v3,criticalRate 0.5,中等血量,左队略强稳赢。暴击 roll
/// 每次攻击都发生 → 若 advance 不走注入的单一 seeded rng,两次跑的伤害序列
/// (及长度)必发散 → 测试今天红。注入后逐 action 全等 → 转绿。
void main() {
  setUpAll(() async {
    // loadAllDefs 副作用设 GameRepository.instance 单例;advance() 内
    // numbersConfigProvider 默认实现读该单例。
    await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  // 普攻(兜底,无内力消耗)。
  const normal = SkillDef(
    id: 'skill_seed_det_normal',
    name: '普攻',
    description: 'seed 确定性测普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  // 强力技(有内力时 AI 优先;倍率更高放大暴击发散)。
  const power = SkillDef(
    id: 'skill_seed_det_power',
    name: '强力技',
    description: 'seed 确定性测强力技',
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
        criticalRate: 0.5, // 高暴击率 → 每次攻击都有 rng 分歧
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

  // 左队略强(更高速度+攻击)→ 稳赢,胜负稳定但伤害序列随暴击 roll 变。
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

  /// 经 ProviderContainer 驱动 notifier 跑完整场,返回逐 action 摘要 + 胜负。
  String runOnce(int seed) {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // 永久 listener 防 autoDispose 在 read 间隙释放 notifier(否则 state 丢失)。
    final sub = container.listen(battleProvider, (_, _) {}, fireImmediately: true);
    addTearDown(sub.close);

    final notifier = container.read(battleProvider.notifier);
    notifier.startBattle(leftTeam(), rightTeam(), seed: seed);

    var guard = 0;
    while (!container.read(battleProvider).isFinished && guard < 3000) {
      notifier.advance();
      guard++;
    }

    final s = container.read(battleProvider);
    final ops = s.actionLog
        .map((a) =>
            '${a.tick}|${a.actorId}|${a.targetId}|${a.skill?.id}|${a.attackResult?.finalDamage}|${a.interrupted}')
        .join(';');
    return '${s.result}#$ops';
  }

  test('红线:同 seed 经 BattleNotifier.advance 两次跑 actionLog + 胜负全等', () {
    final first = runOnce(12345);
    final second = runOnce(12345);

    // 防空过:场景必须真产生足够多 action(含暴击 roll),否则不确定性无从证伪。
    expect(
      first.split(';').length,
      greaterThan(10),
      reason: '场景应产生 >10 个 action,确保有足够暴击 roll 暴露不确定性',
    );
    expect(
      first,
      equals(second),
      reason: 'advance() 必须走 startBattle 注入的单一 seeded rng;'
          '同 seed 两次跑应逐 action(含伤害/暴击)与胜负全等',
    );
  });
}
