import 'package:flutter/material.dart';

/// 受击闪：命中瞬间染亮目标的非透明像素（白/绛红），
/// 随 animation 淡出。不使用铺满槽位的矩形色块，避免破坏立绘轮廓。
/// 由 battle_screen 在 actionLog 边沿驱动 controller，纯表现层（不写 BattleState）。
class HitFlash extends StatelessWidget {
  final Animation<double> animation;
  final Color color;
  final Widget child;
  const HitFlash({
    super.key,
    required this.animation,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (_, child) {
        final alpha = ((1.0 - animation.value) * 0.42).clamp(0.0, 1.0);
        if (alpha <= 0.001) return child!;
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
            color.withValues(alpha: alpha),
            BlendMode.srcATop,
          ),
          child: child!,
        );
      },
    );
  }
}
