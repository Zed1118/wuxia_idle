/// 连续主线 run 纯合同（P2-M2-R01 / MAINLINE-RUN-01，decision registry
/// 2026-08-24 frozen）：
/// - A（participant_lock）：整段 run 锁同一参与者；
/// - B（between_stage_loadout）：关间允许换装，每次进入下一关生成版本化
///   新战斗快照；快照以独立、不透明的 `loadoutSnapshotId` 表达，与每角色
///   唯一持久装配方案（REOPEN-LOADOUT-PLAN-01=A）语义解耦，不把持久装配
///   误当 run snapshot，也不新增双 preset；
/// - B（injury_interruption）：仅当参与者下一关不再可战时中断；可战与否
///   是调用方已判定的外部事实，`proceedToNext` 强制消费该事实——`false`
///   即拒绝推进（fail closed）；本合同不发明可战判定、伤势阈值或任何
///   调优默认，也不做查询。
///
/// 纯值对象：无持久化、无 schema、无时钟、不接入生产流。
library;

/// 连续 run 的唯一停止理由（G0 injury_interruption=B）。
enum MainlineRunStopReason { participantNotBattleEligibleForNextStage }

/// 连续 run 合同错误基类。
class MainlineRunException implements Exception {
  const MainlineRunException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// 推进被拒：外部事实表明参与者下一关不再可战时，`proceedToNext`
/// fail closed，绝不返回新 run 或新快照（MAINLINE-RUN-01/C=B 强制中断）。
final class MainlineRunTransitionRefusedError extends MainlineRunException {
  MainlineRunTransitionRefusedError(this.reason)
    : super('MainlineRun transition refused: ${reason.name}');

  final MainlineRunStopReason reason;
}

/// 关间装配快照：版本在本 run 内单调递增（第一关为 1）。
///
/// [loadoutSnapshotId] 是调用方生成的不透明快照 ID：本合同对其 trim
/// 规范化后校验非空并携带，不解析、不比对持久装配方案，也不从 ID
/// 推断内容。
final class MainlineRunLoadoutSnapshot {
  MainlineRunLoadoutSnapshot({
    required this.version,
    required String loadoutSnapshotId,
  }) : _loadoutSnapshotId = loadoutSnapshotId.trim() {
    if (version < 1) {
      throw ArgumentError.value(version, 'version', 'must be >= 1');
    }
    if (_loadoutSnapshotId.isEmpty) {
      throw ArgumentError.value(
        loadoutSnapshotId,
        'loadoutSnapshotId',
        'must not be empty',
      );
    }
  }

  final int version;
  final String _loadoutSnapshotId;

  /// 不透明快照 ID；不是持久装配方案 ID，也不承载装配内容。
  String get loadoutSnapshotId => _loadoutSnapshotId;

  @override
  bool operator ==(Object other) =>
      other is MainlineRunLoadoutSnapshot &&
      other.version == version &&
      other.loadoutSnapshotId == loadoutSnapshotId;

  @override
  int get hashCode => Object.hash(version, loadoutSnapshotId);

  @override
  String toString() =>
      'MainlineRunLoadoutSnapshot(version: $version, '
      'loadoutSnapshotId: $loadoutSnapshotId)';
}

/// 一段连续主线 run：整段锁同一参与者，关间换装生成版本化新快照。
final class MainlineRun {
  MainlineRun.begin({
    required String runId,
    required int participantId,
    required String stageId,
    required String loadoutSnapshotId,
  }) : this._(
         runId: runId,
         participantId: participantId,
         stageId: stageId,
         snapshots: [
           MainlineRunLoadoutSnapshot(
             version: 1,
             loadoutSnapshotId: loadoutSnapshotId,
           ),
         ],
       );

  MainlineRun._({
    required String runId,
    required this.participantId,
    required String stageId,
    required List<MainlineRunLoadoutSnapshot> snapshots,
  }) : _runId = runId.trim(),
       _currentStageId = stageId.trim(),
       _loadoutSnapshots = List.unmodifiable(snapshots) {
    if (_runId.isEmpty) {
      throw ArgumentError.value(runId, 'runId', 'must not be empty');
    }
    if (participantId <= 0) {
      throw ArgumentError.value(
        participantId,
        'participantId',
        'must be a positive character ID',
      );
    }
    if (_currentStageId.isEmpty) {
      throw ArgumentError.value(stageId, 'stageId', 'must not be empty');
    }
  }

  final String _runId;

  /// 整段 run 锁定的参与者（MAINLINE-RUN-01/A）。
  final int participantId;

  final String _currentStageId;
  final List<MainlineRunLoadoutSnapshot> _loadoutSnapshots;

  String get runId => _runId;
  String get currentStageId => _currentStageId;

  /// 本 run 内全部版本化装配快照（不可变，第一关版本为 1）。
  List<MainlineRunLoadoutSnapshot> get loadoutSnapshots => _loadoutSnapshots;

  int get currentLoadoutVersion => _loadoutSnapshots.last.version;

  /// 记录、成长与伤势归属对象恒为锁定的实际参与者。
  int get growthAndInjuryOwnerId => participantId;

  /// 进入下一关：参与者不变，装配允许更换并生成新版本快照；
  /// [loadoutSnapshotId] 由调用方为新一关生成，与持久装配方案无关。
  ///
  /// [participantBattleEligibleForNextStage] 是调用方已判定的外部事实。
  /// 推进前必须经同一停止决策（[stopReasonForNextStage]）：为 `false`
  /// （参与者下一关不再可战）时抛 [MainlineRunTransitionRefusedError]，
  /// fail closed，绝不返回新 run 或新快照；调用方不得绕过。
  MainlineRun proceedToNext({
    required String stageId,
    required String loadoutSnapshotId,
    required bool participantBattleEligibleForNextStage,
  }) {
    final stopReason = stopReasonForNextStage(
      participantBattleEligibleForNextStage:
          participantBattleEligibleForNextStage,
    );
    if (stopReason != null) {
      throw MainlineRunTransitionRefusedError(stopReason);
    }
    return MainlineRun._(
      runId: _runId,
      participantId: participantId,
      stageId: stageId,
      snapshots: [
        ..._loadoutSnapshots,
        MainlineRunLoadoutSnapshot(
          version: currentLoadoutVersion + 1,
          loadoutSnapshotId: loadoutSnapshotId,
        ),
      ],
    );
  }

  /// 是否停止连续 run：[participantBattleEligibleForNextStage] 是调用方
  /// 已判定的外部事实；仅当其为 `false`（参与者下一关不再可战）时返回
  /// 停止理由。本合同不做任何查询，也不猜测伤势阈值或其他停止条件。
  MainlineRunStopReason? stopReasonForNextStage({
    required bool participantBattleEligibleForNextStage,
  }) {
    if (participantBattleEligibleForNextStage) return null;
    return MainlineRunStopReason.participantNotBattleEligibleForNextStage;
  }

  @override
  bool operator ==(Object other) =>
      other is MainlineRun &&
      other.runId == runId &&
      other.participantId == participantId &&
      other.currentStageId == currentStageId &&
      _listEquals(other._loadoutSnapshots, _loadoutSnapshots);

  static bool _listEquals(
    List<MainlineRunLoadoutSnapshot> a,
    List<MainlineRunLoadoutSnapshot> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    runId,
    participantId,
    currentStageId,
    Object.hashAll(_loadoutSnapshots),
  );

  @override
  String toString() =>
      'MainlineRun(runId: $runId, participantId: $participantId, '
      'currentStageId: $currentStageId, '
      'loadoutVersion: $currentLoadoutVersion)';
}
