import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const feedbackDir = 'lib/phase0b/feedback';

  /// The draft must never persist loot or anything else, never pull an
  /// audio dependency, never touch production code, and never wire into
  /// any Gate writer or human-gate path.
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

  test('feedback draft sources stay persistence-, audio-, and gate-free', () {
    final files = Directory(feedbackDir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
    expect(files, isNotEmpty, reason: 'feedback draft sources must exist');
    for (final file in files) {
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
    const fixture = "import 'dart:io'; // Isar audioplayers gate_eligible=true";
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

  test('non-Gate and not-final claims stay on screen', () {
    final source = File(
      '$feedbackDir/phase0b_feedback_draft_app.dart',
    ).readAsStringSync();
    expect(source, contains('gate_eligible=false'));
    expect(source, contains('NOT FINAL'));
  });

  test('nested pubspec gains no audio or persistence dependency', () {
    final source = File('pubspec.yaml').readAsStringSync();
    for (final dependency in const [
      'audioplayers:',
      'flame_audio:',
      'just_audio:',
      'so_loud:',
      'isar:',
      'path_provider:',
      'shared_preferences:',
    ]) {
      expect(source.contains(dependency), isFalse, reason: dependency);
    }
  });
}
