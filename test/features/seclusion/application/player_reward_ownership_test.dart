import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/ascension/application/ascend_service.dart';
import 'package:wuxia_idle/features/debug/application/phase2_seed_service.dart';
import 'package:wuxia_idle/features/inventory/application/item_use_service.dart';
import 'package:wuxia_idle/features/onboarding/application/onboarding_service.dart';
import 'package:wuxia_idle/features/onboarding/domain/founder_creation_selection.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/seclusion/application/seclusion_service.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';
import 'package:wuxia_idle/features/seclusion/domain/retreat_session.dart';

import '../../../support/isar_test_support.dart';
import '../../../support/test_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late Isar isar;
  late GameRepository repo;
  final startedAt = DateTime(2026, 9, 10, 8);

  setUpAll(() async {
    await initializeTestIsarCore();
    repo = await loadTestGameRepository();
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('wuxia_reward_owner_');
    await IsarSetup.init(directory: directory, inspector: false);
    isar = IsarSetup.instance;
    await Phase2SeedService(isar: isar).seedMasterDisciple();
    await isar.writeTxn(() async {
      final founder = (await isar.characters.get(1))!;
      founder.realmTier = repo.numbers.ascension.requiredRealmTier!;
      founder.realmLayer = repo.numbers.ascension.requiredRealmLayer!;
      await isar.characters.put(founder);
      final required = repo.numbers.ascension.clearedStagesRequired;
      final progress = MainlineProgress()
        ..saveDataId = IsarSetup.currentSlotId
        ..currentChapterIndex = 6
        ..clearedStageIds = required.toList()
        ..clearedAt = required.map((_) => startedAt).toList();
      await isar.mainlineProgress.put(progress);
      final save = (await isar.saveDatas.get(0))!;
      save.createdAt = startedAt.subtract(const Duration(days: 1));
      save.lastOnlineAt = startedAt;
      save.passiveLastSettledAt = startedAt;
      await isar.saveDatas.put(save);
    });
  });

  tearDown(() async {
    await IsarSetup.close();
    await directory.delete(recursive: true);
  });

  Future<void> ascend({DateTime? now}) async {
    final founder = (await isar.characters.get(1))!;
    final service = AscendService(isar, repo.numbers);
    expect((await service.computeEligibility()).canAscend, isTrue);
    await isar.writeTxn(
      () => service.performAscend(
        {founder.equippedWeaponId!: 2, founder.equippedArmorId!: 2},
        promotedDiscipleId: 2,
        now: now ?? startedAt,
      ),
    );
    expect((await isar.saveDatas.get(0))!.founderCharacterId, 2);
    expect((await isar.characters.get(1))!.isFounder, isTrue);
    expect((await isar.characters.get(2))!.isFounder, isTrue);
  }

  Future<RetreatSession> start({DateTime? now}) async =>
      SeclusionService(isar: isar).startRetreat(
        mapType: RetreatMapType.shanLin,
        saveDataId: IsarSetup.currentSlotId,
        characterId: 1,
        charRealmTier: (await isar.characters.get(1))!.realmTier,
        maps: repo.seclusionMaps,
        now: now ?? startedAt,
      );

  test(
    'experience pill after real succession belongs to current leader',
    () async {
      await ascend();
      final beforeOld = (await isar.characters.get(1))!.experience;
      final beforeNew = (await isar.characters.get(2))!.experience;
      final def = repo.itemDefs['item_jingyandan_mid']!;
      await isar.writeTxn(
        () => isar.inventoryItems.put(
          InventoryItem()
            ..defId = def.defId
            ..itemType = ItemType.jingYanDan
            ..quantity = 1
            ..firstObtainedAt = startedAt
            ..lastObtainedAt = startedAt,
        ),
      );
      final result = await ItemUseService.use(
        isar,
        def: def,
        realmLookup: repo.getRealm,
        isLayerLocked: (_, _) => true,
      );
      expect(result.kind, ItemUseKind.experienceApplied);
      expect((await isar.characters.get(1))!.experience, beforeOld);
      expect(
        (await isar.characters.get(2))!.experience,
        greaterThan(beforeNew),
      );
      expect(await isar.inventoryItems.getByDefId(def.defId), isNull);
    },
  );

  test(
    'succession cannot redirect an existing retreat to new leader',
    () async {
      final session = await start();
      await ascend();
      final before = (await isar.characters.get(2))!.experience;
      final service = SeclusionService(isar: isar);
      await expectLater(
        service.completeRetreat(
          session: session,
          characterId: 2,
          config: repo.numbers.retreat,
          maps: repo.seclusionMaps,
          now: startedAt.add(const Duration(hours: 8)),
        ),
        throwsStateError,
      );
      expect((await isar.characters.get(2))!.experience, before);
      expect(
        (await isar.characters.get(1))!.currentRetreatSessionId,
        session.id,
      );
      expect(
        (await isar.retreatSessions.get(session.id))!.status,
        RetreatStatus.active,
      );
      final result = await service.completeRetreat(
        session: session,
        characterId: 1,
        config: repo.numbers.retreat,
        maps: repo.seclusionMaps,
        now: startedAt.add(const Duration(hours: 8)),
      );
      expect(result.experiencePoints, greaterThan(0));
      expect((await isar.characters.get(2))!.experience, before);
      expect((await isar.characters.get(1))!.currentRetreatSessionId, isNull);
      await IsarSetup.close();
      await IsarSetup.init(directory: directory, inspector: false);
      isar = IsarSetup.instance;
      expect(
        (await isar.retreatSessions.get(session.id))!.status,
        RetreatStatus.completed,
      );
    },
  );

  test('changing maps must not abandon accumulated retreat rewards', () async {
    final old = await start();
    final service = SeclusionService(isar: isar);
    await expectLater(
      service.startRetreat(
        mapType: RetreatMapType.duanYaJueBi,
        saveDataId: IsarSetup.currentSlotId,
        characterId: 1,
        charRealmTier: (await isar.characters.get(1))!.realmTier,
        maps: repo.seclusionMaps,
        now: startedAt.add(const Duration(hours: 8)),
      ),
      throwsStateError,
    );
    expect(
      (await isar.retreatSessions.get(old.id))!.status,
      RetreatStatus.active,
    );
    expect((await isar.characters.get(1))!.currentRetreatSessionId, old.id);
  });

  test(
    'ambiguous retreat ownership fails without consuming the session',
    () async {
      final session = await start();
      await isar.writeTxn(() async {
        final other = (await isar.characters.get(2))!;
        other.currentRetreatSessionId = session.id;
        await isar.characters.put(other);
      });
      await expectLater(
        SeclusionService(isar: isar).completeRetreat(
          session: session,
          characterId: 1,
          config: repo.numbers.retreat,
          maps: repo.seclusionMaps,
          now: startedAt.add(const Duration(hours: 8)),
        ),
        throwsStateError,
      );
      expect(
        (await isar.retreatSessions.get(session.id))!.status,
        RetreatStatus.active,
      );
      expect(session.status, RetreatStatus.active);
    },
  );

  test(
    'collection uses persisted timing and cannot replay a stale session',
    () async {
      final session = await start();
      final stale = (await isar.retreatSessions.get(session.id))!;
      stale.startedAt = startedAt.subtract(const Duration(hours: 72));
      final service = SeclusionService(isar: isar);
      final result = await service.completeRetreat(
        session: stale,
        characterId: 1,
        config: repo.numbers.retreat,
        maps: repo.seclusionMaps,
        now: startedAt.add(const Duration(hours: 8)),
      );
      expect(result.elapsedHours, 8);
      final before = (await isar.characters.get(1))!.experience;
      await expectLater(
        service.completeRetreat(
          session: session,
          characterId: 1,
          config: repo.numbers.retreat,
          maps: repo.seclusionMaps,
          now: startedAt.add(const Duration(hours: 9)),
        ),
        throwsStateError,
      );
      expect((await isar.characters.get(1))!.experience, before);
    },
  );

  test(
    'missing current-leader pointer does not feed a historical founder',
    () async {
      await ascend();
      final def = repo.itemDefs['item_jingyandan_mid']!;
      await isar.writeTxn(() async {
        final save = (await isar.saveDatas.get(0))!;
        save.founderCharacterId = null;
        await isar.saveDatas.put(save);
        await isar.inventoryItems.put(
          InventoryItem()
            ..defId = def.defId
            ..itemType = ItemType.jingYanDan
            ..quantity = 1
            ..firstObtainedAt = startedAt
            ..lastObtainedAt = startedAt,
        );
      });
      final result = await ItemUseService.use(
        isar,
        def: def,
        realmLookup: repo.getRealm,
      );
      expect(result.kind, ItemUseKind.noTarget);
      expect((await isar.inventoryItems.getByDefId(def.defId))!.quantity, 1);
    },
  );

  test(
    'real succession settles elapsed time and fractions for the old leader',
    () async {
      await isar.writeTxn(() async {
        final previous = (await isar.characters.get(1))!;
        previous.passiveExperienceRemainder = 0.25;
        await isar.characters.put(previous);
      });
      final previous = (await isar.characters.get(1))!;
      final nextBefore = (await isar.characters.get(2))!.experience;
      final at = startedAt.add(const Duration(hours: 2, minutes: 10));
      final hours =
          at.difference(startedAt).inMicroseconds /
          Duration.microsecondsPerHour;
      final exact =
          0.25 +
          repo.numbers.passiveIdle.baseExpPerHour *
              repo.numbers.passiveIdle.realmScaleFor(previous.realmTier) *
              hours;

      await ascend(now: at);
      final retired = (await isar.characters.get(1))!;
      expect(retired.experience, previous.experience + exact.floor());
      expect(
        retired.passiveExperienceRemainder,
        closeTo(exact - exact.floor(), 1e-8),
      );
      expect((await isar.characters.get(2))!.experience, nextBefore);
      expect((await isar.saveDatas.get(0))!.passiveLastSettledAt, at);
      await IsarSetup.close();
      await IsarSetup.init(directory: directory, inspector: false);
      isar = IsarSetup.instance;
      expect(
        (await isar.characters.get(1))!.passiveExperienceRemainder,
        closeTo(exact - exact.floor(), 1e-8),
      );
    },
  );

  Future<void> placeLeaderBeforeTierBoundary() async {
    await isar.writeTxn(() async {
      final founder = (await isar.characters.get(1))!;
      founder.realmTier = RealmTier.xueTu;
      founder.realmLayer = RealmLayer.dengFeng;
      founder.experience =
          repo.getRealm(RealmTier.xueTu, RealmLayer.dengFeng).experienceToNext -
          1;
      founder.passiveExperienceRemainder = 0;
      await isar.characters.put(founder);
      final progress = (await isar.mainlineProgress
          .filter()
          .saveDataIdEqualTo(IsarSetup.currentSlotId)
          .findFirst())!;
      progress.clearedStageIds = {
        ...progress.clearedStageIds,
        ...repo.numbers.innerDemon.requiredRealmLayer.keys,
      }.toList();
      progress.clearedAt = progress.clearedStageIds
          .map((_) => startedAt)
          .toList();
      await isar.mainlineProgress.put(progress);
    });
  }

  test(
    'experience pill uses the realm reached by passive time before use',
    () async {
      await placeLeaderBeforeTierBoundary();
      final def = repo.itemDefs['item_jingyandan_mid']!;
      await isar.writeTxn(
        () => isar.inventoryItems.put(
          InventoryItem()
            ..defId = def.defId
            ..itemType = ItemType.jingYanDan
            ..quantity = 1
            ..firstObtainedAt = startedAt
            ..lastObtainedAt = startedAt,
        ),
      );
      final at = startedAt.add(const Duration(minutes: 20));
      final result = await ItemUseService.use(
        isar,
        def: def,
        realmLookup: repo.getRealm,
        isLayerLocked: (_, _) => true,
        now: at,
      );
      expect(result.kind, ItemUseKind.experienceApplied);
      final founder = (await isar.characters.get(1))!;
      expect(founder.realmTier, RealmTier.sanLiu);
      final expected =
          (repo.getRealm(RealmTier.sanLiu, RealmLayer.qiMeng).experienceToNext *
                  def.layerFraction!)
              .round();
      expect(founder.experience, expected);
      final save = (await isar.saveDatas.get(0))!;
      expect(save.totalPassiveExperience, 1);
      expect(save.passiveLastSettledAt, at);
      expect(await isar.inventoryItems.getByDefId(def.defId), isNull);
    },
  );

  test(
    'retreat starts after ordinary settlement with a fresh realm snapshot',
    () async {
      await placeLeaderBeforeTierBoundary();
      final at = startedAt.add(const Duration(minutes: 20));
      final session = await start(now: at);
      expect(session.realmTierAtStart, RealmTier.sanLiu);
      expect((await isar.characters.get(1))!.realmTier, RealmTier.sanLiu);
      final save = (await isar.saveDatas.get(0))!;
      expect(save.totalPassiveExperience, 1);
      expect(save.passiveLastSettledAt, at);
      expect(save.passiveMojianshiRemainder, closeTo(1 / 12, 1e-9));
    },
  );

  test(
    'retreat completion excludes its full interval from ordinary accrual',
    () async {
      final session = await start();
      final end = startedAt.add(const Duration(hours: 100));
      final completed = await SeclusionService(isar: isar).completeRetreat(
        session: session,
        characterId: 1,
        config: repo.numbers.retreat,
        maps: repo.seclusionMaps,
        now: end,
      );
      var save = (await isar.saveDatas.get(0))!;
      expect(save.passiveLastSettledAt, end);
      expect(save.lastOnlineAt, end);
      expect(save.totalPassiveExperience, completed.passive.experience);
      final experience = (await isar.characters.get(1))!.experience;
      expect(
        await OfflinePassiveService.settleWindow(isar: isar, now: end),
        isNull,
      );
      save = (await isar.saveDatas.get(0))!;
      expect(save.totalPassiveExperience, completed.passive.experience);
      expect((await isar.characters.get(1))!.experience, experience);
    },
  );

  test(
    'first founder establishes the ledger at creation, excluding time on the form',
    () async {
      await IsarSetup.close();
      await directory.delete(recursive: true);
      directory = await Directory.systemTemp.createTemp('wuxia_first_owner_');
      await IsarSetup.init(directory: directory, inspector: false);
      isar = IsarSetup.instance;
      await isar.writeTxn(() async {
        final save = (await isar.saveDatas.get(0))!;
        save.createdAt = startedAt.subtract(const Duration(hours: 12));
        save.lastOnlineAt = save.createdAt;
        await isar.saveDatas.put(save);
      });
      expect(
        await OnboardingService(isar: isar).createFoundingMaster(
          selection: FounderCreationSelection(
            school: repo.founderCreation.schools.first,
            origin: repo.founderCreation.origins.first,
            fate: repo.founderCreation.fatePool.first,
          ),
          now: startedAt,
        ),
        isTrue,
      );
      expect((await isar.saveDatas.get(0))!.passiveLastSettledAt, startedAt);
      final result = await OfflinePassiveService.settleWindow(
        isar: isar,
        now: startedAt.add(const Duration(hours: 8)),
      );
      expect(result?.experience, 24);
      expect(result?.mojianshi, 2);
    },
  );
}
