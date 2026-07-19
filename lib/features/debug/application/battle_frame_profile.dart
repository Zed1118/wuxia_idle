import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

const _frameBudget = Duration(microseconds: 16700);

class BattleFrameProfileSummary {
  const BattleFrameProfileSummary({
    required this.sampledFrames,
    required this.maxBuild,
    required this.maxRaster,
    required this.maxConsecutiveBuildOverBudget,
    required this.maxConsecutiveRasterOverBudget,
  });

  final int sampledFrames;
  final Duration maxBuild;
  final Duration maxRaster;
  final int maxConsecutiveBuildOverBudget;
  final int maxConsecutiveRasterOverBudget;

  bool get passes =>
      sampledFrames > 0 &&
      maxConsecutiveBuildOverBudget < 3 &&
      maxConsecutiveRasterOverBudget < 3;

  String toJsonLine({required int totalSeconds, required int warmupSeconds}) {
    return '{'
        '"totalSeconds":$totalSeconds,'
        '"warmupSeconds":$warmupSeconds,'
        '"sampledFrames":$sampledFrames,'
        '"maxBuildMs":${(maxBuild.inMicroseconds / 1000).toStringAsFixed(3)},'
        '"maxRasterMs":${(maxRaster.inMicroseconds / 1000).toStringAsFixed(3)},'
        '"maxConsecutiveBuildOverBudget":$maxConsecutiveBuildOverBudget,'
        '"maxConsecutiveRasterOverBudget":$maxConsecutiveRasterOverBudget,'
        '"passes":$passes'
        '}';
  }
}

class BattleFrameProfileAccumulator {
  BattleFrameProfileAccumulator({required this.warmup});

  final Duration warmup;
  int _sampledFrames = 0;
  Duration _maxBuild = Duration.zero;
  Duration _maxRaster = Duration.zero;
  int _buildStreak = 0;
  int _rasterStreak = 0;
  int _maxBuildStreak = 0;
  int _maxRasterStreak = 0;

  void add({
    required Duration elapsed,
    required Duration build,
    required Duration raster,
  }) {
    if (elapsed < warmup) return;
    _sampledFrames++;
    if (build > _maxBuild) _maxBuild = build;
    if (raster > _maxRaster) _maxRaster = raster;
    _buildStreak = build > _frameBudget ? _buildStreak + 1 : 0;
    _rasterStreak = raster > _frameBudget ? _rasterStreak + 1 : 0;
    if (_buildStreak > _maxBuildStreak) _maxBuildStreak = _buildStreak;
    if (_rasterStreak > _maxRasterStreak) _maxRasterStreak = _rasterStreak;
  }

  BattleFrameProfileSummary get summary => BattleFrameProfileSummary(
    sampledFrames: _sampledFrames,
    maxBuild: _maxBuild,
    maxRaster: _maxRaster,
    maxConsecutiveBuildOverBudget: _maxBuildStreak,
    maxConsecutiveRasterOverBudget: _maxRasterStreak,
  );
}

/// 仅由 profile 验收命令的 dart-define 启用，不进入正常游戏路径。
class BattleFrameProfileProbe extends StatefulWidget {
  const BattleFrameProfileProbe({super.key, required this.child});

  final Widget child;

  static Widget maybeWrap(Widget child) {
    const seconds = int.fromEnvironment('BATTLE_FRAME_PROFILE_SECONDS');
    if (seconds <= 0) return child;
    return BattleFrameProfileProbe(child: child);
  }

  @override
  State<BattleFrameProfileProbe> createState() =>
      _BattleFrameProfileProbeState();
}

class _BattleFrameProfileProbeState extends State<BattleFrameProfileProbe> {
  static const _warmup = Duration(seconds: 5);
  static const _totalSeconds = int.fromEnvironment(
    'BATTLE_FRAME_PROFILE_SECONDS',
  );

  final Stopwatch _elapsed = Stopwatch();
  late final BattleFrameProfileAccumulator _profile;
  Timer? _finishTimer;

  @override
  void initState() {
    super.initState();
    _profile = BattleFrameProfileAccumulator(warmup: _warmup);
    _elapsed.start();
    SchedulerBinding.instance.addTimingsCallback(_recordTimings);
    _finishTimer = Timer(const Duration(seconds: _totalSeconds), _report);
  }

  void _recordTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _profile.add(
        elapsed: _elapsed.elapsed,
        build: timing.buildDuration,
        raster: timing.rasterDuration,
      );
    }
  }

  void _report() {
    final line = _profile.summary.toJsonLine(
      totalSeconds: _totalSeconds,
      warmupSeconds: _warmup.inSeconds,
    );
    debugPrint('BATTLE_FRAME_PROFILE_SUMMARY: $line');
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    SchedulerBinding.instance.removeTimingsCallback(_recordTimings);
    _elapsed.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
