import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuxia_idle/features/settings/application/display_settings_controller.dart';
import 'package:wuxia_idle/features/settings/application/display_settings_service.dart';
import 'package:wuxia_idle/features/settings/application/window_controller.dart';
import 'package:wuxia_idle/features/settings/domain/display_settings.dart';

/// fake 窗口副作用层:记录被应用的设置,不碰真 window_manager platform channel。
class _FakeWindowController implements WindowController {
  DisplaySettings? lastApplied;
  int applyCount = 0;

  @override
  Future<void> apply(DisplaySettings settings) async {
    lastApplied = settings;
    applyCount++;
  }
}

/// L1 DisplaySettingsController 编排：持久化 + 应用到窗口。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('apply：先持久化 SharedPreferences，再应用到窗口', () async {
    final fake = _FakeWindowController();
    final ctl = DisplaySettingsController(DisplaySettingsService(), fake);
    const next = DisplaySettings(
      fullscreen: true,
      sizePreset: WindowSizePreset.hd1080,
    );

    await ctl.apply(next);

    final loaded = await DisplaySettingsService().load();
    expect(loaded.fullscreen, isTrue);
    expect(loaded.sizePreset, WindowSizePreset.hd1080);
    expect(fake.lastApplied, next);
    expect(fake.applyCount, 1);
  });

  test('toggleFullscreen：翻转当前全屏 + 持久化 + 应用，返回新设置', () async {
    final fake = _FakeWindowController();
    final ctl = DisplaySettingsController(DisplaySettingsService(), fake);

    final result = await ctl.toggleFullscreen(
      const DisplaySettings(fullscreen: false),
    );

    expect(result.fullscreen, isTrue);
    expect(fake.lastApplied?.fullscreen, isTrue);
    final loaded = await DisplaySettingsService().load();
    expect(loaded.fullscreen, isTrue);
  });
}
