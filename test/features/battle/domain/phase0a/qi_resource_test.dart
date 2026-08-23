import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/qi_resource.dart';

void main() {
  group('QiResourceLedger validation', () {
    test('rejects invalid bounds and negative amounts', () {
      expect(
        () => QiResourceLedger(capacity: -1, current: 0),
        throwsArgumentError,
      );
      expect(
        () => QiResourceLedger(capacity: 2, current: 3),
        throwsArgumentError,
      );
      final ledger = QiResourceLedger(capacity: 2, current: 2);
      expect(
        () => ledger.reserve(actionId: 'a', amount: -1),
        throwsArgumentError,
      );
      expect(
        () => ledger.gainAction(actionId: 'a', amount: -1),
        throwsArgumentError,
      );
    });

    test('rejects duplicate reservation IDs', () {
      final ledger = QiResourceLedger(capacity: 5, current: 5);
      ledger.reserve(actionId: 'action', amount: 2);
      expect(
        () => ledger.reserve(actionId: 'action', amount: 1),
        throwsStateError,
      );
    });
  });

  group('reservation lifecycle', () {
    test('reserve holds qi, commit spends only on first active tick', () {
      final ledger = QiResourceLedger(capacity: 10, current: 8);
      final reservation = ledger.reserve(actionId: 'slash', amount: 5);

      expect(ledger.current, 8);
      expect(ledger.available, 3);
      expect(reservation.amount, 5);

      expect(ledger.commit('slash'), QiReservationResult.committed);
      expect(ledger.current, 3);
      expect(ledger.available, 3);
      expect(ledger.commit('slash'), QiReservationResult.alreadyCommitted);
    });

    test('cancel before effect releases qi and requires failure cooldown', () {
      final ledger = QiResourceLedger(capacity: 10, current: 8);
      ledger.reserve(actionId: 'interrupted', amount: 5);

      final result = ledger.cancel('interrupted');

      expect(result, QiCancellationResult.releasedWithFailureCooldown);
      expect(ledger.current, 8);
      expect(ledger.available, 8);
      expect(
        ledger.cancel('interrupted'),
        QiCancellationResult.alreadyCancelled,
      );
    });

    test('cannot commit after cancellation or cancel after commit', () {
      final ledger = QiResourceLedger(capacity: 10, current: 8);
      ledger.reserve(actionId: 'cancelled', amount: 2);
      ledger.cancel('cancelled');
      expect(() => ledger.commit('cancelled'), throwsStateError);

      ledger.reserve(actionId: 'committed', amount: 2);
      ledger.commit('committed');
      expect(() => ledger.cancel('committed'), throwsStateError);
    });

    test('insufficient spendable qi rejects reservation without mutation', () {
      final ledger = QiResourceLedger(capacity: 10, current: 4);
      expect(
        () => ledger.reserve(actionId: 'too_expensive', amount: 5),
        throwsStateError,
      );
      expect(ledger.current, 4);
      expect(ledger.available, 4);
    });
  });

  group('gain and bounded kill refund', () {
    test('one action can gain only once, including multi-segment calls', () {
      final ledger = QiResourceLedger(capacity: 10, current: 2);

      final first = ledger.gainAction(actionId: 'multi_hit', amount: 3);
      final repeated = ledger.gainAction(actionId: 'multi_hit', amount: 3);

      expect(first.applied, 3);
      expect(first.overflow, 0);
      expect(repeated.isAlreadyApplied, isTrue);
      expect(ledger.current, 5);
    });

    test(
      'kill gains are capped by injected window budget and overflow is reported',
      () {
        final ledger = QiResourceLedger(capacity: 10, current: 2);

        final first = ledger.gainKill(
          actionId: 'kill_1',
          windowId: 'window',
          amount: 4,
          windowCap: 5,
        );
        final second = ledger.gainKill(
          actionId: 'kill_2',
          windowId: 'window',
          amount: 4,
          windowCap: 5,
        );

        expect(first.applied, 4);
        expect(first.overflow, 0);
        expect(second.applied, 1);
        expect(second.overflow, 3);
        expect(ledger.current, 7);
        expect(
          ledger
              .gainKill(
                actionId: 'kill_2',
                windowId: 'window',
                amount: 4,
                windowCap: 5,
              )
              .isAlreadyApplied,
          isTrue,
        );
      },
    );

    test('capacity overflow is reported and discarded', () {
      final ledger = QiResourceLedger(capacity: 5, current: 4);
      final result = ledger.gainAction(actionId: 'ordinary', amount: 3);

      expect(result.applied, 1);
      expect(result.overflow, 2);
      expect(ledger.current, 5);
    });
  });
}
