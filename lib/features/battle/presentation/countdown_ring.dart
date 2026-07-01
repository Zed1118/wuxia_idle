import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/theme/colors.dart';

/// 读秒圆环(纯绘制)：底 track 整圆 + 剩余比例扫弧(12 点起顺时针消退) + 中心数字。
///
/// 纯展示，不含动画逻辑——喂什么比例画什么。`remaining` 可为小数(供节拍插值)。
/// `remaining<=0` 时只留空 track、不显数字。中心数字 = `remaining.ceil()`。
class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.remaining,
    required this.total,
    required this.color,
    this.size = 40,
    this.strokeWidth = 3.5,
    this.trackColor = WuxiaColors.barTrack,
  });

  final double remaining; // 可小数
  final int total;
  final Color color;
  final double size;
  final double strokeWidth;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final frac = total <= 0 ? 0.0 : (remaining / total).clamp(0.0, 1.0);
    final n = remaining.ceil();
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CountdownRingPainter(
            frac: frac,
            color: color,
            trackColor: trackColor,
            stroke: strokeWidth,
          ),
          child: Center(
            child: n > 0
                ? Text(
                    '$n',
                    style: TextStyle(
                      fontSize: size * 0.42,
                      height: 1.0,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

/// 接共享节拍 [beat](本拍内 0→1)平滑插值：显示剩余 = `remaining - beat.value`，
/// 每拍 state 里 `remaining` 减 1 时环无缝续扫。CD/敌蓄力/破绽用(均每全局拍减 1)。
class BeatCountdownRing extends StatelessWidget {
  const BeatCountdownRing({
    super.key,
    required this.remaining,
    required this.total,
    required this.beat,
    required this.color,
    this.size = 40,
    this.strokeWidth = 3.5,
  });

  final int remaining;
  final int total;
  final Animation<double> beat;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: beat,
      builder: (_, __) {
        final disp = (remaining - beat.value).clamp(0.0, total.toDouble());
        return CountdownRing(
          remaining: disp,
          total: total,
          color: color,
          size: size,
          strokeWidth: strokeWidth,
        );
      },
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  _CountdownRingPainter({
    required this.frac,
    required this.color,
    required this.trackColor,
    required this.stroke,
  });

  final double frac;
  final Color color;
  final Color trackColor;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = (Offset.zero & size).center;
    final radius = (size.shortestSide - stroke) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor.withValues(alpha: 0.55);
    canvas.drawCircle(center, radius, track);
    if (frac <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = color;
    // 12 点(-90°)起顺时针，扫 frac 圈(剩余比例)。
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * frac,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_CountdownRingPainter old) =>
      old.frac != frac || old.color != color;
}
