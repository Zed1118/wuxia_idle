import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mainline and tower delegate common progression settlement', () async {
    final paths = [
      'lib/features/mainline/presentation/stage_entry_flow.dart',
      'lib/features/tower/presentation/tower_entry_flow.dart',
    ];
    for (final path in paths) {
      final source = await File(path).readAsString();
      expect(source, contains('CombatProgressionSettlementService'));
      expect(
        source,
        isNot(contains('CharacterAdvancementService.applyExperience')),
      );
      expect(source, isNot(contains('recordRealmBreakthrough')));
      expect(source, isNot(contains('recordResonanceUpgraded')));
    }

    final mainline = await File(paths.first).readAsString();
    final tower = await File(paths.last).readAsString();
    expect(mainline, contains('experienceReward: stage.baseExpReward'));
    expect(
      tower,
      contains(
        'experienceReward: grantsFirstClearExperience ? floor.baseExpReward : 0',
      ),
    );
  });

  test('shared settlement never owns a transaction', () async {
    final source = await File(
      'lib/features/combat_shared/application/combat_progression_settlement_service.dart',
    ).readAsString();
    expect(source, isNot(contains('writeTxn')));
  });
}
