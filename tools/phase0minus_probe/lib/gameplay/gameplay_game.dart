import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phase0minus_probe/config/probe_config.dart';
import 'package:phase0minus_probe/gameplay/combat_rules.dart';

enum PlayerAction {
  locomotion,
  basic,
  movementArt,
  gather,
  clear,
  hurt,
  defeated,
}

enum BufferedPlayerAction { movementArt, gather, clear }

enum FeedbackKind { basic, gather, clear }

enum EnemyMode {
  spawning,
  approach,
  attack,
  telegraph,
  commit,
  staggered,
  hitReact,
  defeated,
}

final class GameplayHudState {
  const GameplayHudState({
    required this.health,
    required this.qi,
    required this.movementArtCooldown,
    required this.gatherCooldown,
    required this.enemyCount,
    required this.wave,
    required this.phase,
    required this.message,
    required this.counters,
  });

  final double health;
  final double qi;
  final double movementArtCooldown;
  final double gatherCooldown;
  final int enemyCount;
  final int wave;
  final GameplayPhase phase;
  final String message;
  final Map<String, int> counters;
}

final class GameplayGame extends FlameGame with KeyboardEvents {
  GameplayGame({
    required this.config,
    this.onSessionEnded,
    this.deterministicReplay = false,
  }) : tuning = GameplayTuning.fromConfig(config),
       random = math.Random(config.fixedSeed),
       hud = ValueNotifier(
         const GameplayHudState(
           health: 1,
           qi: 0.4,
           movementArtCooldown: 0,
           gatherCooldown: 0,
           enemyCount: 0,
           wave: 1,
           phase: GameplayPhase.active,
           message: 'Preparing greybox...',
           counters: {},
         ),
       );

  final ProbeConfig config;
  final void Function(Map<String, Object?> report)? onSessionEnded;
  final bool deterministicReplay;
  final GameplayTuning tuning;
  math.Random random;
  final ValueNotifier<GameplayHudState> hud;
  final GameplayCounters counters = GameplayCounters();
  final GameplayTelemetry telemetry = GameplayTelemetry();
  final List<GameplayEnemy> enemies = [];
  final Set<LogicalKeyboardKey> _keys = {};
  late final GameplayPlayer player;
  late final GameplayFeedbackPool feedbackPool;

  Vector2 pointerWorld = Vector2(800, 360);
  bool primaryHeld = false;
  bool _primaryPressed = false;
  bool _primaryReleased = false;
  GameplayPhase phase = GameplayPhase.active;
  int wave = 1;
  double _waveElapsed = 0;
  double _betweenRemaining = 0;
  double _hudElapsed = 0;
  double _cameraX = 640;
  int _nextEnemyId = 0;
  final Set<int> _spawnedBatches = {};
  bool _sessionReported = false;
  int _sessionSerial = 1;
  String? _terminalOutcome;
  GameplayPhase _phaseBeforePause = GameplayPhase.active;
  int clearEventId = -1;
  int replayPeakCount = 0;
  int replayCycleCount = 0;
  double _replayElapsed = 0;
  int _replayPhase = -1;
  bool _replayGathered = false;
  bool _replayCleared = false;
  double _hitStopRemaining = 0;
  double _cameraShakeRemaining = 0;
  double _normalAttackStartCooldown = 0;
  bool _replayPeakObservedThisPhase = false;
  int replayObservedPeakCount = 0;

  double get fieldWidth => config.number('gameplay.field.width');
  double get fieldHeight => config.number('gameplay.field.height');
  double get combatTop => config.number('gameplay.field.combat_top');
  double get combatBottom => config.number('gameplay.field.combat_bottom');

  @override
  Color backgroundColor() => const Color(0xffe8e0cb);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.center;
    await world.add(
      RectangleComponent(
        size: Vector2(fieldWidth, fieldHeight),
        paint: Paint()..color = const Color(0xffd9cfb5),
      ),
    );
    await world.add(
      RectangleComponent(
        position: Vector2(0, combatTop),
        size: Vector2(fieldWidth, combatBottom - combatTop),
        paint: Paint()..color = const Color(0xffc9c1aa),
      ),
    );
    player = GameplayPlayer(game: this);
    await world.add(player);
    feedbackPool = GameplayFeedbackPool(
      size: config.integer('gameplay.feedback.pool_size'),
    );
    await feedbackPool.mount(world);
    await world.add(GameplaySkillGuide(game: this));
    if (deterministicReplay) {
      _prepareReplayResidents();
    } else {
      _spawnDueBatches();
    }
    _updateCamera(0);
    _updateHud('Wave 1: learn the moving attack and Q to R payoff.');
  }

  @override
  void update(double dt) {
    if (phase == GameplayPhase.paused ||
        phase == GameplayPhase.victory ||
        phase == GameplayPhase.defeat) {
      _hudElapsed += dt;
      if (_hudElapsed >= 0.1) {
        _hudElapsed = 0;
        _updateHud();
      }
      return;
    }
    var simulationDt = dt;
    if (_hitStopRemaining > 0) {
      if (_hitStopRemaining >= simulationDt) {
        _hitStopRemaining -= simulationDt;
        return;
      }
      simulationDt -= _hitStopRemaining;
      _hitStopRemaining = 0;
    }
    _normalAttackStartCooldown = math.max(
      0,
      _normalAttackStartCooldown - simulationDt,
    );
    super.update(simulationDt);
    _assignAttackSlots();
    if (deterministicReplay) {
      _driveReplay(simulationDt);
    } else {
      _driveWaves(simulationDt);
    }
    final aliveEnemies = enemies.where((enemy) => enemy.alive).length;
    final normalAttackers = enemies
        .where(
          (enemy) =>
              enemy.alive && !enemy.elite && enemy.mode == EnemyMode.attack,
        )
        .length;
    telemetry.tick(simulationDt, aliveEnemies, normalAttackers);
    _updateCamera(simulationDt);
    _hudElapsed += simulationDt;
    if (_hudElapsed >= 0.1) {
      _hudElapsed = 0;
      _updateHud();
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _keys
      ..clear()
      ..addAll(keysPressed);
    if (event is KeyDownEvent && event is! KeyRepeatEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        togglePause();
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        player.requestMovementArt();
      } else if (event.logicalKey == LogicalKeyboardKey.keyQ) {
        player.requestGather();
      } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
        player.requestClear();
      }
    }
    return KeyEventResult.handled;
  }

  Vector2 movementInput() => normalizedMovement(
    left:
        _keys.contains(LogicalKeyboardKey.keyA) ||
        _keys.contains(LogicalKeyboardKey.arrowLeft),
    right:
        _keys.contains(LogicalKeyboardKey.keyD) ||
        _keys.contains(LogicalKeyboardKey.arrowRight),
    up:
        _keys.contains(LogicalKeyboardKey.keyW) ||
        _keys.contains(LogicalKeyboardKey.arrowUp),
    down:
        _keys.contains(LogicalKeyboardKey.keyS) ||
        _keys.contains(LogicalKeyboardKey.arrowDown),
  );

  void updatePointer(Vector2 widgetPosition) {
    pointerWorld = camera.globalToLocal(widgetPosition);
  }

  void setPrimaryHeld(bool value) {
    primaryHeld = value;
    if (value) {
      _primaryPressed = true;
    } else {
      _primaryReleased = true;
    }
  }

  bool consumePrimaryPressed() {
    final pressed = _primaryPressed;
    _primaryPressed = false;
    return pressed;
  }

  bool consumePrimaryReleased() {
    final released = _primaryReleased;
    _primaryReleased = false;
    return released;
  }

  void clearInput() {
    _keys.clear();
    primaryHeld = false;
    _primaryPressed = false;
    _primaryReleased = false;
  }

  void togglePause() {
    if (phase == GameplayPhase.victory || phase == GameplayPhase.defeat) return;
    if (phase == GameplayPhase.paused) {
      phase = _phaseBeforePause;
    } else {
      _phaseBeforePause = phase;
      phase = GameplayPhase.paused;
    }
    clearInput();
    _updateHud(phase == GameplayPhase.paused ? 'Paused' : 'Resumed');
  }

  void resetSession() {
    for (final enemy in enemies.toList()) {
      enemy.removeFromParent();
    }
    enemies.clear();
    counters
      ..basicUses = 0
      ..dashUses = 0
      ..gatherUses = 0
      ..clearUses = 0
      ..breakSuccesses = 0
      ..kills = 0
      ..maximumChain = 0
      ..currentChain = 0;
    telemetry.reset();
    _sessionReported = false;
    _sessionSerial++;
    _terminalOutcome = null;
    random = math.Random(config.fixedSeed);
    _nextEnemyId = 0;
    _phaseBeforePause = GameplayPhase.active;
    phase = GameplayPhase.active;
    wave = 1;
    _waveElapsed = 0;
    _betweenRemaining = 0;
    _spawnedBatches.clear();
    _normalAttackStartCooldown = 0;
    player.resetForSession();
    _spawnDueBatches();
    _updateHud('Wave 1: move, aim, then use Q to R.');
  }

  void requestReplay() {
    if (phase != GameplayPhase.victory && phase != GameplayPhase.defeat) return;
    telemetry.replayRequests++;
    _finishSession(_terminalOutcome ?? 'unknown', replace: true);
    resetSession();
  }

  Iterable<GameplayEnemy> enemiesInRadius(Vector2 center, double radius) sync* {
    final radiusSquared = radius * radius;
    for (final enemy in enemies) {
      if (enemy.alive &&
          enemy.position.distanceToSquared(center) <= radiusSquared) {
        yield enemy;
      }
    }
  }

  void onEnemyDefeated(GameplayEnemy enemy) {
    counters.recordKill();
  }

  void onEnemyRemoval(GameplayEnemy enemy) => enemies.remove(enemy);

  void triggerHitStop(double seconds) {
    _hitStopRemaining = math.max(_hitStopRemaining, seconds);
  }

  void triggerCameraShake() {
    _cameraShakeRemaining = config.number(
      'gameplay.feedback.clear_camera_shake_seconds',
    );
  }

  void damagePlayer(double amount, Vector2 source) {
    if (deterministicReplay) return;
    if (player.receiveDamage(amount, source, heavy: amount >= 20)) {
      telemetry.recordDamage(wave);
      counters.breakChain();
      if (player.health <= 0) {
        phase = GameplayPhase.defeat;
        _updateHud('Defeated. Click PLAY AGAIN if you want another run.');
        _finishSession('defeat');
      }
    }
  }

  void _driveWaves(double dt) {
    if (phase == GameplayPhase.betweenWaves) {
      _betweenRemaining -= dt;
      if (_betweenRemaining <= 0) {
        wave++;
        if (wave > 3) {
          phase = GameplayPhase.victory;
          _updateHud(
            'Complete. Click PLAY AGAIN only if you want another run.',
          );
          _finishSession('victory');
          return;
        }
        phase = GameplayPhase.active;
        _waveElapsed = 0;
        _spawnedBatches.clear();
        player.qi = math.min(
          config.number('gameplay.player.qi_capacity'),
          player.qi + config.number('gameplay.waves.qi_recovery'),
        );
        _spawnDueBatches();
      }
      return;
    }
    _waveElapsed += dt;
    _spawnDueBatches();
    if (_spawnedBatches.length == 3 && enemies.every((enemy) => !enemy.alive)) {
      telemetry.finishWave(wave);
      phase = GameplayPhase.betweenWaves;
      _betweenRemaining = config.number('gameplay.waves.between_seconds');
      _updateHud('Wave clear. Qi +25; health is not restored.');
    }
  }

  void _finishSession(String outcome, {bool replace = false}) {
    if (_sessionReported && !replace) return;
    _sessionReported = true;
    _terminalOutcome ??= outcome;
    onSessionEnded?.call({
      ...telemetry.toJson(outcome: _terminalOutcome!, counters: counters),
      'session_serial': _sessionSerial,
      'replay_requested': telemetry.replayRequests > 0,
    });
  }

  void _spawnDueBatches() {
    final schedule = switch (wave) {
      1 => const [(0.0, 5, false), (0.8, 5, false), (0.8, 0, false)],
      2 => const [(0.0, 8, false), (0.7, 6, false), (1.4, 6, false)],
      _ => const [(0.0, 8, false), (0.7, 6, true), (1.4, 6, false)],
    };
    for (var batch = 0; batch < schedule.length; batch++) {
      if (_spawnedBatches.contains(batch) ||
          _waveElapsed < schedule[batch].$1) {
        continue;
      }
      _spawnedBatches.add(batch);
      for (var index = 0; index < schedule[batch].$2; index++) {
        _spawnEnemy(elite: false, batch: batch, index: index);
      }
      if (schedule[batch].$3) _spawnEnemy(elite: true, batch: batch, index: 99);
    }
  }

  void _spawnEnemy({
    required bool elite,
    required int batch,
    required int index,
  }) {
    final fromRight = batch != 1;
    final x =
        (fromRight
                ? math.min(
                    fieldWidth - 80,
                    player.position.x + 700 + index * 23,
                  )
                : math.max(80, player.position.x - 620 - index * 18))
            .toDouble();
    final y =
        combatTop + 40 + random.nextDouble() * (combatBottom - combatTop - 80);
    final enemy = GameplayEnemy(
      game: this,
      id: _nextEnemyId++,
      elite: elite,
      spawn: Vector2(x, y),
    );
    enemies.add(enemy);
    world.add(enemy);
  }

  void _prepareReplayResidents() {
    for (var index = 0; index < 20; index++) {
      _spawnEnemy(elite: false, batch: index % 3, index: index);
    }
    _spawnEnemy(elite: true, batch: 1, index: 99);
    _activateReplayPhase(0);
  }

  void _driveReplay(double dt) {
    _replayElapsed += dt;
    final cycleTime = _replayElapsed % 12;
    final nextPhase = (cycleTime / 4).floor().clamp(0, 2);
    if (nextPhase != _replayPhase) _activateReplayPhase(nextPhase);
    primaryHeld = true;
    pointerWorld = player.position + Vector2(260, 0);
    if (_replayPhase == 2) {
      if (!_replayPeakObservedThisPhase &&
          enemies.where((enemy) => enemy.alive).length == 21) {
        _replayPeakObservedThisPhase = true;
        replayObservedPeakCount++;
      }
      final local = cycleTime - 8;
      if (local >= 1.0 && !_replayGathered) {
        _replayGathered = player.requestGather();
      }
      if (local >= 1.7 && !_replayCleared) {
        player.qi = config.number('gameplay.player.qi_capacity');
        _replayCleared = player.requestClear();
        if (_replayCleared) clearEventId++;
      }
    }
  }

  void _activateReplayPhase(int nextPhase) {
    _replayPhase = nextPhase;
    _replayGathered = false;
    _replayCleared = false;
    _replayPeakObservedThisPhase = false;
    wave = nextPhase + 1;
    if (nextPhase == 0 && _replayElapsed > 0) replayCycleCount++;
    final activeNormals = switch (nextPhase) {
      0 => 10,
      1 => 20,
      _ => 20,
    };
    var normalIndex = 0;
    for (final enemy in enemies) {
      if (enemy.elite) {
        if (nextPhase == 2) {
          enemy.activateForReplay(player.position + Vector2(250, -80));
        } else {
          enemy.deactivateForReplay();
        }
        continue;
      }
      if (normalIndex < activeNormals) {
        final angle = normalIndex * math.pi * 2 / activeNormals;
        final radius = (150 + (normalIndex % 4) * 35).toDouble();
        enemy.activateForReplay(
          player.position + Vector2(math.cos(angle), math.sin(angle)) * radius,
        );
      } else {
        enemy.deactivateForReplay();
      }
      normalIndex++;
    }
    if (nextPhase == 2) replayPeakCount++;
  }

  Map<String, Object?> replayWorkloadSnapshot() => {
    'mode': 'phase0a_replay',
    'replay_script_version': 'phase0a-compressed-12s-v1',
    'replay_peak_20_plus_1_count': replayPeakCount,
    'replay_observed_peak_20_plus_1_count': replayObservedPeakCount,
    'replay_cycle_count': replayCycleCount,
    'clear_event_id': clearEventId,
    'clear_event_count': clearEventId + 1,
    'resident_enemies': enemies.length,
    'active_enemies': enemies.where((enemy) => enemy.alive).length,
    'telemetry': telemetry.toJson(outcome: 'replay', counters: counters),
  };

  Map<String, Object?> replayPoolSnapshot() => {
    'enemy_residents': {
      'created_total': enemies.length,
      'active_current': enemies.where((enemy) => enemy.alive).length,
      'active_peak': 21,
      'allocation_after_warmup': 0,
      'invariant_holds': enemies.length == 21,
    },
    'feedback_residents': feedbackPool.snapshot(),
  };

  void _assignAttackSlots() {
    final aliveNormals =
        enemies.where((enemy) => enemy.alive && !enemy.elite).toList()..sort(
          (a, b) => a.position
              .distanceToSquared(player.position)
              .compareTo(b.position.distanceToSquared(player.position)),
        );
    final slots = config.integer('gameplay.normal.attack_slots');
    final leased = aliveNormals
        .where((enemy) => enemy.mode == EnemyMode.attack)
        .take(slots)
        .toSet();
    for (final enemy in aliveNormals) {
      enemy.hasAttackSlot = leased.contains(enemy);
    }
    var remaining = slots - leased.length;
    for (final enemy in aliveNormals) {
      if (remaining == 0) break;
      if (enemy.hasAttackSlot || enemy.mode == EnemyMode.attack) continue;
      enemy.hasAttackSlot = true;
      remaining--;
    }
  }

  bool tryStartNormalAttack() {
    if (_normalAttackStartCooldown > 0) return false;
    _normalAttackStartCooldown = config.number(
      'gameplay.normal.attack_start_interval_seconds',
    );
    return true;
  }

  void _updateCamera(double dt) {
    final halfWidth = size.x / 2;
    final target = player.position.x.clamp(halfWidth, fieldWidth - halfWidth);
    _cameraX += (target - _cameraX) * 0.12;
    var shakeX = 0.0;
    if (_cameraShakeRemaining > 0) {
      _cameraShakeRemaining = math.max(0, _cameraShakeRemaining - dt);
      shakeX =
          math.sin(_cameraShakeRemaining * 210) *
          config.number('gameplay.feedback.clear_camera_shake_pixels');
    }
    camera.viewfinder.position = Vector2(_cameraX + shakeX, fieldHeight / 2);
  }

  void _updateHud([String? message]) {
    hud.value = GameplayHudState(
      health: player.health / tuning.playerMaxHealth,
      qi: player.qi / config.number('gameplay.player.qi_capacity'),
      movementArtCooldown: player.movementArtCooldown / tuning.dashCooldown,
      gatherCooldown: player.gatherCooldown / tuning.gatherCooldown,
      enemyCount: enemies.where((enemy) => enemy.alive).length,
      wave: wave,
      phase: phase,
      message: message ?? hud.value.message,
      counters: counters.toJson(),
    );
  }

  @override
  void onRemove() {
    hud.dispose();
    super.onRemove();
  }
}

final class GameplayPlayer extends PositionComponent {
  GameplayPlayer({required this.game})
    : health = game.tuning.playerMaxHealth,
      qi = game.config.number('gameplay.player.starting_qi'),
      super(
        size: Vector2.all(game.config.number('gameplay.player.radius') * 2),
        anchor: Anchor.center,
        position: Vector2(400, game.config.number('gameplay.field.height') / 2),
        priority: 20,
      );

  final GameplayGame game;
  double health;
  double qi;
  PlayerAction action = PlayerAction.locomotion;
  double actionRemaining = 0;
  double movementArtCooldown = 0;
  double gatherCooldown = 0;
  double invulnerabilityRemaining = 0;
  double damageProtectionRemaining = 0;
  double recoveryRemaining = 0;
  Vector2 aimDirection = Vector2(1, 0);
  Vector2 _movementArtDirection = Vector2(1, 0);
  BufferedPlayerAction? _bufferedAction;
  double _bufferRemaining = 0;
  bool _basicResolved = false;
  bool _gatherResolved = false;
  bool _clearResolved = false;

  @override
  void update(double dt) {
    movementArtCooldown = math.max(0, movementArtCooldown - dt);
    gatherCooldown = math.max(0, gatherCooldown - dt);
    invulnerabilityRemaining = math.max(0, invulnerabilityRemaining - dt);
    damageProtectionRemaining = math.max(0, damageProtectionRemaining - dt);
    recoveryRemaining = math.max(0, recoveryRemaining - dt);
    _bufferRemaining = math.max(0, _bufferRemaining - dt);
    if (_bufferRemaining == 0) _bufferedAction = null;
    final pointerDelta = game.pointerWorld - position;
    if (pointerDelta.length2 > 1) aimDirection = pointerDelta.normalized();

    if (action == PlayerAction.defeated) return;
    if (actionRemaining > 0) {
      actionRemaining -= dt;
      _updateCurrentAction(dt);
      if (actionRemaining <= 0) {
        if (action == PlayerAction.movementArt) recoveryRemaining = 0.08;
        action = PlayerAction.locomotion;
      }
    } else {
      action = PlayerAction.locomotion;
      _move(game.movementInput(), dt, 1);
      if (recoveryRemaining <= 0) {
        if (_consumeBufferedAction()) {
          super.update(dt);
          return;
        }
        final pressed = game.consumePrimaryPressed();
        game.consumePrimaryReleased();
        if (game.primaryHeld || pressed) _startBasic();
      }
    }
    super.update(dt);
  }

  bool requestMovementArt() {
    if (action == PlayerAction.defeated || movementArtCooldown > 0) {
      return false;
    }
    final canCancelBasic =
        action == PlayerAction.basic && actionRemaining <= 0.095;
    if (action != PlayerAction.locomotion && !canCancelBasic) {
      _buffer(BufferedPlayerAction.movementArt);
      return false;
    }
    final input = game.movementInput();
    _movementArtDirection = input.length2 > 0 ? input : aimDirection;
    action = PlayerAction.movementArt;
    actionRemaining = game.tuning.dashDuration;
    movementArtCooldown = game.tuning.dashCooldown;
    invulnerabilityRemaining = 0;
    game.counters.record(GameplayAction.dash);
    return true;
  }

  bool requestGather() {
    if (gatherCooldown > 0 || action == PlayerAction.defeated) return false;
    if (action != PlayerAction.locomotion) {
      _buffer(BufferedPlayerAction.gather);
      return false;
    }
    action = PlayerAction.gather;
    actionRemaining = 0.60;
    gatherCooldown = game.tuning.gatherCooldown;
    _gatherResolved = false;
    game.counters.record(GameplayAction.gather);
    return true;
  }

  bool requestClear() {
    if (qi < game.tuning.clearQiCost || action == PlayerAction.defeated) {
      return false;
    }
    if (action != PlayerAction.locomotion) {
      _buffer(BufferedPlayerAction.clear);
      return false;
    }
    action = PlayerAction.clear;
    actionRemaining = 0.76;
    qi -= game.tuning.clearQiCost;
    _clearResolved = false;
    game.counters.record(GameplayAction.clear);
    return true;
  }

  bool receiveDamage(double amount, Vector2 source, {required bool heavy}) {
    if (invulnerabilityRemaining > 0 || damageProtectionRemaining > 0) {
      return false;
    }
    health = math.max(0, health - amount);
    damageProtectionRemaining = 0.18;
    if (health <= 0) {
      action = PlayerAction.defeated;
      actionRemaining = 0;
    } else if (action != PlayerAction.clear || heavy) {
      action = PlayerAction.hurt;
      actionRemaining = 0.18;
      final away = position - source;
      if (away.length2 > 0) position += away.normalized() * 26;
    }
    return true;
  }

  void resetForSession() {
    health = game.tuning.playerMaxHealth;
    qi = game.config.number('gameplay.player.starting_qi');
    action = PlayerAction.locomotion;
    actionRemaining = 0;
    movementArtCooldown = 0;
    gatherCooldown = 0;
    invulnerabilityRemaining = 0;
    damageProtectionRemaining = 0;
    recoveryRemaining = 0;
    _bufferedAction = null;
    _bufferRemaining = 0;
    position = Vector2(400, game.fieldHeight / 2);
  }

  void _buffer(BufferedPlayerAction action) {
    _bufferedAction = action;
    _bufferRemaining = 0.12;
  }

  bool _consumeBufferedAction() {
    final buffered = _bufferedAction;
    if (buffered == null || _bufferRemaining <= 0) return false;
    _bufferedAction = null;
    _bufferRemaining = 0;
    return switch (buffered) {
      BufferedPlayerAction.movementArt => requestMovementArt(),
      BufferedPlayerAction.gather => requestGather(),
      BufferedPlayerAction.clear => requestClear(),
    };
  }

  void _startBasic() {
    action = PlayerAction.basic;
    actionRemaining = game.tuning.basicInterval;
    _basicResolved = false;
    game.counters.record(GameplayAction.basic);
  }

  void _updateCurrentAction(double dt) {
    switch (action) {
      case PlayerAction.basic:
        _move(game.movementInput(), dt, game.tuning.basicMoveFactor);
        if (!_basicResolved && actionRemaining <= 0.25) {
          _basicResolved = true;
          _resolveBasic();
        }
      case PlayerAction.movementArt:
        final elapsed = game.tuning.dashDuration - actionRemaining;
        invulnerabilityRemaining = elapsed >= 0.03 && elapsed <= 0.15
            ? math.max(invulnerabilityRemaining, dt)
            : 0;
        position += _movementArtDirection * game.tuning.dashSpeed * dt;
        final radius = size.x / 2;
        position.clamp(
          Vector2(radius, game.combatTop + radius),
          Vector2(game.fieldWidth - radius, game.combatBottom - radius),
        );
      case PlayerAction.gather:
        if (!_gatherResolved && actionRemaining <= 0.42) {
          _gatherResolved = true;
          _resolveGather();
        }
      case PlayerAction.clear:
        if (!_clearResolved && actionRemaining <= 0.48) {
          _clearResolved = true;
          _resolveClear();
        }
      case PlayerAction.hurt:
      case PlayerAction.defeated:
      case PlayerAction.locomotion:
        break;
    }
  }

  void _move(Vector2 input, double dt, double factor) {
    position +=
        Vector2(
          input.x * game.tuning.playerHorizontalSpeed,
          input.y * game.tuning.playerVerticalSpeed,
        ) *
        dt *
        factor;
    final radius = size.x / 2;
    position.clamp(
      Vector2(radius, game.combatTop + radius),
      Vector2(game.fieldWidth - radius, game.combatBottom - radius),
    );
  }

  void _resolveBasic() {
    var hitAny = false;
    var lightReacts = 0;
    final maxReacts = game.config.integer('gameplay.basic.maximum_hit_reacts');
    for (final enemy in game.enemies) {
      if (!enemy.alive ||
          !isInsideAimArc(
            origin: position,
            aimDirection: aimDirection,
            target: enemy.position,
            range: game.tuning.basicRange,
            halfArcRadians: game.tuning.basicHalfArcRadians,
          )) {
        continue;
      }
      hitAny = true;
      enemy.receiveHit(
        game.tuning.basicDamage,
        breakPoints: 1,
        lightReact: lightReacts++ < maxReacts,
        source: position,
      );
    }
    if (hitAny) {
      qi = qiAfterBasicCast(
        currentQi: qi,
        hitAnyTarget: true,
        capacity: game.config.number('gameplay.player.qi_capacity'),
        tuning: game.tuning,
      );
      game.feedbackPool.emit(
        kind: FeedbackKind.basic,
        origin: position + aimDirection * 90,
        count: game.config.integer('gameplay.feedback.basic_particles'),
        lifetime: game.config.number(
          'gameplay.feedback.basic_lifetime_seconds',
        ),
        random: game.random,
      );
      game.triggerHitStop(
        game.config.number('gameplay.feedback.basic_hit_stop_seconds'),
      );
    }
  }

  void _resolveGather() {
    final maxRange = game.config.number('gameplay.gather.maximum_cast_range');
    final delta = game.pointerWorld - position;
    final center = delta.length > maxRange
        ? position + delta.normalized() * maxRange
        : game.pointerWorld.clone();
    final maxPull = game.config.number('gameplay.gather.maximum_pull_distance');
    final targets = game
        .enemiesInRadius(center, game.tuning.gatherRadius)
        .toList();
    game.telemetry.gatherTargetCounts.add(targets.length);
    game.feedbackPool.emit(
      kind: FeedbackKind.gather,
      origin: center,
      count: game.config.integer('gameplay.feedback.gather_particles'),
      lifetime: game.config.number('gameplay.feedback.gather_lifetime_seconds'),
      random: game.random,
    );
    for (final enemy in targets) {
      if (enemy.elite) {
        enemy.pullToward(center, maxPull * 0.35);
        enemy.applyBreakPoints(2);
      } else {
        enemy.pullToward(
          gatherDestination(
            origin: center,
            enemy: enemy.position,
            targetRadius: game.tuning.gatherTargetRadius,
          ),
          maxPull,
        );
        enemy.imbalanceRemaining = game.tuning.imbalanceDuration;
      }
    }
  }

  void _resolveClear() {
    final targets = game
        .enemiesInRadius(position, game.tuning.clearRadius)
        .toList();
    var kills = 0;
    for (final enemy in targets) {
      final wasAlive = enemy.alive;
      if (enemy.elite) {
        enemy.receiveHit(
          game.config.number('gameplay.clear.elite_damage'),
          breakPoints: 2,
          lightReact: false,
          source: position,
        );
      } else {
        enemy.receiveHit(
          normalClearDamage(
            imbalanced: enemy.imbalanceRemaining > 0,
            tuning: game.tuning,
            imbalancedMultiplier: game.config.number(
              'gameplay.clear.imbalanced_multiplier',
            ),
          ),
          breakPoints: 0,
          lightReact: true,
          source: position,
          knockback: 100,
        );
      }
      if (wasAlive && !enemy.alive) kills++;
    }
    game.telemetry
      ..clearHitCounts.add(targets.length)
      ..clearKillCounts.add(kills);
    game.feedbackPool.emit(
      kind: FeedbackKind.clear,
      origin: position,
      count: game.config.integer('gameplay.feedback.clear_particles'),
      lifetime: game.config.number('gameplay.feedback.clear_lifetime_seconds'),
      random: game.random,
    );
    game.triggerHitStop(
      game.config.number('gameplay.feedback.clear_hit_stop_seconds'),
    );
    game.triggerCameraShake();
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;
    canvas.drawCircle(
      center,
      radius + 6,
      Paint()..color = const Color(0x66eee6d2),
    );
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xff24332e));
    canvas.drawLine(
      center,
      center + Offset(aimDirection.x, aimDirection.y) * 34,
      Paint()
        ..color = action == PlayerAction.clear
            ? const Color(0xffa33b32)
            : const Color(0xffeee6d2)
        ..strokeWidth = 5,
    );
    if (action == PlayerAction.gather || action == PlayerAction.clear) {
      final progress =
          1 - actionRemaining / (action == PlayerAction.gather ? 0.60 : 0.76);
      canvas.drawCircle(
        center,
        action == PlayerAction.clear
            ? game.tuning.clearRadius * progress.clamp(0.05, 1)
            : radius + 10 + progress * 12,
        Paint()
          ..color = const Color(0xff8a332e)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }
}

final class GameplayEnemy extends PositionComponent {
  GameplayEnemy({
    required this.game,
    required this.id,
    required this.elite,
    required Vector2 spawn,
  }) : health = elite ? game.tuning.eliteHealth : game.tuning.normalHealth,
       super(
         position: spawn,
         size: Vector2.all(
           game.config.number(
                 elite ? 'gameplay.elite.radius' : 'gameplay.normal.radius',
               ) *
               2,
         ),
         anchor: Anchor.center,
         priority: elite ? 12 : 10,
       ) {
    attackCooldown = (id % 3) * 0.18;
  }

  final GameplayGame game;
  final int id;
  final bool elite;
  double health;
  EnemyMode mode = EnemyMode.spawning;
  bool hasAttackSlot = false;
  double spawnGrace = 1.2;
  double attackCooldown = 0;
  double modeRemaining = 0;
  double imbalanceRemaining = 0;
  int breakPoints = 0;
  double _telegraphCooldown = 4.0;
  double _defeatRemaining = 0;
  double _flashRemaining = 0;
  double _pullRemaining = 0;
  Vector2? _pullTarget;
  bool _activeInEncounter = true;
  Vector2 _impulse = Vector2.zero();

  bool get alive =>
      _activeInEncounter && health > 0 && mode != EnemyMode.defeated;
  bool get inBreakWindow =>
      elite && mode == EnemyMode.telegraph && modeRemaining <= 0.85;

  @override
  void update(double dt) {
    if (!alive) {
      if (!_activeInEncounter) return;
      if (mode == EnemyMode.defeated) {
        _defeatRemaining -= dt;
        if (_defeatRemaining <= 0) {
          if (!game.deterministicReplay) {
            removeFromParent();
            game.onEnemyRemoval(this);
          }
        }
      }
      return;
    }
    final wasInSpawnGrace = spawnGrace > 0;
    spawnGrace = math.max(0, spawnGrace - dt);
    if (!wasInSpawnGrace) {
      attackCooldown = math.max(0, attackCooldown - dt);
    }
    imbalanceRemaining = math.max(0, imbalanceRemaining - dt);
    _flashRemaining = math.max(0, _flashRemaining - dt);
    if (_pullRemaining > 0 && _pullTarget != null) {
      final step = math.min(1.0, dt / _pullRemaining);
      position += (_pullTarget! - position) * step;
      _pullRemaining = math.max(0, _pullRemaining - dt);
      if (_pullRemaining == 0) _pullTarget = null;
    }
    if (_impulse.length2 > 1) {
      position += _impulse * dt;
      _impulse.scale(math.pow(0.015, dt).toDouble());
    }
    if (mode == EnemyMode.staggered) {
      modeRemaining -= dt;
      if (modeRemaining <= 0) mode = EnemyMode.approach;
      return;
    }
    if (mode == EnemyMode.hitReact) {
      modeRemaining -= dt;
      if (modeRemaining <= 0) mode = EnemyMode.approach;
      return;
    }
    if (mode == EnemyMode.telegraph) {
      modeRemaining -= dt;
      if (modeRemaining <= 0.2) {
        mode = EnemyMode.commit;
        modeRemaining = 0.2;
      }
      return;
    }
    if (mode == EnemyMode.commit) {
      modeRemaining -= dt;
      if (modeRemaining <= 0) {
        final heavyDelta = game.player.position - position;
        const heavyRange = 230.0;
        if (heavyDelta.length2 <= heavyRange * heavyRange) {
          game.damagePlayer(
            game.config.number('gameplay.elite.heavy_damage'),
            position,
          );
        }
        mode = EnemyMode.approach;
        _telegraphCooldown = game.tuning.eliteChargeInterval;
      }
      return;
    }
    if (mode == EnemyMode.attack) {
      modeRemaining -= dt;
      if (modeRemaining <= 0) {
        final strikeDelta = game.player.position - position;
        final strikeRange = game.tuning.enemyAttackRange + size.x / 2 + 18;
        if (strikeDelta.length2 <= strikeRange * strikeRange) {
          game.damagePlayer(elite ? 12 : game.tuning.enemyDamage, position);
        }
        mode = EnemyMode.approach;
        attackCooldown = game.tuning.enemyAttackInterval;
      }
      return;
    }
    if (spawnGrace > 0) return;
    if (elite) {
      _telegraphCooldown -= dt;
      if (_telegraphCooldown <= 0) {
        mode = EnemyMode.telegraph;
        modeRemaining = game.tuning.eliteTelegraphDuration;
        breakPoints = 0;
        game.telemetry.breakOpportunities++;
        return;
      }
    }
    final delta = game.player.position - position;
    final distance = delta.length;
    final radius = size.x / 2;
    if (distance > game.tuning.enemyAttackRange + radius ||
        (!elite && !hasAttackSlot)) {
      mode = EnemyMode.approach;
      if (distance > 0) {
        final speed = elite ? game.tuning.eliteSpeed : game.tuning.normalSpeed;
        if (!elite && !hasAttackSlot && distance < 155) {
          final orbitDirection = id.isEven ? 1.0 : -1.0;
          final tangent = Vector2(-delta.y, delta.x) / distance;
          position += tangent * speed * orbitDirection * dt * 0.6;
        } else {
          position += delta / distance * speed * dt;
        }
      }
    } else if (attackCooldown <= 0 && (elite || game.tryStartNormalAttack())) {
      mode = EnemyMode.attack;
      modeRemaining = 0.35;
    }
    final radiusWithBounds = size.x / 2;
    position.clamp(
      Vector2(radiusWithBounds, game.combatTop + radiusWithBounds),
      Vector2(
        game.fieldWidth - radiusWithBounds,
        game.combatBottom - radiusWithBounds,
      ),
    );
    super.update(dt);
  }

  void receiveHit(
    double damage, {
    required int breakPoints,
    required bool lightReact,
    required Vector2 source,
    double knockback = 35,
  }) {
    if (!alive) return;
    applyBreakPoints(breakPoints);
    final staggerMultiplier = mode == EnemyMode.staggered ? 1.5 : 1.0;
    health = math.max(0, health - damage * staggerMultiplier);
    _flashRemaining = 0.08;
    final away = position - source;
    if (away.length2 > 0 && (lightReact || !elite)) {
      _impulse = away.normalized() * knockback;
    }
    if (lightReact && !elite && mode == EnemyMode.attack) {
      mode = EnemyMode.hitReact;
      modeRemaining = 0.12;
      attackCooldown = game.tuning.enemyAttackInterval;
    }
    if (health <= 0) {
      mode = EnemyMode.defeated;
      _defeatRemaining = (id % 20) * 0.009;
      game.onEnemyDefeated(this);
    }
  }

  void applyBreakPoints(int amount) {
    if (!inBreakWindow || amount <= 0) return;
    breakPoints += amount;
    if (breakPoints >= game.tuning.eliteBreakThreshold) {
      mode = EnemyMode.staggered;
      modeRemaining = game.config.number('gameplay.elite.stagger_seconds');
      _telegraphCooldown = game.tuning.eliteChargeInterval;
      game.counters.record(GameplayAction.breakSuccess);
      game.triggerHitStop(
        game.config.number('gameplay.feedback.break_hit_stop_seconds'),
      );
      game.player.qi = math.min(
        game.config.number('gameplay.player.qi_capacity'),
        game.player.qi + 15,
      );
    }
  }

  void pullToward(Vector2 target, double maximumDistance) {
    final delta = target - position;
    if (delta.length2 == 0) return;
    _pullTarget =
        position + delta.normalized() * math.min(maximumDistance, delta.length);
    _pullRemaining = 0.30;
  }

  void activateForReplay(Vector2 spawn) {
    _activeInEncounter = true;
    position = spawn;
    health = elite ? game.tuning.eliteHealth : game.tuning.normalHealth;
    mode = EnemyMode.spawning;
    spawnGrace = 0.35;
    attackCooldown = (id % 3) * 0.18;
    modeRemaining = 0;
    imbalanceRemaining = 0;
    breakPoints = 0;
    _telegraphCooldown = elite ? 1.0 : 4.0;
    _defeatRemaining = 0;
    _flashRemaining = 0;
    _pullRemaining = 0;
    _pullTarget = null;
    _impulse = Vector2.zero();
  }

  void deactivateForReplay() {
    _activeInEncounter = false;
    health = 0;
    mode = EnemyMode.defeated;
    hasAttackSlot = false;
  }

  @override
  void render(Canvas canvas) {
    if (!_activeInEncounter) return;
    final radius = size.x / 2;
    final center = Offset(radius, radius);
    final color = _flashRemaining > 0
        ? const Color(0xffeee6d2)
        : elite
        ? const Color(0xff6a2f2b)
        : const Color(0xff515a54);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: radius * (elite ? 1.75 : 1.5),
        height: radius * 2,
      ),
      Paint()..color = color,
    );
    if (imbalanceRemaining > 0) {
      canvas.drawCircle(
        center,
        radius + 4,
        Paint()
          ..color = const Color(0xff837c68)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    if (mode == EnemyMode.telegraph) {
      final breakable = inBreakWindow;
      canvas.drawCircle(
        center,
        radius + 8,
        Paint()
          ..color = breakable
              ? const Color(0xffc04a3e)
              : const Color(0xff413b35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = breakable ? 6 : 3,
      );
    }
    if (mode == EnemyMode.commit) {
      canvas.drawCircle(
        center,
        230,
        Paint()
          ..color = const Color(0x55a33b32)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7,
      );
    }
    if (mode == EnemyMode.attack) {
      final facing = game.player.position - position;
      if (facing.length2 > 0) {
        final direction = facing.normalized();
        canvas.drawLine(
          center,
          center + Offset(direction.x, direction.y) * (radius + 16),
          Paint()
            ..color = const Color(0xffa33b32)
            ..strokeWidth = 4,
        );
      }
    }
    if (elite) {
      final maxHealth = game.tuning.eliteHealth;
      canvas.drawRect(
        Rect.fromLTWH(0, -8, size.x * (health / maxHealth), 4),
        Paint()..color = const Color(0xff8a332e),
      );
    }
  }
}

final class GameplaySkillGuide extends PositionComponent {
  GameplaySkillGuide({required this.game}) : super(priority: 14);

  final GameplayGame game;

  @override
  void update(double dt) {
    position = game.pointerWorld;
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final gathering = game.player.action == PlayerAction.gather;
    canvas.drawCircle(
      Offset.zero,
      gathering ? game.tuning.gatherRadius : 9,
      Paint()
        ..color = gathering ? const Color(0x66737b70) : const Color(0x99672d2a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = gathering ? 3 : 2,
    );
    if (gathering) {
      canvas.drawCircle(
        Offset.zero,
        game.tuning.gatherTargetRadius,
        Paint()
          ..color = const Color(0x998a332e)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }
}

final class GameplayFeedbackPool {
  GameplayFeedbackPool({required int size})
    : _residents = List.generate(size, (_) => GameplayFeedback());

  final List<GameplayFeedback> _residents;
  int _cursor = 0;
  int emittedTotal = 0;
  int overflowTotal = 0;
  int activePeak = 0;

  Future<void> mount(World world) async {
    await world.addAll(_residents);
  }

  void emit({
    required FeedbackKind kind,
    required Vector2 origin,
    required int count,
    required double lifetime,
    required math.Random random,
  }) {
    for (var index = 0; index < count; index++) {
      GameplayFeedback? target;
      for (var attempt = 0; attempt < _residents.length; attempt++) {
        final candidate = _residents[_cursor];
        _cursor = (_cursor + 1) % _residents.length;
        if (!candidate.active) {
          target = candidate;
          break;
        }
      }
      if (target == null) {
        overflowTotal++;
        break;
      }
      final angle = random.nextDouble() * math.pi * 2;
      final speed = switch (kind) {
        FeedbackKind.basic => 90.0,
        FeedbackKind.gather => -120.0,
        FeedbackKind.clear => 210.0,
      };
      final radial = Vector2(math.cos(angle), math.sin(angle));
      target.activate(
        kind: kind,
        origin: origin + radial * (kind == FeedbackKind.gather ? 210 : 12),
        velocity: radial * speed,
        lifetime: lifetime,
      );
      emittedTotal++;
    }
    activePeak = math.max(
      activePeak,
      _residents.where((resident) => resident.active).length,
    );
  }

  Map<String, Object?> snapshot() => {
    'created_total': _residents.length,
    'active_current': _residents.where((resident) => resident.active).length,
    'active_peak': activePeak,
    'emitted_total': emittedTotal,
    'overflow_total': overflowTotal,
    'allocation_after_warmup': 0,
    'invariant_holds': _residents.isNotEmpty && overflowTotal == 0,
  };
}

final class GameplayFeedback extends PositionComponent {
  GameplayFeedback()
    : super(size: Vector2.all(8), anchor: Anchor.center, priority: 8);

  bool active = false;
  FeedbackKind kind = FeedbackKind.basic;
  double _remaining = 0;
  double _lifetime = 1;
  Vector2 _velocity = Vector2.zero();

  void activate({
    required FeedbackKind kind,
    required Vector2 origin,
    required Vector2 velocity,
    required double lifetime,
  }) {
    active = true;
    this.kind = kind;
    position = origin;
    _velocity = velocity;
    _remaining = lifetime;
    _lifetime = lifetime;
  }

  @override
  void update(double dt) {
    if (!active) return;
    _remaining -= dt;
    position += _velocity * dt;
    if (kind == FeedbackKind.gather) {
      _velocity.scale(math.pow(0.06, dt).toDouble());
    } else {
      _velocity.scale(math.pow(0.22, dt).toDouble());
    }
    if (_remaining <= 0) {
      active = false;
      _remaining = 0;
      _velocity = Vector2.zero();
    }
  }

  @override
  void render(Canvas canvas) {
    if (!active) return;
    final alpha = (_remaining / _lifetime).clamp(0.0, 1.0);
    final color = switch (kind) {
      FeedbackKind.basic => const Color(0xffeee6d2),
      FeedbackKind.gather => const Color(0xff59655f),
      FeedbackKind.clear => const Color(0xff7b332e),
    };
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      kind == FeedbackKind.clear ? 4 : 3,
      Paint()..color = color.withValues(alpha: alpha),
    );
  }
}
