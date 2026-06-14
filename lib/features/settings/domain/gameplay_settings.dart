/// 全局玩法设置值对象。
///
/// 设置≠存档(走 SharedPreferences,与 Isar 隔离,沿 [AudioSettings] 体例)。
class GameplaySettings {
  const GameplaySettings({this.autoPlayDefault = true});

  /// 战斗交互重做 Phase 3:全局默认战斗模式。`true` = 纯挂机自动 / `false` =
  /// 允许拖招干预。默认 true;每关可经 per-stage override 覆盖(每关记忆,见
  /// `stage_auto_play_pref.dart`)。
  final bool autoPlayDefault;

  GameplaySettings copyWith({bool? autoPlayDefault}) => GameplaySettings(
        autoPlayDefault: autoPlayDefault ?? this.autoPlayDefault,
      );
}
