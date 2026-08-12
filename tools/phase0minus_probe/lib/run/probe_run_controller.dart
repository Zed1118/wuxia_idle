import 'dart:async';
import 'dart:io';

import 'package:phase0minus_probe/config/probe_config.dart';
import 'package:phase0minus_probe/metrics/frame_collector.dart';
import 'package:phase0minus_probe/metrics/run_metrics.dart';
import 'package:phase0minus_probe/report/result_writer.dart';
import 'package:phase0minus_probe/workload/probe_game.dart';
import 'package:window_manager/window_manager.dart';

final class ProbeRunController {
  ProbeRunController({
    required this.game,
    required this.config,
    required this.tier,
    required this.viewport,
    required this.runId,
    required this.durationScale,
    required this.autoClose,
    required this.outputRoot,
    required this.repositoryRoot,
  }) : metrics = RunMetrics(config: config);

  final ProbeGame game;
  final ProbeConfig config;
  final ProbeTier tier;
  final ProbeViewport viewport;
  final String runId;
  final double durationScale;
  final bool autoClose;
  final String outputRoot;
  final String repositoryRoot;
  final RunMetrics metrics;
  late final FrameCollector collector = FrameCollector(
    phase: () => phase,
    clearEventId: () => game.clearEventId,
  );
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  RunPhase phase = RunPhase.warmup;
  var _lastMemorySecond = -1;
  bool _finished = false;

  Future<void> start() async {
    await game.loaded;
    collector.attach();
    _stopwatch.start();
    stdout.writeln('PHASE0_MINUS_RUN_START $runId');
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
      game.markWarmupComplete();
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
    final workload = game.workloadSnapshot()
      ..['duration_scale'] = durationScale
      ..['gate_eligible_duration'] = durationScale == 1;
    final directory = await const ResultWriter().write(
      runId: runId,
      config: config,
      tier: tier,
      viewport: viewport,
      frames: collector.samples,
      metrics: metrics,
      poolSnapshot: game.poolSnapshot(),
      workloadSnapshot: workload,
      outputRoot: outputRoot,
      repositoryRoot: repositoryRoot,
    );
    stdout.writeln('PHASE0_MINUS_RESULT ${directory.absolute.path}');
    stdout.writeln('GC_TELEMETRY_MISSING: run cannot PASS');
    if (autoClose) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await windowManager.close();
    }
  }

  void dispose() {
    _timer?.cancel();
    collector.detach();
  }
}
