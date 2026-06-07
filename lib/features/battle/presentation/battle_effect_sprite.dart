import 'package:flutter/material.dart';

/// 单次战斗 MJ 特效贴片。由外层 actionLog 边沿创建，动画结束后移除。
class BattleEffectSprite extends StatelessWidget {
  const BattleEffectSprite({
    super.key,
    required this.assetPath,
    required this.animation,
    this.size = 220,
    this.opacity = 0.82,
    this.rotation = 0,
    this.mirrored = false,
  });

  final String assetPath;
  final Animation<double> animation;
  final double size;
  final double opacity;
  final double rotation;
  final bool mirrored;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value.clamp(0.0, 1.0);
        final fadeIn = (t / 0.18).clamp(0.0, 1.0);
        final fadeOut = ((1.0 - t) / 0.34).clamp(0.0, 1.0);
        final alpha = opacity * fadeIn * fadeOut;
        final scale = 0.82 + t * 0.26;
        return Opacity(
          opacity: alpha,
          child: Transform.scale(
            scaleX: mirrored ? -scale : scale,
            scaleY: scale,
            child: Transform.rotate(
              angle: rotation,
              child: Image.asset(
                assetPath,
                width: size,
                height: size,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
