import 'dart:convert';
import 'dart:io';

// Use `dart run --verbosity=error tool/compare_phase0a_headless_baseline.dart`
// when parsing stdout: the SDK's default verbosity prints package build hooks
// before this entry point starts. This program itself emits exactly one JSON row.
const _scope = 'engineering_regression_candidate';
const _absentBaseline = Object();
const _limitation =
    'Explicit engineering comparison only; not a frozen M4 performance promise. '
    'Detailed run coverage is not certified by this comparator.';

/// Compares compatible captures. Throughput is derived from measured counters,
/// never from a claimed rate or the number of detailed diagnostic rows.
Map<String, Object?> comparePhase0aHeadlessBaselines({
  required Object? candidate,
  Object? baseline = _absentBaseline,
  required double maxRegressionPercent,
}) {
  try {
    _validateThreshold(maxRegressionPercent);
    final current = _readReport(candidate, 'candidate');
    final previous = identical(baseline, _absentBaseline)
        ? null
        : _readReport(baseline, 'baseline');
    final common = <String, Object?>{
      'schema_version': 1,
      'scope': _scope,
      'limitation': _limitation,
      'candidate_run_id': current.runId,
      'baseline_run_id': previous?.runId,
      'max_regression_percent': maxRegressionPercent,
    };
    if (previous == null) {
      return {
        ...common,
        'status': 'NOT_EVALUATED',
        'reason': 'No independent baseline was supplied.',
        'groups': <Object?>[],
      };
    }
    if (previous.runId == current.runId) {
      throw const FormatException('Baseline and candidate run_id must differ.');
    }
    if (!_deepEqual(previous.comparisonKey, current.comparisonKey)) {
      return {
        ...common,
        'status': 'INCOMPATIBLE',
        'reason': 'comparison_key differs.',
      };
    }
    final ids = current.groups.keys.toList()..sort();
    final previousIds = previous.groups.keys.toList()..sort();
    if (!_deepEqual(ids, previousIds)) {
      return {
        ...common,
        'status': 'INCOMPATIBLE',
        'reason': 'Group id sets differ.',
      };
    }
    for (final id in ids) {
      if (previous.groups[id]!.attempts != current.groups[id]!.attempts) {
        return {
          ...common,
          'status': 'INCOMPATIBLE',
          'reason': 'Group $id attempts differ.',
        };
      }
    }
    var regressed = false;
    var incomplete = false;
    final groups = <Map<String, Object?>>[];
    for (final id in ids) {
      final before = previous.groups[id]!;
      final after = current.groups[id]!;
      final ticks = _compareMetric(
        before.ticksPerSecond,
        after.ticksPerSecond,
        maxRegressionPercent,
      );
      final battles = _compareMetric(
        before.battlesPerSecond,
        after.battlesPerSecond,
        maxRegressionPercent,
        evaluable: before.completed > 0 && after.completed > 0,
      );
      final groupRegressed =
          ticks['status'] == 'REGRESSION' || battles['status'] == 'REGRESSION';
      final groupIncomplete = battles['status'] == 'NOT_EVALUATED';
      regressed |= groupRegressed;
      incomplete |= groupIncomplete;
      groups.add({
        'id': id,
        'status': groupRegressed
            ? 'REGRESSION'
            : groupIncomplete
            ? 'NOT_EVALUATED'
            : 'PASS',
        'simulated_ticks_per_second': ticks,
        'completed_battles_per_second': battles,
      });
    }
    return {
      ...common,
      'status': regressed
          ? 'REGRESSION'
          : incomplete
          ? 'NOT_EVALUATED'
          : 'PASS',
      'groups': groups,
    };
  } on FormatException catch (error) {
    return _invalid(error.message);
  }
}

Map<String, Object?> _compareMetric(
  double baseline,
  double candidate,
  double threshold, {
  bool evaluable = true,
}) {
  if (!evaluable) {
    return {
      'status': 'NOT_EVALUATED',
      'baseline': baseline,
      'candidate': candidate,
      'regression_percent': null,
      'reason': 'At least one capture completed zero battles.',
    };
  }
  final decline = (baseline - candidate) / baseline * 100;
  final regressed = decline > threshold;
  return {
    'status': regressed ? 'REGRESSION' : 'PASS',
    'baseline': baseline,
    'candidate': candidate,
    'regression_percent': decline,
  };
}

final class _Report {
  const _Report(this.runId, this.comparisonKey, this.groups);

  final String runId;
  final Map<String, Object?> comparisonKey;
  final Map<String, _Group> groups;
}

final class _Group {
  const _Group(
    this.attempts,
    this.completed,
    this.ticksPerSecond,
    this.battlesPerSecond,
  );

  final int attempts;
  final int completed;
  final double ticksPerSecond;
  final double battlesPerSecond;
}

_Report _readReport(Object? value, String label) {
  final report = _object(value, label);
  if (report['schema_version'] is! int || report['schema_version'] != 1) {
    throw FormatException('$label.schema_version must be integer 1.');
  }
  final runId = _identifier(report['run_id'], '$label.run_id');
  final key = _object(report['comparison_key'], '$label.comparison_key');
  if (key.isEmpty) {
    throw FormatException('$label.comparison_key must not be empty.');
  }
  _validateJson(key, '$label.comparison_key');
  final correctness = _object(report['correctness'], '$label.correctness');
  if (correctness['same_seed_equal'] != true) {
    throw FormatException('$label.correctness.same_seed_equal must be true.');
  }
  _integer(correctness['compared_pairs'], '$label.compared_pairs', minimum: 1);
  if (report['runs'] is! List) {
    throw FormatException('$label.runs must be an array.');
  }
  final rawGroups = report['groups'];
  if (rawGroups is! List || rawGroups.isEmpty) {
    throw FormatException('$label.groups must be a non-empty array.');
  }
  final groups = <String, _Group>{};
  for (var i = 0; i < rawGroups.length; i++) {
    final path = '$label.groups[$i]';
    final group = _object(rawGroups[i], path);
    final id = _identifier(group['id'], '$path.id');
    if (groups.containsKey(id)) {
      throw FormatException('$label contains duplicate group $id.');
    }
    final attempts = _integer(group['attempts'], '$path.attempts', minimum: 1);
    final completed = _integer(
      group['completed_battles'],
      '$path.completed_battles',
    );
    final timeouts = _integer(group['timeouts'], '$path.timeouts');
    if (completed > attempts || timeouts != attempts - completed) {
      throw FormatException(
        '$path completed_battles/timeouts contradict attempts.',
      );
    }
    final ticks = _integer(
      group['simulated_ticks'],
      '$path.simulated_ticks',
      minimum: 1,
    );
    final micros = _integer(
      group['simulation_microseconds'],
      '$path.simulation_microseconds',
      minimum: 1,
    );
    final ticksRate =
        ticks.toDouble() * Duration.microsecondsPerSecond / micros;
    final battlesRate =
        completed.toDouble() * Duration.microsecondsPerSecond / micros;
    _checkRate(
      group['simulated_ticks_per_second'],
      ticksRate,
      '$path.simulated_ticks_per_second',
      positive: true,
    );
    _checkRate(
      group['completed_battles_per_second'],
      battlesRate,
      '$path.completed_battles_per_second',
      positive: false,
    );
    groups[id] = _Group(attempts, completed, ticksRate, battlesRate);
  }
  return _Report(runId, key, groups);
}

Map<String, Object?> _object(Object? value, String path) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw FormatException('$path must be a JSON object.');
  }
  return value.cast<String, Object?>();
}

String _identifier(Object? value, String path) {
  if (value is! String || value.trim().isEmpty || value.trim() != value) {
    throw FormatException('$path must be a non-empty trimmed string.');
  }
  return value;
}

int _integer(Object? value, String path, {int minimum = 0}) {
  if (value is! int || value < minimum) {
    throw FormatException('$path must be an integer >= $minimum.');
  }
  return value;
}

void _checkRate(
  Object? value,
  double derived,
  String path, {
  required bool positive,
}) {
  if (value is! num ||
      !value.isFinite ||
      value < 0 ||
      (positive && value == 0)) {
    throw FormatException(
      '$path must be a finite ${positive ? 'positive' : 'non-negative'} number.',
    );
  }
  if ((value - derived).abs() > derived.abs() * 1e-9) {
    throw FormatException(
      '$path disagrees with counters and simulation_microseconds.',
    );
  }
}

void _validateJson(Object? value, String path) {
  if (value == null || value is String || value is bool) return;
  if (value is num && value.isFinite) return;
  if (value is List) {
    for (var i = 0; i < value.length; i++) {
      _validateJson(value[i], '$path[$i]');
    }
    return;
  }
  if (value is Map) {
    for (final entry in _object(value, path).entries) {
      _validateJson(entry.value, '$path.${entry.key}');
    }
    return;
  }
  throw FormatException('$path must contain only finite JSON values.');
}

bool _deepEqual(Object? left, Object? right) {
  if (left is Map && right is Map) {
    return left.length == right.length &&
        left.keys.every(
          (key) => right.containsKey(key) && _deepEqual(left[key], right[key]),
        );
  }
  if (left is List && right is List) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (!_deepEqual(left[i], right[i])) return false;
    }
    return true;
  }
  return left == right;
}

void _validateThreshold(double value) {
  if (!value.isFinite || value < 0 || value > 100) {
    throw const FormatException(
      'max-regression-percent must be finite and within [0, 100].',
    );
  }
}

Map<String, Object?> _invalid(String reason) => {
  'schema_version': 1,
  'scope': _scope,
  'limitation': _limitation,
  'status': 'INVALID',
  'reason': reason,
};

void main(List<String> args) {
  Map<String, Object?> result;
  try {
    final options = <String, String>{};
    const allowed = {'--baseline', '--candidate', '--max-regression-percent'};
    for (var i = 0; i < args.length; i += 2) {
      final option = args[i];
      if (!allowed.contains(option) ||
          options.containsKey(option) ||
          i + 1 >= args.length ||
          args[i + 1].startsWith('--')) {
        throw FormatException(
          'Unknown, duplicate or incomplete option: $option',
        );
      }
      options[option] = args[i + 1];
    }
    final candidatePath = options['--candidate'];
    final threshold = double.tryParse(
      options['--max-regression-percent'] ?? '',
    );
    if (candidatePath == null || candidatePath.isEmpty || threshold == null) {
      throw const FormatException(
        'Explicit --candidate and --max-regression-percent are required.',
      );
    }
    _validateThreshold(threshold);
    final baselinePath = options['--baseline'];
    result = comparePhase0aHeadlessBaselines(
      candidate: jsonDecode(File(candidatePath).readAsStringSync()),
      baseline: baselinePath == null
          ? _absentBaseline
          : jsonDecode(File(baselinePath).readAsStringSync()),
      maxRegressionPercent: threshold,
    );
  } on FormatException catch (error) {
    result = _invalid(error.message);
  } on FileSystemException catch (error) {
    result = _invalid(error.toString());
  }
  stdout.writeln(jsonEncode(result));
  exitCode = switch (result['status']) {
    'REGRESSION' => 1,
    'INVALID' || 'INCOMPATIBLE' => 2,
    _ => 0,
  };
}
