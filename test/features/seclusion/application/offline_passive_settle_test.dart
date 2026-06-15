import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';

void main() {
  late Directory tempDir;
  const kCharId = 10;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    if (!GameRepository.isLoaded) {
      await GameRepository.loadAllDefs(loader: (p) => File(p).readAsString());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_passive_settle_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    final ch = Character.create(
      name: 'hero',
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 1, 1),
      internalForce: 500,
    )..id = kCharId;
    await IsarSetup.instance
        .writeTxn(() => IsarSetup.instance.characters.put(ch));
  });

  tearDown(() async => await IsarSetup.close());

  test('settle 发放磨剑石入包 + 经验入角色 + 累计 +=', () async {
    final result = await OfflinePassiveService.settle(
      saveDataId: 1,
      characterId: kCharId,
      awayHours: 10, // 学徒 → moji 2 / exp 250
      now: DateTime(2026, 6, 15, 12),
    );
    expect(result.mojianshi, 2);
    expect(result.experience, 250);

    final item =
        await IsarSetup.instance.inventoryItems.getByDefId('item_mojianshi');
    expect(item?.quantity, 2);

    final save = (await IsarSetup.currentSaveData())!;
    expect(save.totalPassiveMojianshi, 2);
    expect(save.totalPassiveExperience, 250);
    expect(save.lastOnlineAt, DateTime(2026, 6, 15, 12)); // 重置基准
  });

  test('settle 幂等：第二次结算继续累加（基于新 lastOnlineAt 应由 caller clamp，'
      'service 本身按传入 awayHours 累加）', () async {
    await OfflinePassiveService.settle(
      saveDataId: 1,
      characterId: kCharId,
      awayHours: 10,
      now: DateTime(2026, 6, 15, 12),
    );
    await OfflinePassiveService.settle(
      saveDataId: 1,
      characterId: kCharId,
      awayHours: 10,
      now: DateTime(2026, 6, 15, 22),
    );
    final item =
        await IsarSetup.instance.inventoryItems.getByDefId('item_mojianshi');
    expect(item?.quantity, 4);
    final save = (await IsarSetup.currentSaveData())!;
    expect(save.totalPassiveMojianshi, 4);
    expect(save.totalPassiveExperience, 500);
    expect(save.lastOnlineAt, DateTime(2026, 6, 15, 22));
  });
}
