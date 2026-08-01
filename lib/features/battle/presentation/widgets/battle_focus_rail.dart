import 'package:flutter/material.dart';

import '../../../../shared/theme/wuxia_tokens.dart';
import '../battle_layout_tokens.dart';

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
    final responsiveStyle = BattleDeskResponsiveStyle.fromSlotHeight(
      height ?? BattleLayoutTokens.sampleStyleCompactSlotHeight,
    );
    final rail = Container(
      key: const ValueKey('battle_desk_focus_region'),
      width: width,
      height: height == null ? null : height! + responsiveStyle.value(0, 8),
      decoration: const BoxDecoration(
        color: WuxiaUi.battleFocusBase,
        boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 8)],
      ),
      child: Stack(
        clipBehavior: Clip.none,
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
            padding: EdgeInsets.fromLTRB(
              responsiveStyle.value(12, 19),
              4,
              responsiveStyle.value(12, 26),
              6,
            ),
            child: child,
          ),
        ],
      ),
    );
    return Transform.translate(
      offset: Offset(0, responsiveStyle.value(0, -3)),
      child: rail,
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
    final lightGrain = Paint()
      ..color = const Color(0xFFC3B7A1).withValues(alpha: 0.045);
    final darkGrain = Paint()
      ..color = const Color(0xFF0D0E0D).withValues(alpha: 0.07);
    for (var i = 0; i < 96; i++) {
      final x = ((i * 73 + 19) % 257) / 257 * size.width;
      final y = ((i * 41 + 13) % 193) / 193 * size.height;
      canvas.drawCircle(
        Offset(x, y),
        0.24 + (i % 3) * 0.14,
        i.isEven ? lightGrain : darkGrain,
      );
    }
    final fiber = Paint()
      ..color = const Color(0xFFB6AA95).withValues(alpha: 0.038)
      ..strokeWidth = 0.45;
    for (var i = 0; i < 17; i++) {
      final y = 8.0 + i * ((size.height - 16) / 17);
      final start = ((i * 53) % 149) / 149 * size.width * 0.7;
      canvas.drawLine(
        Offset(start, y),
        Offset(start + 18 + (i % 4) * 12, y + 0.5),
        fiber,
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
      ..color = const Color(0xFF8D714E).withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final faintOrnament = Paint()
      ..color = const Color(0xFF8D714E).withValues(alpha: 0.18)
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

    void drawCornerFlourish(Offset anchor, double scaleX, double scaleY) {
      canvas.save();
      canvas.translate(anchor.dx, anchor.dy);
      canvas.scale(scaleX, scaleY);
      final curl = Path()
        ..moveTo(0, 13)
        ..cubicTo(5, 13, 7, 11, 7, 7)
        ..cubicTo(7, 3, 10, 1, 14, 1)
        ..moveTo(1, 14)
        ..cubicTo(1, 10, 3, 7, 7, 7)
        ..cubicTo(11, 7, 13, 5, 13, 0);
      canvas.drawPath(curl, ornament);
      final diamond = Path()
        ..moveTo(7, 4)
        ..lineTo(10, 7)
        ..lineTo(7, 10)
        ..lineTo(4, 7)
        ..close();
      canvas.drawPath(diamond, faintOrnament);
      canvas.restore();
    }

    drawCornerFlourish(Offset.zero, 1, 1);
    drawCornerFlourish(Offset(size.width, 0), -1, 1);
    drawCornerFlourish(Offset(0, size.height), 1, -1);
    drawCornerFlourish(Offset(size.width, size.height), -1, -1);

    final dividerX = size.width + 20;
    canvas.drawLine(
      Offset(dividerX, 15),
      Offset(dividerX, size.height - 15),
      faintOrnament,
    );
    for (final y in [20.0, size.height / 2, size.height - 20]) {
      final knot = Path()
        ..moveTo(dividerX, y - 4)
        ..lineTo(dividerX + 3, y)
        ..lineTo(dividerX, y + 4)
        ..lineTo(dividerX - 3, y)
        ..close();
      canvas.drawPath(knot, faintOrnament);
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
