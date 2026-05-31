import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/debug/application/visual_route.dart';

// Isar setup 体例照搬 test/features/sect/sect_member_service_test.dart
void main() {
  test('parseVisualRoute 识别 sect_screen_npc', () {
    expect(parseVisualRoute('sect_screen_npc'), VisualRoute.sectScreenNpc);
  });

  group('seedSectWithFullNpc', () {
    late Directory tempDir;

    setUpAll(() async {
      await Isar.initializeIsarCore(download: true);
      if (!GameRepository.isLoaded) {
        await GameRepository.loadAllDefs(
          loader: (p) => File(p).readAsString(),
        );
      }
    });

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('wuxia_sect_portrait_test_');
      await IsarSetup.init(directory: tempDir, inspector: false);
    });

    tearDown(() async {
      await IsarSetup.close();
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('6 sect_candidate NPC 全 isInSect + portraitPath 非空,祖师有 portraitPath',
        () async {
      final isar = IsarSetup.instance;
      await Phase2SeedService(isar: isar).seedSectWithFullNpc();
      final all = await isar.characters.where().findAll();
      final npc = all.where((c) => c.isInSect && !c.isFounder).toList();
      expect(npc.length, greaterThanOrEqualTo(6));
      for (final c in npc) {
        expect(c.portraitPath, isNotNull, reason: '${c.name} 应有立绘');
      }
      final founder = all.firstWhere((c) => c.isFounder);
      expect(founder.portraitPath, isNotNull);
    });
  });
}
