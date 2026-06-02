import 'package:flutter/material.dart';

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
    // 头随 t 前进，尾拖 0.3 形成笔触；整体随 t 渐隐。
    final head = Offset.lerp(start, end, t)!;
    final tail = Offset.lerp(start, end, (t - 0.3).clamp(0.0, 1.0))!;
    final paint = Paint()
      ..color = color.withValues(alpha: (1.0 - t) * 0.9)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tail, head, paint);
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.t != t || old.start != start || old.end != end;
}
