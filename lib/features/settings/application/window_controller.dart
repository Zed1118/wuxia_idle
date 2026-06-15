import 'package:window_manager/window_manager.dart';

import '../domain/display_settings.dart';

/// 窗口副作用抽象（platform channel 隔离层）。
///
/// 测试注入 fake;生产用 [WindowManagerController] 调真 window_manager。
abstract class WindowController {
  Future<void> apply(DisplaySettings settings);
}

/// 生产实现:把 [DisplaySettings] 落到真实窗口（window_manager 0.5.x）。
///
/// 全屏时只切 fullscreen（忽略尺寸）;窗口模式时设尺寸并居中。
/// platform channel 薄封装,逻辑全在 [DisplaySettingsController]/纯函数层（已测）。
class WindowManagerController implements WindowController {
  const WindowManagerController();

  @override
  Future<void> apply(DisplaySettings settings) async {
    await windowManager.setFullScreen(settings.fullscreen);
    if (!settings.fullscreen) {
      await windowManager.setSize(settings.sizePreset.size);
      await windowManager.center();
    }
  }
}
