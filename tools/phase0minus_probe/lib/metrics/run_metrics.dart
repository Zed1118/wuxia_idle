import 'dart:io';

import 'package:phase0minus_probe/config/probe_config.dart';
import 'package:phase0minus_probe/metrics/frame_collector.dart';
import 'package:phase0minus_probe/metrics/frame_statistics.dart';

final class MemorySample {
  const MemorySample({required this.elapsedMs, required this.rssBytes});

  final int elapsedMs;
  final int rssBytes;

  Map<String, int> toJson() => {'elapsed_ms': elapsedMs, 'rss_bytes': rssBytes};
}

final class RunMetrics {
  RunMetrics({required this.config});

  final ProbeConfig config;
  final List<MemorySample> memory = [];
  int rssAtWarmupEnd = 0;
  int rssAtCooldownEnd = 0;

  void recordMemory(int elapsedMs) {
    memory.add(
      MemorySample(elapsedMs: elapsedMs, rssBytes: ProcessInfo.currentRss),
    );
  }

  Map<String, Object?> summarize(List<FrameSample> samples) {
    if (samples.isEmpty) {
      return {
        'validity': 'INVALID_INSUFFICIENT_FRAMES',
        'frames': 0,
        'gc_telemetry': 'GC_TELEMETRY_MISSING',
        'gate': 'BLOCKED',
      };
    }
    final total = samples.map((sample) => sample.totalSpanUs).toList();
    final build = samples.map((sample) => sample.buildDurationUs).toList();
    final raster = samples.map((sample) => sample.rasterDurationUs).toList();
    final overBudget = total
        .where((value) => value >= config.frameBudgetUs)
        .length;
    final severe = total.where((value) => value > config.severeFrameUs).length;
    final severeStreak = maximumConsecutiveAbove(total, config.severeFrameUs);
    final enoughFrames = samples.length >= config.minimumValidFrames;
    final timingPass =
        nearestRank(total, 0.99) < config.frameBudgetUs &&
        severeStreak <= config.maximumSevereStreak;

    return {
      'validity': enoughFrames ? 'VALID' : 'INVALID_INSUFFICIENT_FRAMES',
      'frames': samples.length,
      'total_span': DurationSummary.from(total).toJson(),
      'build_duration': DurationSummary.from(build).toJson(),
      'raster_duration': DurationSummary.from(raster).toJson(),
      'over_budget_count': overBudget,
      'over_budget_fraction': overBudget / total.length,
      'severe_count': severe,
      'maximum_severe_streak': severeStreak,
      'rss_warmup_end_bytes': rssAtWarmupEnd,
      'rss_peak_bytes': memory.isEmpty
          ? 0
          : memory
                .map((sample) => sample.rssBytes)
                .reduce((a, b) => a > b ? a : b),
      'rss_cooldown_end_bytes': rssAtCooldownEnd,
      'timing_gate': enoughFrames
          ? timingPass
                ? 'PASS'
                : 'FAIL'
          : 'INVALID',
      'gc_telemetry': 'GC_TELEMETRY_MISSING',
      'gate': 'BLOCKED',
      'gate_reason': 'GC telemetry is mandatory and was not collected.',
    };
  }
}
