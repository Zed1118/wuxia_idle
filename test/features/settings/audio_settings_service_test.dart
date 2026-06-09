import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuxia_idle/features/settings/application/audio_settings_service.dart';
import 'package:wuxia_idle/features/settings/domain/audio_settings.dart';

void main() {
  test('空 prefs → 返回默认值', () async {
    SharedPreferences.setMockInitialValues({});
    final s = await AudioSettingsService().load();
    expect(s.masterVolume, 0.8);
    expect(s.bgmVolume, 0.7);
    expect(s.sfxVolume, 0.9);
    expect(s.muted, false);
  });

  test('save → load 往返一致', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = AudioSettingsService();
    const written = AudioSettings(
      masterVolume: 0.5,
      bgmVolume: 0.4,
      sfxVolume: 0.3,
      muted: true,
    );
    await svc.save(written);
    final read = await svc.load();
    expect(read, written);
  });
}
