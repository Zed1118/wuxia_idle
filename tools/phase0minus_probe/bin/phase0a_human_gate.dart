import 'dart:convert';
import 'dart:io';

import 'package:phase0minus_probe/human_gate/human_execution_evidence.dart';
import 'package:phase0minus_probe/human_gate/human_gate_aggregator.dart';
import 'package:phase0minus_probe/human_gate/playtest_aggregator.dart';
import 'package:phase0minus_probe/human_gate/playtest_report.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 3 || !{'human', 'raw'}.contains(arguments[0])) {
    stderr.writeln(
      'Usage: phase0a_human_gate <human|raw> <results-dir> <summary.json>',
    );
    exitCode = 64;
    return;
  }
  final mode = arguments[0];
  final source = Directory(arguments[1]);
  if (!await source.exists()) {
    stderr.writeln('Results directory does not exist: ${source.path}');
    exitCode = 66;
    return;
  }
  final reports = <Map<String, Object?>>[];
  final rawReports = <Map<String, Object?>>[];
  final evidenceErrors = <String>[];
  await for (final entity in source.list(recursive: mode == 'human')) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    final isHumanSession = entity.path.endsWith('/human-session.json');
    final isRawReport = entity.path.contains('/phase0a-playtests/');
    if (mode == 'human' && !isHumanSession && !isRawReport) {
      continue;
    }
    try {
      final decoded = jsonDecode(await entity.readAsString());
      if (decoded is! Map<String, dynamic>) {
        stderr.writeln('${entity.path}: root must be an object');
        exitCode = 65;
        return;
      }
      final report = decoded.cast<String, Object?>();
      if (mode == 'human' && isRawReport) {
        rawReports.add(report);
      } else {
        reports.add(report);
        if (mode == 'human' && isHumanSession) {
          evidenceErrors.addAll(
            await validateHumanExecutionEvidence(
              sessionState: File('${entity.parent.path}/session.state'),
              executionEvents: File('${entity.parent.path}/execution.events'),
              participantId: report['participant_id'] as String? ?? '',
              participantSessionId:
                  report['participant_session_id'] as String? ?? '',
              order: report['order'] as String? ?? '',
            ),
          );
        }
      }
    } on FormatException catch (error) {
      stderr.writeln('${entity.path}: invalid JSON: $error');
      exitCode = 65;
      return;
    }
  }
  if (mode == 'human') {
    final manifestValues = await _readManifest(
      File('${source.parent.parent.path}/MANIFEST.txt'),
    );
    if (manifestValues['commit'] == null ||
        manifestValues['scenario_checksum'] == null) {
      evidenceErrors.add(
        'package MANIFEST missing commit or scenario checksum',
      );
    }
    final aggregation = aggregateHumanGate(
      reports,
      rawReports: rawReports,
      executionEvidenceErrors: evidenceErrors,
      expectedPackageId: manifestValues['commit'],
      expectedScenarioChecksum: manifestValues['scenario_checksum'],
    );
    await writeJsonAtomically(File(arguments[2]), aggregation.summary);
    stdout.writeln(
      'Validated ${aggregation.summary['valid_sample_count']} human sessions; '
      'verdict=${aggregation.verdict}.',
    );
    exitCode = humanGateProcessExitCode(aggregation.verdict);
  } else {
    final aggregation = aggregatePlaytestReports(reports);
    if (!aggregation.isValid) {
      for (final error in aggregation.errors) {
        stderr.writeln(error);
      }
      exitCode = 65;
      return;
    }
    await writeJsonAtomically(File(arguments[2]), aggregation.summary);
    stdout.writeln(
      'Validated ${aggregation.summary['valid_report_count']} raw reports; '
      'schedule_complete=${aggregation.summary['schedule_complete']}.',
    );
    if (aggregation.summary['schedule_complete'] != true) exitCode = 2;
  }
}

Future<Map<String, String>> _readManifest(File manifest) async {
  if (!await manifest.exists()) return const {};
  final values = <String, String>{};
  for (final line in await manifest.readAsLines()) {
    final separator = line.indexOf('=');
    if (separator > 0) {
      values[line.substring(0, separator)] = line.substring(separator + 1);
    }
  }
  return values;
}
