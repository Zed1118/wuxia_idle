import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/audio_settings.dart';
import 'audio_settings_service.dart';
import '../../../shared/audio/sound_manager.dart';

part 'audio_settings_provider.g.dart';

/// 音频设置 Notifier(codegen)。改动即存(shared_preferences)+ 即应用到引擎
/// (`SoundManager.instance`)。UI 滑条/开关读 [state] 显示,调 set* 写回。
@riverpod
class AudioSettingsNotifier extends _$AudioSettingsNotifier {
  final AudioSettingsService _service = AudioSettingsService();

  @override
  Future<AudioSettings> build() async {
    final s = await _service.load();
    await SoundManager.instance.applySettings(s);
    return s;
  }

  Future<void> _update(AudioSettings next) async {
    state = AsyncData(next);
    await _service.save(next);
    await SoundManager.instance.applySettings(next);
  }

  Future<void> setMasterVolume(double v) =>
      _update(state.requireValue.copyWith(masterVolume: v));
  Future<void> setBgmVolume(double v) =>
      _update(state.requireValue.copyWith(bgmVolume: v));
  Future<void> setSfxVolume(double v) =>
      _update(state.requireValue.copyWith(sfxVolume: v));
  Future<void> setMuted(bool m) =>
      _update(state.requireValue.copyWith(muted: m));
}
