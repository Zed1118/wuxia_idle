/// NOT FINAL DRAFT TUNING — Phase 0B playable draft only.
///
/// Probe-local constants on purpose: `assets/probe_scenarios.yaml` checksums
/// are referenced by signed observation evidence, and production `data/*.yaml`
/// must never grow draft values. Nothing here is gate material.
final class PlayableDraftTuning {
  PlayableDraftTuning._();

  static const worldWidth = 3600.0;
  static const worldHeight = 720.0;
  static const viewWidth = 1280.0;
  static const viewHeight = 720.0;
  static const combatTop = 365.0;
  static const combatBottom = 640.0;
  static const heroTop = combatTop + 70;
  static const heroBottom = combatBottom - 70;

  // Readability pocket, matching the frozen Phase 0B camera V2 magnitude
  // (~210x152px). Enemies must never enter this radius around the hero.
  static const pocketRadius = 112.0;
  static const ringRadius = 175.0;

  static const enemyHealth = 60.0;
  static const enemyApproachSpeed = 150.0;
  static const enemyRetreatSpeed = 185.0;
  static const spawnOffscreenMargin = 160.0;
  static const spawnBatchInterval = 0.12;
  static const enterCompletionDistance = 10.0;

  static const telegraphSeconds = 0.55;
  static const strikeSeconds = 0.18;
  static const strikeRange = 72.0;
  static const strikeDamage = 7.0;
  static const retreatSeconds = 0.6;
  static const attackTokenLimit = 2;
  static const attackCooldownBase = 1.8;
  static const attackCooldownIdSpread = 0.12;
  static const slowFieldSpeedFactor = 0.6;

  static const bossMaxHealth = 800.0;
  static const bossPhaseTwoFraction = 0.5;
  static const bossPreferredRange = 235.0;
  static const bossAdvanceSpeedPhaseOne = 95.0;
  static const bossAdvanceSpeedPhaseTwo = 125.0;
  static const bossAttackCooldownPhaseOne = 3.0;
  static const bossAttackCooldownPhaseTwo = 2.1;
  static const bossSlamTelegraphSeconds = 0.9;
  static const bossSlamSeconds = 0.22;
  static const bossSlamRadius = 150.0;
  static const bossSlamDamage = 18.0;
  static const bossSweepTelegraphSeconds = 1.05;
  static const bossSweepSeconds = 0.28;
  static const bossSweepRadius = 210.0;
  static const bossSweepHalfArc = 0.9;
  static const bossSweepDamage = 14.0;
  static const bossExhaustedSeconds = 1.1;
  static const bossExhaustedDamageMultiplier = 1.5;
  static const bossPhaseShiftSeconds = 0.9;

  static const playerMaxHealth = 100.0;
  static const playerQiCapacity = 100.0;
  static const playerStartingQi = 40.0;
  static const playerHorizontalSpeed = 330.0;
  static const playerVerticalSpeed = 225.0;
  static const dashSpeed = 1050.0;
  static const dashDuration = 0.17;
  static const dashCooldown = 3.0;
  static const clearQiCost = 60.0;
  static const qiRecoverOnGroupClear = 15.0;
  static const gatherCooldown = 6.5;
}
