/// C13 失败策略纯合同类型（二阶段方案 §17.7 / 任务清单 C13）。
///
/// 只定义类型、校验与索赔键；分支解析与索赔记账见
/// `failure_policy_resolver.dart`。无持久化、无 schema 变更。
library;

/// 失败内容种类：失败策略分支与伤势索赔的作用域维度之一。
///
/// 与 [StageType] 独立：远征 / 断魂庄没有 StageType，仍是合法内容种类；
/// 新增内容种类时若未注入对应规则，resolver 会 fail closed（见
/// `failure_policy_resolver.dart`）。
enum FailureContentKind {
  mainline, // 主线
  tower, // 爬塔
  innerDemon, // 心魔
  expedition, // 远征
  gauntlet, // 断魂庄
  lightFoot, // 轻功对决
  massBattle, // 群战守城
}

/// 失败原因：挑战终结方式，与 [FailureContentKind] 组成规则分支键。
enum FailureReason {
  defeat, // 战败（血尽）
  surrender, // 主动退出（§17.7「主动退出」）
  timeout, // 限时内容超时（如心魔终关 survive 20 tick）
  aborted, // 应用中断 / 崩溃恢复时对未完成 session 的结算
}

/// 失败结算四分支（二阶段方案 §17.7）。
enum FailureResolution {
  /// 物理伤势（轻伤 / 重伤，落地由应用层 InjuryService 负责）。
  injury,

  /// 内息紊乱（临时代价，不扣永久内力）。
  disorder,

  /// 部分奖励（无伤势，只扣奖励）。
  partialReward,

  /// 无惩罚。
  noPenalty,
}

/// 失败策略合同错误基类。
class FailurePolicyException implements Exception {
  const FailurePolicyException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// 规则缺失：fail closed，拒绝猜测惩罚。
final class MissingFailurePolicyRuleError extends FailurePolicyException {
  MissingFailurePolicyRuleError({
    required this.contentKind,
    required this.failureReason,
  }) : super(
         'No failure policy rule for contentKind=${contentKind.name}, '
         'failureReason=${failureReason.name}; failing closed without a penalty',
       );

  final FailureContentKind contentKind;
  final FailureReason failureReason;
}

/// 索赔键非法：sessionId / participantId 为空。
final class InvalidFailureClaimKeyError extends FailurePolicyException {
  const InvalidFailureClaimKeyError(super.message);
}

/// 索赔冲突：同键已结算或批内重复，拒绝重复结伤。
final class FailureClaimConflictError extends FailurePolicyException {
  const FailureClaimConflictError(super.message);
}

/// 伤势输入快照（§17.7「伤势输入至少记录剩余生命比例、承受重击/不可阻挡次数、
/// 倒地/被破势次数、主动退出与内容危险档」）。
///
/// 目前**不参与**分支解析（M0/M2 模拟定标前不设 injury 权重），仅作为合同
/// 输入校验并透传，供后续权重层消费。
final class FailurePerformanceSnapshot {
  FailurePerformanceSnapshot({
    required this.remainingHpRatio,
    required this.heavyHitsTaken,
    required this.unblockableHitsTaken,
    required this.knockdownCount,
    required this.postureBreakCount,
    required this.voluntarilyQuit,
    required this.contentDangerTier,
  }) {
    if (!remainingHpRatio.isFinite ||
        remainingHpRatio < 0 ||
        remainingHpRatio > 1) {
      throw ArgumentError.value(
        remainingHpRatio,
        'remainingHpRatio',
        'must be within [0.0, 1.0]',
      );
    }
    if (heavyHitsTaken < 0) {
      throw ArgumentError.value(
        heavyHitsTaken,
        'heavyHitsTaken',
        'must be >= 0',
      );
    }
    if (unblockableHitsTaken < 0) {
      throw ArgumentError.value(
        unblockableHitsTaken,
        'unblockableHitsTaken',
        'must be >= 0',
      );
    }
    if (knockdownCount < 0) {
      throw ArgumentError.value(
        knockdownCount,
        'knockdownCount',
        'must be >= 0',
      );
    }
    if (postureBreakCount < 0) {
      throw ArgumentError.value(
        postureBreakCount,
        'postureBreakCount',
        'must be >= 0',
      );
    }
    if (contentDangerTier < 1) {
      throw ArgumentError.value(
        contentDangerTier,
        'contentDangerTier',
        'must be >= 1',
      );
    }
  }

  /// 结算时剩余生命比例（0.0 死亡 ~ 1.0 满血）。
  final double remainingHpRatio;

  /// 承受重击次数。
  final int heavyHitsTaken;

  /// 承受不可阻挡攻击次数。
  final int unblockableHitsTaken;

  /// 倒地次数。
  final int knockdownCount;

  /// 被破势次数。
  final int postureBreakCount;

  /// 是否主动退出（与 [FailureReason.surrender] 同源，供权重层冗余校验）。
  final bool voluntarilyQuit;

  /// 内容危险档（≥1，越高失败代价越重）。
  final int contentDangerTier;
}

/// 伤势索赔幂等键：`sessionId + participantId + contentKind` 三元组。
///
/// - 确定性：同输入恒同键（构造时 trim 规范化）；
/// - 非空：各部分 trim 后均非空，否则抛 [InvalidFailureClaimKeyError]；
/// - 作用域：仅含上述三元组，不含 failureReason（重试换失败原因仍是同一次索赔）。
///
/// 挑战 session 从第一次进入直到玩家胜利、主动退出、返回地图或应用恢复后
/// 明确结算为止（§17.7）；多次重试只结一次伤势：同一键的重复索赔被
/// `FailureClaimLedger` 拒绝。
final class FailureClaimKey {
  FailureClaimKey({
    required String sessionId,
    required String participantId,
    required FailureContentKind contentKind,
  }) : _sessionId = sessionId.trim(),
       _participantId = participantId.trim(),
       _contentKind = contentKind {
    if (_sessionId.isEmpty) {
      throw const InvalidFailureClaimKeyError('sessionId must not be empty');
    }
    if (_participantId.isEmpty) {
      throw const InvalidFailureClaimKeyError(
        'participantId must not be empty',
      );
    }
    if (_sessionId.contains('|') || _participantId.contains('|')) {
      throw const InvalidFailureClaimKeyError(
        'sessionId and participantId must not contain "|"',
      );
    }
  }

  final String _sessionId;
  final String _participantId;
  final FailureContentKind _contentKind;

  String get sessionId => _sessionId;
  String get participantId => _participantId;
  FailureContentKind get contentKind => _contentKind;

  /// 确定性规范化键（唯一标识一次伤势索赔）。
  String get value => '$_sessionId|$_participantId|${_contentKind.name}';

  @override
  bool operator ==(Object other) =>
      other is FailureClaimKey && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'FailureClaimKey($value)';
}
