/// 战斗屏播放速度偏好。仅影响 UI Timer 的播放节拍,不改变战斗结算。
enum BattlePlaybackSpeed {
  relaxed,
  normal,
  brisk,
  rapid;

  String get storageKey => name;

  double get intervalFactor => switch (this) {
    BattlePlaybackSpeed.relaxed => 1.25,
    BattlePlaybackSpeed.normal => 1.0,
    BattlePlaybackSpeed.brisk => 0.75,
    BattlePlaybackSpeed.rapid => 0.5,
  };

  static BattlePlaybackSpeed? byStorageKey(String key) {
    for (final s in values) {
      if (s.name == key) return s;
    }
    return null;
  }
}

/// 全局文字密度偏好。当前作为本机舒适性偏好集中持久化,供展示层逐步消费。
enum TextDensityPreference {
  comfortable,
  standard,
  compact;

  String get storageKey => name;

  static TextDensityPreference? byStorageKey(String key) {
    for (final d in values) {
      if (d.name == key) return d;
    }
    return null;
  }
}

/// 全局玩法设置值对象。
///
/// 设置≠存档(走 SharedPreferences,与 Isar 隔离,沿 [AudioSettings] 体例)。
class GameplaySettings {
  const GameplaySettings({
    this.autoPlayDefault = true,
    this.battlePlaybackSpeed = BattlePlaybackSpeed.normal,
    this.textDensity = TextDensityPreference.standard,
    this.reduceFlashing = false,
  });

  /// 战斗交互重做 Phase 3:全局默认战斗模式。`true` = 纯挂机自动 / `false` =
  /// 允许拖招干预。默认 true;每关可经 per-stage override 覆盖(每关记忆,见
  /// `stage_auto_play_pref.dart`)。
  final bool autoPlayDefault;
  final BattlePlaybackSpeed battlePlaybackSpeed;
  final TextDensityPreference textDensity;
  final bool reduceFlashing;

  GameplaySettings copyWith({
    bool? autoPlayDefault,
    BattlePlaybackSpeed? battlePlaybackSpeed,
    TextDensityPreference? textDensity,
    bool? reduceFlashing,
  }) => GameplaySettings(
    autoPlayDefault: autoPlayDefault ?? this.autoPlayDefault,
    battlePlaybackSpeed: battlePlaybackSpeed ?? this.battlePlaybackSpeed,
    textDensity: textDensity ?? this.textDensity,
    reduceFlashing: reduceFlashing ?? this.reduceFlashing,
  );

  int scaledBattleIntervalMs(int baseMs) {
    return (baseMs * battlePlaybackSpeed.intervalFactor).round().clamp(
      50,
      3000,
    );
  }
}
