import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// 水墨 loading 指示器（P0-2 2026-06-29 审查修复 · 替换 Material
/// CircularProgressIndicator）。
///
/// 砚台墨晕扩散:中心墨点 + 数圈墨晕由内向外扩散并淡出,循环 1.5s。水墨克制,
/// 无炫光特效。颜色走 [WuxiaColors]（默认 [WuxiaColors.textMuted] 在深色底
/// 可读），不硬编码。提供 const 构造,可直接 `const InkLoadingIndicator()`
/// 替换 `const CircularProgressIndicator()`（strokeWidth 参数无需迁移）。
class InkLoadingIndicator extends StatefulWidget {
  const InkLoadingIndicator({
    super.key,
    this.size = 48,
    this.color = WuxiaColors.textMuted,
  });

  /// 方形边长（px）。默认 48,对齐原 CircularProgressIndicator 视觉占位。
  final double size;

  /// 墨色。默认 [WuxiaColors.textMuted];调用方原本指定了 color 的沿用其值。
  final Color color;

  @override
  State<InkLoadingIndicator> createState() => _InkLoadingIndicatorState();
}

class _InkLoadingIndicatorState extends State<InkLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) => CustomPaint(
          painter: _InkRipplePainter(t: _ctrl.value, color: widget.color),
        ),
      ),
    );
  }
}

/// 墨晕扩散绘制:[rippleCount] 圈错相位墨晕由内向外扩散淡出 + 中心墨点。
class _InkRipplePainter extends CustomPainter {
  _InkRipplePainter({required this.t, required this.color});

  /// 动画相位 [0,1)。
  final double t;
  final Color color;

  static const int rippleCount = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2;

    // 中心墨点(砚心),恒定半透。
    canvas.drawCircle(
      center,
      maxRadius * 0.14,
      Paint()..color = color.withValues(alpha: 0.55),
    );

    // 错相位墨晕圈:每圈 phase = (t + i/count) % 1,半径随 phase 扩散,
    // 透明度随扩散淡出(由浓到无)。
    for (var i = 0; i < rippleCount; i++) {
      final phase = (t + i / rippleCount) % 1.0;
      final radius = maxRadius * (0.18 + phase * 0.82);
      final alpha = (1.0 - phase) * 0.5;
      if (alpha <= 0.01) continue;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = maxRadius * 0.10,
      );
    }
  }

  @override
  bool shouldRepaint(_InkRipplePainter old) =>
      old.t != t || old.color != color;
}
