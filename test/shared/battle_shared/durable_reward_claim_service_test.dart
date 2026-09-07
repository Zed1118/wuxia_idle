import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/save_data.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/reward/application/durable_reward_claim_service.dart';
import 'package:wuxia_idle/features/reward/application/reward_claim_plan.dart';
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

    RewardClaimPlan plan(String occurrence) => RewardClaimPlan.forSettlement(
      contentKind: RewardContentKind.tower,
      contentId: 'tower_floor_31_cycle_1',
      saveDataId: 1,
      participantId: 11,
      occurrenceId: occurrence,
      includesFirstClear: true,
    );

    test(
      'historical first clear cannot veto recurring effects or progress',
      () async {
        final claims = plan('tower-31');
        await isar.writeTxn(
          () => isar.rewardClaimReceipts.put(
            RewardClaimReceipt.fromKey(
              key: claims.firstClearKeys.single,
              sourceSettlementId:
                  'migration:0.42.0:cleared-tower:tower_floor_31_cycle_1',
              createdAt: DateTime(2026, 8, 31),
              isHistoricalTombstone: true,
            ),
          ),
        );
        var applies = 0;
        Future<void> apply(bool grantsFirstClear) async {
          expect(grantsFirstClear, isFalse);
          final save = (await isar.saveDatas.get(0))!;
          save.baicaoMaxDepth++;
          await isar.saveDatas.put(save);
          applies++;
        }

        expect(
          await service.claimSettlement(
            plan: claims,
            sourceSettlementId: 'tower-31',
            at: DateTime(2026, 9, 7),
            applyInTxn: apply,
          ),
          RewardClaimDisposition.applied,
        );
        await IsarSetup.close();
        await IsarSetup.init(directory: tempDir, inspector: false);
        isar = IsarSetup.instance;
        service = DurableRewardClaimService(isar);
        expect(
          await service.claimSettlement(
            plan: claims,
            sourceSettlementId: 'tower-31',
            at: DateTime(2026, 9, 7),
            applyInTxn: apply,
          ),
          RewardClaimDisposition.alreadyApplied,
        );
        expect(applies, 1);
        expect((await isar.saveDatas.get(0))!.baicaoMaxDepth, 1);
        expect(await isar.rewardClaimReceipts.count(), 3);
      },
    );

    test(
      'split batches roll back first clear, recurring and effects together',
      () async {
        final claims = plan('split-fails');
        await expectLater(
          isar.writeTxn(
            () => service.claimSettlementInTxn(
              plan: claims,
              sourceSettlementId: 'split-fails',
              at: DateTime(2026, 9, 7),
              applyInTxn: (grantsFirstClear) async {
                expect(grantsFirstClear, isTrue);
                final save = (await isar.saveDatas.get(0))!;
                save.baicaoMaxDepth = 31;
                await isar.saveDatas.put(save);
                throw StateError(
                  'failure after first-clear receipt and effect',
                );
              },
            ),
          ),
          throwsStateError,
        );
        expect((await isar.saveDatas.get(0))!.baicaoMaxDepth, 0);
        expect(await isar.rewardClaimReceipts.count(), 0);
      },
    );

    test(
      'recurring replay cannot create or grant a missing first clear',
      () async {
        final claims = plan('recurring-replay');
        await service.claimBatch(
          keys: claims.recurringKeys,
          sourceSettlementId: 'recurring-replay',
          at: DateTime(2026, 9, 7),
          applyInTxn: () async {},
        );
        expect(
          await service.claimSettlement(
            plan: claims,
            sourceSettlementId: 'recurring-replay',
            at: DateTime(2026, 9, 7),
            applyInTxn: (_) async =>
                fail('replayed occurrence must not run effects'),
          ),
          RewardClaimDisposition.alreadyApplied,
        );
        expect(await service.isClaimed(claims.firstClearKeys.single), isFalse);
        expect(await isar.rewardClaimReceipts.count(), 2);
      },
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
