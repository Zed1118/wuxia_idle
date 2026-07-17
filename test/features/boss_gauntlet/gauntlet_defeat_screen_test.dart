import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/boss_gauntlet/application/gauntlet_service.dart';
import 'package:wuxia_idle/features/boss_gauntlet/presentation/gauntlet_defeat_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

/// #1 wiring Task 3 断魂庄战败结算屏（spec §3.3）：展示已击败精英经验 + 轻重伤摘要，
/// 「离庄」→ pop 回主菜单。settleDefeat 已由 flow 先调（删会话），本屏只读传入摘要 DTO，
/// 不依赖 provider。1280×720 与 1440×900 一屏无溢出。
const _summary = GauntletDefeatSummary(
  elitesDefeated: 1,
  eliteExpPerMember: 50,
  members: [
    GauntletDefeatMember(name: '沈青', downed: true),
    GauntletDefeatMember(name: '楚河', downed: false),
  ],
);

const _summaryNoElite = GauntletDefeatSummary(
  elitesDefeated: 0,
  eliteExpPerMember: 0,
  members: [GauntletDefeatMember(name: '沈青', downed: true)],
);

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  GauntletDefeatSummary summary = _summary,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: GauntletDefeatScreen(summary: summary)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('战败屏：精英经验 + 轻重伤摘要 + 离庄，1280×720 无溢出', (tester) async {
    await _pump(tester, const Size(1280, 720));

    expect(find.text(UiStrings.gauntletDefeatSection), findsOneWidget);
    // 已破 1 关精英，各得经验 50。
    expect(find.text(UiStrings.gauntletDefeatEliteLine(1, 50)), findsOneWidget);
    // 成员名 + 伤势标（沈青 重伤 / 楚河 轻伤）。
    expect(find.text('沈青'), findsOneWidget);
    expect(find.text('楚河'), findsOneWidget);
    expect(find.text(UiStrings.gauntletDefeatHeavyTag), findsOneWidget);
    expect(find.text(UiStrings.gauntletDefeatLightTag), findsOneWidget);
    // 离庄按钮。
    expect(find.text(UiStrings.gauntletLeaveButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('战败屏：1440×900 无溢出，离庄可见', (tester) async {
    await _pump(tester, const Size(1440, 900));
    expect(find.text(UiStrings.gauntletLeaveButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('战败屏：未破精英（0）→ 无经验行，显未破精英', (tester) async {
    await _pump(tester, const Size(1280, 720), summary: _summaryNoElite);
    expect(find.text(UiStrings.gauntletDefeatNoElite), findsOneWidget);
    expect(find.text(UiStrings.gauntletDefeatEliteLine(0, 0)), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('战败屏：点离庄 → pop 回上层', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        const GauntletDefeatScreen(summary: _summary),
                  ),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.gauntletDefeatSection), findsOneWidget);

    await tester.tap(find.text(UiStrings.gauntletLeaveButton));
    await tester.pumpAndSettle();
    // 离庄后战败屏出栈。
    expect(find.text(UiStrings.gauntletDefeatSection), findsNothing);
    expect(find.text('go'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
