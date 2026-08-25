import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/activity/domain/activity_member_snapshot.dart';
import 'package:wuxia_idle/features/battle/domain/phase0a/activity_participation_request.dart';
import 'package:wuxia_idle/features/boss_gauntlet/domain/boss_gauntlet_run.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/tower/application/tower_automation_admission.dart';
import 'package:wuxia_idle/features/tower/domain/tower_automation_policy.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  late Directory tempDir;
  late int leaderId;

  setUpAll(() async {
    await initializeTestIsarCore();
    await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tower_automation_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    await Phase2SeedService(isar: IsarSetup.instance).seedP3();
    final save = await IsarSetup.instance.saveDatas.get(0);
    final firstCharacter = await IsarSetup.instance.characters
        .where()
        .findFirst();
    leaderId = firstCharacter!.id;
    await IsarSetup.instance.writeTxn(() async {
      save!
        ..founderCharacterId = leaderId
        ..activeCharacterIds = [leaderId];
      await IsarSetup.instance.saveDatas.put(save);
      await IsarSetup.instance.towerProgress.put(
        TowerProgress()
          ..saveDataId = save.slotId
          ..highestClearedFloor = 7
          ..highestClearedAt = DateTime(2026, 8, 25)
          ..createdAt = DateTime(2026, 8, 25)
          ..currentCycleIndex = 1
          ..maxClearedCycle = 1,
      );
    });
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  ActivityParticipationRequest request({int? characterId}) {
    final id = characterId ?? leaderId;
    return ActivityParticipationRequest(
      contentId: 'tower_7',
      contentKind: ActivityContentKind.tower,
      characterId: id,
      loadoutPlanId: towerAutomationLoadoutPlanId(
        floorIndex: 7,
        characterId: id,
      ),
      participation: ActivityParticipationMode.direct,
      controller: ActivityController.playerBot,
      clock: ActivityClock.headless,
      entryKind: ActivityEntryKind.sweep,
    );
  }

  Future<Character> insertOtherCharacter() async {
    final leader = (await IsarSetup.instance.characters.get(leaderId))!;
    final other = Character.create(
      name: '异代门人',
      realmTier: leader.realmTier,
      realmLayer: leader.realmLayer,
      attributes: Attributes(),
      rarity: leader.rarity,
      lineageRole: LineageRole.disciple,
      createdAt: DateTime(2026, 8, 25),
      masterId: leaderId,
    );
    await IsarSetup.instance.writeTxn(
      () => IsarSetup.instance.characters.put(other),
    );
    return other;
  }

  test(
    'current leader exact snapshot is admitted for a cleared floor',
    () async {
      final admission = await TowerAutomationAdmissionService(
        IsarSetup.instance,
      ).admit(request: request(), floorIndex: 7, cycleIndex: 1);

      expect(admission.participantCharacterId, leaderId);
      expect(admission.snapshot.characterId, leaderId);
      expect(admission.currentCycleIndex, 1);
      expect(admission.highestClearedFloor, 7);
    },
  );

  test(
    'wrong participant and dangling loadout fail before runner assembly',
    () async {
      await expectLater(
        TowerAutomationAdmissionService(IsarSetup.instance).admit(
          request: request(characterId: leaderId + 9999),
          floorIndex: 7,
          cycleIndex: 1,
        ),
        throwsStateError,
      );

      final leader = await IsarSetup.instance.characters.get(leaderId);
      await IsarSetup.instance.writeTxn(() async {
        leader!.equippedWeaponId = 999999;
        await IsarSetup.instance.characters.put(leader);
      });
      await expectLater(
        TowerAutomationAdmissionService(
          IsarSetup.instance,
        ).admit(request: request(), floorIndex: 7, cycleIndex: 1),
        throwsStateError,
      );
    },
  );

  test(
    'missing, non-founder, dead, healing, and no-main leader fail closed',
    () async {
      final isar = IsarSetup.instance;
      final save = (await isar.saveDatas.get(0))!;
      final leader = (await isar.characters.get(leaderId))!;
      final mainTechniqueId = leader.mainTechniqueId;
      final another = await insertOtherCharacter();
      final service = TowerAutomationAdmissionService(isar);

      await isar.writeTxn(() async {
        save.founderCharacterId = 999999;
        await isar.saveDatas.put(save);
      });
      await expectLater(
        service.admit(request: request(), floorIndex: 7, cycleIndex: 1),
        throwsStateError,
      );

      await isar.writeTxn(() async {
        save.founderCharacterId = another.id;
        await isar.saveDatas.put(save);
      });
      await expectLater(
        service.admit(
          request: request(characterId: another.id),
          floorIndex: 7,
          cycleIndex: 1,
        ),
        throwsStateError,
      );

      await isar.writeTxn(() async {
        save.founderCharacterId = leaderId;
        leader.isAlive = false;
        await isar.saveDatas.put(save);
        await isar.characters.put(leader);
      });
      await expectLater(
        service.admit(request: request(), floorIndex: 7, cycleIndex: 1),
        throwsStateError,
      );

      await isar.writeTxn(() async {
        leader
          ..isAlive = true
          ..injuryHoursRemaining = 2;
        await isar.characters.put(leader);
      });
      await expectLater(
        service.admit(request: request(), floorIndex: 7, cycleIndex: 1),
        throwsStateError,
      );

      await isar.writeTxn(() async {
        leader
          ..injuryHoursRemaining = 0
          ..mainTechniqueId = null;
        await isar.characters.put(leader);
      });
      await expectLater(
        service.admit(request: request(), floorIndex: 7, cycleIndex: 1),
        throwsStateError,
      );
      expect(mainTechniqueId, isNotNull);
    },
  );

  test('character and reserved loadout occupancy fail closed', () async {
    final isar = IsarSetup.instance;
    final leader = (await isar.characters.get(leaderId))!;
    final another = await insertOtherCharacter();
    final service = TowerAutomationAdmissionService(isar);

    await isar.writeTxn(() async {
      leader.currentRetreatSessionId = 88;
      await isar.characters.put(leader);
    });
    await expectLater(
      service.admit(request: request(), floorIndex: 7, cycleIndex: 1),
      throwsStateError,
    );

    await isar.writeTxn(() async {
      leader.currentRetreatSessionId = null;
      await isar.characters.put(leader);
      await isar.expeditionRuns.put(
        ExpeditionRun()
          ..saveDataId = 0
          ..policy = ExpeditionPolicy.yanJingCaiYao
          ..seed = 1
          ..departedAt = DateTime(2026, 8, 25)
          ..members = [
            ActivityMemberSnapshot()
              ..characterId = another.id
              ..reservedTechniqueIds = [leader.mainTechniqueId!],
          ],
      );
    });
    await expectLater(
      service.admit(request: request(), floorIndex: 7, cycleIndex: 1),
      throwsStateError,
    );
  });

  test('duplicate activity occupancy fails closed', () async {
    final isar = IsarSetup.instance;
    await isar.writeTxn(() async {
      await isar.expeditionRuns.put(
        ExpeditionRun()
          ..saveDataId = 0
          ..policy = ExpeditionPolicy.yanJingCaiYao
          ..seed = 1
          ..departedAt = DateTime(2026, 8, 25)
          ..members = [ActivityMemberSnapshot()..characterId = leaderId],
      );
      await isar.bossGauntletRuns.put(
        BossGauntletRun()
          ..saveDataId = 0
          ..seed = 2
          ..members = [ActivityMemberSnapshot()..characterId = leaderId],
      );
    });

    await expectLater(
      TowerAutomationAdmissionService(
        isar,
      ).admit(request: request(), floorIndex: 7, cycleIndex: 1),
      throwsStateError,
    );
  });

  test('participant or progress change makes an admission stale', () async {
    final service = TowerAutomationAdmissionService(IsarSetup.instance);
    final admission = await service.admit(
      request: request(),
      floorIndex: 7,
      cycleIndex: 1,
    );
    final leader = await IsarSetup.instance.characters.get(leaderId);
    await IsarSetup.instance.writeTxn(() async {
      leader!.mainTechniqueId = null;
      await IsarSetup.instance.characters.put(leader);
    });

    await expectLater(service.revalidate(admission), throwsStateError);
  });

  test('progress change makes an admission stale', () async {
    final service = TowerAutomationAdmissionService(IsarSetup.instance);
    final admission = await service.admit(
      request: request(),
      floorIndex: 7,
      cycleIndex: 1,
    );
    final progress =
        (await IsarSetup.instance.towerProgress.where().findAll()).single;
    await IsarSetup.instance.writeTxn(() async {
      progress.highestClearedFloor = 8;
      await IsarSetup.instance.towerProgress.put(progress);
    });

    await expectLater(service.revalidate(admission), throwsStateError);
  });
}
