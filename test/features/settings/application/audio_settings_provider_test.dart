import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wuxia_idle/features/settings/application/audio_settings_provider.dart';

/// `audioSettingsProvider` 行为测（2026-07-19 夜批 coverage 补强，
/// 基线 3/15 行）。
///
/// 真 ProviderContainer + mock SharedPreferences + 默认 SilentAudioBackend
/// （widget 测安全），钉「改动即存 + 即应用」语义：
///   - build:空偏好 → spec §3 默认 0.8/0.7/0.9/false
///   - build:预置偏好 → 读回持久化值
///   - set*:state 即改 + SharedPreferences 落盘(重 build 仍在)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final sub = container.listen(audioSettingsProvider, (_, _) {});
    addTearDown(sub.close);
    return container;
  }

  test('build:空偏好 → 默认 0.8/0.7/0.9/false', () async {
    SharedPreferences.setMockInitialValues({});
    final container = makeContainer();

    final s = await container.read(audioSettingsProvider.future);

    expect(s.masterVolume, 0.8);
    expect(s.bgmVolume, 0.7);
    expect(s.sfxVolume, 0.9);
    expect(s.muted, isFalse);
  });

  test('build:预置偏好 → 读回持久化值', () async {
    SharedPreferences.setMockInitialValues({
      'audio.master': 0.3,
      'audio.bgm': 0.4,
      'audio.sfx': 0.5,
      'audio.muted': true,
    });
    final container = makeContainer();

    final s = await container.read(audioSettingsProvider.future);

    expect(s.masterVolume, 0.3);
    expect(s.bgmVolume, 0.4);
    expect(s.sfxVolume, 0.5);
    expect(s.muted, isTrue);
  });

  test('setMasterVolume/setMuted:state 即改且落盘', () async {
    SharedPreferences.setMockInitialValues({});
    final container = makeContainer();
    await container.read(audioSettingsProvider.future);

    await container.read(audioSettingsProvider.notifier).setMasterVolume(0.25);
    expect(
      container.read(audioSettingsProvider).value?.masterVolume,
      0.25,
      reason: 'state 即改(UI 滑条即时反映)',
    );

    await container.read(audioSettingsProvider.notifier).setMuted(true);
    expect(container.read(audioSettingsProvider).value?.muted, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('audio.master'), 0.25, reason: '改动即存');
    expect(prefs.getBool('audio.muted'), isTrue);

    // 持久化闭环:新 container 重 build 读出改后值。
    final container2 = makeContainer();
    final reloaded = await container2.read(audioSettingsProvider.future);
    expect(reloaded.masterVolume, 0.25);
    expect(reloaded.muted, isTrue);
  });

  test('setBgmVolume/setSfxVolume:分项落盘互不影响', () async {
    SharedPreferences.setMockInitialValues({});
    final container = makeContainer();
    await container.read(audioSettingsProvider.future);

    await container.read(audioSettingsProvider.notifier).setBgmVolume(0.1);
    await container.read(audioSettingsProvider.notifier).setSfxVolume(0.2);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('audio.bgm'), 0.1);
    expect(prefs.getDouble('audio.sfx'), 0.2);
    expect(
      prefs.getDouble('audio.master'),
      0.8,
      reason: '未动的分项保持默认(copyWith 语义)',
    );
  });
}
