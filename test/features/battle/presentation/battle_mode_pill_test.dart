import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/presentation/widgets/battle_header.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  testWidgets('纯自动模式说明托管轮转职责', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BattleModePill(allowPlayerIntervention: false)),
      ),
    );

    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, UiStrings.battleAutoModeHint);
    expect(find.text(UiStrings.battleAutoMode), findsOneWidget);
    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('battle_auto_mode')),
    );
    expect(semantics.label, UiStrings.battleAutoMode);
    expect(semantics.value, UiStrings.battleAutoMode);
    expect(semantics.hint, UiStrings.battleAutoModeHint);
  });

  testWidgets('可点选模式说明预支行动与重新回势代价', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: BattleModePill(allowPlayerIntervention: true)),
      ),
    );

    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, UiStrings.battleAutoInterventionHint);
    expect(
      find.text(
        '${UiStrings.battleAutoMode}·${UiStrings.battleAutoIntervention}',
      ),
      findsOneWidget,
    );
    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('battle_auto_mode')),
    );
    expect(semantics.label, UiStrings.battleAutoMode);
    expect(semantics.value, UiStrings.battleAutoIntervention);
    expect(semantics.hint, UiStrings.battleAutoInterventionHint);
  });
}
