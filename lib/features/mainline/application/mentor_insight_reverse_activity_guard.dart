import '../domain/mentor_insight_policy.dart';
import 'mentor_insight_stage_occupancy_runtime.dart';

/// Refuses one activity request for the exact active listening companion.
final class MentorInsightActivityEntryRefusedError implements Exception {
  const MentorInsightActivityEntryRefusedError({
    required this.activeCompanion,
    required this.activity,
    required this.characterId,
  });

  final MentorInsightCompanion activeCompanion;
  final MentorInsightBlockingActivity activity;
  final int characterId;

  @override
  String toString() =>
      '$runtimeType(activeCompanion: $activeCompanion, '
      'activity: ${activity.name}, characterId: $characterId)';
}

/// Requires one character activity request to be compatible with the supplied
/// immutable mentor-insight occupancy view.
void requireMentorInsightActivityEntryAllowed({
  required MentorInsightStageOccupancySnapshot occupancy,
  required int characterId,
  required MentorInsightBlockingActivity activity,
}) {
  if (characterId <= 0) {
    throw ArgumentError.value(
      characterId,
      'characterId',
      'must be a positive character ID',
    );
  }
  if (!MentorInsightPolicy.mutuallyExclusiveActivities.contains(activity)) {
    throw ArgumentError.value(
      activity,
      'activity',
      'must be a frozen mutually exclusive activity',
    );
  }

  final activeCompanion = occupancy.companion;
  if (activeCompanion == null || activeCompanion.characterId != characterId) {
    return;
  }

  throw MentorInsightActivityEntryRefusedError(
    activeCompanion: activeCompanion,
    activity: activity,
    characterId: characterId,
  );
}
