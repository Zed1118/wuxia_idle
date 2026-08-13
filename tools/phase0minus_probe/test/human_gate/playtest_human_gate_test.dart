import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/human_gate/playtest_aggregator.dart';
import 'package:phase0minus_probe/human_gate/playtest_identity.dart';
import 'package:phase0minus_probe/human_gate/playtest_report.dart';

void main() {
  test('accepts the two legal order boundaries', () {
    expect(
      PlaytestIdentity.fromEnvironment(_environment('P01', 'AB', 1)).toJson(),
      containsPair('order', 'AB'),
    );
    expect(
      PlaytestIdentity.fromEnvironment(_environment('P06', 'BA', 6)).toJson(),
      containsPair('slot', 6),
    );
  });

  test('rejects missing, identifying, and out-of-bound metadata', () {
    expect(
      () => PlaytestIdentity.fromEnvironment(_environment('P00', 'AB', 0)),
      throwsFormatException,
    );
    expect(
      () => PlaytestIdentity.fromEnvironment(_environment('P07', 'BA', 7)),
      throwsFormatException,
    );
    expect(
      () => PlaytestIdentity.fromEnvironment(_environment('P01', 'A/B', 1)),
      throwsFormatException,
    );
    final identifying = _report('P01', 'AB', 1)..['email'] = 'not-allowed';
    expect(
      validatePlaytestReport(identifying).errors,
      contains('forbidden identity key email'),
    );
  });

  test('validates legal AB and BA reports and numeric boundaries', () {
    expect(validatePlaytestReport(_report('P01', 'AB', 1)).isValid, isTrue);
    expect(validatePlaytestReport(_report('P06', 'BA', 6)).isValid, isTrue);

    final invalid = _report('P01', 'AB', 1)
      ..['elapsed_seconds'] = -0.01
      ..['peak_active_enemies'] = -1
      ..['session_serial'] = 0;
    expect(validatePlaytestReport(invalid).isValid, isFalse);
  });

  test('aggregates exact fixed six-person AB BA schedule', () {
    final reports = [
      _report('P01', 'AB', 1),
      _report('P02', 'BA', 2),
      _report('P03', 'AB', 3),
      _report('P04', 'BA', 4),
      _report('P05', 'AB', 5),
      _report('P06', 'BA', 6),
    ];
    final result = aggregatePlaytestReports(reports);

    expect(result.isValid, isTrue, reason: result.errors.join('\n'));
    expect(result.summary['valid_report_count'], 6);
    expect(result.summary['order_counts'], {'AB': 3, 'BA': 3});
    expect(result.summary['schedule_complete'], isTrue);
    expect(result.summary['human_gate_verdict'], 'NOT_EVALUATED');
  });

  test('rejects swapped order, duplicate slot, and mixed build', () {
    final reports = [
      _report('P01', 'BA', 2),
      _report('P02', 'BA', 2)
        ..['build_commit'] = 'different'
        ..['session_id'] = 'other-session',
    ];
    final result = aggregatePlaytestReports(reports);
    final errors = result.errors.join('\n');

    expect(errors, contains('P01 must use AB in slot 1'));
    expect(errors, contains('slot 2 assigned to both'));
    expect(errors, contains('mixed build_commit'));
  });

  test('atomic writer replaces a report without leaving a temp file', () async {
    final directory = await Directory.systemTemp.createTemp(
      'phase0a-human-gate-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final destination = File('${directory.path}/report.json');

    await writeJsonAtomically(destination, {'value': 1});
    await writeJsonAtomically(destination, {'value': 2});

    expect(jsonDecode(await destination.readAsString()), {'value': 2});
    expect(
      directory.listSync().where((entry) => entry.path.contains('.tmp-')),
      isEmpty,
    );
  });

  test('checked-in schedule is anonymous, balanced, and matches validator', () {
    final schedule =
        jsonDecode(
              File(
                'config/phase0a_human_gate_schedule.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final participants = schedule['participants'] as List<dynamic>;

    expect(participants, hasLength(6));
    expect(
      participants.where((entry) => (entry as Map)['order'] == 'AB'),
      hasLength(3),
    );
    expect(
      participants.where((entry) => (entry as Map)['order'] == 'BA'),
      hasLength(3),
    );
    for (final entry in participants.cast<Map<String, dynamic>>()) {
      final assignment = phase0aHumanGateAssignments[entry['participant_id']]!;
      expect(
        entry.keys,
        unorderedEquals(['participant_id', 'player_type', 'order', 'slot']),
      );
      expect(entry['order'], assignment.order);
      expect(entry['slot'], assignment.slot);
      expect(entry['player_type'], assignment.playerType);
    }
  });
}

Map<String, String> _environment(String participant, String order, int slot) =>
    {
      phase0aParticipantEnvironmentKey: participant,
      phase0aSessionEnvironmentKey: 'phase0a-gate-v1',
      phase0aOrderEnvironmentKey: order,
      phase0aSlotEnvironmentKey: '$slot',
    };

Map<String, Object?> _report(String participant, String order, int slot) => {
  'schema_version': phase0aHumanGateSchemaVersion,
  'participant_id': participant,
  'session_id': 'phase0a-gate-v1',
  'order': order,
  'slot': slot,
  'scenario_checksum': 'scenario',
  'build_commit': 'commit',
  'platform': 'macos',
  'platform_version': 'test',
  'logical_viewport': {'width': 1280, 'height': 720},
  'run_id': 'phase0a-gate-v1-$participant-run01',
  'outcome': slot.isEven ? 'defeat' : 'victory',
  'elapsed_seconds': 30.0,
  'peak_active_enemies': 21,
  'actions': {
    'basic_uses': 10,
    'dash_uses': 2,
    'gather_uses': 2,
    'clear_uses': 1,
    'break_successes': 1,
    'kills': 20,
    'maximum_chain': 10,
  },
  'session_serial': 1,
  'replay_requested': false,
};
