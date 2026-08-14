import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Isolation boundary for the Phase 0B vertical slice integration.
///
/// The dependency rule is structural: `phase0b/encounter` must never
/// import `phase0b/feedback`, `phase0b/feedback` must never import
/// `phase0b/encounter`; only `phase0b/integration` may depend on both.
/// The integration layer itself must stay persistence-, audio-, and
/// gate-free like every other draft slice.
void main() {
  List<File> dartFiles(String dir) => Directory(dir)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  void expectNoImport(String dir, RegExp forbidden, String label) {
    final files = dartFiles(dir);
    expect(files, isNotEmpty, reason: '$dir sources must exist');
    for (final file in files) {
      final imports = file
          .readAsStringSync()
          .split('\n')
          .where((line) => line.trimLeft().startsWith('import '))
          .toList();
      for (final line in imports) {
        expect(
          forbidden.hasMatch(line),
          isFalse,
          reason: '${file.path} must not import $label: $line',
        );
      }
    }
  }

  test('encounter slice never imports the feedback slice', () {
    expectNoImport(
      'lib/phase0b/encounter',
      RegExp(r'phase0b/feedback'),
      'phase0b/feedback',
    );
  });

  test('feedback slice never imports the encounter slice', () {
    expectNoImport(
      'lib/phase0b/feedback',
      RegExp(r'phase0b/encounter'),
      'phase0b/encounter',
    );
  });

  test('integration layer is the only slice importing both directions', () {
    final files = dartFiles('lib/phase0b/integration');
    expect(files, isNotEmpty);
    final adapter = files.firstWhere(
      (file) => file.path.endsWith('encounter_feedback_adapter.dart'),
    );
    final source = adapter.readAsStringSync();
    expect(source, contains('phase0b/encounter'));
    expect(source, contains('phase0b/feedback'));
  });

  test('integration slice stays persistence-, audio-, and gate-free', () {
    const forbiddenPatterns = <String>[
      'dart:io',
      'dart:js',
      'Isar',
      'SharedPreferences',
      'path_provider',
      'getApplicationDocumentsDirectory',
      'audioplayers',
      'flame_audio',
      'so_loud',
      'just_audio',
      'package:wuxia_idle/',
      'result_writer',
      'human_gate',
      'windows_gate',
      'gate_eligible: true',
      'gate_eligible=true',
    ];
    for (final file in dartFiles('lib/phase0b/integration')) {
      final source = file.readAsStringSync();
      for (final pattern in forbiddenPatterns) {
        expect(
          source.contains(pattern),
          isFalse,
          reason: '${file.path} contains forbidden pattern: $pattern',
        );
      }
    }
  });

  test('guard proves it can fail red on the forbidden shapes', () {
    const fixture =
        "import 'package:phase0minus_probe/phase0b/feedback/x.dart';\n"
        "import 'dart:io'; // Isar audioplayers gate_eligible=true";
    expect(
      fixture
          .split('\n')
          .where((line) => line.trimLeft().startsWith('import '))
          .any((line) => RegExp(r'phase0b/feedback').hasMatch(line)),
      isTrue,
    );
    for (final pattern in const [
      'dart:io',
      'Isar',
      'audioplayers',
      'gate_eligible=true',
    ]) {
      expect(
        fixture.contains(pattern),
        isTrue,
        reason: 'guard must detect $pattern',
      );
    }
  });

  test('mode is registered and carries the non-Gate claims', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    expect(mainSource, contains('phase0b_vertical_slice_draft'));
    final appSource = File(
      'lib/phase0b/integration/phase0b_vertical_slice_draft_app.dart',
    ).readAsStringSync();
    expect(appSource, contains('NOT FINAL'));
    expect(appSource, contains('gate_eligible=false'));
  });
}
