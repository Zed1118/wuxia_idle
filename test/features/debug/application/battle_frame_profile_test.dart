import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/debug/application/battle_frame_profile.dart';

void main() {
  test('运行时参数只在完整生产采样契约下启用', () {
    expect(BattleFrameProfileRunConfig.tryParse(const <String>[]), isNull);

    final config = BattleFrameProfileRunConfig.tryParse(const <String>[
      '--battle-profile-run-id=run-01',
      '--battle-profile-output=C:\\evidence\\run-01',
      '--battle-profile-sample-seconds=60',
      '--battle-profile-warmup-seconds=12',
      '--battle-profile-cooldown-seconds=30',
      '--battle-profile-viewport=1280x720',
      '--battle-profile-auto-close=true',
    ]);

    expect(config, isNotNull);
    expect(config!.runId, 'run-01');
    expect(config.sample, const Duration(seconds: 60));
    expect(config.total, const Duration(seconds: 102));
    expect(config.warmup, const Duration(seconds: 12));
    expect(config.autoClose, isTrue);
    expect(config.viewportWidth, 1280);
    expect(config.viewportHeight, 720);
    expect(config.nativeContentViewport, isFalse);
  });

  test(
    'macOS runner can delegate exact content viewport sizing to native shell',
    () {
      final config = BattleFrameProfileRunConfig.tryParse(const <String>[
        '--battle-profile-run-id=run-mac',
        '--battle-profile-output=out',
        '--battle-profile-sample-seconds=60',
        '--battle-profile-viewport=1440x900',
        '--battle-profile-native-content-viewport=true',
      ]);

      expect(config?.nativeContentViewport, isTrue);
    },
  );

  test('不允许负采样时长', () {
    expect(
      () => BattleFrameProfileRunConfig.tryParse(const <String>[
        '--battle-profile-run-id=run-01',
        '--battle-profile-output=out',
        '--battle-profile-sample-seconds=-1',
        '--battle-profile-warmup-seconds=12',
        '--battle-profile-viewport=1280x720',
      ]),
      throwsFormatException,
    );
  });

  test('前五秒预热不进入战斗帧性能统计', () {
    final profile = BattleFrameProfileAccumulator(
      warmup: const Duration(seconds: 5),
    );

    profile.add(
      elapsed: const Duration(seconds: 4),
      build: const Duration(milliseconds: 40),
      raster: const Duration(milliseconds: 40),
    );
    profile.add(
      elapsed: const Duration(seconds: 6),
      build: const Duration(milliseconds: 8),
      raster: const Duration(milliseconds: 9),
    );

    expect(profile.summary.sampledFrames, 1);
    expect(profile.summary.maxBuild.inMilliseconds, 8);
    expect(profile.summary.maxRaster.inMilliseconds, 9);
  });

  test('分别记录 build 与 raster 超预算连续帧峰值', () {
    final profile = BattleFrameProfileAccumulator(warmup: Duration.zero);

    for (final (buildMs, rasterMs) in const [
      (18, 8),
      (19, 18),
      (8, 19),
      (20, 20),
      (21, 8),
    ]) {
      profile.add(
        elapsed: const Duration(seconds: 10),
        build: Duration(milliseconds: buildMs),
        raster: Duration(milliseconds: rasterMs),
      );
    }

    expect(profile.summary.maxConsecutiveBuildOverBudget, 2);
    expect(profile.summary.maxConsecutiveRasterOverBudget, 3);
    expect(profile.summary.p99Build.inMilliseconds, 21);
    expect(profile.summary.p99Raster.inMilliseconds, 20);
    expect(profile.summary.passes, isFalse);
  });
}
