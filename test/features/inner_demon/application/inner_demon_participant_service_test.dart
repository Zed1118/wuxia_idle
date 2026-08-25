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
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/inner_demon/application/inner_demon_participant_service.dart';
import 'package:wuxia_idle/features/inner_demon/domain/inner_demon_participation_policy.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'wuxia_inner_demon_participant_',
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
    int? masterId,
    bool alive = true,
    bool battleReady = true,
    double injuryHours = 0,
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
          ..injuryHoursRemaining = injuryHours;
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
      final save = (await IsarSetup.instance.saveDatas.get(0))!;
      save.founderCharacterId = leader.id;
      save.activeCharacterIds = [leader.id];
      await IsarSetup.instance.saveDatas.put(save);
    });
  }

  ActivityParticipationRequest request(int characterId) =>
      ActivityParticipationRequest(
        contentId: 'stage_inner_demon_01',
        contentKind: ActivityContentKind.innerDemon,
        characterId: characterId,
        loadoutPlanId: innerDemonLoadoutPlanId(
          stageId: 'stage_inner_demon_01',
          characterId: characterId,
        ),
        participation: ActivityParticipationMode.direct,
        controller: ActivityController.human,
        clock: ActivityClock.realtime,
        entryKind: ActivityEntryKind.firstClear,
      );

  test('当前代目标本人装配 exact snapshot，不回退掌门', () async {
    final leader = await insertCharacter(name: '掌门', founder: true);
    final disciple = await insertCharacter(
      name: '门人',
      founder: false,
      masterId: leader.id,
    );
    await pointLeader(leader);

    final snapshot = await resolveInnerDemonParticipantSnapshot(
      isar: IsarSetup.instance,
      request: request(disciple.id),
      expectedStageId: 'stage_inner_demon_01',
      expectedCharacterId: disciple.id,
    );

    expect(snapshot.characterId, disciple.id);
    expect(snapshot.characterId, isNot(leader.id));
  });

  test('错人、占用、疗养、死亡和无主修全部 fail closed', () async {
    final leader = await insertCharacter(name: '掌门', founder: true);
    final target = await insertCharacter(
      name: '目标',
      founder: false,
      masterId: leader.id,
    );
    await pointLeader(leader);

    await expectLater(
      resolveInnerDemonParticipantSnapshot(
        isar: IsarSetup.instance,
        request: request(leader.id),
        expectedStageId: 'stage_inner_demon_01',
        expectedCharacterId: target.id,
      ),
      throwsStateError,
    );

    await IsarSetup.instance.writeTxn(() async {
      target.currentRetreatSessionId = 1;
      await IsarSetup.instance.characters.put(target);
    });
    await expectLater(
      resolveInnerDemonParticipantSnapshot(
        isar: IsarSetup.instance,
        request: request(target.id),
        expectedStageId: 'stage_inner_demon_01',
        expectedCharacterId: target.id,
      ),
      throwsStateError,
    );

    await IsarSetup.instance.writeTxn(() async {
      target.currentRetreatSessionId = null;
      target.injuryHoursRemaining = 2;
      await IsarSetup.instance.characters.put(target);
    });
    await expectLater(
      resolveInnerDemonParticipantSnapshot(
        isar: IsarSetup.instance,
        request: request(target.id),
        expectedStageId: 'stage_inner_demon_01',
        expectedCharacterId: target.id,
      ),
      throwsStateError,
    );

    await IsarSetup.instance.writeTxn(() async {
      target.injuryHoursRemaining = 0;
      target.isAlive = false;
      await IsarSetup.instance.characters.put(target);
    });
    await expectLater(
      resolveInnerDemonParticipantSnapshot(
        isar: IsarSetup.instance,
        request: request(target.id),
        expectedStageId: 'stage_inner_demon_01',
        expectedCharacterId: target.id,
      ),
      throwsStateError,
    );

    await IsarSetup.instance.writeTxn(() async {
      target.isAlive = true;
      target.mainTechniqueId = null;
      await IsarSetup.instance.characters.put(target);
    });
    await expectLater(
      resolveInnerDemonParticipantSnapshot(
        isar: IsarSetup.instance,
        request: request(target.id),
        expectedStageId: 'stage_inner_demon_01',
        expectedCharacterId: target.id,
      ),
      throwsStateError,
    );
  });

  test('跨代目标与悬空心法或装备全部 fail closed', () async {
    final leader = await insertCharacter(name: '掌门', founder: true);
    final otherFounder = await insertCharacter(name: '旧掌门', founder: true);
    final target = await insertCharacter(
      name: '旧代门人',
      founder: false,
      masterId: otherFounder.id,
    );
    await pointLeader(leader);

    await expectLater(
      resolveInnerDemonParticipantSnapshot(
        isar: IsarSetup.instance,
        request: request(target.id),
        expectedStageId: 'stage_inner_demon_01',
        expectedCharacterId: target.id,
      ),
      throwsStateError,
    );

    target.masterId = leader.id;
    target.mainTechniqueId = 999999;
    await IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.characters.put(target),
    );
    await expectLater(
      resolveInnerDemonParticipantSnapshot(
        isar: IsarSetup.instance,
        request: request(target.id),
        expectedStageId: 'stage_inner_demon_01',
        expectedCharacterId: target.id,
      ),
      throwsStateError,
    );

    final technique = Technique.create(
      defId: 'tech_gangmeng_jichu',
      ownerCharacterId: target.id,
      tier: TechniqueTier.values.first,
      school: TechniqueSchool.gangMeng,
      role: TechniqueRole.main,
      learnedAt: DateTime.utc(2026, 8, 25),
    );
    await IsarSetup.instance.writeTxn(() async {
      target.mainTechniqueId = await IsarSetup.instance.techniques.put(
        technique,
      );
      target.equippedWeaponId = 999999;
      await IsarSetup.instance.characters.put(target);
    });
    await expectLater(
      resolveInnerDemonParticipantSnapshot(
        isar: IsarSetup.instance,
        request: request(target.id),
        expectedStageId: 'stage_inner_demon_01',
        expectedCharacterId: target.id,
      ),
      throwsStateError,
    );
  });
}
