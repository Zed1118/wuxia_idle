import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/wuxia_tokens.dart';
import '../../theme/wuxia_typography.dart';
import '../wuxia_image.dart';

/// 长尾深色页面的题头。只强化题签、朱印和枯笔分隔，不承担页面布局。
class InkPageHeader extends StatelessWidget {
  const InkPageHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            WuxiaColors.inkPanelTop.withValues(alpha: 0.86),
            WuxiaColors.inkPanelBottom.withValues(alpha: 0.18),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: WuxiaColors.inkPanelEdge.withValues(alpha: 0.82),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: WuxiaImage(
                WuxiaUi.sealRed,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    color: WuxiaUi.jiang.withValues(alpha: 0.72),
                    border: Border.all(
                      color: WuxiaUi.paper.withValues(alpha: 0.34),
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WuxiaTypography.featureTitleStyle(
                      WuxiaColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: WuxiaTypography.supportingStyle(
                      WuxiaColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 深色档案/流程页的紧凑分区题签：左侧绛红落笔、标题、右侧枯笔线。
class InkSectionLabel extends StatelessWidget {
  const InkSectionLabel(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: WuxiaUi.jiang,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: WuxiaTypography.sectionTitleStyle(WuxiaUi.gold)),
        const SizedBox(width: 10),
        const Expanded(
          child: SizedBox(
            height: 7,
            child: CustomPaint(
              key: ValueKey('inkArchive.sectionDryBrush'),
              painter: _InkArchiveDividerPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

/// 深色列表卡的统一表面。调用方继续保留原 InkWell、padding 和交互语义。
class InkListCard extends StatelessWidget {
  const InkListCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    this.selected = false,
    this.enabled = true,
    this.accent = WuxiaUi.gold,
    this.borderRadius = 6,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool selected;
  final bool enabled;
  final Color accent;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.56;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WuxiaColors.inkPanelTop.withValues(alpha: opacity),
            WuxiaColors.inkPanelBottom.withValues(alpha: opacity),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: selected
              ? accent
              : WuxiaColors.inkPanelEdge.withValues(
                  alpha: enabled ? 0.88 : 0.46,
                ),
          width: selected ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: enabled ? 0.16 : 0.08),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (selected)
            Positioned(
              key: const ValueKey('inkArchive.selectedMark'),
              left: 0,
              top: 8,
              bottom: 8,
              width: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _InkArchiveDividerPainter extends CustomPainter {
  const _InkArchiveDividerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final main = Paint()
      ..color = WuxiaUi.gold.withValues(alpha: 0.34)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final dry = Paint()
      ..color = WuxiaUi.paper.withValues(alpha: 0.12)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final y = size.height * 0.5;
    canvas.drawLine(Offset(0, y), Offset(size.width * 0.76, y), main);
    canvas.drawLine(
      Offset(size.width * 0.16, y - 1.5),
      Offset(size.width * 0.48, y - 0.6),
      dry,
    );
    canvas.drawLine(
      Offset(size.width * 0.62, y + 1.2),
      Offset(size.width, y + 0.4),
      dry,
    );
  }

  @override
  bool shouldRepaint(covariant _InkArchiveDividerPainter oldDelegate) => false;
}
