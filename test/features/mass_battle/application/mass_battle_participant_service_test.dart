import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/mass_battle/application/mass_battle_participant_service.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_mass_battle_participant_',
    );
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<Character> insertCharacter({
    required String name,
    required bool founder,
    bool battleReady = true,
    bool alive = true,
    int? masterId,
    double injuryHoursRemaining = 0,
  }) async {
    final isar = IsarSetup.instance;
    final character =
        Character.create(
            name: name,
            realmTier: RealmTier.xueTu,
            realmLayer: RealmLayer.qiMeng,
            attributes: Attributes(),
            rarity: RarityTier.biaoZhun,
            lineageRole: founder ? LineageRole.founder : LineageRole.disciple,
            createdAt: DateTime.utc(2026, 8, 25),
            internalForce: 3000,
            school: TechniqueSchool.gangMeng,
            isFounder: founder,
            isAlive: alive,
          )
          ..masterId = masterId
          ..injuryHoursRemaining = injuryHoursRemaining;
    await isar.writeTxn(() => isar.characters.put(character));
    if (battleReady) {
      final technique = Technique.create(
        defId: 'tech_gangmeng_jichu',
        ownerCharacterId: character.id,
        tier: TechniqueTier.values.first,
        school: TechniqueSchool.gangMeng,
        role: TechniqueRole.main,
        learnedAt: DateTime.utc(2026, 8, 25),
      );
      await isar.writeTxn(() async {
        character.mainTechniqueId = await isar.techniques.put(technique);
        await isar.characters.put(character);
      });
    }
    return character;
  }

  Future<void> pointLeader(Character leader) async {
    await IsarSetup.instance.writeTxn(() async {
      final save = SaveData()
        ..saveVersion = '0.54'
        ..createdAt = DateTime.utc(2026, 8, 25)
        ..lastSavedAt = DateTime.utc(2026, 8, 25)
        ..lastOnlineAt = DateTime.utc(2026, 8, 25)
        ..founderCharacterId = leader.id
        ..activeCharacterIds = [leader.id];
      await IsarSetup.instance.saveDatas.put(save);
    });
  }

  test('候选只来自当前代且按掌门优先，活动/疗养/死亡/无主修 fail closed', () async {
    final leader = await insertCharacter(name: '掌门', founder: true);
    final idle = await insertCharacter(
      name: '空闲门人',
      founder: false,
      masterId: leader.id,
    );
    final occupied = await insertCharacter(
      name: '闭关门人',
      founder: false,
      masterId: leader.id,
    );
    final noMain = await insertCharacter(
      name: '未修门人',
      founder: false,
      masterId: leader.id,
      battleReady: false,
    );
    final healing = await insertCharacter(
      name: '疗养门人',
      founder: false,
      masterId: leader.id,
      injuryHoursRemaining: 2,
    );
    final dead = await insertCharacter(
      name: '亡者',
      founder: false,
      masterId: leader.id,
      alive: false,
    );
    await pointLeader(leader);
    await IsarSetup.instance.writeTxn(() async {
      occupied.currentRetreatSessionId = 1;
      await IsarSetup.instance.characters.put(occupied);
    });

    final candidates = await loadMassBattleParticipantCandidates(
      isar: IsarSetup.instance,
    );
    expect(candidates.map((candidate) => candidate.character.id).toList(), [
      leader.id,
      idle.id,
      occupied.id,
      noMain.id,
      healing.id,
    ]);
    expect(
      candidates
          .where((candidate) => candidate.selectable)
          .map((c) => c.character.id),
      [leader.id, idle.id],
    );
    expect(
      candidates.map((candidate) => candidate.character.id),
      isNot(contains(dead.id)),
    );
  });

  test('exact snapshot 不允许错人、占用或悬空装备/心法，并且不回退掌门', () async {
    final leader = await insertCharacter(name: '掌门', founder: true);
    final disciple = await insertCharacter(
      name: '门人',
      founder: false,
      masterId: leader.id,
    );
    await pointLeader(leader);

    final snapshot = await resolveMassBattleParticipantSnapshot(
      isar: IsarSetup.instance,
      requestedParticipantId: disciple.id,
    );
    expect(snapshot.characterId, disciple.id);

    await IsarSetup.instance.writeTxn(() async {
      disciple.currentRetreatSessionId = 99;
      await IsarSetup.instance.characters.put(disciple);
    });
    await expectLater(
      resolveMassBattleParticipantSnapshot(
        isar: IsarSetup.instance,
        requestedParticipantId: disciple.id,
      ),
      throwsStateError,
    );
    await IsarSetup.instance.writeTxn(() async {
      disciple.currentRetreatSessionId = null;
      disciple.equippedWeaponId = 999999;
      await IsarSetup.instance.characters.put(disciple);
    });
    await expectLater(
      resolveMassBattleParticipantSnapshot(
        isar: IsarSetup.instance,
        requestedParticipantId: disciple.id,
      ),
      throwsStateError,
    );
  });
}
