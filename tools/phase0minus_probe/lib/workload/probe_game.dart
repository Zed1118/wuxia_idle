import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:phase0minus_probe/config/probe_config.dart';
import 'package:phase0minus_probe/metrics/frame_statistics.dart';
import 'package:phase0minus_probe/workload/deterministic_script.dart';
import 'package:phase0minus_probe/workload/object_pool.dart';
import 'package:phase0minus_probe/workload/spatial_hash.dart';

enum AgentState { idle, moving, attacking, hurt, dying }

final class ProbeHudState {
  const ProbeHudState({
    required this.health,
    required this.energy,
    required this.cooldownA,
    required this.cooldownB,
    required this.enemyCount,
    required this.tier,
    required this.paused,
  });

  final double health;
  final double energy;
  final double cooldownA;
  final double cooldownB;
  final int enemyCount;
  final String tier;
  final bool paused;
}

final class ProbeGame extends FlameGame with HasCollisionDetection {
  ProbeGame({required this.config, required this.tier})
    : spatialHash = SpatialHash<EnemyAgent>(config.gridCellSize),
      script = DeterministicScript(
        seed: config.fixedSeed,
        burstIntervalSeconds: config.burstIntervalSeconds,
      ),
      hud = ValueNotifier(
        ProbeHudState(
          health: 1,
          energy: 0.4,
          cooldownA: 0,
          cooldownB: 0,
          enemyCount: tier.totalEnemies,
          tier: tier.id,
          paused: false,
        ),
      );

  final ProbeConfig config;
  final ProbeTier tier;
  final SpatialHash<EnemyAgent> spatialHash;
  final DeterministicScript script;
  final ValueNotifier<ProbeHudState> hud;
  late final PlayerAgent player;
  late final ObjectPool<EnemyAgent> enemyPool;
  late final ObjectPool<TransientEffect> particlePool;
  late final ObjectPool<TransientEffect> afterimagePool;
  late final ObjectPool<TransientEffect> damageLabelPool;
  final List<EnemyAgent> enemies = [];
  late final math.Random _random = math.Random(config.fixedSeed);
  double _elapsed = 0;
  double _lastBurstAt = 0;
  double _lastHudAt = 0;
  double _respawnAt = -1;
  int clearEventId = -1;
  int clearEventCount = 0;
  int broadPhaseCandidates = 0;
  int narrowPhaseCallbacks = 0;
  int mergedDamageLabels = 0;
  final List<int> _broadCandidatesPerFrame = [];
  final List<int> _narrowCallbacksPerFrame = [];

  @override
  Color backgroundColor() => const Color(0xffe8e0cb);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = Vector2(size.x / 2, config.worldDepth / 2);
    await world.add(
      RectangleComponent(
        size: Vector2(config.worldWidth, config.worldDepth),
        paint: Paint()..color = const Color(0xffd9cfb5),
      ),
    );
    player = PlayerAgent(
      radius: config.number('simulation.player_radius'),
      worldWidth: config.worldWidth,
      worldDepth: config.worldDepth,
      speed: config.number('simulation.player_speed'),
    );
    await world.add(player);
    enemyPool = ObjectPool(
      () => EnemyAgent(
        onCollisionTick: () => narrowPhaseCallbacks++,
        release: _releaseEnemy,
      ),
    );
    particlePool = ObjectPool(
      () =>
          TransientEffect(kind: EffectKind.particle, release: _releaseParticle),
    );
    afterimagePool = ObjectPool(
      () => TransientEffect(
        kind: EffectKind.afterimage,
        release: _releaseAfterimage,
      ),
    );
    damageLabelPool = ObjectPool(
      () => TransientEffect(
        kind: EffectKind.damageLabel,
        release: _releaseDamageLabel,
      ),
    );
    final labelBudget = tier.id == 'baseline_10'
        ? config.integer('effects.baseline_damage_labels')
        : tier.id == 'target_20_plus_1'
        ? config.integer('effects.target_damage_labels')
        : config.integer('effects.stress_damage_labels');
    particlePool.prewarm(
      tier.totalEnemies * config.integer('effects.death_particles_per_enemy') +
          config.integer('effects.center_burst_particles'),
    );
    afterimagePool.prewarm(config.integer('effects.afterimages'));
    damageLabelPool.prewarm(labelBudget);
    await _spawnWave();
  }

  @override
  void update(double dt) {
    final broadBefore = broadPhaseCandidates;
    final narrowBefore = narrowPhaseCallbacks;
    _elapsed += dt;
    spatialHash.rebuild(
      enemies.where((enemy) => enemy.active && enemy.hitPoints > 0),
    );
    _assignAttackSlots();
    super.update(dt);
    _moveCamera();
    _driveBurst();
    _driveHud();
    _broadCandidatesPerFrame.add(broadPhaseCandidates - broadBefore);
    _narrowCallbacksPerFrame.add(narrowPhaseCallbacks - narrowBefore);
  }

  void markWarmupComplete() {
    enemyPool.warmupComplete = true;
    particlePool.warmupComplete = true;
    afterimagePool.warmupComplete = true;
    damageLabelPool.warmupComplete = true;
  }

  void _moveCamera() {
    final half = config.cameraTravel / 2;
    final center = size.x / 2 + half;
    final x = center + math.sin(_elapsed * 0.35) * half;
    camera.viewfinder.position = Vector2(
      x.clamp(size.x / 2, config.worldWidth - size.x / 2),
      config.worldDepth / 2,
    );
  }

  void _assignAttackSlots() {
    final alive = enemies.where((enemy) => enemy.active).toList()
      ..sort(
        (a, b) => a.position
            .distanceTo(player.position)
            .compareTo(b.position.distanceTo(player.position)),
      );
    var normalSlots = config.integer('simulation.melee_attack_slots');
    var eliteSlots = config.integer('simulation.elite_attack_slots');
    for (final enemy in alive) {
      if (enemy.isElite) {
        enemy.hasAttackSlot = eliteSlots-- > 0;
      } else {
        enemy.hasAttackSlot = normalSlots-- > 0;
      }
    }
  }

  void _driveBurst() {
    if (_elapsed - _lastBurstAt >= config.burstIntervalSeconds) {
      _lastBurstAt += config.burstIntervalSeconds;
      _triggerClearBurst();
    }
    if (_respawnAt >= 0 && _elapsed >= _respawnAt) {
      _respawnAt = -1;
      _spawnWave();
    }
  }

  void _driveHud() {
    final interval = 1 / config.hudUpdateHz;
    if (_elapsed - _lastHudAt < interval) return;
    _lastHudAt = _elapsed;
    hud.value = ProbeHudState(
      health: 0.72 + math.sin(_elapsed * 0.7) * 0.18,
      energy: 0.50 + math.sin(_elapsed * 1.1) * 0.35,
      cooldownA: (_elapsed % 3) / 3,
      cooldownB: (_elapsed % 7) / 7,
      enemyCount: enemies.where((enemy) => enemy.active).length,
      tier: tier.id,
      paused: paused,
    );
  }

  void _triggerClearBurst() {
    clearEventId++;
    clearEventCount++;
    final alive = enemies.where((enemy) => enemy.active).toList();
    for (final enemy in alive) {
      enemy.receiveClearHit(
        knockback: config.number('simulation.hit_knockback'),
      );
    }
    final deathParticles =
        alive.length * config.integer('effects.death_particles_per_enemy');
    final centerParticles = config.integer('effects.center_burst_particles');
    _emitEffects(
      pool: particlePool,
      count: deathParticles + centerParticles,
      lifetime: config.number('effects.particle_lifetime_seconds'),
    );
    _emitEffects(
      pool: afterimagePool,
      count: config.integer('effects.afterimages'),
      lifetime: config.number('effects.afterimage_lifetime_seconds'),
    );
    final labelBudget = tier.id == 'baseline_10'
        ? config.integer('effects.baseline_damage_labels')
        : tier.id == 'target_20_plus_1'
        ? config.integer('effects.target_damage_labels')
        : config.integer('effects.stress_damage_labels');
    mergedDamageLabels += math.max(0, alive.length - labelBudget);
    _emitEffects(
      pool: damageLabelPool,
      count: math.min(alive.length, labelBudget),
      lifetime: config.number('effects.damage_label_lifetime_seconds'),
    );
    _respawnAt = _elapsed + config.respawnDelaySeconds;
  }

  Future<void> _spawnWave() async {
    if (enemies.any((enemy) => enemy.active)) return;
    for (var index = 0; index < tier.totalEnemies; index++) {
      final enemy = enemyPool.acquire();
      final elite = index >= tier.normalEnemies;
      enemy.configure(
        id: index,
        elite: elite,
        radius: elite
            ? config.number('simulation.elite_radius')
            : config.number('simulation.enemy_radius'),
        hitPoints: elite
            ? config.number('simulation.elite_hit_points')
            : config.number('simulation.enemy_hit_points'),
        speed: elite
            ? config.number('simulation.elite_speed')
            : config.number('simulation.enemy_speed'),
        separationRadius: config.number('simulation.separation_radius'),
        worldWidth: config.worldWidth,
        worldDepth: config.worldDepth,
        eliteChargeSeconds: config.number('simulation.elite_charge_seconds'),
        animationHz: config.number('simulation.enemy_animation_hz'),
        spawn: Vector2(
          520 + _random.nextDouble() * (config.worldWidth - 700),
          45 + _random.nextDouble() * (config.worldDepth - 90),
        ),
      );
      enemies.add(enemy);
      await world.add(enemy);
    }
  }

  void _emitEffects({
    required ObjectPool<TransientEffect> pool,
    required int count,
    required double lifetime,
  }) {
    for (var index = 0; index < count; index++) {
      final effect = pool.acquire();
      effect.configure(
        lifetime: lifetime,
        position:
            player.position +
            Vector2(
              (_random.nextDouble() - 0.5) * 460,
              (_random.nextDouble() - 0.5) * 280,
            ),
        velocity: Vector2(
          (_random.nextDouble() - 0.5) * 180,
          (_random.nextDouble() - 0.5) * 180,
        ),
      );
      world.add(effect);
    }
  }

  void _releaseEnemy(EnemyAgent enemy) {
    enemies.remove(enemy);
    enemyPool.release(enemy);
  }

  void _releaseParticle(TransientEffect effect) => particlePool.release(effect);
  void _releaseAfterimage(TransientEffect effect) =>
      afterimagePool.release(effect);
  void _releaseDamageLabel(TransientEffect effect) =>
      damageLabelPool.release(effect);

  List<EnemyAgent> neighbours(EnemyAgent enemy, double radius) {
    final result = spatialHash.query(enemy.position, radius);
    broadPhaseCandidates += result.length;
    return result;
  }

  Map<String, Object?> poolSnapshot() => {
    'enemy': enemyPool.counters.toJson(freeCurrent: enemyPool.availableCount),
    'particle': particlePool.counters.toJson(
      freeCurrent: particlePool.availableCount,
    ),
    'afterimage': afterimagePool.counters.toJson(
      freeCurrent: afterimagePool.availableCount,
    ),
    'damage_label': damageLabelPool.counters.toJson(
      freeCurrent: damageLabelPool.availableCount,
    ),
  };

  Map<String, Object?> workloadSnapshot() => {
    'clear_event_count': clearEventCount,
    'clear_event_id': clearEventId,
    'event_checksum': script.checksumForDuration(
      config.warmupSeconds + config.sampleSeconds + config.cooldownSeconds,
    ),
    'broad_phase_candidate_total': broadPhaseCandidates,
    'narrow_phase_callback_total': narrowPhaseCallbacks,
    'broad_phase_candidates': _loadSummary(_broadCandidatesPerFrame),
    'narrow_phase_callbacks': _loadSummary(_narrowCallbacksPerFrame),
    'merged_damage_labels': mergedDamageLabels,
    'active_enemies': enemies.where((enemy) => enemy.active).length,
  };

  Map<String, int> _loadSummary(List<int> samples) {
    if (samples.isEmpty) return {'p50': 0, 'p99': 0, 'max': 0};
    return {
      'p50': nearestRank(samples, 0.50),
      'p99': nearestRank(samples, 0.99),
      'max': samples.reduce(math.max),
    };
  }
}

final class PlayerAgent extends PositionComponent with CollisionCallbacks {
  PlayerAgent({
    required this.radius,
    required this.worldWidth,
    required this.worldDepth,
    required this.speed,
  }) : super(
         size: Vector2.all(radius * 2),
         anchor: Anchor.center,
         position: Vector2(360, worldDepth / 2),
       );

  final double radius;
  final double worldWidth;
  final double worldDepth;
  final double speed;
  double _elapsed = 0;
  AgentState state = AgentState.idle;
  late final CircleHitbox _attackHitbox;

  @override
  Future<void> onLoad() async {
    await add(CircleHitbox(collisionType: CollisionType.passive));
    _attackHitbox = CircleHitbox(
      radius: radius * 1.8,
      position: Vector2.all(radius),
      anchor: Anchor.center,
      collisionType: CollisionType.inactive,
    );
    await add(_attackHitbox);
  }

  @override
  void update(double dt) {
    _elapsed += dt;
    state = (_elapsed % 4) < 0.45 ? AgentState.attacking : AgentState.moving;
    _attackHitbox.collisionType = state == AgentState.attacking
        ? CollisionType.active
        : CollisionType.inactive;
    position = Vector2(
      360 + ((_elapsed * speed) % (worldWidth - 720)),
      worldDepth / 2 + math.sin(_elapsed * 0.8) * worldDepth * 0.28,
    );
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final pulse = 1 + math.sin(_elapsed * 10) * 0.06;
    canvas.drawCircle(
      Offset(radius, radius),
      radius * pulse,
      Paint()..color = const Color(0xff27352f),
    );
    canvas.drawLine(
      Offset(radius, radius),
      Offset(radius + 26, radius - 14),
      Paint()
        ..color = const Color(0xffa33b32)
        ..strokeWidth = state == AgentState.attacking ? 6 : 3,
    );
  }
}

final class EnemyAgent extends PositionComponent
    with CollisionCallbacks
    implements PoolResettable {
  EnemyAgent({required this.onCollisionTick, required this.release});

  final VoidCallback onCollisionTick;
  final void Function(EnemyAgent) release;
  int id = -1;
  bool isElite = false;
  bool active = false;
  bool hasAttackSlot = false;
  double radius = 0;
  double hitPoints = 0;
  double maximumHitPoints = 0;
  double speed = 0;
  double separationRadius = 0;
  double worldWidth = 0;
  double worldDepth = 0;
  double eliteChargeSeconds = 0;
  double animationHz = 0;
  double _elapsed = 0;
  double _charge = 0;
  double _deathRemaining = 0;
  Vector2 _knockback = Vector2.zero();
  AgentState state = AgentState.idle;
  CircleHitbox? _bodyHitbox;
  CircleHitbox? _attackHitbox;

  void configure({
    required int id,
    required bool elite,
    required double radius,
    required double hitPoints,
    required double speed,
    required double separationRadius,
    required double worldWidth,
    required double worldDepth,
    required double eliteChargeSeconds,
    required double animationHz,
    required Vector2 spawn,
  }) {
    this.id = id;
    isElite = elite;
    this.radius = radius;
    maximumHitPoints = hitPoints;
    this.hitPoints = hitPoints;
    this.speed = speed;
    this.separationRadius = separationRadius;
    this.worldWidth = worldWidth;
    this.worldDepth = worldDepth;
    this.eliteChargeSeconds = eliteChargeSeconds;
    this.animationHz = animationHz;
    size = Vector2.all(radius * 2);
    anchor = Anchor.center;
    position = spawn;
    _bodyHitbox
      ?..radius = radius
      ..position = Vector2.all(radius);
    _attackHitbox
      ?..radius = radius * 1.5
      ..position = Vector2.all(radius);
  }

  @override
  Future<void> onLoad() async {
    _bodyHitbox = CircleHitbox(
      radius: radius,
      position: Vector2.all(radius),
      anchor: Anchor.center,
      collisionType: CollisionType.active,
    );
    _attackHitbox = CircleHitbox(
      radius: radius * 1.5,
      position: Vector2.all(radius),
      anchor: Anchor.center,
      collisionType: CollisionType.inactive,
    );
    await addAll([_bodyHitbox!, _attackHitbox!]);
  }

  @override
  void update(double dt) {
    if (!active) return;
    _elapsed += dt;
    final game = findGame()! as ProbeGame;
    if (hitPoints <= 0) {
      state = AgentState.dying;
      position += _knockback * dt;
      _knockback.scale(math.pow(0.01, dt).toDouble());
      _deathRemaining -= dt;
      if (_deathRemaining <= 0) {
        active = false;
        removeFromParent();
        release(this);
      }
      super.update(dt);
      return;
    }
    final toPlayer = game.player.position - position;
    final distance = toPlayer.length;
    var velocity = Vector2.zero();
    if (distance > radius * 2.2 || !hasAttackSlot) {
      velocity += toPlayer.normalized() * speed;
      state = AgentState.moving;
    } else {
      state = AgentState.attacking;
    }
    for (final neighbour in game.neighbours(this, separationRadius)) {
      if (identical(neighbour, this) || !neighbour.active) continue;
      final delta = position - neighbour.position;
      final length = delta.length;
      if (length > 0 && length < separationRadius) {
        velocity +=
            delta.normalized() * speed * (1 - length / separationRadius);
      }
    }
    if (_knockback.length2 > 0.1) {
      velocity += _knockback;
      _knockback.scale(math.pow(0.01, dt).toDouble());
      state = AgentState.hurt;
    }
    position += velocity * dt;
    position.clamp(
      Vector2(radius, radius),
      Vector2(worldWidth - radius, worldDepth - radius),
    );
    if (isElite) _charge = (_charge + dt) % eliteChargeSeconds;
    _attackHitbox?.collisionType = state == AgentState.attacking
        ? CollisionType.active
        : CollisionType.inactive;
    super.update(dt);
  }

  void receiveClearHit({required double knockback}) {
    if (!active) return;
    hitPoints = 0;
    state = AgentState.hurt;
    final game = findGame()! as ProbeGame;
    final direction = position - game.player.position;
    _knockback = direction.length2 == 0
        ? Vector2(knockback, 0)
        : direction.normalized() * knockback;
    _deathRemaining = (id % 5) * 0.03;
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    onCollisionTick();
    super.onCollision(intersectionPoints, other);
  }

  @override
  void render(Canvas canvas) {
    final frame = ((_elapsed * animationHz).floor() % 4) / 4;
    final body = isElite ? const Color(0xff672d2a) : const Color(0xff4a5550);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(radius, radius),
        width: radius * 1.6 + frame * 3,
        height: radius * 2.0 - frame * 2,
      ),
      Paint()..color = body,
    );
    if (isElite) {
      final charge = _charge / eliteChargeSeconds;
      canvas.drawCircle(
        Offset(radius, radius),
        radius + 5 + charge * 8,
        Paint()
          ..color = const Color(0x55a33b32)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  void resetForAcquire() {
    active = true;
    hasAttackSlot = false;
    state = AgentState.idle;
    _elapsed = 0;
    _charge = 0;
    _deathRemaining = 0;
    _knockback = Vector2.zero();
    _bodyHitbox?.collisionType = CollisionType.active;
    _attackHitbox?.collisionType = CollisionType.inactive;
  }

  @override
  void resetForRelease() {
    active = false;
    hasAttackSlot = false;
    hitPoints = 0;
    _deathRemaining = 0;
    state = AgentState.dying;
    _knockback = Vector2.zero();
    _bodyHitbox?.collisionType = CollisionType.inactive;
    _attackHitbox?.collisionType = CollisionType.inactive;
  }
}

enum EffectKind { particle, afterimage, damageLabel }

final class TransientEffect extends PositionComponent
    implements PoolResettable {
  TransientEffect({required this.kind, required this.release});

  final EffectKind kind;
  final void Function(TransientEffect) release;
  double _remaining = 0;
  double _initialLifetime = 1;
  Vector2 _velocity = Vector2.zero();
  bool _active = false;

  void configure({
    required double lifetime,
    required Vector2 position,
    required Vector2 velocity,
  }) {
    _remaining = lifetime;
    _initialLifetime = lifetime;
    this.position = position;
    _velocity = velocity;
    size = kind == EffectKind.damageLabel ? Vector2(32, 14) : Vector2.all(8);
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    if (!_active) return;
    _remaining -= dt;
    position += _velocity * dt;
    if (_remaining <= 0) {
      _active = false;
      removeFromParent();
      release(this);
    }
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final alpha = (_remaining / _initialLifetime).clamp(0.0, 1.0);
    final color = switch (kind) {
      EffectKind.particle => const Color(0xff202824),
      EffectKind.afterimage => const Color(0xff73827a),
      EffectKind.damageLabel => const Color(0xff8a332e),
    };
    final paint = Paint()..color = color.withValues(alpha: alpha);
    if (kind == EffectKind.damageLabel) {
      canvas.drawRect(size.toRect(), paint);
    } else {
      canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
    }
  }

  @override
  void resetForAcquire() {
    _active = true;
    _remaining = 0;
    _velocity = Vector2.zero();
    position = Vector2.zero();
  }

  @override
  void resetForRelease() {
    _active = false;
    _remaining = 0;
    _velocity = Vector2.zero();
    position = Vector2.zero();
  }
}
