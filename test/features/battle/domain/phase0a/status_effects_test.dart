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

    test('rejects non-finite slow movement multipliers', () {
      for (final multiplier in <double>[
        double.nan,
        double.infinity,
        double.negativeInfinity,
      ]) {
        expect(
          () => TimedStatusSpec(
            type: TimedStatusType.slow,
            sourceId: 'source',
            durationTicks: 2,
            tickIntervalTicks: 1,
            stackLimit: 1,
            movementMultiplier: multiplier,
          ),
          throwsArgumentError,
          reason: 'movementMultiplier=$multiplier must fail closed',
        );
      }
    });
  });

  group('TimedStatusLedger', () {
    test('immutable snapshot round-trips active fixed-tick state', () {
      final original = TimedStatusLedger.empty
        ..apply(
          _poison(
            durationTicks: 4,
            tickIntervalTicks: 2,
            sourceId: 'source_b',
            damagePerTick: 7,
          ),
        )
        ..apply(
          _poison(durationTicks: 3, sourceId: 'source_a', damagePerTick: 2),
        )
        ..advance(1);

      final snapshot = original.snapshot;
      final restored = TimedStatusLedger.fromSnapshot(snapshot);

      expect(restored.snapshot, snapshot);
      expect(restored.advance(2).damages, original.advance(2).damages);
      expect(restored.snapshot, original.snapshot);
    });

    test('same source refreshes rather than stacking by default', () {
      final ledger = TimedStatusLedger.empty
        ..apply(_poison(durationTicks: 4, sourceId: 'a'))
        ..advance(2);

      ledger.apply(_poison(durationTicks: 6, sourceId: 'a'));

      expect(ledger.active.single.stacks, 1);
      expect(ledger.active.single.remainingTicks, 6);
      expect(ledger.active.single.elapsedTicks, 0);
    });

    test('same source refresh adopts the complete new spec', () {
      final ledger = TimedStatusLedger.empty
        ..apply(
          _poison(
            durationTicks: 4,
            tickIntervalTicks: 2,
            sourceId: 'a',
            damagePerTick: 3,
          ),
        )
        ..advance(1);

      ledger.apply(
        _poison(
          durationTicks: 6,
          tickIntervalTicks: 1,
          sourceId: 'a',
          damagePerTick: 9,
        ),
      );

      expect(ledger.advance(1).damages, [
        const StatusDamage(
          tick: 2,
          sourceId: 'a',
          type: TimedStatusType.poison,
          amount: 9,
        ),
      ]);
      expect(ledger.active.single.remainingTicks, 5);
      expect(ledger.active.single.spec.damagePerTick, 9);
      expect(ledger.active.single.spec.tickIntervalTicks, 1);
    });

    test('same source stacks only when explicit stack limit allows it', () {
      final ledger = TimedStatusLedger.empty;
      ledger.apply(_poison(durationTicks: 4, sourceId: 'a', stackLimit: 2));
      ledger.apply(_poison(durationTicks: 6, sourceId: 'a', stackLimit: 2));

      expect(ledger.active.single.stacks, 2);
      expect(ledger.active.single.remainingTicks, 6);
    });

    test('refresh uses the new stack cap and movement multiplier', () {
      final ledger = TimedStatusLedger.empty
        ..apply(
          TimedStatusSpec(
            type: TimedStatusType.slow,
            sourceId: 'mud',
            durationTicks: 4,
            tickIntervalTicks: 4,
            stackLimit: 3,
            movementMultiplier: 0.5,
          ),
        )
        ..apply(
          TimedStatusSpec(
            type: TimedStatusType.slow,
            sourceId: 'mud',
            durationTicks: 5,
            tickIntervalTicks: 5,
            stackLimit: 2,
            movementMultiplier: 0.8,
          ),
        )
        ..apply(
          TimedStatusSpec(
            type: TimedStatusType.slow,
            sourceId: 'mud',
            durationTicks: 6,
            tickIntervalTicks: 6,
            stackLimit: 2,
            movementMultiplier: 0.7,
          ),
        );

      expect(ledger.active.single.stacks, 2);
      expect(ledger.active.single.spec.stackLimit, 2);
      expect(ledger.movementMultiplier, closeTo(0.49, 0.000001));
    });

    test('active snapshots cannot mutate ledger internals', () {
      final ledger = TimedStatusLedger.empty
        ..apply(_poison(durationTicks: 4, sourceId: 'a'));
      final snapshot = ledger.active.single;

      snapshot.remainingTicks = 0;
      expect(ledger.active.single.remainingTicks, 4);
    });

    test(
      'expiration tick damage is emitted before the instance is removed',
      () {
        final ledger = TimedStatusLedger.empty
          ..apply(_poison(durationTicks: 1, sourceId: 'a', damagePerTick: 7));

        expect(ledger.advance(1).damages.single.amount, 7);
        expect(ledger.active, isEmpty);
      },
    );

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
          tick: 1,
          sourceId: 'a',
          type: TimedStatusType.poison,
          amount: 2,
        ),
        const StatusDamage(
          tick: 2,
          sourceId: 'a',
          type: TimedStatusType.poison,
          amount: 2,
        ),
        const StatusDamage(
          tick: 2,
          sourceId: 'b',
          type: TimedStatusType.poison,
          amount: 7,
        ),
        const StatusDamage(
          tick: 3,
          sourceId: 'a',
          type: TimedStatusType.poison,
          amount: 2,
        ),
      ]);
      expect(ledger.active, hasLength(1));
      expect(ledger.active.single.sourceId, 'b');
    });

    test(
      'batched and one-tick advances emit the same ordered damage events',
      () {
        TimedStatusLedger buildLedger() => TimedStatusLedger.empty
          ..apply(
            _poison(
              durationTicks: 3,
              tickIntervalTicks: 1,
              sourceId: 'a',
              damagePerTick: 2,
            ),
          )
          ..apply(
            _poison(
              durationTicks: 3,
              tickIntervalTicks: 2,
              sourceId: 'b',
              damagePerTick: 7,
            ),
          );

        final batched = buildLedger().advance(3).damages;
        final steppedLedger = buildLedger();
        final stepped = <StatusDamage>[
          ...steppedLedger.advance(1).damages,
          ...steppedLedger.advance(1).damages,
          ...steppedLedger.advance(1).damages,
        ];

        expect(stepped, batched);
      },
    );

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
