import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/reward/application/durable_reward_claim_service.dart';
import 'package:wuxia_idle/features/reward/domain/reward_claim_receipt.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_claim_key.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_policy.dart';

import '../../support/isar_test_support.dart';

void main() {
  setUpAll(initializeTestIsarCore);

  group('DurableRewardClaimService', () {
    late Directory tempDir;
    late Isar isar;
    late DurableRewardClaimService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('reward_claim_');
      await IsarSetup.init(directory: tempDir, inspector: false);
      isar = IsarSetup.instance;
      service = DurableRewardClaimService(isar);
    });

    tearDown(() async {
      await IsarSetup.close();
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    RewardClaimKey key(String occurrence) => RewardClaimKey.contentLayer(
      contentKind: RewardContentKind.mainline,
      contentId: 'stage_01_01',
      layer: RewardLayer.personalGrowth,
      scope: RewardScope.personal,
      saveDataId: 1,
      participantId: 11,
      occurrenceId: occurrence,
    );

    test('effect and receipt commit in one transaction', () async {
      final claim = key('run-1');
      final disposition = await service.claimBatch(
        keys: [claim],
        sourceSettlementId: 'run-1',
        at: DateTime(2026, 8, 31),
        applyInTxn: () async {
          final save = (await isar.saveDatas.get(0))!;
          save.sectName = '原子写入';
          await isar.saveDatas.put(save);
        },
      );

      expect(disposition, RewardClaimDisposition.applied);
      expect((await isar.saveDatas.get(0))!.sectName, '原子写入');
      expect(
        await isar.rewardClaimReceipts.getByClaimKey(claim.canonical),
        isNotNull,
      );
    });

    test('throwing effect rolls back both effect and receipt', () async {
      final claim = key('run-fails');

      await expectLater(
        service.claimBatch(
          keys: [claim],
          sourceSettlementId: 'run-fails',
          at: DateTime(2026, 8, 31),
          applyInTxn: () async {
            final save = (await isar.saveDatas.get(0))!;
            save.sectName = '不得落库';
            await isar.saveDatas.put(save);
            throw StateError('inject failure');
          },
        ),
        throwsStateError,
      );

      expect((await isar.saveDatas.get(0))!.sectName, isNot('不得落库'));
      expect(
        await isar.rewardClaimReceipts.getByClaimKey(claim.canonical),
        isNull,
      );
    });

    test(
      'duplicate claim never executes callback, including after reopen',
      () async {
        final claim = key('run-restart');
        var applies = 0;
        await service.claimBatch(
          keys: [claim],
          sourceSettlementId: 'run-restart',
          at: DateTime(2026, 8, 31),
          applyInTxn: () async => applies++,
        );

        await IsarSetup.close();
        await IsarSetup.init(directory: tempDir, inspector: false);
        isar = IsarSetup.instance;
        service = DurableRewardClaimService(isar);
        final replay = await service.claimBatch(
          keys: [claim],
          sourceSettlementId: 'run-restart',
          at: DateTime(2026, 8, 31, 0, 1),
          applyInTxn: () async => applies++,
        );

        expect(replay, RewardClaimDisposition.alreadyApplied);
        expect(applies, 1);
        expect(await isar.rewardClaimReceipts.count(), 1);
      },
    );

    test('batch failure leaves zero partial receipts', () async {
      final claims = [key('batch-a'), key('batch-b')];

      await expectLater(
        service.claimBatch(
          keys: claims,
          sourceSettlementId: 'batch',
          at: DateTime(2026, 8, 31),
          applyInTxn: () async => throw StateError('batch failure'),
        ),
        throwsStateError,
      );

      expect(await isar.rewardClaimReceipts.count(), 0);
    });
  });
}
