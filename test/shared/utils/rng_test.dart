import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/utils/rng.dart';
import 'package:wuxia_idle/shared/utils/rng_provider.dart';

void main() {
  group('DefaultRng', () {
    test('same seed produces the same int/double/pick sequence', () {
      final a = DefaultRng(seed: 42);
      final b = DefaultRng(seed: 42);

      final intsA = [for (var i = 0; i < 8; i++) a.nextInt(1000)];
      final intsB = [for (var i = 0; i < 8; i++) b.nextInt(1000)];
      expect(intsA, intsB);

      final doublesA = [for (var i = 0; i < 8; i++) a.nextDouble()];
      final doublesB = [for (var i = 0; i < 8; i++) b.nextDouble()];
      expect(doublesA, doublesB);

      const list = ['松', '竹', '梅', '兰'];
      final picksA = [for (var i = 0; i < 8; i++) a.pick(list)];
      final picksB = [for (var i = 0; i < 8; i++) b.pick(list)];
      expect(picksA, picksB);
    });

    test('nextInt and nextDouble stay within Random-compatible bounds', () {
      final rng = DefaultRng(seed: 7);

      expect(rng.nextInt(1), 0);
      expect(() => rng.nextInt(0), throwsRangeError);

      for (var i = 0; i < 100; i++) {
        final value = rng.nextDouble();
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThan(1));
      }
    });

    test('pick returns a list element and rejects empty lists', () {
      final rng = DefaultRng(seed: 8);
      const list = [10, 20, 30];

      expect(list, contains(rng.pick(list)));
      expect(() => rng.pick(<int>[]), throwsArgumentError);
    });
  });

  group('rngProvider', () {
    test('can be overridden with a deterministic Rng', () {
      final container = ProviderContainer(
        overrides: [rngProvider.overrideWithValue(const _FixedRng())],
      );
      addTearDown(container.dispose);

      final rng = container.read(rngProvider);

      expect(rng.nextInt(10), 3);
      expect(rng.nextDouble(), 0.25);
      expect(rng.pick(['a', 'b']), 'b');
    });
  });
}

class _FixedRng implements Rng {
  const _FixedRng();

  @override
  int nextInt(int max) => 3;

  @override
  double nextDouble() => 0.25;

  @override
  T pick<T>(List<T> list) => list.last;
}
