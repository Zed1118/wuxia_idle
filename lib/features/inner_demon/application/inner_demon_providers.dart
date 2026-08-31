import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:isar_community/isar.dart';

import '../../../data/game_repository.dart';
import '../../../data/isar_setup.dart';
import '../../reward/domain/reward_claim_receipt.dart';
import '../../../shared/battle_shared/reward_claim_key.dart';
import '../../../shared/battle_shared/reward_contract.dart';
import '../domain/inner_demon_progress.dart';

part 'inner_demon_providers.g.dart';

/// 指定角色的心魔通关进度。
///
/// U09 胜利结算会在同一事务写入个人作用域的 durable reward receipt；这里把
/// `contentId + participantId` 作为已经发生过该角色胜利的持久事实。存档级
/// `MainlineProgress.clearedStageIds` 只继续承担全局内容链/首通奖励语义，不再让
/// 一个角色的心魔胜利被另一角色继承。
@riverpod
Future<InnerDemonProgress> innerDemonProgress(Ref ref, int characterId) async {
  if (characterId <= 0) {
    throw ArgumentError.value(characterId, 'characterId', 'must be > 0');
  }
  final isar = IsarSetup.instanceOrNull;
  if (isar == null) {
    throw StateError('Inner demon personal progress requires Isar');
  }
  final receipts = await isar.rewardClaimReceipts.where().findAll();
  final clearedStageIds = <String>{};
  for (final receipt in receipts) {
    if (receipt.saveDataId != IsarSetup.currentSlotId ||
        receipt.contentKind != RewardContentKind.innerDemon ||
        receipt.scope != RewardScope.personal ||
        receipt.participantId != characterId) {
      continue;
    }
    // Canonical key 与冗余列漂移时 fail closed，不能把损坏行当成个人通关事实。
    receipt.key;
    clearedStageIds.add(receipt.contentId);
  }
  return InnerDemonProgress.from(
    innerDemonDef: GameRepository.instance.numbers.innerDemon,
    clearedStageIds: clearedStageIds,
  );
}
