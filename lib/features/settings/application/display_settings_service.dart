import 'package:shared_preferences/shared_preferences.dart';

import '../domain/display_settings.dart';

/// L1 显示设置持久化（照搬 [GameplaySettingsService] 体例）。
///
/// 用 SharedPreferences 而非 Isar:窗口模式/分辨率是端机本地偏好,
/// 不该进存档同步（用户拍板 2026-06-15）。
class DisplaySettingsService {
  static const _kFullscreen = 'display.fullscreen';
  static const _kSizePreset = 'display.sizePreset';

  Future<DisplaySettings> load() async {
    final p = await SharedPreferences.getInstance();
    return DisplaySettings(
      fullscreen: p.getBool(_kFullscreen) ?? false,
      sizePreset:
          WindowSizePreset.byStorageKey(p.getString(_kSizePreset) ?? '') ??
          WindowSizePreset.hd900,
    );
  }

  Future<void> save(DisplaySettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kFullscreen, s.fullscreen);
    await p.setString(_kSizePreset, s.sizePreset.storageKey);
  }
}
