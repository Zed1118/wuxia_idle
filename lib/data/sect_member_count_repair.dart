import 'package:isar_community/isar.dart';

import '../core/domain/character.dart';
import '../core/domain/save_data.dart';
import '../features/sect/domain/sect.dart';

enum SectMemberCountIssueReason {
  unsupportedSectIdentity,
  missingFounderPointer,
  founderPointerMismatch,
  missingFounder,
  unconfirmedFounder,
  founderInAnotherSect,
  inconsistentMembership,
  unassignedMembership,
}

/// An unresolved row is retained, never replaced with an invented zero count.
class SectMemberCountRepairIssue {
  const SectMemberCountRepairIssue({
    required this.sectId,
    required this.reason,
    this.characterId,
  });

  final int sectId;
  final int? characterId;
  final SectMemberCountIssueReason reason;

  @override
  String toString() =>
      'SectMemberCountRepairIssue(sectId: $sectId, '
      'characterId: $characterId, reason: ${reason.name})';
}

/// Approved menu 1A: rebuild only negative member-count caches from verified
/// current membership. This is separate from the exact 0.48 numeric defaults.
/// The caller owns the selected save's write transaction, including its version.
abstract final class SectMemberCountRepair {
  static Future<List<SectMemberCountRepairIssue>> repairInTxn(
    Isar isar,
    SaveData save,
  ) async {
    // Inspect deserialized values so the real readLong missing-property sentinel
    // and already-persisted minLong+k values take the same negative-count path.
    final sects = await isar.sects.where().findAll();
    final pending = sects.where((sect) => sect.memberCount < 0).toList();
    if (pending.isEmpty) return const [];

    final characters = await isar.characters.where().findAll();
    final byId = {for (final character in characters) character.id: character};
    final sectIds = sects.map((sect) => sect.id).toSet();
    final issues = <SectMemberCountRepairIssue>[];
    for (final sect in pending) {
      final rowIssues = <SectMemberCountRepairIssue>[];
      void reject(SectMemberCountIssueReason reason, [int? characterId]) {
        rowIssues.add(
          SectMemberCountRepairIssue(
            sectId: sect.id,
            characterId: characterId,
            reason: reason,
          ),
        );
      }

      // All production creation paths use this persistent default-sect ID.
      // SaveData's founder pointer cannot establish ownership of another sect.
      if (sect.id != 1) {
        reject(SectMemberCountIssueReason.unsupportedSectIdentity);
        issues.addAll(rowIssues);
        continue;
      }

      final founder = byId[sect.founderId];
      if (save.founderCharacterId == null) {
        reject(SectMemberCountIssueReason.missingFounderPointer);
      } else if (save.founderCharacterId != sect.founderId) {
        reject(
          SectMemberCountIssueReason.founderPointerMismatch,
          sect.founderId,
        );
      }
      if (founder == null) {
        reject(SectMemberCountIssueReason.missingFounder, sect.founderId);
      } else {
        if (!founder.isFounder) {
          reject(SectMemberCountIssueReason.unconfirmedFounder, founder.id);
        }
        if (founder.sectId != null && founder.sectId != sect.id) {
          reject(SectMemberCountIssueReason.founderInAnotherSect, founder.id);
        }
      }

      var count = 0;
      for (final character in characters) {
        final owner = character.sectId;
        if (owner == null) {
          if (character.isInSect || character.sectRank != null) {
            // Its actual owner cannot be established; do not silently omit it.
            reject(
              SectMemberCountIssueReason.unassignedMembership,
              character.id,
            );
          }
          continue;
        }
        if (!sectIds.contains(owner)) {
          reject(SectMemberCountIssueReason.unassignedMembership, character.id);
          continue;
        }
        if (owner != sect.id) continue;
        if (!character.isInSect || character.sectRank == null) {
          reject(
            SectMemberCountIssueReason.inconsistentMembership,
            character.id,
          );
          continue;
        }
        // A retired founder may still have isFounder=true. Death, active state,
        // and lineage role do not remove a character from the current sect.
        if (character.id != sect.founderId) count++;
      }

      if (rowIssues.isNotEmpty) {
        issues.addAll(rowIssues);
        continue;
      }
      sect.memberCount = count;
      await isar.sects.put(sect);
    }
    return List.unmodifiable(issues);
  }
}
