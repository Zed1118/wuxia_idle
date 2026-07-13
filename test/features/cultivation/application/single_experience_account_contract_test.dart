import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'mainline and tower settlements do not write the legacy level account',
    () async {
      for (final path in [
        'lib/features/mainline/presentation/stage_entry_flow.dart',
        'lib/features/tower/presentation/tower_entry_flow.dart',
      ]) {
        final source = await File(path).readAsString();
        expect(
          source,
          isNot(contains('LevelService.applyLevelExp')),
          reason: path,
        );
        expect(source, isNot(contains('numbers.level')), reason: path);
      }
    },
  );

  test(
    'retreat, offline, and item use do not write the legacy level account',
    () async {
      for (final path in [
        'lib/features/seclusion/application/seclusion_service.dart',
        'lib/features/seclusion/application/offline_passive_service.dart',
        'lib/features/inventory/application/item_use_service.dart',
      ]) {
        final source = await File(path).readAsString();
        expect(
          source,
          isNot(contains('LevelService.applyLevelExp')),
          reason: path,
        );
        expect(source, isNot(contains('LevelConfig')), reason: path);
      }
    },
  );
}
