import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/metrics/frame_statistics.dart';

void main() {
  test('nearest-rank uses ceil rank without interpolation', () {
    final values = List<int>.generate(
      100,
      (index) => index + 1,
    ).reversed.toList();
    expect(nearestRank(values, 0.50), 50);
    expect(nearestRank(values, 0.95), 95);
    expect(nearestRank(values, 0.99), 99);
    expect(nearestRank(values, 1), 100);
  });

  test('p99 at 16.6ms preserves strict gate boundary', () {
    final values = List<int>.filled(99, 10000, growable: true)..add(16600);
    expect(nearestRank(values, 0.99), 10000);
    values[98] = 16600;
    expect(nearestRank(values, 0.99), 16600);
    expect(nearestRank(values, 0.99) < 16600, isFalse);
  });

  test('severe streak uses original order and strict greater-than', () {
    expect(maximumConsecutiveAbove([33301, 33302, 10000, 50000], 33300), 2);
    expect(maximumConsecutiveAbove([33300, 33300], 33300), 0);
  });
}
