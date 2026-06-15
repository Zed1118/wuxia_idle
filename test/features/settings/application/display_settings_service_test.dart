import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuxia_idle/features/settings/application/display_settings_service.dart';
import 'package:wuxia_idle/features/settings/domain/display_settings.dart';

/// L1 显示设置 SharedPreferences 持久化（照搬 GameplaySettingsService 体例）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('空 prefs → 默认（窗口模式 + hd900）', () async {
    final s = await DisplaySettingsService().load();
    expect(s.fullscreen, isFalse);
    expect(s.sizePreset, WindowSizePreset.hd900);
  });

  test('save → load round-trip 全字段', () async {
    await DisplaySettingsService().save(
      const DisplaySettings(
        fullscreen: true,
        sizePreset: WindowSizePreset.hd1080,
      ),
    );
    final s = await DisplaySettingsService().load();
    expect(s.fullscreen, isTrue);
    expect(s.sizePreset, WindowSizePreset.hd1080);
  });

  test('改分辨率档持久化，全屏保持默认', () async {
    await DisplaySettingsService().save(
      const DisplaySettings(sizePreset: WindowSizePreset.hd720),
    );
    final s = await DisplaySettingsService().load();
    expect(s.sizePreset, WindowSizePreset.hd720);
    expect(s.fullscreen, isFalse);
  });
}
