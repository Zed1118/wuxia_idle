import 'package:flutter/material.dart';

/// 执招者名帖的统一墨框，内容与点击语义由调用方提供。
class BattleFocusRailSurface extends StatelessWidget {
  const BattleFocusRailSurface({
    super.key,
    required this.width,
    required this.child,
    this.height,
  });

  final double width;
  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final expandedSampleStyle = (height ?? 0) >= 190;
    return Container(
      key: const ValueKey('battle_desk_focus_region'),
      width: width,
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xB3131210),
        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8)],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(
            key: ValueKey('battle.focusRailOrnateFrame'),
            painter: _BattleFocusRailFramePainter(),
          ),
          Padding(
            padding: expandedSampleStyle
                ? const EdgeInsets.fromLTRB(19, 4, 26, 6)
                : const EdgeInsets.fromLTRB(12, 4, 12, 6),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _BattleFocusRailFramePainter extends CustomPainter {
  const _BattleFocusRailFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Paint()
      ..color = const Color(0xFF7A6448).withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final inner = Paint()
      ..color = const Color(0xFF4E4030).withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRect(Offset.zero & size, outer);
    canvas.drawRect(
      Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
      inner,
    );

    final ornament = Paint()
      ..color = const Color(0xFF8D714E).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final faintOrnament = Paint()
      ..color = const Color(0xFF8D714E).withValues(alpha: 0.26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    for (final anchor in [
      const Offset(7, 7),
      Offset(size.width - 7, 7),
      Offset(7, size.height - 7),
      Offset(size.width - 7, size.height - 7),
    ]) {
      canvas.drawCircle(anchor, 2.3, ornament);
      canvas.drawCircle(anchor, 4.8, faintOrnament);
    }
    canvas.drawLine(
      Offset(size.width + 10, size.height * 0.08),
      Offset(size.width + 10, size.height * 0.92),
      inner,
    );
  }

  @override
  bool shouldRepaint(covariant _BattleFocusRailFramePainter oldDelegate) =>
      false;
}
