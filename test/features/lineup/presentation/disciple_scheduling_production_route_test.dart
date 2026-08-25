import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('生产入口不再引用旧 TeamLineupScreen', () {
    for (final path in [
      'lib/features/sect/presentation/sect_hub_screen.dart',
      'lib/features/character_panel/presentation/lineage_panel_screen.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('disciple_scheduling_screen.dart'), reason: path);
      expect(source, contains('DiscipleSchedulingScreen'), reason: path);
      expect(source, isNot(contains('team_lineup_screen.dart')), reason: path);
      expect(source, isNot(contains('TeamLineupScreen')), reason: path);
    }
  });

  test('门人调度页保持只读，不写全局阵容', () {
    final source = File(
      'lib/features/lineup/presentation/disciple_scheduling_screen.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('LineupService')));
    expect(source, isNot(contains('activeCharacterIds')));
    expect(source, isNot(contains('writeTxn')));
  });
}
