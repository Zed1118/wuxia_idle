import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_provider.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/inheritance/application/founder_buff_providers.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// `founderBuffActiveProvider` 行为测（2026-07-19 夜批 coverage 补强，
/// 基线 2/5 行）。
///
/// 真 Isar + 真 GameRepository + ProviderContainer 真读（生产入口 =
/// CharacterDerivedStats 的 founderBuffActive 可选参注入），钉：
///   - Isar 未 init / active 空 → false
///   - founder 在 activeCharacterIds → true(yaml enabled_when_alive=true)
///   - founder 被移出 active → false
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_founder_buff_');
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  Future<int> seedFounder({required bool inActive}) async {
    final realm = GameRepository.instance.getRealm(
      RealmTier.xueTu,
      RealmLayer.qiMeng,
    );
    late int id;
    await IsarSetup.instance.writeTxn(() async {
      id = await IsarSetup.instance.characters.put(
        Character.create(
          name: '祖师',
          realmTier: RealmTier.xueTu,
          realmLayer: RealmLayer.qiMeng,
          attributes: Attributes(),
          rarity: RarityTier.biaoZhun,
          lineageRole: LineageRole.founder,
          createdAt: DateTime(2026, 7, 19),
          internalForce: realm.internalForceMax,
          internalForceMax: realm.internalForceMax,
          experienceToNextLayer: realm.experienceToNext,
          isFounder: true,
          isActive: inActive,
        ),
      );
      final save = (await IsarSetup.instance.saveDatas.get(0))!
        ..founderCharacterId = id
        ..activeCharacterIds = inActive ? [id] : const <int>[];
      await IsarSetup.instance.saveDatas.put(save);
    });
    return id;
  }

  test('Isar 未 init → false', () async {
    final container = makeContainer();
    expect(await container.read(founderBuffActiveProvider.future), isFalse);
  });

  test('active 空 → false', () async {
    await IsarSetup.init(directory: tempDir, inspector: false);
    final container = makeContainer();
    container.invalidate(isarProvider);
    expect(
      await container.read(founderBuffActiveProvider.future),
      isFalse,
      reason: 'SaveData 未 seed active → false',
    );
  });

  test('founder 在 active → true;移出 active → false', () async {
    await IsarSetup.init(directory: tempDir, inspector: false);
    final founderId = await seedFounder(inActive: true);
    final container = makeContainer();
    container.invalidate(isarProvider);

    expect(
      await container.read(founderBuffActiveProvider.future),
      isTrue,
      reason: 'enabled_when_alive=true 且 founder 在阵',
    );

    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.instance.saveDatas.get(0))!
        ..activeCharacterIds = const <int>[];
      await IsarSetup.instance.saveDatas.put(save);
    });
    container.invalidate(founderBuffActiveProvider);
    expect(
      await container.read(founderBuffActiveProvider.future),
      isFalse,
      reason: 'founder($founderId) 移出 active → buff 失效',
    );
  });
}
