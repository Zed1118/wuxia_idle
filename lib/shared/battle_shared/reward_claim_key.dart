/// Deterministic, versioned keys identifying a single claimable reward grant.
///
/// Two claim-key shapes are supported:
/// - battle session grants: `battleSessionId + stageId + rewardGrantId`
/// - run choice grants: `runId + rewardChoiceId`
/// - mentor insight first-clear grants: `stageId + characterId`
///
/// The canonical string is the single source of identity: two keys are equal
/// if and only if their canonical strings are equal. The version segment lets
/// future key format changes fail closed against stale claims instead of
/// silently colliding or matching.
library;

enum RewardClaimKeyKind {
  battleSessionGrant,
  runChoice,

  /// 随行听剑首通成长发放键（P2-M2-R02 · MENTOR-INSIGHT-CORE-01 不重复发放）。
  /// 键形 `stageId + characterId`：只锁关 + 门人，不含 session，崩溃恢复
  /// 重放同一键；重打 / 自动重刷 / 扫荡也命中同一键 → 不重复发放。
  mentorInsight,
}

final class RewardClaimKey {
  RewardClaimKey._({
    required this.version,
    required this.kind,
    required List<String> parts,
  }) : parts = List.unmodifiable(parts);

  static const int currentVersion = 1;
  static const String versionPrefix = 'v';
  static const String componentSeparator = '|';

  final int version;
  final RewardClaimKeyKind kind;

  /// Canonical component order per kind:
  /// - [RewardClaimKeyKind.battleSessionGrant]: battleSessionId, stageId, rewardGrantId
  /// - [RewardClaimKeyKind.runChoice]: runId, rewardChoiceId
  /// - [RewardClaimKeyKind.mentorInsight]: stageId, characterId
  final List<String> parts;

  factory RewardClaimKey.battleSessionGrant({
    required String battleSessionId,
    required String stageId,
    required String rewardGrantId,
  }) {
    return RewardClaimKey._(
      version: currentVersion,
      kind: RewardClaimKeyKind.battleSessionGrant,
      parts: [
        _validatedComponent(battleSessionId, 'battleSessionId'),
        _validatedComponent(stageId, 'stageId'),
        _validatedComponent(rewardGrantId, 'rewardGrantId'),
      ],
    );
  }

  factory RewardClaimKey.runChoice({
    required String runId,
    required String rewardChoiceId,
  }) {
    return RewardClaimKey._(
      version: currentVersion,
      kind: RewardClaimKeyKind.runChoice,
      parts: [
        _validatedComponent(runId, 'runId'),
        _validatedComponent(rewardChoiceId, 'rewardChoiceId'),
      ],
    );
  }

  /// 随行听剑首通成长发放键（P2-M2-R02 · MENTOR-INSIGHT-CORE-01）。
  ///
  /// 键形 `stageId + characterId`，个人作用域（按门人记账）。
  /// [characterId] 必须 > 0；[stageId] trim 后非空且不含分隔符。
  factory RewardClaimKey.mentorInsight({
    required String stageId,
    required int characterId,
  }) {
    if (characterId <= 0) {
      throw ArgumentError.value(characterId, 'characterId', 'must be > 0');
    }
    return RewardClaimKey._(
      version: currentVersion,
      kind: RewardClaimKeyKind.mentorInsight,
      parts: [
        _validatedComponent(stageId.trim(), 'stageId'),
        characterId.toString(),
      ],
    );
  }

  /// Parses a canonical string produced by [canonical].
  ///
  /// Throws [FormatException] on malformed input or an unsupported version so
  /// stale keys fail closed instead of being treated as claimable.
  static RewardClaimKey parse(String canonical) {
    final segments = canonical.split(componentSeparator);
    if (segments.length < 2) {
      throw FormatException(
        'Malformed reward claim key (expected version and components): '
        '"$canonical"',
      );
    }

    final versionSegment = segments.first;
    if (!versionSegment.startsWith(versionPrefix)) {
      throw FormatException(
        'Malformed reward claim key (missing version prefix): "$canonical"',
      );
    }
    final version = int.tryParse(
      versionSegment.substring(versionPrefix.length),
    );
    if (version == null) {
      throw FormatException(
        'Malformed reward claim key (unparseable version "$versionSegment"): '
        '"$canonical"',
      );
    }
    if (version != currentVersion) {
      throw FormatException(
        'Unsupported reward claim key version $version '
        '(current: $currentVersion): "$canonical"',
      );
    }

    final kindName = segments[1];
    final kind = RewardClaimKeyKind.values.firstWhere(
      (candidate) => candidate.name == kindName,
      orElse: () => throw FormatException(
        'Unknown reward claim key kind "$kindName": "$canonical"',
      ),
    );

    final parts = segments.sublist(2);
    final expectedPartCount = _expectedPartCount(kind);
    if (parts.length != expectedPartCount) {
      throw FormatException(
        'Reward claim key kind "$kindName" expects $expectedPartCount '
        'components, got ${parts.length}: "$canonical"',
      );
    }
    for (var i = 0; i < parts.length; i++) {
      try {
        _validatedComponent(parts[i], '$kindName component $i');
      } on ArgumentError catch (error) {
        throw FormatException(
          'Malformed reward claim key component: $error',
          canonical,
        );
      }
    }
    if (kind == RewardClaimKeyKind.mentorInsight) {
      final characterId = int.tryParse(parts[1]);
      if (characterId == null || characterId <= 0) {
        throw FormatException(
          'Reward claim key kind "$kindName" requires a positive integer '
          'characterId, got "${parts[1]}": "$canonical"',
        );
      }
    }

    return RewardClaimKey._(version: version, kind: kind, parts: parts);
  }

  String get canonical =>
      ['$versionPrefix$version', kind.name, ...parts].join(componentSeparator);

  /// mentorInsight 形态的 stageId（其他 kind 抛 [StateError]）。
  String get stageId {
    if (kind != RewardClaimKeyKind.mentorInsight) {
      throw StateError(
        'RewardClaimKey kind ${kind.name} has no stageId component',
      );
    }
    return parts[0];
  }

  /// mentorInsight 形态的 characterId（其他 kind 抛 [StateError]）。
  int get characterId {
    if (kind != RewardClaimKeyKind.mentorInsight) {
      throw StateError(
        'RewardClaimKey kind ${kind.name} has no characterId component',
      );
    }
    return int.parse(parts[1]);
  }

  static int _expectedPartCount(RewardClaimKeyKind kind) {
    switch (kind) {
      case RewardClaimKeyKind.battleSessionGrant:
        return 3;
      case RewardClaimKeyKind.runChoice:
        return 2;
      case RewardClaimKeyKind.mentorInsight:
        return 2;
    }
  }

  static String _validatedComponent(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        name,
        'Reward claim key component must not be empty',
      );
    }
    if (value.contains(componentSeparator)) {
      throw ArgumentError.value(
        value,
        name,
        'Reward claim key component must not contain '
        '"$componentSeparator"',
      );
    }
    return value;
  }

  @override
  bool operator ==(Object other) =>
      other is RewardClaimKey && other.canonical == canonical;

  @override
  int get hashCode => canonical.hashCode;

  @override
  String toString() => canonical;
}
