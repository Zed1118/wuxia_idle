import 'package:shared_preferences/shared_preferences.dart';

import '../domain/gameplay_settings.dart';

/// 玩法设置持久化(shared_preferences,key 前缀 gameplay.)。
/// 设置≠存档,与 Isar 隔离(沿 [AudioSettingsService] 体例)。
class GameplaySettingsService {
  static const _kAutoPlay = 'gameplay.autoPlayDefault';

  Future<GameplaySettings> load() async {
    final p = await SharedPreferences.getInstance();
    return GameplaySettings(
      autoPlayDefault: p.getBool(_kAutoPlay) ?? true,
    );
  }

  Future<void> save(GameplaySettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kAutoPlay, s.autoPlayDefault);
  }
}
