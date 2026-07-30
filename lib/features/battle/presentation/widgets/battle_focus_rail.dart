import 'package:flutter/material.dart';

import '../../../../shared/theme/wuxia_tokens.dart';

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
        color: WuxiaUi.battleFocusBase,
        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8)],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(
            child: CustomPaint(painter: _BattleFocusRailMottlePainter()),
          ),
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

class _BattleFocusRailMottlePainter extends CustomPainter {
  const _BattleFocusRailMottlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dark = Paint()
      ..color = const Color(0xFF0F100F).withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final pale = Paint()
      ..color = const Color(0xFF8B8478).withValues(alpha: 0.09)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (var i = 0; i < 18; i++) {
      final x = ((i * 47 + 13) % 193) / 193 * size.width;
      final y = ((i * 31 + 11) % 149) / 149 * size.height;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 34 + (i % 4) * 17,
          height: 14 + (i % 3) * 9,
        ),
        i.isEven ? dark : pale,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BattleFocusRailMottlePainter oldDelegate) =>
      false;
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
