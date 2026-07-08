import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'projectile_trail_style.dart';

/// 水墨笔触弹道线：攻击者→目标的短动画线段(P0-2)。
///
/// [color] 只作为极淡流派洗色，主体必须是墨色笔触，避免战斗读成彩色激光线。
/// 由 battle_screen 在 actionLog 边沿命令式 spawn，纯表现层（不写 BattleState）。
class ProjectileTrail extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final double strokeWidth;
  final Offset start;
  final Offset end;
  final ProjectileTrailStyle style;
  final int seed;

  const ProjectileTrail({
    super.key,
    required this.animation,
    required this.color,
    required this.strokeWidth,
    required this.start,
    required this.end,
    this.style = ProjectileTrailStyle.normal,
    this.seed = 0,
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
            style: style,
            seed: seed,
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
  final ProjectileTrailStyle style;
  final int seed;
  _TrailPainter({
    required this.t,
    required this.color,
    required this.strokeWidth,
    required this.start,
    required this.end,
    required this.style,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final vector = end - start;
    final distance = vector.distance;
    if (distance < 1) return;

    final unit = vector / distance;
    final normal = Offset(-unit.dy, unit.dx);
    final routeSide = _signedNoise(1) >= 0 ? 1.0 : -1.0;
    final routeT = (0.44 + _signedNoise(2) * 0.14).clamp(0.30, 0.62);
    final routePull = unit * distance * _signedNoise(3) * 0.055;
    final bendScale = style == ProjectileTrailStyle.skill ? 0.19 : 0.13;
    final bendNoise = 0.82 + _unitNoise(4) * 0.62;
    final bend = (distance * bendScale * bendNoise + strokeWidth * 5.6).clamp(
      38.0,
      132.0,
    );
    final control =
        Offset.lerp(start, end, routeT)! +
        normal * bend * routeSide +
        routePull;
    final progress = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final tailWindow = style == ProjectileTrailStyle.skill ? 0.62 : 0.5;
    final tailProgress = (progress - tailWindow).clamp(0.0, 1.0);
    final fade = math.pow(1.0 - t, 0.7).toDouble();
    final ink = const Color(0xFF11100D);
    final wetInk = const Color(0xFF252018);
    final paperScratch = const Color(0xFFE7D8B4);

    if (style == ProjectileTrailStyle.skill) {
      _paintSkill(
        canvas,
        control: control,
        progress: progress,
        tailProgress: tailProgress,
        fade: fade,
        normal: normal,
        ink: ink,
        wetInk: wetInk,
        paperScratch: paperScratch,
      );
      return;
    }

    _paintNormal(
      canvas,
      control: control,
      progress: progress,
      tailProgress: tailProgress,
      fade: fade,
      normal: normal,
      ink: ink,
      wetInk: wetInk,
      paperScratch: paperScratch,
    );
  }

  void _paintNormal(
    Canvas canvas, {
    required Offset control,
    required double progress,
    required double tailProgress,
    required double fade,
    required Offset normal,
    required Color ink,
    required Color wetInk,
    required Color paperScratch,
  }) {
    final segment = _segmentPath(tailProgress, progress, control);
    final wash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * 5.0
      ..color = color.withValues(alpha: 0.07 * fade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(segment, wash);

    final inkShadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * 2.8
      ..color = Colors.black.withValues(alpha: 0.2 * fade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawPath(segment, inkShadow);

    final mainStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * (1.42 + 0.26 * math.sin(t * math.pi))
      ..color = ink.withValues(alpha: 0.88 * fade);
    canvas.drawPath(segment, mainStroke);

    final wetCore = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(1.0, strokeWidth * 0.72)
      ..color = wetInk.withValues(alpha: 0.64 * fade);
    canvas.drawPath(
      _segmentPath(
        (tailProgress + 0.04).clamp(0.0, 1.0),
        progress,
        control,
        offset: -normal * strokeWidth * 0.18,
      ),
      wetCore,
    );

    final dryBrush = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(1.0, strokeWidth * 0.28)
      ..color = paperScratch.withValues(alpha: 0.6 * fade);
    for (final offsetScale in const [-0.72, -0.36, 0.24, 0.66]) {
      canvas.drawPath(
        _segmentPath(
          (tailProgress + 0.06 + offsetScale.abs() * 0.025).clamp(0.0, 1.0),
          (progress - 0.05).clamp(0.0, 1.0),
          control,
          offset: normal * strokeWidth * offsetScale,
        ),
        dryBrush,
      );
    }

    final head = _pointAt(progress, control);
    final tail = _pointAt(tailProgress, control);
    _drawInkDot(canvas, head, strokeWidth * 1.35, 0.62 * fade, ink);
    _drawInkDot(
      canvas,
      head - normal * strokeWidth * 1.7,
      strokeWidth * 0.45,
      0.26 * fade,
      ink,
    );
    _drawInkDot(
      canvas,
      tail + normal * strokeWidth * 1.2,
      strokeWidth * 0.34,
      0.20 * fade,
      wetInk,
    );
  }

  void _paintSkill(
    Canvas canvas, {
    required Offset control,
    required double progress,
    required double tailProgress,
    required double fade,
    required Offset normal,
    required Color ink,
    required Color wetInk,
    required Color paperScratch,
  }) {
    final head = _pointAt(progress, control);
    final tail = _pointAt(tailProgress, control);
    final segment = _segmentPath(tailProgress, progress, control);
    final pulse = math.sin(t * math.pi).clamp(0.0, 1.0);

    final outerWash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * (8.8 + pulse * 1.8)
      ..color = color.withValues(alpha: 0.11 * fade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawPath(segment, outerWash);

    final broadInk = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * (3.2 + pulse * 0.7)
      ..color = Colors.black.withValues(alpha: 0.28 * fade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.8);
    for (final offsetScale in const [-1.25, 0.0, 1.25]) {
      canvas.drawPath(
        _segmentPath(
          (tailProgress + offsetScale.abs() * 0.03).clamp(0.0, 1.0),
          progress,
          control,
          offset: normal * strokeWidth * offsetScale,
        ),
        broadInk,
      );
    }

    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth * (1.72 + pulse * 0.38)
      ..color = ink.withValues(alpha: 0.9 * fade);
    canvas.drawPath(segment, core);

    final dryBrush = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(1.0, strokeWidth * 0.34)
      ..color = paperScratch.withValues(alpha: 0.62 * fade);
    for (final offsetScale in const [-1.05, -0.5, 0.55, 1.1]) {
      canvas.drawPath(
        _segmentPath(
          (tailProgress + 0.08 + offsetScale.abs() * 0.02).clamp(0.0, 1.0),
          (progress - 0.035).clamp(0.0, 1.0),
          control,
          offset: normal * strokeWidth * offsetScale,
        ),
        dryBrush,
      );
    }

    final splashAlpha = fade * (0.45 + pulse * 0.45);
    _drawInkDot(canvas, head, strokeWidth * (3.2 + pulse), splashAlpha, ink);
    _drawInkDot(
      canvas,
      head - normal * strokeWidth * 2.4,
      strokeWidth * 1.35,
      splashAlpha * 0.72,
      wetInk,
    );
    _drawInkDot(
      canvas,
      head + normal * strokeWidth * 2.1,
      strokeWidth * 1.05,
      splashAlpha * 0.58,
      ink,
    );
    _drawInkDot(
      canvas,
      tail + normal * strokeWidth * 1.9,
      strokeWidth * 0.72,
      fade * 0.34,
      wetInk,
    );
    _drawImpactBursts(canvas, head, normal, fade, ink, paperScratch);
  }

  void _drawImpactBursts(
    Canvas canvas,
    Offset center,
    Offset normal,
    double fade,
    Color ink,
    Color paperScratch,
  ) {
    final tangent = Offset(normal.dy, -normal.dx);
    final burstPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(1.0, strokeWidth * 0.42)
      ..color = ink.withValues(alpha: 0.46 * fade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.8);
    final scratchPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = math.max(1.0, strokeWidth * 0.24)
      ..color = paperScratch.withValues(alpha: 0.56 * fade);

    for (final spec in const [
      (axis: 0, side: -1.0, len: 4.2),
      (axis: 0, side: 1.0, len: 3.5),
      (axis: 1, side: -1.0, len: 3.2),
      (axis: 1, side: 1.0, len: 2.7),
    ]) {
      final dir = (spec.axis == 0 ? tangent : normal) * spec.side;
      final from = center - dir * strokeWidth * 0.45;
      final to = center + dir * strokeWidth * spec.len;
      canvas.drawLine(from, to, burstPaint);
      canvas.drawLine(
        from + normal * strokeWidth * 0.2,
        to - dir * strokeWidth * 0.9,
        scratchPaint,
      );
    }
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

  double _unitNoise(int salt) {
    var x = seed ^ (salt * 0x45d9f3b);
    x = ((x >> 16) ^ x) * 0x45d9f3b;
    x = ((x >> 16) ^ x) * 0x45d9f3b;
    x = (x >> 16) ^ x;
    return (x & 0xffff) / 0xffff;
  }

  double _signedNoise(int salt) => _unitNoise(salt) * 2.0 - 1.0;

  void _drawInkDot(
    Canvas canvas,
    Offset center,
    double radius,
    double alpha,
    Color ink,
  ) {
    if (radius <= 0 || alpha <= 0) return;
    final paint = Paint()
      ..color = ink.withValues(alpha: alpha.clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.t != t ||
      old.start != start ||
      old.end != end ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.style != style ||
      old.seed != seed;
}

extension on Path {
  void moveToPoint(Offset p) => moveTo(p.dx, p.dy);
  void lineToPoint(Offset p) => lineTo(p.dx, p.dy);
}
