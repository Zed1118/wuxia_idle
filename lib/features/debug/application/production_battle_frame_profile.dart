import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import 'battle_frame_profile.dart';
import 'production_profile_keyboard_driver.dart';

// Capture JSON metadata by value. Sorting map keys permits equivalent rebuilds,
// while recursively copying lists/maps prevents later caller mutation from
// rewriting the identity of frames that have already been collected.
Object? _freezeProfileJson(Object? value) {
  if (value is Map<String, Object?>) {
    final keys = value.keys.toList()..sort();
    return Map<String, Object?>.unmodifiable({
      for (final key in keys) key: _freezeProfileJson(value[key]),
    });
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_freezeProfileJson));
  }
  return value;
}

Map<String, Object?> _sceneSnapshot(Map<String, Object?> scene) =>
    _freezeProfileJson(scene)! as Map<String, Object?>;

String _configIdentity(BattleFrameProfileRunConfig config) => jsonEncode({
  'run_id': config.runId,
  'output_directory': config.outputDirectory,
  'sample_us': config.sample.inMicroseconds,
  'warmup_us': config.warmup.inMicroseconds,
  'cooldown_us': config.cooldown.inMicroseconds,
  'auto_close': config.autoClose,
  'viewport_width': config.viewportWidth,
  'viewport_height': config.viewportHeight,
  'native_content_viewport': config.nativeContentViewport,
  'diagnostics': config.diagnostics,
  'scope': config.scope,
  'content_id': config.contentId,
  'legal_character': config.legalCharacter,
  'keyboard_policy': config.keyboardPolicy,
});

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

  void inputFocus(Duration elapsed, {required bool hasPrimaryFocus}) {
    if (isSampling(elapsed) && !hasPrimaryFocus) {
      invalidReasons.add('battle_input_focus_lost');
    }
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
    if (reason != 'sample_complete' || elapsed < config.total)
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
    this.diagnosticsFactory,
    this.keyboardDriverFactory,
  });

  final Widget child;
  final Listenable owner;
  final BattleFrameProfileRunConfig config;
  final Map<String, Object?> scene;
  final Map<String, Object?> Function() readWorkload;
  final bool Function() isCombatOngoing;

  @visibleForTesting
  final BattleFrameProfileDiagnostics Function()? diagnosticsFactory;

  final ProductionProfileKeyboardDriver Function(bool Function() isForeground)?
  keyboardDriverFactory;

  static _ProductionBattleFrameProfileState? _active;
  static final Set<Future<void>> _pendingWrites = {};

  static bool get isCapturing => _active != null;

  /// Reads the production camera's existing Offstage decision. This counts
  /// onstage living actor boundaries, not pixel visibility through other actors
  /// or the HUD. Call only after build, while the child tree is mounted.
  static Map<String, Object?> observeVisibleEnemies(
    BuildContext context,
    Iterable<String> activeEnemyIds,
  ) {
    final clock = Stopwatch()..start();
    final targets = {for (final id in activeEnemyIds) 'phase0a_actor_$id': id};
    final visible = <String>{};
    var visited = 0;
    void visit(Element element) {
      if (visible.length == targets.length) return;
      visited++;
      final widget = element.widget;
      if (widget is Offstage && widget.offstage) return;
      if (widget is RepaintBoundary) {
        final key = widget.key;
        if (key is ValueKey<String>) {
          final id = targets[key.value];
          if (id != null) visible.add(id);
          // Actor descendants cannot contain another actor boundary. Pruning
          // also avoids walking dead/player standees and their image subtrees.
          if (key.value.startsWith('phase0a_actor_')) return;
        }
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    clock.stop();
    return {
      'visible_active_enemies': visible.length,
      'visible_enemy_ids': visible.toList()..sort(),
      'visibility_observer_status': 'observed',
      'visibility_observer_elapsed_us': clock.elapsedMicroseconds,
      'visibility_observer_visited_elements': visited,
    };
  }

  static void recordActivity(
    Object owner, {
    required bool paused,
    required bool foreground,
    required bool combatOngoing,
  }) {
    final active = _active;
    if (active != null && identical(owner, active._owner)) {
      final inputActivityChanged =
          active._paused != paused || active._battleForeground != foreground;
      active._paused = paused;
      active._battleForeground = foreground;
      if (inputActivityChanged) active._keyboardDriver?.refreshForeground();
      active._window.activity(
        active._elapsed.elapsed,
        paused: paused,
        foreground: foreground && active._foreground,
        combatOngoing: combatOngoing,
      );
      active._window.inputFocus(
        active._elapsed.elapsed,
        hasPrimaryFocus: active._battleFocusNode?.hasPrimaryFocus ?? false,
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
  late final BattleFrameProfileRunConfig _config;
  late final String _configKey;
  late final Listenable _owner;
  late final Map<String, Object?> Function() _readWorkload;
  late final bool Function() _isCombatOngoing;
  late final Map<String, Object?> _initialScene;
  late final String _initialSceneKey;
  late final Map<String, Object?> _sceneAtCaptureEnd;
  Timer? _finishTimer;
  Timer? _memoryTimer;
  Timer? _diagnosticsFinishTimer;
  BattleFrameProfileDiagnostics? _diagnostics;
  ProductionProfileKeyboardDriver? _keyboardDriver;
  FocusNode? _battleFocusNode;
  Future<void>? _connection;
  bool _started = false;
  bool _finished = false;
  double? _width;
  double? _height;
  double? _dpr;
  bool _foreground = false;
  bool _battleForeground = true;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _config = widget.config;
    _configKey = _configIdentity(_config);
    _owner = widget.owner;
    _readWorkload = widget.readWorkload;
    _isCombatOngoing = widget.isCombatOngoing;
    _initialScene = _sceneSnapshot(widget.scene);
    _initialSceneKey = jsonEncode(_initialScene);
    _window = ProductionProfileWindow(_config);
    _frames = BattleFrameProfileAccumulator(
      warmup: _config.warmup,
      sampleDuration: _config.sample,
    );
    if (!BattleFrameProfileProbe.claimProductionRun(_config)) return;
    final directory = Directory(_config.outputDirectory);
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
    _keyboardDriver = widget.keyboardDriverFactory?.call(
      () =>
          _foreground &&
          _battleForeground &&
          (_battleFocusNode?.hasPrimaryFocus ?? false) &&
          !_paused &&
          !_finished &&
          _isCombatOngoing(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Focus autofocus applies in a microtask after the battle has mounted.
      scheduleMicrotask(() {
        if (!mounted || _finished) return;
        _bindBattleFocus();
        if (_isCombatOngoing()) _keyboardDriver?.start();
      });
    });
    if (_config.diagnostics) {
      _diagnostics =
          widget.diagnosticsFactory?.call() ?? BattleFrameProfileDiagnostics();
      unawaited(_diagnostics!.start());
      _diagnosticsFinishTimer = Timer(
        _config.warmup + _config.sample,
        () => unawaited(_diagnostics!.finish()),
      );
    }
    WidgetsBinding.instance.addObserver(this);
    _owner.addListener(_combatChanged);
    _combatChanged();
    SchedulerBinding.instance.addTimingsCallback(_recordFrames);
    _connection = _gc.connect();
    _recordWorkload(observeVisibility: false);
    _memoryTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _recordWorkload(),
    );
    _finishTimer = Timer(_config.total, () => _queueFinish('sample_complete'));
  }

  @override
  void didUpdateWidget(ProductionBattleFrameProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_started || _finished) return;
    _checkScene();
    if (!identical(widget.owner, _owner)) {
      _window.invalidReasons.add('battle_owner_changed');
    }
    if (_configIdentity(widget.config) != _configKey) {
      _window.invalidReasons.add('profile_config_changed');
    }
    if (_window.invalidReasons.contains('battle_owner_changed') ||
        _window.invalidReasons.contains('profile_config_changed')) {
      // Never combine a new battle or run config with the old frame buffer.
      // _queueFinish detaches the captured owner, not this replacement widget.
      _queueFinish('profile_identity_changed');
    }
  }

  Map<String, Object?> _checkScene() {
    final scene = _sceneSnapshot(widget.scene);
    if (jsonEncode(scene) != _initialSceneKey) {
      // Latch across warmup, sample and cooldown, including changes restored
      // before capture ends. A mixed presentation run is not a baseline.
      _window.invalidReasons.add('scene_configuration_changed');
    }
    return scene;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _combatChanged();
  }

  void _combatChanged() {
    _keyboardDriver?.refreshForeground();
    _window.activity(
      _elapsed.elapsed,
      paused: _paused,
      foreground: _foreground,
      combatOngoing: _isCombatOngoing(),
    );
  }

  void _bindBattleFocus() {
    void visit(Element element) {
      if (_battleFocusNode != null) return;
      final widget = element.widget;
      if (widget is Offstage && widget.offstage) return;
      if (widget is Focus && widget.focusNode != null) {
        _battleFocusNode = widget.focusNode;
        return;
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    _battleFocusNode?.addListener(_battleInputFocusChanged);
    _battleInputFocusChanged();
  }

  void _battleInputFocusChanged() {
    if (_finished) return;
    _keyboardDriver?.refreshForeground();
    _window.inputFocus(
      _elapsed.elapsed,
      hasPrimaryFocus: _battleFocusNode?.hasPrimaryFocus ?? false,
    );
  }

  void _recordFrames(List<FrameTiming> timings) {
    for (final timing in timings) {
      _frames.add(
        elapsed: _elapsed.elapsed,
        build: timing.buildDuration,
        raster: timing.rasterDuration,
        totalSpan: timing.totalSpan,
        rssBytes: ProcessInfo.currentRss,
        frameTiming: timing,
      );
    }
  }

  void _recordWorkload({bool observeVisibility = true}) {
    final elapsed = _elapsed.elapsed;
    _memory.add({
      'record_type': 'memory_sample',
      'elapsed_ms': elapsed.inMilliseconds,
      'rss_bytes': ProcessInfo.currentRss,
      'gate_eligible': elapsed >= _config.warmup,
    });
    try {
      _checkScene();
      final value = _readWorkload();
      final activeEnemyIds = value['active_enemy_ids'];
      final visible = observeVisibility && activeEnemyIds is List<String>
          ? ProductionBattleFrameProfile.observeVisibleEnemies(
              context,
              activeEnemyIds,
            )
          : <String, Object?>{
              'visible_active_enemies': observeVisibility ? null : 0,
              'visible_enemy_ids': observeVisibility ? null : <String>[],
              'visibility_observer_status': observeVisibility
                  ? 'missing_active_enemy_ids'
                  : 'outside_periodic_observation',
              'visibility_observer_elapsed_us': 0,
              'visibility_observer_visited_elements': 0,
            };
      if (observeVisibility) {
        _window.inputFocus(
          elapsed,
          hasPrimaryFocus: _battleFocusNode?.hasPrimaryFocus ?? false,
        );
      }
      _window.workload(elapsed, value);
      _workloads.add({
        'elapsed_us': elapsed.inMicroseconds,
        'logical_width': _width,
        'logical_height': _height,
        'device_pixel_ratio': _dpr,
        'foreground': _foreground,
        'battle_input_focus_bound': _battleFocusNode != null,
        'battle_input_has_primary_focus': _battleFocusNode?.hasPrimaryFocus,
        ...value,
        ...visible,
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
    _keyboardDriver?.stop();
    _battleFocusNode?.removeListener(_battleInputFocusChanged);
    _sceneAtCaptureEnd = _checkScene();
    _finishTimer?.cancel();
    _memoryTimer?.cancel();
    _diagnosticsFinishTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _owner.removeListener(_combatChanged);
    SchedulerBinding.instance.removeTimingsCallback(_recordFrames);
    _recordWorkload(observeVisibility: false);
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
      await _diagnostics?.finish();
      await _connection;
      await _gc.close();
      final summary = _frames.summary;
      final invalid = _window.reasonsAtEnd(
        elapsed: _elapsed.elapsed,
        reason: reason,
        sampledFrames: summary.sampledFrames,
      );
      if (_width != _config.viewportWidth ||
          _height != _config.viewportHeight ||
          _dpr == null) {
        invalid.add('viewport_mismatch');
      }
      if (_config.diagnostics) invalid.add('diagnostic_run_not_baseline');
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
        'run_id': _config.runId,
        'evidence_kind': 'normal_root_production_host',
        'entry_origin': 'normal_root',
        'diagnostics_enabled': _config.diagnostics,
        'capture_window_valid': valid,
        if (_diagnostics != null) 'diagnostics': _diagnostics!.status,
        if (_keyboardDriver != null)
          'keyboard_driver': _keyboardDriver!.metadata,
        'scene': _initialScene,
        'scene_at_capture_end': _sceneAtCaptureEnd,
        'capture_end_reason': reason,
        'capture_elapsed_us': _elapsed.elapsedMicroseconds,
        'sample_seconds': _config.sample.inSeconds,
        'cooldown_seconds': _config.cooldown.inSeconds,
        'cooldown_observation':
            'host_still_mounted; not proof of released battle pools',
        'sampling_status': valid ? 'COMPLETE' : 'INCOMPLETE',
        'invalid_reasons': invalid.toList()..sort(),
        ...summary.toJson(
          totalSeconds: _config.total.inSeconds,
          warmupSeconds: _config.warmup.inSeconds,
        ),
        'raw_frame_streak_gate_passes': summary.passes,
        'frame_streak_gate_passes': valid && summary.passes,
        'composite_gate': valid && summary.passes && rssGate,
        'gate_scope': 'observed frame timings and in-host RSS only',
        'visible_enemy_observation':
            '1Hz living actor RepaintBoundary scan; skips production Offstage '
            'subtrees. Camera-onstage only, not proof of unobscured pixels. '
            'Observer elapsed time and visited elements are recorded per sample.',
        'input_focus_observation':
            'Exact first explicit FocusNode under the battle wrapper; primary '
            'focus required, including when the application remains resumed.',
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
      final directory = Directory(_config.outputDirectory);
      await directory.create(recursive: true);
      await _diagnostics?.writeEvidence(directory);
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
      if (reason == 'sample_complete' && _config.autoClose && mounted) {
        await windowManager.close();
      }
    } on Object catch (error) {
      debugPrint('PRODUCTION_BATTLE_PROFILE_WRITE_FAILED: $error');
    }
  }

  @override
  void dispose() {
    _queueFinish('host_disposed');
    _keyboardDriver?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_finished) {
      final media = MediaQuery.maybeOf(context);
      _width = media?.size.width;
      _height = media?.size.height;
      _dpr = media?.devicePixelRatio;
      _window.viewport(_elapsed.elapsed, _width, _height, _dpr);
    }
    return widget.child;
  }
}
