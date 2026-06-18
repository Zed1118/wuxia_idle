import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';

/// 第六阶段 Task 3:集火破绽窗口确定性测试。
///
/// **不变量**:同 seed 两次 BattleNotifier.advance 全程驱动的战斗,逐 action 的
/// (tick, actor, target, skill, 伤害) 序列与最终胜负全等。集火 _pickFocusTargetId
/// 是纯函数(无 rng),引入后不破坏战斗确定性。
///
/// **为何走 BattleNotifier 而非 strategy.tick**:
/// 与 battle_seed_determinism_test.dart 同理——strategy 层早已确定性;
/// 破坏点在 notifier advance() 循环,故用 ProviderContainer 驱动全程。
/// (见 memory `feedback_battle_determinism_test_via_notifier`)
///
/// **场景**:左队有破防技(可开破绽窗口),右队略弱。战斗中会出现 stagger>0 敌人,
/// 触发 _pickFocusTargetId 路径,验证该路径确定性不受影响。
void main() {
  setUpAll(() async {
    await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });

  // 普攻:无内力消耗,兜底。
  const normal = SkillDef(
    id: 'skill_ccd_normal',
    name: '普攻',
    description: '集火确定性测普攻',
    type: SkillType.normalAttack,
    powerMultiplier: 500,
    internalForceCost: 0,
    cooldownTurns: 0,
    requiresManualTrigger: false,
    visualEffect: 'stub',
  );

  // 破防技:有 defenseBreakPct>0,命中时可开破绽窗口;AI 优先用它。
  const breakSkill = SkillDef(
    id: 'skill_ccd_break',
    name: '破防技',
    description: '集火确定性测破防技',
    type: SkillType.powerSkill,
    powerMultiplier: 1200,
    internalForceCost: 100,
    cooldownTurns: 2,
    requiresManualTrigger: false,
    visualEffect: 'stub',
    defenseBreakPct: 0.5, // 开破绽窗口 → 触发集火路径
  );

  BattleCharacter unit({
    required int charId,
    required int teamSide,
    required int slot,
    required int speed,
    required int equipAttack,
    List<SkillDef> skills = const [breakSkill, normal],
  }) =>
      BattleCharacter(
        characterId: charId,
        name: '$charId',
        realmTier: RealmTier.yiLiu,
        realmLayer: RealmLayer.qiMeng,
        school: TechniqueSchool.gangMeng,
        maxHp: 10000,
        currentHp: 10000,
        maxInternalForce: 2000,
        currentInternalForce: 2000,
        speed: speed,
        criticalRate: 0.4, // 足够高暴击率 → 暴露 rng 不确定性
        evasionRate: 0.0,
        defenseRate: 0.1,
        totalEquipmentAttack: equipAttack,
        mainCultivationLayer: CultivationLayer.daCheng,
        availableSkills: skills,
        skillCooldowns: const {},
        activeBuffs: const [],
        actionPoint: 0,
        isAlive: true,
        teamSide: teamSide,
        slotIndex: slot,
      );

  String runOnce(int seed) {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // 永久 listener 防 autoDispose 在 read 间隙释放 notifier。
    final sub = container.listen(battleProvider, (_, _) {}, fireImmediately: true);
    addTearDown(sub.close);

    final notifier = container.read(battleProvider.notifier);
    notifier.startBattle(
      [
        unit(charId: 1, teamSide: 0, slot: 0, speed: 130, equipAttack: 700),
        unit(charId: 2, teamSide: 0, slot: 1, speed: 120, equipAttack: 650),
        unit(charId: 3, teamSide: 0, slot: 2, speed: 110, equipAttack: 600),
      ],
      [
        unit(charId: -1, teamSide: 1, slot: 0, speed: 105, equipAttack: 450),
        unit(charId: -2, teamSide: 1, slot: 1, speed: 100, equipAttack: 420),
        unit(charId: -3, teamSide: 1, slot: 2, speed: 95, equipAttack: 400),
      ],
      seed: seed,
    );

    var guard = 0;
    while (!container.read(battleProvider).isFinished && guard < 3000) {
      notifier.advance();
      guard++;
    }

    final s = container.read(battleProvider);
    final ops = s.actionLog
        .map((a) =>
            '${a.tick}|${a.actorId}|${a.targetId}|${a.skill?.id}'
            '|${a.attackResult?.finalDamage}|${a.openedBreakWindow}')
        .join(';');
    return '${s.result}#$ops';
  }

  test('红线:同 seed + 含破防开窗场景两跑 actionLog + 胜负全等(集火路径确定性)', () {
    final first = runOnce(20260618);
    final second = runOnce(20260618);

    // 防空过:场景必须产生足够多 action(含暴击 roll + 破防开窗),否则无从证伪。
    expect(
      first.split(';').length,
      greaterThan(10),
      reason: '场景应产生 >10 个 action,确保有足够暴击 roll 暴露不确定性',
    );
    expect(
      first,
      equals(second),
      reason: '含破防开窗+集火的 advance() 全程须走注入的单一 seeded rng,'
          '同 seed 两跑 actionLog(含 openedBreakWindow 标记)与胜负全等',
    );
  });
}
