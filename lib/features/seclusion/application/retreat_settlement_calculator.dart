import 'dart:math' as math;

typedef RetreatTimeSplit = ({double retreatHours, double passiveHours});

abstract final class RetreatSettlementCalculator {
  static RetreatTimeSplit splitHours({
    required double elapsedHours,
    required double fullRateHours,
  }) {
    final safeElapsed = math.max(0.0, elapsedHours);
    final safeFullRate = math.max(0.0, fullRateHours);
    final retreatHours = math.min(safeElapsed, safeFullRate);
    return (
      retreatHours: retreatHours,
      passiveHours: safeElapsed - retreatHours,
    );
  }
}
