import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/debug/application/battle_frame_profile.dart';

void main() {
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
    expect(profile.summary.passes, isFalse);
  });
}
