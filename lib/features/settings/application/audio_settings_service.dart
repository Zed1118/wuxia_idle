import 'package:shared_preferences/shared_preferences.dart';
import '../domain/audio_settings.dart';

/// 音频设置持久化（shared_preferences，key 前缀 audio.）。设置≠存档，与 Isar 隔离。
class AudioSettingsService {
  static const _kMaster = 'audio.master';
  static const _kBgm = 'audio.bgm';
  static const _kSfx = 'audio.sfx';
  static const _kMuted = 'audio.muted';

  Future<AudioSettings> load() async {
    final p = await SharedPreferences.getInstance();
    return AudioSettings(
      masterVolume: p.getDouble(_kMaster) ?? 0.8,
      bgmVolume: p.getDouble(_kBgm) ?? 0.7,
      sfxVolume: p.getDouble(_kSfx) ?? 0.9,
      muted: p.getBool(_kMuted) ?? false,
    );
  }

  Future<void> save(AudioSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kMaster, s.masterVolume);
    await p.setDouble(_kBgm, s.bgmVolume);
    await p.setDouble(_kSfx, s.sfxVolume);
    await p.setBool(_kMuted, s.muted);
  }
}
