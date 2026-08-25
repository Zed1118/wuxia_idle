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
import 'package:wuxia_idle/features/light_foot/application/light_foot_participant_service.dart';

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
      'wuxia_light_foot_participant_',
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
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      final save = (await isar.saveDatas.get(0))!;
      save.founderCharacterId = leader.id;
      save.activeCharacterIds = [leader.id];
      await isar.saveDatas.put(save);
    });
  }

  test('候选仅含当前掌门与当代存活门人，并按占用、疗养和主修 fail closed', () async {
    final leader = await insertCharacter(name: '掌门', founder: true);
    await insertCharacter(name: '前代祖师', founder: true);
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
      battleReady: false,
      masterId: leader.id,
    );
    final healing = await insertCharacter(
      name: '疗养门人',
      founder: false,
      masterId: leader.id,
      injuryHoursRemaining: 2,
    );
    await insertCharacter(
      name: '亡者',
      founder: false,
      alive: false,
      masterId: leader.id,
    );
    final oldGeneration = await insertCharacter(
      name: '前代门人',
      founder: false,
      masterId: 999999,
    );
    await pointLeader(leader);
    await IsarSetup.instance.writeTxn(() async {
      occupied.currentRetreatSessionId = 88;
      await IsarSetup.instance.characters.put(occupied);
    });

    final candidates = await loadLightFootParticipantCandidates(
      isar: IsarSetup.instance,
    );
    final byId = {for (final value in candidates) value.character.id: value};
    expect(
      byId.keys,
      containsAll([leader.id, idle.id, occupied.id, noMain.id]),
    );
    expect(
      candidates.where((value) => value.character.isFounder),
      hasLength(1),
    );
    expect(byId[idle.id]!.selectable, isTrue);
    expect(byId[occupied.id]!.occupied, isTrue);
    expect(byId[occupied.id]!.selectable, isFalse);
    expect(byId[noMain.id]!.hasMainTechnique, isFalse);
    expect(byId[noMain.id]!.selectable, isFalse);
    expect(byId[healing.id]!.healing, isTrue);
    expect(byId[healing.id]!.selectable, isFalse);
    expect(byId, isNot(contains(oldGeneration.id)));
  });

  test('非 active 空闲门人装配 exact snapshot；状态漂移和悬空装备均拒绝且不回退掌门', () async {
    final leader = await insertCharacter(name: '掌门', founder: true);
    final disciple = await insertCharacter(
      name: '门人',
      founder: false,
      masterId: leader.id,
    );
    await pointLeader(leader);

    final snapshot = await resolveLightFootParticipantSnapshot(
      isar: IsarSetup.instance,
      requestedParticipantId: disciple.id,
    );
    expect(snapshot.characterId, disciple.id);

    await IsarSetup.instance.writeTxn(() async {
      disciple.currentRetreatSessionId = 99;
      await IsarSetup.instance.characters.put(disciple);
    });
    await expectLater(
      resolveLightFootParticipantSnapshot(
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
      resolveLightFootParticipantSnapshot(
        isar: IsarSetup.instance,
        requestedParticipantId: disciple.id,
      ),
      throwsStateError,
    );
  });

  test('无效掌门指针使候选和精确选择整体 fail closed', () async {
    final disciple = await insertCharacter(name: '门人', founder: false);
    await IsarSetup.instance.writeTxn(() async {
      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      save.founderCharacterId = 999999;
      await IsarSetup.instance.saveDatas.put(save);
    });

    await expectLater(
      loadLightFootParticipantCandidates(isar: IsarSetup.instance),
      throwsStateError,
    );
    await expectLater(
      resolveLightFootParticipantSnapshot(
        isar: IsarSetup.instance,
        requestedParticipantId: disciple.id,
      ),
      throwsStateError,
    );
  });
}
