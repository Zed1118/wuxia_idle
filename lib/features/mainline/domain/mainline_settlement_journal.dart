import 'package:isar_community/isar.dart';

part 'mainline_settlement_journal.g.dart';

/// 主线持久结算键。四个组成部分共同锁定一次可结算事实，避免只用关卡/周目
/// 把合法重打误判为重复，也避免进程内 run 恢复后换参与者或装配版本。
final class MainlineSettlementIdentity {
  MainlineSettlementIdentity({
    required String runId,
    required String stageId,
    required this.loadoutVersion,
    required this.participantId,
  }) : runId = _component(runId, 'runId'),
       stageId = _component(stageId, 'stageId') {
    if (loadoutVersion < 1) {
      throw ArgumentError.value(
        loadoutVersion,
        'loadoutVersion',
        'must be >= 1',
      );
    }
    if (participantId <= 0) {
      throw ArgumentError.value(participantId, 'participantId', 'must be > 0');
    }
  }

  static const int currentVersion = 1;
  static const String _separator = '|';

  final String runId;
  final String stageId;
  final int loadoutVersion;
  final int participantId;

  String get canonical =>
      'v$currentVersion$_separator$runId$_separator$stageId$_separator'
      '$loadoutVersion$_separator$participantId';

  static MainlineSettlementIdentity parse(String canonical) {
    final parts = canonical.split(_separator);
    if (parts.length != 5 || parts.first != 'v$currentVersion') {
      throw FormatException('Invalid mainline settlement identity', canonical);
    }
    final loadoutVersion = int.tryParse(parts[3]);
    final participantId = int.tryParse(parts[4]);
    if (loadoutVersion == null || participantId == null) {
      throw FormatException('Invalid numeric identity component', canonical);
    }
    MainlineSettlementIdentity parsed;
    try {
      parsed = MainlineSettlementIdentity(
        runId: parts[1],
        stageId: parts[2],
        loadoutVersion: loadoutVersion,
        participantId: participantId,
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid settlement identity: $error', canonical);
    }
    if (parsed.canonical != canonical) {
      throw FormatException(
        'Non-canonical mainline settlement identity',
        canonical,
      );
    }
    return parsed;
  }

  static String _component(String value, String name) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.contains(_separator)) {
      throw ArgumentError.value(
        value,
        name,
        'must be non-empty and must not contain "$_separator"',
      );
    }
    return normalized;
  }

  @override
  bool operator ==(Object other) =>
      other is MainlineSettlementIdentity && other.canonical == canonical;

  @override
  int get hashCode => canonical.hashCode;

  @override
  String toString() => canonical;
}

enum MainlineSettlementPhase { prepared, coreApplied, closed }

enum MainlineSettlementRecoveryAction {
  restartSameStage,
  resumePostSettlement,
  none,
}

enum MainlinePostSettlementAction {
  none,
  returnToMap,
  enterNextStage,
  showChapterScroll,
}

/// 主线单章连续首通的持久 stage-boundary journal。
///
/// `prepared` 只证明同一参与者/关卡/装配版本已获准开战，不证明胜负或结算；
/// 崩溃后必须重打当前关。`coreApplied` 只能与核心业务写入在同一 Isar 事务
/// 落库，恢复时只排空后置 effect，绝不重放成长、伤势、普通掉落或进度。
@collection
class MainlineSettlementJournal {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String settlementId;

  @Index()
  late int saveDataId;

  @Index()
  late String runId;

  late String stageId;
  late int participantId;
  late int loadoutVersion;
  late String loadoutSnapshotId;
  List<String> loadoutSnapshotIds = [];

  @Enumerated(EnumType.name)
  MainlineSettlementPhase phase = MainlineSettlementPhase.prepared;

  @Enumerated(EnumType.name)
  MainlinePostSettlementAction postSettlementAction =
      MainlinePostSettlementAction.none;

  List<String> pendingEffectIds = [];
  List<String> completedEffectIds = [];

  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? coreAppliedAt;
  DateTime? closedAt;

  static MainlineSettlementJournal prepare({
    required int saveDataId,
    required MainlineSettlementIdentity identity,
    required String loadoutSnapshotId,
    List<String>? loadoutSnapshotIds,
    required DateTime createdAt,
  }) {
    if (saveDataId < 1) {
      throw ArgumentError.value(saveDataId, 'saveDataId', 'must be >= 1');
    }
    final normalizedSnapshotId = loadoutSnapshotId.trim();
    if (normalizedSnapshotId.isEmpty) {
      throw ArgumentError.value(
        loadoutSnapshotId,
        'loadoutSnapshotId',
        'must not be empty',
      );
    }
    final normalizedSnapshotIds = (loadoutSnapshotIds ?? [loadoutSnapshotId])
        .map((value) => value.trim())
        .toList(growable: false);
    if (normalizedSnapshotIds.length != identity.loadoutVersion ||
        normalizedSnapshotIds.any((value) => value.isEmpty) ||
        normalizedSnapshotIds.last != normalizedSnapshotId) {
      throw ArgumentError.value(
        loadoutSnapshotIds,
        'loadoutSnapshotIds',
        'must contain every version and end with loadoutSnapshotId',
      );
    }
    return MainlineSettlementJournal()
      ..settlementId = identity.canonical
      ..saveDataId = saveDataId
      ..runId = identity.runId
      ..stageId = identity.stageId
      ..participantId = identity.participantId
      ..loadoutVersion = identity.loadoutVersion
      ..loadoutSnapshotId = normalizedSnapshotId
      ..loadoutSnapshotIds = normalizedSnapshotIds
      ..phase = MainlineSettlementPhase.prepared
      ..postSettlementAction = MainlinePostSettlementAction.none
      ..pendingEffectIds = []
      ..completedEffectIds = []
      ..createdAt = createdAt
      ..updatedAt = createdAt;
  }

  @ignore
  MainlineSettlementIdentity get identity {
    final parsed = MainlineSettlementIdentity.parse(settlementId);
    if (parsed.runId != runId ||
        parsed.stageId != stageId ||
        parsed.participantId != participantId ||
        parsed.loadoutVersion != loadoutVersion ||
        loadoutSnapshotIds.length != loadoutVersion ||
        loadoutSnapshotIds.isEmpty ||
        loadoutSnapshotIds.last != loadoutSnapshotId) {
      throw StateError('Mainline settlement journal identity fields drifted');
    }
    return parsed;
  }

  @ignore
  MainlineSettlementRecoveryAction get recoveryAction {
    switch (phase) {
      case MainlineSettlementPhase.prepared:
        return MainlineSettlementRecoveryAction.restartSameStage;
      case MainlineSettlementPhase.coreApplied:
        return MainlineSettlementRecoveryAction.resumePostSettlement;
      case MainlineSettlementPhase.closed:
        return MainlineSettlementRecoveryAction.none;
    }
  }

  void markCoreApplied({
    required List<String> pendingEffectIds,
    required DateTime at,
  }) {
    if (phase != MainlineSettlementPhase.prepared) {
      throw StateError('Only a prepared journal can apply core settlement');
    }
    final normalized = <String>[];
    final seen = <String>{};
    for (final effectId in pendingEffectIds) {
      final value = effectId.trim();
      if (value.isEmpty || !seen.add(value)) {
        throw ArgumentError.value(
          pendingEffectIds,
          'pendingEffectIds',
          'must contain unique non-empty ids',
        );
      }
      normalized.add(value);
    }
    phase = MainlineSettlementPhase.coreApplied;
    this.pendingEffectIds = normalized;
    completedEffectIds = [];
    coreAppliedAt = at;
    updatedAt = at;
  }

  /// 返回 true 表示本次首次完成；同 effect 重放返回 false，不重复写 claim。
  bool markEffectCompleted(String effectId, {required DateTime at}) {
    if (phase != MainlineSettlementPhase.coreApplied) {
      throw StateError('Effects can only complete after core settlement');
    }
    final normalized = effectId.trim();
    if (!pendingEffectIds.contains(normalized)) {
      throw StateError('Unknown mainline settlement effect: $effectId');
    }
    if (completedEffectIds.contains(normalized)) return false;
    completedEffectIds = [...completedEffectIds, normalized];
    updatedAt = at;
    return true;
  }

  @ignore
  bool get allEffectsCompleted =>
      pendingEffectIds.every(completedEffectIds.contains);

  /// 持久记录玩家离开结算页后的唯一去向。恢复流程只能重放同一选择，不能
  /// 在已推进下一关后改成返回地图（反之亦然）。
  bool recordPostSettlementAction(
    MainlinePostSettlementAction action, {
    required DateTime at,
  }) {
    if (phase != MainlineSettlementPhase.coreApplied) {
      throw StateError('Post-settlement action requires applied settlement');
    }
    if (action == MainlinePostSettlementAction.none) {
      throw ArgumentError.value(action, 'action', 'must not be none');
    }
    if (postSettlementAction == action) return false;
    if (postSettlementAction != MainlinePostSettlementAction.none) {
      throw StateError('Mainline post-settlement action already recorded');
    }
    postSettlementAction = action;
    updatedAt = at;
    return true;
  }

  void close({required DateTime at}) {
    if (phase != MainlineSettlementPhase.coreApplied) {
      throw StateError('Only an applied journal can close');
    }
    if (!allEffectsCompleted) {
      throw StateError('Cannot close with pending settlement effects');
    }
    if (postSettlementAction == MainlinePostSettlementAction.none) {
      throw StateError('Cannot close before post-settlement action');
    }
    phase = MainlineSettlementPhase.closed;
    closedAt = at;
    updatedAt = at;
  }
}
