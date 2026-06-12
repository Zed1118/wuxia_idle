import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_demo.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';
import 'package:wuxia_idle/features/battle/presentation/victory_overlay.dart';
import 'package:wuxia_idle/data/numbers_config.dart';

/// 最短测试动画时序，加速 pumpAndSettle。
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

/// 可写 state 的 TestNotifier,允许测试注入任意 BattleState。
/// advance() 是 no-op,避免在 widget test 中触发 GameRepository 依赖。
class _TestBattleNotifier extends BattleNotifier {
  final BattleState _initial;
  _TestBattleNotifier(this._initial);

  @override
  BattleState build() => _initial;

  @override
  void advance({int maxConsecutiveTicks = 100}) {}

  /// 直接推送一个新 state,触发 ref.listen 边沿。
  void push(BattleState s) => state = s;
}

/// 构建 BattleScreen,返回注入的 notifier 供后续 push 状态。
Future<_TestBattleNotifier> _pump(
  WidgetTester tester, {
  bool deferVictoryToCaller = false,
  VoidCallback? onVictory,
  VoidCallback? onBattleEnd,
}) async {
  late _TestBattleNotifier notifier;
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final (left, right) = BattleDemo.mockTeams();
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
      child: MaterialApp(
        home: BattleScreen(
          animConfig: _testAnim,
          deferVictoryToCaller: deferVictoryToCaller,
          onVictory: onVictory,
          onBattleEnd: onBattleEnd,
          autoStart: false, // 禁 Timer,避免 GameRepository 读取崩溃
        ),
      ),
    ),
  );
  await tester.pump();
  return notifier;
}

/// 将 notifier 推进到 leftWin 已结束状态,并让 postFrameCallback 触发。
Future<void> _triggerLeftWin(
  WidgetTester tester,
  _TestBattleNotifier notifier,
) async {
  final finished = notifier.state.copyWith(result: BattleResult.leftWin);
  notifier.push(finished);
  // ref.listen 检测到 result 由 null→非空 → addPostFrameCallback(_showResultDialog)
  await tester.pump(); // 触发 ref.listen + postFrameCallback 注册
  await tester.pump(); // 执行 postFrameCallback
  // 等待 showGeneralDialog 的过渡动画(若有 overlay 则等其出现)
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  // ─── 主测试 1: deferVictoryToCaller=true + leftWin → 不弹 overlay,直接回调 ──

  testWidgets(
    'deferVictoryToCaller=true: leftWin 不弹 VictoryOverlay,直接触发 onVictory',
    (tester) async {
      var victoryCalled = 0;
      var battleEndCalled = 0;

      final notifier = await _pump(
        tester,
        deferVictoryToCaller: true,
        onVictory: () => victoryCalled++,
        onBattleEnd: () => battleEndCalled++,
      );

      await _triggerLeftWin(tester, notifier);

      // overlay 不应出现
      expect(find.byType(VictoryOverlay), findsNothing);
      // 回调必须各被调用恰好一次
      expect(victoryCalled, 1);
      expect(battleEndCalled, 1);
    },
  );

  // ─── 主测试 2: deferVictoryToCaller=false(默认) + leftWin → 弹 VictoryOverlay ─

  testWidgets(
    'deferVictoryToCaller=false(默认): leftWin 弹出 VictoryOverlay',
    (tester) async {
      final notifier = await _pump(tester, deferVictoryToCaller: false);

      await _triggerLeftWin(tester, notifier);

      expect(find.byType(VictoryOverlay), findsOneWidget);
    },
  );
}
