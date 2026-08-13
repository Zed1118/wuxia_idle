import 'package:flame/components.dart';
import 'package:phase0minus_probe/gameplay/combat_rules.dart';
import 'package:phase0minus_probe/gameplay/gameplay_game.dart';

abstract interface class GameplayStrategy {
  String get id;

  void reset();

  void tick(GameplayGame game, double elapsedSeconds);
}

final class WeakHoldStrategy implements GameplayStrategy {
  bool _holding = false;

  @override
  String get id => 'weak_stationary_lmb_qr';

  @override
  void reset() => _holding = false;

  @override
  void tick(GameplayGame game, double elapsedSeconds) {
    game.setStrategyMovementOverride(Vector2.zero());
    final nearest = _nearestAlive(game);
    if (nearest != null) game.pointerWorld = nearest.position.clone();
    if (!_holding) {
      game.setPrimaryHeld(true);
      _holding = true;
    }
    if (game.player.gatherCooldown <= 0) game.player.requestGather();
    if (game.player.qi >= game.tuning.clearQiCost) {
      game.player.requestClear();
    }
  }
}

final class BaselineComboStrategy implements GameplayStrategy {
  bool _holding = false;
  double _nextDashAt = 0;

  @override
  String get id => 'baseline_dash_gather_clear_break';

  @override
  void reset() {
    _holding = false;
    _nextDashAt = 0;
  }

  @override
  void tick(GameplayGame game, double elapsedSeconds) {
    final alive = game.enemies.where((enemy) => enemy.alive).toList();
    if (alive.isEmpty) {
      game.setStrategyMovementOverride(Vector2.zero());
      return;
    }
    if (!_holding) {
      game.setPrimaryHeld(true);
      _holding = true;
    }
    final elite = alive.where((enemy) => enemy.elite).firstOrNull;
    final breakTarget = elite != null && elite.inBreakWindow ? elite : null;
    final cluster = _densestNormalCluster(game, alive) ?? elite ?? alive.first;
    final aimTarget = breakTarget ?? cluster;
    game.pointerWorld = aimTarget.position.clone();

    final nearest = _nearestAlive(game)!;
    final nearestDelta = nearest.position - game.player.position;
    final nearestDistance = nearestDelta.length;
    var movement = Vector2.zero();
    if (nearestDistance > 149) {
      movement = nearestDelta.normalized();
    } else if (nearestDistance < 138) {
      movement = -nearestDelta.normalized();
    } else if (nearestDistance > 0) {
      final orbitSign = ((elapsedSeconds / 2).floor().isEven) ? 1.0 : -1.0;
      movement = Vector2(-nearestDelta.y, nearestDelta.x).normalized()
        ..scale(orbitSign);
    }
    final player = game.player;
    final hazards = alive.where((enemy) {
      final distanceSquared = enemy.position.distanceToSquared(player.position);
      if (enemy.elite &&
          (enemy.mode == EnemyMode.telegraph ||
              enemy.mode == EnemyMode.commit)) {
        return distanceSquared < 340 * 340;
      }
      return enemy.mode == EnemyMode.attack && distanceSquared < 210 * 210;
    }).toList();
    final crowded =
        alive
            .where(
              (enemy) =>
                  enemy.position.distanceToSquared(player.position) < 135 * 135,
            )
            .length >=
        3;
    final immediateDanger = hazards.isNotEmpty || crowded;
    if (immediateDanger &&
        elapsedSeconds >= _nextDashAt &&
        player.movementArtCooldown <= 0) {
      final hazard = hazards.isNotEmpty
          ? hazards.reduce(
              (a, b) =>
                  a.position.distanceToSquared(player.position) <
                      b.position.distanceToSquared(player.position)
                  ? a
                  : b,
            )
          : nearest;
      final escape = player.position - hazard.position;
      if (escape.length2 > 0) {
        movement = escape.normalized();
      }
      game.setStrategyMovementOverride(movement);
      if (player.requestMovementArt()) {
        _nextDashAt = elapsedSeconds + game.tuning.dashCooldown;
      }
    } else {
      game.setStrategyMovementOverride(movement);
    }

    if (breakTarget != null) {
      final eliteDistance = breakTarget.position.distanceTo(player.position);
      if (player.gatherCooldown <= 0 && eliteDistance <= 660) {
        player.requestGather();
      } else if (player.qi >= game.tuning.clearQiCost &&
          eliteDistance <= game.tuning.clearRadius) {
        player.requestClear();
      }
      return;
    }

    final clusterDistance = cluster.position.distanceTo(player.position);
    final normalsNearCluster = alive
        .where(
          (enemy) =>
              !enemy.elite &&
              enemy.position.distanceToSquared(cluster.position) <= 300 * 300,
        )
        .length;
    if (player.gatherCooldown <= 0 &&
        clusterDistance <= 620 &&
        normalsNearCluster >= 3) {
      player.requestGather();
    }

    final imbalancedInClear = alive
        .where(
          (enemy) =>
              !enemy.elite &&
              enemy.imbalanceRemaining > 0 &&
              enemy.position.distanceToSquared(player.position) <=
                  game.tuning.clearRadius * game.tuning.clearRadius,
        )
        .length;
    if (player.qi >= game.tuning.clearQiCost && imbalancedInClear >= 2) {
      player.requestClear();
    }
  }
}

final class StrategyRunResult {
  const StrategyRunResult({
    required this.strategyId,
    required this.seed,
    required this.outcome,
    required this.elapsedSeconds,
    required this.terminalWave,
    required this.actions,
    required this.damageEvents,
    required this.breakOpportunities,
  });

  final String strategyId;
  final int seed;
  final String outcome;
  final double elapsedSeconds;
  final int terminalWave;
  final Map<String, int> actions;
  final int damageEvents;
  final int breakOpportunities;

  bool get passed => outcome == 'victory';
  bool get failedInWaveThreeOrTimedOut =>
      outcome == 'timeout' || (outcome == 'defeat' && terminalWave == 3);

  Map<String, Object?> toJson() => {
    'strategy': strategyId,
    'seed': seed,
    'outcome': outcome,
    'elapsed_seconds': elapsedSeconds,
    'terminal_wave': terminalWave,
    'actions': actions,
    'damage_events': damageEvents,
    'break_opportunities': breakOpportunities,
  };
}

StrategyRunResult runGameplayStrategy({
  required GameplayGame game,
  required GameplayStrategy strategy,
  required int seed,
  double timeoutSeconds = 180,
  double fixedStepSeconds = 1 / 60,
}) {
  strategy.reset();
  var elapsed = 0.0;
  while (elapsed < timeoutSeconds &&
      game.phase != GameplayPhase.victory &&
      game.phase != GameplayPhase.defeat) {
    strategy.tick(game, elapsed);
    game.update(fixedStepSeconds);
    elapsed += fixedStepSeconds;
  }
  game.setPrimaryHeld(false);
  game.setStrategyMovementOverride(null);
  final outcome = switch (game.phase) {
    GameplayPhase.victory => 'victory',
    GameplayPhase.defeat => 'defeat',
    _ => 'timeout',
  };
  return StrategyRunResult(
    strategyId: strategy.id,
    seed: seed,
    outcome: outcome,
    elapsedSeconds: elapsed,
    terminalWave: game.wave,
    actions: Map<String, int>.from(game.counters.toJson()),
    damageEvents: game.telemetry.damageEvents,
    breakOpportunities: game.telemetry.breakOpportunities,
  );
}

GameplayEnemy? _nearestAlive(GameplayGame game) {
  GameplayEnemy? nearest;
  var nearestDistance = double.infinity;
  for (final enemy in game.enemies) {
    if (!enemy.alive) continue;
    final distance = enemy.position.distanceToSquared(game.player.position);
    if (distance < nearestDistance) {
      nearest = enemy;
      nearestDistance = distance;
    }
  }
  return nearest;
}

GameplayEnemy? _densestNormalCluster(
  GameplayGame game,
  List<GameplayEnemy> alive,
) {
  GameplayEnemy? best;
  var bestCount = -1;
  var bestDistance = double.infinity;
  for (final candidate in alive) {
    if (candidate.elite) continue;
    var count = 0;
    for (final enemy in alive) {
      if (!enemy.elite &&
          enemy.position.distanceToSquared(candidate.position) <= 300 * 300) {
        count++;
      }
    }
    final distance = candidate.position.distanceToSquared(game.player.position);
    if (count > bestCount || (count == bestCount && distance < bestDistance)) {
      best = candidate;
      bestCount = count;
      bestDistance = distance;
    }
  }
  return best;
}
