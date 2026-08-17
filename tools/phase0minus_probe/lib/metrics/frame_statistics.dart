import 'dart:math' as math;

int nearestRank(List<int> values, double percentile) {
  if (values.isEmpty) throw ArgumentError.value(values, 'values', 'is empty');
  if (percentile <= 0 || percentile > 1) {
    throw ArgumentError.value(percentile, 'percentile', 'must be in (0, 1]');
  }
  final sorted = List<int>.of(values)..sort();
  final rank = math.max(1, (percentile * sorted.length).ceil());
  return sorted[rank - 1];
}

int maximumConsecutiveAbove(List<int> values, int strictThreshold) {
  var current = 0;
  var maximum = 0;
  for (final value in values) {
    if (value > strictThreshold) {
      current++;
      maximum = math.max(maximum, current);
    } else {
      current = 0;
    }
  }
  return maximum;
}

final class DurationSummary {
  const DurationSummary({
    required this.p50,
    required this.p95,
    required this.p99,
    required this.maximum,
  });

  factory DurationSummary.from(List<int> values) => DurationSummary(
    p50: nearestRank(values, 0.50),
    p95: nearestRank(values, 0.95),
    p99: nearestRank(values, 0.99),
    maximum: values.reduce(math.max),
  );

  final int p50;
  final int p95;
  final int p99;
  final int maximum;

  Map<String, int> toJson() => {
    'p50_us': p50,
    'p95_us': p95,
    'p99_us': p99,
    'max_us': maximum,
  };
}
