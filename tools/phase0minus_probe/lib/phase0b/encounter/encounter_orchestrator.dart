import 'dart:math' as math;

import 'package:flame/components.dart';

import '../playable/boss_brain.dart';
import '../playable/draft_tuning.dart';
import '../playable/enemy_brain.dart';
import '../playable/style_profiles.dart';
import 'encounter_events.dart';

/// NOT FINAL — probe-local encounter orchestration for the Phase 0B draft.
///
/// Drives the existing playable sims ([DraftEnemyGroupSim], [DraftBossBrain],
/// [DraftStyleProfile]) without duplicating their rules, and emits neutral
/// [EncounterEvent]s from before/after state diffs. Deterministic for a fixed
/// seed + dt + command list. No file writes, no persistence, no feedback-layer
/// dependency.

enum EncounterCommandKind { moveBy, castGather, castClear, setStyle }

final class EncounterCommand {
  const EncounterCommand({
    required this.at,
    required this.kind,
    this.dx = 0,
    this.style,
  });

  final double at;
  final EncounterCommandKind kind;
  final double dx;
  final DraftStyleKind? style;
}

final class EncounterGroupSetup {
  const EncounterGroupSetup({
    required this.id,
    required this.count,
    required this.seed,
    required this.cameraLeft,
    this.activateAt = 0,
  });

  final int id;
  final int count;
  final int seed;
  final double cameraLeft;
  final double activateAt;
}

final class EncounterResult {
  const EncounterResult({required this.time, required this.events});

  final double time;
  final List<EncounterEvent> events;
}

final class EncounterOrchestrator {
  EncounterOrchestrator({
    required int seed,
    required DraftStyleKind style,
    Vector2? heroStart,
    List<EncounterGroupSetup> groups = const [],
    Vector2? bossSpawn,
    List<EncounterCommand> commands = const [],
  }) : _commands = [...commands]..sort((a, b) => a.at.compareTo(b.at)) {
    _style = DraftStyleProfile.of(style);
    _heroPosition = heroStart?.clone() ?? Vector2(1600, 500);
    for (final setup in groups) {
      _groups.add(
        _OrchestratedGroup(
          setup: setup,
          sim: DraftEnemyGroupSim(count: setup.count, seed: setup.seed),
        ),
      );
    }
    final spawn = bossSpawn;
    if (spawn != null) {
      final boss = DraftBossBrain(spawn: spawn);
      _boss = boss;
      _bossPrevState = boss.state;
    }
    _emit(EncounterStarted(time: _clock, seed: seed, style: style));
  }

  static final Vector2 _aimEast = Vector2(1, 0);

  final List<EncounterCommand> _commands;
  final List<_OrchestratedGroup> _groups = [];
  final List<EncounterEvent> _log = [];
  final Map<int, double> _injuryRemaining = {};

  DraftBossBrain? _boss;
  DraftBossState? _bossPrevState;
  late DraftStyleProfile _style;
  late Vector2 _heroPosition;

  double _clock = 0;
  int _commandIndex = 0;
  double _basicTimer = 0;
  double _gatherCooldown = 0;
  double _heroHealth = PlayableDraftTuning.playerMaxHealth;
  double _heroQi = PlayableDraftTuning.playerStartingQi;
  bool _battleConcluded = false;

  double get time => _clock;
  bool get battleConcluded => _battleConcluded;
  List<EncounterEvent> get events => List.unmodifiable(_log);
  Vector2 get heroPosition => _heroPosition.clone();
  double get heroHealth => _heroHealth;
  double get heroQi => _heroQi;
  DraftStyleKind get style => _style.kind;

  void advance(double dt) {
    if (_battleConcluded || dt <= 0) return;
    _consumeCommands();
    _clock += dt;
    _gatherCooldown = math.max(0, _gatherCooldown - dt);
    _advanceGroups(dt);
    _advanceBoss(dt);
    _heroAutoBasic(dt);
    _applyInjuryTicks(dt);
    _checkGroupCleared();
    _maybeConclude();
  }

  EncounterResult runSeconds(double seconds, {double dt = 1.0 / 60.0}) {
    final steps = (seconds / dt).round();
    for (var step = 0; step < steps; step++) {
      advance(dt);
      if (_battleConcluded) break;
    }
    return EncounterResult(time: _clock, events: events);
  }

  void _emit(EncounterEvent event) => _log.add(event);

  void _consumeCommands() {
    while (_commandIndex < _commands.length &&
        _commands[_commandIndex].at <= _clock) {
      _applyCommand(_commands[_commandIndex]);
      _commandIndex++;
    }
  }

  void _applyCommand(EncounterCommand command) {
    switch (command.kind) {
      case EncounterCommandKind.moveBy:
        _heroPosition
          ..x = (_heroPosition.x + command.dx).clamp(
            24,
            PlayableDraftTuning.worldWidth - 24,
          )
          ..y = _heroPosition.y.clamp(
            PlayableDraftTuning.heroTop,
            PlayableDraftTuning.heroBottom,
          );
      case EncounterCommandKind.castGather:
        _castGather();
      case EncounterCommandKind.castClear:
        _castClear();
      case EncounterCommandKind.setStyle:
        final kind = command.style;
        if (kind != null && kind != _style.kind) {
          _style = DraftStyleProfile.of(kind);
          _emit(HeroStyleChanged(time: _clock, style: kind));
        }
    }
  }

  void _castGather() {
    if (_gatherCooldown > 0) return;
    final profile = _style;
    switch (profile.gatherKind) {
      case DraftGatherKind.pull:
        for (final group in _groups) {
          group.sim.applyPull(
            center: _heroPosition,
            radius: profile.gatherRadius,
            targetRadius: profile.gatherTargetRadius,
            maxDistance: profile.gatherRadius,
          );
        }
      case DraftGatherKind.slowFog:
        for (final group in _groups) {
          group.sim.applySlowField(
            center: _heroPosition,
            radius: profile.gatherRadius,
            duration: profile.slowFieldDuration,
          );
        }
    }
    _gatherCooldown = PlayableDraftTuning.gatherCooldown;
  }

  void _castClear() {
    if (_heroQi < PlayableDraftTuning.clearQiCost) return;
    _heroQi -= PlayableDraftTuning.clearQiCost;
    _emit(
      HeroResourceChanged(
        time: _clock,
        delta: -PlayableDraftTuning.clearQiCost,
        value: _heroQi,
      ),
    );
    final profile = _style;
    for (final group in _groups) {
      for (final enemy in group.sim.enemies) {
        if (!enemy.alive) continue;
        if (!draftInsideClearZone(
          profile: profile,
          origin: _heroPosition,
          aim: _aimEast,
          point: enemy.position,
        )) {
          continue;
        }
        _damageEnemy(group, enemy, profile.clearDamage);
      }
    }
    _damageBossIfInClearZone(profile);
  }

  void _damageBossIfInClearZone(DraftStyleProfile profile) {
    final boss = _boss;
    if (boss == null || boss.defeated) return;
    if (!draftInsideClearZone(
      profile: profile,
      origin: _heroPosition,
      aim: _aimEast,
      point: boss.position,
    )) {
      return;
    }
    _applyBossDamage(boss, profile.clearDamage);
  }

  void _heroAutoBasic(double dt) {
    final profile = _style;
    _basicTimer += dt;
    while (_basicTimer >= profile.basicInterval) {
      _basicTimer -= profile.basicInterval;
      _fireBasic(profile);
    }
  }

  void _fireBasic(DraftStyleProfile profile) {
    final hits = <(int, DraftEnemy)>[];
    for (final group in _groups) {
      for (final enemy in group.sim.enemies) {
        if (!enemy.alive) continue;
        if (enemy.position.distanceTo(_heroPosition) > profile.basicRange) {
          continue;
        }
        if (!draftInsideBasicArc(
          profile: profile,
          origin: _heroPosition,
          aim: _aimEast,
          target: enemy.position,
        )) {
          continue;
        }
        hits.add((group.setup.id, enemy));
      }
    }
    final boss = _boss;
    var bossHit = false;
    if (boss != null &&
        !boss.defeated &&
        draftInsideBasicArc(
          profile: profile,
          origin: _heroPosition,
          aim: _aimEast,
          target: boss.position,
        )) {
      _applyBossDamage(boss, profile.basicDamage);
      bossHit = true;
    }
    if (hits.isEmpty && !bossHit) return;
    for (final (groupId, enemy) in hits) {
      final group = _groupById(groupId);
      if (profile.appliesInternalInjury) {
        _injuryRemaining[enemy.id] = profile.internalInjuryDuration;
      }
      _damageEnemy(group, enemy, profile.basicDamage);
    }
    _heroQi = math.min(
      PlayableDraftTuning.playerQiCapacity,
      _heroQi + profile.basicQiGain,
    );
    _emit(
      HeroResourceChanged(
        time: _clock,
        delta: profile.basicQiGain,
        value: _heroQi,
      ),
    );
  }

  _OrchestratedGroup _groupById(int groupId) =>
      _groups.firstWhere((group) => group.setup.id == groupId);

  void _damageEnemy(_OrchestratedGroup group, DraftEnemy enemy, double damage) {
    final defeated = group.sim.applyHit(enemy.id, damage);
    _emit(
      EnemyDamaged(
        time: _clock,
        groupId: group.setup.id,
        enemyId: enemy.id,
        damage: damage,
        defeated: defeated,
      ),
    );
  }

  void _applyInjuryTicks(double dt) {
    if (!_style.appliesInternalInjury) return;
    final dps = _style.internalInjuryDps;
    for (final group in _groups) {
      for (final enemy in group.sim.enemies) {
        final remaining = _injuryRemaining[enemy.id];
        if (remaining == null || remaining <= 0 || !enemy.alive) continue;
        final tickDamage = draftInternalInjuryTick(
          dps: dps,
          remaining: remaining,
          dt: dt,
        );
        _injuryRemaining[enemy.id] = math.max(0, remaining - dt);
        if (tickDamage <= 0) continue;
        _damageEnemy(group, enemy, tickDamage);
      }
    }
  }

  void _advanceGroups(double dt) {
    for (final group in _groups) {
      final setup = group.setup;
      if (!group.sim.activated && _clock >= setup.activateAt) {
        group.sim.activate(cameraLeft: setup.cameraLeft);
      }
      if (!group.sim.activated) continue;
      final strikes = group.sim.advance(dt, _heroPosition);
      _diffGroupStates(group, strikes);
      for (final strike in strikes) {
        _damageHero(strike.damage);
      }
    }
  }

  void _diffGroupStates(
    _OrchestratedGroup group,
    List<DraftEnemyStrikeEvent> strikes,
  ) {
    for (final enemy in group.sim.enemies) {
      final previous =
          group.previousStates[enemy.id] ?? DraftEnemyState.waiting;
      final current = enemy.state;
      if (previous == current) continue;
      group.previousStates[enemy.id] = current;
      if (previous == DraftEnemyState.waiting) {
        _emit(
          EnemyEntered(
            time: _clock,
            groupId: group.setup.id,
            enemyId: enemy.id,
          ),
        );
      }
      switch (current) {
        case DraftEnemyState.telegraphing:
          _emit(
            EnemyTelegraphStarted(
              time: _clock,
              groupId: group.setup.id,
              enemyId: enemy.id,
            ),
          );
        case DraftEnemyState.striking:
          DraftEnemyStrikeEvent? landed;
          for (final strike in strikes) {
            if (strike.enemyId == enemy.id) {
              landed = strike;
              break;
            }
          }
          _emit(
            EnemyStrikeResolved(
              time: _clock,
              groupId: group.setup.id,
              enemyId: enemy.id,
              hitHero: landed != null,
              damage: landed?.damage ?? 0,
            ),
          );
        case DraftEnemyState.retreating:
          _emit(
            EnemyRetreated(
              time: _clock,
              groupId: group.setup.id,
              enemyId: enemy.id,
            ),
          );
        case DraftEnemyState.waiting:
        case DraftEnemyState.entering:
        case DraftEnemyState.ringing:
        case DraftEnemyState.defeated:
          break;
      }
    }
  }

  void _advanceBoss(double dt) {
    final boss = _boss;
    if (boss == null || boss.defeated) return;
    final events = boss.advance(dt, _heroPosition);
    _diffBossState(boss);
    for (final event in events) {
      switch (event.kind) {
        case DraftBossEventKind.slamResolved:
        case DraftBossEventKind.sweepResolved:
          final kind = event.kind == DraftBossEventKind.slamResolved
              ? EncounterBossStrikeKind.slam
              : EncounterBossStrikeKind.sweep;
          _emit(
            BossStrikeResolved(
              time: _clock,
              kind: kind,
              hitHero: event.hitPlayer,
              damage: event.damage,
            ),
          );
          if (event.hitPlayer) _damageHero(event.damage);
        case DraftBossEventKind.phaseChanged:
          _emit(BossPhaseChanged(time: _clock, phase: 2, total: 2));
      }
    }
  }

  void _diffBossState(DraftBossBrain boss) {
    final previous = _bossPrevState;
    final current = boss.state;
    if (previous == current) return;
    _bossPrevState = current;
    switch (current) {
      case DraftBossState.telegraphSlam:
      case DraftBossState.telegraphSweep:
        final zone = boss.activeZone;
        if (zone != null) {
          _emit(
            BossTelegraphStarted(
              time: _clock,
              shape: zone.shape == DraftBossDangerShape.circle
                  ? EncounterDangerShape.circle
                  : EncounterDangerShape.arc,
              center: zone.center.clone(),
              radius: zone.radius,
              halfArcRadians: zone.halfArcRadians,
              direction: zone.direction?.clone(),
            ),
          );
        }
      case DraftBossState.exhausted:
        _emit(BossExhaustedStarted(time: _clock));
      case DraftBossState.advancing:
      case DraftBossState.phaseShift:
      case DraftBossState.slamming:
      case DraftBossState.sweeping:
      case DraftBossState.defeated:
        break;
    }
  }

  void _applyBossDamage(DraftBossBrain boss, double rawDamage) {
    final effective = rawDamage * boss.incomingDamageMultiplier;
    final wasDefeated = boss.defeated;
    boss.takeDamage(rawDamage);
    if (wasDefeated) return;
    _emit(
      BossDamaged(time: _clock, damage: effective, defeated: boss.defeated),
    );
    _diffBossState(boss);
    if (boss.defeated) {
      _emit(BossDefeated(time: _clock));
      _emit(LootRequested(time: _clock, sourceId: 'boss_draft_v1'));
    }
  }

  void _damageHero(double amount) {
    _heroHealth = math.max(0, _heroHealth - amount);
    _emit(HeroDamaged(time: _clock, amount: amount, healthAfter: _heroHealth));
  }

  void _checkGroupCleared() {
    for (final group in _groups) {
      if (group.cleared || !group.sim.activated || group.sim.aliveCount > 0) {
        continue;
      }
      group.cleared = true;
      _emit(GroupCleared(time: _clock, groupId: group.setup.id));
      _heroQi = math.min(
        PlayableDraftTuning.playerQiCapacity,
        _heroQi + PlayableDraftTuning.qiRecoverOnGroupClear,
      );
      _emit(
        HeroResourceChanged(
          time: _clock,
          delta: PlayableDraftTuning.qiRecoverOnGroupClear,
          value: _heroQi,
        ),
      );
    }
  }

  void _maybeConclude() {
    if (_battleConcluded) return;
    if (_heroHealth <= 0) {
      _battleConcluded = true;
      _emit(BattleConcluded(time: _clock, outcome: EncounterOutcome.defeat));
      return;
    }
    final boss = _boss;
    final groupsDone = _groups.every((group) => group.cleared);
    if (groupsDone && (boss == null || boss.defeated)) {
      _battleConcluded = true;
      _emit(BattleConcluded(time: _clock, outcome: EncounterOutcome.victory));
    }
  }
}

final class _OrchestratedGroup {
  _OrchestratedGroup({required this.setup, required this.sim});

  final EncounterGroupSetup setup;
  final DraftEnemyGroupSim sim;
  final Map<int, DraftEnemyState> previousStates = {};
  bool cleared = false;
}
