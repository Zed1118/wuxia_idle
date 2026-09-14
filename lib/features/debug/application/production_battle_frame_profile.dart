import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import 'battle_frame_profile.dart';

/// Validates a real battle interval separately from its raw frame timings.
/// Neither menu frames nor a short/paused/finished fight can certify a run.
final class ProductionProfileWindow {
  ProductionProfileWindow(this.config);

  final BattleFrameProfileRunConfig config;
  final Set<String> invalidReasons = {};
  final Set<int> _workloadSeconds = {};
  int? _previousTick;
  Duration? _previousWorkloadTime;
  double? _sampleDpr;
  double? get sampleDpr => _sampleDpr;

  bool isSampling(Duration elapsed) =>
      elapsed >= config.warmup && elapsed < config.warmup + config.sample;

  void activity(
    Duration elapsed, {
    required bool paused,
    required bool foreground,
    required bool combatOngoing,
  }) {
    if (!isSampling(elapsed)) return;
    if (paused) invalidReasons.add('paused_during_sample');
    if (!foreground) invalidReasons.add('backgrounded_during_sample');
    if (!combatOngoing) invalidReasons.add('combat_finished_during_sample');
  }

  void viewport(Duration elapsed, double? width, double? height, double? dpr) {
    if (!isSampling(elapsed)) return;
    if (width != config.viewportWidth ||
        height != config.viewportHeight ||
        dpr == null ||
        dpr <= 0) {
      invalidReasons.add('viewport_mismatch');
    }
    if (_sampleDpr != null && dpr != _sampleDpr) {
      invalidReasons.add('device_pixel_ratio_changed');
    }
    _sampleDpr ??= dpr;
  }

  void workload(Duration elapsed, Map<String, Object?> value) {
    final tick = value['tick'];
    if (tick is! int ||
        value['active_enemies'] is! int ||
        value['combat_ongoing'] is! bool) {
      invalidReasons.add('invalid_workload_record');
      return;
    }
    if (isSampling(elapsed)) {
      _workloadSeconds.add((elapsed - config.warmup).inSeconds);
      if (value['combat_ongoing'] != true) {
        invalidReasons.add('combat_finished_during_sample');
      }
      final previous = _previousWorkloadTime;
      if (previous != null &&
          isSampling(previous) &&
          elapsed - previous >= const Duration(milliseconds: 900) &&
          tick <= (_previousTick ?? tick)) {
        invalidReasons.add('simulation_not_advancing');
      }
    }
    _previousTick = tick;
    _previousWorkloadTime = elapsed;
  }

  Set<String> reasonsAtEnd({
    required Duration elapsed,
    required String reason,
    required int sampledFrames,
  }) => {
    ...invalidReasons,
    if (reason != 'timer_completed' || elapsed < config.total)
      'capture_ended_early',
    if (config.sample < const Duration(seconds: 60)) 'sample_shorter_than_60s',
    if (config.cooldown < const Duration(seconds: 30))
      'cooldown_shorter_than_30s',
    if (sampledFrames < config.sample.inSeconds * 50) 'insufficient_frames',
    if (_workloadSeconds.length < config.sample.inSeconds)
      'incomplete_workload_coverage',
  };
}

/// Opt-in wrapper around an already-ready production Host's battle screen.
/// The entry origin and exact content selection are owned by main/configure.
final class ProductionBattleFrameProfile extends StatefulWidget {
  const ProductionBattleFrameProfile({
    super.key,
    required this.child,
    required this.owner,
    required this.config,
    required this.scene,
    required this.readWorkload,
    required this.isCombatOngoing,
  });

  final Widget child;
  final Listenable owner;
  final BattleFrameProfileRunConfig config;
  final Map<String, Object?> scene;
  final Map<String, Object?> Function() readWorkload;
  final bool Function() isCombatOngoing;

  static _ProductionBattleFrameProfileState? _active;
  static final Set<Future<void>> _pendingWrites = {};

  static bool get isCapturing => _active != null;

  static void recordActivity(
    Object owner, {
    required bool paused,
    required bool foreground,
    required bool combatOngoing,
  }) {
    final active = _active;
    if (active != null && identical(owner, active.widget.owner)) {
      active._window.activity(
        active._elapsed.elapsed,
        paused: paused,
        foreground: foreground && active._foreground,
        combatOngoing: combatOngoing,
      );
      active._window.viewport(
        active._elapsed.elapsed,
        active._width,
        active._height,
        active._dpr,
      );
    }
  }

  /// Used by verification/controlled shutdown; does not delay gameplay routes.
  static Future<void> flushPendingEvidence() async {
    while (_pendingWrites.isNotEmpty) {
      await Future.wait(_pendingWrites.toList());
    }
  }

  @override
  State<ProductionBattleFrameProfile> createState() =>
      _ProductionBattleFrameProfileState();
}

class _ProductionBattleFrameProfileState
    extends State<ProductionBattleFrameProfile>
    with WidgetsBindingObserver {
  final _elapsed = Stopwatch();
  final _gc = BattleProfileGcCollector();
  final List<Map<String, Object?>> _memory = [];
  final List<Map<String, Object?>> _workloads = [];
  late final ProductionProfileWindow _window;
  late final BattleFrameProfileAccumulator _frames;
  Timer? _finishTimer;
  Timer? _memoryTimer;
  Future<void>? _connection;
  bool _started = false;
  bool _finished = false;
  double? _width;
  double? _height;
  double? _dpr;
  bool _foreground = false;

  @override
  void initState() {
    super.initState();
    _window = ProductionProfileWindow(widget.config);
    _frames = BattleFrameProfileAccumulator(
      warmup: widget.config.warmup,
      sampleDuration: widget.config.sample,
    );
    if (!BattleFrameProfileProbe.claimProductionRun(widget.config)) return;
    final directory = Directory(widget.config.outputDirectory);
    if ([
      'summary.json',
      'frames.jsonl',
      'workload.jsonl',
      'memory_gc.jsonl',
    ].any((name) => File('${directory.path}/$name').existsSync())) {
      debugPrint(
        'PRODUCTION_BATTLE_PROFILE_REJECTED: evidence output already exists',
      );
      return;
    }
    _started = true;
    _foreground =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    ProductionBattleFrameProfile._active = this;
    _elapsed.start();
    WidgetsBinding.instance.addObserver(this);
    widget.owner.addListener(_combatChanged);
    _combatChanged();
    SchedulerBinding.instance.addTimingsCallback(_recordFrames);
    _connection = _gc.connect();
    _recordWorkload();
    _memoryTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _recordWorkload(),
    );
    _finishTimer = Timer(
      widget.config.total,
      () => _queueFinish('timer_completed'),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _combatChanged();
  }

  void _combatChanged() => _window.activity(
    _elapsed.elapsed,
    paused: false,
    foreground: _foreground,
    combatOngoing: widget.isCombatOngoing(),
  );

  void _recordFrames(List<FrameTiming> timings) {
    for (final timing in timings) {
      _frames.add(
        elapsed: _elapsed.elapsed,
        build: timing.buildDuration,
        raster: timing.rasterDuration,
        totalSpan: timing.totalSpan,
        rssBytes: ProcessInfo.currentRss,
      );
    }
  }

  void _recordWorkload() {
    final elapsed = _elapsed.elapsed;
    _memory.add({
      'record_type': 'memory_sample',
      'elapsed_ms': elapsed.inMilliseconds,
      'rss_bytes': ProcessInfo.currentRss,
      'gate_eligible': elapsed >= widget.config.warmup,
    });
    try {
      final value = widget.readWorkload();
      _window.workload(elapsed, value);
      _workloads.add({
        'elapsed_us': elapsed.inMicroseconds,
        'logical_width': _width,
        'logical_height': _height,
        'device_pixel_ratio': _dpr,
        'foreground': _foreground,
        ...value,
      });
    } on Object catch (error) {
      _window.invalidReasons.add('workload_read_failed');
      _workloads.add({
        'elapsed_us': elapsed.inMicroseconds,
        'error': error.toString(),
      });
    }
  }

  void _queueFinish(String reason) {
    if (!_started || _finished) return;
    _finished = true;
    _finishTimer?.cancel();
    _memoryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.owner.removeListener(_combatChanged);
    SchedulerBinding.instance.removeTimingsCallback(_recordFrames);
    _recordWorkload();
    _elapsed.stop();
    if (identical(ProductionBattleFrameProfile._active, this)) {
      ProductionBattleFrameProfile._active = null;
    }
    final write = _writeEvidence(reason);
    ProductionBattleFrameProfile._pendingWrites.add(write);
    unawaited(
      write.whenComplete(
        () => ProductionBattleFrameProfile._pendingWrites.remove(write),
      ),
    );
  }

  Future<void> _writeEvidence(String reason) async {
    try {
      await _connection;
      await _gc.close();
      final summary = _frames.summary;
      final invalid = _window.reasonsAtEnd(
        elapsed: _elapsed.elapsed,
        reason: reason,
        sampledFrames: summary.sampledFrames,
      );
      if (_width != widget.config.viewportWidth ||
          _height != widget.config.viewportHeight ||
          _dpr == null) {
        invalid.add('viewport_mismatch');
      }
      if (widget.config.diagnostics) invalid.add('diagnostic_run_not_baseline');
      if (_gc.status != 'GC_TELEMETRY_COLLECTED') {
        invalid.add('gc_telemetry_missing');
      }
      final rss = _memory
          .where((m) => m['gate_eligible'] == true)
          .map((m) => m['rss_bytes']! as int)
          .toList();
      final rssGate = rss.isNotEmpty && rss.last <= rss.first * 1.10 + 67108864;
      final valid = invalid.isEmpty;
      final payload = <String, Object?>{
        'schema': 'production-host-profile-v1',
        'run_id': widget.config.runId,
        'evidence_kind': 'normal_root_production_host',
        'entry_origin': 'normal_root',
        'scene': widget.scene,
        'capture_end_reason': reason,
        'capture_elapsed_us': _elapsed.elapsedMicroseconds,
        'sample_seconds': widget.config.sample.inSeconds,
        'cooldown_seconds': widget.config.cooldown.inSeconds,
        'cooldown_observation':
            'host_still_mounted; not proof of released battle pools',
        'sampling_status': valid ? 'COMPLETE' : 'INCOMPLETE',
        'invalid_reasons': invalid.toList()..sort(),
        ...summary.toJson(
          totalSeconds: widget.config.total.inSeconds,
          warmupSeconds: widget.config.warmup.inSeconds,
        ),
        'raw_frame_streak_gate_passes': summary.passes,
        'frame_streak_gate_passes': valid && summary.passes,
        'composite_gate': valid && summary.passes && rssGate,
        'gate_scope': 'observed frame timings and in-host RSS only',
        'gc_telemetry_status': _gc.status,
        'gc_event_count': _gc.events.length,
        'rss_start_bytes': rss.isEmpty ? null : rss.first,
        'rss_peak_bytes': rss.isEmpty
            ? null
            : rss.reduce((a, b) => a > b ? a : b),
        'rss_end_bytes': rss.isEmpty ? null : rss.last,
        'rss_gate_passes': rssGate,
        'logical_width': _width,
        'logical_height': _height,
        'device_pixel_ratio': _window.sampleDpr,
        'final_device_pixel_ratio': _dpr,
        'limitation':
            'Observed production load only; audio/presentation settings require separate evidence. Does not certify unconfigured density targets, released-pool memory, human feel or physical Windows.',
      };
      final directory = Directory(widget.config.outputDirectory);
      await directory.create(recursive: true);
      for (final entry in <String, Iterable<Object?>>{
        'frames.jsonl': _frames.samples.map((e) => e.toJson()),
        'workload.jsonl': _workloads,
        'memory_gc.jsonl': [
          ..._memory,
          ..._gc.events,
          {
            'record_type': 'gc_status',
            'status': _gc.status,
            'error': _gc.error,
          },
        ],
      }.entries) {
        await File(
          '${directory.path}/${entry.key}',
        ).writeAsString('${entry.value.map(jsonEncode).join('\n')}\n');
      }
      await File('${directory.path}/summary.json').writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(payload)}\n',
      );
      debugPrint(
        'PRODUCTION_BATTLE_PROFILE_RESULT: ${directory.path} (${payload['sampling_status']})',
      );
      if (reason == 'timer_completed' && widget.config.autoClose && mounted) {
        await windowManager.close();
      }
    } on Object catch (error) {
      debugPrint('PRODUCTION_BATTLE_PROFILE_WRITE_FAILED: $error');
    }
  }

  @override
  void dispose() {
    _queueFinish('host_disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    _width = media?.size.width;
    _height = media?.size.height;
    _dpr = media?.devicePixelRatio;
    _window.viewport(_elapsed.elapsed, _width, _height, _dpr);
    return widget.child;
  }
}
