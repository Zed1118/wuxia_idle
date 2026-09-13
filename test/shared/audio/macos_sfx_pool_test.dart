import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/audio/macos_sfx_pool.dart';

class _Assets extends AudioCache {
  final requests = <String>[];
  Completer<void>? hold;

  @override
  Future<String> loadPath(String fileName) async {
    requests.add(fileName);
    await hold?.future;
    return '/cached/$fileName';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.pen.wuxia/macos_sfx');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late AudioCache previousCache;
  late _Assets assets;
  late MacosSfxPool pool;
  late List<MethodCall> calls;
  Completer<void>? nativeHold;
  Object? nativeFailure;
  bool starts = true;

  setUp(() {
    previousCache = AudioCache.instance;
    assets = _Assets();
    AudioCache.instance = assets;
    pool = MacosSfxPool(maxVoices: 2);
    calls = [];
    nativeHold = null;
    nativeFailure = null;
    starts = true;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'play') {
        await nativeHold?.future;
        if (nativeFailure case final error?) throw error;
        return {'started': starts, 'voiceCount': 2, 'activeVoices': 2};
      }
      return null;
    });
  });

  tearDown(() async {
    if (assets.hold case final gate? when !gate.isCompleted) gate.complete();
    if (nativeHold case final gate? when !gate.isCompleted) gate.complete();
    await pool.dispose();
    AudioCache.instance = previousCache;
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'bursts are bounded before asset extraction and native completion',
    () async {
      assets.hold = Completer<void>();
      nativeHold = Completer<void>();
      final first = pool.play('hit.mp3', 0.8);
      final second = pool.play('slash.mp3', 0.7);
      final burst = List.generate(1000, (_) => pool.play('stale.mp3', 0.5));
      await pumpEventQueue();
      expect(assets.requests, ['hit.mp3', 'slash.mp3']);
      expect(calls, isEmpty);

      assets.hold!.complete();
      await pumpEventQueue();
      expect(calls.map((call) => call.method), ['play', 'play']);
      await pool.play('still-stale.mp3', 0.5);
      expect(assets.requests, hasLength(2));
      final arguments = calls.first.arguments as Map;
      expect(arguments['assetPath'], '/cached/hit.mp3');
      expect(arguments['maxVoices'], 2);
      expect(arguments['volume'], 0.8);
      expect((calls.last.arguments as Map)['poolId'], arguments['poolId']);

      nativeHold!.complete();
      await Future.wait([first, second, ...burst]);
      await pool.play('later.mp3', 0.6);
      expect(calls, hasLength(3), reason: 'No delayed burst backlog');
      expect((calls.last.arguments as Map)['assetPath'], '/cached/later.mp3');
    },
  );

  test('disposal while extracting prevents a late native start', () async {
    assets.hold = Completer<void>();
    final playback = pool.play('hit.mp3', 0.8);
    final disposal = pool.dispose();
    expect(identical(disposal, pool.dispose()), isTrue);
    await pumpEventQueue();
    expect(calls, isEmpty);
    assets.hold!.complete();
    await Future.wait([playback, disposal]);
    await pool.play('after-dispose.mp3', 0.8);
    expect(assets.requests, ['hit.mp3']);
    expect(calls.map((call) => call.method), ['dispose']);
  });

  test('native work settles before the pool is released', () async {
    nativeHold = Completer<void>();
    final playback = pool.play('hit.mp3', 0.8);
    await pumpEventQueue();
    final disposal = pool.dispose();
    await pumpEventQueue();
    expect(calls.map((call) => call.method), ['play']);
    nativeHold!.complete();
    await Future.wait([playback, disposal]);
    expect(calls.map((call) => call.method), ['play', 'dispose']);
  });

  test(
    'native errors and failed starts release capacity for later sounds',
    () async {
      nativeFailure = PlatformException(code: 'prepare-failed');
      await expectLater(
        pool.play('broken.mp3', 0.8),
        throwsA(isA<PlatformException>()),
      );
      nativeFailure = null;
      starts = false;
      await expectLater(pool.play('cannot-start.mp3', 0.8), throwsStateError);
      starts = true;
      await pool.play('recovered.mp3', 0.8);
      expect(calls.where((call) => call.method == 'play'), hasLength(3));
    },
  );

  test('different backends own different native pools', () async {
    final other = MacosSfxPool(maxVoices: 1);
    try {
      await pool.play('first.mp3', 0.8);
      await other.play('second.mp3', 0.7);
      expect(
        (calls[0].arguments as Map)['poolId'],
        isNot((calls[1].arguments as Map)['poolId']),
      );
      expect((calls[1].arguments as Map)['maxVoices'], 1);
      await pool.dispose();
      await other.play('still-active.mp3', 0.6);
      expect(calls.last.method, 'play');
    } finally {
      await other.dispose();
    }
  });
}
