import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production player assembler 不回引 legacy battle character', () {
    final source = File(
      'lib/features/battle/application/'
      'player_combatant_snapshot_assembler.dart',
    ).readAsStringSync();

    expect(source, isNot(contains("domain/battle_state.dart")));
    expect(source, isNot(contains('legacy_3v3_combatant_adapter.dart')));
    expect(source, isNot(contains('BattleCharacter.fromCharacter')));
    expect(source, contains('PlayerCombatantSnapshotBuilder.build'));
  });

  test('neutral builder API 不接受 legacy team/slot 坐标', () {
    final source = File(
      'lib/features/battle/domain/player_combatant_snapshot_builder.dart',
    ).readAsStringSync();
    final buildSignature = RegExp(
      r'static CombatantSnapshot build\(\{([\s\S]*?)\n  \}\)',
    ).firstMatch(source);

    expect(buildSignature, isNotNull);
    expect(buildSignature!.group(1), isNot(contains('teamSide')));
    expect(buildSignature.group(1), isNot(contains('slotIndex')));
  });
}
