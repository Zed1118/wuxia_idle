import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/route_c_gate_preflight.dart';

void main() {
  const commit = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const checksum =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

  test('SHA-256 parser accepts shasum and certutil output formats', () {
    expect(parseSha256Output('$checksum  package/wuxia_idle\n'), checksum);
    expect(
      parseSha256Output('SHA256 hash of file:\n$checksum\nCertUtil: OK\n'),
      checksum,
    );
    expect(parseSha256Output('not a checksum\n'), isNull);
  });

  test('candidate tree rejects every non-Phase0A battle source', () {
    expect(
      validateRouteCDeletionTree(const <String>[
        'lib/features/battle/domain/phase0a/reducer.dart',
        'lib/features/battle/domain/battle_state.dart',
      ]).state,
      GateState.invalid,
    );
    expect(
      validateRouteCDeletionTree(const <String>[
        'lib/features/battle/domain/phase0a/reducer.dart',
        'lib/features/battle/presentation/phase0a/screen.dart',
      ]).state,
      GateState.pass,
    );
  });

  test('candidate consumer audit rejects retired imports and gates', () {
    expect(validateRouteCConsumerViolations('').state, GateState.pass);
    final failed = validateRouteCConsumerViolations(
      'lib/features/mainline/x.dart:4:import battle_state.dart',
    );
    expect(failed.state, GateState.invalid);
    expect(failed.details.join('\n'), contains('battle_state.dart'));
  });

  test(
    'human gate requires six unique valid sessions on one candidate binary',
    () {
      final sessions = List<Map<String, Object?>>.generate(
        6,
        (index) => _humanSession(index, commit, checksum),
      );
      expect(
        validateHumanSessions(sessions, expectedCommit: commit).state,
        GateState.pass,
      );
      sessions.last['commit'] = 'wrong';
      expect(
        validateHumanSessions(sessions, expectedCommit: commit).state,
        GateState.invalid,
      );
    },
  );

  test(
    'human gate distinguishes local threshold failure from bad evidence',
    () {
      final sessions = List<Map<String, Object?>>.generate(
        6,
        (index) => _humanSession(index, commit, checksum),
      );
      for (var index = 0; index < 2; index++) {
        (sessions[index]['mechanics']!
                as Map<String, Object?>)['charge_warning_seen'] =
            false;
      }

      final aggregation = aggregateRouteCHumanGate(
        sessions,
        expectedCommit: commit,
      );

      expect(aggregation.verdict, 'LOCAL_FAIL');
      expect(aggregation.summary['schema_errors'], isEmpty);
      expect(
        (aggregation.summary['checks']! as Map)['charge_warning_seen_5_of_6'],
        isFalse,
      );
    },
  );

  test('human gate rejects PII, mixed fixture and unbalanced viewports', () {
    final sessions = List<Map<String, Object?>>.generate(
      6,
      (index) => _humanSession(index, commit, checksum),
    );
    sessions.first['name'] = 'forbidden';
    sessions.last['fixture_sha256'] =
        'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
    sessions.last['viewport'] = '1280x720';

    final aggregation = aggregateRouteCHumanGate(
      sessions,
      expectedCommit: commit,
    );
    final errors = (aggregation.summary['schema_errors']! as List).join('\n');

    expect(aggregation.verdict, 'INCONCLUSIVE');
    expect(errors, contains('forbidden identity key name'));
    expect(errors, contains('mix multiple production fixtures'));
    expect(errors, contains('1440x900 requires 3 human sessions'));
  });

  test('human package binds sessions to returned AOT payload and fixture', () {
    final sessions = List<Map<String, Object?>>.generate(
      6,
      (index) => _humanSession(index, commit, checksum),
    );
    final manifest = <String, Object?>{
      'schema': 'route-c-human-package-v1',
      'commit': commit,
      'app_package': 'wuxia_idle',
      'route_id': routeCProductionRoute,
      'binary_sha256': checksum,
      'fixture_sha256': checksum,
    };

    expect(
      validateHumanEvidence(
        sessions,
        <Map<String, Object?>>[manifest],
        expectedCommit: commit,
        actualBinaryChecksum: checksum,
        actualFixtureChecksum: checksum,
      ).state,
      GateState.pass,
    );
    expect(
      validateHumanEvidence(
        sessions,
        <Map<String, Object?>>[manifest],
        expectedCommit: commit,
        actualBinaryChecksum:
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
        actualFixtureChecksum: checksum,
      ).details,
      contains('human package AOT payload checksum mismatch'),
    );
  });

  test('prepared human package remains pending until templates are filled', () {
    final sessions = List<Map<String, Object?>>.generate(
      6,
      (index) => _unfilledHumanSession(index, commit, checksum),
    );
    final manifest = <String, Object?>{
      'schema': 'route-c-human-package-v1',
      'commit': commit,
      'app_package': 'wuxia_idle',
      'route_id': routeCProductionRoute,
      'binary_sha256': checksum,
      'fixture_sha256': checksum,
    };

    expect(
      validateHumanEvidence(
        sessions,
        <Map<String, Object?>>[manifest],
        expectedCommit: commit,
        actualBinaryChecksum: checksum,
        actualFixtureChecksum: checksum,
      ).state,
      GateState.pending,
    );

    sessions.first['schema'] = 'corrupt-template';
    expect(
      validateHumanEvidence(
        sessions,
        <Map<String, Object?>>[manifest],
        expectedCommit: commit,
        actualBinaryChecksum: checksum,
        actualFixtureChecksum: checksum,
      ).state,
      GateState.invalid,
    );
  });

  test('Windows gate requires root app, two viewports and three runs each', () {
    final runs = _windowsRuns(commit, checksum);
    expect(
      validateWindowsRuns(runs, expectedCommit: commit).state,
      GateState.pass,
    );
    runs.last['app_package'] = 'phase0minus_probe';
    expect(
      validateWindowsRuns(runs, expectedCommit: commit).state,
      GateState.invalid,
    );
  });

  test('Windows gate re-derives raw telemetry and validates host facts', () {
    final runs = _windowsRuns(commit, checksum);
    _addValidRawEvidence(runs);
    final host = _windowsHost();

    expect(
      validateWindowsRuns(
        runs,
        expectedCommit: commit,
        requireRawEvidence: true,
        hostManifest: host,
        actualHostManifestChecksum: checksum,
        actualBinaryChecksum: checksum,
        actualFixtureChecksum: checksum,
      ).state,
      GateState.pass,
    );
    (runs.first['_derived']! as Map<String, Object?>)['sampled_frames'] = 1;
    final failed = validateWindowsRuns(
      runs,
      expectedCommit: commit,
      requireRawEvidence: true,
      hostManifest: host,
      actualHostManifestChecksum: checksum,
      actualBinaryChecksum: checksum,
      actualFixtureChecksum: checksum,
    );
    expect(failed.state, GateState.invalid);
    expect(
      failed.details.join('\n'),
      contains('raw telemetry fails the composite thresholds'),
    );
  });

  test(
    'Windows physical gate accepts recorded discrete-GPU host, rejects RDP',
    () {
      final runs = _windowsRuns(commit, checksum);
      _addValidRawEvidence(runs);
      final host = _windowsHost();

      final passed = validateWindowsRuns(
        runs,
        expectedCommit: commit,
        requireRawEvidence: true,
        hostManifest: host,
        actualHostManifestChecksum: checksum,
        actualBinaryChecksum: checksum,
        actualFixtureChecksum: checksum,
      );
      expect(passed.state, GateState.pass);

      (host['session']! as Map<String, Object?>)['remote_desktop'] = true;
      final failed = validateWindowsRuns(
        runs,
        expectedCommit: commit,
        requireRawEvidence: true,
        hostManifest: host,
        actualHostManifestChecksum: checksum,
        actualBinaryChecksum: checksum,
        actualFixtureChecksum: checksum,
      );
      expect(failed.state, GateState.invalid);
      expect(
        failed.details,
        contains(
          'Windows host manifest fails physical-host/local-console rules',
        ),
      );
    },
  );

  test('Windows raw parser derives percentile, streak, GC and RSS', () async {
    final directory = await Directory.systemTemp.createTemp(
      'route-c-windows-raw-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final frames = File('${directory.path}/frames.jsonl');
    final memory = File('${directory.path}/memory_gc.jsonl');
    await frames.writeAsString(
      '${<String>['{"build_us":1000,"raster_us":1000,"total_span_us":10000}', '{"build_us":17000,"raster_us":1000,"total_span_us":33301}', '{"build_us":18000,"raster_us":1000,"total_span_us":34000}'].join('\n')}\n',
    );
    await memory.writeAsString(
      '${<String>['{"record_type":"memory_sample","rss_bytes":100}', '{"record_type":"memory_sample","rss_bytes":110}', '{"record_type":"gc_status","status":"GC_TELEMETRY_COLLECTED"}'].join('\n')}\n',
    );

    final derived = await deriveWindowsRawTelemetry(frames, memory);

    expect(derived?['sampled_frames'], 3);
    expect(derived?['p99_total_span_ms'], 34.0);
    expect(derived?['max_consecutive_severe_frames'], 2);
    expect(derived?['max_consecutive_build_over_budget'], 2);
    expect(derived?['rss_start_bytes'], 100);
    expect(derived?['rss_end_bytes'], 110);
    expect(derived?['gc_telemetry_status'], 'GC_TELEMETRY_COLLECTED');
  });

  test('raw parser derives RSS from samples after the warmup marker', () async {
    final directory = await Directory.systemTemp.createTemp(
      'route-c-windows-warmup-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final frames = File('${directory.path}/frames.jsonl');
    final memory = File('${directory.path}/memory_gc.jsonl');
    await frames.writeAsString(
      '{"build_us":400,"raster_us":600,"total_span_us":1000}\n',
    );
    await memory.writeAsString(
      '${<String>['{"record_type":"memory_sample","rss_bytes":100,"gate_eligible":false}', '{"record_type":"memory_sample","rss_bytes":240,"gate_eligible":true}', '{"record_type":"memory_sample","rss_bytes":260,"gate_eligible":true}', '{"record_type":"gc_status","status":"GC_TELEMETRY_COLLECTED"}'].join('\n')}\n',
    );

    final derived = await deriveWindowsRawTelemetry(frames, memory);

    expect(derived?['rss_start_bytes'], 240);
    expect(derived?['rss_end_bytes'], 260);
  });

  test('missing external evidence is pending, never pass', () {
    expect(
      validateHumanSessions(
        const <Map<String, Object?>>[],
        expectedCommit: commit,
      ).state,
      GateState.pending,
    );
    expect(
      validateWindowsRuns(
        const <Map<String, Object?>>[],
        expectedCommit: commit,
      ).state,
      GateState.pending,
    );
  });
}

Map<String, Object?> _humanSession(
  int index,
  String commit,
  String checksum,
) => <String, Object?>{
  'schema': routeCHumanSessionSchema,
  'session_id': 'route-c-p${index + 1}-session',
  'participant_id': 'P0${index + 1}',
  'commit': commit,
  'binary_sha256': checksum,
  'fixture_sha256': checksum,
  'route_id': routeCProductionRoute,
  'viewport': index < 3 ? '1280x720' : '1440x900',
  'player_type': const <String>['idle', 'arpg', 'mixed'][index % 3],
  'ratings': <String, Object?>{
    'release': 4,
    'readability': 4,
    'active_intent': 4,
  },
  'replay_willing': true,
  'mechanics': <String, Object?>{
    'charge_warning_seen': true,
    'interrupt_feedback_understood': true,
    'stagger_seen': true,
    'vulnerability_window_understood': true,
    'keyboard_mouse_completed': true,
    'no_layout_overflow_or_hang': true,
  },
  'direct_veto': <String, Object?>{
    'stationary_or_cooldown_only_is_optimal': false,
    'two_core_actions_lack_role': false,
    'density_unreadable': false,
    'requires_forbidden_mechanic': false,
  },
  'integrity': <String, Object?>{
    'completed_three_waves': true,
    'participant_had_input_control': true,
    'implementer_assisted': false,
    'external_event_polluted': false,
    'questionnaire_complete': true,
  },
  'validity': <String, Object?>{'valid': true, 'invalid_reasons': <String>[]},
};

Map<String, Object?> _unfilledHumanSession(
  int index,
  String commit,
  String checksum,
) {
  final session = _humanSession(index, commit, checksum);
  session['ratings'] = <String, Object?>{
    'release': 1,
    'readability': 1,
    'active_intent': 1,
  };
  session['replay_willing'] = false;
  session['mechanics'] = <String, Object?>{
    'charge_warning_seen': false,
    'interrupt_feedback_understood': false,
    'stagger_seen': false,
    'vulnerability_window_understood': false,
    'keyboard_mouse_completed': false,
    'no_layout_overflow_or_hang': false,
  };
  session['integrity'] = <String, Object?>{
    'completed_three_waves': false,
    'participant_had_input_control': false,
    'implementer_assisted': false,
    'external_event_polluted': false,
    'questionnaire_complete': false,
  };
  session['validity'] = <String, Object?>{
    'valid': false,
    'invalid_reasons': <String>['NOT_FILLED'],
  };
  return session;
}

List<Map<String, Object?>> _windowsRuns(String commit, String checksum) =>
    <Map<String, Object?>>[
      for (final viewport in const <String>['1280x720', '1440x900'])
        for (var index = 1; index <= 3; index++)
          <String, Object?>{
            'schema': routeCWindowsRunSchema,
            'run_id': '$viewport-$index',
            'app_package': 'wuxia_idle',
            'route_id': routeCProductionProfileRoute,
            'commit': commit,
            'binary_sha256': checksum,
            'fixture_sha256': checksum,
            'host_manifest_sha256': checksum,
            'viewport': viewport,
            'windows_physical_attested': true,
            'local_console': true,
            'renderer': 'impeller-d3d',
            'composite_gate': 'PASS',
          },
    ];

void _addValidRawEvidence(List<Map<String, Object?>> runs) {
  for (final run in runs) {
    final viewport = (run['viewport']! as String).split('x');
    run['_raw_files_present'] = true;
    run['raw_evidence'] = <String, Object?>{
      'frames_jsonl': 'frames.jsonl',
      'memory_gc_jsonl': 'memory_gc.jsonl',
      'summary_json': 'summary.json',
      'run_log': 'run.log',
    };
    run['_summary'] = <String, Object?>{
      'schema': 'route-c-production-profile-summary-v1',
      'run_id': run['run_id'],
      'sample_seconds': 60,
      'warmup_seconds': 12,
      'cooldown_seconds': 30,
      'sampled_frames': 3600,
      'p99_total_span_ms': 10.0,
      'max_consecutive_severe_frames': 0,
      'frame_streak_gate_passes': true,
      'gc_telemetry_status': 'GC_TELEMETRY_COLLECTED',
      'logical_width': int.parse(viewport[0]),
      'logical_height': int.parse(viewport[1]),
      'device_pixel_ratio': 1.0,
      'rss_start_bytes': 100000000,
      'rss_end_bytes': 110000000,
    };
    run['_derived'] = <String, Object?>{
      'sampled_frames': 3600,
      'p99_total_span_ms': 10.0,
      'max_consecutive_severe_frames': 0,
      'max_consecutive_build_over_budget': 0,
      'max_consecutive_raster_over_budget': 0,
      'gc_telemetry_status': 'GC_TELEMETRY_COLLECTED',
      'rss_start_bytes': 100000000,
      'rss_end_bytes': 110000000,
    };
  }
}

Map<String, Object?> _windowsHost() => <String, Object?>{
  'status': 'RECORDED',
  'device': <String, Object?>{
    'os_caption': 'Windows 11 Pro',
    'os_version': '10.0.26200',
    'os_build': '26200',
    'cpu_model': 'AMD Ryzen 7 5800X',
    'gpu_name': 'NVIDIA GeForce RTX 4070 SUPER',
    'gpu_driver_version': '32.0.16.1062',
    'ram_gib': 16,
    'storage_type': 'SSD',
    'power_mode': 'High performance',
    'plugged_in': true,
  },
  'display': <String, Object?>{
    'refresh_rate_hz': 143,
    'scale_percent': 100,
    'required_logical_viewports': <String>['1280x720', '1440x900'],
    'local_interactive_session': true,
  },
  'session': <String, Object?>{
    'session_name': 'Console',
    'remote_desktop': false,
    'virtual_machine': false,
  },
  'runtime': <String, Object?>{'renderer': 'impeller-d3d'},
  'attestation': <String, Object?>{
    'valid_for_windows_physical_gate': true,
    'physical_machine_confirmed': true,
    'local_console_confirmed': true,
    'power_mode_confirmed_best_performance': true,
  },
};
