import 'package:flutter/material.dart';

/// 受击闪：命中瞬间在目标上叠一层半透明色块(白/绛红)，随 animation 淡出(P0-2)。
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
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: animation,
              builder: (_, _) {
                final a = (1.0 - animation.value) * 0.5;
                return ColoredBox(color: color.withValues(alpha: a));
              },
            ),
          ),
        ),
      ],
    );
  }
}
