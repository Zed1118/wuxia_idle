import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

enum Phase0bRuntimeBeat {
  approach('01 拉扯与包围'),
  gather('02 Q 聚怪'),
  clear('03 R 清场'),
  breakTelegraph('04A 精英蓄力'),
  breakSuccess('04B 破招命中'),
  settle('05 击退与留白');

  const Phase0bRuntimeBeat(this.label);

  final String label;
}

final class Phase0bRuntimeApp extends StatefulWidget {
  const Phase0bRuntimeApp({super.key});

  @override
  State<Phase0bRuntimeApp> createState() => _Phase0bRuntimeAppState();
}

final class _Phase0bRuntimeAppState extends State<Phase0bRuntimeApp> {
  late final Phase0bRuntimeGame game = Phase0bRuntimeGame();

  @override
  void dispose() {
    game.beat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xFF171815),
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget<Phase0bRuntimeGame>(game: game)),
          Positioned(
            left: 20,
            top: 16,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xD9181916),
                  border: Border.all(color: const Color(0x887B7568)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: ValueListenableBuilder<Phase0bRuntimeBeat>(
                    valueListenable: game.beat,
                    builder: (context, beat, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          beat.label,
                          key: const ValueKey('phase0b-runtime-beat'),
                          style: const TextStyle(
                            color: Color(0xFFF0E7D2),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'POSE ATLAS PROTOTYPE · 1 主角 + 6 杂兵 + 1 精英',
                          style: TextStyle(
                            color: Color(0xFFBDB6A8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: IgnorePointer(
              child: Text(
                '引擎内真实透明图集播放；用于验证尺寸、层级与怪群可读性。'
                ' 它不是骨骼动画，不代表最终品质。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFE6DCC6),
                  fontSize: 13,
                  shadows: [Shadow(color: Colors.black, blurRadius: 5)],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

final class Phase0bRuntimeGame extends FlameGame {
  static const atlasColumns = 3;
  static const atlasRows = 2;
  static const loopSeconds = 8.0;

  final ValueNotifier<Phase0bRuntimeBeat> beat = ValueNotifier(
    Phase0bRuntimeBeat.approach,
  );

  ui.Image? _background;
  ui.Image? _founder;
  ui.Image? _bandit;
  ui.Image? _elite;
  double _elapsed = 0;

  bool get assetsReady =>
      _background != null &&
      _founder != null &&
      _bandit != null &&
      _elite != null;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    images.prefix = 'assets/';
    _background = await images.load(
      'phase0b/runtime/mountain_pass_background_v1.webp',
    );
    _founder = await images.load('phase0b/runtime/founder_pose_atlas_v1.png');
    _bandit = await images.load('phase0b/runtime/bandit_pose_atlas_v1.png');
    _elite = await images.load('phase0b/runtime/elite_pose_atlas_v1.png');
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed = (_elapsed + dt) % loopSeconds;
    final next = switch (_elapsed) {
      < 1.8 => Phase0bRuntimeBeat.approach,
      < 3.2 => Phase0bRuntimeBeat.gather,
      < 4.5 => Phase0bRuntimeBeat.clear,
      < 5.65 => Phase0bRuntimeBeat.breakTelegraph,
      < 6.6 => Phase0bRuntimeBeat.breakSuccess,
      _ => Phase0bRuntimeBeat.settle,
    };
    if (beat.value != next) beat.value = next;
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

    canvas.drawImageRect(
      background,
      Rect.fromLTWH(
        0,
        0,
        background.width.toDouble(),
        background.height.toDouble(),
      ),
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0x28120F0B),
    );

    final scaleX = size.x / 1280;
    final scaleY = size.y / 720;
    final center = Offset(640 * scaleX, 430 * scaleY);
    final phase = _elapsed;
    final gatherT = _segment(phase, 1.8, 3.2);
    final clearT = _segment(phase, 3.2, 4.5);
    final breakT = _segment(phase, 4.5, 6.6);
    final settleT = _segment(phase, 6.6, loopSeconds);

    _drawGroundEffects(canvas, center, gatherT, clearT, scaleX, scaleY);

    const starts = <Offset>[
      Offset(320, 335),
      Offset(405, 470),
      Offset(515, 555),
      Offset(785, 555),
      Offset(900, 465),
      Offset(980, 335),
    ];
    const gathered = <Offset>[
      Offset(515, 350),
      Offset(535, 465),
      Offset(575, 535),
      Offset(740, 535),
      Offset(780, 455),
      Offset(795, 350),
    ];

    for (var index = 0; index < starts.length; index++) {
      final start = Offset(
        starts[index].dx * scaleX,
        starts[index].dy * scaleY,
      );
      final group = Offset(
        gathered[index].dx * scaleX,
        gathered[index].dy * scaleY,
      );
      final outward = Offset(
        (index < 3 ? -1 : 1) * (190 + index % 3 * 34) * scaleX,
        (index.isEven ? -35 : 22) * scaleY,
      );
      Offset position;
      var pose = index.isEven ? 1 : 0;
      if (phase < 1.8) {
        final approachT = Curves.easeInOut.transform(phase / 1.8);
        position = Offset.lerp(start, group, approachT * 0.42)!;
        pose = index.isEven ? 1 : 2;
      } else if (phase < 3.2) {
        position = Offset.lerp(start, group, Curves.easeIn.transform(gatherT))!;
        pose = 4;
      } else if (phase < 4.5) {
        position = group + outward * Curves.easeOutCubic.transform(clearT);
        pose = 5;
      } else {
        final cleared = group + outward;
        if (phase < 6.6) {
          position = cleared;
          pose = 5;
        } else {
          position = Offset.lerp(cleared, start, settleT)!;
          pose = settleT < 0.5 ? 5 : 0;
        }
      }
      _drawAtlasPose(
        canvas,
        bandit,
        pose,
        position,
        210 * math.min(scaleX, scaleY),
        mirror: index < 3,
        opacity: phase >= 4.5 && phase < 6.6
            ? 0.32
            : phase >= 6.6
            ? math.min(1, 0.32 + settleT)
            : 1,
        rowDividerRatio: 500 / 941,
      );
    }

    final eliteStart = Offset(1080 * scaleX, 485 * scaleY);
    final eliteThreat = Offset(930 * scaleX, 475 * scaleY);
    final eliteBase = phase < 4.5
        ? Offset.lerp(eliteStart, eliteThreat, clearT * 0.18)!
        : phase < 6.6
        ? Offset.lerp(
            eliteStart,
            eliteThreat,
            Curves.easeOut.transform(breakT),
          )!
        : Offset.lerp(eliteThreat, eliteStart, settleT)!;
    final elitePose = switch (phase) {
      < 4.5 => 0,
      < 5.65 => 1,
      < 6.6 => 2,
      _ => 0,
    };
    if (phase >= 4.5 && phase < 5.65) {
      _drawEliteTelegraph(canvas, eliteBase, breakT, scaleX, scaleY);
    }
    _drawAtlasPose(
      canvas,
      elite,
      elitePose,
      eliteBase,
      310 * math.min(scaleX, scaleY),
      mirror: true,
      columns: 2,
      rows: 2,
    );

    final heroPose = switch (phase) {
      < 1.2 => 0,
      < 1.8 => 1,
      < 3.2 => 3,
      < 4.5 => 4,
      < 5.65 => 0,
      < 6.6 => 5,
      _ => 0,
    };
    _drawAtlasPose(
      canvas,
      founder,
      heroPose,
      center,
      290 * math.min(scaleX, scaleY),
    );
  }

  static double _segment(double value, double start, double end) =>
      ((value - start) / (end - start)).clamp(0, 1);

  static Rect atlasCellRect(
    ui.Image atlas,
    int pose, {
    double rowDividerRatio = 0.5,
    int columns = atlasColumns,
    int rows = atlasRows,
  }) {
    return atlasCellRectForSize(
      Size(atlas.width.toDouble(), atlas.height.toDouble()),
      pose,
      rowDividerRatio: rowDividerRatio,
      columns: columns,
      rows: rows,
    );
  }

  static Rect atlasCellRectForSize(
    Size atlasSize,
    int pose, {
    double rowDividerRatio = 0.5,
    int columns = atlasColumns,
    int rows = atlasRows,
  }) {
    if (columns <= 0 || rows != 2) {
      throw ArgumentError('atlas grid must use positive columns and two rows');
    }
    if (pose < 0 || pose >= columns * rows) {
      throw RangeError.range(pose, 0, columns * rows - 1, 'pose');
    }
    if (rowDividerRatio <= 0 || rowDividerRatio >= 1) {
      throw RangeError.range(rowDividerRatio, 0, 1, 'rowDividerRatio');
    }
    final column = pose % columns;
    final row = pose ~/ columns;
    final left = atlasSize.width * column / columns;
    final divider = atlasSize.height * rowDividerRatio;
    final top = row == 0 ? 0.0 : divider;
    final bottom = row == 0 ? divider : atlasSize.height;
    return Rect.fromLTRB(
      left,
      top,
      atlasSize.width * (column + 1) / columns,
      bottom,
    );
  }

  static void _drawAtlasPose(
    Canvas canvas,
    ui.Image atlas,
    int pose,
    Offset base,
    double height, {
    bool mirror = false,
    double opacity = 1,
    double rowDividerRatio = 0.5,
    int columns = atlasColumns,
    int rows = atlasRows,
  }) {
    final source = atlasCellRect(
      atlas,
      pose,
      rowDividerRatio: rowDividerRatio,
      columns: columns,
      rows: rows,
    );
    final width = height * source.width / source.height;
    final destination = Rect.fromLTWH(-width / 2, -height, width, height);
    canvas.save();
    canvas.translate(base.dx, base.dy);
    if (mirror) canvas.scale(-1, 1);
    canvas.drawImageRect(
      atlas,
      source,
      destination,
      Paint()
        ..filterQuality = FilterQuality.high
        ..color = Color.fromRGBO(255, 255, 255, opacity),
    );
    canvas.restore();
  }

  static void _drawGroundEffects(
    Canvas canvas,
    Offset center,
    double gatherT,
    double clearT,
    double scaleX,
    double scaleY,
  ) {
    if (gatherT > 0 && gatherT < 1) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * math.min(scaleX, scaleY)
        ..color = Color.fromRGBO(38, 35, 30, 0.68 * (1 - gatherT * 0.45));
      for (var i = 0; i < 3; i++) {
        final radius = (250 - gatherT * 145 + i * 20) * scaleX;
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: radius * 2,
            height: radius * 0.7 * scaleY / scaleX,
          ),
          paint,
        );
      }
    }
    if (clearT > 0 && clearT < 1) {
      final eased = Curves.easeOutCubic.transform(clearT);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (16 - eased * 11) * math.min(scaleX, scaleY)
        ..color = Color.fromRGBO(30, 27, 24, 0.78 * (1 - clearT));
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: 680 * scaleX * eased,
          height: 250 * scaleY * eased,
        ),
        paint,
      );
    }
  }

  static void _drawEliteTelegraph(
    Canvas canvas,
    Offset eliteBase,
    double progress,
    double scaleX,
    double scaleY,
  ) {
    final pulse = 0.55 + math.sin(progress * math.pi * 5).abs() * 0.22;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * math.min(scaleX, scaleY)
      ..strokeCap = StrokeCap.round
      ..color = Color.fromRGBO(145, 45, 34, pulse);
    final path = Path()
      ..moveTo(eliteBase.dx - 20 * scaleX, eliteBase.dy - 132 * scaleY)
      ..quadraticBezierTo(
        eliteBase.dx - 120 * scaleX,
        eliteBase.dy - 205 * scaleY,
        eliteBase.dx - 205 * scaleX,
        eliteBase.dy - 76 * scaleY,
      );
    canvas.drawPath(path, paint);
  }
}
