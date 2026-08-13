import 'dart:io';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phase0minus_probe/config/probe_config.dart';
import 'package:phase0minus_probe/gameplay/combat_rules.dart';

void main() {
  test('diagonal movement is normalized', () {
    final movement = normalizedMovement(
      left: false,
      right: true,
      up: true,
      down: false,
    );
    expect(movement.length, closeTo(1, 0.0001));
    expect(movement.x, closeTo(math.sqrt1_2, 0.0001));
    expect(movement.y, closeTo(-math.sqrt1_2, 0.0001));
  });

  test('basic attack respects both range and aim arc', () {
    final origin = Vector2.zero();
    final aim = Vector2(1, 0);
    expect(
      isInsideAimArc(
        origin: origin,
        aimDirection: aim,
        target: Vector2(100, 20),
        range: 145,
        halfArcRadians: 0.72,
      ),
      isTrue,
    );
    expect(
      isInsideAimArc(
        origin: origin,
        aimDirection: aim,
        target: Vector2(-100, 0),
        range: 145,
        halfArcRadians: 0.72,
      ),
      isFalse,
    );
    expect(
      isInsideAimArc(
        origin: origin,
        aimDirection: aim,
        target: Vector2(150, 0),
        range: 145,
        halfArcRadians: 0.72,
      ),
      isFalse,
    );
  });

  test('gather stops enemies at a readable ring around the player', () {
    final destination = gatherDestination(
      origin: Vector2(10, 20),
      enemy: Vector2(410, 20),
      targetRadius: 88,
    );
    expect(destination.x, closeTo(98, 0.0001));
    expect(destination.y, closeTo(20, 0.0001));
  });

  test('break window is only the final telegraph segment', () {
    const tuning = GameplayTuning();
    expect(isBreakWindow(telegraphRemaining: 1.2, tuning: tuning), isFalse);
    expect(isBreakWindow(telegraphRemaining: 0.5, tuning: tuning), isTrue);
    expect(isBreakWindow(telegraphRemaining: 0, tuning: tuning), isFalse);
  });

  test('session counters preserve action identity and chain peak', () {
    final counters = GameplayCounters();
    counters
      ..record(GameplayAction.basic)
      ..record(GameplayAction.dash)
      ..record(GameplayAction.gather)
      ..record(GameplayAction.clear)
      ..record(GameplayAction.breakSuccess)
      ..recordKill()
      ..recordKill()
      ..breakChain()
      ..recordKill();

    expect(counters.toJson(), {
      'basic_uses': 1,
      'dash_uses': 1,
      'gather_uses': 1,
      'clear_uses': 1,
      'break_successes': 1,
      'kills': 3,
      'maximum_chain': 2,
    });
  });

  test('greybox tuning is loaded from the isolated scenario asset', () {
    final config = ProbeConfig.parse(
      File('assets/probe_scenarios.yaml').readAsStringSync(),
    );
    final tuning = GameplayTuning.fromConfig(config);

    expect(tuning.basicInterval, 0.30);
    expect(tuning.basicDamage, 34);
    expect(tuning.basicQiGain, 5);
    expect(tuning.dashCooldown, 3.2);
    expect(tuning.gatherCooldown, 6.5);
    expect(tuning.clearQiCost, 60);
    expect(tuning.eliteBreakThreshold, 2);
  });

  test('Q to R kills a normal while naked R does not', () {
    const tuning = GameplayTuning();
    expect(
      normalClearDamage(
        imbalanced: false,
        tuning: tuning,
        imbalancedMultiplier: 1.7,
      ),
      lessThan(tuning.normalHealth),
    );
    expect(
      normalClearDamage(
        imbalanced: true,
        tuning: tuning,
        imbalancedMultiplier: 1.7,
      ),
      greaterThanOrEqualTo(tuning.normalHealth),
    );
  });

  test('one basic cast grants qi once regardless of target count', () {
    const tuning = GameplayTuning();
    expect(
      qiAfterBasicCast(
        currentQi: 40,
        hitAnyTarget: true,
        capacity: 100,
        tuning: tuning,
      ),
      45,
    );
    expect(
      qiAfterBasicCast(
        currentQi: 40,
        hitAnyTarget: false,
        capacity: 100,
        tuning: tuning,
      ),
      40,
    );
  });
}
