import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/audio/audio_assets.dart';
import 'package:wuxia_idle/shared/audio/audio_backend.dart';
import 'package:wuxia_idle/shared/audio/bgm_scope.dart';
import 'package:wuxia_idle/shared/audio/sound_manager.dart';

/// 录 BGM 的 fake 后端（沿 sound_manager_test 体例）。
class _RecordingBackend implements AudioBackend {
  final List<String> bgmPlays = [];
  @override
  Future<void> playBgm(String assetPath, double volume) async =>
      bgmPlays.add(assetPath);
  @override
  Future<void> stopBgm() async {}
  @override
  void setBgmVolume(double volume) {}
  @override
  Future<void> playSfx(String assetPath, double volume) async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  late _RecordingBackend rec;

  setUp(() {
    rec = _RecordingBackend();
    SoundManager.instance = SoundManager(rec);
  });

  tearDown(() {
    SoundManager.instance = SoundManager(const SilentAudioBackend());
  });

  testWidgets('push 战斗路由切 battle 轨,pop 后切回 mainMenu 轨', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BgmScope(
          track: BgmTrack.mainMenu,
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => Navigator.of(ctx).push(
                MaterialPageRoute<void>(
                  builder: (_) => BgmScope(
                    track: BgmTrack.battle,
                    child: Builder(
                      builder: (ctx2) => ElevatedButton(
                        onPressed: () => Navigator.of(ctx2).pop(),
                        child: const Text('back'),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('enter'),
            ),
          ),
        ),
      ),
    );
    expect(rec.bgmPlays, [bgmAssetPath(BgmTrack.mainMenu)]);

    await tester.tap(find.text('enter'));
    await tester.pumpAndSettle();
    expect(rec.bgmPlays.last, bgmAssetPath(BgmTrack.battle));

    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();
    expect(rec.bgmPlays.last, bgmAssetPath(BgmTrack.mainMenu),
        reason: 'pop 战斗路由后应切回上一层 scope 的主菜单轨');
  });

  testWidgets('push 无 scope 路由不切轨,pop 也不重播', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BgmScope(
          track: BgmTrack.mainMenu,
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => Navigator.of(ctx).push(
                MaterialPageRoute<void>(
                  builder: (_) => Builder(
                    builder: (ctx2) => ElevatedButton(
                      onPressed: () => Navigator.of(ctx2).pop(),
                      child: const Text('back'),
                    ),
                  ),
                ),
              ),
              child: const Text('enter'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('enter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();
    expect(rec.bgmPlays, [bgmAssetPath(BgmTrack.mainMenu)],
        reason: '无 scope 的子路由进出不该触发任何切轨');
  });
}
