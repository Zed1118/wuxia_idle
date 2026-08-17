import 'human_session.dart';
import 'playtest_aggregator.dart';
import 'playtest_report.dart';

final class HumanGateAggregation {
  const HumanGateAggregation({required this.verdict, required this.summary});

  final String verdict;
  final Map<String, Object?> summary;
}

int humanGateProcessExitCode(String verdict) => switch (verdict) {
  'HUMAN_GATE_PASS' => 0,
  'LOCAL_FAIL' => 1,
  'INCONCLUSIVE' => 2,
  _ => 70,
};

HumanGateAggregation aggregateHumanGate(
  List<Map<String, Object?>> sessions, {
  List<Map<String, Object?>> rawReports = const [],
  List<String> executionEvidenceErrors = const [],
  String? expectedPackageId,
  String? expectedScenarioChecksum,
}) {
  final schemaErrors = <String>[...executionEvidenceErrors];
  final valid = <Map<String, Object?>>[];
  final seenParticipants = <String>{};
  final seenSlots = <int>{};
  String? studyId;
  String? packageId;
  String? scenarioChecksum;
  final rawByRunId = <String, Map<String, Object?>>{
    for (final report in rawReports)
      if (report['run_id'] is String) report['run_id']! as String: report,
  };
  for (var index = 0; index < rawReports.length; index++) {
    final validation = validatePlaytestReport(rawReports[index]);
    schemaErrors.addAll(
      validation.errors.map((error) => 'raw_report[$index]: $error'),
    );
  }
  for (var index = 0; index < sessions.length; index++) {
    final session = sessions[index];
    final validation = validateHumanSession(session);
    if (!validation.isValid) {
      schemaErrors.addAll(
        validation.errors.map((error) => 'session[$index]: $error'),
      );
      continue;
    }
    final participant = session['participant_id']! as String;
    final slot = session['slot']! as int;
    final assignment = phase0aHumanGateAssignments[participant]!;
    if (assignment.order != session['order'] ||
        assignment.slot != slot ||
        assignment.playerType != session['player_type']) {
      schemaErrors.add('$participant violates frozen AB/BA schedule');
      continue;
    }
    if (!seenParticipants.add(participant)) {
      schemaErrors.add('duplicate participant $participant');
      continue;
    }
    if (!seenSlots.add(slot)) {
      schemaErrors.add('duplicate slot $slot');
      continue;
    }
    studyId ??= session['study_id']! as String;
    packageId ??= session['package_id']! as String;
    if (session['study_id'] != studyId) {
      schemaErrors.add('mixed study_id');
      continue;
    }
    if (session['package_id'] != packageId) {
      schemaErrors.add('mixed package_id');
      continue;
    }
    if (expectedPackageId != null &&
        session['package_id'] != expectedPackageId) {
      schemaErrors.add('$participant package_id does not match MANIFEST');
      continue;
    }
    final mechanical = session['mechanical_evidence']! as Map;
    final rawRunId = mechanical['raw_report_run_id']! as String;
    final raw = rawByRunId[rawRunId];
    if (raw == null) {
      schemaErrors.add('$participant missing linked raw report $rawRunId');
      continue;
    }
    final clickedAfterVictory =
        raw['outcome'] == 'victory' && raw['replay_requested'] == true;
    if (raw['participant_id'] != participant ||
        raw['session_id'] != session['participant_session_id'] ||
        raw['build_commit'] != session['package_id'] ||
        raw['order'] != session['order'] ||
        raw['slot'] != session['slot'] ||
        raw['outcome'] != mechanical['terminal_outcome'] ||
        clickedAfterVictory != mechanical['replay_clicked_after_victory'] ||
        clickedAfterVictory !=
            ((session['pairwise']! as Map)['app_replay_clicked'] == true)) {
      schemaErrors.add(
        '$participant mechanical evidence does not match raw report',
      );
      continue;
    }
    final viewport = raw['logical_viewport'];
    if (raw['platform'] != 'macos' ||
        viewport is! Map ||
        (viewport['width'] as num?)?.round() != 1280 ||
        (viewport['height'] as num?)?.round() != 720) {
      schemaErrors.add('$participant did not use the frozen Mac viewport');
      continue;
    }
    scenarioChecksum ??= raw['scenario_checksum'] as String?;
    if (raw['scenario_checksum'] != scenarioChecksum) {
      schemaErrors.add('mixed scenario_checksum');
      continue;
    }
    if (expectedScenarioChecksum != null &&
        raw['scenario_checksum'] != expectedScenarioChecksum) {
      schemaErrors.add(
        '$participant scenario checksum does not match MANIFEST',
      );
      continue;
    }
    final validity = session['validity']! as Map;
    if (validity['valid'] == true) valid.add(session);
  }

  final directVetos = <String>[];
  for (final session in valid) {
    final veto = session['direct_veto']! as Map;
    for (final entry in veto.entries) {
      if (entry.value == true) {
        directVetos.add('${session['participant_id']}:${entry.key}');
      }
    }
  }
  final metrics = <String, Object?>{
    'release_median': _median(valid, 'release'),
    'readability_median': _median(valid, 'readability'),
    'active_intent_median': _median(valid, 'active_intent'),
    'verbal_replay_willing_count': _countNested(
      valid,
      'pairwise',
      'verbal_replay_willing',
    ),
    'app_replay_clicked_count': _countNested(
      valid,
      'pairwise',
      'app_replay_clicked',
    ),
    'clearly_better_count': _countNested(
      valid,
      'pairwise',
      'clearly_better_than_production',
    ),
    'all_three_roles_count': valid.where((session) {
      final roles = session['core_action_roles']! as Map;
      return roles['dash'] == true &&
          roles['gather'] == true &&
          roles['break'] == true;
    }).length,
    'qr_noninterchangeable_count': _countNested(
      valid,
      'pairwise',
      'qr_noninterchangeable_explained',
    ),
    'protagonist_all_five_count': valid.where((session) {
      final trials = session['readability_trials']! as List;
      return trials.every(
        (trial) => (trial as Map)['protagonist_within_1s'] == true,
      );
    }).length,
    'danger_correct_trials': valid.fold<int>(0, (sum, session) {
      final trials = session['readability_trials']! as List;
      return sum +
          trials
              .where((trial) => (trial as Map)['danger_correct'] == true)
              .length;
    }),
    'danger_total_trials': valid.length * 5,
    'frequently_lost_protagonist_count': _countNested(
      valid,
      'observations',
      'frequently_lost_protagonist',
    ),
    'frequently_lost_danger_count': _countNested(
      valid,
      'observations',
      'frequently_lost_danger',
    ),
    'single_skill_optimal_count': _countNested(
      valid,
      'observations',
      'single_skill_judged_optimal',
    ),
    'completed_unassisted_count': valid.where((session) {
      final integrity = session['integrity']! as Map;
      return integrity['completed_three_waves'] == true &&
          integrity['implementer_assisted'] == false;
    }).length,
  };

  final enough =
      valid.length == 6 &&
      schemaErrors.isEmpty &&
      seenParticipants.length == 6 &&
      seenSlots.length == 6;
  final passChecks = <String, bool>{
    'three_medians_at_least_4':
        _number(metrics, 'release_median') >= 4 &&
        _number(metrics, 'readability_median') >= 4 &&
        _number(metrics, 'active_intent_median') >= 4,
    'verbal_replay_4_of_6': metrics['verbal_replay_willing_count'] as int >= 4,
    'clicked_replay_4_of_6': metrics['app_replay_clicked_count'] as int >= 4,
    'clearly_better_4_of_6': metrics['clearly_better_count'] as int >= 4,
    'all_three_roles_4_of_6': metrics['all_three_roles_count'] as int >= 4,
    'protagonist_5_of_6': metrics['protagonist_all_five_count'] as int >= 5,
    'danger_24_of_30':
        metrics['danger_total_trials'] == 30 &&
        (metrics['danger_correct_trials'] as int) >= 24,
    'qr_explained_5_of_6': metrics['qr_noninterchangeable_count'] as int >= 5,
    'lost_protagonist_below_4':
        (metrics['frequently_lost_protagonist_count'] as int) < 4,
    'lost_danger_below_4': (metrics['frequently_lost_danger_count'] as int) < 4,
    'single_skill_below_4': (metrics['single_skill_optimal_count'] as int) < 4,
    'completed_unassisted_5_of_6':
        (metrics['completed_unassisted_count'] as int) >= 5,
    'no_direct_veto': directVetos.isEmpty,
  };
  final verdict = !enough
      ? 'INCONCLUSIVE'
      : passChecks.values.every((passed) => passed)
      ? 'HUMAN_GATE_PASS'
      : 'LOCAL_FAIL';
  return HumanGateAggregation(
    verdict: verdict,
    summary: {
      'schema': 'phase0a-human-gate-summary-v1',
      'study_id': studyId,
      'package_id': packageId,
      'verdict': verdict,
      'valid_sample_count': valid.length,
      'schema_errors': schemaErrors,
      'direct_vetos': directVetos,
      'metrics': metrics,
      'checks': passChecks,
    },
  );
}

double _median(List<Map<String, Object?>> sessions, String key) {
  if (sessions.isEmpty) return 0;
  final values =
      sessions
          .map(
            (session) => ((session['ratings']! as Map)[key] as int).toDouble(),
          )
          .toList()
        ..sort();
  final middle = values.length ~/ 2;
  return values.length.isOdd
      ? values[middle]
      : (values[middle - 1] + values[middle]) / 2;
}

int _countNested(
  List<Map<String, Object?>> sessions,
  String group,
  String key,
) => sessions.where((session) => (session[group]! as Map)[key] == true).length;

double _number(Map<String, Object?> metrics, String key) =>
    (metrics[key]! as num).toDouble();
