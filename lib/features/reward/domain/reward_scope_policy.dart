import '../../../shared/battle_shared/reward_claim_key.dart';
import '../../../shared/battle_shared/reward_contract.dart';

/// U09 冻结的 scope 语义；只决定领取 owner，不承载任何奖励值或倍率。
abstract final class RewardScopePolicy {
  static RewardScope scopeFor({
    required RewardContentKind contentKind,
    required RewardLayer layer,
  }) {
    if (layer == RewardLayer.firstClear &&
        contentKind != RewardContentKind.innerDemon) {
      return RewardScope.sectShared;
    }
    return RewardScope.personal;
  }
}
