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

GateCheck validateRouteCConsumerViolations(String grepOutput) {
  final violations = grepOutput
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .toList(growable: false);
  if (violations.isNotEmpty) {
    return GateCheck('production_consumers', GateState.invalid, <String>[
      'Candidate production consumers still reference retired 3v3 symbols.',
      ...violations.take(20),
    ]);
  }
  return const GateCheck('production_consumers', GateState.pass, <String>[
    'Production consumers contain no retired 3v3 imports or route gates.',
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
  bool requireRawEvidence = false,
  Map<String, Object?>? hostManifest,
  String? actualHostManifestChecksum,
  String? actualBinaryChecksum,
  String? actualFixtureChecksum,
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
    if (requireRawEvidence) {
      _validateWindowsRawEvidence(record, id, viewport, problems);
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
  if (requireRawEvidence) {
    if (actualBinaryChecksum == null ||
        binaries.length != 1 ||
        binaries.single != actualBinaryChecksum) {
      problems.add(
        'frozen Windows executable is missing or checksum mismatched',
      );
    }
    if (actualFixtureChecksum == null ||
        fixtures.length != 1 ||
        fixtures.single != actualFixtureChecksum) {
      problems.add('frozen Windows fixture is missing or checksum mismatched');
    }
    _validateWindowsHost(
      hostManifest,
      actualChecksum: actualHostManifestChecksum,
      expectedChecksums: hosts,
      problems: problems,
    );
  }
  if (problems.isNotEmpty) {
    return GateCheck('windows_gate', GateState.invalid, problems);
  }
  return GateCheck('windows_gate', GateState.pass, <String>[
    '6 minimum-spec runs use one root-app binary at $expectedCommit.',
  ]);
}

void _validateWindowsRawEvidence(
  Map<String, Object?> record,
  String id,
  String viewport,
  List<String> problems,
) {
  if (record['_raw_files_present'] != true) {
    problems.add('$id is missing one or more raw evidence files');
  }
  final rawEvidence = _objectMap(record['raw_evidence']);
  if (rawEvidence?['frames_jsonl'] != 'frames.jsonl' ||
      rawEvidence?['memory_gc_jsonl'] != 'memory_gc.jsonl' ||
      rawEvidence?['summary_json'] != 'summary.json' ||
      rawEvidence?['run_log'] != 'run.log') {
    problems.add('$id raw evidence paths are not the frozen filenames');
  }
  final summary = _objectMap(record['_summary']);
  final derived = _objectMap(record['_derived']);
  if (summary == null || derived == null) {
    problems.add('$id lacks independently readable summary/raw telemetry');
    return;
  }
  if (summary['schema'] != 'route-c-production-profile-summary-v1' ||
      summary['run_id'] != id ||
      summary['sample_seconds'] != 60 ||
      summary['warmup_seconds'] != 12 ||
      summary['cooldown_seconds'] != 30) {
    problems.add('$id has invalid production summary metadata');
  }
  final viewportParts = viewport.split('x');
  final expectedWidth = viewportParts.length == 2
      ? int.tryParse(viewportParts[0])
      : null;
  final expectedHeight = viewportParts.length == 2
      ? int.tryParse(viewportParts[1])
      : null;
  final sampledFrames = _asInt(summary['sampled_frames']);
  final p99 = _asDouble(summary['p99_total_span_ms']);
  final severe = _asInt(summary['max_consecutive_severe_frames']);
  final rssStart = _asInt(summary['rss_start_bytes']);
  final rssEnd = _asInt(summary['rss_end_bytes']);
  final summaryPass =
      sampledFrames != null &&
      sampledFrames >= 3000 &&
      p99 != null &&
      p99 < 16.6 &&
      severe != null &&
      severe <= 1 &&
      summary['frame_streak_gate_passes'] == true &&
      summary['gc_telemetry_status'] == 'GC_TELEMETRY_COLLECTED' &&
      _asDouble(summary['logical_width']) == expectedWidth &&
      _asDouble(summary['logical_height']) == expectedHeight &&
      _asDouble(summary['device_pixel_ratio']) == 1.0 &&
      rssStart != null &&
      rssEnd != null &&
      rssEnd <= rssStart * 1.10 + 67108864;
  if (!summaryPass) problems.add('$id summary fails the composite thresholds');

  final derivedFrames = _asInt(derived['sampled_frames']);
  final derivedP99 = _asDouble(derived['p99_total_span_ms']);
  final derivedSevere = _asInt(derived['max_consecutive_severe_frames']);
  final derivedBuild = _asInt(derived['max_consecutive_build_over_budget']);
  final derivedRaster = _asInt(derived['max_consecutive_raster_over_budget']);
  final derivedRssStart = _asInt(derived['rss_start_bytes']);
  final derivedRssEnd = _asInt(derived['rss_end_bytes']);
  final derivedPass =
      derivedFrames != null &&
      derivedFrames >= 3000 &&
      derivedP99 != null &&
      derivedP99 < 16.6 &&
      derivedSevere != null &&
      derivedSevere <= 1 &&
      derivedBuild != null &&
      derivedBuild < 3 &&
      derivedRaster != null &&
      derivedRaster < 3 &&
      derived['gc_telemetry_status'] == 'GC_TELEMETRY_COLLECTED' &&
      derivedRssStart != null &&
      derivedRssEnd != null &&
      derivedRssEnd <= derivedRssStart * 1.10 + 67108864;
  if (!derivedPass) {
    problems.add('$id raw telemetry fails the composite thresholds');
  }
  if (sampledFrames != derivedFrames ||
      p99 == null ||
      derivedP99 == null ||
      (p99 - derivedP99).abs() > 0.001 ||
      severe != derivedSevere ||
      rssStart != derivedRssStart ||
      rssEnd != derivedRssEnd ||
      summary['gc_telemetry_status'] != derived['gc_telemetry_status']) {
    problems.add('$id summary does not match independently derived telemetry');
  }
}

void _validateWindowsHost(
  Map<String, Object?>? host, {
  required String? actualChecksum,
  required Set<String> expectedChecksums,
  required List<String> problems,
}) {
  if (host == null || actualChecksum == null) {
    problems.add('Windows host_manifest.json is missing or unreadable');
    return;
  }
  if (expectedChecksums.length != 1 ||
      expectedChecksums.single != actualChecksum) {
    problems.add('Windows host manifest checksum does not match all runs');
  }
  final device = _objectMap(host['device']) ?? const {};
  final display = _objectMap(host['display']) ?? const {};
  final session = _objectMap(host['session']) ?? const {};
  final runtime = _objectMap(host['runtime']) ?? const {};
  final attestation = _objectMap(host['attestation']) ?? const {};
  final renderer = runtime['renderer']?.toString() ?? '';
  final requiredViewports = display['required_logical_viewports'];
  if (host['status'] != 'RECORDED' ||
      attestation['valid_for_minimum_spec_gate'] != true ||
      attestation['cpu_at_or_below_target'] != true ||
      attestation['gpu_at_or_below_target'] != true ||
      attestation['ram_matches_target'] != true ||
      attestation['power_mode_confirmed_best_performance'] != true ||
      device['gpu_is_integrated'] != true ||
      device['plugged_in'] != true ||
      display['local_interactive_session'] != true ||
      display['refresh_rate_hz'] != 60 ||
      display['scale_percent'] != 100 ||
      session['remote_desktop'] != false ||
      session['virtual_machine'] != false ||
      renderer.isEmpty ||
      renderer.contains('FILL_') ||
      renderer.contains('UNKNOWN') ||
      requiredViewports is! List ||
      !requiredViewports.contains('1280x720') ||
      !requiredViewports.contains('1440x900')) {
    problems.add(
      'Windows host manifest fails minimum-spec/local-console rules',
    );
  }
}

int? _asInt(Object? value) => value is num ? value.toInt() : null;

double? _asDouble(Object? value) => value is num ? value.toDouble() : null;

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
  final consumerViolations = await _gitGrep(repository, <String>[
    '-n',
    '-E',
    r'^[[:space:]]*import.*battle/(application/(battle_providers|'
        r'legacy_3v3_combatant_adapter|stage_battle_setup)|'
        r'domain/battle_state|presentation/battle_screen)\.dart|'
        r'Phase0a(Mainline|Tower|Sweep|Expedition|Gauntlet)Gate',
    resolvedCandidate,
    '--',
    'lib/features/mainline',
    'lib/features/tower',
    'lib/features/sweep',
    'lib/features/expedition',
    'lib/features/boss_gauntlet',
    'lib/features/injury',
    'lib/features/jianghu',
    'lib/features/inner_demon',
    'lib/shared',
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
  final windowsRoot = options['windows-dir'];
  final windowsHostFile = windowsRoot == null
      ? null
      : File('$windowsRoot/host_manifest.json');
  final windowsHost = windowsHostFile == null
      ? null
      : await _readJsonObjectIfExists(windowsHostFile);
  final windowsHostChecksum = windowsHostFile == null
      ? null
      : await _sha256IfExists(windowsHostFile);
  final windowsBinaryChecksum = windowsRoot == null
      ? null
      : await _sha256IfExists(File('$windowsRoot/wuxia_idle.exe'));
  final windowsFixtureChecksum = windowsRoot == null
      ? null
      : await _sha256IfExists(File('$windowsRoot/phase0a_debug_battle.yaml'));
  final windowsRuns = await _readWindowsEvidence(windowsRoot);
  final checks = <GateCheck>[
    GateCheck(
      'worktree',
      dirty.isEmpty ? GateState.pass : GateState.invalid,
      <String>[dirty.isEmpty ? 'Worktree is clean.' : 'Worktree is dirty.'],
    ),
    validateRouteCDeletionTree(candidateFiles.split('\n')),
    validateRouteCConsumerViolations(consumerViolations),
    validateHumanEvidence(
      humanSessions,
      humanPackages,
      expectedCommit: resolvedCandidate,
      actualBinaryChecksum: actualHumanBinary,
      actualFixtureChecksum: actualHumanFixture,
    ),
    validateWindowsRuns(
      windowsRuns,
      expectedCommit: resolvedCandidate,
      requireRawEvidence: windowsRoot != null,
      hostManifest: windowsHost,
      actualHostManifestChecksum: windowsHostChecksum,
      actualBinaryChecksum: windowsBinaryChecksum,
      actualFixtureChecksum: windowsFixtureChecksum,
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

Future<String> _gitGrep(Directory repository, List<String> arguments) async {
  final result = await Process.run('git', <String>[
    'grep',
    ...arguments,
  ], workingDirectory: repository.path);
  if (result.exitCode == 1) return '';
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
  final result = Platform.isWindows
      ? await Process.run('certutil', <String>[
          '-hashfile',
          file.path,
          'SHA256',
        ])
      : await Process.run('shasum', <String>['-a', '256', file.path]);
  if (result.exitCode != 0) return null;
  for (final line in const LineSplitter().convert(result.stdout as String)) {
    final checksum = line.trim().toLowerCase();
    if (RegExp(r'^[0-9a-f]{64}$').hasMatch(checksum)) return checksum;
  }
  return null;
}

Future<Map<String, Object?>?> _readJsonObjectIfExists(File file) async {
  if (!file.existsSync()) return null;
  final decoded = jsonDecode(await file.readAsString());
  if (decoded is! Map) {
    throw FormatException('${file.path} must contain a JSON object.');
  }
  return decoded.cast<String, Object?>();
}

Future<List<Map<String, Object?>>> _readWindowsEvidence(
  String? rootPath,
) async {
  if (rootPath == null) return const <Map<String, Object?>>[];
  final root = Directory(rootPath);
  if (!root.existsSync()) return const <Map<String, Object?>>[];
  final records = <Map<String, Object?>>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is! File || entity.uri.pathSegments.last != 'manifest.json') {
      continue;
    }
    final manifest = await _readJsonObjectIfExists(entity);
    if (manifest == null) continue;
    final directory = entity.parent;
    final summaryFile = File('${directory.path}/summary.json');
    final framesFile = File('${directory.path}/frames.jsonl');
    final memoryFile = File('${directory.path}/memory_gc.jsonl');
    final logFile = File('${directory.path}/run.log');
    records.add(<String, Object?>{
      ...manifest,
      '_summary': await _readJsonObjectIfExists(summaryFile),
      '_derived': await deriveWindowsRawTelemetry(framesFile, memoryFile),
      '_raw_files_present':
          summaryFile.existsSync() &&
          framesFile.existsSync() &&
          memoryFile.existsSync() &&
          logFile.existsSync(),
    });
  }
  return records;
}

Future<Map<String, Object?>?> deriveWindowsRawTelemetry(
  File framesFile,
  File memoryFile,
) async {
  if (!framesFile.existsSync() || !memoryFile.existsSync()) return null;
  final frames = await _readJsonLines(framesFile);
  final memoryGc = await _readJsonLines(memoryFile);
  final totalSpans = <int>[];
  var severeStreak = 0;
  var maxSevereStreak = 0;
  var buildStreak = 0;
  var maxBuildStreak = 0;
  var rasterStreak = 0;
  var maxRasterStreak = 0;
  for (final frame in frames) {
    final total = _asInt(frame['total_span_us']);
    final build = _asInt(frame['build_us']);
    final raster = _asInt(frame['raster_us']);
    if (total == null || build == null || raster == null) return null;
    totalSpans.add(total);
    severeStreak = total > 33300 ? severeStreak + 1 : 0;
    buildStreak = build > 16600 ? buildStreak + 1 : 0;
    rasterStreak = raster > 16600 ? rasterStreak + 1 : 0;
    if (severeStreak > maxSevereStreak) maxSevereStreak = severeStreak;
    if (buildStreak > maxBuildStreak) maxBuildStreak = buildStreak;
    if (rasterStreak > maxRasterStreak) maxRasterStreak = rasterStreak;
  }
  totalSpans.sort();
  final percentileIndex = totalSpans.isEmpty
      ? null
      : ((totalSpans.length - 1) * 0.99).ceil();
  final memorySamples = memoryGc
      .where((record) => record['record_type'] == 'memory_sample')
      .map((record) => _asInt(record['rss_bytes']))
      .whereType<int>()
      .toList(growable: false);
  final gcStatuses = memoryGc
      .where((record) => record['record_type'] == 'gc_status')
      .map((record) => record['status']?.toString())
      .whereType<String>()
      .toList(growable: false);
  return <String, Object?>{
    'sampled_frames': totalSpans.length,
    'p99_total_span_ms': percentileIndex == null
        ? null
        : totalSpans[percentileIndex] / 1000,
    'max_consecutive_severe_frames': maxSevereStreak,
    'max_consecutive_build_over_budget': maxBuildStreak,
    'max_consecutive_raster_over_budget': maxRasterStreak,
    'rss_start_bytes': memorySamples.isEmpty ? null : memorySamples.first,
    'rss_end_bytes': memorySamples.isEmpty ? null : memorySamples.last,
    'gc_telemetry_status': gcStatuses.isEmpty ? null : gcStatuses.last,
  };
}

Future<List<Map<String, Object?>>> _readJsonLines(File file) async {
  final records = <Map<String, Object?>>[];
  for (final line in const LineSplitter().convert(await file.readAsString())) {
    if (line.trim().isEmpty) continue;
    final decoded = jsonDecode(line);
    if (decoded is! Map) {
      throw FormatException('${file.path} contains a non-object JSON line.');
    }
    records.add(decoded.cast<String, Object?>());
  }
  return records;
}
