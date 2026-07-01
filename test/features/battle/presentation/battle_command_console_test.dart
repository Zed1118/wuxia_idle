import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_demo.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';

/// 批三战斗指令台（T1/T2/T3）widget 测试。
///
/// 复用 [battle_screen_log_test] 的 no-op advance notifier 体例，避免 Timer
/// 触发时读 GameRepository 崩溃；所有用例显式构造 BattleState。

const _testAnim = AnimationNumbers(
  attackRushMs: 10,
  attackHoldMs: 10,
  attackRetreatMs: 10,
  attackRushOffsetPx: 20.0,
  damagePopupFloatPx: 20.0,
  damagePopupMs: 100,
  actionIntervalMs: 50,
  fastForwardIntervalMs: 20,
  shakeOffsetPx: 1.0,
  shakeDurationMs: 50,
  criticalFontScale: 1.5,
  projectileMs: 30,
  hitFlashMs: 30,
);

class _TestBattleNotifier extends BattleNotifier {
  final BattleState _initial;
  _TestBattleNotifier(this._initial);

  @override
  BattleState build() => _initial;

  @override
  void advance({int maxConsecutiveTicks = 100}) {}

  void setState(BattleState s) => state = s;

  void appendActions(List<BattleAction> actions) {
    state = state.copyWith(actionLog: [...state.actionLog, ...actions]);
  }
}

const _normalResult = AttackResult(
  finalDamage: 800,
  mainDamage: 800,
  quakeDamage: 0,
  isCritical: false,
  isDodged: false,
  schoolCounterMultiplier: 1.0,
  realmDiffAttackerMod: 1.0,
  realmDiffDefenderMod: 1.0,
  cultivationMultiplier: 1.0,
  criticalMultiplier: 1.0,
  defenseRate: 0.15,
  evasionRate: 0.05,
  appliedEffects: <String>[],
  formulaBreakdown: 'normal',
);

const _critResult = AttackResult(
  finalDamage: 2600,
  mainDamage: 2600,
  quakeDamage: 0,
  isCritical: true,
  isDodged: false,
  schoolCounterMultiplier: 1.0,
  realmDiffAttackerMod: 1.0,
  realmDiffDefenderMod: 1.0,
  cultivationMultiplier: 1.0,
  criticalMultiplier: 1.8,
  defenseRate: 0.15,
  evasionRate: 0.05,
  appliedEffects: <String>[],
  formulaBreakdown: 'crit',
);

/// 玩家大招（T3 关键战报用）。
const _playerUlt = SkillDef(
  id: 'player_ult',
  name: '惊雷无双斩',
  description: '',
  type: SkillType.ultimate,
  powerMultiplier: 5000,
  internalForceCost: 1000,
  cooldownTurns: 5,
  requiresManualTrigger: true,
  visualEffect: '',
);

// ── T1 指令台测试技能 ──────────────────────────────────────────────────────
const _power = SkillDef(
  id: 'p1',
  name: '崩山拳',
  description: '',
  type: SkillType.powerSkill,
  powerMultiplier: 1500,
  internalForceCost: 200,
  cooldownTurns: 2,
  requiresManualTrigger: false,
  visualEffect: '',
);
const _powerB = SkillDef(
  id: 'pB',
  name: '穿云腿',
  description: '',
  type: SkillType.powerSkill,
  powerMultiplier: 1400,
  internalForceCost: 200,
  cooldownTurns: 2,
  requiresManualTrigger: false,
  visualEffect: '',
);
const _break = SkillDef(
  id: 'b1',
  name: '截脉手',
  description: '',
  type: SkillType.powerSkill,
  powerMultiplier: 1200,
  internalForceCost: 150,
  cooldownTurns: 3,
  requiresManualTrigger: false,
  canInterrupt: true,
  visualEffect: '',
);
const _ult = SkillDef(
  id: 'u1',
  name: '龙吟九霄',
  description: '',
  type: SkillType.ultimate,
  powerMultiplier: 5000,
  internalForceCost: 800,
  cooldownTurns: 5,
  requiresManualTrigger: true,
  visualEffect: '',
);

/// 敌人蓄力中的大招（T2 危险条用）。
const _chargeSkill = SkillDef(
  id: 'enemy_charge_ult',
  name: '裂石碎金掌',
  description: '',
  type: SkillType.ultimate,
  powerMultiplier: 5000,
  internalForceCost: 1000,
  cooldownTurns: 5,
  requiresManualTrigger: false,
  visualEffect: '',
);

Future<_TestBattleNotifier> _pumpWith(
  WidgetTester tester,
  List<BattleCharacter> left,
  List<BattleCharacter> right, {
  Size size = const Size(1280, 720),
}) async {
  late _TestBattleNotifier notifier;
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        battleProvider.overrideWith(() {
          notifier = _TestBattleNotifier(
            BattleState.initial(leftTeam: left, rightTeam: right),
          );
          return notifier;
        }),
      ],
      child: const MaterialApp(
        home: BattleScreen(
          animConfig: _testAnim,
          allowPlayerIntervention: true,
        ),
      ),
    ),
  );
  await tester.pump();
  return notifier;
}

void main() {
  group('T2 蓄力危险条', () {
    testWidgets('敌人蓄力时顶部出现危险条，显示蓄力招名', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final charging = right.first.copyWith(
        chargingSkill: _chargeSkill,
        chargeTicksRemaining: 3,
      );
      await _pumpWith(tester, left, [charging, ...right.skip(1)]);

      expect(find.byKey(const ValueKey('battle_danger_bar')), findsOneWidget);
      expect(find.textContaining(_chargeSkill.name), findsWidgets);
    });

    testWidgets('无敌人蓄力时不显示危险条', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      await _pumpWith(tester, left, right);

      expect(find.byKey(const ValueKey('battle_danger_bar')), findsNothing);
    });
  });

  group('T3 最近战报3条', () {
    testWidgets('大招命中进入底部战报条，显示招名', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final notifier = await _pumpWith(tester, left, right);

      notifier.appendActions(const [
        BattleAction(
          tick: 3,
          actorId: 1,
          targetId: 11,
          skill: _playerUlt,
          attackResult: _normalResult,
          description: '大招命中',
        ),
      ]);
      await tester.pump();

      expect(find.byKey(const ValueKey('battle_report_strip')), findsOneWidget);
      expect(find.textContaining(_playerUlt.name), findsWidgets);
    });

    testWidgets('暴击命中进入战报条', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final notifier = await _pumpWith(tester, left, right);

      notifier.appendActions(const [
        BattleAction(
          tick: 4,
          actorId: 2,
          targetId: 12,
          attackResult: _critResult,
          description: '暴击',
        ),
      ]);
      await tester.pump();

      expect(find.byKey(const ValueKey('battle_report_strip')), findsOneWidget);
    });

    testWidgets('普通非关键命中不进战报条', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final notifier = await _pumpWith(tester, left, right);

      notifier.appendActions(const [
        BattleAction(
          tick: 5,
          actorId: 1,
          targetId: 11,
          attackResult: _normalResult,
          description: '普攻',
        ),
      ]);
      await tester.pump();

      expect(find.byKey(const ValueKey('battle_report_strip')), findsNothing);
    });

    testWidgets('点战报条打开完整日志抽屉', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final notifier = await _pumpWith(tester, left, right);

      notifier.appendActions(const [
        BattleAction(
          tick: 3,
          actorId: 1,
          targetId: 11,
          skill: _playerUlt,
          attackResult: _critResult,
          description: '大招暴击',
        ),
      ]);
      await tester.pump();

      expect(find.byKey(const ValueKey('battle_log_drawer')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('battle_report_strip')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('battle_log_drawer')), findsOneWidget);
    });

    testWidgets('只显示最近3条关键战报', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final notifier = await _pumpWith(tester, left, right);

      notifier.appendActions(const [
        BattleAction(
          tick: 1,
          actorId: 1,
          targetId: 11,
          skill: _playerUlt,
          attackResult: _normalResult,
          description: 'u1',
        ),
        BattleAction(
          tick: 2,
          actorId: 2,
          targetId: 12,
          attackResult: _critResult,
          description: 'c1',
        ),
        BattleAction(
          tick: 3,
          actorId: 3,
          targetId: 13,
          skill: _playerUlt,
          attackResult: _normalResult,
          description: 'u2',
        ),
        BattleAction(
          tick: 4,
          actorId: 1,
          targetId: 11,
          attackResult: _critResult,
          description: 'c2',
        ),
      ]);
      await tester.pump();

      // 最近 3 条关键：tick 2/3/4；tick1 的 u1 应被挤出。
      expect(
        find.byKey(const ValueKey('battle_report_line_0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('battle_report_line_1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('battle_report_line_2')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('battle_report_line_3')), findsNothing);
    });
  });

  group('T1 战斗指令台', () {
    testWidgets('指令台暴露重点角色的全部可用技能（分组按钮）', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(
        availableSkills: [_power, _break, _ult],
      );
      await _pumpWith(tester, [focus, ...left.skip(1)], right);

      // 重点角色默认 = 0 号，三类技能按钮都出现。
      expect(find.byKey(const ValueKey('skill_cmd_1_p1')), findsOneWidget);
      expect(find.byKey(const ValueKey('skill_cmd_1_b1')), findsOneWidget);
      expect(find.byKey(const ValueKey('skill_cmd_1_u1')), findsOneWidget);
      // 分组标签
      expect(find.text('强力'), findsWidgets);
      expect(find.text('破招'), findsWidgets);
      expect(find.text('大招'), findsWidgets);
    });

    // 两段点选：长按技能方块弹简介浮层(不下发);点击 = 释放由 battle_tap_skill_test 守。
    testWidgets('长按技能方块 → 弹简介浮层，不写 pending', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_power, _ult]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);

      await tester.longPress(find.byKey(const ValueKey('skill_cmd_1_p1')));
      await tester.pumpAndSettle();

      // 长按只弹浮层（关闭按钮「知道了」可见），不下发命令。
      expect(find.text('知道了'), findsOneWidget);
      expect(notifier.state.pendingUltimates[1], isNull);
    });

    testWidgets('点 single 技能方块显示本地「待发」印但不写 pendingUltimates', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_power, _ult]);
      final notifier = await _pumpWith(tester, [focus, ...left.skip(1)], right);

      expect(find.text('待发'), findsNothing);
      // 点击 single 技进待发态(本地 UI 态)，按钮盖「待发」印，但 domain pending 仍为空。
      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_p1')));
      await tester.pumpAndSettle();
      expect(find.text('待发'), findsWidgets);
      expect(
        find.byKey(const ValueKey('skill_pending_stamp_badge')),
        findsOneWidget,
      );
      expect(notifier.state.pendingUltimates[1], isNull);
    });

    testWidgets('可用态技能按钮显示「耗内N · CDM」（批次 1.2）', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(
        availableSkills: [_power], // cost=200, cd=2
        currentInternalForce: 1000, // 充足，进可用态
        maxInternalForce: 1000,
        skillCooldowns: const {},
      );
      await _pumpWith(tester, [focus, ...left.skip(1)], right);

      // 耗内200 · CD2
      expect(find.text(UiStrings.skillCostShort(200, 2)), findsOneWidget);
      expect(find.textContaining('耗内200'), findsOneWidget);
      expect(find.textContaining('CD2'), findsOneWidget);
    });

    testWidgets('内力不足态技能按钮显示「内力不足」（批次 1.2）', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(
        availableSkills: [_power], // cost=200
        currentInternalForce: 10, // < 200，内力不足
        maxInternalForce: 1000,
        skillCooldowns: const {},
      );
      await _pumpWith(tester, [focus, ...left.skip(1)], right);

      expect(find.text(UiStrings.skillInsufficientForce), findsOneWidget);
      expect(find.text('内力不足'), findsOneWidget);
      // 内力不足态不显示可用态的耗内文案。
      expect(find.textContaining('耗内'), findsNothing);
    });

    testWidgets('冷却态技能按钮显示「冷却N」（批次 1.2 保持现状）', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(
        availableSkills: [_power], // cd=2
        currentInternalForce: 1000,
        maxInternalForce: 1000,
        skillCooldowns: const {'p1': 3}, // CD 中
      );
      await _pumpWith(tester, [focus, ...left.skip(1)], right);

      expect(find.text(UiStrings.skillCooldownShort(3)), findsOneWidget);
      expect(find.text('冷却3'), findsOneWidget);
    });

    testWidgets('点头像切换重点角色，露出另一角色的技能', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final c0 = left[0].copyWith(availableSkills: [_power]);
      final c1 = left[1].copyWith(availableSkills: [_powerB]);
      await _pumpWith(tester, [c0, c1, left[2]], right);

      expect(find.byKey(const ValueKey('skill_cmd_1_p1')), findsOneWidget);
      expect(find.byKey(const ValueKey('skill_cmd_2_pB')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('focus_chip_1')));
      await tester.pump();

      expect(find.byKey(const ValueKey('skill_cmd_1_p1')), findsNothing);
      expect(find.byKey(const ValueKey('skill_cmd_2_pB')), findsOneWidget);
    });

    testWidgets('敌人蓄力时重点角色自动切到可破招者', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final c0 = left[0].copyWith(availableSkills: [_power]); // 无破招
      final c1 = left[1].copyWith(availableSkills: [_break]); // 有破招
      final charging = right.first.copyWith(
        chargingSkill: _chargeSkill,
        chargeTicksRemaining: 2,
      );
      await _pumpWith(tester, [c0, c1, left[2]], [charging, ...right.skip(1)]);

      // 未手动切焦点，但敌人蓄力 → 焦点自动落到 1 号（有可破招技）。
      expect(find.byKey(const ValueKey('skill_cmd_2_b1')), findsOneWidget);
      expect(find.byKey(const ValueKey('skill_cmd_1_p1')), findsNothing);
    });

    testWidgets('指令台 + 危险条 + 战报条同屏 1280×720 不溢出', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(
        availableSkills: [_power, _break, _ult],
      );
      final charging = right.first.copyWith(
        chargingSkill: _chargeSkill,
        chargeTicksRemaining: 3,
      );
      final notifier = await _pumpWith(
        tester,
        [focus, ...left.skip(1)],
        [charging, ...right.skip(1)],
      );
      notifier.appendActions(const [
        BattleAction(
          tick: 3,
          actorId: 1,
          targetId: 11,
          skill: _playerUlt,
          attackResult: _critResult,
          description: '大招暴击',
        ),
      ]);
      await tester.pump();

      expect(find.byKey(const ValueKey('battle_danger_bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('battle_report_strip')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
