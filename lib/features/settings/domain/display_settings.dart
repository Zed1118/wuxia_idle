import 'package:flutter/widgets.dart';

/// L1 窗口分辨率预设（GDD 无关 · 端机本地显示偏好）。
///
/// 仅窗口模式生效;全屏时忽略尺寸。三档覆盖常见桌面分辨率。
enum WindowSizePreset {
  hd720,
  hd900,
  hd1080;

  /// 对应窗口逻辑尺寸。
  Size get size => switch (this) {
    WindowSizePreset.hd720 => const Size(1280, 720),
    WindowSizePreset.hd900 => const Size(1600, 900),
    WindowSizePreset.hd1080 => const Size(1920, 1080),
  };

  /// SharedPreferences 持久化键（= enum name）。
  String get storageKey => name;

  /// 从持久化键反查;未知键返回 null（调用方退默认）。
  static WindowSizePreset? byStorageKey(String key) {
    for (final p in values) {
      if (p.name == key) return p;
    }
    return null;
  }
}

/// L1 显示设置值对象。SharedPreferences 持久化（不进 Isar 存档）。
@immutable
class DisplaySettings {
  const DisplaySettings({
    this.fullscreen = false,
    this.sizePreset = WindowSizePreset.hd900,
  });

  final bool fullscreen;
  final WindowSizePreset sizePreset;

  DisplaySettings copyWith({bool? fullscreen, WindowSizePreset? sizePreset}) =>
      DisplaySettings(
        fullscreen: fullscreen ?? this.fullscreen,
        sizePreset: sizePreset ?? this.sizePreset,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DisplaySettings &&
          other.fullscreen == fullscreen &&
          other.sizePreset == sizePreset;

  @override
  int get hashCode => Object.hash(fullscreen, sizePreset);
}
