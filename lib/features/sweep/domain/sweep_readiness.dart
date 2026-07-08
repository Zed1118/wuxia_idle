/// Non-daily resource that gates repeated mainline sweep rewards.
///
/// This is intentionally scoped to sweep economy pacing. It is not global
/// stamina and must not affect first clears, offline idle, Taohua Island, or
/// normal combat.
class SweepReadinessConfig {
  final bool enabled;
  final int maxPoints;
  final int recoverMinutesPerPoint;
  final int mainlineStageCost;

  const SweepReadinessConfig({
    required this.enabled,
    required this.maxPoints,
    required this.recoverMinutesPerPoint,
    required this.mainlineStageCost,
  });

  static const disabled = SweepReadinessConfig(
    enabled: false,
    maxPoints: 0,
    recoverMinutesPerPoint: 60,
    mainlineStageCost: 0,
  );

  factory SweepReadinessConfig.fromYaml(Map<String, dynamic>? y) {
    if (y == null) return disabled;
    final enabled = y['enabled'] as bool? ?? true;
    final maxPoints = (y['max_points'] as num?)?.toInt() ?? 60;
    final recoverMinutes =
        (y['recover_minutes_per_point'] as num?)?.toInt() ?? 60;
    final stageCost = (y['mainline_stage_cost'] as num?)?.toInt() ?? 1;
    if (maxPoints < 0 || recoverMinutes <= 0 || stageCost < 0) {
      throw ArgumentError('sweep_readiness 数值非法: $y');
    }
    return SweepReadinessConfig(
      enabled: enabled,
      maxPoints: maxPoints,
      recoverMinutesPerPoint: recoverMinutes,
      mainlineStageCost: stageCost,
    );
  }

  int mainlineSweepCostFor(int stageCount) {
    if (!enabled) return 0;
    if (stageCount <= 0) return 0;
    return stageCount * mainlineStageCost;
  }
}

class SweepReadinessState {
  final int points;
  final DateTime lastRecoveredAt;
  final SweepReadinessConfig config;

  const SweepReadinessState({
    required this.points,
    required this.lastRecoveredAt,
    required this.config,
  });

  static SweepReadinessState normalize({
    required int? points,
    required DateTime? lastRecoveredAt,
    required DateTime now,
    required SweepReadinessConfig config,
  }) {
    if (!config.enabled) {
      return SweepReadinessState(
        points: config.maxPoints,
        lastRecoveredAt: now,
        config: config,
      );
    }
    if (points == null || lastRecoveredAt == null) {
      return SweepReadinessState(
        points: config.maxPoints,
        lastRecoveredAt: now,
        config: config,
      );
    }

    final clamped = points.clamp(0, config.maxPoints);
    if (lastRecoveredAt.isAfter(now)) {
      return SweepReadinessState(
        points: clamped,
        lastRecoveredAt: now,
        config: config,
      );
    }
    if (clamped >= config.maxPoints) {
      return SweepReadinessState(
        points: config.maxPoints,
        lastRecoveredAt: now,
        config: config,
      );
    }

    final elapsedMinutes = now.difference(lastRecoveredAt).inMinutes;
    final recovered = elapsedMinutes ~/ config.recoverMinutesPerPoint;
    if (recovered <= 0) {
      return SweepReadinessState(
        points: clamped,
        lastRecoveredAt: lastRecoveredAt,
        config: config,
      );
    }

    final nextPoints = (clamped + recovered).clamp(0, config.maxPoints);
    final nextLastRecoveredAt = nextPoints >= config.maxPoints
        ? now
        : lastRecoveredAt.add(
            Duration(minutes: recovered * config.recoverMinutesPerPoint),
          );
    return SweepReadinessState(
      points: nextPoints,
      lastRecoveredAt: nextLastRecoveredAt,
      config: config,
    );
  }

  int costForMainlineStages(int stageCount) =>
      config.mainlineSweepCostFor(stageCount);

  bool canSweepMainlineStages(int stageCount) =>
      points >= costForMainlineStages(stageCount);

  int missingForMainlineStages(int stageCount) {
    final missing = costForMainlineStages(stageCount) - points;
    return missing > 0 ? missing : 0;
  }

  DateTime? get nextRecoveryAt {
    if (!config.enabled || points >= config.maxPoints) return null;
    return lastRecoveredAt.add(
      Duration(minutes: config.recoverMinutesPerPoint),
    );
  }

  SweepReadinessState spendMainlineStages(int stageCount) {
    final cost = costForMainlineStages(stageCount);
    if (cost <= 0) return this;
    if (points < cost) return this;
    return SweepReadinessState(
      points: points - cost,
      lastRecoveredAt: lastRecoveredAt,
      config: config,
    );
  }
}
