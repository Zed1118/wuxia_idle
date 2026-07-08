import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/currency_pill.dart';

void main() {
  testWidgets('CurrencyAmountPill renders silver amount with custom icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CurrencyAmountPill(amount: 360))),
    );

    expect(find.text(UiStrings.silverBalanceLabel(360)), findsOneWidget);
    expect(find.byType(CurrencyIcon), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('CurrencyAmountPill supports compact dark tone', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: CurrencyAmountPill(
            amount: 12,
            tone: CurrencyPillTone.dark,
            compact: true,
          ),
        ),
      ),
    );

    expect(find.text(UiStrings.silverBalanceLabel(12)), findsOneWidget);
    expect(find.text(UiStrings.currencySilverUnit), findsNothing);
  });
}
