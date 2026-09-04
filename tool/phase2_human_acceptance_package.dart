import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  try {
    final options = _parseArgs(args);
    final commit = _required(options, 'candidate');
    if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(commit)) {
      throw const FormatException(
        '--candidate must be an exact 40-character SHA',
      );
    }

    final app = File(_required(options, 'app'));
    final fixture = File(_required(options, 'fixture'));
    final archive = File(_required(options, 'archive'));
    final template = File(_required(options, 'template'));
    for (final file in <File>[app, fixture, archive, template]) {
      if (!file.existsSync()) {
        throw StateError(
          'required package artifact does not exist: ${file.path}',
        );
      }
    }

    final output = Directory(_required(options, 'output'));
    await output.create(recursive: true);
    final appChecksum = await _sha256(app);
    final fixtureChecksum = await _sha256(fixture);
    final archiveChecksum = await _sha256(archive);
    final manifest = buildPackageManifest(
      commit: commit,
      appChecksum: appChecksum,
      fixtureChecksum: fixtureChecksum,
      archiveChecksum: archiveChecksum,
    );
    final checklist = renderConsolidatedChecklist(
      await template.readAsString(),
      <String, String>{
        'COMMIT': commit,
        'APP_SHA256': appChecksum,
        'FIXTURE_SHA256': fixtureChecksum,
        'ARCHIVE_SHA256': archiveChecksum,
      },
    );

    final encoder = const JsonEncoder.withIndent('  ');
    await File(
      '${output.path}/package-manifest.json',
    ).writeAsString('${encoder.convert(manifest)}\n');
    await File('${output.path}/HUMAN_ACCEPTANCE.md').writeAsString(checklist);

    stdout.writeln(
      encoder.convert(<String, Object?>{
        'state': 'READY_FOR_HUMAN_EXECUTION',
        'formal_gates_closed': const <String>[],
        'output': output.absolute.path,
        'commit': commit,
        'app_sha256': appChecksum,
        'fixture_sha256': fixtureChecksum,
        'archive_sha256': archiveChecksum,
      }),
    );
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 64;
  }
}

Map<String, Object?> buildPackageManifest({
  required String commit,
  required String appChecksum,
  required String fixtureChecksum,
  required String archiveChecksum,
}) {
  return <String, Object?>{
    'schema': 'phase2-consolidated-human-package-v1',
    'commit': commit,
    'app_package': 'wuxia_idle',
    'build_mode': 'macos_profile',
    'entry_mode': 'production_root_app',
    'evidence_state': 'PENDING_HUMAN_EXECUTION',
    'covered_milestones': const <String>['M2', 'M3', 'M4', 'M5', 'M6'],
    'app_sha256': appChecksum,
    'fixture_sha256': fixtureChecksum,
    'archive_sha256': archiveChecksum,
    'supplemental_fixture_role': 'visual_debug_only',
    'formal_gates_closed': const <String>[],
    'human_gate_substituted': false,
    'windows_gate_substituted': false,
  };
}

String renderConsolidatedChecklist(
  String template,
  Map<String, String> fields,
) {
  var rendered = template;
  for (final entry in fields.entries) {
    rendered = rendered.replaceAll('{{${entry.key}}}', entry.value);
  }
  final unresolved = RegExp(r'\{\{[^}]+\}\}').allMatches(rendered).toList();
  if (unresolved.isNotEmpty) {
    throw StateError(
      'unresolved checklist placeholder: ${unresolved.first.group(0)}',
    );
  }
  return rendered.endsWith('\n') ? rendered : '$rendered\n';
}

Map<String, String> _parseArgs(List<String> args) {
  final result = <String, String>{};
  for (var index = 0; index < args.length; index++) {
    final key = args[index];
    if (!key.startsWith('--') || index + 1 >= args.length) {
      throw FormatException('invalid argument list near $key');
    }
    result[key.substring(2)] = args[++index];
  }
  return result;
}

String _required(Map<String, String> options, String key) {
  final value = options[key];
  if (value == null || value.isEmpty) {
    throw FormatException('missing --$key');
  }
  return value;
}

Future<String> _sha256(File file) async {
  final result = await Process.run('shasum', <String>['-a', '256', file.path]);
  if (result.exitCode != 0) {
    throw StateError('sha256 failed for ${file.path}: ${result.stderr}');
  }
  final checksum = result.stdout.toString().trim().split(RegExp(r'\s+')).first;
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(checksum)) {
    throw StateError('invalid sha256 output for ${file.path}');
  }
  return checksum;
}
