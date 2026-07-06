import 'package:flutter/material.dart';

import '../../theme/wuxia_tokens.dart';
import 'panel_surface.dart';

/// 分区小标（UI kit · demo `.wx .shead`）：墨笔标题 + 底部枯笔分隔线。
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.dividerMaxWidth = 560,
    this.dividerOpacity = 0.68,
  });

  final String title;
  final double dividerMaxWidth;
  final double dividerOpacity;

  @override
  Widget build(BuildContext context) {
    final surface = PanelSurface.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: surface.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 5),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: dividerMaxWidth),
              child: SizedBox(
                width: double.infinity,
                height: 8,
                child: Opacity(
                  opacity: dividerOpacity,
                  child: CustomPaint(
                  painter: _SectionDividerPainter(surface.secondary),
                ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDividerPainter extends CustomPainter {
  const _SectionDividerPainter(this.inkColor);

  /// 枯笔分隔线墨色（随面板底色翻转，取 [PanelSurface.secondary]）。
  final Color inkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final main = Paint()
      ..color = inkColor.withValues(alpha: 0.42)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final dry = Paint()
      ..color = inkColor.withValues(alpha: 0.18)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final accent = Paint()
      ..color = WuxiaUi.woodDark.withValues(alpha: 0.16)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    final y = size.height * 0.52;
    canvas.drawLine(Offset.zero.translate(0, y), Offset(size.width, y), main);
    canvas.drawLine(
      Offset(size.width * 0.04, y - 2),
      Offset(size.width * 0.32, y - 1.1),
      dry,
    );
    canvas.drawLine(
      Offset(size.width * 0.42, y + 1.6),
      Offset(size.width * 0.92, y + 0.8),
      accent,
    );
    canvas.drawLine(
      Offset(size.width * 0.72, y - 1.5),
      Offset(size.width, y - 1.2),
      dry,
    );
  }

  @override
  bool shouldRepaint(covariant _SectionDividerPainter oldDelegate) =>
      oldDelegate.inkColor != inkColor;
}
