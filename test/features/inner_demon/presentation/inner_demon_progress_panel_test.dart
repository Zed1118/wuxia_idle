import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_panel.dart';
import 'package:wuxia_idle/features/inner_demon/presentation/breakthrough_blocker.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/plaque_button.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(const Size(1280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    await tester.pump();
  }

  testWidgets('blocked 态:显「突破被拦」+ 进度 + 强 CTA', (tester) async {
    var tapped = false;
    await pump(
      tester,
      InnerDemonProgressPanel(
        state: InnerDemonPanelState.blocked,
        clearedCount: 2,
        totalCount: 7,
        blockingStageName: '心魔·痴',
        onNavigate: () => tapped = true,
      ),
    );
    expect(find.text(UiStrings.innerDemonPanelTitle), findsOneWidget);
    expect(find.text(UiStrings.innerDemonPanelProgress(2, 7)), findsOneWidget);
    expect(find.text(UiStrings.innerDemonBlockedBody('心魔·痴')), findsOneWidget);
    final cta = find.widgetWithText(
      PlaqueButton,
      UiStrings.innerDemonBreakthroughCta,
    );
    expect(cta, findsOneWidget);
    final button = tester.widget<PlaqueButton>(cta);
    expect(button.destructive, isTrue);
    expect(button.primary, isFalse);
    await tester.tap(find.text(UiStrings.innerDemonBreakthroughCta));
    expect(tapped, isTrue);
  });

  testWidgets('inProgress 态:显进度 + 下一关 + 弱 CTA', (tester) async {
    var tapped = false;
    await pump(
      tester,
      InnerDemonProgressPanel(
        state: InnerDemonPanelState.inProgress,
        clearedCount: 1,
        totalCount: 7,
        nextStageName: '心魔·嗔',
        onNavigate: () => tapped = true,
      ),
    );
    expect(find.text(UiStrings.innerDemonNextLabel('心魔·嗔')), findsOneWidget);
    final cta = find.widgetWithText(
      PlaqueButton,
      UiStrings.breakthroughGoToInnerDemon,
    );
    expect(cta, findsOneWidget);
    final button = tester.widget<PlaqueButton>(cta);
    expect(button.destructive, isFalse);
    expect(button.primary, isFalse);
    await tester.tap(find.text(UiStrings.breakthroughGoToInnerDemon));
    expect(tapped, isTrue);
  });

  testWidgets('cleared 态:显「心魔已尽」无 CTA', (tester) async {
    await pump(
      tester,
      const InnerDemonProgressPanel(
        state: InnerDemonPanelState.cleared,
        clearedCount: 7,
        totalCount: 7,
      ),
    );
    expect(find.text(UiStrings.innerDemonClearedLabel), findsOneWidget);
    expect(find.text(UiStrings.innerDemonBreakthroughCta), findsNothing);
    expect(find.text(UiStrings.breakthroughGoToInnerDemon), findsNothing);
  });
}
