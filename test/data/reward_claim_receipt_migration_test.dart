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
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
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
        '0.42.0',
      );

      await IsarSetup.close();
      await IsarSetup.init(directory: tempDir, inspector: false);
      expect(
        await IsarSetup.instance.rewardClaimReceipts.count(),
        receipts.length,
      );
    },
  );
}
