import 'package:flutter/material.dart';

/// 战备行囊的独立装帧，避免与纸签共享按钮外观。
class BattlePouchRailSurface extends StatelessWidget {
  const BattlePouchRailSurface({
    super.key,
    required this.width,
    required this.compact,
    required this.child,
  });

  final double width;
  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('battle_desk_pouch_region'),
      width: width,
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(color: Color(0xB3131210)),
      child: Container(
        key: const ValueKey('battle.pouch.woodCase'),
        padding: compact
            ? const EdgeInsets.fromLTRB(10, 3, 10, 3)
            : const EdgeInsets.fromLTRB(10, 6, 10, 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3C2C20), Color(0xFF251B15), Color(0xFF332419)],
            stops: [0, 0.58, 1],
          ),
          border: Border.all(color: const Color(0xFF8A6945), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: CustomPaint(painter: _WoodCaseGrainPainter(), child: child),
      ),
    );
  }
}

class _WoodCaseGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grain = Paint()
      ..color = const Color(0x198E6C47)
      ..strokeWidth = 0.8;
    for (var y = 8.0; y < size.height; y += 13) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 2), grain);
    }
    final joint = Paint()..color = const Color(0x806E5135);
    for (final x in [5.0, size.width - 5]) {
      canvas.drawCircle(Offset(x, 5), 1.2, joint);
      canvas.drawCircle(Offset(x, size.height - 5), 1.2, joint);
    }
  }

  @override
  bool shouldRepaint(covariant _WoodCaseGrainPainter oldDelegate) => false;
}
