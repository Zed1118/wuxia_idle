import 'dart:convert';
import 'dart:io';

const phase0aHumanGateSchemaVersion = 2;

final class PlaytestReportValidation {
  const PlaytestReportValidation(this.errors);

  final List<String> errors;
  bool get isValid => errors.isEmpty;
}

PlaytestReportValidation validatePlaytestReport(Map<String, Object?> report) {
  final errors = <String>[];
  const requiredKeys = {
    'schema_version',
    'participant_id',
    'session_id',
    'order',
    'slot',
    'scenario_checksum',
    'build_commit',
    'platform',
    'logical_viewport',
    'run_id',
    'outcome',
    'elapsed_seconds',
    'peak_active_enemies',
    'actions',
    'session_serial',
    'replay_requested',
  };
  const forbiddenIdentityKeys = {
    'name',
    'real_name',
    'email',
    'account',
    'phone',
    'device_owner',
  };
  for (final key in requiredKeys) {
    if (!report.containsKey(key)) errors.add('missing $key');
  }
  for (final key in forbiddenIdentityKeys) {
    if (report.containsKey(key)) errors.add('forbidden identity key $key');
  }
  if (report['schema_version'] != phase0aHumanGateSchemaVersion) {
    errors.add('schema_version must be $phase0aHumanGateSchemaVersion');
  }
  final participant = report['participant_id'];
  if (participant is! String || !RegExp(r'^P0[1-6]$').hasMatch(participant)) {
    errors.add('participant_id must be P01..P06');
  }
  final session = report['session_id'];
  if (session is! String ||
      !RegExp(r'^[a-z0-9][a-z0-9_-]{2,31}$').hasMatch(session)) {
    errors.add('session_id must be an anonymous slug');
  }
  if (report['order'] != 'AB' && report['order'] != 'BA') {
    errors.add('order must be AB or BA');
  }
  final slot = report['slot'];
  if (slot is! int || slot < 1 || slot > 6) errors.add('slot must be 1..6');
  if (report['session_serial'] is! int ||
      (report['session_serial'] as int? ?? 0) < 1) {
    errors.add('session_serial must be a positive integer');
  }
  if (report['replay_requested'] is! bool) {
    errors.add('replay_requested must be boolean');
  }
  if (!{'victory', 'defeat'}.contains(report['outcome'])) {
    errors.add('outcome must be victory or defeat');
  }
  if (report['elapsed_seconds'] is! num ||
      (report['elapsed_seconds'] as num? ?? -1) < 0) {
    errors.add('elapsed_seconds must be non-negative');
  }
  if (report['peak_active_enemies'] is! int ||
      (report['peak_active_enemies'] as int? ?? -1) < 0) {
    errors.add('peak_active_enemies must be a non-negative integer');
  }
  final actions = report['actions'];
  if (actions is! Map) {
    errors.add('actions must be an object');
  } else {
    for (final key in const [
      'basic_uses',
      'dash_uses',
      'gather_uses',
      'clear_uses',
      'break_successes',
      'kills',
      'maximum_chain',
    ]) {
      final value = actions[key];
      if (value is! int || value < 0) errors.add('actions.$key invalid');
    }
  }
  return PlaytestReportValidation(errors);
}

Future<void> writeJsonAtomically(
  File destination,
  Map<String, Object?> value,
) async {
  await destination.parent.create(recursive: true);
  final temporary = File(
    '${destination.path}.tmp-$pid-${DateTime.now().microsecondsSinceEpoch}',
  );
  try {
    await temporary.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(value)}\n',
      flush: true,
    );
    await temporary.rename(destination.path);
  } finally {
    if (await temporary.exists()) await temporary.delete();
  }
}
