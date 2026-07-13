import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('former consumers never read or write legacy level fields', () async {
    const forbidden = <String>[
      'LevelService',
      'LevelConfig',
      'levelExp',
      'c.level',
      'character.level',
    ];
    const formerConsumers = <String>[
      'lib/features/mainline/presentation/stage_entry_flow.dart',
      'lib/features/tower/presentation/tower_entry_flow.dart',
      'lib/features/seclusion/application/seclusion_service.dart',
      'lib/features/seclusion/application/offline_passive_service.dart',
      'lib/features/inventory/application/item_use_service.dart',
      'lib/features/battle/domain/derived_stats.dart',
      'lib/features/character_panel/presentation/character_panel_screen.dart',
      'lib/data/numbers_config.dart',
      'lib/data/isar_setup.dart',
    ];

    for (final path in formerConsumers) {
      final source = await File(path).readAsString();
      for (final token in forbidden) {
        expect(source, isNot(contains(token)), reason: '$path: $token');
      }
      expect(
        source,
        isNot(contains(RegExp(r'\.numbers\.level\b'))),
        reason: '$path: numbers.level',
      );
    }
  });
}
