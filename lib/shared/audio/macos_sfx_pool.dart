import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Short macOS sounds use a bounded native pool on its own serial queue.
/// Asset extraction and native preparation share the same in-flight limit, so
/// an input burst cannot become a delayed playback backlog.
class MacosSfxPool {
  MacosSfxPool({required this.maxVoices})
    : assert(maxVoices > 0),
      _poolId = 'sfx-${_nextPoolId++}';

  static const _channel = MethodChannel('com.pen.wuxia/macos_sfx');
  static int _nextPoolId = 0;

  final int maxVoices;
  final String _poolId;
  final Set<Future<void>> _pending = {};
  bool _disposed = false;
  Future<void>? _disposeWork;

  Future<void> play(String assetPath, double volume) {
    if (_disposed || _pending.length >= maxVoices) return Future.value();
    final work = _play(assetPath, volume);
    _pending.add(work);
    return work.whenComplete(() => _pending.remove(work));
  }

  Future<void> _play(String assetPath, double volume) async {
    // Keep the existing bundled-asset lookup and extraction contract. The
    // native side receives a local path, never an untrusted network URL.
    final path = await AudioCache.instance.loadPath(assetPath);
    if (_disposed) return;
    final response = await _channel.invokeMapMethod<String, Object?>('play', {
      'poolId': _poolId,
      'maxVoices': maxVoices,
      'assetPath': path,
      'volume': volume,
    });
    if (response?['started'] != true) {
      throw StateError('macOS SFX playback did not start: $assetPath');
    }
  }

  Future<void> dispose() {
    _disposed = true;
    return _disposeWork ??= _dispose();
  }

  Future<void> _dispose() async {
    await Future.wait([
      for (final work in _pending.toList())
        work.then<void>((_) {}, onError: (Object _, StackTrace _) {}),
    ]);
    await _channel.invokeMethod<void>('dispose', {'poolId': _poolId});
  }
}
