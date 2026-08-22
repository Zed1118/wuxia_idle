import 'package:flutter_test/flutter_test.dart';

import '../../tool/route_c_gate_preflight.dart';

void main() {
  const commit = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const checksum =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

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

  test('human package binds sessions to returned executable and fixture', () {
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
      contains('human package executable checksum mismatch'),
    );
  });

  test('Windows gate requires root app, two viewports and three runs each', () {
    final runs = <Map<String, Object?>>[
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
            'minimum_spec_attested': true,
            'local_console': true,
            'composite_gate': 'PASS',
          },
    ];
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
