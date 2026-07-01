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
      builder: (_, _) {
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

/// 内伤专用：state 无初始 total，用「激活期见过的最大剩余」作分母(max-seen)，
/// 状态清零(remaining<=0)复位。`remaining` 变化时 ~250ms 短过渡扫一段(跳变，
/// 不假装匀速——内伤按守方自己出手减 1，节奏不规则)。
class SteppedCountdownRing extends StatefulWidget {
  const SteppedCountdownRing({
    super.key,
    required this.remaining,
    required this.color,
    this.size = 40,
    this.strokeWidth = 3.5,
  });

  final int remaining;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  State<SteppedCountdownRing> createState() => _SteppedCountdownRingState();
}

class _SteppedCountdownRingState extends State<SteppedCountdownRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _maxSeen = 0;
  double _from = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    if (widget.remaining > 0) _maxSeen = widget.remaining;
    _from = widget.remaining.toDouble();
    _ctrl.value = 1; // 静止态 disp == remaining
  }

  @override
  void didUpdateWidget(SteppedCountdownRing old) {
    super.didUpdateWidget(old);
    if (old.remaining != widget.remaining) {
      if (widget.remaining <= 0) {
        _maxSeen = 0; // 清零复位分母
      } else if (widget.remaining > _maxSeen) {
        _maxSeen = widget.remaining; // 同源刷新 → 抬高分母
      }
      _from = old.remaining.toDouble();
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.remaining <= 0) return const SizedBox.shrink();
    final total = _maxSeen <= 0 ? 1 : _maxSeen;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final disp = _from + (widget.remaining - _from) * _ctrl.value;
        return CountdownRing(
          remaining: disp,
          total: total,
          color: widget.color,
          size: widget.size,
          strokeWidth: widget.strokeWidth,
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
