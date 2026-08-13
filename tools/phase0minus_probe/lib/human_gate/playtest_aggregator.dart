import 'playtest_report.dart';

const phase0aHumanGateAssignments =
    <String, ({String order, int slot, String playerType})>{
      'P01': (order: 'AB', slot: 1, playerType: 'idle'),
      'P02': (order: 'BA', slot: 2, playerType: 'idle'),
      'P03': (order: 'AB', slot: 3, playerType: 'arpg'),
      'P04': (order: 'BA', slot: 4, playerType: 'arpg'),
      'P05': (order: 'AB', slot: 5, playerType: 'mixed'),
      'P06': (order: 'BA', slot: 6, playerType: 'mixed'),
    };

final class PlaytestAggregation {
  const PlaytestAggregation({required this.summary, required this.errors});

  final Map<String, Object?> summary;
  final List<String> errors;
  bool get isValid => errors.isEmpty;
}

PlaytestAggregation aggregatePlaytestReports(
  List<Map<String, Object?>> reports,
) {
  final errors = <String>[];
  final latestByParticipant = <String, Map<String, Object?>>{};
  final identityBySlot = <int, String>{};
  String? buildCommit;
  String? scenarioChecksum;

  for (var index = 0; index < reports.length; index++) {
    final report = reports[index];
    final validation = validatePlaytestReport(report);
    errors.addAll(validation.errors.map((error) => 'report[$index]: $error'));
    if (!validation.isValid) continue;
    final participant = report['participant_id']! as String;
    final slot = report['slot']! as int;
    final assignment = phase0aHumanGateAssignments[participant]!;
    if (report['order'] != assignment.order || slot != assignment.slot) {
      errors.add(
        '$participant must use ${assignment.order} in slot ${assignment.slot}',
      );
    }
    final previousSlotOwner = identityBySlot[slot];
    if (previousSlotOwner != null && previousSlotOwner != participant) {
      errors.add(
        'slot $slot assigned to both $previousSlotOwner and $participant',
      );
    }
    identityBySlot[slot] = participant;
    if (buildCommit != null && report['build_commit'] != buildCommit) {
      errors.add('mixed build_commit values');
    }
    if (scenarioChecksum != null &&
        report['scenario_checksum'] != scenarioChecksum) {
      errors.add('mixed scenario_checksum values');
    }
    buildCommit ??= report['build_commit']! as String;
    scenarioChecksum ??= report['scenario_checksum']! as String;
    final previous = latestByParticipant[participant];
    final serial = report['session_serial']! as int;
    final previousSerial = previous?['session_serial'] as int? ?? 0;
    if (previous == null ||
        serial > previousSerial ||
        (serial == previousSerial && report['replay_requested'] == true)) {
      latestByParticipant[participant] = report;
    }
  }

  final finalReports = latestByParticipant.values.toList()
    ..sort((a, b) => (a['slot']! as int).compareTo(b['slot']! as int));
  final ab = finalReports.where((report) => report['order'] == 'AB').length;
  final ba = finalReports.where((report) => report['order'] == 'BA').length;
  final victories = finalReports
      .where((report) => report['outcome'] == 'victory')
      .length;
  final replayRequests = finalReports
      .where((report) => report['replay_requested'] == true)
      .length;
  final totals = <String, int>{};
  for (final key in const [
    'basic_uses',
    'dash_uses',
    'gather_uses',
    'clear_uses',
    'break_successes',
    'kills',
  ]) {
    totals[key] = finalReports.fold<int>(
      0,
      (sum, report) => sum + ((report['actions']! as Map)[key] as int? ?? 0),
    );
  }
  final scheduleComplete =
      finalReports.length == 6 &&
      ab == 3 &&
      ba == 3 &&
      identityBySlot.length == 6;

  return PlaytestAggregation(
    errors: errors,
    summary: {
      'schema_version': 1,
      'participant_session_ids': [
        for (final report in finalReports) report['session_id'],
      ],
      'build_commit': buildCommit,
      'scenario_checksum': scenarioChecksum,
      'valid_report_count': finalReports.length,
      'order_counts': {'AB': ab, 'BA': ba},
      'schedule_complete': scheduleComplete,
      'victory_count': victories,
      'replay_requested_count': replayRequests,
      'action_totals': totals,
      'participants': [
        for (final report in finalReports)
          {
            'participant_id': report['participant_id'],
            'slot': report['slot'],
            'order': report['order'],
            'outcome': report['outcome'],
            'session_serial': report['session_serial'],
            'replay_requested': report['replay_requested'],
          },
      ],
      'mechanical_only': true,
      'human_gate_verdict': 'NOT_EVALUATED',
    },
  );
}
