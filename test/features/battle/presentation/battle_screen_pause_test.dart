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

/// no-op advance：避免 Timer 触发时读 GameRepository 崩溃(沿用 log_test 体例)。
class _TestBattleNotifier extends BattleNotifier {
  final BattleState _initial;
  _TestBattleNotifier(this._initial);

  @override
  BattleState build() => _initial;

  @override
  void advance({int maxConsecutiveTicks = 100}) {}
}

Future<void> _pumpBattle(
  WidgetTester tester, {
  VoidCallback? onSurrender,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final (left, right) = BattleDemo.mockTeams();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        battleProvider.overrideWith(
          () => _TestBattleNotifier(
            BattleState.initial(leftTeam: left, rightTeam: right),
          ),
        ),
      ],
      child: MaterialApp(
        home: BattleScreen(animConfig: _testAnim, onSurrender: onSurrender),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('默认无暂停遮罩,顶栏有暂停键', (tester) async {
    await _pumpBattle(tester);
    expect(find.text(UiStrings.battlePausedTitle), findsNothing);
    expect(find.byKey(const ValueKey('battle_pause_toggle')), findsOneWidget);
  });

  testWidgets('点暂停 → 遮罩出现;点继续 → 遮罩消失', (tester) async {
    await _pumpBattle(tester);

    await tester.tap(find.byKey(const ValueKey('battle_pause_toggle')));
    await tester.pump();
    expect(find.text(UiStrings.battlePausedTitle), findsOneWidget);

    // 遮罩上的「继续」按钮(唯一渲染的文本;顶栏 tooltip 不入树)。
    await tester.tap(find.text(UiStrings.battleResume));
    await tester.pump();
    expect(find.text(UiStrings.battlePausedTitle), findsNothing);
  });

  testWidgets('轻触遮罩任意处也恢复', (tester) async {
    await _pumpBattle(tester);
    await tester.tap(find.byKey(const ValueKey('battle_pause_toggle')));
    await tester.pump();
    expect(find.text(UiStrings.battlePausedTitle), findsOneWidget);

    await tester.tapAt(const Offset(100, 100)); // 遮罩左上角空白处
    await tester.pump();
    expect(find.text(UiStrings.battlePausedTitle), findsNothing);
  });

  testWidgets('onSurrender 为 null → 不显投降键', (tester) async {
    await _pumpBattle(tester);
    expect(find.byKey(const ValueKey('battle_surrender')), findsNothing);
  });

  testWidgets('投降键 → 确认框 → 撤退 → 触发 onSurrender', (tester) async {
    var surrendered = 0;
    await _pumpBattle(tester, onSurrender: () => surrendered++);

    expect(find.byKey(const ValueKey('battle_surrender')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('battle_surrender')));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.surrenderConfirmTitle), findsWidgets);
    expect(surrendered, 0, reason: '确认前不触发');

    await tester.tap(find.text(UiStrings.surrenderConfirmAction));
    await tester.pumpAndSettle();
    expect(surrendered, 1);
  });

  testWidgets('投降确认点「再打打」→ 不投降', (tester) async {
    var surrendered = 0;
    await _pumpBattle(tester, onSurrender: () => surrendered++);

    await tester.tap(find.byKey(const ValueKey('battle_surrender')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(UiStrings.surrenderCancelAction));
    await tester.pumpAndSettle();
    expect(surrendered, 0);
  });
}
