import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/data/defs/skill_def.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_demo.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';

/// 半手动战斗 P0 步骤3c · 单步战斗 UI widget 测试。
///
/// 用户拍板(2026-06-13):A 强制停顿(每次「下一步」= 一次 [BattleNotifier.step])
/// / B 立即弹目标 picker(点单体技即弹选敌) / C 临时入口(manualStep flag)。
///
/// 沿 [battle_command_console_test] 的 no-op notifier 体例,避免 Timer / step
/// 触发时读 GameRepository 崩溃;step()/requestUltimate 在测试 notifier 里记录
/// 调用,不真推进战斗内核(内核确定性已由 battle_step_one_test 锁死)。
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

/// 单体强力技(目标 picker 用)。char 1 内力 5400 ≥ 200 → ready。
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

class _RecordingNotifier extends BattleNotifier {
  final BattleState _initial;
  _RecordingNotifier(this._initial);

  int stepCount = 0;
  final List<({int charId, String skillId, int? targetId})> requested = [];

  @override
  BattleState build() => _initial;

  @override
  void advance({int maxConsecutiveTicks = 100}) {}

  @override
  void step() {
    stepCount++;
  }

  @override
  void requestUltimate(int characterId, SkillDef ultimate, {int? targetId}) {
    requested.add((charId: characterId, skillId: ultimate.id, targetId: targetId));
    // 镜像生产语义置 pending(让「待发」印 / picker gate 等 UI 反应可被测到)。
    state = state.copyWith(
      pendingUltimates: {...state.pendingUltimates, characterId: ultimate},
    );
  }

  void setState(BattleState s) => state = s;
}

Future<_RecordingNotifier> _pump(
  WidgetTester tester, {
  required List<BattleCharacter> left,
  required List<BattleCharacter> right,
  bool manualStep = false,
  List<({int charId, int teamSide})> actorQueue = const [],
}) async {
  late _RecordingNotifier notifier;
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        battleProvider.overrideWith(() {
          notifier = _RecordingNotifier(
            BattleState.initial(leftTeam: left, rightTeam: right)
                .copyWith(actorQueue: actorQueue),
          );
          return notifier;
        }),
      ],
      child: MaterialApp(
        home: BattleScreen(animConfig: _testAnim, manualStep: manualStep),
      ),
    ),
  );
  await tester.pump();
  return notifier;
}

void main() {
  group('C · manualStep 入口 + A 强制停顿', () {
    testWidgets('manualStep=true 显示「下一步」按钮', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      await _pump(tester, left: left, right: right, manualStep: true);

      expect(
        find.byKey(const ValueKey('battle_next_step_button')),
        findsOneWidget,
      );
    });

    testWidgets('manualStep=false(默认)不显示「下一步」按钮(自动模式不变)',
        (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      await _pump(tester, left: left, right: right);

      expect(
        find.byKey(const ValueKey('battle_next_step_button')),
        findsNothing,
      );
    });

    testWidgets('点「下一步」调一次 notifier.step()(A 强制停顿:一步一 actor)',
        (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final n = await _pump(tester, left: left, right: right, manualStep: true);

      expect(n.stepCount, 0);
      await tester.tap(find.byKey(const ValueKey('battle_next_step_button')));
      await tester.pump();
      expect(n.stepCount, 1);
    });
  });

  group('A · 本回合行动顺序', () {
    testWidgets('actorQueue 非空 → 显示行动顺序条,含队列角色名', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      await _pump(
        tester,
        left: left,
        right: right,
        manualStep: true,
        actorQueue: const [
          (charId: 1, teamSide: 0),
          (charId: 11, teamSide: 1),
        ],
      );

      expect(
        find.byKey(const ValueKey('battle_actor_order_bar')),
        findsOneWidget,
      );
      // 队列两名 actor 的名字都在条上(萧夜寒=1 / 黑风寨主=11)。
      expect(find.textContaining('萧夜寒'), findsWidgets);
      expect(find.textContaining('黑风寨主'), findsWidgets);
    });

    testWidgets('actorQueue 空(tick 边界)→ 不显示行动顺序条', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      await _pump(tester, left: left, right: right, manualStep: true);

      expect(
        find.byKey(const ValueKey('battle_actor_order_bar')),
        findsNothing,
      );
    });
  });

  group('B · 单体技目标 picker(立即弹)', () {
    testWidgets('manualStep 点单体技 → 弹目标 picker 列存活敌人', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_power]);
      final n = await _pump(
        tester,
        left: [focus, ...left.skip(1)],
        right: right,
        manualStep: true,
      );

      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_p1')));
      await tester.pumpAndSettle();

      // picker 弹出,尚未下发(等选目标)。
      expect(
        find.byKey(const ValueKey('battle_target_picker')),
        findsOneWidget,
      );
      expect(n.requested, isEmpty);
      // 两名存活敌人(11/12)是选项,死亡的 13(毒娘子)不在。
      expect(
        find.byKey(const ValueKey('battle_target_option_11')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('battle_target_option_12')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('battle_target_option_13')),
        findsNothing,
      );
    });

    testWidgets('选目标 → requestUltimate 带该 targetId 下发', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_power]);
      final n = await _pump(
        tester,
        left: [focus, ...left.skip(1)],
        right: right,
        manualStep: true,
      );

      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('battle_target_option_12')));
      await tester.pumpAndSettle();

      expect(n.requested.length, 1);
      expect(n.requested.single.charId, 1);
      expect(n.requested.single.skillId, 'p1');
      expect(n.requested.single.targetId, 12);
      // picker 已关闭。
      expect(
        find.byKey(const ValueKey('battle_target_picker')),
        findsNothing,
      );
    });

    testWidgets('自动模式(manualStep=false)点技能 → 不弹 picker,直接下发(targetId=null)',
        (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      final focus = left.first.copyWith(availableSkills: [_power]);
      final n = await _pump(
        tester,
        left: [focus, ...left.skip(1)],
        right: right,
      );

      await tester.tap(find.byKey(const ValueKey('skill_cmd_1_p1')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('battle_target_picker')),
        findsNothing,
      );
      expect(n.requested.length, 1);
      expect(n.requested.single.targetId, isNull);
    });
  });
}
