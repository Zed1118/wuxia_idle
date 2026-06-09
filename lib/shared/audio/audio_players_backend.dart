import 'package:audioplayers/audioplayers.dart';
import 'audio_backend.dart';

/// audioplayers 真后端。BGM 单 player 循环；SFX 池 round-robin 叠播。
class AudioPlayersBackend implements AudioBackend {
  AudioPlayersBackend({int sfxPoolSize = 5})
      : _sfxPool = List.generate(sfxPoolSize, (_) => AudioPlayer());

  final AudioPlayer _bgm = AudioPlayer()..setReleaseMode(ReleaseMode.loop);
  final List<AudioPlayer> _sfxPool;
  int _sfxCursor = 0;

  @override
  Future<void> playBgm(String assetPath, double volume) async {
    await _bgm.stop();
    await _bgm.setVolume(volume);
    await _bgm.play(AssetSource(assetPath), volume: volume);
  }

  @override
  Future<void> stopBgm() async => _bgm.stop();

  @override
  void setBgmVolume(double volume) {
    _bgm.setVolume(volume);
  }

  @override
  Future<void> playSfx(String assetPath, double volume) async {
    final p = _sfxPool[_sfxCursor];
    _sfxCursor = (_sfxCursor + 1) % _sfxPool.length;
    await p.stop();
    await p.play(AssetSource(assetPath), volume: volume);
  }

  @override
  Future<void> dispose() async {
    await _bgm.dispose();
    for (final p in _sfxPool) {
      await p.dispose();
    }
  }
}
