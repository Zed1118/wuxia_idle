import 'package:flutter/foundation.dart';
import 'audio_assets.dart';
import 'audio_backend.dart';
import '../../features/settings/domain/audio_settings.dart';

/// 音频引擎单例。持后端 + 当前设置，算有效音量、同轨去重、缺素材 guard。
class SoundManager {
  SoundManager(this._backend);

  /// 全局单例。默认 SilentAudioBackend（widget 测/未 init 不崩）；main 换真后端。
  static SoundManager instance = SoundManager(const SilentAudioBackend());

  final AudioBackend _backend;
  AudioSettings _settings = const AudioSettings();
  BgmTrack? _currentBgm;
  bool _warned = false;

  double get _bgmEffective =>
      _settings.muted ? 0.0 : _settings.masterVolume * _settings.bgmVolume;
  double get _sfxEffective =>
      _settings.muted ? 0.0 : _settings.masterVolume * _settings.sfxVolume;

  /// 应用一份设置（load 后 / 用户改动后调）。
  Future<void> applySettings(AudioSettings s) async {
    _settings = s;
    _backend.setBgmVolume(_bgmEffective);
  }

  Future<void> playBgm(BgmTrack track) async {
    if (_currentBgm == track) return;
    _currentBgm = track;
    await _guard(() => _backend.playBgm(bgmAssetPath(track), _bgmEffective));
  }

  Future<void> stopBgm() async {
    _currentBgm = null;
    await _guard(_backend.stopBgm);
  }

  Future<void> playSfx(SfxId id) async {
    if (_settings.muted) return;
    await _guard(() => _backend.playSfx(sfxAssetPath(id), _sfxEffective));
  }

  /// 直接按 asset 路径播 SFX（平A 按单位变体等「一槽多文件」场景用）。
  Future<void> playSfxPath(String assetPath) async {
    if (_settings.muted) return;
    await _guard(() => _backend.playSfx(assetPath, _sfxEffective));
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!_warned) {
        debugPrint('[SoundManager] 音频播放失败（素材缺失？）: $e');
        _warned = true;
      }
    }
  }
}
