import 'package:isar_community/isar.dart';

import '../domain/progressive_unlock.dart';
import '../domain/progressive_unlock_receipt.dart';

class PendingProgressiveUnlock {
  const PendingProgressiveUnlock({
    required this.unlockId,
    required this.openedAt,
  });

  final ProgressiveUnlockId unlockId;
  final DateTime openedAt;
}

abstract interface class ProgressiveUnlockReceiptPort {
  Future<List<PendingProgressiveUnlock>> observe({
    required int saveDataId,
    required ProgressiveUnlockSnapshot snapshot,
    required DateTime now,
  });

  Future<void> acknowledge({
    required int saveDataId,
    required Iterable<ProgressiveUnlockId> unlockIds,
    required DateTime now,
  });
}

class ProgressiveUnlockService implements ProgressiveUnlockReceiptPort {
  const ProgressiveUnlockService(this._isar);

  final Isar _isar;

  @override
  Future<List<PendingProgressiveUnlock>> observe({
    required int saveDataId,
    required ProgressiveUnlockSnapshot snapshot,
    required DateTime now,
  }) async {
    final pending = <PendingProgressiveUnlock>[];
    await _isar.writeTxn(() async {
      for (final unlockId in ProgressiveUnlockId.values) {
        final key = ProgressiveUnlockReceipt.canonicalKey(
          saveDataId: saveDataId,
          unlockId: unlockId,
        );
        var row = await _isar.progressiveUnlockReceipts.getByReceiptKey(key);
        final observedState = snapshot[unlockId];
        if (row == null) {
          row = ProgressiveUnlockReceipt.firstObservation(
            saveDataId: saveDataId,
            unlockId: unlockId,
            state: observedState,
            observedAt: now,
          );
        } else {
          row.validateIdentity();
          if (observedState.index > row.highestState.index) {
            final previousState = row.highestState;
            row.highestState = observedState;
            if (previousState != ProgressiveUnlockState.open &&
                observedState == ProgressiveUnlockState.open &&
                row.openedAt == null) {
              row.openedAt = now;
            }
          }
          row.updatedAt = now;
        }
        await _isar.progressiveUnlockReceipts.put(row);
        if (row.highestState == ProgressiveUnlockState.open &&
            row.sealAcknowledgedAt == null) {
          final openedAt = row.openedAt;
          if (openedAt == null) {
            throw StateError('Pending progressive unlock has no openedAt');
          }
          pending.add(
            PendingProgressiveUnlock(unlockId: unlockId, openedAt: openedAt),
          );
        }
      }
    });
    return List.unmodifiable(pending);
  }

  @override
  Future<void> acknowledge({
    required int saveDataId,
    required Iterable<ProgressiveUnlockId> unlockIds,
    required DateTime now,
  }) async {
    final ids = unlockIds.toList(growable: false);
    if (ids.isEmpty) return;
    if (ids.toSet().length != ids.length) {
      throw ArgumentError.value(unlockIds, 'unlockIds', 'must be unique');
    }
    await _isar.writeTxn(() async {
      final rows = <ProgressiveUnlockReceipt>[];
      for (final unlockId in ids) {
        final key = ProgressiveUnlockReceipt.canonicalKey(
          saveDataId: saveDataId,
          unlockId: unlockId,
        );
        final row = await _isar.progressiveUnlockReceipts.getByReceiptKey(key);
        if (row == null) {
          throw StateError('Progressive unlock receipt is missing: $key');
        }
        row.validateIdentity();
        if (row.highestState != ProgressiveUnlockState.open ||
            row.openedAt == null) {
          throw StateError('Progressive unlock is not open: $key');
        }
        rows.add(row);
      }
      for (final row in rows) {
        row
          ..sealAcknowledgedAt ??= now
          ..updatedAt = now;
        await _isar.progressiveUnlockReceipts.put(row);
      }
    });
  }
}
