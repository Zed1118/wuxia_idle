import 'package:flutter/material.dart';

/// 技能签内墨线；基础纸签形态与后续五态在此单点演进。
class BattleSkillSlipInkFrame extends StatelessWidget {
  const BattleSkillSlipInkFrame({super.key, required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BattleSkillSlipFramePainter(accent: accent));
  }
}

class _BattleSkillSlipFramePainter extends CustomPainter {
  const _BattleSkillSlipFramePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = const Color(0xFF5B4934).withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRect(
      Rect.fromLTWH(4.5, 4.5, size.width - 9, size.height - 9),
      ink,
    );

    final accentPaint = Paint()
      ..color = accent.withValues(alpha: 0.82)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      const Offset(4.5, 7),
      Offset(4.5, size.height - 7),
      accentPaint,
    );

    final corner = Paint()
      ..color = const Color(0xFF382E24).withValues(alpha: 0.54)
      ..strokeWidth = 1.1;
    canvas.drawLine(const Offset(9, 9), const Offset(20, 9), corner);
    canvas.drawLine(const Offset(9, 9), const Offset(9, 18), corner);
    canvas.drawLine(
      Offset(size.width - 9, size.height - 9),
      Offset(size.width - 20, size.height - 9),
      corner,
    );
    canvas.drawLine(
      Offset(size.width - 9, size.height - 9),
      Offset(size.width - 9, size.height - 18),
      corner,
    );
  }

  @override
  bool shouldRepaint(covariant _BattleSkillSlipFramePainter oldDelegate) =>
      oldDelegate.accent != accent;
}
