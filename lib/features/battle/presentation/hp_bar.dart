import 'package:flutter/material.dart';

import '../../../shared/theme/colors.dart';

/// 通用比例条（phase1_tasks.md T14 §785-786）。
///
/// 用 Stack 把背景轨道、按比例填充的前景、居中文本三层叠起来。
/// `isInternalForce=true` 走内力蓝；否则走 HP 三段色。
class HpBar extends StatelessWidget {
  final int current;
  final int max;
  final double height;
  final bool isInternalForce;
  final bool showLabel;

  /// 居中数值前的标签前缀（如内力条传「内 」→「内 100 / 100」）。
  /// 走 [UiStrings]，不在调用点内联中文。
  final String labelPrefix;

  const HpBar({
    super.key,
    required this.current,
    required this.max,
    this.height = 12,
    this.isInternalForce = false,
    this.showLabel = true,
    this.labelPrefix = '',
  });

  @override
  Widget build(BuildContext context) {
    final ratio = max <= 0 ? 0.0 : (current / max).clamp(0.0, 1.0).toDouble();
    final fillColor = isInternalForce
        ? WuxiaColors.internalForce
        : WuxiaColors.hpColor(ratio);
    final borderRadius = BorderRadius.circular(2);

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: WuxiaColors.barTrack,
              borderRadius: borderRadius,
            ),
          ),
          FractionallySizedBox(
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: borderRadius,
              ),
            ),
          ),
          if (showLabel)
            Center(
              child: Text(
                '$labelPrefix$current / $max',
                style: TextStyle(
                  fontSize: height * 0.72,
                  color: WuxiaColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
