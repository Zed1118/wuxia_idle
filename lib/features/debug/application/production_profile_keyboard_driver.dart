import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../../battle/domain/phase0a/phase0a_wave.dart';
import '../../battle/presentation/phase0a/phase0a_battle_controller.dart';

enum ProductionProfileKeyboardStrategy { baseline, survive }

/// Profile-only keyboard automation of an already mounted production battle.
///
/// These are synthetic Framework keyboard events, not physical OS input. They
/// enter at the same KeyData boundary as WidgetTester.sendKeyDownEvent, update
/// HardwareKeyboard, and pass through the real Focus/Phase0aBattleScreen handler.
/// This driver never enqueues commands, advances the simulation, or writes state.
final class ProductionProfileKeyboardDriver {
  ProductionProfileKeyboardDriver({
    required this.controller,
    required this.basicAttackRange,
    required this.isForeground,
    this.strategy = ProductionProfileKeyboardStrategy.baseline,
  }) {
    if (!basicAttackRange.isFinite || basicAttackRange <= 0) {
      throw ArgumentError.value(basicAttackRange, 'basicAttackRange');
    }
  }

  final Phase0aBattleController controller;
  final double basicAttackRange;
  final bool Function() isForeground;
  final ProductionProfileKeyboardStrategy strategy;
  final _clock = Stopwatch();
  final _held = <LogicalKeyboardKey>{};
  Timer? _activityTimer;
  bool _running = false;
  bool _disposed = false;
  int _lastTick = -1;
  int _entryTick = 0;
  int _nextClearAttempt = 0;
  int _nextSkillAttempt = 5;
  int _decisions = 0;
  int _downEvents = 0;
  int _upEvents = 0;
  int _externalKeyConflicts = 0;

  static Map<String, Object?> configurationFor({
    required ProductionProfileKeyboardStrategy strategy,
    required double fixedDeltaSeconds,
  }) => {
    'strategy': strategy.name,
    'input_source': 'synthetic_framework_key_data',
    'physical_os_input': false,
    'direct_command_injection': false,
    'decision_cadence': 'once_per_new_simulation_tick',
    'fixed_delta_seconds': fixedDeltaSeconds,
  };

  Map<String, Object?> get configurationMetadata => configurationFor(
    strategy: strategy,
    fixedDeltaSeconds: controller.fixedDeltaSeconds,
  );

  Map<String, Object?> get metadata => {
    ...configurationMetadata,
    'running': _running,
    'decisions': _decisions,
    'key_down_events': _downEvents,
    'key_up_events': _upEvents,
    'external_key_conflicts': _externalKeyConflicts,
    'held_key_ids': _held.map((key) => key.keyId).toList()..sort(),
  };

  /// Call only after the production battle Focus has mounted and gained focus.
  void start() {
    if (_disposed) throw StateError('Keyboard driver is disposed');
    if (_running) return;
    _running = true;
    _entryTick = controller.state.tick;
    _lastTick = -1;
    _nextClearAttempt = 0;
    _nextSkillAttempt = 5;
    _clock.start();
    controller.addListener(_observe);
    // A backgrounded Host may stop ticking. Still release our keys promptly.
    _activityTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _observe(),
    );
    _observe();
  }

  void refreshForeground() => _observe();

  void stop() {
    if (_running) controller.removeListener(_observe);
    _running = false;
    _activityTimer?.cancel();
    _activityTimer = null;
    _keys({});
    _clock.stop();
  }

  void dispose() {
    if (_disposed) return;
    stop();
    _disposed = true;
  }

  void _observe() {
    if (!_running) return;
    if (controller.outcome != Phase0aBattleOutcome.ongoing) {
      stop();
      return;
    }
    if (!isForeground()) {
      _keys({});
      return;
    }
    final state = controller.state;
    if (state.tick == _lastTick) return;
    _lastTick = state.tick;
    _decisions++;
    final tick = state.tick - _entryTick;
    final p = state.player.position;
    final enemies = state.enemies.where((enemy) => enemy.isAlive).toList()
      ..sort(
        (a, b) => (a.position - p).lengthSquared.compareTo(
          (b.position - p).lengthSquared,
        ),
      );
    final close =
        enemies.isNotEmpty && (enemies.first.position - p).length < 180;
    final baseline = strategy == ProductionProfileKeyboardStrategy.baseline;
    final desired = <LogicalKeyboardKey>{if (baseline) LogicalKeyboardKey.keyJ};
    // Baseline thresholds/cadence are intentionally copied from the approved
    // driveOnboardingBattle baseline policy. They control keys, not game values.
    if (enemies.isNotEmpty) {
      var direction = enemies.first.position - p;
      final distance = direction.length;
      final retreat = baseline
          ? distance < 130 && state.player.attackCooldownRemaining > 0
          : close;
      if (retreat) direction = direction * -1;
      var move = baseline
          ? retreat || distance > basicAttackRange * .9
          : retreat;
      if (p.x.abs() > 570 || p.y.abs() > 220) {
        direction = p * -1;
        move = true;
      }
      if (move) {
        if (direction.x.abs() > 10) {
          desired.add(
            direction.x > 0 ? LogicalKeyboardKey.keyD : LogicalKeyboardKey.keyA,
          );
        }
        if (direction.y.abs() > 10) {
          desired.add(
            direction.y > 0 ? LogicalKeyboardKey.keyS : LogicalKeyboardKey.keyW,
          );
        }
      }
    } else if (baseline &&
        controller.checkpointObjectiveProgress?.remainingEnemies == 0) {
      desired.add(LogicalKeyboardKey.keyD);
    }
    _keys(desired);
    if (baseline &&
        close &&
        state.player.basicAction?.timeline.firstEffectEmitted == true) {
      if (tick >= _nextClearAttempt) {
        _tap(LogicalKeyboardKey.keyR);
        _nextClearAttempt = tick + 10;
      } else if (tick >= _nextSkillAttempt) {
        _tap(LogicalKeyboardKey.digit1);
        _nextSkillAttempt = tick + 10;
      }
    }
    if (close && state.player.defenseCooldownRemaining == 0) {
      _tap(LogicalKeyboardKey.space);
    }
  }

  void _keys(Set<LogicalKeyboardKey> desired) {
    for (final key in _held.difference(desired).toList()) {
      _up(key);
    }
    for (final key in desired.difference(_held).toList()) {
      _down(key);
    }
  }

  void _tap(LogicalKeyboardKey key) {
    if (_down(key)) _up(key);
  }

  bool _down(LogicalKeyboardKey key) {
    if (HardwareKeyboard.instance.logicalKeysPressed.contains(key)) {
      _externalKeyConflicts++;
      return false;
    }
    _held.add(key);
    _dispatch(key, down: true);
    _downEvents++;
    return true;
  }

  void _up(LogicalKeyboardKey key) {
    _held.remove(key);
    // A native focus-loss synchronization may already have released this key.
    if (!HardwareKeyboard.instance.logicalKeysPressed.contains(key)) return;
    _dispatch(key, down: false);
    _upEvents++;
  }

  void _dispatch(LogicalKeyboardKey key, {required bool down}) {
    final physical = switch (key) {
      LogicalKeyboardKey.keyA => PhysicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyD => PhysicalKeyboardKey.keyD,
      LogicalKeyboardKey.keyW => PhysicalKeyboardKey.keyW,
      LogicalKeyboardKey.keyS => PhysicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyJ => PhysicalKeyboardKey.keyJ,
      LogicalKeyboardKey.keyR => PhysicalKeyboardKey.keyR,
      LogicalKeyboardKey.digit1 => PhysicalKeyboardKey.digit1,
      LogicalKeyboardKey.space => PhysicalKeyboardKey.space,
      _ => throw ArgumentError.value(key, 'key'),
    };
    // Current Flutter's Focus manager consumes KeyMessage, so calling only
    // HardwareKeyboard.handleKeyEvent would skip the production Focus handler.
    // Synthesized KeyData dispatches immediately without a following raw event.
    // ignore: deprecated_member_use
    ServicesBinding.instance.keyEventManager.handleKeyData(
      ui.KeyData(
        type: down ? ui.KeyEventType.down : ui.KeyEventType.up,
        physical: physical.usbHidUsage,
        logical: key.keyId,
        character: down ? key.keyLabel.toLowerCase() : null,
        timeStamp: _clock.elapsed,
        synthesized: true,
      ),
    );
  }
}
