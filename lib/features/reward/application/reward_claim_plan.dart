import '../../../shared/battle_shared/reward_claim_key.dart';
import '../../../shared/battle_shared/reward_contract.dart';
import '../domain/reward_scope_policy.dart';

/// 一次既有结算对应的 claim 集合。只组装身份，不计算或改变任何奖励。
abstract final class RewardClaimPlan {
  static List<RewardClaimKey> forSettlement({
    required RewardContentKind contentKind,
    required String contentId,
    required int saveDataId,
    required int participantId,
    required String occurrenceId,
    required bool includesFirstClear,
  }) {
    final layers = <RewardLayer>[
      if (includesFirstClear) RewardLayer.firstClear,
      RewardLayer.repeat,
      RewardLayer.personalGrowth,
    ];
    return [
      for (final layer in layers)
        RewardClaimKey.contentLayer(
          contentKind: contentKind,
          contentId: contentId,
          layer: layer,
          scope: RewardScopePolicy.scopeFor(
            contentKind: contentKind,
            layer: layer,
          ),
          saveDataId: saveDataId,
          participantId: participantId,
          occurrenceId: occurrenceId,
        ),
    ];
  }
}
