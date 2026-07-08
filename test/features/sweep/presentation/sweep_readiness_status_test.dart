import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/sweep/application/sweep_readiness_providers.dart';
import 'package:wuxia_idle/features/sweep/domain/sweep_readiness.dart';
import 'package:wuxia_idle/features/sweep/presentation/sweep_readiness_status.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  testWidgets('renders compact sweep readiness status', (tester) async {
    final state = SweepReadinessState(
      points: 42,
      lastRecoveredAt: DateTime(2026),
      config: const SweepReadinessConfig(
        enabled: true,
        maxPoints: 60,
        recoverMinutesPerPoint: 60,
        mainlineStageCost: 1,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sweepReadinessStatusProvider.overrideWith((ref) async => state),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SweepReadinessPill(compact: true)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(UiStrings.sweepReadinessShort(42, 60)), findsOneWidget);
  });

  testWidgets('renders sweep readiness panel with progress copy', (
    tester,
  ) async {
    final state = SweepReadinessState(
      points: 60,
      lastRecoveredAt: DateTime(2026),
      config: const SweepReadinessConfig(
        enabled: true,
        maxPoints: 60,
        recoverMinutesPerPoint: 60,
        mainlineStageCost: 1,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sweepReadinessStatusProvider.overrideWith((ref) async => state),
        ],
        child: const MaterialApp(home: Scaffold(body: SweepReadinessPanel())),
      ),
    );
    await tester.pump();

    expect(find.text(UiStrings.sweepReadinessPanelTitle), findsOneWidget);
    expect(find.text(UiStrings.sweepReadinessShort(60, 60)), findsOneWidget);
    expect(find.textContaining(UiStrings.sweepReadinessFull), findsOneWidget);
  });
}
