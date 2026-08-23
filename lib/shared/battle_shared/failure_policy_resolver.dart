import 'failure_policy.dart';

/// C13 失败策略解析与索赔记账（二阶段方案 §17.7 / 任务清单 C13）。
///
/// 解析器无状态纯合同：注入规则表决定四分支，缺失规则 fail closed；
/// 台账持有内存态索赔键，保证重复拒绝、失败不记账与批量记账原子性。

/// 规则分支键：`(contentKind, failureReason)` → [FailureResolution]。
typedef FailurePolicyRuleKey = ({
  FailureContentKind contentKind,
  FailureReason failureReason,
});

/// 结算效果回调：应用层把 [FailureResolution] 落地为具体副作用
/// （伤势字段 / 内息紊乱 / 扣奖励）。本层只保证索赔记账语义与原子性，
/// 效果目标的事务性由调用方 outbox/事务负责（§17.7「结算、唯一奖励和
/// 待处理事件使用同一事务或 outbox」）。
typedef FailureEffect = void Function(FailureResolution resolution);

/// 解析结果：四分支决议 + 幂等索赔键。
final class FailurePolicyVerdict {
  const FailurePolicyVerdict({
    required this.resolution,
    required this.claimKey,
  });

  final FailureResolution resolution;
  final FailureClaimKey claimKey;
}

/// 失败策略解析器（无状态纯合同）。
///
/// 注入规则表决定 injury / disorder / partialReward / noPenalty 四分支；
/// 规则缺失 → fail closed 抛 [MissingFailurePolicyRuleError]，不静默猜测。
///
/// 作用域边界（二阶段方案 §17.7 / G0 PROPOSED）：
/// - **无 injury 权重**：解析只依赖规则表；[FailurePerformanceSnapshot] 仅校验
///   并透传，具体权重在 M0/M2 模拟中定标；
/// - **无 MainlineRun 参与者 / 换装 / 中断策略**：`leaderId + loadoutSnapshotId`
///   锁定、连续关卡间换装、伤势达到何种程度中断推进均为 PROPOSED，不在本合同内。
final class FailurePolicyResolver {
  FailurePolicyResolver({
    required Map<FailurePolicyRuleKey, FailureResolution> rules,
  }) : _rules = Map.unmodifiable(Map.of(rules));

  final Map<FailurePolicyRuleKey, FailureResolution> _rules;

  /// 解析一次失败结算。
  ///
  /// [sessionId] 与 [participantId] 组成索赔键作用域（trim 后非空校验）；
  /// [performanceSnapshot] 当前不参与分支，仅作合同输入校验。
  FailurePolicyVerdict resolve({
    required FailureContentKind contentKind,
    required String participantId,
    required String sessionId,
    required FailureReason failureReason,
    required FailurePerformanceSnapshot performanceSnapshot,
  }) {
    final ruleKey = (contentKind: contentKind, failureReason: failureReason);
    final resolution = _rules[ruleKey];
    if (resolution == null) {
      throw MissingFailurePolicyRuleError(
        contentKind: contentKind,
        failureReason: failureReason,
      );
    }
    return FailurePolicyVerdict(
      resolution: resolution,
      claimKey: FailureClaimKey(
        sessionId: sessionId,
        participantId: participantId,
        contentKind: contentKind,
      ),
    );
  }
}

/// 批内一条索赔：键 + 分支 + 应用层落地回调。
final class FailureBatchItem {
  const FailureBatchItem({
    required this.claimKey,
    required this.resolution,
    required this.effect,
  });

  final FailureClaimKey claimKey;
  final FailureResolution resolution;
  final FailureEffect effect;
}

/// 伤势索赔台账（内存态，无持久化）。
///
/// 语义保证：
/// - 同键重复索赔被拒（抛 [FailureClaimConflictError]）；
/// - 单条：效果回调抛错 → 键保持未索赔（不记账）并向上抛；
/// - 批量：先全量预校验（批内无重复键、无已结算键），再逐个执行效果，
///   任一效果失败 → 全部键都不记账（索赔记账原子性）；效果目标的事务性
///   由调用方 outbox/事务负责（§17.7）。
final class FailureClaimLedger {
  FailureClaimLedger();

  final Set<String> _claimed = <String>{};

  bool isClaimed(FailureClaimKey key) => _claimed.contains(key.value);

  /// 单条索赔：效果成功后才记账；效果抛错则不记账并向上抛。
  void applySingle({
    required FailureClaimKey claimKey,
    required FailureResolution resolution,
    required FailureEffect effect,
  }) {
    if (isClaimed(claimKey)) {
      throw FailureClaimConflictError(
        'Claim already settled: ${claimKey.value}',
      );
    }
    effect(resolution);
    _claimed.add(claimKey.value);
  }

  /// 批量索赔：预校验失败或任一效果失败时，全部键保持未索赔。
  void applyBatch(List<FailureBatchItem> items) {
    final pending = <String>{};
    for (final item in items) {
      final value = item.claimKey.value;
      if (_claimed.contains(value) || !pending.add(value)) {
        throw FailureClaimConflictError(
          'Batch contains a duplicate or already-settled claim: $value',
        );
      }
    }
    for (final item in items) {
      item.effect(item.resolution);
    }
    for (final item in items) {
      _claimed.add(item.claimKey.value);
    }
  }
}
