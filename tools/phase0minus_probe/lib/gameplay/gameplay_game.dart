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

enum EnemyMode { spawning, approach, attack, telegraph, staggered, defeated }

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
  GameplayGame({required this.config, this.onSessionEnded})
    : tuning = GameplayTuning.fromConfig(config),
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
  final GameplayTuning tuning;
  final math.Random random;
  final ValueNotifier<GameplayHudState> hud;
  final GameplayCounters counters = GameplayCounters();
  final GameplayTelemetry telemetry = GameplayTelemetry();
  final List<GameplayEnemy> enemies = [];
  final Set<LogicalKeyboardKey> _keys = {};
  late final GameplayPlayer player;

  Vector2 pointerWorld = Vector2(800, 360);
  bool primaryHeld = false;
  bool _primaryPressed = false;
  GameplayPhase phase = GameplayPhase.active;
  int wave = 1;
  double _waveElapsed = 0;
  double _betweenRemaining = 0;
  double _hudElapsed = 0;
  double _cameraX = 640;
  int _nextEnemyId = 0;
  final Set<int> _spawnedBatches = {};
  bool _sessionReported = false;

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
    _spawnDueBatches();
    _updateCamera();
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
    super.update(dt);
    _assignAttackSlots();
    _driveWaves(dt);
    telemetry.tick(dt, enemies.where((enemy) => enemy.alive).length);
    _updateCamera();
    _hudElapsed += dt;
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
      } else if (event.logicalKey == LogicalKeyboardKey.enter &&
          (phase == GameplayPhase.victory || phase == GameplayPhase.defeat)) {
        resetSession();
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
    if (value) _primaryPressed = true;
  }

  bool consumePrimaryPressed() {
    final pressed = _primaryPressed;
    _primaryPressed = false;
    return pressed;
  }

  void clearInput() {
    _keys.clear();
    primaryHeld = false;
    _primaryPressed = false;
  }

  void togglePause() {
    if (phase == GameplayPhase.victory || phase == GameplayPhase.defeat) return;
    phase = phase == GameplayPhase.paused
        ? GameplayPhase.active
        : GameplayPhase.paused;
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
    phase = GameplayPhase.active;
    wave = 1;
    _waveElapsed = 0;
    _betweenRemaining = 0;
    _spawnedBatches.clear();
    player.resetForSession();
    _spawnDueBatches();
    _updateHud('Wave 1: move, aim, then use Q to R.');
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

  void damagePlayer(double amount, Vector2 source) {
    if (player.receiveDamage(amount, source)) {
      telemetry.damageEvents++;
      counters.breakChain();
      if (player.health <= 0) {
        phase = GameplayPhase.defeat;
        _updateHud('Defeated. Press Enter to try again.');
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
            'Complete. Press Enter to replay after recording feedback.',
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

  void _finishSession(String outcome) {
    if (_sessionReported) return;
    _sessionReported = true;
    onSessionEnded?.call(
      telemetry.toJson(outcome: outcome, counters: counters),
    );
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

  void _assignAttackSlots() {
    final aliveNormals =
        enemies.where((enemy) => enemy.alive && !enemy.elite).toList()..sort(
          (a, b) => a.position
              .distanceToSquared(player.position)
              .compareTo(b.position.distanceToSquared(player.position)),
        );
    final slots = config.integer('gameplay.normal.attack_slots');
    for (var index = 0; index < aliveNormals.length; index++) {
      aliveNormals[index].hasAttackSlot = index < slots;
    }
  }

  void _updateCamera() {
    final halfWidth = size.x / 2;
    final target = player.position.x.clamp(halfWidth, fieldWidth - halfWidth);
    _cameraX += (target - _cameraX) * 0.12;
    camera.viewfinder.position = Vector2(_cameraX, fieldHeight / 2);
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
  Vector2 aimDirection = Vector2(1, 0);
  Vector2 _movementArtDirection = Vector2(1, 0);
  bool _basicResolved = false;
  bool _gatherResolved = false;
  bool _clearResolved = false;

  @override
  void update(double dt) {
    movementArtCooldown = math.max(0, movementArtCooldown - dt);
    gatherCooldown = math.max(0, gatherCooldown - dt);
    invulnerabilityRemaining = math.max(0, invulnerabilityRemaining - dt);
    damageProtectionRemaining = math.max(0, damageProtectionRemaining - dt);
    final pointerDelta = game.pointerWorld - position;
    if (pointerDelta.length2 > 1) aimDirection = pointerDelta.normalized();

    if (action == PlayerAction.defeated) return;
    if (actionRemaining > 0) {
      actionRemaining -= dt;
      _updateCurrentAction(dt);
      if (actionRemaining <= 0) action = PlayerAction.locomotion;
    } else {
      action = PlayerAction.locomotion;
      _move(game.movementInput(), dt, 1);
      if (game.primaryHeld || game.consumePrimaryPressed()) _startBasic();
    }
    super.update(dt);
  }

  void requestMovementArt() {
    if (action == PlayerAction.defeated || movementArtCooldown > 0) return;
    final canCancelBasic =
        action == PlayerAction.basic && actionRemaining <= 0.095;
    if (action != PlayerAction.locomotion && !canCancelBasic) return;
    final input = game.movementInput();
    _movementArtDirection = input.length2 > 0 ? input : aimDirection;
    action = PlayerAction.movementArt;
    actionRemaining = game.tuning.dashDuration;
    movementArtCooldown = game.tuning.dashCooldown;
    invulnerabilityRemaining = 0.15;
    game.counters.record(GameplayAction.dash);
  }

  void requestGather() {
    if (action != PlayerAction.locomotion || gatherCooldown > 0) return;
    action = PlayerAction.gather;
    actionRemaining = 0.60;
    gatherCooldown = game.tuning.gatherCooldown;
    _gatherResolved = false;
    game.counters.record(GameplayAction.gather);
  }

  void requestClear() {
    if (action != PlayerAction.locomotion || qi < game.tuning.clearQiCost) {
      return;
    }
    action = PlayerAction.clear;
    actionRemaining = 0.76;
    qi -= game.tuning.clearQiCost;
    _clearResolved = false;
    game.counters.record(GameplayAction.clear);
  }

  bool receiveDamage(double amount, Vector2 source) {
    if (invulnerabilityRemaining > 0 || damageProtectionRemaining > 0) {
      return false;
    }
    health = math.max(0, health - amount);
    damageProtectionRemaining = 0.18;
    if (health <= 0) {
      action = PlayerAction.defeated;
      actionRemaining = 0;
    } else {
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
    position = Vector2(400, game.fieldHeight / 2);
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
        invulnerabilityRemaining = math.max(invulnerabilityRemaining, 0.03);
        _move(_movementArtDirection, dt, game.tuning.dashSpeed / 360);
      case PlayerAction.gather:
        if (!_gatherResolved && actionRemaining <= 0.30) {
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
        radius + 10 + progress * 12,
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
  Vector2 _impulse = Vector2.zero();

  bool get alive => health > 0 && mode != EnemyMode.defeated;
  bool get inBreakWindow =>
      elite &&
      mode == EnemyMode.telegraph &&
      isBreakWindow(telegraphRemaining: modeRemaining, tuning: game.tuning);

  @override
  void update(double dt) {
    if (!alive) {
      if (mode == EnemyMode.defeated) {
        _defeatRemaining -= dt;
        if (_defeatRemaining <= 0) {
          removeFromParent();
          game.onEnemyRemoval(this);
        }
      }
      return;
    }
    spawnGrace = math.max(0, spawnGrace - dt);
    attackCooldown = math.max(0, attackCooldown - dt);
    imbalanceRemaining = math.max(0, imbalanceRemaining - dt);
    if (_impulse.length2 > 1) {
      position += _impulse * dt;
      _impulse.scale(math.pow(0.015, dt).toDouble());
    }
    if (mode == EnemyMode.staggered) {
      modeRemaining -= dt;
      if (modeRemaining <= 0) mode = EnemyMode.approach;
      return;
    }
    if (mode == EnemyMode.telegraph) {
      modeRemaining -= dt;
      if (modeRemaining <= 0) {
        game.damagePlayer(
          game.config.number('gameplay.elite.heavy_damage'),
          position,
        );
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
        position += delta / distance * speed * dt;
      }
    } else if (attackCooldown <= 0) {
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
    final away = position - source;
    if (away.length2 > 0 && (lightReact || !elite)) {
      _impulse = away.normalized() * knockback;
    }
    if (health <= 0) {
      mode = EnemyMode.defeated;
      _defeatRemaining = 0.24;
      game.onEnemyDefeated(this);
    }
  }

  void applyBreakPoints(int amount) {
    if (!inBreakWindow || amount <= 0) return;
    breakPoints += amount;
    if (breakPoints >= game.tuning.eliteBreakThreshold) {
      mode = EnemyMode.staggered;
      modeRemaining = game.config.number('gameplay.elite.stagger_seconds');
      game.counters.record(GameplayAction.breakSuccess);
      game.player.qi = math.min(
        game.config.number('gameplay.player.qi_capacity'),
        game.player.qi + 15,
      );
    }
  }

  void pullToward(Vector2 target, double maximumDistance) {
    final delta = target - position;
    if (delta.length2 == 0) return;
    position += delta.normalized() * math.min(maximumDistance, delta.length);
  }

  @override
  void render(Canvas canvas) {
    final radius = size.x / 2;
    final center = Offset(radius, radius);
    final color = elite ? const Color(0xff6a2f2b) : const Color(0xff515a54);
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
