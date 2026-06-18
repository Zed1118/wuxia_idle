// 第六阶段 Task 5 widget 测试：破绽窗口指令栏提示「该爆发了」。
//
// 验证：
//   1. 右队（敌方）有存活角色且 staggerTicksRemaining > 0 时，
//      指令栏上方出现「破绽 · 该爆发了」提示。
//   2. 右队无任何角色处于破绽窗口时，提示不出现。
//
// 遵循 break_window_feedback_widget_test.dart 体例：
//   - _TestBattleNotifier（no-op advance 防 Timer 触 GameRepository）。
//   - setSurfaceSize(1280, 720)。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_demo.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

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

/// no-op advance：防止 Timer 触发时读 GameRepository 崩溃。
class _TestBattleNotifier extends BattleNotifier {
  final BattleState _initial;
  _TestBattleNotifier(this._initial);

  @override
  BattleState build() => _initial;

  @override
  void advance({int maxConsecutiveTicks = 100}) {}
}

Future<void> _pumpBattle(
  WidgetTester tester,
  BattleState state,
) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        battleProvider.overrideWith(() => _TestBattleNotifier(state)),
      ],
      child: const MaterialApp(
        home: BattleScreen(animConfig: _testAnim, autoStart: false),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('破绽窗口指令栏提示', () {
    testWidgets('敌方有 staggerTicksRemaining>0 时显示「破绽 · 该爆发了」', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      // 将右队第 0 个角色置为 stagger>0（存活）。
      final staggeredRight = List<BattleCharacter>.from(right);
      staggeredRight[0] = staggeredRight[0].copyWith(
        staggerTicksRemaining: 3,
        isAlive: true,
      );
      final state = BattleState.initial(
        leftTeam: left,
        rightTeam: staggeredRight,
      );
      await _pumpBattle(tester, state);

      expect(
        find.text(UiStrings.coopBurstPrompt),
        findsOneWidget,
        reason: '敌方踉跄窗口开时，指令栏附近应显示「破绽 · 该爆发了」提示',
      );
    });

    testWidgets('敌方无 staggerTicksRemaining>0 时不显示提示', (tester) async {
      final (left, right) = BattleDemo.mockTeams();
      // BattleDemo.mockTeams() 默认 staggerTicksRemaining=0。
      final state = BattleState.initial(leftTeam: left, rightTeam: right);
      await _pumpBattle(tester, state);

      expect(
        find.text(UiStrings.coopBurstPrompt),
        findsNothing,
        reason: '无敌方踉跄时，不应出现「破绽 · 该爆发了」提示',
      );
    });
  });
}
