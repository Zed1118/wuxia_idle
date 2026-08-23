/// P2-M2-R02 随行听剑首通 claim 纯合同
/// （MENTOR-INSIGHT-CORE-01 不重复发放 + MENTOR-INSIGHT-RATE-01 成长对象）。
///
/// 只接受调用方事实（isFirstClear、externallyDurablyClaimed）并输出
/// grant / skip / fail-closed 决策；不执行数值回调、不拥有 ledger、不声称
/// 持久化。claim 键复用 shared `RewardClaimKey` 的 mentorInsight 形态
/// （stageId + characterId，版本化键串与解析完全走 shared，见
/// `lib/shared/battle_shared/reward_claim_key.dart`）。比例与每关上限为
/// TUNING，本合同不含任何数值字段。
library;

import '../domain/mentor_insight_policy.dart';

/// claim 决策输出。
enum MentorInsightClaimOutcome {
  /// 发放：首通且 durable 层未 claim，宿主据此落地主修招式熟练度成长。
  grant,

  /// 跳过：durable 层已 claim，不重复发放。
  skip,

  /// 拒绝（fail closed）：非首通（重打 / 自动重刷 / 扫荡）或输入矛盾，
  /// 不猜测发放。
  failClosed,
}

/// 首通 claim 纯合同（决策面）。
///
/// 决策输入只有 [decide] 的 isFirstClear 与 externallyDurablyClaimed 两个
/// 调用方事实；不消费 release reason —— 占用释放（四种结算一律释放，见
/// domain `MentorInsightPolicy.releaseReasons`）与成长发放完全解耦，failure /
/// explicit exit / recovery 不自动触发成长；恢复场景由宿主以 durable 事实
/// 重放同一决策（已 claim → skip）。
final class MentorInsightClaimPolicy {
  const MentorInsightClaimPolicy._();

  /// 成长对象仅主修招式熟练度（RATE-01）；单一取值，无其它目标。
  static const MentorInsightGrowthTarget growthTarget =
      MentorInsightGrowthTarget.mainTechniqueProficiency;

  /// 仅首通发放（CORE-01）；重打 / 自动重刷 / 扫荡不产生新发放。
  static const bool firstClearOnly = true;

  /// 个人作用域：按门人个人记账，不跨角色共享
  /// （对齐 shared `RewardScope.personal` 语义）。
  static const bool personalScope = true;

  /// 纯决策：调用方事实 → grant / skip / fail-closed。
  ///
  /// - [isFirstClear]：该关是否首通（仅成功首通结算时宿主传 true；失败 /
  ///   主动退出结算传 false → fail closed）；
  /// - [externallyDurablyClaimed]：该键（`RewardClaimKey.mentorInsight` 的
  ///   stageId + characterId 键形）是否已在宿主 durable claim 层记账。
  ///
  /// 本函数无副作用、不持有任何状态；数值落地与 durable 记账由宿主承接，
  /// 进程内重复拒绝纪律可参考 shared `RewardGrantGuard`，但它不代表
  /// durable storage。
  static MentorInsightClaimOutcome decide({
    required bool isFirstClear,
    required bool externallyDurablyClaimed,
  }) {
    if (!isFirstClear) {
      return MentorInsightClaimOutcome.failClosed;
    }
    return externallyDurablyClaimed
        ? MentorInsightClaimOutcome.skip
        : MentorInsightClaimOutcome.grant;
  }
}
