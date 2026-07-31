import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/theme/colors.dart';
import 'battle_typography_tokens.dart';

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
  final Color? fillColorOverride;
  final Color? trackColorOverride;
  final double? labelFontSize;
  final bool compactLabel;
  final bool tightLabel;

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
    this.fillColorOverride,
    this.trackColorOverride,
    this.labelFontSize,
    this.compactLabel = false,
    this.tightLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = max <= 0 ? 0.0 : (current / max).clamp(0.0, 1.0).toDouble();
    final fillColor =
        fillColorOverride ??
        (isInternalForce
            ? WuxiaColors.internalForce
            : WuxiaColors.hpColor(ratio));
    final borderRadius = BorderRadius.circular(2);

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                key: const ValueKey('battle.hpBarTrack'),
                color: trackColorOverride ?? WuxiaColors.barTrack,
              ),
            ),
            FractionallySizedBox(
              widthFactor: ratio,
              child: SizedBox.expand(
                child: ColoredBox(
                  key: const ValueKey('battle.hpBarFill'),
                  color: fillColor,
                ),
              ),
            ),
            if (showLabel)
              Center(
                child: Text(
                  compactLabel
                      ? '$labelPrefix${_compactBattleValue(current)}/${_compactBattleValue(max)}'
                      : tightLabel
                      ? '$labelPrefix$current/$max'
                      : '$labelPrefix$current / $max',
                  style: TextStyle(
                    // 内力条 height 小(9)时 height*0.72≈6.5px 近不可读，设 10px 下限。
                    fontSize: labelFontSize ?? math.max(height * 0.72, 10.0),
                    color: WuxiaColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontFamilyFallback: BattleTypography.uiFallback,
                    fontFeatures: BattleTypography.tabularFigures,
                    height: 1,
                    shadows: const [
                      Shadow(color: Colors.black54, blurRadius: 2),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 全人物舞台的状态牌宽度受站位景深限制，五位数以上改用
/// K 缩写避免挤压。通用详情页未开 [HpBar.compactLabel]，仍显示完整值。
String _compactBattleValue(int value) {
  if (value.abs() < 10000) return '$value';
  final thousands = value / 1000;
  final fractionDigits = value.abs() < 100000 && value.abs() % 1000 != 0
      ? 1
      : 0;
  return '${thousands.toStringAsFixed(fractionDigits)}K';
}
