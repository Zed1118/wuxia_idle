import 'package:isar_community/isar.dart';

import '../../../shared/battle_shared/reward_claim_key.dart';
import '../domain/reward_claim_receipt.dart';

enum RewardClaimDisposition { applied, alreadyApplied }

/// 七类内容共享的持久奖励防重事务边界。
final class DurableRewardClaimService {
  const DurableRewardClaimService(this._isar);

  final Isar _isar;

  Future<bool> isClaimed(RewardClaimKey key) async {
    _requireContentLayer(key);
    return await _isar.rewardClaimReceipts.getByClaimKey(key.canonical) != null;
  }

  /// 自行开启写事务；effect 与全部 receipt 要么一起提交，要么一起回滚。
  Future<RewardClaimDisposition> claimBatch({
    required List<RewardClaimKey> keys,
    required String sourceSettlementId,
    required DateTime at,
    required Future<void> Function() applyInTxn,
  }) {
    return _isar.writeTxn(
      () => claimBatchInTxn(
        keys: keys,
        sourceSettlementId: sourceSettlementId,
        at: at,
        applyInTxn: applyInTxn,
      ),
    );
  }

  /// 供已有 journal/run 事务调用，禁止内部再开嵌套事务。
  Future<RewardClaimDisposition> claimBatchInTxn({
    required List<RewardClaimKey> keys,
    required String sourceSettlementId,
    required DateTime at,
    required Future<void> Function() applyInTxn,
  }) async {
    if (keys.isEmpty) {
      throw ArgumentError.value(keys, 'keys', 'must not be empty');
    }
    final source = sourceSettlementId.trim();
    if (source.isEmpty) {
      throw ArgumentError.value(
        sourceSettlementId,
        'sourceSettlementId',
        'must not be empty',
      );
    }
    final canonicals = <String>{};
    for (final key in keys) {
      _requireContentLayer(key);
      if (!canonicals.add(key.canonical)) {
        throw ArgumentError.value(keys, 'keys', 'contains a duplicate key');
      }
      if (await _isar.rewardClaimReceipts.getByClaimKey(key.canonical) !=
          null) {
        return RewardClaimDisposition.alreadyApplied;
      }
    }

    await applyInTxn();
    await _isar.rewardClaimReceipts.putAll([
      for (final key in keys)
        RewardClaimReceipt.fromKey(
          key: key,
          sourceSettlementId: source,
          createdAt: at,
        ),
    ]);
    return RewardClaimDisposition.applied;
  }

  static void _requireContentLayer(RewardClaimKey key) {
    if (key.kind != RewardClaimKeyKind.contentLayer) {
      throw ArgumentError.value(key, 'key', 'must be a contentLayer key');
    }
  }
}
