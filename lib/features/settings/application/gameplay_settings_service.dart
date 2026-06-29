import 'package:shared_preferences/shared_preferences.dart';

import '../domain/gameplay_settings.dart';

/// 玩法设置持久化(shared_preferences,key 前缀 gameplay.)。
/// 设置≠存档,与 Isar 隔离(沿 [AudioSettingsService] 体例)。
class GameplaySettingsService {
  static const _kAutoPlay = 'gameplay.autoPlayDefault';
  static const _kBattlePlaybackSpeed = 'gameplay.battlePlaybackSpeed';
  static const _kTextDensity = 'gameplay.textDensity';
  static const _kReduceFlashing = 'gameplay.reduceFlashing';

  Future<GameplaySettings> load() async {
    final p = await SharedPreferences.getInstance();
    return GameplaySettings(
      autoPlayDefault: p.getBool(_kAutoPlay) ?? true,
      battlePlaybackSpeed:
          BattlePlaybackSpeed.byStorageKey(
            p.getString(_kBattlePlaybackSpeed) ?? '',
          ) ??
          BattlePlaybackSpeed.normal,
      textDensity:
          TextDensityPreference.byStorageKey(
            p.getString(_kTextDensity) ?? '',
          ) ??
          TextDensityPreference.standard,
      reduceFlashing: p.getBool(_kReduceFlashing) ?? false,
    );
  }

  Future<void> save(GameplaySettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kAutoPlay, s.autoPlayDefault);
    await p.setString(_kBattlePlaybackSpeed, s.battlePlaybackSpeed.storageKey);
    await p.setString(_kTextDensity, s.textDensity.storageKey);
    await p.setBool(_kReduceFlashing, s.reduceFlashing);
  }
}
