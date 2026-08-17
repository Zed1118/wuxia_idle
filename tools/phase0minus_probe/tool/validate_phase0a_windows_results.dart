import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:phase0minus_probe/gate/windows_gate_validator.dart';

Future<void> main(List<String> arguments) async {
  final options = _options(arguments);
  final requiredKeys = {
    'results-root',
    'host-manifest',
    'expected-commit',
    'expected-checksum',
    'output-root',
  };
  final missing = requiredKeys.where((key) => (options[key] ?? '').isEmpty);
  if (missing.isNotEmpty) {
    stderr.writeln('Missing options: ${missing.join(', ')}');
    exitCode = 2;
    return;
  }

  final resultsRoot = Directory(options['results-root']!);
  final hostFile = File(options['host-manifest']!);
  final outputRoot = Directory(options['output-root']!);
  if (!resultsRoot.existsSync() || !hostFile.existsSync()) {
    stderr.writeln('Results root or host manifest does not exist.');
    exitCode = 2;
    return;
  }
  await outputRoot.create(recursive: true);
  final hostBytes = await hostFile.readAsBytes();
  final host = _jsonMap(utf8.decode(hostBytes))
    ..['manifest_sha256'] = sha256.convert(hostBytes).toString();
  final runs = <WindowsGateRun>[];
  await for (final entity in resultsRoot.list(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('manifest.json')) continue;
    if (entity.absolute.path == hostFile.absolute.path) continue;
    final directory = entity.parent;
    final summaryFile = File(
      '${directory.path}${Platform.pathSeparator}summary.json',
    );
    if (!summaryFile.existsSync()) continue;
    final manifest = _jsonMap(await entity.readAsString());
    final summary = _jsonMap(await summaryFile.readAsString());
    runs.add(
      WindowsGateRun(
        manifest: manifest,
        summary: summary,
        artifactsValid: await _verifyArtifacts(directory, manifest),
        runLogPresent: File(
          '${directory.path}${Platform.pathSeparator}run.log',
        ).existsSync(),
      ),
    );
  }
  runs.sort(
    (left, right) => (left.manifest['run_id'] ?? '').toString().compareTo(
      (right.manifest['run_id'] ?? '').toString(),
    ),
  );
  final validation = validatePhase0aWindowsGate(
    hostManifest: host,
    runs: runs,
    expectedCommit: options['expected-commit']!,
    expectedScenarioChecksum: options['expected-checksum']!,
  );
  final jsonFile = File('${outputRoot.path}/windows_gate_validation.json');
  await jsonFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(validation.toJson()),
    flush: true,
  );
  final markdownFile = File('${outputRoot.path}/windows_gate_validation.md');
  await markdownFile.writeAsString(_markdown(validation), flush: true);
  stdout.writeln('WINDOWS_GATE_${validation.passed ? 'PASS' : 'FAIL'}');
  stdout.writeln(jsonFile.absolute.path);
  if (!validation.passed) {
    for (final error in validation.errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
  }
}

Map<String, String> _options(List<String> arguments) {
  final result = <String, String>{};
  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (!argument.startsWith('--')) continue;
    final key = argument.substring(2);
    if (index + 1 < arguments.length) result[key] = arguments[++index];
  }
  return result;
}

Map<String, Object?> _jsonMap(String source) {
  final normalized = source.startsWith('\uFEFF') ? source.substring(1) : source;
  return (jsonDecode(normalized) as Map).cast<String, Object?>();
}

Future<bool> _verifyArtifacts(
  Directory directory,
  Map<String, Object?> manifest,
) async {
  final raw = manifest['files_sha256'];
  if (raw is! Map || raw.isEmpty) return false;
  for (final entry in raw.entries) {
    final file = File('${directory.path}${Platform.pathSeparator}${entry.key}');
    if (!file.existsSync()) return false;
    final checksum = sha256.convert(await file.readAsBytes()).toString();
    if (checksum != entry.value) return false;
  }
  return true;
}

String _markdown(WindowsGateValidation validation) {
  final buffer = StringBuffer()
    ..writeln('# Phase 0A Windows minimum-spec Gate')
    ..writeln()
    ..writeln('> Result: `${validation.passed ? 'PASS' : 'FAIL'}`')
    ..writeln()
    ..writeln('## Matrix')
    ..writeln();
  for (final entry in validation.viewportRunCounts.entries) {
    buffer.writeln('- `${entry.key}`: ${entry.value}/3');
  }
  buffer
    ..writeln()
    ..writeln('## Validation errors')
    ..writeln();
  if (validation.errors.isEmpty) {
    buffer.writeln('- None.');
  } else {
    for (final error in validation.errors) {
      buffer.writeln('- $error');
    }
  }
  return buffer.toString();
}
