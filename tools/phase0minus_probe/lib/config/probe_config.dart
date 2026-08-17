import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

const scenarioAssetPath = 'assets/probe_scenarios.yaml';

final class ProbeConfig {
  ProbeConfig._({required this.raw, required this.checksum});

  final Map<String, Object?> raw;
  final String checksum;

  static Future<ProbeConfig> load() async {
    final source = await rootBundle.loadString(scenarioAssetPath);
    return ProbeConfig.parse(source);
  }

  static ProbeConfig parse(String source) {
    final document = loadYaml(source);
    if (document is! YamlMap) {
      throw const FormatException('Probe scenario root must be a map.');
    }
    final normalized = _normalize(document) as Map<String, Object?>;
    final config = ProbeConfig._(
      raw: normalized,
      checksum: sha256.convert(utf8.encode(source)).toString(),
    );
    config._validate();
    return config;
  }

  int get schemaVersion => integer('schema_version');
  int get fixedSeed => integer('fixed_seed');
  String get scriptVersion => string('script_version');
  String get collisionBackend => string('collision_backend');
  double get worldWidth => number('world.width');
  double get worldDepth => number('world.depth');
  double get gridCellSize => number('world.grid_cell_size');
  double get cameraTravel => number('world.camera_travel');
  double get warmupSeconds => number('timing.warmup_seconds');
  double get sampleSeconds => number('timing.sample_seconds');
  double get cooldownSeconds => number('timing.cooldown_seconds');
  double get burstIntervalSeconds => number('timing.burst_interval_seconds');
  double get respawnDelaySeconds => number('timing.respawn_delay_seconds');
  int get minimumValidFrames => integer('timing.minimum_valid_frames');
  double get hudUpdateHz => number('timing.hud_update_hz');
  int get frameBudgetUs => integer('thresholds.frame_budget_us');
  int get severeFrameUs => integer('thresholds.severe_frame_us');
  int get maximumSevereStreak => integer('thresholds.maximum_severe_streak');

  Map<String, Object?> section(String path) {
    final value = _at(path);
    if (value is! Map<String, Object?>) {
      throw FormatException('$path must be a map.');
    }
    return value;
  }

  double number(String path) {
    final value = _at(path);
    if (value is! num) throw FormatException('$path must be numeric.');
    return value.toDouble();
  }

  int integer(String path) {
    final value = _at(path);
    if (value is! int) throw FormatException('$path must be an integer.');
    return value;
  }

  String string(String path) {
    final value = _at(path);
    if (value is! String) throw FormatException('$path must be a string.');
    return value;
  }

  ProbeTier tier(String id) {
    final tiers = section('tiers');
    final value = tiers[id];
    if (value is! Map<String, Object?>) {
      throw FormatException('Unknown tier: $id');
    }
    return ProbeTier(
      id: id,
      normalEnemies: _mapInt(value, 'normal_enemies'),
      eliteEnemies: _mapInt(value, 'elite_enemies'),
      expectedPeakEffects: _mapInt(value, 'expected_peak_effects'),
    );
  }

  ProbeViewport viewport(String id) {
    final viewports = section('viewports');
    final value = viewports[id];
    if (value is! Map<String, Object?>) {
      throw FormatException('Unknown viewport: $id');
    }
    return ProbeViewport(
      id: id,
      width: _mapNum(value, 'width'),
      height: _mapNum(value, 'height'),
    );
  }

  Object? _at(String path) {
    Object? current = raw;
    for (final segment in path.split('.')) {
      if (current is! Map<String, Object?> || !current.containsKey(segment)) {
        throw FormatException('Missing scenario key: $path');
      }
      current = current[segment];
    }
    return current;
  }

  void _validate() {
    if (schemaVersion != 1) {
      throw FormatException('Unsupported schema version: $schemaVersion');
    }
    for (final id in const ['baseline_10', 'target_20_plus_1', 'stress_30']) {
      final value = tier(id);
      if (value.normalEnemies < 1 || value.eliteEnemies < 0) {
        throw FormatException('Invalid entity counts for $id');
      }
    }
    for (final id in const ['desktop_1280x720', 'desktop_1440x900']) {
      final value = viewport(id);
      if (value.width <= 0 || value.height <= 0) {
        throw FormatException('Invalid viewport: $id');
      }
    }
  }
}

final class ProbeTier {
  const ProbeTier({
    required this.id,
    required this.normalEnemies,
    required this.eliteEnemies,
    required this.expectedPeakEffects,
  });

  final String id;
  final int normalEnemies;
  final int eliteEnemies;
  final int expectedPeakEffects;

  int get totalEnemies => normalEnemies + eliteEnemies;
}

final class ProbeViewport {
  const ProbeViewport({
    required this.id,
    required this.width,
    required this.height,
  });

  final String id;
  final double width;
  final double height;
}

int _mapInt(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

double _mapNum(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! num) throw FormatException('$key must be numeric.');
  return value.toDouble();
}

Object? _normalize(Object? value) {
  if (value is YamlMap) {
    return <String, Object?>{
      for (final entry in value.entries)
        entry.key.toString(): _normalize(entry.value),
    };
  }
  if (value is YamlList) return value.map(_normalize).toList();
  return value;
}
