import '../domain/display_settings.dart';
import 'display_settings_service.dart';
import 'window_controller.dart';

/// L1 显示设置编排：持久化 + 应用到窗口。
///
/// 纯编排逻辑（可测）;真窗口副作用委托给注入的 [WindowController]。
class DisplaySettingsController {
  const DisplaySettingsController(this._service, this._window);

  final DisplaySettingsService _service;
  final WindowController _window;

  /// 保存设置并即时应用到窗口（先存后用,失败不致设置丢失）。
  Future<void> apply(DisplaySettings next) async {
    await _service.save(next);
    await _window.apply(next);
  }

  /// 翻转全屏状态,持久化 + 应用,返回新设置（F11 快捷键用）。
  Future<DisplaySettings> toggleFullscreen(DisplaySettings current) async {
    final next = current.copyWith(fullscreen: !current.fullscreen);
    await apply(next);
    return next;
  }
}
