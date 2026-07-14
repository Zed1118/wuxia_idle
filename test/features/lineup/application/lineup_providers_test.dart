import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderOrFamily;
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/application/character_providers.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/lineup/application/lineup_invalidation.dart';
import 'package:wuxia_idle/features/lineup/application/lineup_providers.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

/// lineup providers:nullable propagation + 替补池派生 + 编成后失效集合。
void main() {
  late GameRepository repository;
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_lineup_prov_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  tearDownAll(GameRepository.resetForTest);

  Character makeChar({
    required int id,
    required String name,
    bool isFounder = false,
    bool isActive = false,
  }) {
    final realm = repository.getRealm(RealmTier.xueTu, RealmLayer.qiMeng);
    return Character.create(
          name: name,
          realmTier: RealmTier.xueTu,
          realmLayer: RealmLayer.qiMeng,
          attributes: Attributes(),
          rarity: RarityTier.biaoZhun,
          lineageRole: isFounder ? LineageRole.founder : LineageRole.disciple,
          createdAt: DateTime(2026, 7, 14),
          internalForce: realm.internalForceMax,
          internalForceMax: realm.internalForceMax,
          experienceToNextLayer: realm.experienceToNext,
          isFounder: isFounder,
          isActive: isActive,
        )
        ..id = id;
  }

  Future<void> seed() async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.characters.putAll([
        makeChar(id: 1, name: '祖师', isFounder: true, isActive: true),
        makeChar(id: 4, name: '替补甲'),
        makeChar(id: 5, name: '替补乙'),
      ]);
      final save = SaveData()
        ..saveVersion = '0.36'
        ..createdAt = DateTime(2026, 7, 14)
        ..lastSavedAt = DateTime(2026, 7, 14)
        ..lastOnlineAt = DateTime(2026, 7, 14)
        ..founderCharacterId = 1
        ..activeCharacterIds = [1];
      await isar.saveDatas.put(save);
    });
  }

  test('lineupServiceProvider:Isar 已 init → 非 null', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(lineupServiceProvider), isNotNull);
  });

  test('lineupReserveProvider 派生替补池;编成失效集合驱动刷新', () async {
    await seed();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final before = await container.read(lineupReserveProvider.future);
    expect(before.map((c) => c.id).toList(), [4, 5]);

    // 换人:4 上场 → invalidate 后替补池只剩 5,active 列表更新。
    final service = container.read(lineupServiceProvider)!;
    final result = await service.apply(newActiveIds: [1, 4]);
    expect(result.isSuccess, isTrue);
    invalidateAfterLineupChange(container.invalidate);

    final after = await container.read(lineupReserveProvider.future);
    expect(after.map((c) => c.id).toList(), [5]);
    final activeIds = await container.read(activeCharacterIdsProvider.future);
    expect(activeIds, [1, 4]);
  });

  test('invalidateAfterLineupChange 覆盖最小失效集合', () {
    final invalidated = <ProviderOrFamily>{};
    invalidateAfterLineupChange(invalidated.add);

    expect(
      invalidated,
      containsAll(<ProviderOrFamily>[
        activeCharacterIdsProvider,
        characterByIdProvider,
        lineupReserveProvider,
      ]),
    );
  });
}
