import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/audio/audio_backend.dart';
import 'package:wuxia_idle/shared/audio/audio_assets.dart';
import 'package:wuxia_idle/shared/audio/sound_manager.dart';
import 'package:wuxia_idle/features/settings/domain/audio_settings.dart';

class FakeAudioBackend implements AudioBackend {
  final List<String> bgmPlays = [];
  final List<String> sfxPlays = [];
  final List<double> bgmVolumes = [];
  int stopBgmCount = 0;
  Set<String> throwOnPaths = {};

  @override
  Future<void> playBgm(String assetPath, double volume) async {
    if (throwOnPaths.contains(assetPath)) throw Exception('missing asset');
    bgmPlays.add(assetPath);
  }
  @override
  Future<void> stopBgm() async => stopBgmCount++;
  @override
  void setBgmVolume(double volume) => bgmVolumes.add(volume);
  @override
  Future<void> playSfx(String assetPath, double volume) async {
    if (throwOnPaths.contains(assetPath)) throw Exception('missing asset');
    sfxPlays.add(assetPath);
  }
  @override
  Future<void> dispose() async {}
}

void main() {
  test('同轨重复 playBgm 只播一次', () async {
    final fake = FakeAudioBackend();
    final m = SoundManager(fake);
    await m.playBgm(BgmTrack.mainMenu);
    await m.playBgm(BgmTrack.mainMenu);
    expect(fake.bgmPlays.length, 1);
  });

  test('换轨 playBgm 再播', () async {
    final fake = FakeAudioBackend();
    final m = SoundManager(fake);
    await m.playBgm(BgmTrack.mainMenu);
    await m.playBgm(BgmTrack.battle);
    expect(fake.bgmPlays.length, 2);
  });

  test('缺素材 playSfx 不抛（静默 no-op）', () async {
    final fake = FakeAudioBackend()..throwOnPaths = {sfxAssetPath(SfxId.uiTap)};
    final m = SoundManager(fake);
    await m.playSfx(SfxId.uiTap); // 不应抛
    expect(fake.sfxPlays, isEmpty);
  });

  test('静音时 playSfx 不调后端', () async {
    final fake = FakeAudioBackend();
    final m = SoundManager(fake);
    await m.applySettings(const AudioSettings(muted: true));
    await m.playSfx(SfxId.uiTap);
    expect(fake.sfxPlays, isEmpty);
  });

  test('applySettings 把 master*bgm 应用到后端 bgm 音量', () async {
    final fake = FakeAudioBackend();
    final m = SoundManager(fake);
    await m.applySettings(const AudioSettings(masterVolume: 0.5, bgmVolume: 0.4));
    expect(fake.bgmVolumes.last, closeTo(0.2, 1e-9));
  });
}
