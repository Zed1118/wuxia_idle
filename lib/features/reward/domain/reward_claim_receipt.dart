import 'package:isar_community/isar.dart';

import '../../../shared/battle_shared/reward_claim_key.dart';
import '../../../shared/battle_shared/reward_contract.dart';

part 'reward_claim_receipt.g.dart';

/// 一条已原子应用的奖励领取事实。
///
/// 奖励值、概率与物品 payload 仍由现有模式结算器拥有；本集合只记录 canonical
/// claim 身份。写入必须与对应 effect 位于同一 Isar write transaction。
@collection
class RewardClaimReceipt {
  Id id = Isar.autoIncrement;

  /// Receipt 行结构版本；与 canonical claim key 的版本相互独立。
  int receiptVersion = 1;

  @Index(unique: true)
  late String claimKey;

  @Index()
  late int saveDataId;

  @Enumerated(EnumType.name)
  late RewardContentKind contentKind;

  late String contentId;

  @Enumerated(EnumType.name)
  late RewardLayer layer;

  @Enumerated(EnumType.name)
  late RewardScope scope;

  int? participantId;
  String? occurrenceId;

  /// 现有 durable run / settlement 的稳定身份；历史墓碑使用 migration 标识。
  late String sourceSettlementId;

  /// 旧档已有通关/领取事实只建立防重墓碑，不代表本次迁移补发任何奖励。
  bool isHistoricalTombstone = false;

  late DateTime createdAt;

  static RewardClaimReceipt fromKey({
    required RewardClaimKey key,
    required String sourceSettlementId,
    required DateTime createdAt,
    bool isHistoricalTombstone = false,
  }) {
    if (key.kind != RewardClaimKeyKind.contentLayer) {
      throw ArgumentError.value(key, 'key', 'must be a contentLayer key');
    }
    final source = sourceSettlementId.trim();
    if (source.isEmpty) {
      throw ArgumentError.value(
        sourceSettlementId,
        'sourceSettlementId',
        'must not be empty',
      );
    }
    return RewardClaimReceipt()
      ..claimKey = key.canonical
      ..saveDataId = key.saveDataId
      ..contentKind = key.contentKind
      ..contentId = key.contentId
      ..layer = key.layer
      ..scope = key.scope
      ..participantId = key.participantId
      ..occurrenceId = key.occurrenceId
      ..sourceSettlementId = source
      ..isHistoricalTombstone = isHistoricalTombstone
      ..createdAt = createdAt;
  }

  @ignore
  RewardClaimKey get key {
    final parsed = RewardClaimKey.parse(claimKey);
    if (parsed.kind != RewardClaimKeyKind.contentLayer ||
        parsed.saveDataId != saveDataId ||
        parsed.contentKind != contentKind ||
        parsed.contentId != contentId ||
        parsed.layer != layer ||
        parsed.scope != scope ||
        parsed.participantId != participantId ||
        parsed.occurrenceId != occurrenceId) {
      throw StateError('Reward claim receipt fields drifted from claimKey');
    }
    return parsed;
  }
}
