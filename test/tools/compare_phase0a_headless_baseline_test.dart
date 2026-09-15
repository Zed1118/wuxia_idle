import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/compare_phase0a_headless_baseline.dart' as comparator;

Map<String, Object?> _group({
  String id = 'typed_mainline/sync',
  int attempts = 10,
  int completed = 8,
  int ticks = 1000,
  int microseconds = 1000000,
}) => {
  'id': id,
  'attempts': attempts,
  'completed_battles': completed,
  'timeouts': attempts - completed,
  'simulated_ticks': ticks,
  'simulation_microseconds': microseconds,
  'simulated_ticks_per_second': ticks * 1000000 / microseconds,
  'completed_battles_per_second': completed * 1000000 / microseconds,
};

Map<String, Object?> _report({String id = 'candidate'}) => {
  'schema_version': 1,
  'run_id': id,
  'comparison_key': {
    'machine': {'cpu': 'test-cpu', 'os': 'test-os'},
    'runtime': {'flutter': 'test-version', 'mode': 'test'},
    'fingerprints': ['data', 'fixture'],
    'configuration': {
      'cycles': [1, 2],
    },
  },
  'correctness': {'same_seed_equal': true, 'compared_pairs': 1},
  'groups': [_group()],
  'runs': <Object?>[],
};

Future<({int exitCode, Map<String, Object?> json})> _run({
  Object? baseline,
  Object? candidate,
  List<String> thresholdArgs = const ['--max-regression-percent', '10'],
  List<String> extraArgs = const [],
  String? rawCandidate,
  String? rawBaseline,
  bool usePubRunner = false,
}) async {
  final directory = await Directory.systemTemp.createTemp('headless_compare_');
  try {
    final candidateFile = File('${directory.path}/candidate.json');
    await candidateFile.writeAsString(
      rawCandidate ?? jsonEncode(candidate ?? _report()),
    );
    final args = ['--candidate', candidateFile.path];
    if (baseline != null || rawBaseline != null) {
      final baselineFile = File('${directory.path}/baseline.json');
      await baselineFile.writeAsString(rawBaseline ?? jsonEncode(baseline));
      args.addAll(['--baseline', baselineFile.path]);
    }
    final process = await Process.run('dart', [
      // This CLI imports only dart: libraries. Direct execution retains its
      // argument parsing, JSON output and exit codes without repeating package
      // build hooks for every invalid-input case. Keep the documented launch
      // path covered explicitly below.
      if (usePubRunner) ...['run', '--verbosity=error'],
      'tool/compare_phase0a_headless_baseline.dart',
      ...args,
      ...thresholdArgs,
      ...extraArgs,
    ]);
    expect(
      process.stdout.toString().trim(),
      isNotEmpty,
      reason: 'CLI must emit JSON; stderr=${process.stderr}',
    );
    return (
      exitCode: process.exitCode,
      json: (jsonDecode(process.stdout as String) as Map)
          .cast<String, Object?>(),
    );
  } finally {
    await directory.delete(recursive: true);
  }
}

void main() {
  test('first capture is NOT_EVALUATED and never self-compared', () async {
    final result = await _run();
    expect(result.exitCode, 0);
    expect(result.json['status'], 'NOT_EVALUATED');
    final documented = await _run(usePubRunner: true);
    expect(documented.exitCode, result.exitCode);
    expect(documented.json, result.json);
  });

  test(
    'equal nested keys ignore map/group order but preserve values',
    () async {
      final baseline = _report(id: 'baseline');
      baseline['groups'] = [_group(), _group(id: 'legacy_tower/async')];
      final candidate = _report();
      candidate['comparison_key'] = {
        'configuration': {
          'cycles': [1, 2],
        },
        'fingerprints': ['data', 'fixture'],
        'runtime': {'mode': 'test', 'flutter': 'test-version'},
        'machine': {'os': 'test-os', 'cpu': 'test-cpu'},
      };
      candidate['groups'] = [_group(id: 'legacy_tower/async'), _group()];
      final result = await _run(baseline: baseline, candidate: candidate);
      expect(result.exitCode, 0);
      expect(result.json['status'], 'PASS');
      expect(result.json['scope'], 'engineering_regression_candidate');
    },
  );

  test('explicit boundary passes; exceeding it regresses per metric', () async {
    for (final ticks in [800, 799]) {
      final candidate = _report()..['groups'] = [_group(ticks: ticks)];
      final result = await _run(
        baseline: _report(id: 'baseline'),
        candidate: candidate,
        thresholdArgs: ['--max-regression-percent', '20'],
      );
      expect(result.exitCode, ticks == 800 ? 0 : 1);
      expect(result.json['status'], ticks == 800 ? 'PASS' : 'REGRESSION');
    }
    final candidate = _report()..['groups'] = [_group(completed: 7)];
    final result = await _run(
      baseline: _report(id: 'baseline'),
      candidate: candidate,
    );
    expect(result.exitCode, 1);
    expect(result.json['status'], 'REGRESSION');
  });

  test(
    'zero completed battles never turns an unevaluable metric green',
    () async {
      for (final zeroSide in ['baseline', 'candidate', 'both']) {
        final baseline = _report(id: 'baseline');
        final candidate = _report();
        if (zeroSide != 'candidate') {
          baseline['groups'] = [_group(completed: 0)];
        }
        if (zeroSide != 'baseline') {
          candidate['groups'] = [_group(completed: 0)];
        }
        final result = await _run(baseline: baseline, candidate: candidate);
        expect(result.exitCode, 0, reason: zeroSide);
        expect(result.json['status'], 'NOT_EVALUATED', reason: zeroSide);
      }
      final candidate = _report()
        ..['groups'] = [_group(completed: 0, ticks: 500)];
      final result = await _run(
        baseline: _report(id: 'baseline'),
        candidate: candidate,
      );
      expect(result.exitCode, 1);
      expect(result.json['status'], 'REGRESSION');
    },
  );

  test('same run, mismatched key, list order and groups fail closed', () async {
    final mutations = <void Function(Map<String, Object?>)>[
      (r) => r['run_id'] = 'baseline',
      (r) => r['comparison_key'] = {'machine': 'different'},
      (r) => (r['comparison_key'] as Map)['fingerprints'] = ['fixture', 'data'],
      (r) => r['groups'] = [_group(id: 'different/sync')],
      (r) => r['groups'] = [_group(), _group()],
    ];
    for (final mutate in mutations) {
      final candidate = _report();
      mutate(candidate);
      final result = await _run(
        baseline: _report(id: 'baseline'),
        candidate: candidate,
      );
      expect(result.exitCode, 2);
      expect(result.json['status'], anyOf('INVALID', 'INCOMPATIBLE'));
    }
  });

  test(
    'every required report field is validated even without a baseline',
    () async {
      for (final key in _report().keys) {
        final candidate = _report()..remove(key);
        final result = await _run(candidate: candidate);
        expect(result.exitCode, 2, reason: key);
        expect(result.json['status'], 'INVALID', reason: key);
      }
      for (final bad in [false, null, 'true']) {
        final candidate = _report()
          ..['correctness'] = {'same_seed_equal': bad, 'compared_pairs': 1};
        expect((await _run(candidate: candidate)).exitCode, 2);
      }
    },
  );

  test(
    'counters and redundant rates reject forged or invalid summaries',
    () async {
      final changes = <String, Object?>{
        'attempts': 0,
        'completed_battles': 11,
        'timeouts': 3,
        'simulated_ticks': -1,
        'simulation_microseconds': 0,
        'simulated_ticks_per_second': 1001,
        'completed_battles_per_second': 8.1,
      };
      for (final change in changes.entries) {
        final candidate = _report()
          ..['groups'] = [_group()..[change.key] = change.value];
        expect(
          (await _run(candidate: candidate)).exitCode,
          2,
          reason: change.key,
        );
      }
      final invalidBaseline = _report(id: 'baseline')
        ..['groups'] = [_group()..['simulated_ticks_per_second'] = 99999];
      expect((await _run(baseline: invalidBaseline)).exitCode, 2);
    },
  );

  test('threshold is explicit, finite and within 0 through 100', () async {
    for (final value in ['-1', '100.1', 'NaN', 'Infinity', '-Infinity', 'x']) {
      final result = await _run(
        thresholdArgs: ['--max-regression-percent', value],
      );
      expect(result.exitCode, 2, reason: value);
      expect(result.json['status'], 'INVALID');
    }
    expect((await _run(thresholdArgs: [])).exitCode, 2);
    for (final boundary in ['0', '100']) {
      expect(
        (await _run(
          baseline: _report(id: 'baseline'),
          thresholdArgs: ['--max-regression-percent', boundary],
        )).exitCode,
        0,
      );
    }
  });

  test(
    'malformed JSON, unknown and duplicate CLI options emit INVALID',
    () async {
      expect((await _run(rawCandidate: '{invalid')).exitCode, 2);
      expect((await _run(rawCandidate: 'null')).exitCode, 2);
      expect((await _run(rawBaseline: 'null')).exitCode, 2);
      expect((await _run(extraArgs: ['--unknown', 'x'])).exitCode, 2);
      expect((await _run(extraArgs: ['--candidate', 'missing'])).exitCode, 2);
    },
  );

  test('missing group fields and invalid correctness counts fail closed', () {
    for (final key in _group().keys) {
      final candidate = _report()..['groups'] = [_group()..remove(key)];
      expect(
        comparator.comparePhase0aHeadlessBaselines(
          candidate: candidate,
          maxRegressionPercent: 10,
        )['status'],
        'INVALID',
        reason: key,
      );
    }
    for (final pairs in [null, 0, -1, 1.5, '1']) {
      final candidate = _report()
        ..['correctness'] = {'same_seed_equal': true, 'compared_pairs': pairs};
      expect(
        comparator.comparePhase0aHeadlessBaselines(
          candidate: candidate,
          maxRegressionPercent: 10,
        )['status'],
        'INVALID',
      );
    }
  });

  test('non-finite rates and comparison keys are rejected', () {
    for (final value in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      for (final key in [
        'simulated_ticks_per_second',
        'completed_battles_per_second',
      ]) {
        final candidate = _report()..['groups'] = [_group()..[key] = value];
        expect(
          comparator.comparePhase0aHeadlessBaselines(
            candidate: candidate,
            maxRegressionPercent: 10,
          )['status'],
          'INVALID',
        );
      }
      final candidate = _report()
        ..['comparison_key'] = {
          'nested': [value],
        };
      expect(
        comparator.comparePhase0aHeadlessBaselines(
          candidate: candidate,
          maxRegressionPercent: 10,
        )['status'],
        'INVALID',
      );
    }
  });

  test('zero threshold rejects even a small measured decline', () {
    final baseline = _report(id: 'baseline')
      ..['groups'] = [_group(ticks: 1000000000000)];
    final candidate = _report()..['groups'] = [_group(ticks: 999999999999)];
    expect(
      comparator.comparePhase0aHeadlessBaselines(
        baseline: baseline,
        candidate: candidate,
        maxRegressionPercent: 0,
      )['status'],
      'REGRESSION',
    );
  });

  test(
    'different attempts are incompatible even when both rates match',
    () async {
      final candidate = _report()..['groups'] = [_group(attempts: 11)];
      final result = await _run(
        baseline: _report(id: 'baseline'),
        candidate: candidate,
      );
      expect(result.exitCode, 2);
      expect(result.json['status'], 'INCOMPATIBLE');
    },
  );
}
