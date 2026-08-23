/// P2-M2-R02 随行听剑首通幂等 claim 合同
/// （MENTOR-INSIGHT-CORE-01 不重复发放 + MENTOR-INSIGHT-RATE-01 成长对象）。
///
/// 只定义 claim 键、作用域声明与幂等台账；无持久化、无 schema、无生产接线。
/// 比例与每关上限为 TUNING，本合同不含任何数值字段。
///
/// 对齐既有 shared `reward_claim_key.dart` / `reward_policy.dart` 的纪律：
/// 版本化规范串为唯一身份、未知版本 fail closed、重复键先拒后执行、回调抛错
/// 不记账；因随行听剑键形（stageId + 门人 id，个人作用域）与既有两种键形
/// 均不同，故在应用层内自成一体，不改动 shared 实现。
library;

import '../domain/mentor_insight_policy.dart';

/// 首通随行听剑 claim 幂等键。
///
/// 规范串为唯一身份：`v1|mentorInsight|<stageId>|<characterId>`。
/// - 确定性：同 (stageId, characterId) 恒同键；
/// - 作用域：只含 stageId + 门人 id，不含 session —— 崩溃恢复重放同一键，
///   重打 / 自动重刷 / 扫荡也命中同一键 → 不重复发放；
/// - 版本化：未知版本 fail closed，不当作可 claim。
final class MentorInsightClaimKey {
  MentorInsightClaimKey._({
    required this.version,
    required this.stageId,
    required this.characterId,
  });

  factory MentorInsightClaimKey({
    required String stageId,
    required int characterId,
  }) {
    final trimmed = stageId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(stageId, 'stageId', 'must not be empty');
    }
    if (trimmed.contains(componentSeparator)) {
      throw ArgumentError.value(
        stageId,
        'stageId',
        'must not contain "$componentSeparator"',
      );
    }
    if (characterId <= 0) {
      throw ArgumentError.value(characterId, 'characterId', 'must be > 0');
    }
    return MentorInsightClaimKey._(
      version: currentVersion,
      stageId: trimmed,
      characterId: characterId,
    );
  }

  static const int currentVersion = 1;
  static const String versionPrefix = 'v';
  static const String componentSeparator = '|';
  static const String kindName = 'mentorInsight';

  final int version;
  final String stageId;
  final int characterId;

  /// 规范化键（唯一身份）。解析失败见 [parse]。
  String get canonical =>
      '$versionPrefix$version|$kindName|$stageId|$characterId';

  /// 解析 [canonical] 产生的规范串。
  ///
  /// 畸形输入、未知版本、错误 kind、组件数不符或组件非法一律抛
  /// [FormatException]，fail closed 不当作可 claim。
  static MentorInsightClaimKey parse(String canonical) {
    final segments = canonical.split(componentSeparator);
    if (segments.length < 3) {
      throw FormatException(
        'Malformed mentor insight claim key (expected version, kind and '
        'components): "$canonical"',
      );
    }

    final versionSegment = segments[0];
    if (!versionSegment.startsWith(versionPrefix)) {
      throw FormatException(
        'Malformed mentor insight claim key (missing version prefix): '
        '"$canonical"',
      );
    }
    final version = int.tryParse(
      versionSegment.substring(versionPrefix.length),
    );
    if (version == null) {
      throw FormatException(
        'Malformed mentor insight claim key (unparseable version '
        '"$versionSegment"): "$canonical"',
      );
    }
    if (version != currentVersion) {
      throw FormatException(
        'Unsupported mentor insight claim key version $version '
        '(current: $currentVersion): "$canonical"',
      );
    }

    if (segments[1] != kindName) {
      throw FormatException(
        'Unknown mentor insight claim key kind "${segments[1]}": "$canonical"',
      );
    }

    final parts = segments.sublist(2);
    if (parts.length != 2) {
      throw FormatException(
        'Mentor insight claim key expects 2 components (stageId, characterId), '
        'got ${parts.length}: "$canonical"',
      );
    }
    final stageId = parts[0];
    if (stageId.isEmpty) {
      throw FormatException(
        'Malformed mentor insight claim key (empty stageId): "$canonical"',
      );
    }
    final characterId = int.tryParse(parts[1]);
    if (characterId == null || characterId <= 0) {
      throw FormatException(
        'Malformed mentor insight claim key (invalid characterId '
        '"${parts[1]}"): "$canonical"',
      );
    }

    return MentorInsightClaimKey._(
      version: version,
      stageId: stageId,
      characterId: characterId,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MentorInsightClaimKey && other.canonical == canonical;

  @override
  int get hashCode => canonical.hashCode;

  @override
  String toString() => canonical;
}

/// 首通 claim 政策声明（CORE-01 不重复发放 + RATE-01 成长对象）。
final class MentorInsightClaimPolicy {
  const MentorInsightClaimPolicy._();

  /// 成长对象仅主修招式熟练度（RATE-01）；单一取值，无其它目标。
  static const MentorInsightGrowthTarget growthTarget =
      MentorInsightGrowthTarget.mainTechniqueProficiency;

  /// 仅首通发放（CORE-01）；重打 / 自动重刷 / 扫荡不产生新 claim。
  static const bool firstClearOnly = true;

  /// 个人作用域：claim 按门人个人记账，不跨角色共享
  /// （对齐 shared `RewardScope.personal` 语义）。
  static const bool personalScope = true;

  /// 首通闸门：非首通 fail closed，不猜测重打 / 扫荡发放。
  static void enforceFirstClear(bool isFirstClear) {
    if (!isFirstClear) {
      throw const MentorInsightNotFirstClearException();
    }
  }
}

/// claim 结算效果回调：把成长对象落地（生产侧写入门人主修招式熟练度）。
typedef MentorInsightGrant = void Function(MentorInsightGrowthTarget target);

/// claim 合同错误基类。
class MentorInsightClaimException implements Exception {
  const MentorInsightClaimException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// 非首通（重打 / 自动重刷 / 扫荡）尝试 claim：fail closed，不发放。
final class MentorInsightNotFirstClearException
    extends MentorInsightClaimException {
  const MentorInsightNotFirstClearException()
    : super(
        'Mentor insight growth is granted only on the first clear of the '
        'stage; replays, auto re-runs and sweeps must not re-grant',
      );
}

/// 同键重复 claim：已发放过，拒绝重复发放。
final class MentorInsightClaimConflictException
    extends MentorInsightClaimException {
  const MentorInsightClaimConflictException(super.message);
}

/// 首通幂等台账（内存态，无持久化）。
///
/// 语义保证（对齐 shared `RewardGrantGuard` / `FailureClaimLedger` 体例）：
/// - 同键重复 claim 被拒（抛 [MentorInsightClaimConflictException]），grant
///   回调不执行；
/// - 非首通 claim 被拒（抛 [MentorInsightNotFirstClearException]），不记账；
/// - 单条：grant 回调抛错 → 键保持未 claim 并向上抛，调用方可重试；
/// - 幂等恢复结算 [settleIdempotently]：已 claim 则 no-op（返回 false），
///   未 claim 才发放（返回 true）——崩溃恢复重放同一键不会重复发放。
/// 落库 / 事务性由生产侧按 shared 体例承接，本合同不写存储。
final class MentorInsightClaimLedger {
  MentorInsightClaimLedger();

  final Set<String> _claimed = <String>{};

  bool isClaimed(MentorInsightClaimKey key) => _claimed.contains(key.canonical);

  /// 单条首通 claim：成功后才记账；重复或非首通不执行 grant。
  void claimFirstClear({
    required MentorInsightClaimKey key,
    required bool isFirstClear,
    required MentorInsightGrant grant,
  }) {
    MentorInsightClaimPolicy.enforceFirstClear(isFirstClear);
    if (isClaimed(key)) {
      throw MentorInsightClaimConflictException(
        'Mentor insight claim already settled: ${key.canonical}',
      );
    }
    grant(MentorInsightClaimPolicy.growthTarget);
    _claimed.add(key.canonical);
  }

  /// 幂等恢复结算：已发放则 no-op 返回 false；未发放才执行 grant 并返回 true。
  ///
  /// 对应 [MentorInsightReleaseReason.idempotentRecoverySettlement]：崩溃恢复
  /// 重放同一结算键，重复调用不会重复发放。
  bool settleIdempotently({
    required MentorInsightClaimKey key,
    required bool isFirstClear,
    required MentorInsightGrant grant,
  }) {
    MentorInsightClaimPolicy.enforceFirstClear(isFirstClear);
    if (isClaimed(key)) {
      return false;
    }
    claimFirstClear(key: key, isFirstClear: isFirstClear, grant: grant);
    return true;
  }
}
