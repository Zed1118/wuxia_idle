import 'package:flutter/material.dart';

import '../theme/wuxia_tokens.dart';
import 'asset_fallback.dart';

/// Equipment artwork that blends white-backed assets into the paper UI.
class EquipmentArtImage extends StatelessWidget {
  const EquipmentArtImage({
    super.key,
    required this.imagePath,
    required this.fallback,
    this.fit = BoxFit.contain,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 3,
    this.backgroundOpacity = 0.08,
    this.tintOpacity = 1,
  });

  final String imagePath;
  final Widget fallback;
  final BoxFit fit;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double backgroundOpacity;
  final double tintOpacity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: WuxiaUi.paper.withValues(alpha: backgroundOpacity),
        ),
        child: Padding(
          padding: padding,
          child: Image.asset(
            imagePath,
            fit: fit,
            color: WuxiaUi.paper2.withValues(alpha: tintOpacity),
            colorBlendMode: BlendMode.multiply,
            errorBuilder: wuxiaAssetErrorBuilder(() => fallback),
          ),
        ),
      ),
    );
  }
}
