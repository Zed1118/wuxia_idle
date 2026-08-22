import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

const _frameBudget = Duration(microseconds: 16600);
const _severeFrame = Duration(microseconds: 33300);

final class BattleFrameProfileRunConfig {
  const BattleFrameProfileRunConfig({
    required this.runId,
    required this.outputDirectory,
    required this.sample,
    required this.warmup,
    required this.cooldown,
    required this.autoClose,
    required this.viewportWidth,
    required this.viewportHeight,
  });

  final String runId;
  final String outputDirectory;
  final Duration sample;
  final Duration warmup;
  final Duration cooldown;
  final bool autoClose;
  final double viewportWidth;
  final double viewportHeight;

  Duration get total => warmup + sample + cooldown;

  static BattleFrameProfileRunConfig? tryParse(List<String> args) {
    final values = <String, String>{};
    for (final argument in args) {
      if (!argument.startsWith('--battle-profile-')) continue;
      final separator = argument.indexOf('=');
      if (separator <= 2) {
        throw const FormatException(
          'Battle profile arguments must use --key=value.',
        );
      }
      values[argument.substring(2, separator)] = argument.substring(
        separator + 1,
      );
    }
    if (values.isEmpty) return null;
    final runId = values['battle-profile-run-id'] ?? '';
    final output = values['battle-profile-output'] ?? '';
    final sampleSeconds = int.tryParse(
      values['battle-profile-sample-seconds'] ?? '',
    );
    final warmupSeconds = int.tryParse(
      values['battle-profile-warmup-seconds'] ?? '12',
    );
    final cooldownSeconds = int.tryParse(
      values['battle-profile-cooldown-seconds'] ?? '30',
    );
    final viewport = RegExp(
      r'^(\d+)x(\d+)$',
    ).firstMatch(values['battle-profile-viewport'] ?? '');
    if (runId.isEmpty ||
        output.isEmpty ||
        sampleSeconds == null ||
        sampleSeconds <= 0) {
      throw const FormatException(
        'Battle profile requires run-id, output and positive sample seconds.',
      );
    }
    if (warmupSeconds == null ||
        warmupSeconds < 0 ||
        cooldownSeconds == null ||
        cooldownSeconds < 0) {
      throw const FormatException(
        'Battle profile warmup and cooldown must be non-negative.',
      );
    }
    if (viewport == null) {
      throw const FormatException(
        'Battle profile requires viewport formatted as WIDTHxHEIGHT.',
      );
    }
    return BattleFrameProfileRunConfig(
      runId: runId,
      outputDirectory: output,
      sample: Duration(seconds: sampleSeconds),
      warmup: Duration(seconds: warmupSeconds),
      cooldown: Duration(seconds: cooldownSeconds),
      autoClose: values['battle-profile-auto-close'] == 'true',
      viewportWidth: double.parse(viewport.group(1)!),
      viewportHeight: double.parse(viewport.group(2)!),
    );
  }
}

final class BattleFrameProfileSample {
  const BattleFrameProfileSample({
    required this.elapsedUs,
    required this.buildUs,
    required this.rasterUs,
    required this.totalSpanUs,
    required this.rssBytes,
  });

  final int elapsedUs;
  final int buildUs;
  final int rasterUs;
  final int totalSpanUs;
  final int rssBytes;

  Map<String, Object> toJson() => <String, Object>{
    'elapsed_us': elapsedUs,
    'build_us': buildUs,
    'raster_us': rasterUs,
    'total_span_us': totalSpanUs,
    'rss_bytes': rssBytes,
  };
}

class BattleFrameProfileSummary {
  const BattleFrameProfileSummary({
    required this.sampledFrames,
    required this.maxBuild,
    required this.maxRaster,
    required this.p99Build,
    required this.p99Raster,
    required this.p99TotalSpan,
    required this.maxConsecutiveBuildOverBudget,
    required this.maxConsecutiveRasterOverBudget,
    required this.maxConsecutiveSevereFrames,
  });

  final int sampledFrames;
  final Duration maxBuild;
  final Duration maxRaster;
  final Duration p99Build;
  final Duration p99Raster;
  final Duration p99TotalSpan;
  final int maxConsecutiveBuildOverBudget;
  final int maxConsecutiveRasterOverBudget;
  final int maxConsecutiveSevereFrames;

  bool get passes =>
      sampledFrames > 0 &&
      p99TotalSpan < _frameBudget &&
      maxConsecutiveSevereFrames <= 1 &&
      maxConsecutiveBuildOverBudget < 3 &&
      maxConsecutiveRasterOverBudget < 3;

  Map<String, Object> toJson({
    required int totalSeconds,
    required int warmupSeconds,
  }) => <String, Object>{
    'total_seconds': totalSeconds,
    'warmup_seconds': warmupSeconds,
    'sampled_frames': sampledFrames,
    'max_build_ms': maxBuild.inMicroseconds / 1000,
    'max_raster_ms': maxRaster.inMicroseconds / 1000,
    'p99_build_ms': p99Build.inMicroseconds / 1000,
    'p99_raster_ms': p99Raster.inMicroseconds / 1000,
    'p99_total_span_ms': p99TotalSpan.inMicroseconds / 1000,
    'max_consecutive_build_over_budget': maxConsecutiveBuildOverBudget,
    'max_consecutive_raster_over_budget': maxConsecutiveRasterOverBudget,
    'max_consecutive_severe_frames': maxConsecutiveSevereFrames,
    'frame_streak_gate_passes': passes,
  };

  String toJsonLine({required int totalSeconds, required int warmupSeconds}) =>
      jsonEncode(
        toJson(totalSeconds: totalSeconds, warmupSeconds: warmupSeconds),
      );
}

class BattleFrameProfileAccumulator {
  BattleFrameProfileAccumulator({required this.warmup, this.sampleDuration});

  final Duration warmup;
  final Duration? sampleDuration;
  final List<BattleFrameProfileSample> samples = <BattleFrameProfileSample>[];
  Duration _maxBuild = Duration.zero;
  Duration _maxRaster = Duration.zero;
  int _buildStreak = 0;
  int _rasterStreak = 0;
  int _maxBuildStreak = 0;
  int _maxRasterStreak = 0;
  int _severeStreak = 0;
  int _maxSevereStreak = 0;

  void add({
    required Duration elapsed,
    required Duration build,
    required Duration raster,
    Duration? totalSpan,
    int rssBytes = 0,
  }) {
    if (elapsed < warmup ||
        (sampleDuration != null && elapsed >= warmup + sampleDuration!)) {
      return;
    }
    samples.add(
      BattleFrameProfileSample(
        elapsedUs: elapsed.inMicroseconds,
        buildUs: build.inMicroseconds,
        rasterUs: raster.inMicroseconds,
        totalSpanUs: (totalSpan ?? build + raster).inMicroseconds,
        rssBytes: rssBytes,
      ),
    );
    if (build > _maxBuild) _maxBuild = build;
    if (raster > _maxRaster) _maxRaster = raster;
    _buildStreak = build > _frameBudget ? _buildStreak + 1 : 0;
    _rasterStreak = raster > _frameBudget ? _rasterStreak + 1 : 0;
    if (_buildStreak > _maxBuildStreak) _maxBuildStreak = _buildStreak;
    if (_rasterStreak > _maxRasterStreak) _maxRasterStreak = _rasterStreak;
    _severeStreak = (totalSpan ?? build + raster) > _severeFrame
        ? _severeStreak + 1
        : 0;
    if (_severeStreak > _maxSevereStreak) {
      _maxSevereStreak = _severeStreak;
    }
  }

  BattleFrameProfileSummary get summary => BattleFrameProfileSummary(
    sampledFrames: samples.length,
    maxBuild: _maxBuild,
    maxRaster: _maxRaster,
    p99Build: _percentile(samples.map((sample) => sample.buildUs), 0.99),
    p99Raster: _percentile(samples.map((sample) => sample.rasterUs), 0.99),
    p99TotalSpan: _percentile(
      samples.map((sample) => sample.totalSpanUs),
      0.99,
    ),
    maxConsecutiveBuildOverBudget: _maxBuildStreak,
    maxConsecutiveRasterOverBudget: _maxRasterStreak,
    maxConsecutiveSevereFrames: _maxSevereStreak,
  );

  static Duration _percentile(Iterable<int> values, double percentile) {
    final sorted = values.toList()..sort();
    if (sorted.isEmpty) return Duration.zero;
    final index = ((sorted.length - 1) * percentile).ceil();
    return Duration(microseconds: sorted[index]);
  }
}

final class _BattleProfileGcCollector {
  final List<Map<String, Object?>> events = <Map<String, Object?>>[];
  VmService? _service;
  StreamSubscription<Event>? _subscription;
  String status = 'GC_TELEMETRY_NOT_STARTED';
  String? error;

  Future<void> connect() async {
    try {
      final uri = (await developer.Service.getInfo()).serverWebSocketUri;
      if (uri == null) throw StateError('Dart VM service URI is unavailable.');
      final service = await vmServiceConnectUri(uri.toString());
      await service.streamListen(EventStreams.kGC);
      _service = service;
      _subscription = service.onGCEvent.listen((event) {
        events.add(<String, Object?>{
          'record_type': 'gc_event',
          'timestamp_ms': event.timestamp,
          'gc_type': event.gcType,
          'isolate_id': event.isolate?.id,
          'isolate_group_id': event.isolateGroup?.id,
        });
      });
      status = 'GC_TELEMETRY_COLLECTED';
    } on Object catch (exception) {
      status = 'GC_TELEMETRY_MISSING';
      error = exception.toString();
    }
  }

  Future<void> close() async {
    await _subscription?.cancel();
    await _service?.dispose();
    _subscription = null;
    _service = null;
  }
}

/// 仅由 profile 验收命令的运行时参数或历史 dart-define 启用。
class BattleFrameProfileProbe extends StatefulWidget {
  const BattleFrameProfileProbe({super.key, required this.child});

  final Widget child;
  static BattleFrameProfileRunConfig? _runtimeConfig;

  static BattleFrameProfileRunConfig? configureFromArgs(List<String> args) {
    return _runtimeConfig = BattleFrameProfileRunConfig.tryParse(args);
  }

  static Widget maybeWrap(Widget child) {
    const legacySeconds = int.fromEnvironment('BATTLE_FRAME_PROFILE_SECONDS');
    if (_runtimeConfig == null && legacySeconds <= 0) return child;
    return BattleFrameProfileProbe(child: child);
  }

  @override
  State<BattleFrameProfileProbe> createState() =>
      _BattleFrameProfileProbeState();
}

class _BattleFrameProfileProbeState extends State<BattleFrameProfileProbe> {
  static const _legacyWarmup = Duration(seconds: 5);
  static const _legacyTotalSeconds = int.fromEnvironment(
    'BATTLE_FRAME_PROFILE_SECONDS',
  );

  final Stopwatch _elapsed = Stopwatch();
  final _gc = _BattleProfileGcCollector();
  final List<Map<String, Object>> _memorySamples = <Map<String, Object>>[];
  late final BattleFrameProfileRunConfig? _config;
  late final BattleFrameProfileAccumulator _profile;
  Timer? _finishTimer;
  Timer? _memoryTimer;
  bool _reported = false;
  double? _logicalWidth;
  double? _logicalHeight;
  double? _devicePixelRatio;

  Duration get _total =>
      _config?.total ?? const Duration(seconds: _legacyTotalSeconds);

  @override
  void initState() {
    super.initState();
    _config = BattleFrameProfileProbe._runtimeConfig;
    _profile = BattleFrameProfileAccumulator(
      warmup: _config?.warmup ?? _legacyWarmup,
      sampleDuration: _config?.sample,
    );
    _elapsed.start();
    SchedulerBinding.instance.addTimingsCallback(_recordTimings);
    unawaited(_gc.connect());
    _recordMemory();
    _memoryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recordMemory();
    });
    _finishTimer = Timer(_total, () => unawaited(_report()));
  }

  void _recordTimings(List<FrameTiming> timings) {
    final rss = ProcessInfo.currentRss;
    for (final timing in timings) {
      _profile.add(
        elapsed: _elapsed.elapsed,
        build: timing.buildDuration,
        raster: timing.rasterDuration,
        totalSpan: timing.totalSpan,
        rssBytes: rss,
      );
    }
  }

  void _recordMemory() {
    _memorySamples.add(<String, Object>{
      'record_type': 'memory_sample',
      'elapsed_ms': _elapsed.elapsedMilliseconds,
      'rss_bytes': ProcessInfo.currentRss,
    });
  }

  Future<void> _report() async {
    if (_reported) return;
    _reported = true;
    _memoryTimer?.cancel();
    SchedulerBinding.instance.removeTimingsCallback(_recordTimings);
    _recordMemory();
    final media = MediaQuery.maybeOf(context);
    _logicalWidth = media?.size.width;
    _logicalHeight = media?.size.height;
    _devicePixelRatio = media?.devicePixelRatio;
    await _gc.close();
    final summary = _profile.summary;
    final line = summary.toJsonLine(
      totalSeconds: _total.inSeconds,
      warmupSeconds: _profile.warmup.inSeconds,
    );
    debugPrint('BATTLE_FRAME_PROFILE_SUMMARY: $line');
    final config = _config;
    if (config != null) {
      await _writeEvidence(config, summary);
      debugPrint('BATTLE_FRAME_PROFILE_RESULT: ${config.outputDirectory}');
      if (config.autoClose) await SystemNavigator.pop();
    }
  }

  Future<void> _writeEvidence(
    BattleFrameProfileRunConfig config,
    BattleFrameProfileSummary summary,
  ) async {
    final directory = Directory(config.outputDirectory);
    await directory.create(recursive: true);
    await File('${directory.path}/frames.jsonl').writeAsString(
      '${_profile.samples.map((sample) => jsonEncode(sample.toJson())).join('\n')}\n',
    );
    final memoryGc = <Map<String, Object?>>[
      ..._memorySamples,
      ..._gc.events,
      <String, Object?>{
        'record_type': 'gc_status',
        'status': _gc.status,
        'error': _gc.error,
      },
    ];
    await File(
      '${directory.path}/memory_gc.jsonl',
    ).writeAsString('${memoryGc.map(jsonEncode).join('\n')}\n');
    final rssValues = _memorySamples
        .map((sample) => sample['rss_bytes']! as int)
        .toList(growable: false);
    final payload = <String, Object?>{
      'schema': 'route-c-production-profile-summary-v1',
      'run_id': config.runId,
      ...summary.toJson(
        totalSeconds: config.total.inSeconds,
        warmupSeconds: config.warmup.inSeconds,
      ),
      'sample_seconds': config.sample.inSeconds,
      'cooldown_seconds': config.cooldown.inSeconds,
      'rss_start_bytes': rssValues.first,
      'rss_peak_bytes': rssValues.reduce((a, b) => a > b ? a : b),
      'rss_end_bytes': rssValues.last,
      'gc_telemetry_status': _gc.status,
      'gc_event_count': _gc.events.length,
      'logical_width': _logicalWidth,
      'logical_height': _logicalHeight,
      'device_pixel_ratio': _devicePixelRatio,
    };
    await File(
      '${directory.path}/summary.json',
    ).writeAsString('${const JsonEncoder.withIndent('  ').convert(payload)}\n');
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    _memoryTimer?.cancel();
    if (!_reported) {
      SchedulerBinding.instance.removeTimingsCallback(_recordTimings);
    }
    _elapsed.stop();
    unawaited(_gc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
