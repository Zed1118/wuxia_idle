import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/wuxia_tokens.dart';
import '../../features/battle/presentation/battle_typography_tokens.dart';

/// 战斗纸本比例条。墨轨、干笔填充和数值墨托均由确定性
/// [CustomPainter] 绘制，避免现代 HUD 的光滑圆角轨道。
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
        fillColorOverride ?? (isInternalForce ? WuxiaUi.qing : WuxiaUi.jiang);
    final trackColor = trackColorOverride ?? WuxiaUi.battleStatusTrack;
    final resolvedLabelFontSize =
        labelFontSize ?? math.max(height * 0.72, 10.0);
    final labelStyle = TextStyle(
      // 内力条 height 小(9)时仍保留 10px 下限。
      fontSize: resolvedLabelFontSize,
      color: WuxiaUi.paper,
      fontWeight: FontWeight.w500,
      fontFamilyFallback: BattleTypography.uiFallback,
      fontFeatures: BattleTypography.tabularFigures,
      height: 1,
      shadows: const [Shadow(color: Colors.black54, blurRadius: 1)],
    );
    final deEmphasizeMaximum = tightLabel && max.abs() >= 10000;

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              key: const ValueKey('battle.hpBarTrack'),
              child: CustomPaint(
                key: const ValueKey('battle.hpBarInkTrack'),
                painter: BattleInkBarPainter(color: trackColor),
              ),
            ),
          ),
          if (ratio > 0)
            Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: FractionallySizedBox(
                widthFactor: ratio,
                child: SizedBox.expand(
                  child: RepaintBoundary(
                    key: const ValueKey('battle.hpBarFill'),
                    child: CustomPaint(
                      key: const ValueKey('battle.hpBarInkFill'),
                      painter: BattleInkBarPainter(
                        color: fillColor,
                        isFill: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (showLabel)
            Center(
              child: CustomPaint(
                key: const ValueKey('battle.hpBarLabelInkPlate'),
                painter: const _BarLabelInkPlatePainter(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: deEmphasizeMaximum
                      ? Text.rich(
                          key: const ValueKey(
                            'battle.hpBarDeemphasizedMaxLabel',
                          ),
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$labelPrefix$current',
                                style: labelStyle,
                              ),
                              TextSpan(
                                text: '/$max',
                                style: labelStyle.copyWith(
                                  color: WuxiaUi.paper.withValues(alpha: 0.68),
                                  fontSize: resolvedLabelFontSize * 0.88,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          compactLabel
                              ? '$labelPrefix${_compactBattleValue(current)}/${_compactBattleValue(max)}'
                              : tightLabel
                              ? '$labelPrefix$current/$max'
                              : '$labelPrefix$current / $max',
                          style: labelStyle,
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 用同一个可验证的墨轨绘制器统一 HP/真气的纸本边缘。
class BattleInkBarPainter extends CustomPainter {
  const BattleInkBarPainter({required this.color, this.isFill = false});

  final Color color;
  final bool isFill;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final h = size.height;
    final w = size.width;
    final body = Path()
      ..moveTo(0, h * 0.28)
      ..lineTo(w * 0.07, h * 0.13)
      ..lineTo(w * 0.24, h * 0.20)
      ..lineTo(w * 0.48, h * 0.08)
      ..lineTo(w * 0.72, h * 0.18)
      ..lineTo(w * 0.93, h * 0.10)
      ..lineTo(w, h * 0.30)
      ..lineTo(w * 0.97, h * 0.76)
      ..lineTo(w * 0.80, h * 0.88)
      ..lineTo(w * 0.57, h * 0.80)
      ..lineTo(w * 0.35, h * 0.92)
      ..lineTo(w * 0.12, h * 0.82)
      ..lineTo(0, h * 0.68)
      ..close();
    canvas.drawPath(body, Paint()..color = color);

    final edgeColor = Color.lerp(color, WuxiaUi.ink, isFill ? 0.42 : 0.68)!;
    canvas.drawPath(
      body,
      Paint()
        ..color = edgeColor.withValues(alpha: 0.82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.65, h * 0.075)
        ..strokeCap = StrokeCap.square,
    );

    final fiber = Paint()
      ..color = (isFill ? WuxiaUi.paper2 : WuxiaUi.ink).withValues(
        alpha: isFill ? 0.16 : 0.28,
      )
      ..strokeWidth = math.max(0.45, h * 0.045)
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(w * 0.04, h * 0.33),
      Offset(w * 0.31, h * 0.27),
      fiber,
    );
    canvas.drawLine(
      Offset(w * 0.58, h * 0.67),
      Offset(w * 0.91, h * 0.61),
      fiber,
    );
  }

  @override
  bool shouldRepaint(covariant BattleInkBarPainter oldDelegate) =>
      color != oldDelegate.color || isFill != oldDelegate.isFill;
}

class _BarLabelInkPlatePainter extends CustomPainter {
  const _BarLabelInkPlatePainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final path = Path()
      ..moveTo(0, size.height * 0.28)
      ..lineTo(size.width * 0.08, size.height * 0.12)
      ..lineTo(size.width * 0.92, size.height * 0.18)
      ..lineTo(size.width, size.height * 0.72)
      ..lineTo(size.width * 0.88, size.height * 0.90)
      ..lineTo(size.width * 0.10, size.height * 0.84)
      ..close();
    canvas.drawPath(path, Paint()..color = WuxiaUi.ink.withValues(alpha: 0.48));
  }

  @override
  bool shouldRepaint(covariant _BarLabelInkPlatePainter oldDelegate) => false;
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
