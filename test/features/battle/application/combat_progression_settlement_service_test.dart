import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/game_event.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/battle/application/combat_progression_settlement_service.dart';

import '../../../support/test_data.dart';
import '../../../support/isar_test_support.dart';

void main() {
  late GameRepository repository;
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_progression_settlement_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  tearDownAll(GameRepository.resetForTest);

  Character makeCharacter({required int id, required String name}) {
    final realm = repository.getRealm(RealmTier.xueTu, RealmLayer.qiMeng);
    return Character.create(
      name: name,
      realmTier: RealmTier.xueTu,
      realmLayer: RealmLayer.qiMeng,
      attributes: Attributes(),
      rarity: RarityTier.biaoZhun,
      lineageRole: LineageRole.founder,
      createdAt: DateTime(2026, 7, 13),
      internalForce: realm.internalForceMax,
      internalForceMax: realm.internalForceMax,
      experienceToNextLayer: realm.experienceToNext,
    )..id = id;
  }

  test('applyExperience rewards every character and keeps stable ids', () {
    final characters = [
      makeCharacter(id: 1, name: '同名'),
      makeCharacter(id: 2, name: '同名'),
      makeCharacter(id: 3, name: '三徒'),
    ];
    final service = CombatProgressionSettlementService(repository);

    final entries = service.applyExperience(
      characters: characters,
      experienceReward: 100,
      clearedStageIds: const {},
    );

    expect(entries.map((entry) => entry.characterId), [1, 2, 3]);
    expect(
      entries.every((entry) => entry.result.experienceGained == 100),
      isTrue,
    );
  });

  test('zero reward returns no entries and mutates no experience', () {
    final character = makeCharacter(id: 1, name: '祖师');
    final before = character.experience;
    final service = CombatProgressionSettlementService(repository);

    final entries = service.applyExperience(
      characters: [character],
      experienceReward: 0,
      clearedStageIds: const {},
    );

    expect(entries, isEmpty);
    expect(character.experience, before);
  });

  test('same-name characters are routed by characterId', () async {
    final isar = IsarSetup.instance;
    final first = makeCharacter(id: 1, name: '同名');
    final second = makeCharacter(id: 2, name: '同名');
    final service = CombatProgressionSettlementService(repository);
    final entries = service.applyExperience(
      characters: [first, second],
      experienceReward: repository
          .getRealm(RealmTier.xueTu, RealmLayer.qiMeng)
          .experienceToNext,
      clearedStageIds: const {},
    );

    await isar.writeTxn(() async {
      await isar.characters.putAll([first, second]);
      await service.recordCommonEvents(
        isar: isar,
        characters: [first, second],
        equipmentsByCharacter: const {},
        resonanceUpgradedEquipmentIds: const [],
        advancements: entries,
        founderId: null,
        bossVictory: null,
      );
    });

    final events = await isar.gameEvents.where().findAll();
    expect(events.map((event) => event.relatedCharacterId).toSet(), {1, 2});
  });

  test(
    'caller transaction rollback leaves no partial progression events',
    () async {
      final isar = IsarSetup.instance;
      final founder = makeCharacter(id: 1, name: '祖师');
      final service = CombatProgressionSettlementService(repository);
      final entries = service.applyExperience(
        characters: [founder],
        experienceReward: repository
            .getRealm(RealmTier.xueTu, RealmLayer.qiMeng)
            .experienceToNext,
        clearedStageIds: const {},
      );

      await expectLater(
        isar.writeTxn(() async {
          await isar.characters.put(founder);
          await service.recordCommonEvents(
            isar: isar,
            characters: [founder],
            equipmentsByCharacter: const {},
            resonanceUpgradedEquipmentIds: const [],
            advancements: entries,
            founderId: founder.id,
            bossVictory: null,
          );
          throw StateError('rollback probe');
        }),
        throwsStateError,
      );

      expect(await isar.gameEvents.where().count(), 0);
      expect(await isar.characters.get(founder.id), isNull);
    },
  );
}
