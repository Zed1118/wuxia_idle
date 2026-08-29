import 'package:flutter/material.dart';

import '../../../../shared/theme/wuxia_tokens.dart';
import 'phase0a_presentation_tokens.dart';

/// Existing battlefield art rendered larger than the viewport and translated
/// against the camera. This supplies world-motion evidence while the player is
/// pinned to the center by the existing camera follow rule.
final class Phase0aParallaxBackground extends StatelessWidget {
  const Phase0aParallaxBackground({super.key, required this.cameraOffset});

  final Offset cameraOffset;

  static Offset translationForCamera(Offset cameraOffset) => Offset(
    -cameraOffset.dx * Phase0aPresentationTokens.backgroundParallaxFactor,
    -cameraOffset.dy * Phase0aPresentationTokens.backgroundParallaxFactor,
  );

  @override
  Widget build(BuildContext context) => Transform.translate(
    key: const ValueKey('phase0a_background_parallax_translation'),
    offset: translationForCamera(cameraOffset),
    child: Transform.scale(
      key: const ValueKey('phase0a_background_parallax_scale'),
      scale: Phase0aPresentationTokens.backgroundParallaxScale,
      child: Image.asset(
        'assets/scenes/battle_mountain_pass_stage_v2.png',
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => const ColoredBox(color: WuxiaUi.ink),
      ),
    ),
  );
}
