/// P2-M2-R02 随行听剑纯合同（MENTOR-INSIGHT-CORE-01 / OCCUPANCY-01 / RATE-01）。
///
/// 只定义类型、校验与边界语义；不写比例、每关 cap、生产发放、存储或 tuning
/// 默认。决策真相源：`docs/dispatch/phase0a_overhaul/decision_registry.yaml`。
/// 与既有 `shared/battle_shared/failure_policy.dart` 同为纯合同体例：无持久化、
/// 无 schema 变更、无生产接线。
library;

/// 随行听剑成长对象（MENTOR-INSIGHT-RATE-01）。
///
/// 单一取值即冻结边界：合同面不存在经验、装备、材料、银两等其它成长目标；
/// 具体比例与每关上限为 TUNING，不在本合同内。
enum MentorInsightGrowthTarget { mainTechniqueProficiency }

/// 随行听剑占用粒度（MENTOR-INSIGHT-OCCUPANCY-01）。
///
/// 单一取值即冻结边界：只占用单关，不存在「锁定整段 MainlineRun」的路径。
enum MentorInsightOccupancyScope { singleStage }

/// 占用释放原因（MENTOR-INSIGHT-OCCUPANCY-01 release_after）。
///
/// 四种结算全部释放单关占用；无第五种「持续占用」路径。
enum MentorInsightReleaseReason {
  /// 胜利结算。
  successSettlement,

  /// 失败结算。
  failureSettlement,

  /// 主动退出。
  explicitExit,

  /// 幂等恢复结算（崩溃恢复重放同一结算键）。
  idempotentRecoverySettlement,
}

/// 与随行听剑互斥的四类既有活动（MENTOR-INSIGHT-OCCUPANCY-01
/// mutually_exclusive_with）。集合固定为四类，无扩展。
enum MentorInsightBlockingActivity {
  /// 闭关。
  retreat,

  /// 远征。
  expedition,

  /// 断魂庄。
  bossGauntlet,

  /// 疗伤。
  healing,
}

/// 门人互斥占用输入快照（纯合同输入，不依赖存储）。
///
/// 由调用方按角色现状填充：
/// - retreat / expedition / bossGauntlet 可来自既有
///   `ActivityOccupancy.activityOf` 的占用判定；
/// - healing 来自角色疗伤状态（如 lightInjuryStacks / injuryHoursRemaining 等）。
final class MentorInsightBlockingStatus {
  const MentorInsightBlockingStatus({
    this.inRetreat = false,
    this.inExpedition = false,
    this.inBossGauntlet = false,
    this.inHealingRecovery = false,
  });

  final bool inRetreat;
  final bool inExpedition;
  final bool inBossGauntlet;
  final bool inHealingRecovery;

  /// 与四类既有活动任一互斥即被阻塞。
  bool get isBlocked =>
      inRetreat || inExpedition || inBossGauntlet || inHealingRecovery;
}

/// 随行听剑冻结保证（MENTOR-INSIGHT-CORE-01）。固定语义，非配置项。
final class MentorInsightPolicy {
  const MentorInsightPolicy._();

  // ---- CORE-01：首通可随行 0-1 名门人，不入战、不受伤、不分掉落、不重复发放 ----

  /// 首通可选 0-1 名门人。
  static const int maxCompanions = 1;

  /// 不入战：不进战场、不提供战斗帮助、无战斗装备快照。
  static const bool noCombatParticipation = true;

  /// 不受伤：实际参战者承担伤势，随行听剑者不受伤。
  static const bool noInjury = true;

  /// 不分掉落：首通掉落归实际参战 / 宗门口径，随行门人不分掉落。
  static const bool noDropShare = true;

  /// 不重复发放：仅该关首通发放，重打 / 自动重刷 / 扫荡不重复发放
  /// （幂等 claim 见 application/mentor_insight_claim_policy.dart）。
  static const bool firstClearOnly = true;

  // ---- RATE-01：成长对象仅主修招式熟练度 ----

  /// 成长对象固定为主修招式熟练度；比例与每关上限为 TUNING，不在本合同。
  static const MentorInsightGrowthTarget growthTarget =
      MentorInsightGrowthTarget.mainTechniqueProficiency;

  // ---- OCCUPANCY-01：单关占用 + 四类活动互斥 + 四种结算释放 ----

  /// 占用粒度固定为单关。
  static const MentorInsightOccupancyScope occupancyScope =
      MentorInsightOccupancyScope.singleStage;

  /// 四种结算全部释放单关占用（success / failure / explicit exit /
  /// idempotent recovery settlement）。
  ///
  /// 释放与成长发放完全解耦：release 只负责占用生命周期；failure /
  /// explicit exit / recovery 一律释放占用，不自动触发成长（grant eligibility
  /// 只由 application 层 claim 决策面的事实决定，见
  /// application/mentor_insight_claim_policy.dart）。
  static const Set<MentorInsightReleaseReason> releaseReasons = {
    MentorInsightReleaseReason.successSettlement,
    MentorInsightReleaseReason.failureSettlement,
    MentorInsightReleaseReason.explicitExit,
    MentorInsightReleaseReason.idempotentRecoverySettlement,
  };

  /// 与随行听剑互斥的四类既有活动（闭关 / 远征 / 断魂庄 / 疗伤）。
  ///
  /// 互斥双向：门人处于任一活动不可随行；已随行门人占用中也不得进入任一活动
  /// （反向落地由宿主接线，本合同只声明互斥集合与入向判定）。
  static const Set<MentorInsightBlockingActivity> mutuallyExclusiveActivities =
      {
        MentorInsightBlockingActivity.retreat,
        MentorInsightBlockingActivity.expedition,
        MentorInsightBlockingActivity.bossGauntlet,
        MentorInsightBlockingActivity.healing,
      };

  /// 门人可随行判定：不处于四类既有活动任一。
  static bool canAccompany(MentorInsightBlockingStatus status) =>
      !status.isBlocked;
}

/// 一次首通随行选择：0 或 1 名门人（MENTOR-INSIGHT-CORE-01）。
///
/// [stageId] 必填非空（trim 规范化）；[menteeCharacterId] 为空 = 不随行，
/// 非空必须 > 0。
final class MentorInsightChoice {
  MentorInsightChoice({required String stageId, this.menteeCharacterId})
    : stageId = stageId.trim() {
    if (this.stageId.isEmpty) {
      throw ArgumentError.value(stageId, 'stageId', 'must not be empty');
    }
    final menteeId = menteeCharacterId;
    if (menteeId != null && menteeId <= 0) {
      throw ArgumentError.value(
        menteeCharacterId,
        'menteeCharacterId',
        'must be > 0 when provided',
      );
    }
  }

  final String stageId;
  final int? menteeCharacterId;

  bool get hasCompanion => menteeCharacterId != null;
}

/// 已成立的随行门人（单关占用条目，MENTOR-INSIGHT-OCCUPANCY-01）。
///
/// 占用作用域 = [stageId]（单关）；只锁 [characterId] 一名门人；不锁整段
/// MainlineRun。释放由 [MentorInsightPolicy.releaseReasons] 四种结算触发。
final class MentorInsightCompanion {
  MentorInsightCompanion({required String stageId, required this.characterId})
    : stageId = stageId.trim() {
    if (this.stageId.isEmpty) {
      throw ArgumentError.value(stageId, 'stageId', 'must not be empty');
    }
    if (characterId <= 0) {
      throw ArgumentError.value(characterId, 'characterId', 'must be > 0');
    }
  }

  final String stageId;
  final int characterId;

  @override
  bool operator ==(Object other) =>
      other is MentorInsightCompanion &&
      other.stageId == stageId &&
      other.characterId == characterId;

  @override
  int get hashCode => Object.hash(stageId, characterId);

  @override
  String toString() => 'MentorInsightCompanion($stageId, $characterId)';
}
