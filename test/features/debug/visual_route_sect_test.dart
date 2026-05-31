import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
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

    // 回归:模拟真机已存 legacy 祖师(0.14 存档·portraitPath=null)。
    // ensureFoundingMasters 对已存在 founder 短路 → 若 seed 不先 _clearAll,
    // 祖师立绘永空(Codex A 段 FAIL 根因)。
    test('已存无立绘 legacy 祖师时,seed 仍补全祖师 portraitPath', () async {
      final isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        final legacy = Character.create(
          name: '旧祖师',
          realmTier: RealmTier.wuSheng,
          realmLayer: RealmLayer.dengFeng,
          attributes: Attributes()
            ..constitution = 6
            ..enlightenment = 6
            ..agility = 6
            ..fortune = 6,
          rarity: RarityTier.biaoZhun,
          lineageRole: LineageRole.founder,
          isFounder: true,
          createdAt: DateTime(2026, 1, 1),
        )..id = 1; // portraitPath 默认 null(模拟旧存档)
        await isar.characters.put(legacy);
      });

      await Phase2SeedService(isar: isar).seedSectWithFullNpc();

      final founder =
          (await isar.characters.where().findAll()).firstWhere((c) => c.isFounder);
      expect(founder.portraitPath, isNotNull,
          reason: 'seed 须 _clearAll 重建带立绘祖师,不被 legacy 短路');
    });
  });
}
