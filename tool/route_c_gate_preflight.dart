import 'dart:convert';
import 'dart:io';

const routeCHumanSessionSchema = 'route-c-human-session-v1';
const routeCWindowsRunSchema = 'route-c-windows-production-run-v1';
const routeCProductionRoute = 'phase0a_battle_playable';

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
}) {
  final records = sessions.toList(growable: false);
  if (records.isEmpty) {
    return const GateCheck('human_gate', GateState.pending, <String>[
      'No production Route C human-session evidence found.',
    ]);
  }
  final problems = <String>[];
  final participants = <String>{};
  final binaries = <String>{};
  for (final record in records) {
    final participant = record['participant_id']?.toString() ?? '<missing>';
    if (!participants.add(participant)) {
      problems.add('duplicate participant_id: $participant');
    }
    if (record['schema'] != routeCHumanSessionSchema) {
      problems.add('$participant uses obsolete session schema');
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
    final mechanics = record['mechanics'];
    if (mechanics is! Map<String, Object?> ||
        const <String>{
          'charge_warning_seen',
          'interrupt_feedback_understood',
          'stagger_seen',
          'vulnerability_window_understood',
          'keyboard_mouse_completed',
          'no_layout_overflow_or_hang',
        }.any((key) => mechanics[key] != true)) {
      problems.add('$participant has incomplete mechanic observations');
    }
    final validity = record['validity'];
    if (validity is! Map<String, Object?> || validity['valid'] != true) {
      problems.add('$participant is not a valid raw sample');
    }
  }
  if (records.length != 6 || participants.length != 6) {
    problems.add(
      'expected 6 unique participants, found ${participants.length}',
    );
  }
  if (binaries.length > 1) {
    problems.add('human sessions mix multiple production binaries');
  }
  if (problems.isNotEmpty) {
    return GateCheck('human_gate', GateState.invalid, problems);
  }
  return GateCheck('human_gate', GateState.pass, <String>[
    '6 valid anonymous sessions use one production binary at $expectedCommit.',
  ]);
}

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
  final viewportCounts = <String, int>{};
  for (final record in records) {
    final id = record['run_id']?.toString() ?? '<missing>';
    if (!ids.add(id)) problems.add('duplicate run_id: $id');
    if (record['schema'] != routeCWindowsRunSchema) {
      problems.add('$id uses obsolete Windows run schema');
    }
    if (record['app_package'] != 'wuxia_idle' ||
        record['route_id'] != routeCProductionRoute) {
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

  final checks = <GateCheck>[
    GateCheck(
      'worktree',
      dirty.isEmpty ? GateState.pass : GateState.invalid,
      <String>[dirty.isEmpty ? 'Worktree is clean.' : 'Worktree is dirty.'],
    ),
    validateRouteCDeletionTree(candidateFiles.split('\n')),
    validateHumanSessions(
      await _readEvidence(options['human-dir'], 'human-session.json'),
      expectedCommit: resolvedCandidate,
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
