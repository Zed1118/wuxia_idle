import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/progressive_unlock/application/progressive_unlock_service.dart';
import 'package:wuxia_idle/features/progressive_unlock/domain/progressive_unlock.dart';
import 'package:wuxia_idle/features/progressive_unlock/presentation/progressive_unlock_seal.dart';
import 'package:wuxia_idle/shared/strings.dart';

class _FakePort implements ProgressiveUnlockReceiptPort {
  _FakePort({this.pending = const []});

  final List<PendingProgressiveUnlock> pending;
  final acknowledged = <ProgressiveUnlockId>[];
  DateTime? acknowledgedAt;

  @override
  Future<List<PendingProgressiveUnlock>> observe({
    required int saveDataId,
    required ProgressiveUnlockSnapshot snapshot,
    required DateTime now,
  }) async => pending;

  @override
  Future<void> acknowledge({
    required int saveDataId,
    required Iterable<ProgressiveUnlockId> unlockIds,
    required DateTime now,
  }) async {
    acknowledged.addAll(unlockIds);
    acknowledgedAt = now;
  }
}

void main() {
  testWidgets(
    'one wax-seal dialog groups all newly open routes and acks on CTA',
    (tester) async {
      final observedAt = DateTime(2026, 9, 1);
      final port = _FakePort(
        pending: [
          PendingProgressiveUnlock(
            unlockId: ProgressiveUnlockId.lightFoot,
            openedAt: observedAt,
          ),
          PendingProgressiveUnlock(
            unlockId: ProgressiveUnlockId.massBattle,
            openedAt: observedAt,
          ),
        ],
      );
      final snapshot = ProgressiveUnlockSnapshot({
        for (final id in ProgressiveUnlockId.values)
          id: ProgressiveUnlockState.open,
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => maybeShowProgressiveUnlockSeal(
                  context: context,
                  saveDataId: 1,
                  snapshot: snapshot,
                  receiptPort: port,
                  now: observedAt,
                ),
                child: const Text('open-test-seal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open-test-seal'));
      await tester.pumpAndSettle();
      expect(find.text(UiStrings.jianghuMapKnownLocations), findsOneWidget);
      expect(find.text(UiStrings.mainMenuLightFoot), findsOneWidget);
      expect(find.text(UiStrings.mainMenuMassBattle), findsOneWidget);
      expect(port.acknowledged, isEmpty, reason: '弹窗出现不等于玩家已确认');

      await tester.tap(find.text(UiStrings.itemUseDismiss));
      await tester.pumpAndSettle();
      expect(port.acknowledged, [
        ProgressiveUnlockId.lightFoot,
        ProgressiveUnlockId.massBattle,
      ]);
      expect(port.acknowledgedAt, observedAt);
      expect(find.text(UiStrings.jianghuMapKnownLocations), findsNothing);
    },
  );

  testWidgets('no pending route does not render or acknowledge a seal', (
    tester,
  ) async {
    final port = _FakePort();
    final snapshot = ProgressiveUnlockSnapshot({
      for (final id in ProgressiveUnlockId.values)
        id: ProgressiveUnlockState.open,
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => maybeShowProgressiveUnlockSeal(
                context: context,
                saveDataId: 1,
                snapshot: snapshot,
                receiptPort: port,
                now: DateTime(2026, 9, 1),
              ),
              child: const Text('observe-empty-seal'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('observe-empty-seal'));
    await tester.pumpAndSettle();
    expect(find.text(UiStrings.jianghuMapKnownLocations), findsNothing);
    expect(port.acknowledged, isEmpty);
  });
}
