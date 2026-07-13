import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/isar_setup.dart';

import '../support/isar_test_support.dart';

void main() {
  late Directory tempDir;

  setUpAll(initializeTestIsarCore);
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('legacy_level_schema_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });
  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('legacy level fields still round-trip without repair', () async {
    final character =
        Character.create(
            name: '旧档角色',
            realmTier: RealmTier.erLiu,
            realmLayer: RealmLayer.qiMeng,
            attributes: Attributes(),
            rarity: RarityTier.xunChang,
            lineageRole: LineageRole.founder,
            createdAt: DateTime(2026, 1, 1),
          )
          ..level = -9223372036854775808
          ..levelExp = 777;
    late int id;
    await IsarSetup.instance.writeTxn(() async {
      id = await IsarSetup.instance.characters.put(character);
    });

    final saved = await IsarSetup.instance.characters.get(id);
    expect(saved!.level, -9223372036854775808);
    expect(saved.levelExp, 777);
  });
}
