/// 半手动战斗 P0 步骤5-B:全局玩法设置值对象。
///
/// 设置≠存档(走 SharedPreferences,与 Isar 隔离,沿 [AudioSettings] 体例)。
class GameplaySettings {
  const GameplaySettings({this.autoPlayDefault = true});

  /// 已通关关卡默认是否走自动战斗(replay / 迁移豁免 fallback)。
  /// 用户拍板#3(2026-06-13)默认 true;每关可经
  /// `BattleReplayRecord.autoPlayOverride` 覆盖(每关记忆)。
  final bool autoPlayDefault;

  GameplaySettings copyWith({bool? autoPlayDefault}) => GameplaySettings(
        autoPlayDefault: autoPlayDefault ?? this.autoPlayDefault,
      );
}
