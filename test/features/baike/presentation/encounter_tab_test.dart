import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wuxia_idle/features/encounter/domain/encounter_def.dart';
import 'package:wuxia_idle/features/baike/application/encounter_codex_provider.dart';
import 'package:wuxia_idle/features/baike/presentation/encounter_tab.dart';
import 'package:wuxia_idle/features/baike/presentation/encounter_detail_screen.dart';
import 'package:wuxia_idle/shared/strings.dart';

EncounterDef _def(String id) => EncounterDef(
      id: id, type: EncounterType.techniqueInsight,
      trigger: const EncounterTrigger(), baseProbability: 0.1, outcomeMapping: const {});

void main() {
  testWidgets('点亮+剪影混态渲染 + 进度', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final groups = [
      EncounterCodexGroup(kind: EncounterGroupKind.insight, triggeredCount: 1, entries: [
        EncounterCodexEntry(def: _def('a'), isTriggered: true, title: '听雨悟剑'),
        EncounterCodexEntry(def: _def('b'), isTriggered: false),
      ]),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [encounterCodexProvider.overrideWith((ref) async => groups)],
      child: const MaterialApp(home: Scaffold(body: EncounterTab())),
    ));
    await tester.pumpAndSettle();
    expect(find.text('听雨悟剑'), findsOneWidget);
    expect(find.text(UiStrings.encounterCodexLocked), findsWidgets); // 剪影 ???
    expect(find.text(UiStrings.encounterCodexProgress(1, 2)), findsOneWidget);
  });

  testWidgets('空态:groups 为空→空提示,不甩剪影墙', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [encounterCodexProvider.overrideWith((ref) async => <EncounterCodexGroup>[])],
      child: const MaterialApp(home: Scaffold(body: EncounterTab())),
    ));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.encounterCodexEmpty), findsOneWidget);
  });

  testWidgets('空态:有 def 但 0 触发→也走空态,不渲染剪影墙(§5.7)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final groups = [
      EncounterCodexGroup(kind: EncounterGroupKind.insight, triggeredCount: 0, entries: [
        EncounterCodexEntry(def: _def('a'), isTriggered: false),
        EncounterCodexEntry(def: _def('b'), isTriggered: false),
      ]),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [encounterCodexProvider.overrideWith((ref) async => groups)],
      child: const MaterialApp(home: Scaffold(body: EncounterTab())),
    ));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.encounterCodexEmpty), findsOneWidget);
    expect(find.text(UiStrings.encounterCodexLocked), findsNothing); // 不甩剪影墙
  });

  testWidgets('点点亮行 push 详情屏', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final groups = [
      EncounterCodexGroup(kind: EncounterGroupKind.insight, triggeredCount: 1, entries: [
        EncounterCodexEntry(def: _def('a'), isTriggered: true, title: '听雨悟剑'),
      ]),
    ];
    await tester.pumpWidget(ProviderScope(
      overrides: [encounterCodexProvider.overrideWith((ref) async => groups)],
      child: const MaterialApp(home: Scaffold(body: EncounterTab())),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('听雨悟剑'));
    await tester.pumpAndSettle();
    expect(find.byType(EncounterDetailScreen), findsOneWidget);
  });
}
