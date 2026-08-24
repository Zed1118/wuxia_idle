import 'package:isar_community/isar.dart';

import '../domain/mainline_settlement_journal.dart';

enum MainlineCoreCommitDisposition { applied, alreadyApplied }

/// 第一章连续首通的持久结算事务边界。
///
/// 本服务只拥有 journal/claim 与调用方提供的事务内 callback，不复制战斗结算、
/// 奖励或伤势规则。callback 必须使用同一个 [isar] 且不得再开启 writeTxn。
class MainlineSettlementJournalService {
  const MainlineSettlementJournalService(this.isar);

  final Isar isar;

  Future<MainlineSettlementJournal?> activeForSave(int saveDataId) async {
    final rows = await isar.mainlineSettlementJournals.where().findAll();
    final active = rows
        .where(
          (row) =>
              row.saveDataId == saveDataId &&
              row.phase != MainlineSettlementPhase.closed,
        )
        .toList(growable: false);
    if (active.length > 1) {
      throw StateError('Multiple active mainline settlement journals');
    }
    return active.firstOrNull;
  }

  /// Reads a receipt by its typed settlement identity for outbox facades.
  Future<MainlineSettlementJournal?> journalFor(
    MainlineSettlementIdentity identity,
  ) => _findByIdentityInTxn(identity);

  Future<MainlineSettlementJournal> prepare({
    required int saveDataId,
    required MainlineSettlementIdentity identity,
    required String loadoutSnapshotId,
    List<String>? loadoutSnapshotIds,
    required DateTime now,
  }) async {
    late MainlineSettlementJournal result;
    await isar.writeTxn(() async {
      final active = await _activeForSaveInTxn(saveDataId);
      if (active != null) {
        final normalizedSnapshots = loadoutSnapshotIds
            ?.map((value) => value.trim())
            .toList(growable: false);
        final isSame =
            active.identity == identity &&
            active.loadoutSnapshotId == loadoutSnapshotId.trim() &&
            (normalizedSnapshots == null ||
                _stringListsEqual(
                  active.loadoutSnapshotIds,
                  normalizedSnapshots,
                ));
        if (isSame) {
          result = active;
          return;
        }
        if (!_canAdvanceToNextStage(
          active: active,
          nextIdentity: identity,
          nextSnapshotIds: normalizedSnapshots,
          nextSnapshotId: loadoutSnapshotId.trim(),
        )) {
          throw StateError(
            'Another mainline settlement journal is already active',
          );
        }
        active.close(at: now);
        await isar.mainlineSettlementJournals.put(active);
      }

      final existing = await _findByIdentityInTxn(identity);
      if (existing != null) {
        // closed identity 不可重新开启；同一结算事实永远只允许一条 receipt。
        result = existing;
        return;
      }

      final journal = MainlineSettlementJournal.prepare(
        saveDataId: saveDataId,
        identity: identity,
        loadoutSnapshotId: loadoutSnapshotId,
        loadoutSnapshotIds: loadoutSnapshotIds,
        createdAt: now,
      );
      await isar.mainlineSettlementJournals.put(journal);
      result = journal;
    });
    return result;
  }

  static bool _stringListsEqual(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  static bool _canAdvanceToNextStage({
    required MainlineSettlementJournal active,
    required MainlineSettlementIdentity nextIdentity,
    required List<String>? nextSnapshotIds,
    required String nextSnapshotId,
  }) {
    if (active.phase != MainlineSettlementPhase.coreApplied ||
        active.postSettlementAction !=
            MainlinePostSettlementAction.enterNextStage ||
        !active.allEffectsCompleted ||
        nextSnapshotIds == null ||
        nextIdentity.runId != active.runId ||
        nextIdentity.participantId != active.participantId ||
        nextIdentity.loadoutVersion != active.loadoutVersion + 1 ||
        nextIdentity.stageId == active.stageId ||
        nextSnapshotIds.length != active.loadoutSnapshotIds.length + 1 ||
        nextSnapshotIds.last != nextSnapshotId) {
      return false;
    }
    for (var index = 0; index < active.loadoutSnapshotIds.length; index++) {
      if (active.loadoutSnapshotIds[index] != nextSnapshotIds[index]) {
        return false;
      }
    }
    return true;
  }

  Future<MainlineCoreCommitDisposition> commitCore({
    required MainlineSettlementIdentity identity,
    required List<String> pendingEffectIds,
    required DateTime now,
    required Future<void> Function() applyInTxn,
  }) => _commitCore(
    identity: identity,
    now: now,
    applyInTxn: () async {
      await applyInTxn();
      return pendingEffectIds;
    },
  );

  /// 与核心业务写入同事务产生 outbox refs，避免在事务外按旧进度预判事项。
  Future<MainlineCoreCommitDisposition> commitCoreProducingEffects({
    required MainlineSettlementIdentity identity,
    required DateTime now,
    required Future<List<String>> Function() applyInTxn,
  }) => _commitCore(identity: identity, now: now, applyInTxn: applyInTxn);

  Future<MainlineCoreCommitDisposition> _commitCore({
    required MainlineSettlementIdentity identity,
    required DateTime now,
    required Future<List<String>> Function() applyInTxn,
  }) async {
    var disposition = MainlineCoreCommitDisposition.alreadyApplied;
    await isar.writeTxn(() async {
      final journal = await _requireByIdentityInTxn(identity);
      if (journal.phase == MainlineSettlementPhase.coreApplied ||
          journal.phase == MainlineSettlementPhase.closed) {
        return;
      }
      if (journal.phase != MainlineSettlementPhase.prepared) {
        throw StateError('Invalid journal phase for core settlement');
      }
      final producedEffectIds = await applyInTxn();
      journal.markCoreApplied(pendingEffectIds: producedEffectIds, at: now);
      await isar.mainlineSettlementJournals.put(journal);
      disposition = MainlineCoreCommitDisposition.applied;
    });
    return disposition;
  }

  /// 在业务 effect 与其 durable claim 的同一事务内执行一次。
  /// 已完成 effect 返回 false，callback 不会再次运行。
  Future<bool> applyEffect({
    required MainlineSettlementIdentity identity,
    required String effectId,
    required DateTime now,
    required Future<void> Function() applyInTxn,
  }) async {
    var applied = false;
    await isar.writeTxn(() async {
      final journal = await _requireByIdentityInTxn(identity);
      final normalized = effectId.trim();
      if (journal.completedEffectIds.contains(normalized)) return;
      if (journal.phase != MainlineSettlementPhase.coreApplied) {
        throw StateError('Journal is not ready for post-settlement effects');
      }
      if (!journal.pendingEffectIds.contains(normalized)) {
        throw StateError('Unknown mainline settlement effect: $effectId');
      }
      await applyInTxn();
      journal.markEffectCompleted(normalized, at: now);
      await isar.mainlineSettlementJournals.put(journal);
      applied = true;
    });
    return applied;
  }

  Future<void> close({
    required MainlineSettlementIdentity identity,
    required DateTime now,
  }) async {
    await isar.writeTxn(() async {
      final journal = await _requireByIdentityInTxn(identity);
      if (journal.phase == MainlineSettlementPhase.closed) return;
      journal.close(at: now);
      await isar.mainlineSettlementJournals.put(journal);
    });
  }

  Future<bool> recordPostSettlementAction({
    required MainlineSettlementIdentity identity,
    required MainlinePostSettlementAction action,
    required DateTime now,
  }) async {
    var recorded = false;
    await isar.writeTxn(() async {
      final journal = await _requireByIdentityInTxn(identity);
      recorded = journal.recordPostSettlementAction(action, at: now);
      if (recorded) {
        await isar.mainlineSettlementJournals.put(journal);
      }
    });
    return recorded;
  }

  Future<MainlineSettlementJournal?> _activeForSaveInTxn(int saveDataId) async {
    final rows = await isar.mainlineSettlementJournals.where().findAll();
    final active = rows
        .where(
          (row) =>
              row.saveDataId == saveDataId &&
              row.phase != MainlineSettlementPhase.closed,
        )
        .toList(growable: false);
    if (active.length > 1) {
      throw StateError('Multiple active mainline settlement journals');
    }
    return active.firstOrNull;
  }

  Future<MainlineSettlementJournal?> _findByIdentityInTxn(
    MainlineSettlementIdentity identity,
  ) async {
    final rows = await isar.mainlineSettlementJournals.where().findAll();
    for (final row in rows) {
      if (row.settlementId == identity.canonical) return row;
    }
    return null;
  }

  Future<MainlineSettlementJournal> _requireByIdentityInTxn(
    MainlineSettlementIdentity identity,
  ) async {
    final journal = await _findByIdentityInTxn(identity);
    if (journal == null) {
      throw StateError('Mainline settlement journal does not exist');
    }
    if (journal.identity != identity) {
      throw StateError('Mainline settlement identity mismatch');
    }
    return journal;
  }
}
