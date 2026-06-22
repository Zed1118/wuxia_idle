import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';
import 'package:wuxia_idle/features/baike/presentation/encounter_detail_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  testWidgets('详情屏显类型标 + opening(占位兜底不崩)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const def = EncounterDef(
      id: 'missing_event_xyz',
      type: EncounterType.techniqueInsight,
      trigger: EncounterTrigger(),
      baseProbability: 0.1,
      outcomeMapping: {},
    );
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: EncounterDetailScreen(def: def)),
    ));
    await tester.pumpAndSettle();
    // 类型标(武学领悟)可见
    expect(find.text(UiStrings.encounterCodexGroupInsight), findsWidgets);
    expect(find.byType(EncounterDetailScreen), findsOneWidget);
  });
}
