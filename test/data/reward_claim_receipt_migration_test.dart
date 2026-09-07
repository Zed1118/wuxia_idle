import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/reward/domain/reward_claim_receipt.dart';
import 'package:wuxia_idle/features/tower/domain/tower_progress.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_claim_key.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_policy.dart';

import '../support/isar_test_support.dart';
import '../support/test_data.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) await loadTestGameRepository();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('reward_claim_migration_');
  });

  tearDown(() async {
    await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test(
    '0.41 existing clear facts become tombstones without reward grants',
    () async {
      await IsarSetup.init(directory: tempDir, inspector: false);
      final before = DateTime(2026, 8, 30);
      await IsarSetup.instance.writeTxn(() async {
        final save = (await IsarSetup.instance.saveDatas.get(0))!;
        save
          ..saveVersion = '0.41.0'
          ..clearedGauntletIds = ['duanhun_v1']
          ..baicaoMaxDepth = 9;
        await IsarSetup.instance.saveDatas.put(save);
        await IsarSetup.instance.mainlineProgress.put(
          MainlineProgress()
            ..saveDataId = 1
            ..clearedStageIds = [
              'stage_01_01',
              'stage_light_foot_01',
              'stage_mass_battle_01',
              'stage_inner_demon_01',
            ]
            ..clearedAt = [before, before, before, before]
            ..clearedStageCycleKeys = []
            ..clearedChapterCycleKeys = [],
        );
        await IsarSetup.instance.towerProgress.put(
          TowerProgress()
            ..saveDataId = 1
            ..highestClearedFloor = 2
            ..highestClearedAt = before
            ..createdAt = before,
        );
      });
      await IsarSetup.close();

      await IsarSetup.init(directory: tempDir, inspector: false);
      final receipts = await IsarSetup.instance.rewardClaimReceipts
          .where()
          .findAll();
      final canonicals = receipts.map((row) => row.claimKey).toSet();

      String firstClear(RewardContentKind kind, String contentId) =>
          RewardClaimKey.contentLayer(
            contentKind: kind,
            contentId: contentId,
            layer: RewardLayer.firstClear,
            scope: RewardScope.sectShared,
            saveDataId: 1,
            participantId: null,
            occurrenceId: 'ignored',
          ).canonical;

      expect(
        canonicals,
        contains(firstClear(RewardContentKind.mainline, 'stage_01_01')),
      );
      expect(
        canonicals,
        contains(
          firstClear(RewardContentKind.lightFoot, 'stage_light_foot_01'),
        ),
      );
      expect(
        canonicals,
        contains(
          firstClear(RewardContentKind.massBattle, 'stage_mass_battle_01'),
        ),
      );
      expect(
        canonicals,
        contains(firstClear(RewardContentKind.tower, 'tower_floor_1_cycle_1')),
      );
      expect(
        canonicals,
        contains(firstClear(RewardContentKind.tower, 'tower_floor_2_cycle_1')),
      );
      expect(
        canonicals,
        contains(firstClear(RewardContentKind.gauntlet, 'duanhun_v1')),
      );

      expect(
        receipts.any(
          (row) =>
              row.contentKind == RewardContentKind.innerDemon ||
              row.contentKind == RewardContentKind.expedition,
        ),
        isFalse,
        reason: '旧档无法证明实际个人领取者或某次远征 run，禁止猜测建墓碑',
      );
      expect(receipts.every((row) => row.isHistoricalTombstone), isTrue);
      expect(
        receipts.every((row) => row.layer == RewardLayer.firstClear),
        isTrue,
      );
      expect(
        (await IsarSetup.instance.saveDatas.get(0))!.saveVersion,
        '0.47.0',
      );

      await IsarSetup.close();
      await IsarSetup.init(directory: tempDir, inspector: false);
      expect(
        await IsarSetup.instance.rewardClaimReceipts.count(),
        receipts.length,
      );
    },
  );

  for (final fixture in [
    (version: '0.20.0', maxCycle: 0, currentCycle: 1, expectedCycles: 1),
    (version: '0.41.0', maxCycle: 1, currentCycle: 1, expectedCycles: 1),
    (version: '0.41.0', maxCycle: 2, currentCycle: 3, expectedCycles: 3),
  ]) {
    test(
      '${fixture.version} tower 30/${fixture.maxCycle}/${fixture.currentCycle} '
      'backfills cleared floors without claiming expanded floors',
      () async {
        await _seedTowerSave(
          tempDir,
          version: fixture.version,
          maxClearedCycle: fixture.maxCycle,
          currentCycleIndex: fixture.currentCycle,
        );

        await IsarSetup.init(directory: tempDir, inspector: false);
        final receipts = await IsarSetup.instance.rewardClaimReceipts
            .where()
            .findAll();
        final canonicals = receipts.map((row) => row.claimKey).toSet();
        for (var cycle = 1; cycle <= fixture.expectedCycles; cycle++) {
          for (var floor = 1; floor <= 30; floor++) {
            expect(
              canonicals,
              contains(_towerReceipt(floor, cycle: cycle).claimKey),
              reason: 'Known clear floor $floor in cycle $cycle must remain',
            );
          }
          for (var floor = 31; floor <= 49; floor++) {
            expect(
              canonicals,
              isNot(contains(_towerReceipt(floor, cycle: cycle).claimKey)),
              reason:
                  'Expanded floor $floor in cycle $cycle exceeds the recorded current floor',
            );
          }
        }
        expect(receipts, hasLength(30 * fixture.expectedCycles));
        expect(receipts.every((row) => row.isHistoricalTombstone), isTrue);
        expect(
          (await IsarSetup.instance.saveDatas.get(0))!.saveVersion,
          '0.47.0',
        );
      },
    );
  }

  test(
    '0.46 removes only matching 0.42 tower tombstones above the current floor',
    () async {
      final preserved = [
        // A real grant remains even when its source resembles the old migration.
        _towerReceipt(31, cycle: 4, historical: false),
        _towerReceipt(
          31,
          cycle: 5,
          source: 'migration:0.41.0:cleared-tower:31',
        ),
        _towerReceipt(31, cycle: 6, source: 'settlement:tower:31'),
        _towerReceipt(31, cycle: 7, contentKind: RewardContentKind.mainline),
        _towerReceipt(31, contentId: 'tower_floor_31_cycle_1_extra'),
        _towerReceipt(31, contentId: 'tower_floor_unknown_cycle_1'),
        _towerReceipt(31, contentId: 'tower_floor_31_cycle_unknown'),
        _towerReceipt(31, contentId: 'tower_floor_31_cycle_1\nextra'),
        _towerReceipt(
          31,
          scope: RewardScope.personal,
          source: 'settlement:personal:tower:31',
        ),
        _towerReceipt(31, layer: RewardLayer.repeat, historical: false),
        // A row belonging to another slot must not be repaired in this database.
        _towerReceipt(49, saveDataId: 2),
      ];
      final seeded = [
        for (final cycle in [1, 2, 99])
          for (var floor = 1; floor <= 49; floor++)
            _towerReceipt(floor, cycle: cycle),
        ...preserved,
      ];
      await _seedTowerSave(tempDir, version: '0.45.0', receipts: seeded);

      await IsarSetup.init(directory: tempDir, inspector: false);
      final receipts = await IsarSetup.instance.rewardClaimReceipts
          .where()
          .findAll();
      final canonicals = receipts.map((row) => row.claimKey).toSet();
      for (final cycle in [1, 2, 99]) {
        for (var floor = 1; floor <= 30; floor++) {
          expect(
            canonicals,
            contains(_towerReceipt(floor, cycle: cycle).claimKey),
          );
        }
        for (var floor = 31; floor <= 49; floor++) {
          expect(
            canonicals,
            isNot(contains(_towerReceipt(floor, cycle: cycle).claimKey)),
          );
        }
      }
      for (final receipt in preserved) {
        final actual = await IsarSetup.instance.rewardClaimReceipts.get(
          receipt.id,
        );
        expect(actual, isNotNull, reason: receipt.claimKey);
        expect(actual!.claimKey, receipt.claimKey);
        expect(actual.sourceSettlementId, receipt.sourceSettlementId);
        expect(actual.createdAt, receipt.createdAt);
        expect(actual.isHistoricalTombstone, receipt.isHistoricalTombstone);
      }
      expect(receipts, hasLength(90 + preserved.length));
      expect(
        (await IsarSetup.instance.saveDatas.get(0))!.saveVersion,
        '0.47.0',
      );
      final progress =
          (await IsarSetup.instance.towerProgress.where().findAll()).single;
      expect(progress.highestClearedFloor, 30);
      expect(progress.currentCycleIndex, 1);
      expect(progress.maxClearedCycle, 1);

      await IsarSetup.close();
      await IsarSetup.init(directory: tempDir, inspector: false);
      expect(
        (await IsarSetup.instance.rewardClaimReceipts.where().findAll())
            .map((row) => row.claimKey)
            .toSet(),
        canonicals,
        reason: 'Reopening an already repaired save must be idempotent',
      );
    },
  );

  test(
    '0.46 leaves receipts alone when no tower progress supplies the cutoff',
    () async {
      final receipt = _towerReceipt(31);
      await _seedTowerSave(
        tempDir,
        version: '0.45.0',
        receipts: [receipt],
        includeTowerProgress: false,
      );
      await IsarSetup.init(directory: tempDir, inspector: false);
      expect(
        await IsarSetup.instance.rewardClaimReceipts.getByClaimKey(
          receipt.claimKey,
        ),
        isNotNull,
      );
    },
  );

  test(
    '0.46 repairs the opened slot without opening another slot database',
    () async {
      final otherSlotReceipt = _towerReceipt(31, saveDataId: 2);
      await _seedTowerSave(
        tempDir,
        slotId: 2,
        version: '0.45.0',
        receipts: [otherSlotReceipt],
      );
      final currentSlotReceipt = _towerReceipt(31);
      await _seedTowerSave(
        tempDir,
        version: '0.45.0',
        receipts: [currentSlotReceipt],
      );

      await IsarSetup.init(directory: tempDir, inspector: false);
      expect(await IsarSetup.instance.rewardClaimReceipts.count(), 0);
      expect(Isar.getInstance('wuxia_save_slot2'), isNull);
      final otherSlot = await Isar.open(
        IsarSetup.schemasForTesting,
        directory: tempDir.path,
        name: 'wuxia_save_slot2',
        inspector: false,
      );
      try {
        expect((await otherSlot.saveDatas.get(0))!.saveVersion, '0.45.0');
        expect(
          await otherSlot.rewardClaimReceipts.getByClaimKey(
            otherSlotReceipt.claimKey,
          ),
          isNotNull,
        );
      } finally {
        await otherSlot.close();
      }
    },
  );
}

Future<void> _seedTowerSave(
  Directory directory, {
  required String version,
  int slotId = 1,
  int maxClearedCycle = 1,
  int currentCycleIndex = 1,
  bool includeTowerProgress = true,
  List<RewardClaimReceipt> receipts = const [],
}) async {
  await IsarSetup.init(slotId: slotId, directory: directory, inspector: false);
  final isar = IsarSetup.instance;
  await isar.writeTxn(() async {
    final save = (await isar.saveDatas.get(0))!..saveVersion = version;
    await isar.saveDatas.put(save);
    if (includeTowerProgress) {
      await isar.towerProgress.put(
        TowerProgress()
          ..saveDataId = slotId
          ..highestClearedFloor = 30
          ..maxClearedCycle = maxClearedCycle
          ..currentCycleIndex = currentCycleIndex
          ..createdAt = DateTime(2026, 8, 30),
      );
    }
    await isar.rewardClaimReceipts.putAll(receipts);
  });
  await IsarSetup.close();
}

RewardClaimReceipt _towerReceipt(
  int floor, {
  int cycle = 1,
  int saveDataId = 1,
  RewardContentKind contentKind = RewardContentKind.tower,
  RewardLayer layer = RewardLayer.firstClear,
  RewardScope scope = RewardScope.sectShared,
  String? contentId,
  String? source,
  bool historical = true,
}) {
  final id = contentId ?? 'tower_floor_${floor}_cycle_$cycle';
  return RewardClaimReceipt.fromKey(
    key: RewardClaimKey.contentLayer(
      contentKind: contentKind,
      contentId: id,
      layer: layer,
      scope: scope,
      saveDataId: saveDataId,
      participantId: scope == RewardScope.personal ? 7 : null,
      occurrenceId: 'test:tower:occurrence',
    ),
    sourceSettlementId: source ?? 'migration:0.42.0:cleared-tower:$id',
    createdAt: DateTime(2026, 8, 30),
    isHistoricalTombstone: historical,
  );
}
