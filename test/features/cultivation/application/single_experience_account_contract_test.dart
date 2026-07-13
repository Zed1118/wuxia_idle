import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const productionExperiencePaths = [
    'lib/features/mainline/presentation/stage_entry_flow.dart',
    'lib/features/tower/presentation/tower_entry_flow.dart',
    'lib/features/battle/application/combat_progression_settlement_service.dart',
    'lib/features/seclusion/application/seclusion_service.dart',
    'lib/features/seclusion/application/offline_passive_service.dart',
    'lib/features/inventory/application/item_use_service.dart',
  ];

  test(
    'all production experience paths ignore the legacy level account',
    () async {
      for (final path in productionExperiencePaths) {
        final source = await File(path).readAsString();
        expect(source, isNot(contains('LevelService')), reason: path);
        expect(source, isNot(contains('LevelConfig')), reason: path);
        expect(source, isNot(contains('.levelExp =')), reason: path);
        expect(source, isNot(contains('numbers.level')), reason: path);
      }
    },
  );
}
