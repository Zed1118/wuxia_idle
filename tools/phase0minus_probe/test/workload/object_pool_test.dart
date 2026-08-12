import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/workload/object_pool.dart';

void main() {
  test(
    'acquire resets state and release returns object to stable baseline',
    () {
      final pool = ObjectPool(FakePoolObject.new);
      final first = pool.acquire();
      first
        ..position = 42
        ..hitPoints = 0
        ..collisionEnabled = false
        ..effects = 9;
      pool.release(first);
      expect(pool.invariantHolds, isTrue);
      expect(pool.activeCount, 0);
      expect(pool.availableCount, 1);

      final second = pool.acquire();
      expect(identical(first, second), isTrue);
      expect(second.position, 0);
      expect(second.hitPoints, 100);
      expect(second.collisionEnabled, isTrue);
      expect(second.effects, 0);
      expect(pool.counters.reusedTotal, 1);
    },
  );

  test('duplicate release is rejected', () {
    final pool = ObjectPool(FakePoolObject.new);
    final object = pool.acquire();
    pool.release(object);
    expect(() => pool.release(object), throwsStateError);
  });

  test('allocation after warmup is counted', () {
    final pool = ObjectPool(FakePoolObject.new)..warmupComplete = true;
    pool.acquire();
    expect(pool.counters.allocationAfterWarmup, 1);
  });

  test('prewarm establishes reusable peak before warmup', () {
    final pool = ObjectPool(FakePoolObject.new)..prewarm(8);
    pool.warmupComplete = true;
    final objects = List.generate(8, (_) => pool.acquire());
    expect(pool.counters.createdTotal, 8);
    expect(pool.counters.allocationAfterWarmup, 0);
    for (final object in objects) {
      pool.release(object);
    }
    expect(pool.invariantHolds, isTrue);
  });
}

final class FakePoolObject implements PoolResettable {
  int position = -1;
  int hitPoints = -1;
  bool collisionEnabled = false;
  int effects = -1;

  @override
  void resetForAcquire() {
    position = 0;
    hitPoints = 100;
    collisionEnabled = true;
    effects = 0;
  }

  @override
  void resetForRelease() {
    position = 0;
    hitPoints = 0;
    collisionEnabled = false;
    effects = 0;
  }
}
