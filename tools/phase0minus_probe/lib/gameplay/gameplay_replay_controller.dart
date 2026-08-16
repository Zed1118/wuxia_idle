import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

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
    final poolSnapshot = game.replayPoolSnapshot();
    final feedbackPool =
        poolSnapshot['feedback_residents']! as Map<String, Object?>;
    final damageLabelPool =
        poolSnapshot['damage_label_residents']! as Map<String, Object?>;
    final enemyPool = poolSnapshot['enemy_residents']! as Map<String, Object?>;
    final residentPoolPass =
        feedbackPool['invariant_holds'] == true &&
        feedbackPool['overflow_total'] == 0 &&
        feedbackPool['allocation_after_warmup'] == 0 &&
        damageLabelPool['invariant_holds'] == true &&
        damageLabelPool['overflow_total'] == 0 &&
        damageLabelPool['allocation_after_warmup'] == 0 &&
        enemyPool['invariant_holds'] == true &&
        enemyPool['allocation_after_warmup'] == 0;
    final requiredCoverage = durationScale == 1 ? 5 : 1;
    final workloadCoveragePass =
        game.replayObservedPeakCount >= requiredCoverage &&
        game.clearEventId + 1 >= requiredCoverage;
    final rssAllowance = config.number('thresholds.rss_cooldown_bytes');
    final rssFraction = config.number('thresholds.rss_cooldown_fraction');
    final rssLimit =
        metrics.rssAtWarmupEnd +
        math.max(rssAllowance, metrics.rssAtWarmupEnd * rssFraction);
    final rssPass = metrics.rssAtCooldownEnd <= rssLimit;
    final workloadSnapshot = game.replayWorkloadSnapshot();
    final collision =
        workloadSnapshot['collision_workload']! as Map<String, Object?>;
    final collisionWorkloadPass =
        (collision['resident_hitboxes'] as int) >= 22 &&
        (collision['contact_starts'] as int) > 0 &&
        (collision['range_query_count'] as int) > 0 &&
        (collision['range_query_candidate_checks'] as int) > 0 &&
        (collision['range_query_hits'] as int) > 0;
    final timing = metrics.summarize(
      collector.samples,
      gcTelemetryAvailable: gcCollector.available,
      gcEventCount: gcCollector.events.length,
    );
    final fixturePass =
        timing['gate'] == 'PASS' &&
        residentPoolPass &&
        workloadCoveragePass &&
        rssPass &&
        collisionWorkloadPass;
    final workload = workloadSnapshot
      ..['duration_scale'] = durationScale
      ..['gate_eligible_duration'] = durationScale == 1
      ..['gate_breakdown'] = {
        'timing_gc_gate': timing['gate'],
        'resident_pool_gate': residentPoolPass ? 'PASS' : 'FAIL',
        'workload_coverage_gate': durationScale == 1
            ? workloadCoveragePass
                  ? 'PASS'
                  : 'FAIL'
            : 'INVALID_SHORT_RUN',
        'rss_gate': rssPass ? 'PASS' : 'FAIL',
        'collision_workload_gate': collisionWorkloadPass ? 'PASS' : 'FAIL',
        'strategy_gate': 'PENDING',
      }
      ..['overall_preliminary_status'] = fixturePass && durationScale == 1
          ? 'PERFORMANCE_FIXTURE_PASS_GAMEPLAY_GATES_PENDING'
          : durationScale == 1
          ? 'PERFORMANCE_FIXTURE_FAIL'
          : 'INVALID_SHORT_RUN';
    final directory = await const ResultWriter().write(
      runId: runId,
      config: config,
      tier: config.tier('target_20_plus_1'),
      viewport: viewport,
      frames: collector.samples,
      metrics: metrics,
      poolSnapshot: poolSnapshot,
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
