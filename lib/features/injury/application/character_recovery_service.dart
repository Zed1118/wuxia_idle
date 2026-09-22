import 'package:isar_community/isar.dart';

import '../../../core/domain/character.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/save_data.dart';
import '../../seclusion/domain/retreat_session.dart';

/// A character owns one real-time recovery clock across every activity.
/// Battle recovery and medicine remain separate, explicit settlement effects.
abstract final class CharacterRecoveryService {
  /// Settles only the supplied object. The caller owns persistence and must run
  /// this before applying a new injury or an explicit recovery effect.
  ///
  /// [fallbackAnchor] is only for legacy/synthetic rows lacking their own clock.
  /// Without trustworthy evidence, recovery begins at [now], never at birth.
  /// Light injury has no timed decay; only explicit rest boundaries clear it.
  static bool settleCharacter({
    required Character character,
    required DateTime now,
    DateTime? fallbackAnchor,
    bool clearLightInjury = false,
  }) {
    if (!character.isAlive) return false;

    final previousAnchor = character.recoverySettledAt;
    final anchor =
        previousAnchor ??
        (fallbackAnchor == null
            ? now
            : fallbackAnchor.isBefore(character.createdAt)
            ? character.createdAt
            : fallbackAnchor);
    // Clock rollback must not heal, clear light injury, or write an earlier
    // boundary. A future fallback is not consumed until its time is reached.
    if (now.isBefore(anchor)) return false;

    var changed = previousAnchor == null || !now.isAtSameMomentAs(anchor);
    final elapsedMicros = now.difference(anchor).inMicroseconds;
    if (elapsedMicros > 0) {
      character.injuryHoursRemaining = _recoverHours(
        character.injuryHoursRemaining,
        elapsedMicros,
      );
      character.innerBreathDisorderHoursRemaining = _recoverHours(
        character.innerBreathDisorderHoursRemaining,
        elapsedMicros,
      );
    }
    if (clearLightInjury && character.lightInjuryStacks != 0) {
      character.lightInjuryStacks = 0;
      changed = true;
    }
    if (changed) character.recoverySettledAt = now;
    return changed;
  }

  static double _recoverHours(double remaining, int elapsedMicros) {
    if (remaining <= 0 || !remaining.isFinite) return remaining;
    // Use DateTime's microsecond precision so partitioning a two-hour recovery
    // into minute ticks reaches exactly zero, without a floating-point tail
    // keeping a healed character out of an activity. No gameplay epsilon.
    final remainingMicros =
        (remaining * Duration.microsecondsPerHour).round() - elapsedMicros;
    return remainingMicros > 0
        ? remainingMicros / Duration.microsecondsPerHour
        : 0;
  }

  /// Runs inside the caller's Isar write transaction; never opens a nested one.
  /// By default every living character recovers, regardless of leader status.
  /// Missing and deceased requested ids are ignored; duplicate ids settle once.
  static Future<void> settleWithinTxn({
    required Isar isar,
    required DateTime now,
    Iterable<int>? characterIds,
    bool clearLightInjury = false,
  }) async {
    final characters = characterIds == null
        ? await isar.characters.filter().isAliveEqualTo(true).findAll()
        : (await isar.characters.getAll(characterIds.toSet().toList()))
              .whereType<Character>()
              .where((character) => character.isAlive)
              .toList(growable: false);
    final save =
        characters.any((character) => character.recoverySettledAt == null)
        ? await isar.saveDatas.get(0)
        : null;
    for (final character in characters) {
      DateTime? fallbackAnchor;
      if (character.recoverySettledAt == null) {
        if (save != null && save.lastOnlineAt != save.createdAt) {
          fallbackAnchor = save.lastOnlineAt;
        }
        final sessionId = character.currentRetreatSessionId;
        if (sessionId != null) {
          final session = await isar.retreatSessions.get(sessionId);
          if (session != null && session.status == RetreatStatus.active) {
            if (save == null || session.saveDataId != save.slotId) {
              throw StateError(
                'Recovery retreat $sessionId has no matching save slot '
                'for character ${character.id}',
              );
            }
            // Old active retreats never settled timed recovery before release.
            fallbackAnchor = session.startedAt;
          }
        }
      }
      if (settleCharacter(
        character: character,
        now: now,
        fallbackAnchor: fallbackAnchor,
        clearLightInjury: clearLightInjury,
      )) {
        await isar.characters.put(character);
      }
    }
  }
}
