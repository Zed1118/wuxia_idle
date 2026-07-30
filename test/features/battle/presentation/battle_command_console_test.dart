import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/application/battle_providers.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/domain/damage_calculator.dart';
import 'package:wuxia_idle/features/battle/domain/enum_localizations.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import '../../../support/battle_demo.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_layout_tokens.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/countdown_ring.dart';
import 'package:wuxia_idle/features/battle/presentation/widgets/battle_bottom_bar.dart';
import 'package:wuxia_idle/features/battle/presentation/widgets/battle_skill_slip.dart';

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
const _playerAoe = SkillDef(
  id: 'player_aoe',
  name: '万钧裂空',
  description: '',
  type: SkillType.ultimate,
  powerMultiplier: 4800,
  internalForceCost: 900,
  cooldownTurns: 5,
  requiresManualTrigger: true,
  targetType: TargetType.aoe,
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
const _breakB = SkillDef(
  id: 'b2',
  name: '断流指',
  description: '',
  type: SkillType.powerSkill,
  powerMultiplier: 1000,
  internalForceCost: 120,
  cooldownTurns: 2,
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
const _joint = SkillDef(
  id: 'j1',
  name: '双剑合璧',
  description: '',
  type: SkillType.jointSkill,
  powerMultiplier: 2400,
  internalForceCost: 320,
  cooldownTurns: 3,
  requiresManualTrigger: false,
  visualEffect: '',
);
const _powerC = SkillDef(
  id: 'pC',
  name: '回风掌',
  description: '',
  type: SkillType.powerSkill,
  powerMultiplier: 1300,
  internalForceCost: 180,
  cooldownTurns: 2,
  requiresManualTrigger: false,
  visualEffect: '',
);
const _ultB = SkillDef(
  id: 'uB',
  name: '天外飞仙',
  description: '',
  type: SkillType.ultimate,
  powerMultiplier: 4800,
  internalForceCost: 760,
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
  bool allowPlayerIntervention = true,
  List<({int charId, int teamSide})> actorQueue = const [],
}) async {
  late _TestBattleNotifier notifier;
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        battleProvider.overrideWith(() {
          notifier = _TestBattleNotifier(
            BattleState.initial(
              leftTeam: left,
              rightTeam: right,
            ).copyWith(actorQueue: actorQueue),
          );
          return notifier;
        }),
      ],
      child: MaterialApp(
        home: BattleScreen(
          animConfig: _testAnim,
          playback: BattleScreenPlaybackConfig(
            allowPlayerIntervention: allowPlayerIntervention,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return notifier;
}

void main() {
  group('自动观战轮转谱', () {
    testWidgets('自动案台轻压暗且仅陈列AI可轮转招式', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final actor = left.first.copyWith(availableSkills: [_power, _ult]);
      await _pumpWith(tester, [actor], right, allowPlayerIntervention: false);

      final opacity = tester.widget<Opacity>(
        find
            .descendant(
              of: find.byKey(const ValueKey('battle_auto_rotation_desk')),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, 0.92);
      expect(
        find.byKey(
          ValueKey('battle_auto_skill_${actor.characterId}_${_power.id}'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('skill_cmd_${actor.characterId}_${_ult.id}')),
        findsNothing,
      );
      expect(
        find.byKey(ValueKey('skill_cmd_${actor.characterId}_${_power.id}')),
        findsNothing,
      );
    });

    testWidgets('纯自动模式复用名帖七签与行囊的案台骨架', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final team = [
        left[0].copyWith(
          availableSkills: [_power, _ult],
          skillCooldowns: const {'p1': 2},
        ),
        left[1].copyWith(availableSkills: [_powerB], currentQi: 0),
        left[2].copyWith(availableSkills: [_powerC]),
      ];
      await _pumpWith(tester, team, right, allowPlayerIntervention: false);

      final desk = find.byKey(const ValueKey('battle_command_desk'));
      expect(desk, findsOneWidget);
      expect(
        find.byKey(const ValueKey('battle_auto_rotation_desk')),
        findsOneWidget,
      );
      for (final actor in team) {
        expect(
          find.byKey(ValueKey('focus_chip_${team.indexOf(actor)}')),
          findsOneWidget,
        );
        expect(find.text(actor.name), findsWidgets);
      }
      expect(find.text(UiStrings.battleAutoRotation), findsNothing);
      for (var i = 0; i < 7; i++) {
        expect(find.byKey(ValueKey('battle_skill_slot_$i')), findsOneWidget);
      }
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(ValueKey('battle_pouch_slot_$i')), findsOneWidget);
      }
      expect(
        tester.getSize(desk).height,
        BattleLayoutMetrics.resolve(
          tester.view.physicalSize / tester.view.devicePixelRatio,
        ).commandDeskHeight,
      );
      expect(
        find.descendant(of: desk, matching: find.byType(ButtonStyleButton)),
        findsNothing,
        reason: '自动案台与可点选案台同形，但不接受按钮、焦点或拖放输入',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('自动与可点选模式的案台三分区几何同构', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final team = [
        left[0].copyWith(availableSkills: [_power, _ult]),
        left[1].copyWith(availableSkills: [_powerB]),
        left[2].copyWith(availableSkills: [_powerC]),
      ];

      await _pumpWith(tester, team, right, allowPlayerIntervention: false);
      final autoFocus = tester.getRect(
        find.byKey(const ValueKey('battle_desk_focus_region')),
      );
      final autoSkills = tester.getRect(
        find.byKey(const ValueKey('battle_desk_skills_region')),
      );

      await _pumpWith(tester, team, right, allowPlayerIntervention: true);
      expect(
        tester.getRect(find.byKey(const ValueKey('battle_desk_focus_region'))),
        autoFocus,
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('battle_desk_skills_region'))),
        autoSkills,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('最近一次我方动作驱动执招者与招式签轮转亮起', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final first = left[0].copyWith(availableSkills: [_power]);
      final second = left[1].copyWith(availableSkills: [_powerB]);
      final notifier = await _pumpWith(
        tester,
        [first, second],
        right,
        allowPlayerIntervention: false,
      );

      notifier.appendActions([
        BattleAction(
          tick: 1,
          actorId: first.characterId,
          targetId: right.first.characterId,
          skill: _power,
          attackResult: _normalResult,
          description: '崩山拳命中',
        ),
      ]);
      await tester.pump();
      expect(
        find.byKey(ValueKey('battle_auto_actor_active_${first.characterId}')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('battle_auto_skill_active_p1')),
        findsOneWidget,
      );

      notifier.appendActions([
        BattleAction(
          tick: 2,
          actorId: second.characterId,
          targetId: right.last.characterId,
          skill: _powerB,
          attackResult: _normalResult,
          description: '穿云腿命中',
        ),
      ]);
      await tester.pump();
      expect(
        find.byKey(ValueKey('battle_auto_actor_active_${second.characterId}')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('battle_auto_skill_active_pB')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('battle_auto_actor_active_${first.characterId}')),
        findsNothing,
      );
    });

    testWidgets('轮转谱在单人、两人、三人队与双视口均不溢出', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      for (final size in const [Size(1280, 720), Size(1440, 900)]) {
        for (var teamSize = 1; teamSize <= 3; teamSize++) {
          await _pumpWith(
            tester,
            left.take(teamSize).toList(),
            right,
            size: size,
            allowPlayerIntervention: false,
          );
          expect(
            find.byKey(const ValueKey('battle_auto_rotation_desk')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        }
      }
    });
  });

  group('T2 蓄力危险条', () {
    testWidgets('敌人蓄力时顶部出现危险条，显示蓄力招名', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final charging = right.first.copyWith(
        chargingSkill: _chargeSkill,
        chargeTicksRemaining: 3,
      );
      await _pumpWith(tester, left, [charging, ...right.skip(1)]);

      expect(find.byKey(const ValueKey('battle_danger_bar')), findsOneWidget);
      expect(find.text(UiStrings.battleDangerChargeLabel), findsOneWidget);
      expect(find.textContaining(_chargeSkill.name), findsWidgets);
    });

    testWidgets('无敌人蓄力时不显示危险条', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      await _pumpWith(tester, left, right);

      expect(find.byKey(const ValueKey('battle_danger_bar')), findsNothing);
    });

    testWidgets('胜负已定后立即清退残留蓄力危险条', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final charging = right.first.copyWith(
        chargingSkill: _chargeSkill,
        chargeTicksRemaining: 3,
      );
      final notifier = await _pumpWith(tester, left, [
        charging,
        ...right.skip(1),
      ]);
      expect(find.byKey(const ValueKey('battle_danger_bar')), findsOneWidget);

      notifier.setState(notifier.state.copyWith(result: BattleResult.rightWin));
      await tester.pump();

      expect(find.byKey(const ValueKey('battle_danger_bar')), findsNothing);
      await tester.pump(const Duration(milliseconds: 401));
      await tester.pumpAndSettle();
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

    testWidgets('同拍三目标群攻在战报条只占一行且保留暴击代表', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final notifier = await _pumpWith(
        tester,
        left,
        right,
        size: const Size(1440, 900),
      );

      notifier.appendActions(const [
        BattleAction(
          tick: 6,
          actorId: 1,
          targetId: 11,
          skill: _playerAoe,
          attackResult: _normalResult,
          description: '群攻一',
        ),
        BattleAction(
          tick: 6,
          actorId: 1,
          targetId: 12,
          skill: _playerAoe,
          attackResult: _critResult,
          description: '群攻二暴击',
        ),
        BattleAction(
          tick: 6,
          actorId: 1,
          targetId: 13,
          skill: _playerAoe,
          attackResult: _normalResult,
          description: '群攻三',
        ),
      ]);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('battle_report_line_0')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('battle_report_line_1')), findsNothing);
      final reportLine = tester.widget<Text>(
        find.byKey(const ValueKey('battle_report_line_0')),
      );
      expect(reportLine.data, contains('暴击'));
      expect(tester.takeException(), isNull);
    });
  });

  group('T1 战斗指令台', () {
    testWidgets('技能签保留桌面按钮语义、焦点、键盘激活与点击光标', (tester) async {
      var activations = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 120,
                child: BattleSkillSlipSurface(
                  height: 150,
                  tiltAngle: 0,
                  backgroundColor: WuxiaUi.paper,
                  foregroundColor: WuxiaUi.ink,
                  border: const BorderSide(color: WuxiaUi.ink),
                  accent: WuxiaUi.jiang,
                  visualState: BattleSkillSlipVisualState.available,
                  onPressed: () => activations++,
                  onLongPress: () {},
                  child: const Text('desktop-skill-slip'),
                ),
              ),
            ),
          ),
        ),
      );

      final semantics = tester
          .getSemantics(find.byType(ElevatedButton))
          .getSemanticsData();
      expect(semantics.flagsCollection.isButton, isTrue);
      expect(semantics.flagsCollection.isEnabled, Tristate.isTrue);
      expect(semantics.hasAction(SemanticsAction.tap), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(activations, 1);

      final mouseRegions = tester.widgetList<MouseRegion>(
        find.descendant(
          of: find.byType(ElevatedButton),
          matching: find.byType(MouseRegion),
        ),
      );
      expect(
        mouseRegions.map((region) => region.cursor).any((cursor) {
          final resolved = cursor is WidgetStateMouseCursor
              ? cursor.resolve(const {WidgetState.hovered})
              : cursor;
          return resolved == SystemMouseCursors.click;
        }),
        isTrue,
      );
    });

    testWidgets('案台三段在双视口保持比例且七签无横向滚动', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      for (final size in const [Size(1280, 720), Size(1440, 900)]) {
        await _pumpWith(tester, left, right, size: size);

        final focus = tester.getSize(
          find.byKey(const ValueKey('battle_desk_focus_region')),
        );
        final skills = tester.getSize(
          find.byKey(const ValueKey('battle_desk_skills_region')),
        );
        final pouch = tester.getSize(
          find.byKey(const ValueKey('battle_desk_pouch_region')),
        );
        expect(focus.width / size.width, inInclusiveRange(0.15, 0.17));
        expect(skills.width / size.width, inInclusiveRange(0.51, 0.55));
        expect(pouch.width / size.width, inInclusiveRange(0.19, 0.21));
        expect(
          find.byKey(const ValueKey('battle_skill_slot_6')),
          findsOneWidget,
        );
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(tester.takeException(), isNull, reason: '$size 不应溢出');
      }
    });

    testWidgets('1280宽案台固定展示7个技能位与3个战备行囊位', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(
        availableSkills: [
          _power,
          _powerB,
          _powerC,
          _break,
          _joint,
          _ult,
          _ultB,
        ],
      );
      await _pumpWith(tester, [focus, ...left.skip(1)], right);

      final desk = find.byKey(const ValueKey('battle_command_desk'));
      expect(desk, findsOneWidget);
      for (var i = 0; i < 7; i++) {
        expect(
          find.descendant(
            of: desk,
            matching: find.byKey(ValueKey('battle_skill_slot_$i')),
          ),
          findsOneWidget,
        );
      }
      for (var i = 0; i < 3; i++) {
        expect(
          find.descendant(
            of: desk,
            matching: find.byKey(ValueKey('battle_pouch_slot_$i')),
          ),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(of: desk, matching: find.byType(SingleChildScrollView)),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('1440×900案台7技能位与3行囊位不溢出', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(
        availableSkills: [
          _power,
          _powerB,
          _powerC,
          _break,
          _joint,
          _ult,
          _ultB,
        ],
      );
      await _pumpWith(
        tester,
        [focus, ...left.skip(1)],
        right,
        size: const Size(1440, 900),
      );

      expect(find.byKey(const ValueKey('battle_skill_slot_6')), findsOneWidget);
      expect(find.byKey(const ValueKey('battle_pouch_slot_2')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('技能不足7个时保留稳定空槽', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(
        availableSkills: [_power, _break, _ult],
      );
      await _pumpWith(tester, [focus, ...left.skip(1)], right);

      for (var i = 0; i < 7; i++) {
        expect(find.byKey(ValueKey('battle_skill_slot_$i')), findsOneWidget);
      }
      for (var i = 3; i < 7; i++) {
        expect(find.byKey(ValueKey('battle_skill_empty_$i')), findsOneWidget);
        expect(
          find.byKey(ValueKey('battle.emptySkillSlot.blankPaper.$i')),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey('battle.emptySkillSlot.emptySeal.$i')),
          findsOneWidget,
        );
      }
      expect(find.text(UiStrings.battleEmptySkillSlot), findsNothing);

      final blankPaper = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('battle.emptySkillSlot.blankPaper.3')),
      );
      final decoration = blankPaper.decoration as BoxDecoration;
      expect(
        decoration.color!.a,
        lessThanOrEqualTo(0.34),
        reason: '空签应退入案台，不得形成大面积高亮空表单',
      );
      expect(
        decoration.image!.opacity,
        lessThanOrEqualTo(0.12),
        reason: '空签纸纹只保留弱材质提示',
      );
    });

    testWidgets('角色名帖保持三行等高，真气汇总独立落在底部', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final team = [
        left[0],
        left[1].copyWith(currentHp: 0, isAlive: false),
        left[2],
      ];
      await _pumpWith(tester, team, right);

      final expanded = find.byKey(
        ValueKey('battle.focusNameplate.expanded.${team.first.characterId}'),
      );
      expect(expanded, findsOneWidget);
      expect(
        find.descendant(
          of: expanded,
          matching: find.text(EnumL10n.school(team.first.school)),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: expanded,
          matching: find.text('${team.first.currentQi}/${team.first.maxQi}'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('battle.focusQiSummary')),
        findsOneWidget,
      );
      expect(
        find.text(
          '${UiStrings.statQi} ${team.first.currentQi}/${team.first.maxQi}',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('battle.focusQiProgress')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey('battle.focusNameplate.compact.${team[2].characterId}'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          ValueKey('battle.focusNameplate.faded.${team[1].characterId}'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('战备行囊使用木匣与三格旧锦而非技能签外形', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      await _pumpWith(tester, left, right);

      expect(
        find.byKey(const ValueKey('battle.pouch.woodCase')),
        findsOneWidget,
      );
      for (var i = 0; i < 3; i++) {
        expect(
          find.byKey(ValueKey('battle.pouch.brocadeSlot.$i')),
          findsOneWidget,
        );
      }
    });

    testWidgets('快进控制在顶栏而不在武学案台', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      await _pumpWith(tester, left, right);

      final speed = find.byKey(const ValueKey('battle_fast_forward_toggle'));
      expect(speed, findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('battle_command_desk')),
          matching: speed,
        ),
        findsNothing,
      );
    });

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
      // 样板使用单字朱印，不在签头横排完整分组名。
      expect(find.text(UiStrings.skillSealPower), findsWidgets);
      expect(find.text(UiStrings.skillSealInterrupt), findsWidgets);
      expect(find.text(UiStrings.skillSealUltimate), findsWidgets);
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
      expect(
        find.byKey(const ValueKey('battle.skillSlip.state.pending')),
        findsOneWidget,
      );
      expect(notifier.state.pendingUltimates[1], isNull);
    });

    testWidgets('待发选目标期间敌人蓄力不抢走实际出手角色焦点', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final pendingActor = left[0].copyWith(
        availableSkills: [_power],
        actionPoint: 1,
      );
      final interrupter = left[1].copyWith(
        availableSkills: [_break],
        actionPoint: 1,
      );
      final notifier = await _pumpWith(tester, [
        pendingActor,
        interrupter,
        left[2],
      ], right);

      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_p1')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('skill_pending_stamp_badge')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('target_chip_11')), findsOneWidget);

      notifier.setState(
        notifier.state.copyWith(
          rightTeam: [
            right.first.copyWith(
              chargingSkill: _chargeSkill,
              chargeTicksRemaining: 2,
            ),
            ...right.skip(1),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('skill_cmd_1_p1')), findsOneWidget);
      expect(find.byKey(const ValueKey('skill_cmd_2_b1')), findsNothing);
      expect(
        find.byKey(const ValueKey('skill_pending_stamp_badge')),
        findsOneWidget,
      );
    });

    testWidgets('待发期间主动切换队友会取消原待发再切换案台', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final c0 = left[0].copyWith(availableSkills: [_power], actionPoint: 1);
      final c1 = left[1].copyWith(availableSkills: [_powerB], actionPoint: 1);
      await _pumpWith(tester, [c0, c1, left[2]], right);

      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_p1')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('skill_pending_stamp_badge')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('focus_chip_1')));
      // 取消待发会恢复自动播放；只推进当前交互帧，避免测试追逐常驻计时器。
      await tester.pump();

      expect(
        find.byKey(const ValueKey('skill_pending_stamp_badge')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('target_chip_11')), findsNothing);
      expect(find.byKey(const ValueKey('skill_cmd_1_p1')), findsNothing);
      expect(find.byKey(const ValueKey('skill_cmd_2_pB')), findsOneWidget);
    });

    testWidgets('可用态技能签将招名、分类与耗气冷却收进完整卡面层级', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(
        availableSkills: [_power], // cost=200, cd=2
        currentInternalForce: 1000, // 充足，进可用态
        maxInternalForce: 1000,
        skillCooldowns: const {},
      );
      await _pumpWith(tester, [focus, ...left.skip(1)], right);

      final skill = find.byKey(const ValueKey('skill_cmd_1_p1'));
      expect(
        find.descendant(
          of: skill,
          matching: find.byKey(const ValueKey('battle.skillSlipHeader')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: skill,
          matching: find.byKey(const ValueKey('battle.skillSlipTitle')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: skill,
          matching: find.byKey(const ValueKey('battle.skillSlipFooter')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: skill,
          matching: find.byKey(const ValueKey('battle.skillSlipNaturalTilt')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: skill,
          matching: find.byKey(const ValueKey('battle.skillSlipRoughPaper')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: skill,
          matching: find.byKey(const ValueKey('battle.skillSlipNatureSeal')),
        ),
        findsOneWidget,
      );
      final titleRect = tester.getRect(
        find.descendant(
          of: skill,
          matching: find.byKey(const ValueKey('battle.skillSlipTitle')),
        ),
      );
      final sealRect = tester.getRect(
        find.descendant(
          of: skill,
          matching: find.byKey(const ValueKey('battle.skillSlipNatureSeal')),
        ),
      );
      expect(sealRect.top, greaterThan(titleRect.center.dy));
      final nativeButton = tester.widget<ElevatedButton>(
        find.descendant(of: skill, matching: find.byType(ElevatedButton)),
      );
      expect(nativeButton.style?.elevation?.resolve({}), 0);
      expect(
        nativeButton.style?.shape?.resolve({}),
        isA<BeveledRectangleBorder>(),
      );
      expect(
        find.byKey(const ValueKey('battle.skillSlip.state.available')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('battle.skillSlipQiCost')),
        findsOneWidget,
      );
      expect(find.text('200'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('battle.skillSlipQiSwirl')),
        findsOneWidget,
      );
    });

    testWidgets('真气不足态技能按钮显示「真气不足」', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(
        availableSkills: [_power], // cost=200
        currentInternalForce: 10, // < 200，内力不足
        maxInternalForce: 1000,
        skillCooldowns: const {},
      );
      await _pumpWith(tester, [focus, ...left.skip(1)], right);

      expect(find.text(UiStrings.skillInsufficientForce), findsNothing);
      expect(
        find.byKey(const ValueKey('battle.skillSlip.state.insufficientQi')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('battle.skillSlip.qiGap')),
        findsOneWidget,
      );
      final semantics = tester.widget<Semantics>(
        find.byKey(const ValueKey('skill_cmd_1_p1')),
      );
      expect(semantics.properties.value, UiStrings.skillInsufficientForce);
      // 内力不足态不显示可用态的耗内文案。
      expect(find.textContaining('耗气'), findsNothing);
    });

    testWidgets('减耗角色按有效耗气解锁按钮并显示实付值', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(
        availableSkills: [_power],
        currentQi: 160,
        maxQi: 1000,
        qiCostReductionPct: 0.20,
        skillCooldowns: const {},
      );
      await _pumpWith(tester, [focus, ...left.skip(1)], right);

      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('battle.skillSlipQiCost')))
            .data,
        '160',
      );
      expect(find.text(UiStrings.skillInsufficientForce), findsNothing);
      final semantics = tester.widget<Semantics>(
        find.byKey(const ValueKey('skill_cmd_1_p1')),
      );
      expect(semantics.properties.enabled, isTrue);
    });

    testWidgets('AP 归零态技能按钮显示「回势中」并保持禁用', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(
        availableSkills: [_power],
        currentInternalForce: 1000,
        maxInternalForce: 1000,
        skillCooldowns: const {},
        actionPoint: 0,
      );
      await _pumpWith(tester, [focus, ...left.skip(1)], right);

      expect(find.text(UiStrings.skillAwaitingAction), findsNothing);
      final semantics = tester.widget<Semantics>(
        find.byKey(const ValueKey('skill_cmd_1_p1')),
      );
      expect(semantics.properties.enabled, isFalse);
      expect(semantics.properties.value, UiStrings.skillAwaitingAction);
    });

    testWidgets('蓄力中技能按钮显示「蓄力中」并保持禁用', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(
        availableSkills: [_power],
        currentInternalForce: 1000,
        maxInternalForce: 1000,
        skillCooldowns: const {},
        actionPoint: 300,
        chargingSkill: _power,
        chargeTicksRemaining: 2,
      );
      await _pumpWith(tester, [focus, ...left.skip(1)], right);

      expect(find.text(UiStrings.skillCharging), findsNothing);
      final semantics = tester.widget<Semantics>(
        find.byKey(const ValueKey('skill_cmd_1_p1')),
      );
      expect(semantics.properties.enabled, isFalse);
      expect(semantics.properties.value, UiStrings.skillCharging);
    });

    testWidgets('踉跄中技能按钮显示「踉跄中」并保持禁用', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(
        availableSkills: [_power],
        currentInternalForce: 1000,
        maxInternalForce: 1000,
        skillCooldowns: const {},
        actionPoint: 300,
        staggerTicksRemaining: 2,
      );
      await _pumpWith(tester, [focus, ...left.skip(1)], right);

      expect(find.text(UiStrings.skillStaggered), findsNothing);
      final semantics = tester.widget<Semantics>(
        find.byKey(const ValueKey('skill_cmd_1_p1')),
      );
      expect(semantics.properties.enabled, isFalse);
      expect(semantics.properties.value, UiStrings.skillStaggered);
    });

    testWidgets('冷却态技能按钮显读秒环 + 中心剩余拍数（不再显文字「冷却N」）', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(
        availableSkills: [_power], // cd=2
        currentInternalForce: 1000,
        maxInternalForce: 1000,
        skillCooldowns: const {'p1': 3}, // CD 中
      );
      await _pumpWith(tester, [focus, ...left.skip(1)], right);

      final ring = find.descendant(
        of: find.byKey(const ValueKey('skill_cmd_1_p1')),
        matching: find.byType(BeatCountdownRing),
      );
      expect(ring, findsOneWidget);
      // 读秒环喂入剩余 = 该技能 CD(3)；渲染 ceil 值随节拍插值,由 countdown_ring 单测覆盖。
      expect(tester.widget<BeatCountdownRing>(ring).remaining, 3);
      expect(
        tester.widget<BeatCountdownRing>(ring).total,
        _power.cooldownTurns,
      );
      expect(find.text('冷却3'), findsNothing);
      expect(
        find.byKey(const ValueKey('battle.skillSlip.state.cooldown')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('battle.skillSlip.inkCooldown')),
        findsOneWidget,
      );
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

    testWidgets('当前重点角色阵亡后自动回落首个存活队友', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final c0 = left[0].copyWith(availableSkills: [_power]);
      final c1 = left[1].copyWith(availableSkills: [_powerB]);
      final notifier = await _pumpWith(tester, [c0, c1, left[2]], right);

      expect(find.byKey(const ValueKey('skill_cmd_1_p1')), findsOneWidget);
      notifier.setState(
        notifier.state.copyWith(
          leftTeam: [c0.copyWith(currentHp: 0, isAlive: false), c1, left[2]],
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('skill_cmd_1_p1')), findsNothing);
      expect(find.byKey(const ValueKey('skill_cmd_2_pB')), findsOneWidget);
      final fallbackChip = tester.widget<FocusChip>(
        find.byKey(const ValueKey('focus_chip_1')),
      );
      expect(fallbackChip.selected, isTrue);
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
      expect(
        find.byKey(const ValueKey('battle.skillSlip.state.interrupt')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('battle.skillSlip.interruptLift')),
        findsOneWidget,
      );
    });

    testWidgets('敌人蓄力时保留已可破招的玩家手选角色', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final c0 = left[0].copyWith(availableSkills: [_break], actionPoint: 1);
      final c1 = left[1].copyWith(availableSkills: [_break], actionPoint: 1);
      final notifier = await _pumpWith(tester, [c0, c1, left[2]], right);

      await tester.tap(find.byKey(const ValueKey('focus_chip_1')));
      await tester.pump();
      expect(find.byKey(const ValueKey('skill_cmd_2_b1')), findsOneWidget);

      notifier.setState(
        notifier.state.copyWith(
          rightTeam: [
            right.first.copyWith(
              chargingSkill: _chargeSkill,
              chargeTicksRemaining: 2,
            ),
            ...right.skip(1),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('skill_cmd_2_b1')), findsOneWidget);
      final selected = tester.widget<FocusChip>(
        find.byKey(const ValueKey('focus_chip_1')),
      );
      expect(selected.selected, isTrue);
    });

    testWidgets('蓄力焦点扫描角色全部破招技而非只看第一招', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final c0 = left[0].copyWith(availableSkills: [_power]);
      final c1 = left[1].copyWith(
        availableSkills: [_break, _breakB],
        skillCooldowns: const {'b1': 2},
        actionPoint: 1,
      );
      final charging = right.first.copyWith(
        chargingSkill: _chargeSkill,
        chargeTicksRemaining: 2,
      );

      await _pumpWith(tester, [c0, c1, left[2]], [charging, ...right.skip(1)]);

      expect(find.byKey(const ValueKey('skill_cmd_2_b2')), findsOneWidget);
      expect(find.byKey(const ValueKey('skill_cmd_1_p1')), findsNothing);
    });

    testWidgets('破绽窗口时当前角色不可操作则临时切到可爆发队友', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final blocked = left[0].copyWith(
        availableSkills: [_power],
        actionPoint: 0,
      );
      final actionable = left[1].copyWith(
        availableSkills: [_powerB],
        actionPoint: 1,
      );
      final staggered = right.first.copyWith(staggerTicksRemaining: 2);

      for (final size in const [Size(1280, 720), Size(1440, 900)]) {
        final notifier = await _pumpWith(
          tester,
          [blocked, actionable, left[2]],
          [staggered, ...right.skip(1)],
          size: size,
        );

        expect(find.text(UiStrings.coopBurstPrompt), findsOneWidget);
        expect(find.byKey(const ValueKey('skill_cmd_2_pB')), findsOneWidget);
        expect(find.byKey(const ValueKey('skill_cmd_1_p1')), findsNothing);
        expect(tester.takeException(), isNull, reason: '$size 不应溢出');

        notifier.setState(
          notifier.state.copyWith(rightTeam: [right.first, ...right.skip(1)]),
        );
        await tester.pump();

        expect(find.byKey(const ValueKey('skill_cmd_1_p1')), findsOneWidget);
        expect(find.byKey(const ValueKey('skill_cmd_2_pB')), findsNothing);
      }
    });

    testWidgets('破绽窗口保留已可操作的玩家手选角色', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final c0 = left[0].copyWith(availableSkills: [_power], actionPoint: 1);
      final c1 = left[1].copyWith(availableSkills: [_powerB], actionPoint: 1);
      final notifier = await _pumpWith(tester, [c0, c1, left[2]], right);

      await tester.tap(find.byKey(const ValueKey('focus_chip_1')));
      await tester.pump();
      expect(find.byKey(const ValueKey('skill_cmd_2_pB')), findsOneWidget);

      notifier.setState(
        notifier.state.copyWith(
          rightTeam: [
            right.first.copyWith(staggerTicksRemaining: 2),
            ...right.skip(1),
          ],
        ),
      );
      await tester.pump();

      expect(find.text(UiStrings.coopBurstPrompt), findsOneWidget);
      expect(find.byKey(const ValueKey('skill_cmd_2_pB')), findsOneWidget);
      expect(find.byKey(const ValueKey('skill_cmd_1_p1')), findsNothing);
    });

    testWidgets('拍内行动队列未结算完时不提示破绽爆发或切换焦点', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final selected = left[0].copyWith(
        availableSkills: [_power],
        actionPoint: 1,
      );
      final ally = left[1].copyWith(availableSkills: [_powerB], actionPoint: 1);
      final staggered = right.first.copyWith(staggerTicksRemaining: 2);

      await _pumpWith(
        tester,
        [selected, ally, left[2]],
        [staggered, ...right.skip(1)],
        actorQueue: const [(charId: 2, teamSide: 0)],
      );

      expect(find.text(UiStrings.coopBurstPrompt), findsNothing);
      expect(find.byKey(const ValueKey('skill_cmd_1_p1')), findsOneWidget);
      expect(find.byKey(const ValueKey('skill_cmd_2_pB')), findsNothing);
      final semantics = tester.widget<Semantics>(
        find.byKey(const ValueKey('skill_cmd_1_p1')),
      );
      expect(semantics.properties.enabled, isFalse);
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

    testWidgets('最大密度战斗 HUD 在 1280×720 同屏不挤爆战场', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(
        availableSkills: [_power, _break, _ult],
        currentInternalForce: 1600,
        maxInternalForce: 1600,
      );
      final ally = left[1].copyWith(
        internalInjury: const InternalInjurySlot(
          remainingTurns: 2,
          damagePerTick: 200,
        ),
        staggerTicksRemaining: 1,
      );
      final boss = right.first.copyWith(
        isBoss: true,
        chargingSkill: _chargeSkill,
        chargeTicksRemaining: 1,
        internalInjury: const InternalInjurySlot(
          remainingTurns: 3,
          damagePerTick: 200,
        ),
        staggerTicksRemaining: 2,
        swordSongResonanceActive: true,
      );
      final enemy = right[1].copyWith(staggerTicksRemaining: 2);
      final notifier = await _pumpWith(
        tester,
        [focus, ally, left[2]],
        [boss, enemy, right[2]],
      );

      notifier.appendActions(const [
        BattleAction(
          tick: 1,
          actorId: 1,
          targetId: 11,
          skill: _playerUlt,
          attackResult: _critResult,
          description: 'dense-ult',
        ),
        BattleAction(
          tick: 2,
          actorId: 2,
          targetId: 12,
          attackResult: _critResult,
          description: 'dense-crit',
          openedBreakWindow: true,
        ),
        BattleAction(
          tick: 3,
          actorId: 3,
          targetId: 13,
          skill: _playerUlt,
          attackResult: _critResult,
          description: 'dense-ult-2',
        ),
      ]);
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'before pending target hints',
      );

      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_p1')));
      await tester.pump();

      expect(find.byKey(const ValueKey('battle_danger_bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('battle_report_strip')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('battle_report_line_2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('coop_burst_prompt_bar')),
        findsOneWidget,
      );
      expect(
        find.byKey(ValueKey('enemy_target_hint_${boss.characterId}')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('battle.bossAvatarFrame')),
        findsOneWidget,
      );
      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason: exception is FlutterError ? exception.toStringDeep() : null,
      );
    });
  });
}
