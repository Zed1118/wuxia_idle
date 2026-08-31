import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/inner_demon/application/inner_demon_providers.dart';
import 'package:wuxia_idle/features/mainline/application/mainline_progress_service.dart';
import 'package:wuxia_idle/features/mainline/domain/mainline_progress.dart';
import 'package:wuxia_idle/features/reward/domain/reward_claim_receipt.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_claim_key.dart';
import 'package:wuxia_idle/shared/battle_shared/reward_contract.dart';

import '../../support/isar_test_support.dart';
import '../../support/test_data.dart';

/// `innerDemonProgressProvider(characterId)` 个人进度行为测。
///
/// 真 Isar + 真 GameRepository + 真 U09 durable receipt，钉：
///   - 全局通关事实不能让另一角色继承个人心魔进度；
///   - 同一胜利事务落下的个人 receipt 才推进该角色的下一关。
void main() {
  late Directory tempDir;

  setUpAll(() async {
    await initializeTestIsarCore();
    if (!GameRepository.isLoaded) {
      await loadTestGameRepository();
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_inner_demon_');
    await IsarSetup.init(directory: tempDir, inspector: false);
  });

  tearDown(() async {
    await IsarSetup.close();
    IsarSetup.resetForTest();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('全局通关不跨角色继承，个人 receipt 只推进实际参战者', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final demonTotal = GameRepository
        .instance
        .numbers
        .innerDemon
        .requiredRealmLayer
        .keys
        .where((k) => k.startsWith('stage_inner_demon_'))
        .length;

    const winnerId = 41;
    const otherId = 42;
    final svc = MainlineProgressService(isar: IsarSetup.instance);
    final row = await svc.getOrCreate(saveDataId: IsarSetup.currentSlotId);
    await IsarSetup.instance.writeTxn(() async {
      row.clearedStageIds = ['stage_inner_demon_01', 'stage_inner_demon_02'];
      await IsarSetup.instance.mainlineProgress.put(row);
      for (final stageId in row.clearedStageIds) {
        final key = RewardClaimKey.contentLayer(
          contentKind: RewardContentKind.innerDemon,
          contentId: stageId,
          layer: RewardLayer.personalGrowth,
          scope: RewardScope.personal,
          saveDataId: IsarSetup.currentSlotId,
          participantId: winnerId,
          occurrenceId: 'winner-$stageId',
        );
        await IsarSetup.instance.rewardClaimReceipts.put(
          RewardClaimReceipt.fromKey(
            key: key,
            sourceSettlementId: 'test:$stageId',
            createdAt: DateTime.utc(2026, 9, 1),
          ),
        );
      }
    });

    final winner = await container.read(
      innerDemonProgressProvider(winnerId).future,
    );
    final other = await container.read(
      innerDemonProgressProvider(otherId).future,
    );

    expect(winner.clearedCount, 2);
    expect(winner.totalCount, demonTotal, reason: '总数派生自 numbers 不硬编码');
    expect(winner.nextUnclearedStageId, 'stage_inner_demon_03');
    expect(
      winner.clearedStageIds,
      containsAll(['stage_inner_demon_01', 'stage_inner_demon_02']),
    );
    expect(other.clearedCount, 0, reason: '存档全局通关事实不得冒充另一角色个人进度');
    expect(other.nextUnclearedStageId, 'stage_inner_demon_01');
  });
}
