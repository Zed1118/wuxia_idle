import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/human_gate/human_gate_aggregator.dart';
import 'package:phase0minus_probe/human_gate/human_session.dart';
import 'package:phase0minus_probe/human_gate/playtest_aggregator.dart';
import 'package:phase0minus_probe/human_gate/playtest_report.dart';

void main() {
  test('process exit status cannot turn a failed gate green', () {
    expect(humanGateProcessExitCode('HUMAN_GATE_PASS'), 0);
    expect(humanGateProcessExitCode('LOCAL_FAIL'), 1);
    expect(humanGateProcessExitCode('INCONCLUSIVE'), 2);
    expect(humanGateProcessExitCode('unexpected'), 70);
  });

  test('passes exactly on median, 4-of-6, 5-of-6, and 24-of-30 edges', () {
    final sessions = _passingSessions();
    sessions[5]['ratings'] = {
      'release': 3,
      'readability': 3,
      'active_intent': 3,
    };
    (sessions[5]['pairwise']! as Map)['verbal_replay_willing'] = false;
    (sessions[4]['pairwise']! as Map)['verbal_replay_willing'] = false;
    _setAppReplay(sessions[5], false);
    _setAppReplay(sessions[4], false);
    (sessions[5]['pairwise']! as Map)['clearly_better_than_production'] = false;
    (sessions[4]['pairwise']! as Map)['clearly_better_than_production'] = false;
    (sessions[5]['pairwise']! as Map)['qr_noninterchangeable_explained'] =
        false;
    ((sessions[5]['readability_trials']! as List)[0]
            as Map)['protagonist_within_1s'] =
        false;
    for (var participant = 0; participant < 6; participant++) {
      ((sessions[participant]['readability_trials']! as List)[0]
              as Map)['danger_correct'] =
          false;
    }

    final result = aggregateHumanGate(
      sessions,
      rawReports: _rawReports(sessions),
    );

    expect(result.verdict, 'HUMAN_GATE_PASS', reason: '${result.summary}');
    final metrics = result.summary['metrics']! as Map;
    expect(metrics['release_median'], 4);
    expect(metrics['verbal_replay_willing_count'], 4);
    expect(metrics['protagonist_all_five_count'], 5);
    expect(metrics['danger_correct_trials'], 24);
    expect(metrics['danger_total_trials'], 30);
  });

  test('returns inconclusive below six valid samples', () {
    final sessions = _passingSessions().take(5).toList();
    final result = aggregateHumanGate(
      sessions,
      rawReports: _rawReports(sessions),
    );

    expect(result.verdict, 'INCONCLUSIVE');
    expect(result.summary['valid_sample_count'], 5);
  });

  test('a direct veto defeats otherwise perfect scores', () {
    final sessions = _passingSessions();
    (sessions.first['direct_veto']! as Map)['density_20_plus_1_unreadable'] =
        true;

    final result = aggregateHumanGate(
      sessions,
      rawReports: _rawReports(sessions),
    );

    expect(result.verdict, 'LOCAL_FAIL');
    expect(
      result.summary['direct_vetos'] as List,
      contains('P01:density_20_plus_1_unreadable'),
    );
  });

  test('fails at 3-of-6, 4-of-6 readability, and 23-of-30 danger', () {
    final sessions = _passingSessions();
    for (var index = 3; index < 6; index++) {
      _setAppReplay(sessions[index], false);
    }
    for (var index = 4; index < 6; index++) {
      ((sessions[index]['readability_trials']! as List)[0]
              as Map)['protagonist_within_1s'] =
          false;
    }
    for (var index = 0; index < 7; index++) {
      final participant = index ~/ 5;
      final frame = index % 5;
      ((sessions[participant]['readability_trials']! as List)[frame]
              as Map)['danger_correct'] =
          false;
    }

    final result = aggregateHumanGate(
      sessions,
      rawReports: _rawReports(sessions),
    );
    final checks = result.summary['checks']! as Map;

    expect(result.verdict, 'LOCAL_FAIL');
    expect(checks['clicked_replay_4_of_6'], isFalse);
    expect(checks['protagonist_5_of_6'], isFalse);
    expect(checks['danger_24_of_30'], isFalse);
  });

  test('validator rejects bad rating, trial count, PII, and validity lie', () {
    final session = _session(1)
      ..['name'] = 'forbidden'
      ..['ratings'] = {'release': 0, 'readability': 6, 'active_intent': 4}
      ..['readability_trials'] = <Object?>[];
    (session['integrity']! as Map)['same_package'] = false;

    final validation = validateHumanSession(session);
    final errors = validation.errors.join('\n');

    expect(validation.isValid, isFalse);
    expect(errors, contains('forbidden identity key name'));
    expect(errors, contains('ratings.release'));
    expect(errors, contains('ratings.readability'));
    expect(errors, contains('exactly 5'));
    expect(errors, contains('contradicts integrity'));
  });

  test('defeat retry cannot count as app replay intent', () {
    final session = _session(1);
    session['mechanical_evidence'] = {
      'raw_report_run_id': 'run-p01',
      'terminal_outcome': 'defeat',
      'replay_clicked_after_victory': true,
    };

    final validation = validateHumanSession(session);

    expect(validation.isValid, isFalse);
    expect(
      validation.errors,
      contains('app replay intent must be a click after victory'),
    );
  });

  test('duplicate participant collapses the gate to inconclusive', () {
    final sessions = _passingSessions();
    final duplicate = _session(1);
    duplicate['participant_session_id'] = 'session-duplicate';
    sessions.add(duplicate);
    final rawReports = _rawReports(sessions);

    final result = aggregateHumanGate(sessions, rawReports: rawReports);

    expect(result.verdict, 'INCONCLUSIVE');
    final errors = result.summary['schema_errors'] as List;
    expect(errors, contains('duplicate participant P01'));
  });

  test('missing linked raw report collapses the gate to inconclusive', () {
    final sessions = _passingSessions();
    final rawReports = _rawReports(sessions);
    (sessions.first['mechanical_evidence']! as Map)['raw_report_run_id'] =
        'nonexistent-run-id';

    final result = aggregateHumanGate(sessions, rawReports: rawReports);

    expect(result.verdict, 'INCONCLUSIVE');
    final errors = result.summary['schema_errors'] as List;
    expect(
      errors.any((e) => (e as String).contains('missing linked raw report')),
      isTrue,
    );
  });

  test('rejects mixed package and frozen schedule violation', () {
    final sessions = _passingSessions();
    sessions[1]['package_id'] = 'another-package';
    sessions[2]['order'] = 'BA';

    final result = aggregateHumanGate(
      sessions,
      rawReports: _rawReports(sessions),
    );
    final errors = result.summary['schema_errors'] as List;

    expect(result.verdict, 'INCONCLUSIVE');
    expect(errors, contains('mixed package_id'));
    expect(errors, contains('P03 violates frozen AB/BA schedule'));
  });
}

List<Map<String, Object?>> _passingSessions() => [
  for (var slot = 1; slot <= 6; slot++) _session(slot),
];

Map<String, Object?> _session(int slot) {
  final participant = 'P${slot.toString().padLeft(2, '0')}';
  final assignment = phase0aHumanGateAssignments[participant]!;
  return {
    'schema': phase0aHumanSessionSchema,
    'study_id': 'phase0a-gate-v1',
    'package_id': 'package-01234567',
    'participant_id': participant,
    'participant_session_id': 'session-p${slot.toString().padLeft(2, '0')}',
    'player_type': assignment.playerType,
    'order': assignment.order,
    'slot': assignment.slot,
    'ratings': {'release': 4, 'readability': 4, 'active_intent': 4},
    'pairwise': {
      'verbal_replay_willing': true,
      'app_replay_clicked': true,
      'clearly_better_than_production': true,
      'qr_noninterchangeable_explained': true,
    },
    'mechanical_evidence': {
      'raw_report_run_id': 'run-p${slot.toString().padLeft(2, '0')}',
      'terminal_outcome': 'victory',
      'replay_clicked_after_victory': true,
    },
    'core_action_roles': {'dash': true, 'gather': true, 'break': true},
    'readability_trials': [
      for (var frame = 1; frame <= 5; frame++)
        {
          'frame': frame,
          'stimulus_id': phase0aReadabilityStimulusIds[frame - 1],
          'sha256': phase0aReadabilityStimulusHashes[frame - 1],
          'protagonist_within_1s': true,
          'danger_correct': true,
        },
    ],
    'observations': {
      'frequently_lost_protagonist': false,
      'frequently_lost_danger': false,
      'single_skill_judged_optimal': false,
    },
    'integrity': {
      'completed_three_waves': true,
      'implementer_assisted': false,
      'same_package': true,
      'optimal_answer_disclosed_before_run': false,
      'external_event_polluted': false,
      'questionnaire_complete': true,
      'participant_had_input_control': true,
      'facilitator_is_primary_implementer': false,
      'app_overlap': false,
      'scheduled_order_followed': true,
      'comparison_continue_pressed': false,
      'stimulus_hashes_verified': true,
      'stimulus_rewatch': false,
    },
    'direct_veto': {
      'stationary_or_cooldown_only_is_optimal': false,
      'two_core_actions_lack_role': false,
      'density_20_plus_1_unreadable': false,
      'spectacle_not_grouping_or_timing': false,
      'requires_forbidden_mechanic': false,
      'production_storage_or_reward_touched': false,
      'mac_performance_unrecoverable': false,
    },
    'validity': {'valid': true, 'invalid_reasons': <String>[]},
  };
}

List<Map<String, Object?>> _rawReports(List<Map<String, Object?>> sessions) => [
  for (final session in sessions)
    {
      'run_id': (session['mechanical_evidence']! as Map)['raw_report_run_id'],
      'participant_id': session['participant_id'],
      'session_id': session['participant_session_id'],
      'build_commit': session['package_id'],
      'outcome': (session['mechanical_evidence']! as Map)['terminal_outcome'],
      'replay_requested':
          (session['mechanical_evidence']!
              as Map)['replay_clicked_after_victory'],
      'schema_version': phase0aHumanGateSchemaVersion,
      'order': session['order'],
      'slot': session['slot'],
      'scenario_checksum': 'scenario-checksum',
      'platform': 'macos',
      'logical_viewport': {'width': 1280.0, 'height': 720.0},
      'elapsed_seconds': 100.0,
      'peak_active_enemies': 21,
      'actions': {
        'basic_uses': 1,
        'dash_uses': 1,
        'gather_uses': 1,
        'clear_uses': 1,
        'break_successes': 1,
        'kills': 51,
        'maximum_chain': 10,
      },
      'session_serial': 1,
    },
];

void _setAppReplay(Map<String, Object?> session, bool clicked) {
  (session['pairwise']! as Map)['app_replay_clicked'] = clicked;
  (session['mechanical_evidence']! as Map)['replay_clicked_after_victory'] =
      clicked;
}
