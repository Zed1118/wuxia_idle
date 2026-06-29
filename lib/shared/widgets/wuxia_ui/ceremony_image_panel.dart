import 'package:flutter/material.dart';

import '../../theme/wuxia_tokens.dart';
import '../wuxia_image.dart';

/// MJ 仪式图承载层：底图只作氛围，伪文字由半透明宣纸面遮盖。
class CeremonyImagePanel extends StatelessWidget {
  const CeremonyImagePanel({
    super.key,
    required this.assetPath,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = WuxiaUi.radius,
    this.borderColor,
    this.imageOpacity = 0.42,
    this.paperVeilOpacity = 0.76,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final String assetPath;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? borderColor;
  final double imageOpacity;
  final double paperVeilOpacity;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: 0.92),
        borderRadius: radius,
        border: Border.all(
          color: borderColor ?? WuxiaUi.ink.withValues(alpha: 0.34),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: imageOpacity,
                child: WuxiaImage(
                  assetPath,
                  fit: fit,
                  alignment: alignment,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: WuxiaUi.paper.withValues(alpha: paperVeilOpacity),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
