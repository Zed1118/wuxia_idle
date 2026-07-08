import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/inventory_providers.dart';
import '../../strings.dart';
import '../../theme/wuxia_tokens.dart';

enum CurrencyPillTone { paper, dark }

class CurrencyIcon extends StatelessWidget {
  const CurrencyIcon({
    super.key,
    this.size = 18,
    this.color = WuxiaUi.gold,
    this.backgroundColor,
  });

  final double size;
  final Color color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CurrencyIconPainter(
        color: color,
        backgroundColor: backgroundColor ?? color.withValues(alpha: 0.14),
      ),
    );
  }
}

class CurrencyAmountPill extends StatelessWidget {
  const CurrencyAmountPill({
    super.key,
    required this.amount,
    this.tone = CurrencyPillTone.paper,
    this.compact = false,
  });

  final int amount;
  final CurrencyPillTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = tone == CurrencyPillTone.dark;
    final textColor = isDark ? WuxiaUi.paper : WuxiaUi.ink;
    final mutedColor = isDark
        ? WuxiaUi.paper.withValues(alpha: 0.70)
        : WuxiaUi.muted;
    final borderColor = isDark
        ? WuxiaUi.gold.withValues(alpha: 0.46)
        : WuxiaUi.gold.withValues(alpha: 0.38);
    final fillColor = isDark
        ? WuxiaUi.ink.withValues(alpha: 0.68)
        : WuxiaUi.paper.withValues(alpha: 0.70);

    return Tooltip(
      message: UiStrings.currencySilverTooltip,
      child: Semantics(
        label: UiStrings.silverBalanceLabel(amount),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 9 : 11,
              vertical: compact ? 5 : 7,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CurrencyIcon(
                  size: compact ? 16 : 18,
                  color: WuxiaUi.gold,
                  backgroundColor: isDark
                      ? WuxiaUi.gold.withValues(alpha: 0.18)
                      : WuxiaUi.gold.withValues(alpha: 0.12),
                ),
                SizedBox(width: compact ? 6 : 8),
                Text(
                  UiStrings.silverBalanceLabel(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: compact ? 12.5 : 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: compact ? 0.8 : 1.2,
                    height: 1.05,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 6),
                  Text(
                    UiStrings.currencySilverUnit,
                    style: TextStyle(
                      color: mutedColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SilverBalancePill extends ConsumerWidget {
  const SilverBalancePill({
    super.key,
    this.tone = CurrencyPillTone.paper,
    this.compact = false,
  });

  final CurrencyPillTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = ref
        .watch(inventoryQuantityByDefIdProvider('item_silver'))
        .maybeWhen(data: (n) => n, orElse: () => 0);
    return CurrencyAmountPill(
      key: const Key('silver_balance_pill'),
      amount: amount,
      tone: tone,
      compact: compact,
    );
  }
}

class _CurrencyIconPainter extends CustomPainter {
  const _CurrencyIconPainter({
    required this.color,
    required this.backgroundColor,
  });

  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final fill = Paint()..color = backgroundColor;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.16
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius * 0.88, fill);
    canvas.drawCircle(center, radius * 0.76, stroke);

    final hole = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: radius * 0.72,
        height: radius * 0.72,
      ),
      Radius.circular(radius * 0.08),
    );
    canvas.drawRRect(
      hole,
      Paint()
        ..color = color.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(hole, stroke..strokeWidth = radius * 0.12);

    final markPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - radius * 0.46, center.dy),
      Offset(center.dx - radius * 0.28, center.dy),
      markPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.28, center.dy),
      Offset(center.dx + radius * 0.46, center.dy),
      markPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CurrencyIconPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.backgroundColor != backgroundColor;
}
