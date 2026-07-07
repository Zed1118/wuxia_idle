import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 水墨笔触弹道线：攻击者→目标的短动画线段(P0-2)。普攻细/大招粗+流派色。
/// 由 battle_screen 在 actionLog 边沿命令式 spawn，纯表现层（不写 BattleState）。
class ProjectileTrail extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final double strokeWidth;
  final Offset start;
  final Offset end;

  const ProjectileTrail({
    super.key,
    required this.animation,
    required this.color,
    required this.strokeWidth,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, _) => CustomPaint(
          painter: _TrailPainter(
            t: animation.value,
            color: color,
            strokeWidth: strokeWidth,
            start: start,
            end: end,
          ),
        ),
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  final double t;
  final Color color;
  final double strokeWidth;
  final Offset start;
  final Offset end;
  _TrailPainter({
    required this.t,
    required this.color,
    required this.strokeWidth,
    required this.start,
    required this.end,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final vector = end - start;
    final distance = vector.distance;
    if (distance < 1) return;

    final unit = vector / distance;
    final normal = Offset(-unit.dy, unit.dx);
    final direction = start.dx <= end.dx ? 1.0 : -1.0;
    final bend = (18 + strokeWidth * 3.6).clamp(18.0, 42.0);
    final control = Offset.lerp(start, end, 0.52)! + normal * bend * direction;
    final progress = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final tailProgress = (progress - 0.38).clamp(0.0, 1.0);
    final fade = math.pow(1.0 - t, 0.7).toDouble();
    final segment = _segmentPath(tailProgress, progress, control);

    final wash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * 3.4
      ..color = color.withValues(alpha: 0.14 * fade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawPath(segment, wash);

    final inkShadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * 1.75
      ..color = Colors.black.withValues(alpha: 0.28 * fade);
    canvas.drawPath(segment, inkShadow);

    final mainStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * (1.08 + 0.16 * math.sin(t * math.pi))
      ..color = color.withValues(alpha: 0.92 * fade);
    canvas.drawPath(segment, mainStroke);

    final dryBrush = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(1.0, strokeWidth * 0.34)
      ..color = Colors.white.withValues(alpha: 0.32 * fade);
    canvas.drawPath(
      _segmentPath(
        (tailProgress + 0.08).clamp(0.0, 1.0),
        (progress - 0.05).clamp(0.0, 1.0),
        control,
        offset: normal * strokeWidth * 0.34,
      ),
      dryBrush,
    );

    final head = _pointAt(progress, control);
    final tail = _pointAt(tailProgress, control);
    _drawInkDot(canvas, head, strokeWidth * 1.15, 0.55 * fade);
    _drawInkDot(
      canvas,
      head - normal * strokeWidth * 1.7,
      strokeWidth * 0.45,
      0.26 * fade,
    );
    _drawInkDot(
      canvas,
      tail + normal * strokeWidth * 1.2,
      strokeWidth * 0.34,
      0.20 * fade,
    );
  }

  Path _segmentPath(
    double from,
    double to,
    Offset control, {
    Offset offset = Offset.zero,
  }) {
    final startT = from.clamp(0.0, 1.0);
    final endT = to.clamp(startT, 1.0);
    final path = Path()..moveToPoint(_pointAt(startT, control) + offset);
    const steps = 8;
    for (var i = 1; i <= steps; i++) {
      final u = startT + (endT - startT) * i / steps;
      path.lineToPoint(_pointAt(u, control) + offset);
    }
    return path;
  }

  Offset _pointAt(double u, Offset control) {
    final a = Offset.lerp(start, control, u)!;
    final b = Offset.lerp(control, end, u)!;
    return Offset.lerp(a, b, u)!;
  }

  void _drawInkDot(Canvas canvas, Offset center, double radius, double alpha) {
    if (radius <= 0 || alpha <= 0) return;
    final paint = Paint()
      ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.t != t ||
      old.start != start ||
      old.end != end ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}

extension on Path {
  void moveToPoint(Offset p) => moveTo(p.dx, p.dy);
  void lineToPoint(Offset p) => lineTo(p.dx, p.dy);
}
