import 'dart:convert';
import 'dart:io';

const routeCHumanSessionSchema = 'route-c-human-session-v1';
const routeCWindowsRunSchema = 'route-c-windows-production-run-v1';
const routeCProductionRoute = 'phase0a_battle_playable';
const routeCProductionProfileRoute = 'phase0a_battle_profile';

enum GateState { pass, pending, invalid }

final class GateCheck {
  const GateCheck(this.name, this.state, this.details);

  final String name;
  final GateState state;
  final List<String> details;

  Map<String, Object> toJson() => <String, Object>{
    'name': name,
    'state': state.name.toUpperCase(),
    'details': details,
  };
}

final class HumanGateAggregation {
  const HumanGateAggregation({required this.verdict, required this.summary});

  final String verdict;
  final Map<String, Object?> summary;
}

GateCheck validateRouteCDeletionTree(Iterable<String> battleFiles) {
  final files = battleFiles.where((path) => path.trim().isNotEmpty).toList();
  final legacy = files
      .where((path) => !path.contains('/phase0a/'))
      .toList(growable: false);
  if (files.isEmpty) {
    return const GateCheck('candidate_tree', GateState.invalid, <String>[
      'Candidate contains no Phase 0A battle sources.',
    ]);
  }
  if (legacy.isNotEmpty) {
    return GateCheck('candidate_tree', GateState.invalid, <String>[
      'Candidate still contains ${legacy.length} non-Phase0A battle files.',
      ...legacy.take(10),
    ]);
  }
  return GateCheck('candidate_tree', GateState.pass, <String>[
    '${files.length} Phase 0A battle source files; no legacy battle source.',
  ]);
}

GateCheck validateHumanSessions(
  Iterable<Map<String, Object?>> sessions, {
  required String expectedCommit,
  String? expectedBinaryChecksum,
  String? expectedFixtureChecksum,
}) {
  final records = sessions.toList(growable: false);
  if (records.isEmpty) {
    return const GateCheck('human_gate', GateState.pending, <String>[
      'No production Route C human-session evidence found.',
    ]);
  }
  final aggregation = aggregateRouteCHumanGate(
    records,
    expectedCommit: expectedCommit,
    expectedBinaryChecksum: expectedBinaryChecksum,
    expectedFixtureChecksum: expectedFixtureChecksum,
  );
  final errors = (aggregation.summary['schema_errors']! as List<Object?>)
      .cast<String>();
  final failedChecks = (aggregation.summary['checks']! as Map<String, Object?>)
      .entries
      .where((entry) => entry.value != true)
      .map((entry) => entry.key)
      .toList(growable: false);
  if (aggregation.verdict != 'HUMAN_GATE_PASS') {
    return GateCheck('human_gate', GateState.invalid, <String>[
      aggregation.verdict,
      ...errors.take(20),
      if (errors.length > 20) '${errors.length - 20} more schema errors',
      if (errors.isEmpty && failedChecks.isNotEmpty)
        'failed checks: ${failedChecks.join(', ')}',
    ]);
  }
  return GateCheck('human_gate', GateState.pass, <String>[
    'HUMAN_GATE_PASS: 6 valid anonymous sessions use one production binary '
        'at $expectedCommit.',
  ]);
}

GateCheck validateHumanEvidence(
  Iterable<Map<String, Object?>> sessions,
  Iterable<Map<String, Object?>> packageManifests, {
  required String expectedCommit,
  String? actualBinaryChecksum,
  String? actualFixtureChecksum,
}) {
  final records = sessions.toList(growable: false);
  if (records.isEmpty) {
    return const GateCheck('human_gate', GateState.pending, <String>[
      'No production Route C human-session evidence found.',
    ]);
  }
  final manifests = packageManifests.toList(growable: false);
  if (manifests.length != 1) {
    return GateCheck('human_gate', GateState.invalid, <String>[
      'INCONCLUSIVE',
      'expected exactly one package-manifest.json, found ${manifests.length}',
    ]);
  }
  final manifest = manifests.single;
  final binary = manifest['binary_sha256']?.toString() ?? '';
  final fixture = manifest['fixture_sha256']?.toString() ?? '';
  final problems = <String>[];
  if (manifest['schema'] != 'route-c-human-package-v1') {
    problems.add('human package uses obsolete schema');
  }
  if (manifest['commit'] != expectedCommit) {
    problems.add('human package commit mismatch');
  }
  if (manifest['app_package'] != 'wuxia_idle' ||
      manifest['route_id'] != routeCProductionRoute) {
    problems.add('human package does not target the root production route');
  }
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(binary)) {
    problems.add('human package has invalid binary_sha256');
  }
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(fixture)) {
    problems.add('human package has invalid fixture_sha256');
  }
  if (actualBinaryChecksum == null) {
    problems.add('human package executable is missing');
  } else if (binary != actualBinaryChecksum) {
    problems.add('human package executable checksum mismatch');
  }
  if (actualFixtureChecksum == null) {
    problems.add('human package fixture is missing');
  } else if (fixture != actualFixtureChecksum) {
    problems.add('human package fixture checksum mismatch');
  }
  if (problems.isNotEmpty) {
    return GateCheck('human_gate', GateState.invalid, <String>[
      'INCONCLUSIVE',
      ...problems,
    ]);
  }
  return validateHumanSessions(
    records,
    expectedCommit: expectedCommit,
    expectedBinaryChecksum: binary,
    expectedFixtureChecksum: fixture,
  );
}

HumanGateAggregation aggregateRouteCHumanGate(
  Iterable<Map<String, Object?>> sessions, {
  required String expectedCommit,
  String? expectedBinaryChecksum,
  String? expectedFixtureChecksum,
}) {
  final records = sessions.toList(growable: false);
  final problems = <String>[];
  final participants = <String>{};
  final sessionIds = <String>{};
  final binaries = <String>{};
  final fixtures = <String>{};
  final viewportCounts = <String, int>{};
  final playerTypeCounts = <String, int>{};
  final valid = <Map<String, Object?>>[];
  for (final record in records) {
    final participant = record['participant_id']?.toString() ?? '<missing>';
    if (!participants.add(participant)) {
      problems.add('duplicate participant_id: $participant');
    }
    if (!RegExp(r'^P0[1-6]$').hasMatch(participant)) {
      problems.add('$participant is not an anonymous P01..P06 id');
    }
    const forbiddenIdentityKeys = <String>{
      'name',
      'real_name',
      'email',
      'account',
      'phone',
      'device_owner',
    };
    for (final key in forbiddenIdentityKeys) {
      if (record.containsKey(key)) {
        problems.add('$participant contains forbidden identity key $key');
      }
    }
    if (record['schema'] != routeCHumanSessionSchema) {
      problems.add('$participant uses obsolete session schema');
    }
    final sessionId = record['session_id']?.toString() ?? '';
    if (!RegExp(r'^[a-z0-9][a-z0-9_-]{7,63}$').hasMatch(sessionId)) {
      problems.add('$participant has invalid session_id');
    } else if (!sessionIds.add(sessionId)) {
      problems.add('duplicate session_id: $sessionId');
    }
    if (record['commit'] != expectedCommit) {
      problems.add('$participant commit mismatch');
    }
    if (record['route_id'] != routeCProductionRoute) {
      problems.add('$participant did not run the production Route C route');
    }
    final binary = record['binary_sha256']?.toString() ?? '';
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(binary)) {
      problems.add('$participant has invalid binary_sha256');
    } else {
      binaries.add(binary);
    }
    if (expectedBinaryChecksum != null && binary != expectedBinaryChecksum) {
      problems.add('$participant binary does not match package manifest');
    }
    final fixture = record['fixture_sha256']?.toString() ?? '';
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(fixture)) {
      problems.add('$participant has invalid fixture_sha256');
    } else {
      fixtures.add(fixture);
    }
    if (expectedFixtureChecksum != null && fixture != expectedFixtureChecksum) {
      problems.add('$participant fixture does not match package manifest');
    }
    final viewport = record['viewport']?.toString() ?? '';
    viewportCounts[viewport] = (viewportCounts[viewport] ?? 0) + 1;
    final playerType = record['player_type']?.toString() ?? '';
    playerTypeCounts[playerType] = (playerTypeCounts[playerType] ?? 0) + 1;

    final ratings = _objectMap(record['ratings']);
    for (final key in const <String>[
      'release',
      'readability',
      'active_intent',
    ]) {
      final value = ratings?[key];
      if (value is! int || value < 1 || value > 5) {
        problems.add('$participant ratings.$key must be 1..5');
      }
    }
    if (record['replay_willing'] is! bool) {
      problems.add('$participant replay_willing must be boolean');
    }
    final mechanics = record['mechanics'];
    final mechanicMap = _objectMap(mechanics);
    for (final key in const <String>[
      'charge_warning_seen',
      'interrupt_feedback_understood',
      'stagger_seen',
      'vulnerability_window_understood',
      'keyboard_mouse_completed',
      'no_layout_overflow_or_hang',
    ]) {
      if (mechanicMap?[key] is! bool) {
        problems.add('$participant mechanics.$key must be boolean');
      }
    }
    final veto = _objectMap(record['direct_veto']);
    for (final key in const <String>[
      'stationary_or_cooldown_only_is_optimal',
      'two_core_actions_lack_role',
      'density_unreadable',
      'requires_forbidden_mechanic',
    ]) {
      if (veto?[key] is! bool) {
        problems.add('$participant direct_veto.$key must be boolean');
      }
    }
    final integrity = _objectMap(record['integrity']);
    for (final key in const <String>[
      'completed_three_waves',
      'participant_had_input_control',
      'implementer_assisted',
      'external_event_polluted',
      'questionnaire_complete',
    ]) {
      if (integrity?[key] is! bool) {
        problems.add('$participant integrity.$key must be boolean');
      }
    }
    final validity = _objectMap(record['validity']);
    final invalidReasons = validity?['invalid_reasons'];
    if (validity?['valid'] is! bool ||
        invalidReasons is! List ||
        invalidReasons.any((reason) => reason is! String)) {
      problems.add('$participant has invalid validity metadata');
    } else if (validity!['valid'] == true && invalidReasons.isNotEmpty) {
      problems.add('$participant valid sample has invalid_reasons');
    } else if (validity['valid'] == false && invalidReasons.isEmpty) {
      problems.add('$participant invalid sample lacks invalid_reasons');
    }
    if (validity?['valid'] == true &&
        (integrity?['participant_had_input_control'] != true ||
            integrity?['implementer_assisted'] == true ||
            integrity?['external_event_polluted'] == true ||
            integrity?['questionnaire_complete'] != true)) {
      problems.add('$participant validity contradicts integrity flags');
    }
    if (validity?['valid'] == true) {
      valid.add(record);
    }
  }
  if (records.length != 6 || participants.length != 6 || valid.length != 6) {
    problems.add('expected 6 unique valid participants, found ${valid.length}');
  }
  if (participants.length == 6 &&
      !participants.containsAll(const <String>{
        'P01',
        'P02',
        'P03',
        'P04',
        'P05',
        'P06',
      })) {
    problems.add('participants must be exactly P01..P06');
  }
  if (binaries.length > 1) {
    problems.add('human sessions mix multiple production binaries');
  }
  if (fixtures.length > 1) {
    problems.add('human sessions mix multiple production fixtures');
  }
  for (final viewport in const <String>['1280x720', '1440x900']) {
    if (viewportCounts[viewport] != 3) {
      problems.add(
        '$viewport requires 3 human sessions, found '
        '${viewportCounts[viewport] ?? 0}',
      );
    }
  }
  for (final playerType in const <String>['idle', 'arpg', 'mixed']) {
    if (playerTypeCounts[playerType] != 2) {
      problems.add(
        '$playerType requires 2 human sessions, found '
        '${playerTypeCounts[playerType] ?? 0}',
      );
    }
  }

  final directVetos = <String>[];
  for (final record in valid) {
    final veto = _objectMap(record['direct_veto']) ?? const {};
    for (final entry in veto.entries) {
      if (entry.value == true) {
        directVetos.add('${record['participant_id']}:${entry.key}');
      }
    }
  }
  final metrics = <String, Object?>{
    'release_median': _medianRating(valid, 'release'),
    'readability_median': _medianRating(valid, 'readability'),
    'active_intent_median': _medianRating(valid, 'active_intent'),
    'replay_willing_count': valid
        .where((record) => record['replay_willing'] == true)
        .length,
    for (final key in const <String>[
      'charge_warning_seen',
      'interrupt_feedback_understood',
      'stagger_seen',
      'vulnerability_window_understood',
      'keyboard_mouse_completed',
      'no_layout_overflow_or_hang',
    ])
      '${key}_count': _countNestedTrue(valid, 'mechanics', key),
    'completed_unassisted_count': valid.where((record) {
      final integrity = _objectMap(record['integrity']) ?? const {};
      return integrity['completed_three_waves'] == true &&
          integrity['participant_had_input_control'] == true &&
          integrity['implementer_assisted'] == false;
    }).length,
  };
  final checks = <String, bool>{
    'schema_and_provenance_valid': problems.isEmpty,
    'ratings_median_at_least_4':
        _metric(metrics, 'release_median') >= 4 &&
        _metric(metrics, 'readability_median') >= 4 &&
        _metric(metrics, 'active_intent_median') >= 4,
    'replay_willing_4_of_6': (metrics['replay_willing_count'] as int) >= 4,
    'charge_warning_seen_5_of_6':
        (metrics['charge_warning_seen_count'] as int) >= 5,
    'interrupt_understood_5_of_6':
        (metrics['interrupt_feedback_understood_count'] as int) >= 5,
    'stagger_seen_5_of_6': (metrics['stagger_seen_count'] as int) >= 5,
    'vulnerability_understood_5_of_6':
        (metrics['vulnerability_window_understood_count'] as int) >= 5,
    'keyboard_mouse_6_of_6': metrics['keyboard_mouse_completed_count'] == 6,
    'layout_and_hang_6_of_6': metrics['no_layout_overflow_or_hang_count'] == 6,
    'completed_unassisted_5_of_6':
        (metrics['completed_unassisted_count'] as int) >= 5,
    'no_direct_veto': directVetos.isEmpty,
  };
  final enough = records.length == 6 && valid.length == 6;
  final verdict = problems.isNotEmpty || !enough
      ? 'INCONCLUSIVE'
      : checks.values.every((passed) => passed)
      ? 'HUMAN_GATE_PASS'
      : 'LOCAL_FAIL';
  return HumanGateAggregation(
    verdict: verdict,
    summary: <String, Object?>{
      'schema': 'route-c-human-gate-summary-v1',
      'verdict': verdict,
      'commit': expectedCommit,
      'valid_sample_count': valid.length,
      'binary_sha256': binaries.length == 1 ? binaries.single : null,
      'fixture_sha256': fixtures.length == 1 ? fixtures.single : null,
      'schema_errors': problems,
      'direct_vetos': directVetos,
      'metrics': metrics,
      'checks': checks,
    },
  );
}

Map<String, Object?>? _objectMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) return value.cast<String, Object?>();
  return null;
}

double _medianRating(List<Map<String, Object?>> records, String key) {
  final values =
      records
          .map((record) => _objectMap(record['ratings'])?[key])
          .whereType<int>()
          .map((value) => value.toDouble())
          .toList()
        ..sort();
  if (values.length != records.length || values.isEmpty) return 0;
  final middle = values.length ~/ 2;
  return values.length.isOdd
      ? values[middle]
      : (values[middle - 1] + values[middle]) / 2;
}

int _countNestedTrue(
  List<Map<String, Object?>> records,
  String group,
  String key,
) => records.where((record) => _objectMap(record[group])?[key] == true).length;

double _metric(Map<String, Object?> metrics, String key) =>
    (metrics[key]! as num).toDouble();

GateCheck validateWindowsRuns(
  Iterable<Map<String, Object?>> runs, {
  required String expectedCommit,
}) {
  final records = runs.toList(growable: false);
  if (records.isEmpty) {
    return const GateCheck('windows_gate', GateState.pending, <String>[
      'No minimum-spec Windows production-run evidence found.',
    ]);
  }
  final problems = <String>[];
  final ids = <String>{};
  final binaries = <String>{};
  final fixtures = <String>{};
  final hosts = <String>{};
  final viewportCounts = <String, int>{};
  for (final record in records) {
    final id = record['run_id']?.toString() ?? '<missing>';
    if (!ids.add(id)) problems.add('duplicate run_id: $id');
    if (record['schema'] != routeCWindowsRunSchema) {
      problems.add('$id uses obsolete Windows run schema');
    }
    if (record['app_package'] != 'wuxia_idle' ||
        record['route_id'] != routeCProductionProfileRoute) {
      problems.add('$id did not measure the root production app');
    }
    if (record['commit'] != expectedCommit) {
      problems.add('$id commit mismatch');
    }
    final binary = record['binary_sha256']?.toString() ?? '';
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(binary)) {
      problems.add('$id has invalid binary_sha256');
    } else {
      binaries.add(binary);
    }
    final fixture = record['fixture_sha256']?.toString() ?? '';
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(fixture)) {
      problems.add('$id has invalid fixture_sha256');
    } else {
      fixtures.add(fixture);
    }
    final host = record['host_manifest_sha256']?.toString() ?? '';
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(host)) {
      problems.add('$id has invalid host_manifest_sha256');
    } else {
      hosts.add(host);
    }
    final viewport = record['viewport']?.toString() ?? '';
    viewportCounts[viewport] = (viewportCounts[viewport] ?? 0) + 1;
    if (record['minimum_spec_attested'] != true ||
        record['local_console'] != true ||
        record['composite_gate'] != 'PASS') {
      problems.add('$id lacks minimum-spec/local-console/composite PASS');
    }
  }
  if (records.length != 6 || ids.length != 6) {
    problems.add('expected 6 unique Windows runs, found ${ids.length}');
  }
  for (final viewport in const <String>['1280x720', '1440x900']) {
    if (viewportCounts[viewport] != 3) {
      problems.add(
        '$viewport requires 3 runs, found ${viewportCounts[viewport] ?? 0}',
      );
    }
  }
  if (binaries.length > 1) {
    problems.add('Windows runs mix multiple production binaries');
  }
  if (fixtures.length > 1) {
    problems.add('Windows runs mix multiple production fixtures');
  }
  if (hosts.length > 1) {
    problems.add('Windows runs mix multiple host manifests');
  }
  if (problems.isNotEmpty) {
    return GateCheck('windows_gate', GateState.invalid, problems);
  }
  return GateCheck('windows_gate', GateState.pass, <String>[
    '6 minimum-spec runs use one root-app binary at $expectedCommit.',
  ]);
}

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  final repository = Directory(options['repository'] ?? Directory.current.path);
  final candidate = options['candidate'];
  if (candidate == null || candidate.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/route_c_gate_preflight.dart '
      '--candidate <git-ref> [--repository <path>] '
      '[--human-dir <path>] [--windows-dir <path>] [--output <path>]',
    );
    exitCode = 64;
    return;
  }

  final resolvedCandidate = await _git(repository, <String>[
    'rev-parse',
    '$candidate^{commit}',
  ]);
  final dirty = await _git(repository, const <String>['status', '--porcelain']);
  final candidateFiles = await _git(repository, <String>[
    'ls-tree',
    '-r',
    '--name-only',
    resolvedCandidate,
    '--',
    'lib/features/battle',
  ]);

  final humanSessions = await _readEvidence(
    options['human-dir'],
    'human-session.json',
  );
  final humanPackages = await _readEvidence(
    options['human-dir'],
    'package-manifest.json',
  );
  final humanRoot = options['human-dir'];
  final actualHumanBinary = humanRoot == null
      ? null
      : await _sha256IfExists(
          File('$humanRoot/package/wuxia_idle.app/Contents/MacOS/wuxia_idle'),
        );
  final actualHumanFixture = humanRoot == null
      ? null
      : await _sha256IfExists(
          File('$humanRoot/package/phase0a_debug_battle.yaml'),
        );
  final checks = <GateCheck>[
    GateCheck(
      'worktree',
      dirty.isEmpty ? GateState.pass : GateState.invalid,
      <String>[dirty.isEmpty ? 'Worktree is clean.' : 'Worktree is dirty.'],
    ),
    validateRouteCDeletionTree(candidateFiles.split('\n')),
    validateHumanEvidence(
      humanSessions,
      humanPackages,
      expectedCommit: resolvedCandidate,
      actualBinaryChecksum: actualHumanBinary,
      actualFixtureChecksum: actualHumanFixture,
    ),
    validateWindowsRuns(
      await _readEvidence(options['windows-dir'], 'manifest.json'),
      expectedCommit: resolvedCandidate,
    ),
  ];
  final state = checks.any((check) => check.state == GateState.invalid)
      ? GateState.invalid
      : checks.any((check) => check.state == GateState.pending)
      ? GateState.pending
      : GateState.pass;
  final report = <String, Object>{
    'schema': 'route-c-gate-preflight-v1',
    'state': state.name.toUpperCase(),
    'candidate_commit': resolvedCandidate,
    'checks': checks.map((check) => check.toJson()).toList(),
  };
  final encoded = const JsonEncoder.withIndent('  ').convert(report);
  stdout.writeln(encoded);
  final output = options['output'];
  if (output != null) await File(output).writeAsString('$encoded\n');
  exitCode = switch (state) {
    GateState.pass => 0,
    GateState.pending => 2,
    GateState.invalid => 1,
  };
}

Map<String, String> _parseArgs(List<String> args) {
  final result = <String, String>{};
  for (var index = 0; index < args.length; index += 2) {
    if (index + 1 >= args.length || !args[index].startsWith('--')) {
      throw const FormatException('Arguments must be --key value pairs.');
    }
    result[args[index].substring(2)] = args[index + 1];
  }
  return result;
}

Future<String> _git(Directory repository, List<String> arguments) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: repository.path,
  );
  if (result.exitCode != 0) {
    throw StateError((result.stderr as String).trim());
  }
  return (result.stdout as String).trim();
}

Future<List<Map<String, Object?>>> _readEvidence(
  String? rootPath,
  String fileName,
) async {
  if (rootPath == null) return const <Map<String, Object?>>[];
  final root = Directory(rootPath);
  if (!root.existsSync()) return const <Map<String, Object?>>[];
  final records = <Map<String, Object?>>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File || entity.uri.pathSegments.last != fileName) continue;
    final decoded = jsonDecode(await entity.readAsString());
    if (decoded is! Map<String, Object?>) {
      throw FormatException('${entity.path} must contain a JSON object.');
    }
    records.add(decoded);
  }
  return records;
}

Future<String?> _sha256IfExists(File file) async {
  if (!file.existsSync()) return null;
  final result = await Process.run('shasum', <String>['-a', '256', file.path]);
  if (result.exitCode != 0) return null;
  final checksum = (result.stdout as String).trim().split(RegExp(r'\s+')).first;
  return RegExp(r'^[0-9a-f]{64}$').hasMatch(checksum) ? checksum : null;
}
