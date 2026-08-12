import 'dart:io';

import 'package:flutter/scheduler.dart';

enum RunPhase { warmup, sample, cooldown, complete }

final class FrameSample {
  const FrameSample({
    required this.sequence,
    required this.timestampUs,
    required this.buildDurationUs,
    required this.rasterDurationUs,
    required this.totalSpanUs,
    required this.rssBytes,
    required this.clearEventId,
  });

  final int sequence;
  final int timestampUs;
  final int buildDurationUs;
  final int rasterDurationUs;
  final int totalSpanUs;
  final int rssBytes;
  final int clearEventId;

  Map<String, Object> toJson() => {
    'sequence': sequence,
    'timestamp_us': timestampUs,
    'build_duration_us': buildDurationUs,
    'raster_duration_us': rasterDurationUs,
    'total_span_us': totalSpanUs,
    'rss_bytes': rssBytes,
    'clear_event_id': clearEventId,
  };
}

final class FrameCollector {
  FrameCollector({
    required RunPhase Function() phase,
    required int Function() clearEventId,
  }) : _phase = phase,
       _clearEventId = clearEventId;

  final RunPhase Function() _phase;
  final int Function() _clearEventId;
  final List<FrameSample> samples = [];
  var _sequence = 0;
  bool _attached = false;

  void attach() {
    if (_attached) return;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _attached = true;
  }

  void detach() {
    if (!_attached) return;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _attached = false;
  }

  void _onTimings(List<FrameTiming> timings) {
    if (_phase() != RunPhase.sample) return;
    final rss = ProcessInfo.currentRss;
    for (final timing in timings) {
      samples.add(
        FrameSample(
          sequence: _sequence++,
          timestampUs: DateTime.now().microsecondsSinceEpoch,
          buildDurationUs: timing.buildDuration.inMicroseconds,
          rasterDurationUs: timing.rasterDuration.inMicroseconds,
          totalSpanUs: timing.totalSpan.inMicroseconds,
          rssBytes: rss,
          clearEventId: _clearEventId(),
        ),
      );
    }
  }
}
