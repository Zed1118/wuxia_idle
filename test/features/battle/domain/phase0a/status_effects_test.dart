import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/status_effects.dart';

void main() {
  group('TimedStatusSpec validation', () {
    test('rejects illegal duration, interval and stack limit', () {
      expect(
        () => TimedStatusSpec(
          type: TimedStatusType.poison,
          sourceId: 'source',
          durationTicks: 0,
          tickIntervalTicks: 1,
          stackLimit: 1,
          damagePerTick: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => TimedStatusSpec(
          type: TimedStatusType.poison,
          sourceId: 'source',
          durationTicks: 2,
          tickIntervalTicks: 0,
          stackLimit: 1,
          damagePerTick: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => TimedStatusSpec(
          type: TimedStatusType.poison,
          sourceId: 'source',
          durationTicks: 2,
          tickIntervalTicks: 1,
          stackLimit: 0,
          damagePerTick: 1,
        ),
        throwsArgumentError,
      );
    });

    test('requires movement multiplier only for slow', () {
      expect(
        () => TimedStatusSpec(
          type: TimedStatusType.slow,
          sourceId: 'source',
          durationTicks: 2,
          tickIntervalTicks: 1,
          stackLimit: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => TimedStatusSpec(
          type: TimedStatusType.poison,
          sourceId: 'source',
          durationTicks: 2,
          tickIntervalTicks: 1,
          stackLimit: 1,
          movementMultiplier: 0.5,
          damagePerTick: 1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('TimedStatusLedger', () {
    test('same source refreshes rather than stacking by default', () {
      final ledger = TimedStatusLedger.empty
        ..apply(_poison(durationTicks: 4, sourceId: 'a'))
        ..advance(2);

      ledger.apply(_poison(durationTicks: 6, sourceId: 'a'));

      expect(ledger.active.single.stacks, 1);
      expect(ledger.active.single.remainingTicks, 6);
      expect(ledger.active.single.elapsedTicks, 0);
    });

    test('same source stacks only when explicit stack limit allows it', () {
      final ledger = TimedStatusLedger.empty;
      ledger.apply(_poison(durationTicks: 4, sourceId: 'a', stackLimit: 2));
      ledger.apply(_poison(durationTicks: 6, sourceId: 'a', stackLimit: 2));

      expect(ledger.active.single.stacks, 2);
      expect(ledger.active.single.remainingTicks, 6);
    });

    test('fixed ticks schedule damage and expire deterministically', () {
      final ledger = TimedStatusLedger.empty;
      ledger.apply(
        _poison(
          durationTicks: 5,
          tickIntervalTicks: 2,
          sourceId: 'b',
          damagePerTick: 7,
        ),
      );
      ledger.apply(
        _poison(
          durationTicks: 3,
          tickIntervalTicks: 1,
          sourceId: 'a',
          damagePerTick: 2,
        ),
      );

      final result = ledger.advance(3);

      expect(result.damages, [
        const StatusDamage(
          sourceId: 'a',
          type: TimedStatusType.poison,
          amount: 2,
        ),
        const StatusDamage(
          sourceId: 'a',
          type: TimedStatusType.poison,
          amount: 2,
        ),
        const StatusDamage(
          sourceId: 'a',
          type: TimedStatusType.poison,
          amount: 2,
        ),
        const StatusDamage(
          sourceId: 'b',
          type: TimedStatusType.poison,
          amount: 7,
        ),
      ]);
      expect(ledger.active, hasLength(1));
      expect(ledger.active.single.sourceId, 'b');
    });

    test('root blocks regular movement but permits attack and defense', () {
      final root = TimedStatusSpec(
        type: TimedStatusType.root,
        sourceId: 'trap',
        durationTicks: 3,
        tickIntervalTicks: 3,
        stackLimit: 1,
      );
      final ledger = TimedStatusLedger.empty..apply(root);

      expect(ledger.blocksRegularMovement, isTrue);
      expect(ledger.allowsAttack, isTrue);
      expect(ledger.allowsDefense, isTrue);
    });

    test(
      'slow exposes movement only and does not alter action permissions',
      () {
        final ledger = TimedStatusLedger.empty
          ..apply(
            TimedStatusSpec(
              type: TimedStatusType.slow,
              sourceId: 'mud',
              durationTicks: 3,
              tickIntervalTicks: 3,
              stackLimit: 1,
              movementMultiplier: 0.5,
            ),
          );

        expect(ledger.movementMultiplier, 0.5);
        expect(ledger.blocksRegularMovement, isFalse);
        expect(ledger.allowsAttack, isTrue);
        expect(ledger.allowsDefense, isTrue);
      },
    );
  });
}

TimedStatusSpec _poison({
  required int durationTicks,
  required String sourceId,
  int tickIntervalTicks = 1,
  int stackLimit = 1,
  int damagePerTick = 1,
}) => TimedStatusSpec(
  type: TimedStatusType.poison,
  sourceId: sourceId,
  durationTicks: durationTicks,
  tickIntervalTicks: tickIntervalTicks,
  stackLimit: stackLimit,
  damagePerTick: damagePerTick,
);
