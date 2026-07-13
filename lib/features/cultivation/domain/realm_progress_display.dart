import 'dart:math' as math;

enum RealmProgressDisplayState { progressing, waitingForBreakthrough, peak }

/// 由当前境界绝对层与层内经验派生的纯展示快照。
///
/// 本类不写存档、不推进境界、不提供战力加成。
final class RealmProgressDisplay {
  const RealmProgressDisplay({
    required this.level,
    required this.experience,
    required this.experienceToNext,
    required this.progress,
    required this.state,
  });

  final int level;
  final int experience;
  final int experienceToNext;
  final double progress;
  final RealmProgressDisplayState state;

  static const empty = RealmProgressDisplay(
    level: 1,
    experience: 0,
    experienceToNext: 0,
    progress: 0,
    state: RealmProgressDisplayState.progressing,
  );

  bool get didReachPeak => state == RealmProgressDisplayState.peak;

  bool get isWaitingForBreakthrough =>
      state == RealmProgressDisplayState.waitingForBreakthrough;

  factory RealmProgressDisplay.fromSnapshot({
    required int absoluteRealmLevel,
    required int experience,
    required int experienceToNext,
    required bool hasNextRealmLayer,
  }) {
    final safeAbsolute = absoluteRealmLevel.clamp(1, 49).toInt();
    final safeExperience = math.max(0, experience).toInt();
    final safeThreshold = math.max(0, experienceToNext).toInt();
    final segment = safeThreshold > 0
        ? (safeExperience * 10 ~/ safeThreshold).clamp(0, 9).toInt()
        : (hasNextRealmLayer ? 0 : 9);
    final atThreshold = safeThreshold > 0 && safeExperience >= safeThreshold;
    final state = !hasNextRealmLayer && atThreshold
        ? RealmProgressDisplayState.peak
        : hasNextRealmLayer && atThreshold
        ? RealmProgressDisplayState.waitingForBreakthrough
        : RealmProgressDisplayState.progressing;

    return RealmProgressDisplay(
      level: ((safeAbsolute - 1) * 10 + segment + 1).clamp(1, 490).toInt(),
      experience: safeExperience,
      experienceToNext: safeThreshold,
      progress: safeThreshold > 0
          ? (safeExperience / safeThreshold).clamp(0.0, 1.0).toDouble()
          : (hasNextRealmLayer ? 0.0 : 1.0),
      state: state,
    );
  }
}

final class RealmProgressChange {
  const RealmProgressChange({required this.before, required this.after});

  final RealmProgressDisplay before;
  final RealmProgressDisplay after;

  static const none = RealmProgressChange(
    before: RealmProgressDisplay.empty,
    after: RealmProgressDisplay.empty,
  );

  bool get didLevelUp => after.level > before.level;
}
