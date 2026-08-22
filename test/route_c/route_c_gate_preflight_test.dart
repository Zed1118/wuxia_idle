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
        (index) => <String, Object?>{
          'schema': routeCHumanSessionSchema,
          'participant_id': 'P0${index + 1}',
          'commit': commit,
          'binary_sha256': checksum,
          'route_id': routeCProductionRoute,
          'mechanics': <String, Object?>{
            'charge_warning_seen': true,
            'interrupt_feedback_understood': true,
            'stagger_seen': true,
            'vulnerability_window_understood': true,
            'keyboard_mouse_completed': true,
            'no_layout_overflow_or_hang': true,
          },
          'validity': <String, Object?>{'valid': true},
        },
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

  test('Windows gate requires root app, two viewports and three runs each', () {
    final runs = <Map<String, Object?>>[
      for (final viewport in const <String>['1280x720', '1440x900'])
        for (var index = 1; index <= 3; index++)
          <String, Object?>{
            'schema': routeCWindowsRunSchema,
            'run_id': '$viewport-$index',
            'app_package': 'wuxia_idle',
            'route_id': routeCProductionRoute,
            'commit': commit,
            'binary_sha256': checksum,
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
