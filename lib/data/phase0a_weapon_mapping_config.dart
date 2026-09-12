import '../core/domain/enums.dart';
import '../features/battle/domain/phase0a/action_timeline.dart';

/// Approved M0 B/C values. Missing sections are handled by the arena loader;
/// a present section must describe every weapon without fallback values.
final class Phase0aWeaponMappingConfig {
  Phase0aWeaponMappingConfig._({
    required this.powerCostAnchor,
    required this.ultimateCostAnchor,
    required this.killQiGain,
    required this.killQiWindowCap,
    required Map<WeaponArchetype, Phase0aWeaponResourceProfile> profiles,
  }) : _profiles = Map.unmodifiable(profiles);

  final int powerCostAnchor;
  final int ultimateCostAnchor;
  final int killQiGain;
  final int killQiWindowCap;
  final Map<WeaponArchetype, Phase0aWeaponResourceProfile> _profiles;

  Phase0aWeaponResourceProfile profileFor(WeaponArchetype weapon) =>
      _profiles[weapon] ??
      (throw StateError('Missing M0 weapon mapping: ${weapon.name}'));

  factory Phase0aWeaponMappingConfig.fromYaml(Object? raw) {
    final values = _map(raw, 'weapon_mapping', {
      'power_cost_anchor',
      'ultimate_cost_anchor',
      'kill_gain',
      'kill_window_cap',
      'weapons',
    });
    final weapons = _map(values['weapons'], 'weapon_mapping.weapons', {
      for (final weapon in WeaponArchetype.values) weapon.name,
    });
    return Phase0aWeaponMappingConfig._(
      powerCostAnchor: _integer(values, 'power_cost_anchor', positive: true),
      ultimateCostAnchor: _integer(
        values,
        'ultimate_cost_anchor',
        positive: true,
      ),
      killQiGain: _integer(values, 'kill_gain'),
      killQiWindowCap: _integer(values, 'kill_window_cap'),
      profiles: {
        for (final weapon in WeaponArchetype.values)
          weapon: Phase0aWeaponResourceProfile._fromYaml(
            weapons[weapon.name],
            weapon.name,
          ),
      },
    );
  }
}

final class Phase0aWeaponResourceProfile {
  const Phase0aWeaponResourceProfile._({
    required this.timeline,
    required this.capacity,
    required this.opening,
    required this.basicGain,
    required this.powerCost,
    required this.ultimateCost,
  });

  final ActionTimelineConfig timeline;

  /// Candidate base values only. Runtime capacity/opening remain the already
  /// derived CombatantSnapshot values, including mind and content modifiers.
  final int capacity;
  final int opening;
  final int basicGain;
  final int powerCost;
  final int ultimateCost;

  factory Phase0aWeaponResourceProfile._fromYaml(Object? raw, String weapon) {
    final values = _map(raw, 'weapon_mapping.weapons.$weapon', {
      'timeline',
      'capacity',
      'opening',
      'basic_gain',
      'power_cost',
      'ultimate_cost',
    });
    final timeline = _map(values['timeline'], '$weapon.timeline', {
      'windup_ticks',
      'active_ticks',
      'recovery_ticks',
      'first_effect_tick',
      'cancel_window_start_tick',
      'cancel_window_end_tick',
      'interrupted_cooldown_ticks',
      'cancelled_cooldown_ticks',
      'failed_cooldown_ticks',
    });
    final capacity = _integer(values, 'capacity', positive: true);
    final opening = _integer(values, 'opening');
    if (opening > capacity) {
      throw ArgumentError('M0 $weapon opening must not exceed capacity');
    }
    return Phase0aWeaponResourceProfile._(
      timeline: ActionTimelineConfig(
        windupTicks: _integer(timeline, 'windup_ticks'),
        activeTicks: _integer(timeline, 'active_ticks', positive: true),
        recoveryTicks: _integer(timeline, 'recovery_ticks'),
        firstEffectTick: _integer(timeline, 'first_effect_tick'),
        cancelWindowStartTick: _integer(timeline, 'cancel_window_start_tick'),
        cancelWindowEndTick: _integer(timeline, 'cancel_window_end_tick'),
        interruptedCooldownTicks: _integer(
          timeline,
          'interrupted_cooldown_ticks',
        ),
        cancelledCooldownTicks: _integer(timeline, 'cancelled_cooldown_ticks'),
        failedCooldownTicks: _integer(timeline, 'failed_cooldown_ticks'),
      ),
      capacity: capacity,
      opening: opening,
      basicGain: _integer(values, 'basic_gain'),
      powerCost: _integer(values, 'power_cost', positive: true),
      ultimateCost: _integer(values, 'ultimate_cost', positive: true),
    );
  }
}

Map<String, dynamic> _map(Object? raw, String name, Set<String> keys) {
  if (raw is! Map ||
      raw.keys.any((key) => key is! String || !keys.contains(key)) ||
      raw.length != keys.length ||
      !keys.every(raw.containsKey)) {
    throw ArgumentError('$name must contain exactly ${keys.join(', ')}');
  }
  return raw.cast<String, dynamic>();
}

int _integer(Map<String, dynamic> values, String key, {bool positive = false}) {
  final value = values[key];
  if (value is! int || value < 0 || (positive && value == 0)) {
    throw ArgumentError.value(
      value,
      key,
      'must be a ${positive ? 'positive' : 'nonnegative'} integer',
    );
  }
  return value;
}
