import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'audio_backend.dart';
import 'macos_sfx_pool.dart';

/// BGM uses one serialized player; SFX use a fixed, overlapping voice pool.
class AudioPlayersBackend implements AudioBackend {
  AudioPlayersBackend({int sfxPoolSize = 5})
    : assert(sfxPoolSize > 0),
      _nativeSfx = _usesMacosSfx ? MacosSfxPool(maxVoices: sfxPoolSize) : null,
      _sfxPool = _usesMacosSfx
          ? []
          : List.generate(sfxPoolSize, (_) => _SfxVoice());

  static bool get _usesMacosSfx =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  final AudioPlayer _bgm = _createPlayer();
  final MacosSfxPool? _nativeSfx;
  final List<_SfxVoice> _sfxPool;
  int _sfxCursor = 0;
  bool _disposed = false;
  Future<void>? _disposeWork;
  Future<void>? _bgmWork;
  _BgmRequest? _pendingBgm;
  int _bgmRevision = 0;
  bool _bgmLoopConfigured = false;
  double _bgmVolume = 1;
  bool _bgmVolumeDirty = false;

  @override
  Future<void> playBgm(String assetPath, double volume) {
    if (_disposed) return Future.value();
    _bgmVolume = volume;
    _bgmVolumeDirty = true;
    _pendingBgm = _BgmRequest(assetPath, ++_bgmRevision);
    return _scheduleBgm();
  }

  @override
  Future<void> stopBgm() {
    if (_disposed) return Future.value();
    _pendingBgm = _BgmRequest(null, ++_bgmRevision);
    return _scheduleBgm();
  }

  @override
  void setBgmVolume(double volume) {
    if (_disposed) return;
    _bgmVolume = volume;
    _bgmVolumeDirty = true;
    unawaited(
      _scheduleBgm().catchError((Object error) {
        debugPrint('AudioPlayersBackend volume update failed: $error');
      }),
    );
  }

  Future<void> _scheduleBgm() => _bgmWork ??= _drainBgm();

  Future<void> _drainBgm() async {
    Object? firstError;
    StackTrace? firstStack;
    try {
      while (!_disposed && (_pendingBgm != null || _bgmVolumeDirty)) {
        final request = _pendingBgm;
        _pendingBgm = null;
        try {
          if (request != null) {
            if (!_bgmLoopConfigured) {
              await _bgm.setReleaseMode(ReleaseMode.loop);
              _bgmLoopConfigured = true;
            }
            await _bgm.stop();
            if (_disposed || request.revision != _bgmRevision) continue;
            final assetPath = request.assetPath;
            if (assetPath != null) {
              await _bgm.setSource(AssetSource(assetPath));
              if (_disposed || request.revision != _bgmRevision) continue;
              await _applyBgmVolume();
              if (!_disposed && request.revision == _bgmRevision) {
                await _bgm.resume();
              }
            }
          }
          if (!_disposed && _bgmVolumeDirty) await _applyBgmVolume();
        } catch (error, stack) {
          firstError ??= error;
          firstStack ??= stack;
        }
      }
      if (firstError != null) {
        Error.throwWithStackTrace(firstError, firstStack!);
      }
    } finally {
      _bgmWork = null;
    }
  }

  Future<void> _applyBgmVolume() async {
    _bgmVolumeDirty = false;
    await _bgm.setVolume(_bgmVolume);
  }

  @override
  Future<void> playSfx(String assetPath, double volume) {
    if (_disposed) return Future.value();
    if (_nativeSfx case final native?) return native.play(assetPath, volume);
    int? availableIndex;
    int? idleIndex;
    int? matchingIdleIndex;
    for (var offset = 0; offset < _sfxPool.length; offset++) {
      final index = (_sfxCursor + offset) % _sfxPool.length;
      final voice = _sfxPool[index];
      if (voice.work != null) continue;
      availableIndex ??= index;
      if (voice.player.state != PlayerState.playing) {
        idleIndex ??= index;
        if (voice.preparedAssetPath == assetPath) {
          matchingIdleIndex = index;
          break;
        }
      }
    }
    final index = matchingIdleIndex ?? idleIndex ?? availableIndex;
    if (index != null) {
      _sfxCursor = (index + 1) % _sfxPool.length;
      return _sfxPool[index].play(assetPath, volume, () => !_disposed);
    }
    // Busy voices are still preparing native AVPlayerItems. Replacing one now
    // can orphan its preparation continuation. Drop stale burst sounds instead
    // of queuing work that would grow with battle density.
    return Future.value();
  }

  @override
  Future<void> dispose() {
    _disposed = true;
    _pendingBgm = null;
    return _disposeWork ??= _disposePlayers();
  }

  Future<void> _disposePlayers() async {
    await Future.wait([
      if (_nativeSfx case final native?) native.dispose(),
      _disposeAudioPlayers(),
    ]);
  }

  Future<void> _disposeAudioPlayers() async {
    await Future.wait([
      _settled(_bgmWork),
      for (final voice in _sfxPool) _settled(voice.work),
    ]);
    await Future.wait([
      _bgm.dispose(),
      for (final voice in _sfxPool) voice.player.dispose(),
    ]);
  }
}

// No game consumer displays audio position. The plugin's default updater polls
// every player over a platform channel on every Flutter frame.
AudioPlayer _createPlayer() => AudioPlayer()..positionUpdater = null;

Future<void> _settled(Future<void>? work) async {
  try {
    await work;
  } catch (_) {
    // The playback caller owns the error; teardown must still release players.
  }
}

class _BgmRequest {
  const _BgmRequest(this.assetPath, this.revision);

  final String? assetPath;
  final int revision;
}

class _SfxVoice {
  final AudioPlayer player = _createPlayer();
  Future<void>? work;
  bool _stopConfigured = false;
  String? preparedAssetPath;

  Future<void> play(String assetPath, double volume, bool Function() active) =>
      work = _play(assetPath, volume, active);

  Future<void> _play(
    String assetPath,
    double volume,
    bool Function() active,
  ) async {
    try {
      if (!_stopConfigured) {
        // A native completion callback can outlive its sound. Keep resources in
        // this fixed pool so its asynchronous auto-release cannot reset the
        // next sound while that sound is preparing.
        await player.setReleaseMode(ReleaseMode.stop);
        _stopConfigured = true;
      }
      // Native stop reads the old media time synchronously on Darwin. A new
      // source starts at zero anyway; a reused source needs an explicit seek,
      // whose future also waits for the native seek-complete event.
      await player.pause();
      if (!active()) return;
      if (player.volume != volume) await player.setVolume(volume);
      if (!active()) return;
      if (preparedAssetPath != assetPath) {
        // ReleaseMode.stop retains the prepared source. Replacing an identical
        // asset adds extraction/platform work and may rebuild native media.
        preparedAssetPath = null;
        await player.setSource(AssetSource(assetPath));
        preparedAssetPath = assetPath;
      } else {
        await player.seek(Duration.zero);
      }
      if (active()) await player.resume();
    } catch (_) {
      preparedAssetPath = null;
      rethrow;
    } finally {
      work = null;
    }
  }
}
