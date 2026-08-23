/// 主线群怪波次配置（`data/numbers.yaml` 的 `mainline_wave` 段）。
///
/// 所有波次数量、每波 `count` 和小怪派生比例均从 YAML 读取；空配置只为
/// 测试 fixture 保留旧单波行为，生产 numbers 必须显式提供两种 profile。
final class MainlineWaveDef {
  final MainlineWaveProfile ordinary;
  final MainlineWaveProfile boss;
  final MainlineWaveIntermission intermission;

  const MainlineWaveDef({
    required this.ordinary,
    required this.boss,
    required this.intermission,
  });

  factory MainlineWaveDef.empty() => const MainlineWaveDef(
    ordinary: MainlineWaveProfile.empty(),
    boss: MainlineWaveProfile.empty(),
    intermission: MainlineWaveIntermission.defaults(),
  );

  factory MainlineWaveDef.fromYaml(Map<String, dynamic>? y) {
    if (y == null) return MainlineWaveDef.empty();
    final result = MainlineWaveDef(
      ordinary: MainlineWaveProfile.fromYaml(y['ordinary'] as Map?),
      boss: MainlineWaveProfile.fromYaml(y['boss'] as Map?),
      intermission: MainlineWaveIntermission.fromYaml(
        y['wave_intermission'] as Map?,
      ),
    );
    result.validate();
    return result;
  }

  bool get isEnabled => ordinary.enabled && boss.enabled;

  MainlineWaveProfile profileFor({required bool isBossStage}) =>
      isBossStage ? boss : ordinary;

  void validate() {
    if (!ordinary.enabled && !boss.enabled) return;
    if (!ordinary.enabled || !boss.enabled) {
      throw StateError('mainline_wave 必须同时提供 ordinary 与 boss profile');
    }
    ordinary.validate(label: 'ordinary', requireBossFinalCount: false);
    boss.validate(label: 'boss', requireBossFinalCount: true);
    intermission.validate();
  }
}

final class MainlineWaveProfile {
  final List<int> waveEnemyCounts;
  final int bossFinalEnemyCount;
  final double hpMultiplier;
  final double attackMultiplier;
  final double outputMultiplier;
  final double speedMultiplier;

  const MainlineWaveProfile({
    required this.waveEnemyCounts,
    required this.bossFinalEnemyCount,
    required this.hpMultiplier,
    required this.attackMultiplier,
    required this.outputMultiplier,
    required this.speedMultiplier,
  });

  const MainlineWaveProfile.empty()
    : waveEnemyCounts = const [],
      bossFinalEnemyCount = 0,
      hpMultiplier = 1.0,
      attackMultiplier = 1.0,
      outputMultiplier = 1.0,
      speedMultiplier = 1.0;

  factory MainlineWaveProfile.fromYaml(Map? y) {
    if (y == null) return const MainlineWaveProfile.empty();
    return MainlineWaveProfile(
      waveEnemyCounts: ((y['waves'] as List?) ?? const [])
          .map((value) => ((value as Map)['count'] as num).toInt())
          .toList(growable: false),
      bossFinalEnemyCount: (y['boss_final_enemy_count'] as num?)?.toInt() ?? 0,
      hpMultiplier: (y['hp_multiplier'] as num?)?.toDouble() ?? 0.0,
      attackMultiplier: (y['attack_multiplier'] as num?)?.toDouble() ?? 0.0,
      outputMultiplier: (y['output_multiplier'] as num?)?.toDouble() ?? 0.0,
      speedMultiplier: (y['speed_multiplier'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool get enabled => waveEnemyCounts.isNotEmpty;

  int get waveCount =>
      waveEnemyCounts.length + (bossFinalEnemyCount > 0 ? 1 : 0);

  int get totalEnemyCount =>
      waveEnemyCounts.fold(0, (total, count) => total + count) +
      bossFinalEnemyCount;

  void validate({required String label, required bool requireBossFinalCount}) {
    if (!enabled) {
      throw StateError('mainline_wave.$label.waves 不得为空');
    }
    if (waveEnemyCounts.any((count) => count < 1)) {
      throw StateError('mainline_wave.$label 每波敌人数必须 >= 1');
    }
    if (requireBossFinalCount && bossFinalEnemyCount != 1) {
      throw StateError('mainline_wave.boss.boss_final_enemy_count 必须为 1');
    }
    if (!requireBossFinalCount && bossFinalEnemyCount != 0) {
      throw StateError('mainline_wave.ordinary.boss_final_enemy_count 必须为 0');
    }
    for (final entry in <String, double>{
      'hp_multiplier': hpMultiplier,
      'attack_multiplier': attackMultiplier,
      'output_multiplier': outputMultiplier,
      'speed_multiplier': speedMultiplier,
    }.entries) {
      if (entry.value <= 0 || entry.value > 1) {
        throw StateError('mainline_wave.$label.${entry.key} 必须 ∈ (0, 1]');
      }
    }
  }
}

/// 主线波间规则复用 Phase 0A 的同核 intermission 语义。
final class MainlineWaveIntermission {
  final bool resetActionPoint;
  final bool preserveHp;
  final bool preserveCooldowns;
  final double intermissionSeconds;
  final double aliveIfRecoveryPct;

  const MainlineWaveIntermission({
    required this.resetActionPoint,
    required this.preserveHp,
    required this.preserveCooldowns,
    required this.intermissionSeconds,
    required this.aliveIfRecoveryPct,
  });

  const MainlineWaveIntermission.defaults()
    : resetActionPoint = true,
      preserveHp = true,
      preserveCooldowns = true,
      intermissionSeconds = 0.0,
      aliveIfRecoveryPct = 0.25;

  factory MainlineWaveIntermission.fromYaml(Map? y) {
    final map = y == null
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(y);
    if (y != null && !map.containsKey('preserve_hp')) {
      throw StateError('mainline_wave.wave_intermission.preserve_hp 必须显式配置');
    }
    return MainlineWaveIntermission(
      resetActionPoint: map['reset_action_point'] as bool? ?? true,
      preserveHp: map['preserve_hp'] as bool? ?? true,
      preserveCooldowns: map['preserve_cooldowns'] as bool? ?? true,
      intermissionSeconds:
          (map['intermission_seconds'] as num?)?.toDouble() ?? 0.0,
      aliveIfRecoveryPct:
          (map['alive_if_recovery_pct'] as num?)?.toDouble() ?? 0.0,
    );
  }

  void validate() {
    if (aliveIfRecoveryPct < 0 || aliveIfRecoveryPct > 1) {
      throw StateError(
        'mainline_wave.wave_intermission.alive_if_recovery_pct 必须 ∈ [0, 1]',
      );
    }
    if (!intermissionSeconds.isFinite || intermissionSeconds < 0) {
      throw StateError(
        'mainline_wave.wave_intermission.intermission_seconds 必须为非负有限秒数',
      );
    }
  }
}
