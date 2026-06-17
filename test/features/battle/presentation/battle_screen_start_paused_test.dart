import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_demo.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// 验收路由 startPaused + 单步键的 widget 红线。沿用 pause_test 的轻量 setUp
/// (override battleProvider 用 no-op advance,避免 Timer 触发读 GameRepository 崩)。
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

/// no-op advance（不触发真 tick）+ 计数 step()，step 时 tick++ 让 UI 可观测推进。
class _TestBattleNotifier extends BattleNotifier {
  final BattleState _initial;
  _TestBattleNotifier(this._initial);

  int stepCalls = 0;

  @override
  BattleState build() => _initial;

  @override
  void advance({int maxConsecutiveTicks = 100}) {}

  @override
  void step() {
    stepCalls++;
    state = state.copyWith(tick: state.tick + 1);
  }
}

Future<_TestBattleNotifier> _pumpBattle(
  WidgetTester tester, {
  required bool startPaused,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final (left, right) = BattleDemo.mockTeams();
  final notifier = _TestBattleNotifier(
    BattleState.initial(leftTeam: left, rightTeam: right),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [battleProvider.overrideWith(() => notifier)],
      child: MaterialApp(
        home: BattleScreen(animConfig: _testAnim, startPaused: startPaused),
      ),
    ),
  );
  await tester.pump();
  return notifier;
}

const _stepKey = ValueKey('battle_step_once');

void main() {
  testWidgets('startPaused 默认 false → 不暂停、无单步键(现有路径回归)', (tester) async {
    await _pumpBattle(tester, startPaused: false);
    // 默认不暂停:无暂停遮罩标题。
    expect(find.text(UiStrings.battlePausedTitle), findsNothing);
    // 单步键仅 startPaused 渲染 → 普通战斗不出现。
    expect(find.byKey(_stepKey), findsNothing);
  });

  testWidgets('startPaused=true → 起手暂停冻结初态、不自动推进', (tester) async {
    final notifier = await _pumpBattle(tester, startPaused: true);
    final tick0 = notifier.state.tick;
    // 多次 pump 推进虚拟时间:_isPaused gate 兜住 timer,tick 不变(无自动推进)。
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(notifier.state.tick, tick0, reason: '起手暂停 → 战斗冻结 seed 初态');
    expect(notifier.stepCalls, 0, reason: '未点单步 → step 不被调');
    // startPaused 模式不挂全屏遮罩(避免拦截单步),但顶栏可见单步键。
    expect(find.byKey(_stepKey), findsOneWidget);
  });

  testWidgets('startPaused=true → 单步键存在且点击推进战斗(step 被调)', (tester) async {
    final notifier = await _pumpBattle(tester, startPaused: true);
    final tick0 = notifier.state.tick;
    expect(find.byKey(_stepKey), findsOneWidget);

    await tester.tap(find.byKey(_stepKey));
    await tester.pump();
    expect(notifier.stepCalls, 1, reason: '点单步 → step() 被调一次');
    expect(notifier.state.tick, tick0 + 1, reason: 'step 推进 tick → UI 反映');

    await tester.tap(find.byKey(_stepKey));
    await tester.pump();
    expect(notifier.stepCalls, 2);
    expect(notifier.state.tick, tick0 + 2);
  });

  testWidgets('startPaused=false(普通战斗)→ 单步键不渲染(生产挂机纯净)', (tester) async {
    await _pumpBattle(tester, startPaused: false);
    expect(find.byKey(_stepKey), findsNothing);
  });
}
