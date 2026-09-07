import '../../../shared/battle_shared/reward_claim_key.dart';
import '../../../shared/battle_shared/reward_contract.dart';
import '../domain/reward_scope_policy.dart';

/// 首通与本次重复/成长分别判重；两批仍由调用方在同一事务中提交。
/// 只组装身份，不计算或改变任何奖励。
final class RewardClaimPlan {
  RewardClaimPlan._({
    required Iterable<RewardClaimKey> firstClearKeys,
    required Iterable<RewardClaimKey> recurringKeys,
  }) : firstClearKeys = List.unmodifiable(firstClearKeys),
       recurringKeys = List.unmodifiable(recurringKeys);

  final List<RewardClaimKey> firstClearKeys;
  final List<RewardClaimKey> recurringKeys;

  static RewardClaimPlan forSettlement({
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
    final keys = [
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
    return RewardClaimPlan._(
      firstClearKeys: keys.where((key) => key.layer == RewardLayer.firstClear),
      recurringKeys: keys.where((key) => key.layer != RewardLayer.firstClear),
    );
  }

  /// 历史多参与者结算共享首通身份，个人重复/成长身份各自保留。
  static RewardClaimPlan combine(Iterable<RewardClaimPlan> plans) {
    final firstClear = <String, RewardClaimKey>{};
    final recurring = <String, RewardClaimKey>{};
    for (final plan in plans) {
      for (final key in plan.firstClearKeys) {
        firstClear[key.canonical] = key;
      }
      for (final key in plan.recurringKeys) {
        recurring[key.canonical] = key;
      }
    }
    return RewardClaimPlan._(
      firstClearKeys: firstClear.values,
      recurringKeys: recurring.values,
    );
  }
}
