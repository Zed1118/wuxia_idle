import '../domain/mainline_pending_jianghu_affair.dart';
import '../domain/mainline_settlement_journal.dart';
import 'mainline_settlement_journal_service.dart';

/// Typed facade over the settlement journal's durable outbox.
///
/// The journal remains the sole persistence/transaction owner. This facade
/// only validates refs and imposes their FIFO consumption contract.
final class MainlinePendingJianghuAffairService {
  const MainlinePendingJianghuAffairService(this.journalService);

  final MainlineSettlementJournalService journalService;

  Future<MainlineCoreCommitDisposition> commitCore({
    required MainlineSettlementIdentity identity,
    required DateTime now,
    required Future<List<MainlinePendingJianghuAffairRef>> Function()
    applyInTxn,
  }) async {
    return journalService.commitCoreProducingEffects(
      identity: identity,
      now: now,
      applyInTxn: () async {
        final refs = await applyInTxn();
        final ids = <String>{};
        final sources = <String>{};
        for (var index = 0; index < refs.length; index++) {
          final ref = refs[index];
          if (ref.settlementId != identity.canonical ||
              ref.ordinal != index + 1 ||
              !ids.add(ref.effectId) ||
              !sources.add('${ref.kind.name}|${ref.sourceId}')) {
            throw StateError(
              'Pending affair ref is duplicated or bound to another settlement',
            );
          }
        }
        return refs.map((ref) => ref.effectId).toList(growable: false);
      },
    );
  }

  /// Returns the FIFO head that has not yet been claimed.
  Future<MainlinePendingJianghuAffairRef?> firstPending({
    required MainlineSettlementIdentity identity,
  }) async {
    final journal = await journalService.journalFor(identity);
    if (journal == null ||
        journal.phase != MainlineSettlementPhase.coreApplied) {
      return null;
    }
    for (final effectId in journal.pendingEffectIds) {
      if (journal.completedEffectIds.contains(effectId)) continue;
      final ref = _parse(effectId);
      if (ref.settlementId != identity.canonical) {
        throw StateError('Pending affair settlement mismatch');
      }
      return ref;
    }
    return null;
  }

  Future<MainlinePendingJianghuAffairRef?> nextPending({
    required MainlineSettlementIdentity identity,
  }) => firstPending(identity: identity);

  /// Resolves one ref; business writes and the durable claim share one txn.
  Future<bool> applyEffect({
    required MainlineSettlementIdentity identity,
    required String effectId,
    required DateTime now,
    required Future<void> Function() applyInTxn,
  }) async {
    final requested = _parse(effectId);
    final journal = await journalService.journalFor(identity);
    if (journal?.completedEffectIds.contains(requested.effectId) ?? false) {
      return false;
    }
    final head = await firstPending(identity: identity);
    if (head == null) return false;
    if (requested != head) {
      throw StateError('Pending affairs must be resolved FIFO');
    }
    return journalService.applyEffect(
      identity: identity,
      effectId: requested.effectId,
      now: now,
      applyInTxn: applyInTxn,
    );
  }

  Future<bool> apply({
    required MainlineSettlementIdentity identity,
    required MainlinePendingJianghuAffairRef affair,
    required DateTime now,
    required Future<void> Function() applyInTxn,
  }) => applyEffect(
    identity: identity,
    effectId: affair.effectId,
    now: now,
    applyInTxn: applyInTxn,
  );

  MainlinePendingJianghuAffairRef _parse(String value) {
    try {
      return MainlinePendingJianghuAffairRef.parse(value);
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Invalid pending affair ref: $error', value);
    }
  }
}
