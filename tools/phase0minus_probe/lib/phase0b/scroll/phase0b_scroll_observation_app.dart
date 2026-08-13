import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phase0minus_probe/metrics/frame_collector.dart';
import 'package:phase0minus_probe/metrics/frame_statistics.dart';
import 'package:phase0minus_probe/phase0b/scroll/phase0b_scroll_review_app.dart';
import 'package:window_manager/window_manager.dart';

final class Phase0bScrollObservationApp extends StatefulWidget {
  const Phase0bScrollObservationApp({
    required this.runId,
    required this.outputRoot,
    required this.durationScale,
    required this.autoClose,
    required this.viewportId,
    required this.expectedWidth,
    required this.expectedHeight,
    required this.buildCommit,
    required this.panoramaSha256,
    this.enableRun = true,
    super.key,
  });

  final String runId;
  final String outputRoot;
  final double durationScale;
  final bool autoClose;
  final String viewportId;
  final double expectedWidth;
  final double expectedHeight;
  final String buildCommit;
  final String panoramaSha256;
  final bool enableRun;

  @override
  State<Phase0bScrollObservationApp> createState() =>
      _Phase0bScrollObservationAppState();
}

final class _Phase0bScrollObservationAppState
    extends State<Phase0bScrollObservationApp> {
  late final Phase0bScrollReviewGame game = Phase0bScrollReviewGame();
  late final FrameCollector collector = FrameCollector(
    phase: () => phase,
    clearEventId: () => game.activeEnemyCount,
  );
  RunPhase phase = RunPhase.warmup;
  Timer? memoryTimer;
  final List<int> rss = [];
  var rssWarmupEnd = 0;
  var minimumHeroX = double.infinity;
  var maximumHeroX = double.negativeInfinity;
  var minimumCameraX = double.infinity;
  var maximumCameraX = double.negativeInfinity;

  @override
  void initState() {
    super.initState();
    if (widget.enableRun) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
    }
  }

  Duration _scaled(Duration value) => Duration(
    milliseconds: math
        .max(1, value.inMilliseconds * widget.durationScale)
        .round(),
  );

  Future<void> _run() async {
    collector.attach();
    memoryTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      rss.add(ProcessInfo.currentRss);
      minimumHeroX = math.min(minimumHeroX, game.heroWorldX);
      maximumHeroX = math.max(maximumHeroX, game.heroWorldX);
      minimumCameraX = math.min(minimumCameraX, game.cameraWorldX);
      maximumCameraX = math.max(maximumCameraX, game.cameraWorldX);
    });
    await Future<void>.delayed(_scaled(const Duration(seconds: 12)));
    rssWarmupEnd = ProcessInfo.currentRss;
    phase = RunPhase.sample;
    await Future<void>.delayed(_scaled(const Duration(seconds: 60)));
    phase = RunPhase.cooldown;
    await Future<void>.delayed(_scaled(const Duration(seconds: 30)));
    phase = RunPhase.complete;
    collector.detach();
    memoryTimer?.cancel();
    await _write();
    if (widget.autoClose) await windowManager.close();
  }

  Future<void> _write() async {
    if (!mounted) return;
    final view = View.of(context);
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    final total = collector.samples
        .map((sample) => sample.totalSpanUs)
        .toList();
    final output = Directory(
      '${widget.outputRoot}/phase0b-scroll/${widget.runId}',
    );
    await output.create(recursive: true);
    final viewportValid =
        (logicalSize.width - widget.expectedWidth).abs() < 1 &&
        (logicalSize.height - widget.expectedHeight).abs() < 1;
    final workloadValid =
        game.observedEncounterPeaks.join(',') == '6,10,21' &&
        game.finalPeakVisibleSeconds >= 0.5 &&
        maximumCameraX - minimumCameraX >= 2000;
    final validity = !kProfileMode
        ? 'INVALID_BUILD_MODE'
        : !viewportValid
        ? 'INVALID_VIEWPORT'
        : collector.samples.length < 300
        ? 'INVALID_INSUFFICIENT_FRAMES'
        : !workloadValid
        ? 'INVALID_WORKLOAD_COVERAGE'
        : 'VALID_OBSERVATION';
    final summary = <String, Object?>{
      'schema_version': 1,
      'probe_kind': 'phase0b_scroll_art_demo',
      'gate_eligible': false,
      'claim': 'continuous_map_camera_and_local_art_load_observation_only',
      'build_mode': kProfileMode
          ? 'profile'
          : kDebugMode
          ? 'debug'
          : 'release',
      'validity': validity,
      'run_id': widget.runId,
      'build_commit': widget.buildCommit,
      'panorama_sha256': widget.panoramaSha256,
      'duration_scale': widget.durationScale,
      'frames': collector.samples.length,
      'viewport': {
        'id': widget.viewportId,
        'expected_width': widget.expectedWidth,
        'expected_height': widget.expectedHeight,
        'actual_width': logicalSize.width,
        'actual_height': logicalSize.height,
        'device_pixel_ratio': view.devicePixelRatio,
        'refresh_rate_hz': view.display.refreshRate,
      },
      'workload': {
        'encounter_peaks': game.observedEncounterPeaks,
        'final_20_plus_1_visible_seconds': game.finalPeakVisibleSeconds,
        'hero_world_travel': maximumHeroX - minimumHeroX,
        'camera_world_travel': maximumCameraX - minimumCameraX,
        'scene_layer_logical_ops_per_frame':
            Phase0bScrollReviewGame.sceneLayerLogicalOpsPerFrame,
        'scene_layers': const [
          'single_panorama',
          'far_mist',
          'ground_mist',
          'actor_depth_sort',
          'foreground_occluder',
        ],
      },
      if (total.isNotEmpty) ...{
        'total_span': DurationSummary.from(total).toJson(),
        'over_reference_budget_count': total
            .where((value) => value >= 16600)
            .length,
        'maximum_severe_streak': maximumConsecutiveAbove(total, 33300),
      },
      'rss_warmup_end_bytes': rssWarmupEnd,
      'rss_peak_bytes': rss.isEmpty ? 0 : rss.reduce(math.max),
      'rss_cooldown_end_bytes': ProcessInfo.currentRss,
    };
    await File('${output.path}/summary.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(summary),
      flush: true,
    );
  }

  @override
  void dispose() {
    collector.detach();
    memoryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GameWidget<Phase0bScrollReviewGame>(game: game),
          ),
          const Positioned(
            left: 18,
            top: 14,
            child: Text(
              'SCROLL PROFILE OBSERVATION · NOT A GAMEPLAY GATE',
              style: TextStyle(
                color: Color(0xFFECE2CD),
                backgroundColor: Color(0xCC181916),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
