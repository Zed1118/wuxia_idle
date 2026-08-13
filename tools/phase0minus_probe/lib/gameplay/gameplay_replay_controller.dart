import 'dart:async';
import 'dart:io';

import 'package:phase0minus_probe/config/probe_config.dart';
import 'package:phase0minus_probe/gameplay/gameplay_game.dart';
import 'package:phase0minus_probe/metrics/frame_collector.dart';
import 'package:phase0minus_probe/metrics/gc_collector.dart';
import 'package:phase0minus_probe/metrics/run_metrics.dart';
import 'package:phase0minus_probe/report/result_writer.dart';
import 'package:window_manager/window_manager.dart';

final class GameplayReplayController {
  GameplayReplayController({
    required this.game,
    required this.config,
    required this.viewport,
    required this.runId,
    required this.durationScale,
    required this.autoClose,
    required this.outputRoot,
    required this.repositoryRoot,
  }) : metrics = RunMetrics(config: config);

  final GameplayGame game;
  final ProbeConfig config;
  final ProbeViewport viewport;
  final String runId;
  final double durationScale;
  final bool autoClose;
  final String outputRoot;
  final String repositoryRoot;
  final RunMetrics metrics;
  final GcCollector gcCollector = GcCollector();
  late final FrameCollector collector = FrameCollector(
    phase: () => phase,
    clearEventId: () => game.clearEventId,
  );
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  RunPhase phase = RunPhase.warmup;
  int _lastMemorySecond = -1;
  bool _finished = false;

  Future<void> start() async {
    await game.loaded;
    await gcCollector.connect();
    collector.attach();
    _stopwatch.start();
    stdout.writeln('PHASE0A_REPLAY_START $runId');
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _tick() {
    final elapsed = _stopwatch.elapsedMilliseconds / 1000;
    final second = elapsed.floor();
    if (second != _lastMemorySecond) {
      _lastMemorySecond = second;
      metrics.recordMemory(_stopwatch.elapsedMilliseconds);
    }
    final warmupEnd = config.warmupSeconds * durationScale;
    final sampleEnd = warmupEnd + config.sampleSeconds * durationScale;
    final cooldownEnd = sampleEnd + config.cooldownSeconds * durationScale;
    if (elapsed >= warmupEnd && phase == RunPhase.warmup) {
      phase = RunPhase.sample;
      metrics.rssAtWarmupEnd = ProcessInfo.currentRss;
    }
    if (elapsed >= sampleEnd && phase == RunPhase.sample) {
      phase = RunPhase.cooldown;
    }
    if (elapsed >= cooldownEnd && phase == RunPhase.cooldown) {
      phase = RunPhase.complete;
      unawaited(_finish());
    }
  }

  Future<void> _finish() async {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    _stopwatch.stop();
    collector.detach();
    metrics.rssAtCooldownEnd = ProcessInfo.currentRss;
    await gcCollector.close();
    final workload = game.replayWorkloadSnapshot()
      ..['duration_scale'] = durationScale
      ..['gate_eligible_duration'] = durationScale == 1
      ..['preliminary_gate'] =
          'FEEDBACK_POOL_PASS_COLLISION_AND_STRATEGY_PENDING';
    final directory = await const ResultWriter().write(
      runId: runId,
      config: config,
      tier: config.tier('target_20_plus_1'),
      viewport: viewport,
      frames: collector.samples,
      metrics: metrics,
      poolSnapshot: game.replayPoolSnapshot(),
      workloadSnapshot: workload,
      outputRoot: outputRoot,
      repositoryRoot: repositoryRoot,
      gcCollector: gcCollector,
    );
    stdout.writeln('PHASE0A_REPLAY_RESULT ${directory.absolute.path}');
    if (autoClose) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await windowManager.close();
    }
  }

  void dispose() {
    _timer?.cancel();
    collector.detach();
    unawaited(gcCollector.close());
  }
}
