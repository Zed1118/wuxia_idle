import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/shared/battle_shared/enum_localizations.dart';
import 'package:wuxia_idle/shared/widgets/wuxia_ui/rarity_tier_badge.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        home: Scaffold(
          body: Center(child: child),
        ),
      );

  testWidgets('六档保留档名、出生点数与非按钮 semantics', (tester) async {
    await tester.pumpWidget(
      host(
        Wrap(
          children: [
            for (final tier in RarityTier.values)
              RarityTierBadge(tier: tier, birthTotal: 20),
          ],
        ),
      ),
    );

    for (final tier in RarityTier.values) {
      final name = EnumL10n.rarityTier(tier);
      expect(find.text('资质 $name（20）'), findsOneWidget);
    }
    final semantics = tester.getSemantics(find.byType(RarityTierBadge).first);
    expect(semantics.label, contains('资质'));
    expect(semantics.label, contains('20'));
    expect(semantics.flagsCollection, isNot(contains(SemanticsFlag.isButton)));
  });

  testWidgets('紧凑模式与长档名在窄卡不溢出', (tester) async {
    await tester.binding.setSurfaceSize(const Size(180, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 150,
          child: RarityTierBadge(
            tier: RarityTier.jueShi,
            birthTotal: 24,
            compact: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('绝世'), findsOneWidget);
  });
}
