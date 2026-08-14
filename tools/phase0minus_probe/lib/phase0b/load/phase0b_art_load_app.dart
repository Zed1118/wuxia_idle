import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phase0minus_probe/metrics/frame_collector.dart';
import 'package:phase0minus_probe/metrics/frame_statistics.dart';
import 'package:phase0minus_probe/phase0b/phase0b_runtime_app.dart';
import 'package:window_manager/window_manager.dart';

final class Phase0bArtLoadApp extends StatefulWidget {
  const Phase0bArtLoadApp({
    required this.runId,
    required this.outputRoot,
    required this.durationScale,
    required this.autoClose,
    required this.viewportId,
    required this.expectedWidth,
    required this.expectedHeight,
    required this.buildCommit,
    required this.assetSha256,
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
  final Map<String, String> assetSha256;
  final bool enableRun;

  @override
  State<Phase0bArtLoadApp> createState() => _Phase0bArtLoadAppState();
}

final class _Phase0bArtLoadAppState extends State<Phase0bArtLoadApp> {
  late final Phase0bArtLoadGame game = Phase0bArtLoadGame();
  late final FrameCollector collector = FrameCollector(
    phase: () => _phase,
    clearEventId: () => game.beatIndex,
  );
  RunPhase _phase = RunPhase.warmup;
  Timer? _memoryTimer;
  final List<int> _rss = [];
  var _rssWarmupEnd = 0;

  @override
  void initState() {
    super.initState();
    if (widget.enableRun) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
    }
  }

  Future<void> _run() async {
    collector.attach();
    _memoryTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _rss.add(ProcessInfo.currentRss),
    );
    await Future<void>.delayed(_scaled(const Duration(seconds: 12)));
    if (!mounted) return;
    _rssWarmupEnd = ProcessInfo.currentRss;
    _phase = RunPhase.sample;
    await Future<void>.delayed(_scaled(const Duration(seconds: 60)));
    if (!mounted) return;
    _phase = RunPhase.cooldown;
    await Future<void>.delayed(_scaled(const Duration(seconds: 30)));
    if (!mounted) return;
    _phase = RunPhase.complete;
    collector.detach();
    _memoryTimer?.cancel();
    await _writeObservation();
    if (widget.autoClose) await windowManager.close();
  }

  Duration _scaled(Duration duration) => Duration(
    milliseconds: math
        .max(1, duration.inMilliseconds * widget.durationScale)
        .round(),
  );

  Future<void> _writeObservation() async {
    final samples = collector.samples;
    final total = samples.map((sample) => sample.totalSpanUs).toList();
    final build = samples.map((sample) => sample.buildDurationUs).toList();
    final raster = samples.map((sample) => sample.rasterDurationUs).toList();
    final output = Directory(
      '${widget.outputRoot}/phase0b-art-load/${widget.runId}',
    );
    await output.create(recursive: true);
    if (!mounted) return;
    final view = View.of(context);
    final logicalSize = view.physicalSize / view.devicePixelRatio;
    final viewportMatches =
        (logicalSize.width - widget.expectedWidth).abs() < 1 &&
        (logicalSize.height - widget.expectedHeight).abs() < 1;
    final validity = !kProfileMode
        ? 'INVALID_BUILD_MODE'
        : !viewportMatches
        ? 'INVALID_VIEWPORT'
        : samples.length < 300
        ? 'INVALID_INSUFFICIENT_FRAMES'
        : 'VALID_OBSERVATION';
    final summary = <String, Object?>{
      'schema_version': 1,
      'probe_kind': 'phase0b_art_load',
      'gate_eligible': false,
      'claim': 'art_load_observation_only_not_phase0minus_or_gameplay_gate',
      'build_mode': kProfileMode
          ? 'profile'
          : kDebugMode
          ? 'debug'
          : 'release',
      'validity': validity,
      'run_id': widget.runId,
      'build_commit': widget.buildCommit,
      'asset_sha256': widget.assetSha256,
      'duration_scale': widget.durationScale,
      'viewport': {
        'id': widget.viewportId,
        'expected_width': widget.expectedWidth,
        'expected_height': widget.expectedHeight,
        'actual_width': logicalSize.width,
        'actual_height': logicalSize.height,
        'device_pixel_ratio': view.devicePixelRatio,
        'refresh_rate_hz': view.display.refreshRate,
      },
      'frames': samples.length,
      'entity_counts': {'hero': 1, 'ordinary': 20, 'elite': 1},
      'logical_image_rect_ops': 23,
      'decoded_texture_bytes_theoretical': game.decodedTextureBytesTheoretical,
      'reference_budget_us': 16600,
      if (samples.isNotEmpty) ...{
        'total_span': DurationSummary.from(total).toJson(),
        'build_duration': DurationSummary.from(build).toJson(),
        'raster_duration': DurationSummary.from(raster).toJson(),
        'over_reference_budget_count': total.where((v) => v >= 16600).length,
        'maximum_severe_streak': maximumConsecutiveAbove(total, 33300),
      },
      'rss_warmup_end_bytes': _rssWarmupEnd,
      'rss_peak_bytes': _rss.isEmpty ? 0 : _rss.reduce(math.max),
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
    _memoryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF171815),
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget<Phase0bArtLoadGame>(game: game)),
          const Positioned(
            left: 18,
            top: 14,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xD9181916)),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'ART LOAD REPLAY · 20+1 · CAMERA V2\n'
                    'NOT GAMEPLAY GATE / NOT BONE RIG',
                    style: TextStyle(color: Color(0xFFECE2CD), fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

enum _ActorKind { bandit, hero, elite }

final class _ActorFrame {
  const _ActorFrame({
    required this.id,
    required this.kind,
    required this.position,
    required this.pose,
    required this.opacity,
    this.mirror = false,
  });

  final int id;
  final _ActorKind kind;
  final Offset position;
  final int pose;
  final double opacity;
  final bool mirror;
}

final class Phase0bArtLoadGame extends FlameGame {
  static const loopSeconds = 8.0;

  ui.Image? _background;
  ui.Image? _founder;
  ui.Image? _bandit;
  ui.Image? _elite;
  double _elapsed = 0;

  int get beatIndex => switch (_elapsed) {
    < 1.8 => 0,
    < 3.2 => 1,
    < 4.5 => 2,
    < 6.6 => 3,
    _ => 4,
  };

  int get decodedTextureBytesTheoretical =>
      [_background, _founder, _bandit, _elite].whereType<ui.Image>().fold(
        0,
        (total, image) => total + image.width * image.height * 4,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    images.prefix = 'assets/';
    _background = await images.load(
      'phase0b/runtime/mountain_pass_background_v2.png',
    );
    _founder = await images.load('phase0b/runtime/founder_pose_atlas_v1.png');
    _bandit = await images.load('phase0b/runtime/bandit_pose_atlas_v1.png');
    _elite = await images.load('phase0b/runtime/elite_pose_atlas_v1.png');
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed = (_elapsed + dt) % loopSeconds;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final background = _background;
    final founder = _founder;
    final bandit = _bandit;
    final elite = _elite;
    if (background == null ||
        founder == null ||
        bandit == null ||
        elite == null) {
      return;
    }
    final scale = math.min(size.x / 1280, size.y / 720);
    final content = Rect.fromLTWH(
      (size.x - 1280 * scale) / 2,
      (size.y - 720 * scale) / 2,
      1280 * scale,
      720 * scale,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Colors.black,
    );
    canvas.drawImageRect(
      background,
      Rect.fromLTWH(
        0,
        0,
        background.width.toDouble(),
        background.height.toDouble(),
      ),
      content,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.save();
    canvas.translate(content.left, content.top);
    canvas.scale(scale);
    final frames = _actorFrames(_elapsed)
      ..sort((a, b) {
        final depth = a.position.dy.compareTo(b.position.dy);
        return depth != 0 ? depth : a.id.compareTo(b.id);
      });
    for (final frame in frames) {
      final atlas = switch (frame.kind) {
        _ActorKind.bandit => bandit,
        _ActorKind.hero => founder,
        _ActorKind.elite => elite,
      };
      final columns = frame.kind == _ActorKind.elite ? 2 : 3;
      final rows = 2;
      final source = Phase0bRuntimeGame.atlasCellRect(
        atlas,
        frame.pose,
        rowDividerRatio: frame.kind == _ActorKind.bandit ? 500 / 941 : 0.5,
        columns: columns,
        rows: rows,
      );
      final perspective = _perspectiveScale(frame.position.dy);
      final height = switch (frame.kind) {
        _ActorKind.hero => 168.0 * perspective,
        _ActorKind.elite => 184.0 * perspective,
        _ActorKind.bandit => 132.0 * perspective,
      };
      final width = height * source.width / source.height;
      canvas.save();
      canvas.translate(frame.position.dx, frame.position.dy);
      if (frame.mirror) canvas.scale(-1, 1);
      canvas.drawImageRect(
        atlas,
        source,
        Rect.fromLTWH(-width / 2, -height, width, height),
        Paint()
          ..filterQuality = FilterQuality.high
          ..color = Color.fromRGBO(255, 255, 255, frame.opacity),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @visibleForTesting
  static int actorCountAt(double phase) => _actorFrames(phase).length;

  @visibleForTesting
  static List<Offset> ordinaryPositionsAt(double phase) => _actorFrames(phase)
      .where((frame) => frame.kind == _ActorKind.bandit)
      .map((frame) => frame.position)
      .toList(growable: false);

  static double _perspectiveScale(double footY) =>
      ui.lerpDouble(0.78, 1.06, ((footY - 350) / 250).clamp(0, 1))!;

  static List<_ActorFrame> _actorFrames(double phase) {
    final frames = <_ActorFrame>[];
    for (var index = 0; index < 20; index++) {
      final side = index < 10 ? -1.0 : 1.0;
      final local = index % 10;
      final lane = local ~/ 2;
      final rank = local % 2;
      final start = Offset(
        640 + side * (235 + rank * 112 + lane * 14),
        370 + lane * 52 + rank * 8,
      );
      final angle = index * math.pi * 2 / 20 + (index.isEven ? 0.06 : -0.04);
      final ringRadiusX = index < 8 ? 190.0 : 278.0;
      final ringRadiusY = index < 8 ? 64.0 : 108.0;
      var groupDx = math.cos(angle) * ringRadiusX;
      if (groupDx.abs() < 105) {
        groupDx = (index.isEven ? -1 : 1) * 105;
      }
      final group = Offset(640 + groupDx, 505 + math.sin(angle) * ringRadiusY);
      final scatter = 0.82 + (index % 4) * 0.08;
      final outward = Offset(
        math.cos(angle) * 205 * scatter,
        math.sin(angle) * 62 * scatter + ((index % 3) - 1) * 12,
      );
      final cohortDelay = (index % 5) * 0.18;
      final gatherT = _segment(phase - cohortDelay, 1.8, 3.2);
      final settleT = _segment(phase - cohortDelay, 6.6, loopSeconds);
      late Offset position;
      late int pose;
      var opacity = 1.0;
      if (phase < 1.8 + cohortDelay) {
        position = Offset.lerp(start, group, 0.28 * _segment(phase, 0, 1.8))!;
        pose = index.isEven ? 1 : 2;
      } else if (phase < 3.2 + cohortDelay) {
        position = Offset.lerp(start, group, Curves.easeIn.transform(gatherT))!;
        pose = 4;
      } else if (phase < 3.62 + cohortDelay) {
        final cascadeT = _segment(phase - cohortDelay, 3.2, 3.62);
        position = group + outward * Curves.easeOutCubic.transform(cascadeT);
        pose = 5;
      } else if (phase < 6.6 + cohortDelay) {
        position = group + outward;
        pose = index.isEven ? 3 : 0;
        opacity = 0.48;
      } else {
        position = Offset.lerp(group + outward, start, settleT)!;
        pose = settleT < 0.35 ? 3 : 0;
        opacity = math.min(1, 0.48 + settleT);
      }
      final heroDx = position.dx - 640;
      final heroDy = position.dy - 510;
      if (heroDx.abs() < 105 && heroDy.abs() < 76) {
        position = Offset(
          640 + (heroDx < 0 || (heroDx == 0 && index.isEven) ? -105 : 105),
          position.dy,
        );
      }
      frames.add(
        _ActorFrame(
          id: index,
          kind: _ActorKind.bandit,
          position: position,
          pose: pose,
          opacity: opacity,
          mirror: side < 0,
        ),
      );
    }
    frames.add(
      const _ActorFrame(
        id: 100,
        kind: _ActorKind.hero,
        position: Offset(640, 510),
        pose: 4,
        opacity: 1,
      ),
    );
    frames.add(
      _ActorFrame(
        id: 101,
        kind: _ActorKind.elite,
        position: const Offset(1010, 510),
        pose: phase >= 4.5 && phase < 5.65
            ? 1
            : phase < 6.6 && phase >= 5.65
            ? 2
            : 0,
        opacity: 1,
        mirror: true,
      ),
    );
    return frames;
  }

  static double _segment(double value, double start, double end) =>
      ((value - start) / (end - start)).clamp(0, 1).toDouble();
}
