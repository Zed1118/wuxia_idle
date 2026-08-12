import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const forbiddenSourcePatterns = <String>[
    'package:wuxia_idle/',
    'package:isar/',
    'IsarSetup.init',
    'Isar.open',
    'getApplicationDocumentsDirectory',
    'SharedPreferences',
    'phase2_seed_service',
    '_clearAll()',
  ];
  const forbiddenDependencies = <String>[
    'isar:',
    'isar_flutter_libs:',
    'path_provider:',
    'shared_preferences:',
    'wuxia_idle:',
  ];

  test('probe source has no production storage or application imports', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      final source = file.readAsStringSync();
      for (final pattern in forbiddenSourcePatterns) {
        expect(
          source.contains(pattern),
          isFalse,
          reason: '${file.path} contains forbidden pattern $pattern',
        );
      }
    }
  });

  test('nested pubspec excludes persistence and production dependencies', () {
    final source = File('pubspec.yaml').readAsStringSync();
    for (final dependency in forbiddenDependencies) {
      expect(source.contains(dependency), isFalse, reason: dependency);
    }
    expect(source, contains('flame: 1.38.0'));
  });

  test('root pubspec and production trees remain Flame-free', () {
    final rootPubspec = File('../../pubspec.yaml').readAsStringSync();
    expect(
      rootPubspec.contains(RegExp(r'^\s*flame\s*:', multiLine: true)),
      isFalse,
    );
    expect(Directory('../../lib').existsSync(), isTrue);
    expect(Directory('../../data').existsSync(), isTrue);
  });

  test('contract fixture demonstrates forbidden call is detected', () {
    const fixture = 'Future<void> bad() => IsarSetup.init();';
    expect(
      forbiddenSourcePatterns.any(fixture.contains),
      isTrue,
      reason: 'The isolation guard must fail red for the known incident shape.',
    );
  });
}
