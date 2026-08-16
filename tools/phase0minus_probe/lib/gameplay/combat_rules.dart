import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:phase0minus_probe/config/probe_config.dart';

final class GameplayTuning {
  const GameplayTuning({
    this.playerHorizontalSpeed = 360,
    this.playerVerticalSpeed = 260,
    this.basicMoveFactor = 0.85,
    this.basicInterval = 0.30,
    this.basicRange = 150,
    this.basicHalfArcRadians = 0.655,
    this.basicDamage = 24,
    this.basicQiGain = 5,
    this.rangedRange = 420,
    this.rangedHalfArcRadians = 0.16,
    this.rangedDamage = 24,
    this.dashSpeed = 1111,
    this.dashDuration = 0.18,
    this.dashCooldown = 3.2,
    this.gatherRadius = 300,
    this.gatherTargetRadius = 100,
    this.gatherCooldown = 6.5,
    this.imbalanceDuration = 2.0,
    this.clearRadius = 340,
    this.clearDamage = 65,
    this.clearQiCost = 60,
    this.normalHealth = 100,
    this.normalSpeed = 105,
    this.eliteHealth = 260,
    this.eliteSpeed = 78,
    this.eliteChargeInterval = 5.0,
    this.eliteTelegraphDuration = 1.2,
    this.eliteBreakWindow = 0.65,
    this.eliteBreakThreshold = 2,
    this.enemyAttackRange = 55,
    this.enemyAttackInterval = 1.1,
    this.enemyDamage = 7,
    this.playerMaxHealth = 100,
  });

  factory GameplayTuning.fromConfig(ProbeConfig config) => GameplayTuning(
    playerHorizontalSpeed: config.number('gameplay.player.horizontal_speed'),
    playerVerticalSpeed: config.number('gameplay.player.vertical_speed'),
    basicMoveFactor: config.number('gameplay.basic.move_factor'),
    basicInterval: config.number('gameplay.basic.interval_seconds'),
    basicRange: config.number('gameplay.basic.range'),
    basicHalfArcRadians: config.number('gameplay.basic.half_arc_radians'),
    basicDamage: config.number('gameplay.basic.damage'),
    basicQiGain: config.number('gameplay.basic.qi_gain'),
    rangedRange: config.number('gameplay.basic.ranged_range'),
    rangedHalfArcRadians: config.number(
      'gameplay.basic.ranged_half_arc_radians',
    ),
    rangedDamage: config.number('gameplay.basic.ranged_damage'),
    dashSpeed: config.number('gameplay.movement_art.speed'),
    dashDuration: config.number('gameplay.movement_art.duration_seconds'),
    dashCooldown: config.number('gameplay.movement_art.cooldown_seconds'),
    gatherRadius: config.number('gameplay.gather.radius'),
    gatherTargetRadius: config.number('gameplay.gather.target_radius'),
    gatherCooldown: config.number('gameplay.gather.cooldown_seconds'),
    imbalanceDuration: config.number('gameplay.gather.imbalance_seconds'),
    clearRadius: config.number('gameplay.clear.radius'),
    clearDamage: config.number('gameplay.clear.damage'),
    clearQiCost: config.number('gameplay.clear.qi_cost'),
    normalHealth: config.number('gameplay.normal.health'),
    normalSpeed: config.number('gameplay.normal.speed'),
    eliteHealth: config.number('gameplay.elite.health'),
    eliteSpeed: config.number('gameplay.elite.speed'),
    eliteChargeInterval: config.number(
      'gameplay.elite.charge_interval_seconds',
    ),
    eliteTelegraphDuration: config.number(
      'gameplay.elite.telegraph_duration_seconds',
    ),
    eliteBreakWindow: config.number('gameplay.elite.break_window_seconds'),
    eliteBreakThreshold: config.integer('gameplay.elite.break_threshold'),
    enemyAttackRange: config.number('gameplay.normal.attack_range'),
    enemyAttackInterval: config.number(
      'gameplay.normal.attack_interval_seconds',
    ),
    enemyDamage: config.number('gameplay.normal.damage'),
    playerMaxHealth: config.number('gameplay.player.health'),
  );

  final double playerHorizontalSpeed;
  final double playerVerticalSpeed;
  final double basicMoveFactor;
  final double basicInterval;
  final double basicRange;
  final double basicHalfArcRadians;
  final double basicDamage;
  final double basicQiGain;
  final double rangedRange;
  final double rangedHalfArcRadians;
  final double rangedDamage;
  final double dashSpeed;
  final double dashDuration;
  final double dashCooldown;
  final double gatherRadius;
  final double gatherTargetRadius;
  final double gatherCooldown;
  final double imbalanceDuration;
  final double clearRadius;
  final double clearDamage;
  final double clearQiCost;
  final double normalHealth;
  final double normalSpeed;
  final double eliteHealth;
  final double eliteSpeed;
  final double eliteChargeInterval;
  final double eliteTelegraphDuration;
  final double eliteBreakWindow;
  final int eliteBreakThreshold;
  final double enemyAttackRange;
  final double enemyAttackInterval;
  final double enemyDamage;
  final double playerMaxHealth;
}

Vector2 normalizedMovement({
  required bool left,
  required bool right,
  required bool up,
  required bool down,
}) {
  final vector = Vector2(
    (right ? 1 : 0) - (left ? 1 : 0),
    (down ? 1 : 0) - (up ? 1 : 0),
  );
  if (vector.length2 > 1) vector.normalize();
  return vector;
}

bool isInsideAimArc({
  required Vector2 origin,
  required Vector2 aimDirection,
  required Vector2 target,
  required double range,
  required double halfArcRadians,
}) {
  final delta = target - origin;
  if (delta.length2 > range * range) return false;
  if (delta.length2 == 0) return true;
  final aim = aimDirection.length2 == 0
      ? Vector2(1, 0)
      : aimDirection.normalized();
  final direction = delta.normalized();
  final dot = aim.dot(direction).clamp(-1.0, 1.0);
  return math.acos(dot) <= halfArcRadians;
}

Vector2 gatherDestination({
  required Vector2 origin,
  required Vector2 enemy,
  required double targetRadius,
}) {
  final delta = enemy - origin;
  if (delta.length2 <= targetRadius * targetRadius) return enemy.clone();
  return origin + delta.normalized() * targetRadius;
}

bool isBreakWindow({
  required double telegraphRemaining,
  required GameplayTuning tuning,
}) => telegraphRemaining > 0 && telegraphRemaining <= tuning.eliteBreakWindow;

double normalClearDamage({
  required bool imbalanced,
  required GameplayTuning tuning,
  required double imbalancedMultiplier,
}) => tuning.clearDamage * (imbalanced ? imbalancedMultiplier : 1);

double qiAfterBasicCast({
  required double currentQi,
  required bool hitAnyTarget,
  required double capacity,
  required GameplayTuning tuning,
}) => hitAnyTarget
    ? math.min(capacity, currentQi + tuning.basicQiGain)
    : currentQi;

enum GameplayPhase { active, betweenWaves, victory, defeat, paused }

enum GameplayAction { basic, dash, gather, clear, breakSuccess }

final class GameplayCounters {
  int basicUses = 0;
  int dashUses = 0;
  int gatherUses = 0;
  int clearUses = 0;
  int breakSuccesses = 0;
  int kills = 0;
  int maximumChain = 0;
  int currentChain = 0;

  void record(GameplayAction action) {
    switch (action) {
      case GameplayAction.basic:
        basicUses++;
        break;
      case GameplayAction.dash:
        dashUses++;
        break;
      case GameplayAction.gather:
        gatherUses++;
        break;
      case GameplayAction.clear:
        clearUses++;
        break;
      case GameplayAction.breakSuccess:
        breakSuccesses++;
        break;
    }
  }

  void recordKill() {
    kills++;
    currentChain++;
    maximumChain = math.max(maximumChain, currentChain);
  }

  void breakChain() => currentChain = 0;

  Map<String, int> toJson() => {
    'basic_uses': basicUses,
    'dash_uses': dashUses,
    'gather_uses': gatherUses,
    'clear_uses': clearUses,
    'break_successes': breakSuccesses,
    'kills': kills,
    'maximum_chain': maximumChain,
  };
}

final class GameplayTelemetry {
  double elapsedSeconds = 0;
  double waveStartedAt = 0;
  int peakActiveEnemies = 0;
  int damageEvents = 0;
  int peakConcurrentNormalAttackers = 0;
  int breakOpportunities = 0;
  int replayRequests = 0;
  int collisionContactStarts = 0;
  int rangeQueryCount = 0;
  int rangeQueryCandidateChecks = 0;
  int rangeQueryHits = 0;
  final Map<int, int> damageEventsByWave = {};
  final Map<int, double> waveDurations = {};
  final List<int> gatherTargetCounts = [];
  final List<int> clearHitCounts = [];
  final List<int> clearKillCounts = [];

  void reset() {
    elapsedSeconds = 0;
    waveStartedAt = 0;
    peakActiveEnemies = 0;
    damageEvents = 0;
    peakConcurrentNormalAttackers = 0;
    breakOpportunities = 0;
    replayRequests = 0;
    collisionContactStarts = 0;
    rangeQueryCount = 0;
    rangeQueryCandidateChecks = 0;
    rangeQueryHits = 0;
    damageEventsByWave.clear();
    waveDurations.clear();
    gatherTargetCounts.clear();
    clearHitCounts.clear();
    clearKillCounts.clear();
  }

  void tick(double dt, int activeEnemies, int concurrentNormalAttackers) {
    elapsedSeconds += dt;
    peakActiveEnemies = math.max(peakActiveEnemies, activeEnemies);
    peakConcurrentNormalAttackers = math.max(
      peakConcurrentNormalAttackers,
      concurrentNormalAttackers,
    );
  }

  void recordDamage(int wave) {
    damageEvents++;
    damageEventsByWave.update(wave, (value) => value + 1, ifAbsent: () => 1);
  }

  void finishWave(int wave) {
    waveDurations[wave] = elapsedSeconds - waveStartedAt;
    waveStartedAt = elapsedSeconds;
  }

  Map<String, Object?> toJson({
    required String outcome,
    required GameplayCounters counters,
  }) => {
    'outcome': outcome,
    'elapsed_seconds': elapsedSeconds,
    'peak_active_enemies': peakActiveEnemies,
    'damage_events': damageEvents,
    'damage_events_by_wave': {
      for (final entry in damageEventsByWave.entries)
        entry.key.toString(): entry.value,
    },
    'peak_concurrent_normal_attackers': peakConcurrentNormalAttackers,
    'break_opportunities': breakOpportunities,
    'replay_requests': replayRequests,
    'collision_contact_starts': collisionContactStarts,
    'range_query_count': rangeQueryCount,
    'range_query_candidate_checks': rangeQueryCandidateChecks,
    'range_query_hits': rangeQueryHits,
    'wave_durations_seconds': {
      for (final entry in waveDurations.entries)
        entry.key.toString(): entry.value,
    },
    'gather_target_counts': gatherTargetCounts,
    'clear_hit_counts': clearHitCounts,
    'clear_kill_counts': clearKillCounts,
    'actions': counters.toJson(),
  };
}
