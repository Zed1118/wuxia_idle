import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_demo.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';

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

/// no-op advance：避免 Timer 触发时读 GameRepository 崩溃。
class _TestBattleNotifier extends BattleNotifier {
  final BattleState _initial;
  _TestBattleNotifier(this._initial);

  @override
  BattleState build() => _initial;

  @override
  void advance({int maxConsecutiveTicks = 100}) {}
}

Future<void> _pumpBattle(WidgetTester tester) async {
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
      child: const MaterialApp(home: BattleScreen(animConfig: _testAnim)),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('日志默认收起，点开显历史，再点收起（P0-2 Task6）', (tester) async {
    await _pumpBattle(tester);

    // 默认：日志抽屉关
    expect(find.byKey(const ValueKey('battle_log_drawer')), findsNothing);

    // 点顶栏日志按钮 → 抽屉开
    await tester.tap(find.byKey(const ValueKey('battle_log_toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('battle_log_drawer')), findsOneWidget);

    // 再点 → 收起
    await tester.tap(find.byKey(const ValueKey('battle_log_toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('battle_log_drawer')), findsNothing);
  });
}
