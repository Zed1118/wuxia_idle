import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/core/domain/technique.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_service.dart';
import 'package:wuxia_idle/features/expedition/application/expedition_timeline.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_milestone_record.dart';
import 'package:wuxia_idle/features/expedition/domain/expedition_run.dart';
import 'package:wuxia_idle/features/inventory/application/item_use_service.dart';
import 'package:wuxia_idle/features/reward/domain/reward_claim_receipt.dart';
import 'package:wuxia_idle/features/seclusion/application/offline_passive_service.dart';

import '../../support/isar_test_support.dart';
import '../../support/phase0a_ch1_founder_profile.dart';

void main() {
  late Directory directory;
  late GameRepository repository;
  late Isar isar;
  late ExpeditionService service;
  late DateTime departedAt;

  setUpAll(() async {
    await initializeTestIsarCore();
    repository = await GameRepository.loadAllDefs(
      loader: (path) => File(path).readAsString(),
    );
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('expedition_boundary_');
    await IsarSetup.init(directory: directory, inspector: false);
    isar = IsarSetup.instance;
    final profile = await seedPhase0aCh1FounderProfile(
      isar: isar,
      schoolId: 'gang_meng',
      originId: 'mountain_wanderer',
      fateId: 'balanced_seed',
      rngSeed: 20260820,
    );
    departedAt = DateTime.now().toUtc();
    await OfflinePassiveService.settleWindow(
      isar: isar,
      now: departedAt,
      updatePresence: true,
    );
    service = ExpeditionService(isar);
    Future<int> dispatch() => service.dispatchRequest(
      request: ExpeditionService.dispatchRequestFor(
        characterId: profile.snapshot.characterId,
      ),
      policy: ExpeditionPolicy.yiZhanLiXing,
      now: departedAt,
    );
    await dispatch();
    await service.recall(now: departedAt);
    await dispatch();
  });
  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    await directory.delete(recursive: true);
  });

  Future<Map<String, Object?>> facts() async => {
    'save': await isar.saveDatas.where().exportJson(),
    'characters': await isar.characters.where().exportJson(),
    'equipment': await isar.equipments.where().exportJson(),
    'techniques': await isar.techniques.where().exportJson(),
    'inventory': await isar.inventoryItems.where().exportJson(),
    'runs': await isar.expeditionRuns.where().exportJson(),
    'milestones': await isar.expeditionMilestoneRecords.where().exportJson(),
    'receipts': await isar.rewardClaimReceipts.where().exportJson(),
  };

  test('raw reward transaction cannot cross a due expedition node', () async {
    final before = await facts();
    await expectLater(
      isar.writeTxn(
        () => OfflinePassiveService.settleWithinTxn(
          isar: isar,
          now: departedAt.add(const Duration(hours: 72)),
        ),
      ),
      throwsStateError,
    );
    expect(await facts(), before);
    // A failed queued operation cannot poison later calls; backwards time stays
    // a no-op and cannot consume a future reward/recap window.
    expect(
      await OfflinePassiveService.settleWindow(
        isar: isar,
        now: departedAt.subtract(const Duration(hours: 1)),
        updatePresence: true,
      ),
      isNull,
    );
    expect(await facts(), before);
  });

  test(
    'new dispatch after a clock rollback cannot precede earned passive time',
    () async {
      final run = (await service.activeRun())!;
      await service.recall(now: departedAt, expectedRunId: run.id);
      final before = (await isar.saveDatas.get(0))!;
      await service.dispatchRequest(
        request: ExpeditionService.dispatchRequestFor(
          characterId: run.members.single.characterId,
        ),
        policy: run.policy,
        now: departedAt.subtract(const Duration(hours: 4)),
      );
      expect((await service.activeRun())!.departedAt.toUtc(), departedAt);
      expect(
        (await isar.saveDatas.get(0))!.totalPassiveExperience,
        before.totalPassiveExperience,
      );
    },
  );

  for (final nullableAnchor in [false, true]) {
    test(
      'historic passive-first conflict preserves data (nullable: $nullableAnchor)',
      () async {
        final at = departedAt.add(const Duration(hours: 72));
        final run = (await service.activeRun())!;
        // Compatibility fixture reproduces the former passive-first writer using
        // real accrual, with the old pending run retained. It fabricates no battle,
        // stat, reward, unlock or serial; it is not an original player save.
        await isar.writeTxn(() async {
          await isar.expeditionRuns.delete(run.id);
          await OfflinePassiveService.settleWithinTxn(
            isar: isar,
            now: at,
            updatePresence: true,
          );
          await isar.expeditionRuns.put(run);
          if (nullableAnchor) {
            final save = (await isar.saveDatas.get(0))!;
            save.passiveLastSettledAt = null;
            await isar.saveDatas.put(save);
          }
        });
        final before = await facts();
        await expectLater(
          OfflinePassiveService.settleWindow(
            isar: isar,
            now: at,
            updatePresence: true,
          ),
          throwsA(
            isA<ExpeditionTimelineConflict>().having(
              (e) => e.runId,
              'exact run',
              run.id,
            ),
          ),
        );
        expect(await facts(), before);
        // The explicit exit may close only the selected run. A stale confirmation
        // must not end another run, and failed reward application restores it.
        expect(
          (await service.recall(now: at, expectedRunId: run.id + 1)).returned,
          isFalse,
        );
        expect(await facts(), before);
        await expectLater(
          service.recall(
            now: at,
            expectedRunId: run.id,
            afterRewardsInTxnForTest: () async =>
                throw StateError('claim rollback'),
          ),
          throwsStateError,
        );
        expect(await facts(), before);
        final result = await service.recall(now: at, expectedRunId: run.id);
        expect(result.returned, isTrue);
        expect(result.deepestNode, 0);
        expect(result.grantedRewards, isEmpty);
        expect(await service.activeRun(), isNull);
        expect(
          (await isar.saveDatas.get(0))!.totalPassiveExperience,
          ((before['save'] as List).single as Map)['totalPassiveExperience'],
        );
        final returned = await facts();
        expect(
          (await service.recall(now: at, expectedRunId: run.id)).returned,
          isFalse,
        );
        expect(await facts(), returned);
      },
    );
  }

  test(
    'no-stock item action preserves independent elapsed expedition progress',
    () async {
      final at = departedAt.add(const Duration(hours: 72));
      final item = repository.itemDefs['item_jingyandan_small']!;
      expect(await isar.inventoryItems.getByDefId(item.defId), isNull);
      final result = await ItemUseService.use(
        isar,
        def: item,
        realmLookup: repository.getRealm,
        now: at,
      );
      expect(result.kind, ItemUseKind.noStock);
      expect(await isar.inventoryItems.getByDefId(item.defId), isNull);
      expect(await service.activeRun(), isNull);
      expect((await isar.saveDatas.get(0))!.baicaoMaxDepth, 4);
      expect((await service.pendingManualMilestone())!.nodeIndex, 5);
      final save = (await isar.saveDatas.get(0))!;
      expect(save.pendingPassiveRecapExperience, greaterThan(0));
      final recap = await OfflinePassiveService.settleWindow(
        isar: isar,
        now: at,
        updatePresence: true,
      );
      expect(
        recap!.experience,
        (await isar.saveDatas.get(0))!.totalPassiveExperience,
      );
      final after = await facts();
      expect(
        await OfflinePassiveService.settleWindow(
          isar: isar,
          now: at,
          updatePresence: true,
        ),
        isNull,
      );
      expect(await facts(), after);
    },
  );
}
