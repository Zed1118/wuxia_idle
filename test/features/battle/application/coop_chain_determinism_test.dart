import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/strategy/default_ground_strategy.dart';
import '../../../support/test_data.dart';

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
    await loadTestGameRepository();
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
    int hp = 10000,
    List<SkillDef> skills = const [breakSkill, normal],
  }) => BattleCharacter(
    characterId: charId,
    name: '$charId',
    realmTier: RealmTier.yiLiu,
    realmLayer: RealmLayer.qiMeng,
    school: TechniqueSchool.gangMeng,
    maxHp: hp,
    currentHp: hp,
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

  BattleState runState(int seed) {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // 永久 listener 防 autoDispose 在 read 间隙释放 notifier。
    final sub = container.listen(
      battleProvider,
      (_, _) {},
      fireImmediately: true,
    );
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

    return container.read(battleProvider);
  }

  String runOnce(int seed) {
    final s = runState(seed);
    final ops = s.actionLog
        .map(
          (a) =>
              '${a.tick}|${a.actorId}|${a.targetId}|${a.skill?.id}'
              '|${a.attackResult?.finalDamage}|${a.openedBreakWindow}',
        )
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
    // 确保破防技确实至少开过一次破绽窗口;否则"确定性测"形同虚设——
    // 集火路径根本没被触发,同 seed 相等只是普通战斗确定性的平凡结论。
    expect(
      first.contains('|true'),
      isTrue,
      reason:
          'breakSkill 应至少打开一次破绽窗口(openedBreakWindow=true),'
          '否则集火路径未被覆盖,该确定性测形同虚设',
    );
    expect(
      first,
      equals(second),
      reason:
          '含破防开窗+集火的 advance() 全程须走注入的单一 seeded rng,'
          '同 seed 两跑 actionLog(含 openedBreakWindow 标记)与胜负全等',
    );
  });

  test('正确性:破绽窗口内集火优先于血最低回落(非纯确定性复述)', () {
    // 与上一条确定性测互补:确定性只锁「两跑一致」——对「恒不集火」或
    // 「踉跄不落」的实现同样成立。本条锁语义本身:_pickFocusTargetId 契约 =
    // 破绽窗口内的踉跄敌优先于血最低回落(_pickTargetId)。
    //
    // 判别设计:被破敌 X 血量高于另一敌 Y(弱破招手 equipAttack=10 + 生产
    // requestUltimate 手动指定破 X)。若集火失效回落血最低,跟进攻击会打 Y
    // 而非 X → 恰红;两敌同血量的场景两条规则同指向,无判别力(首轮教训:
    // 破坏 stagger 落子后旧版本条曾照样绿)。
    const strategy = DefaultGroundStrategy();
    final numbers = GameRepository.instance.numbers;

    final breaker = unit(
      charId: 1,
      teamSide: 0,
      slot: 0,
      speed: 130,
      equipAttack: 10, // 弱破招手:X 挨破后血仍远高于 Y
    );
    final attacker = unit(
      charId: 2,
      teamSide: 0,
      slot: 1,
      speed: 120,
      equipAttack: 400,
      skills: const [normal],
    );
    final enemyX = unit(
      charId: -1,
      teamSide: 1,
      slot: 0,
      speed: 50, // 慢速:跟进者行动前敌不行动,踉跄不被自递减
      equipAttack: 10,
      skills: const [normal],
    );
    final enemyY = unit(
      charId: -2,
      teamSide: 1,
      slot: 1,
      speed: 40,
      equipAttack: 10,
      hp: 5000, // Y 恒为血最低 → 回落规则的指向
      skills: const [normal],
    );

    var s = BattleState.initial(
      leftTeam: [breaker, attacker],
      rightTeam: [enemyX, enemyY],
    );
    // 生产手动指定路径:玩家命令破招手破 X(而非 AI 默认的血最低 Y)。
    s = strategy.requestUltimate(s, 1, breakSkill, targetId: -1);
    // AP 满 1000 才出手:推进到破招手行动(speed 130 → 第 8 tick 才满)。
    var guard = 0;
    while (!s.actionLog.any((a) => a.actorId == 1 && a.attackResult != null) &&
        guard < 50) {
      s = strategy.tick(s, numbers, rng: Random(7));
      guard++;
    }
    expect(guard, lessThan(50), reason: '破招手应在有限 tick 内行动');

    final xAfter = s.rightTeam.firstWhere((c) => c.characterId == -1);
    expect(
      xAfter.staggerTicksRemaining,
      greaterThan(0),
      reason: '破招应真开出破绽窗口,否则集火指向无从证伪(防空过)',
    );
    expect(
      xAfter.currentHp,
      greaterThan(5000),
      reason: '判别前提:X 挨破后血仍高于 Y(5000),集火与血最低两条规则才有区分度',
    );

    // 推进到跟进者行动(speed 120 → 破招手行动后下一 tick 满)。
    while (!s.actionLog.any((a) => a.actorId == 2 && a.attackResult != null) &&
        guard < 100) {
      s = strategy.tick(s, numbers, rng: Random(8));
      guard++;
    }
    expect(guard, lessThan(100), reason: '跟进者应在有限 tick 内行动');
    final followUp = s.actionLog.lastWhere(
      (a) => a.actorId == 2 && a.attackResult != null,
    );
    expect(
      followUp.targetId,
      -1,
      reason:
          '破绽窗口内同队攻击须集火被破敌 X(_pickFocusTargetId),'
          '而非血最低的 Y(_pickTargetId 回落)',
    );
  });
}
