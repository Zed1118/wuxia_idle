import 'dart:convert';
import 'dart:io';

import 'route_c_gate_preflight.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty || !{'prepare', 'aggregate'}.contains(args.first)) {
    stderr.writeln(
      'Usage:\n'
      '  dart run tool/route_c_human_gate.dart prepare --candidate <git-ref> '
      '--app <aot-payload> --fixture <yaml> --output <dir>\n'
      '  dart run tool/route_c_human_gate.dart aggregate --candidate <git-ref> '
      '--sessions <dir> --manifest <package-manifest.json> --app <aot-payload> '
      '--fixture <yaml> '
      '--output <summary.json>',
    );
    exitCode = 64;
    return;
  }
  try {
    final options = _parseArgs(args.skip(1).toList());
    final repository = Directory(
      options['repository'] ?? Directory.current.path,
    );
    final candidate = options['candidate'];
    if (candidate == null) throw const FormatException('missing --candidate');
    final commit = await _git(repository, <String>[
      'rev-parse',
      '$candidate^{commit}',
    ]);
    if (args.first == 'prepare') {
      await _prepare(repository, commit, options);
    } else {
      await _aggregate(commit, options);
    }
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 64;
  }
}

Future<void> _prepare(
  Directory repository,
  String commit,
  Map<String, String> options,
) async {
  final dirty = await _git(repository, const <String>['status', '--porcelain']);
  if (dirty.isNotEmpty) {
    throw StateError(
      'refusing to prepare a human Gate package from a dirty tree',
    );
  }
  final app = File(_required(options, 'app'));
  final fixture = File(_required(options, 'fixture'));
  if (!app.existsSync()) {
    throw StateError('app AOT payload does not exist: ${app.path}');
  }
  if (!fixture.existsSync()) {
    throw StateError('fixture does not exist: ${fixture.path}');
  }
  final output = Directory(_required(options, 'output'));
  await output.create(recursive: true);
  final binaryChecksum = await _sha256(app);
  final fixtureChecksum = await _sha256(fixture);
  final manifest = <String, Object?>{
    'schema': 'route-c-human-package-v1',
    'commit': commit,
    'app_package': 'wuxia_idle',
    'route_id': routeCProductionRoute,
    'binary_sha256': binaryChecksum,
    'fixture_sha256': fixtureChecksum,
    'participant_ids': <String>[
      for (var index = 1; index <= 6; index++)
        'P${index.toString().padLeft(2, '0')}',
    ],
    'viewport_schedule': const <String, String>{
      'P01': '1280x720',
      'P02': '1280x720',
      'P03': '1280x720',
      'P04': '1440x900',
      'P05': '1440x900',
      'P06': '1440x900',
    },
    'player_type_schedule': const <String, String>{
      'P01': 'idle',
      'P02': 'arpg',
      'P03': 'mixed',
      'P04': 'idle',
      'P05': 'arpg',
      'P06': 'mixed',
    },
  };
  await _writeJson(File('${output.path}/package-manifest.json'), manifest);
  for (var index = 0; index < 6; index++) {
    final participant = 'P${(index + 1).toString().padLeft(2, '0')}';
    final sessionDir = Directory('${output.path}/sessions/$participant');
    await sessionDir.create(recursive: true);
    await _writeJson(
      File('${sessionDir.path}/human-session.json'),
      _sessionTemplate(
        participant: participant,
        commit: commit,
        binaryChecksum: binaryChecksum,
        fixtureChecksum: fixtureChecksum,
        viewport: index < 3 ? '1280x720' : '1440x900',
        playerType: const <String>['idle', 'arpg', 'mixed'][index % 3],
      ),
    );
  }
  stdout.writeln(
    const JsonEncoder.withIndent(' ').convert(<String, Object?>{
      'state': 'READY_FOR_HUMAN_SESSIONS',
      'output': output.absolute.path,
      'commit': commit,
      'binary_sha256': binaryChecksum,
      'fixture_sha256': fixtureChecksum,
    }),
  );
}

Future<void> _aggregate(String commit, Map<String, String> options) async {
  final sessionsRoot = Directory(_required(options, 'sessions'));
  final sessions = await _readSessions(sessionsRoot);
  final manifestFile = File(_required(options, 'manifest'));
  final manifestValue = jsonDecode(await manifestFile.readAsString());
  if (manifestValue is! Map) {
    throw FormatException('${manifestFile.path} must contain a JSON object');
  }
  final manifest = manifestValue.cast<String, Object?>();
  final actualBinaryChecksum = await _sha256(File(_required(options, 'app')));
  final actualFixtureChecksum = await _sha256(
    File(_required(options, 'fixture')),
  );
  final evidence = validateHumanEvidence(
    sessions,
    <Map<String, Object?>>[manifest],
    expectedCommit: commit,
    actualBinaryChecksum: actualBinaryChecksum,
    actualFixtureChecksum: actualFixtureChecksum,
  );
  final result = aggregateRouteCHumanGate(
    sessions,
    expectedCommit: commit,
    expectedBinaryChecksum: manifest['binary_sha256']?.toString(),
    expectedFixtureChecksum: manifest['fixture_sha256']?.toString(),
  );
  final verdict = evidence.state == GateState.pass
      ? result.verdict
      : 'INCONCLUSIVE';
  final summary = <String, Object?>{
    ...result.summary,
    'verdict': verdict,
    if (evidence.state != GateState.pass)
      'evidence_errors': evidence.details.skip(1).toList(),
  };
  final encoded = const JsonEncoder.withIndent(' ').convert(summary);
  stdout.writeln(encoded);
  final output = options['output'];
  if (output != null) await File(output).writeAsString('$encoded\n');
  exitCode = switch (verdict) {
    'HUMAN_GATE_PASS' => 0,
    'LOCAL_FAIL' => 1,
    'INCONCLUSIVE' => 2,
    _ => 70,
  };
}

Map<String, Object?> _sessionTemplate({
  required String participant,
  required String commit,
  required String binaryChecksum,
  required String fixtureChecksum,
  required String viewport,
  required String playerType,
}) => <String, Object?>{
  'schema': routeCHumanSessionSchema,
  'session_id':
      'route-c-${participant.toLowerCase()}-${commit.substring(0, 8)}',
  'participant_id': participant,
  'commit': commit,
  'binary_sha256': binaryChecksum,
  'fixture_sha256': fixtureChecksum,
  'route_id': routeCProductionRoute,
  'viewport': viewport,
  'player_type': playerType,
  'ratings': <String, int>{'release': 1, 'readability': 1, 'active_intent': 1},
  'replay_willing': false,
  'mechanics': <String, bool>{
    'charge_warning_seen': false,
    'interrupt_feedback_understood': false,
    'stagger_seen': false,
    'vulnerability_window_understood': false,
    'keyboard_mouse_completed': false,
    'no_layout_overflow_or_hang': false,
  },
  'direct_veto': <String, bool>{
    'stationary_or_cooldown_only_is_optimal': false,
    'two_core_actions_lack_role': false,
    'density_unreadable': false,
    'requires_forbidden_mechanic': false,
  },
  'integrity': <String, bool>{
    'completed_three_waves': false,
    'participant_had_input_control': false,
    'implementer_assisted': false,
    'external_event_polluted': false,
    'questionnaire_complete': false,
  },
  'validity': <String, Object?>{
    'valid': false,
    'invalid_reasons': <String>['NOT_FILLED'],
  },
};

Future<List<Map<String, Object?>>> _readSessions(Directory root) async {
  if (!root.existsSync()) return const <Map<String, Object?>>[];
  final sessions = <Map<String, Object?>>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File ||
        entity.uri.pathSegments.last != 'human-session.json') {
      continue;
    }
    final value = jsonDecode(await entity.readAsString());
    if (value is! Map) {
      throw FormatException('${entity.path} must contain a JSON object');
    }
    sessions.add(value.cast<String, Object?>());
  }
  return sessions;
}

Future<String> _sha256(File file) async {
  final result = await Process.run('shasum', <String>['-a', '256', file.path]);
  if (result.exitCode != 0) throw StateError((result.stderr as String).trim());
  final checksum = (result.stdout as String).trim().split(RegExp(r'\s+')).first;
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(checksum)) {
    throw StateError('invalid SHA-256 output for ${file.path}');
  }
  return checksum;
}

Future<void> _writeJson(File file, Map<String, Object?> value) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(value)}\n',
  );
}

Map<String, String> _parseArgs(List<String> args) {
  final options = <String, String>{};
  for (var index = 0; index < args.length; index += 2) {
    if (index + 1 >= args.length || !args[index].startsWith('--')) {
      throw const FormatException('arguments must be --key value pairs');
    }
    options[args[index].substring(2)] = args[index + 1];
  }
  return options;
}

String _required(Map<String, String> options, String key) {
  final value = options[key];
  if (value == null || value.isEmpty) throw FormatException('missing --$key');
  return value;
}

Future<String> _git(Directory repository, List<String> arguments) async {
  final result = await Process.run(
    'git',
    arguments,
    workingDirectory: repository.path,
  );
  if (result.exitCode != 0) throw StateError((result.stderr as String).trim());
  return (result.stdout as String).trim();
}
