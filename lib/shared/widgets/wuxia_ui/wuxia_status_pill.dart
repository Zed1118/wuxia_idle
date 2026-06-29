import 'package:flutter/material.dart';

import '../../theme/colors.dart';

enum WuxiaStatusTone { neutral, positive, negative, warning, accent }

/// 深色面板上的小型状态标记，供装备仓库 / 角色面板共享。
class WuxiaStatusPill extends StatelessWidget {
  const WuxiaStatusPill({
    super.key,
    required this.label,
    this.tone = WuxiaStatusTone.neutral,
    this.icon,
    this.dense = false,
  });

  final String label;
  final WuxiaStatusTone tone;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      WuxiaStatusTone.neutral => WuxiaColors.statNeutral,
      WuxiaStatusTone.positive => WuxiaColors.statIncrease,
      WuxiaStatusTone.negative => WuxiaColors.statDecrease,
      WuxiaStatusTone.warning => WuxiaColors.resultHighlight,
      WuxiaStatusTone.accent => WuxiaColors.internalForce,
    };
    final vertical = dense ? 2.0 : 3.0;
    final horizontal = dense ? 6.0 : 8.0;
    final fontSize = dense ? 11.0 : 12.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.58)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontal,
          vertical: vertical,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: fontSize + 1, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
