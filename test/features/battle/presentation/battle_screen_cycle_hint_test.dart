import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/application/battle_providers.dart';
import 'package:wuxia_idle/features/battle/domain/battle_state.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_demo.dart';
import 'package:wuxia_idle/features/battle/presentation/battle_screen.dart';
import 'package:wuxia_idle/data/numbers_config.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// P1 周目进化 E2：BattleScreen.cycleHint 渲染测试。
///
/// 验 cycleHint 注入时「江湖记招」提示条渲染，null 时不渲染。
/// 继承 battle_screen_defer_victory_test 体例（TestNotifier + autoStart:false）。
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
}

Future<void> _pump(
  WidgetTester tester, {
  String? cycleHint,
}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 720));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final (left, right) = BattleDemo.mockTeams();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        battleProvider.overrideWith(() => _TestBattleNotifier(
              BattleState.initial(leftTeam: left, rightTeam: right),
            )),
      ],
      child: MaterialApp(
        home: BattleScreen(
          animConfig: _testAnim,
          autoStart: false,
          cycleHint: cycleHint,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('cycleHint 非空 → 渲染江湖记招提示文案', (tester) async {
    await _pump(tester, cycleHint: UiStrings.jianghuRememberHint);
    expect(
      find.text(UiStrings.jianghuRememberHint),
      findsOneWidget,
      reason: 'cycleHint 非空时应显示「江湖记招」提示条',
    );
  });

  testWidgets('cycleHint=null → 不渲染江湖记招提示条', (tester) async {
    await _pump(tester, cycleHint: null);
    expect(
      find.text(UiStrings.jianghuRememberHint),
      findsNothing,
      reason: 'cycleHint=null 时不应渲染提示条',
    );
  });

  testWidgets('battleCycleHint(2) → 横幅含明确「第 2 周目」标签', (tester) async {
    await _pump(tester, cycleHint: UiStrings.battleCycleHint(2));
    expect(
      find.textContaining('第 2 周目'),
      findsOneWidget,
      reason: '战前横幅须明确标注第几周目,让玩家知道在打第2周目',
    );
  });
}
