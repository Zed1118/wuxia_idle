/// Deterministic, versioned keys identifying a single claimable reward grant.
///
/// Three claim-key shapes are supported:
/// - battle session grants: `battleSessionId + stageId + rewardGrantId`
/// - run choice grants: `runId + rewardChoiceId`
/// - mentor insight first-clear grants: `stageId + characterId`
///
/// The canonical string is the single source of identity: two keys are equal
/// if and only if their canonical strings are equal. The version segment lets
/// future key format changes fail closed against stale claims instead of
/// silently colliding or matching.
library;

import 'dart:convert';

import 'reward_contract.dart';

enum RewardContentKind {
  mainline,
  tower,
  lightFoot,
  massBattle,
  innerDemon,
  gauntlet,
  expedition,
}

enum RewardClaimKeyKind {
  battleSessionGrant,
  runChoice,

  /// 随行听剑首通成长发放键（P2-M2-R02 · MENTOR-INSIGHT-CORE-01 不重复发放）。
  /// 键形 `stageId + characterId`：只锁关 + 门人，不含 session，崩溃恢复
  /// 重放同一键；重打 / 自动重刷 / 扫荡也命中同一键 → 不重复发放。
  mentorInsight,

  /// 七类生产内容共用的 durable layer claim。
  contentLayer,
}

final class RewardClaimKey {
  RewardClaimKey._({
    required this.version,
    required this.kind,
    required List<String> parts,
  }) : parts = List.unmodifiable(parts);

  static const int currentVersion = 1;
  static const int durableContentVersion = 2;
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

  /// 构造七类生产内容共用的持久领取键。
  ///
  /// 首通键不含会话身份：宗门共享首通只由存档槽 + 内容锁定，个人首通再加
  /// 实际参战角色。重复产出与个人成长必须包含 occurrence，使一次合法重打
  /// 与另一场合法重打互不碰撞，而同一 durable settlement 重放仍命中同一键。
  factory RewardClaimKey.contentLayer({
    required RewardContentKind contentKind,
    required String contentId,
    required RewardLayer layer,
    required RewardScope scope,
    required int saveDataId,
    required int? participantId,
    required String occurrenceId,
  }) {
    if (saveDataId < 1 || saveDataId > 3) {
      throw ArgumentError.value(saveDataId, 'saveDataId', 'must be 1, 2 or 3');
    }
    if (scope == RewardScope.personal &&
        (participantId == null || participantId <= 0)) {
      throw ArgumentError.value(
        participantId,
        'participantId',
        'must be > 0 for personal scope',
      );
    }
    final occurrence = layer == RewardLayer.firstClear
        ? 'once'
        : _encodedOccurrence(_validatedOccurrence(occurrenceId.trim()));
    return RewardClaimKey._(
      version: durableContentVersion,
      kind: RewardClaimKeyKind.contentLayer,
      parts: [
        contentKind.name,
        _validatedComponent(contentId.trim(), 'contentId'),
        layer.name,
        scope.name,
        saveDataId.toString(),
        scope == RewardScope.sectShared ? 'sect' : participantId!.toString(),
        occurrence,
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
    if (version != currentVersion && version != durableContentVersion) {
      throw FormatException(
        'Unsupported reward claim key version $version '
        '(supported: $currentVersion, $durableContentVersion): "$canonical"',
      );
    }

    final kindName = segments[1];
    final kind = RewardClaimKeyKind.values.firstWhere(
      (candidate) => candidate.name == kindName,
      orElse: () => throw FormatException(
        'Unknown reward claim key kind "$kindName": "$canonical"',
      ),
    );
    if ((version == currentVersion &&
            kind == RewardClaimKeyKind.contentLayer) ||
        (version == durableContentVersion &&
            kind != RewardClaimKeyKind.contentLayer)) {
      throw FormatException(
        'Reward claim key kind "$kindName" is not valid for version $version: '
        '"$canonical"',
      );
    }

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
      // 规范形 fail closed：通过 factory 重建并要求 canonical 与输入完全一致，
      // 拒绝非规范别名（前后空白 stage、leading zero / plus sign / 负号）。
      // 否则 parse 保留别名会形成不同 canonical，绕过 durable 层去重。
      final rebuilt = RewardClaimKey.mentorInsight(
        stageId: parts[0],
        characterId: characterId,
      ).canonical;
      if (rebuilt != canonical) {
        throw FormatException(
          'Non-canonical mentorInsight claim key (expected "$rebuilt"): '
          '"$canonical"',
        );
      }
    }
    if (kind == RewardClaimKeyKind.contentLayer) {
      final contentKind = _enumByName(
        RewardContentKind.values,
        parts[0],
        'content kind',
        canonical,
      );
      final layer = _enumByName(
        RewardLayer.values,
        parts[2],
        'reward layer',
        canonical,
      );
      final scope = _enumByName(
        RewardScope.values,
        parts[3],
        'reward scope',
        canonical,
      );
      final saveDataId = int.tryParse(parts[4]);
      final participantId = scope == RewardScope.personal
          ? int.tryParse(parts[5])
          : 1;
      if (saveDataId == null || participantId == null) {
        throw FormatException(
          'Invalid content-layer numeric component',
          canonical,
        );
      }
      if (scope == RewardScope.sectShared && parts[5] != 'sect') {
        throw FormatException(
          'Sect-shared claim requires owner "sect"',
          canonical,
        );
      }
      late String rebuilt;
      try {
        rebuilt = RewardClaimKey.contentLayer(
          contentKind: contentKind,
          contentId: parts[1],
          layer: layer,
          scope: scope,
          saveDataId: saveDataId,
          participantId: participantId,
          occurrenceId: parts[6] == 'once'
              ? 'ignored'
              : _decodedOccurrence(parts[6], canonical),
        ).canonical;
      } on ArgumentError catch (error) {
        throw FormatException(
          'Malformed contentLayer claim key: $error',
          canonical,
        );
      }
      if (rebuilt != canonical) {
        throw FormatException(
          'Non-canonical contentLayer claim key (expected "$rebuilt")',
          canonical,
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

  RewardContentKind get contentKind {
    _requireContentLayer();
    return RewardContentKind.values.byName(parts[0]);
  }

  String get contentId {
    _requireContentLayer();
    return parts[1];
  }

  RewardLayer get layer {
    _requireContentLayer();
    return RewardLayer.values.byName(parts[2]);
  }

  RewardScope get scope {
    _requireContentLayer();
    return RewardScope.values.byName(parts[3]);
  }

  int get saveDataId {
    _requireContentLayer();
    return int.parse(parts[4]);
  }

  int? get participantId {
    _requireContentLayer();
    return scope == RewardScope.personal ? int.parse(parts[5]) : null;
  }

  String? get occurrenceId {
    _requireContentLayer();
    return layer == RewardLayer.firstClear
        ? null
        : _decodedOccurrence(parts[6], canonical);
  }

  void _requireContentLayer() {
    if (kind != RewardClaimKeyKind.contentLayer) {
      throw StateError('RewardClaimKey kind ${kind.name} is not contentLayer');
    }
  }

  static int _expectedPartCount(RewardClaimKeyKind kind) {
    switch (kind) {
      case RewardClaimKeyKind.battleSessionGrant:
        return 3;
      case RewardClaimKeyKind.runChoice:
        return 2;
      case RewardClaimKeyKind.mentorInsight:
        return 2;
      case RewardClaimKeyKind.contentLayer:
        return 7;
    }
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    String name,
    String label,
    String canonical,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw FormatException('Unknown $label "$name"', canonical);
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

  static String _encodedOccurrence(String value) {
    final encoded = base64Url.encode(utf8.encode(value)).replaceAll('=', '');
    return 'b64:$encoded';
  }

  static String _validatedOccurrence(String value) {
    if (value.isEmpty) {
      throw ArgumentError.value(
        value,
        'occurrenceId',
        'Reward occurrence must not be empty',
      );
    }
    return value;
  }

  static String _decodedOccurrence(String value, String canonical) {
    if (!value.startsWith('b64:')) {
      throw FormatException('Invalid encoded occurrence', canonical);
    }
    final payload = value.substring(4);
    final padded = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
    try {
      return utf8.decode(base64Url.decode(padded));
    } on FormatException {
      throw FormatException('Invalid encoded occurrence', canonical);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is RewardClaimKey && other.canonical == canonical;

  @override
  int get hashCode => canonical.hashCode;

  @override
  String toString() => canonical;
}
