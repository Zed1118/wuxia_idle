import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'all seven experience entrances delegate to the single experience account',
    () async {
      const combatPaths = {
        'mainline': 'lib/features/mainline/presentation/stage_entry_flow.dart',
        'tower': 'lib/features/tower/presentation/tower_entry_flow.dart',
      };
      for (final entry in combatPaths.entries) {
        final source = await File(entry.value).readAsString();
        expect(source, contains('CombatProgressionSettlementService'));
        expect(source, contains('settlement.applyExperience'));
        expect(source, isNot(contains('.levelExp =')), reason: entry.key);
        expect(source, isNot(contains('LevelService')), reason: entry.key);
      }

      const directPaths = {
        'retreat': 'lib/features/seclusion/application/seclusion_service.dart',
        'offline':
            'lib/features/seclusion/application/offline_passive_service.dart',
        'item': 'lib/features/inventory/application/item_use_service.dart',
      };
      for (final entry in directPaths.entries) {
        final source = await File(entry.value).readAsString();
        expect(
          source,
          contains('CharacterAdvancementService.applyExperience'),
          reason: '${entry.key} 未委托唯一成长服务',
        );
        expect(source, isNot(contains('.levelExp =')), reason: entry.key);
        expect(source, isNot(contains('LevelService')), reason: entry.key);
      }
    },
  );

  test(
    'mainline replay and tower first-clear policies remain intentionally different',
    () async {
      final mainline = await File(
        'lib/features/mainline/presentation/stage_entry_flow.dart',
      ).readAsString();
      final tower = await File(
        'lib/features/tower/presentation/tower_entry_flow.dart',
      ).readAsString();

      expect(mainline, contains('experienceReward: stage.baseExpReward'));
      expect(
        tower,
        contains('experienceReward: isFirstClear ? floor.baseExpReward : 0'),
      );
    },
  );

  test(
    'retreat and passive sources combine before one advancement call',
    () async {
      final source = await File(
        'lib/features/seclusion/application/seclusion_service.dart',
      ).readAsString();
      expect(
        source,
        contains('outputs.experiencePoints + settlement.passive.experience'),
      );
    },
  );
}
