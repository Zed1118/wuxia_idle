import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/audio/audio_players_backend.dart';

/// Uses real AudioPlayer source preparation and MethodChannels. Only native
/// method completion and asset extraction are controlled by this fixture.
class _NativeAudioProbe {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  final pending = <String, List<Completer<void>>>{};
  final overlappingPreparations = <String>[];
  final interruptedPreparations = <String>[];
  final players = <String>[];
  final releaseModes = <String, String>{};
  final pendingPauses = <Completer<void>>[];
  final pendingSeeks = <Completer<void>>[];
  final positions = <String, int>{};
  final playbackStarts = <int>[];
  bool holdPreparations = true;
  bool holdPauses = false;
  bool holdSeeks = false;
  bool failNextPreparation = false;

  void install() {
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global/events'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      _handle,
    );
  }

  Future<Object?> _handle(MethodCall call) async {
    calls.add(call);
    final args = call.arguments as Map;
    final id = args['playerId'] as String;
    if (call.method == 'setReleaseMode') {
      releaseModes[id] = args['releaseMode'] as String;
    }
    if (call.method == 'pause' && holdPauses) {
      final gate = Completer<void>();
      pendingPauses.add(gate);
      await gate.future;
      pendingPauses.remove(gate);
    }
    if (call.method == 'seek') {
      final gate = Completer<void>();
      pendingSeeks.add(gate);
      if (!holdSeeks) gate.complete();
      await gate.future;
      pendingSeeks.remove(gate);
      positions[id] = args['position'] as int;
      await messenger.handlePlatformMessage(
        'xyz.luan/audioplayers/events/$id',
        const StandardMethodCodec().encodeSuccessEnvelope({
          'event': 'audio.onSeekComplete',
        }),
        (_) {},
      );
    }
    if (call.method == 'resume') {
      playbackStarts.add(positions[id] ?? 0);
    }
    if (call.method == 'create') {
      players.add(id);
      messenger.setMockMethodCallHandler(
        MethodChannel('xyz.luan/audioplayers/events/$id'),
        (_) async => null,
      );
    }
    if (call.method == 'setSourceUrl') {
      final gates = pending.putIfAbsent(id, () => []);
      if (gates.isNotEmpty) overlappingPreparations.add(id);
      final gate = Completer<void>();
      gates.add(gate);
      if (!holdPreparations) gate.complete();
      await gate.future;
      gates.remove(gate);
      positions[id] = 0;
      await messenger.handlePlatformMessage(
        'xyz.luan/audioplayers/events/$id',
        const StandardMethodCodec().encodeSuccessEnvelope({
          'event': 'audio.onPrepared',
          'value': true,
        }),
        (_) {},
      );
      if (failNextPreparation) {
        failNextPreparation = false;
        throw PlatformException(code: 'prepare-failed');
      }
    }
    if ({'stop', 'release', 'dispose'}.contains(call.method) &&
        (pending[id]?.isNotEmpty ?? false)) {
      interruptedPreparations.add('${call.method}:$id');
    }
    return call.method == 'getCurrentPosition' ? 0 : null;
  }

  int count(String method) => calls.where((c) => c.method == method).length;
  List<MethodCall> named(String method) =>
      calls.where((c) => c.method == method).toList();

  void releasePreparations() {
    for (final gates in pending.values) {
      for (final gate in gates) {
        if (!gate.isCompleted) gate.complete();
      }
    }
  }

  void releasePauses() {
    holdPauses = false;
    for (final gate in pendingPauses) {
      if (!gate.isCompleted) gate.complete();
    }
  }

  void releaseSeeks() {
    holdSeeks = false;
    for (final gate in pendingSeeks) {
      if (!gate.isCompleted) gate.complete();
    }
  }

  Future<void> beginSoundCompletion(String id) =>
      messenger.handlePlatformMessage(
        'xyz.luan/audioplayers/events/$id',
        const StandardMethodCodec().encodeSuccessEnvelope({
          'event': 'audio.onComplete',
        }),
        (_) {},
      );

  void finishNativeCompletion(String id) {
    // Darwin emits completion, awaits seek, then releases the current item in
    // release mode. Let that old seek finish while the next sound is preparing.
    if ((releaseModes[id] ?? 'ReleaseMode.release') == 'ReleaseMode.release' &&
        (pending[id]?.isNotEmpty ?? false)) {
      interruptedPreparations.add('completion-release:$id');
    }
  }

  void uninstall() {
    for (final id in players) {
      messenger.setMockMethodCallHandler(
        MethodChannel('xyz.luan/audioplayers/events/$id'),
        null,
      );
    }
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      null,
    );
  }
}

class _CachedAssets extends AudioCache {
  @override
  Future<String> loadPath(String fileName) async => '/cached/$fileName';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _NativeAudioProbe native;
  late AudioPlayersBackend backend;
  late AudioCache previousCache;

  setUp(() {
    native = _NativeAudioProbe()..install();
    previousCache = AudioCache.instance;
    AudioCache.instance = _CachedAssets();
    backend = AudioPlayersBackend(sfxPoolSize: 2);
  });

  tearDown(() async {
    native.holdPreparations = false;
    native.releasePreparations();
    native.releasePauses();
    native.releaseSeeks();
    await backend.dispose();
    AudioCache.instance = previousCache;
    native.uninstall();
  });

  test(
    'macOS routes short sounds to its pool while BGM keeps its player',
    () async {
      const sfxChannel = MethodChannel('com.pen.wuxia/macos_sfx');
      final sfxCalls = <MethodCall>[];
      native.messenger.setMockMethodCallHandler(sfxChannel, (call) async {
        sfxCalls.add(call);
        return call.method == 'play' ? {'started': true} : null;
      });
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final macBackend = AudioPlayersBackend(sfxPoolSize: 2);
      try {
        native.holdPreparations = false;
        await macBackend.playSfx('hit.mp3', 0.8);
        expect(sfxCalls.map((call) => call.method), ['play']);
        expect((sfxCalls.single.arguments as Map)['maxVoices'], 2);
        expect(native.count('setSourceUrl'), 0);
        await macBackend.playBgm('music.mp3', 0.4);
        expect(native.count('setSourceUrl'), 1);
        expect(native.count('resume'), 1);
        await macBackend.dispose();
        expect(sfxCalls.map((call) => call.method), ['play', 'dispose']);
      } finally {
        await macBackend.dispose();
        debugDefaultTargetPlatformOverride = null;
        native.messenger.setMockMethodCallHandler(sfxChannel, null);
      }
    },
  );

  test(
    'bursts keep preparation bounded while allowing independent voices',
    () async {
      final first = backend.playSfx('hit.mp3', 0.8);
      final second = backend.playSfx('slash.mp3', 0.7);
      await pumpEventQueue();
      expect(native.count('setSourceUrl'), 2);
      expect(native.pending.values.where((g) => g.isNotEmpty), hasLength(2));

      final burst = List.generate(1000, (_) => backend.playSfx('hit.mp3', 0.8));
      await pumpEventQueue();
      expect(native.overlappingPreparations, isEmpty);
      expect(native.interruptedPreparations, isEmpty);
      expect(native.count('setSourceUrl'), 2);
      expect(native.players, hasLength(3));

      native.releasePreparations();
      await Future.wait([first, second, ...burst]);
      expect(native.count('resume'), 2);
      expect(native.count('setSourceUrl'), 2, reason: 'No stale burst backlog');

      native.holdPreparations = false;
      await backend.playSfx('later.mp3', 0.5);
      expect(native.count('resume'), 3, reason: 'Voices remain usable');
      expect(
        native
            .named('setReleaseMode')
            .map((c) => (c.arguments as Map)['releaseMode']),
        ['ReleaseMode.stop', 'ReleaseMode.stop'],
        reason: 'Native completion must not auto-release a reused voice',
      );
    },
  );

  test(
    'preparation errors release the SFX slot for subsequent sound',
    () async {
      native.holdPreparations = false;
      native.failNextPreparation = true;
      await expectLater(
        backend.playSfx('broken.mp3', 0.8),
        throwsA(isA<PlatformException>()),
      );
      await backend.playSfx('next.mp3', 0.8);
      await backend.playSfx('reused.mp3', 0.8);
      expect(native.count('resume'), 2);
      expect(native.overlappingPreparations, isEmpty);
    },
  );

  test(
    'late native completion cannot release a reused preparing voice',
    () async {
      native.holdPreparations = false;
      await backend.playSfx('first.mp3', 0.8);
      final id =
          (native.named('resume').last.arguments as Map)['playerId'] as String;
      await backend.playSfx('second.mp3', 0.8);
      await native.beginSoundCompletion(id);
      await pumpEventQueue();

      native.holdPreparations = true;
      final reuse = backend.playSfx('reused.mp3', 0.8);
      await pumpEventQueue();
      expect(native.pending[id], hasLength(1));
      native.finishNativeCompletion(id);
      expect(native.interruptedPreparations, isEmpty);
      native.releasePreparations();
      await reuse;
      expect(native.count('resume'), 3);
      expect(native.overlappingPreparations, isEmpty);
    },
  );

  test(
    'completed matching voice reuses its source ahead of round robin',
    () async {
      native.holdPreparations = false;
      await backend.playSfx('hit.mp3', 0.8);
      final hitId =
          (native.named('resume').last.arguments as Map)['playerId'] as String;
      await backend.playSfx('slash.mp3', 0.7);
      final slashId =
          (native.named('resume').last.arguments as Map)['playerId'] as String;
      await native.beginSoundCompletion(hitId);
      await native.beginSoundCompletion(slashId);
      await pumpEventQueue();

      await backend.playSfx('slash.mp3', 0.4);
      expect(
        (native.named('resume').last.arguments as Map)['playerId'],
        slashId,
      );
      expect(native.count('setSourceUrl'), 2);
      expect((native.named('setVolume').last.arguments as Map)['volume'], 0.4);
      expect(native.players, hasLength(3));
    },
  );

  test('overlapping identical sounds still use separate voices', () async {
    native.holdPreparations = false;
    await backend.playSfx('hit.mp3', 0.8);
    await backend.playSfx('hit.mp3', 0.8);
    expect(
      native
          .named('resume')
          .map((c) => (c.arguments as Map)['playerId'])
          .toSet(),
      hasLength(2),
    );
    await backend.playSfx('hit.mp3', 0.8);
    expect(native.count('setSourceUrl'), 2);
    expect(native.count('resume'), 3);
  });

  test(
    'failed source replacement invalidates the previously prepared asset',
    () async {
      native.holdPreparations = false;
      await backend.playSfx('hit.mp3', 0.8);
      await backend.playSfx('slash.mp3', 0.8);
      native.failNextPreparation = true;
      await expectLater(
        backend.playSfx('broken.mp3', 0.8),
        throwsA(isA<PlatformException>()),
      );
      await backend.playSfx('hit.mp3', 0.8);
      expect(native.count('setSourceUrl'), 4);
      expect(
        (native.named('setSourceUrl').last.arguments as Map)['url'],
        '/cached/hit.mp3',
      );
      expect(native.count('resume'), 3);
    },
  );

  test('cached playback remains exclusive while pause is pending', () async {
    native.holdPreparations = false;
    await backend.playSfx('hit.mp3', 0.8);
    await backend.playSfx('slash.mp3', 0.8);
    native.holdPauses = true;
    final first = backend.playSfx('hit.mp3', 0.8);
    final second = backend.playSfx('slash.mp3', 0.8);
    await pumpEventQueue();
    expect(native.pendingPauses, hasLength(2));
    final burst = List.generate(100, (_) => backend.playSfx('hit.mp3', 0.8));
    await Future.wait(burst);
    expect(native.pendingPauses, hasLength(2));
    native.releasePauses();
    await Future.wait([first, second]);
    expect(native.count('setSourceUrl'), 2);
    expect(native.count('resume'), 4);
    expect(native.overlappingPreparations, isEmpty);
  });

  test('reused source waits for an explicit rewind before resuming', () async {
    native.holdPreparations = false;
    await backend.playSfx('hit.mp3', 0.8);
    await backend.playSfx('slash.mp3', 0.8);
    for (final id in native.positions.keys) {
      native.positions[id] = 137;
    }
    native.holdSeeks = true;
    final replay = backend.playSfx('hit.mp3', 0.8);
    await pumpEventQueue();
    expect(native.count('resume'), 2);
    expect(native.pendingSeeks, hasLength(1));
    expect((native.named('seek').last.arguments as Map)['position'], 0);
    native.releaseSeeks();
    await replay;
    expect(native.playbackStarts.last, 0);
    expect(native.count('setSourceUrl'), 2);
    expect(native.count('stop'), 0);
  });

  test(
    'different source is prepared from the beginning without seeking old media',
    () async {
      native.holdPreparations = false;
      await backend.playSfx('hit.mp3', 0.8);
      await backend.playSfx('slash.mp3', 0.8);
      for (final id in native.positions.keys) {
        native.positions[id] = 137;
      }
      await backend.playSfx('other.mp3', 0.8);
      expect(native.playbackStarts.last, 0);
      expect(native.count('setSourceUrl'), 3);
      expect(native.count('seek'), 0);
      expect(native.count('stop'), 0);
    },
  );

  test(
    'BGM changes coalesce to the newest track without interrupting preparation',
    () async {
      final first = backend.playBgm('first.mp3', 0.8);
      await pumpEventQueue();
      final superseded = backend.playBgm('superseded.mp3', 0.7);
      final latest = backend.playBgm('latest.mp3', 0.6);
      await pumpEventQueue();
      expect(native.count('setSourceUrl'), 1);
      expect(native.interruptedPreparations, isEmpty);
      native.holdPreparations = false;
      native.releasePreparations();
      await Future.wait([first, superseded, latest]);
      expect(
        native.named('setSourceUrl').map((c) => (c.arguments as Map)['url']),
        ['/cached/first.mp3', '/cached/latest.mp3'],
      );
      expect(
        native.count('resume'),
        1,
        reason: 'Stale track never becomes audible',
      );
      expect(native.overlappingPreparations, isEmpty);
    },
  );

  test('stop during BGM preparation suppresses the pending playback', () async {
    final playing = backend.playBgm('battle.mp3', 0.8);
    await pumpEventQueue();
    final stopping = backend.stopBgm();
    await pumpEventQueue();
    expect(native.interruptedPreparations, isEmpty);
    native.releasePreparations();
    await Future.wait([playing, stopping]);
    expect(native.count('resume'), 0);
  });

  test(
    'BGM volume changes apply the latest value during preparation',
    () async {
      final playing = backend.playBgm('battle.mp3', 0.8);
      await pumpEventQueue();
      backend.setBgmVolume(0.4);
      backend.setBgmVolume(0.2);
      native.releasePreparations();
      await playing;
      expect((native.named('setVolume').last.arguments as Map)['volume'], 0.2);
      expect(native.count('setSourceUrl'), 1);
    },
  );

  test('BGM preparation errors do not poison later changes', () async {
    native.holdPreparations = false;
    native.failNextPreparation = true;
    await expectLater(
      backend.playBgm('broken.mp3', 0.8),
      throwsA(isA<PlatformException>()),
    );
    await backend.playBgm('recovery.mp3', 0.8);
    expect(native.count('resume'), 1);
  });

  test(
    'dispose drains preparation, drops pending work, and is idempotent',
    () async {
      final sfx = backend.playSfx('hit.mp3', 0.8);
      final bgm = backend.playBgm('first.mp3', 0.8);
      await pumpEventQueue();
      final pendingBgm = backend.playBgm('pending.mp3', 0.8);
      final disposing = backend.dispose();
      final disposingAgain = backend.dispose();
      await backend.playSfx('after-dispose.mp3', 0.8);
      await backend.playBgm('after-dispose.mp3', 0.8);
      backend.setBgmVolume(0.3);
      await pumpEventQueue();
      expect(native.count('dispose'), 0);
      expect(native.interruptedPreparations, isEmpty);
      native.releasePreparations();
      await Future.wait([sfx, bgm, pendingBgm, disposing, disposingAgain]);
      expect(native.count('dispose'), 3);
      expect(native.count('setSourceUrl'), 2);
      expect(native.count('resume'), 0);
    },
  );

  test('fire-and-forget audio does not poll playback position', () async {
    native.holdPreparations = false;
    await backend.playSfx('hit.mp3', 0.8);
    await backend.playBgm('battle.mp3', 0.7);
    expect(native.count('resume'), 2);
    expect(native.count('getCurrentPosition'), 0);
  });
}
