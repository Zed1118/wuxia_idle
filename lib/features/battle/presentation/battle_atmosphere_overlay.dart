import 'package:flutter/material.dart';

import '../../../shared/theme/wuxia_tokens.dart';

/// 战斗背景氛围层：只叠加轻雾、远灯与低血暗角，不参与交互和战斗结算。
class BattleAtmosphereOverlay extends StatelessWidget {
  const BattleAtmosphereOverlay({
    super.key,
    this.showLowHealth = false,
    this.showInkCloud = false,
  });

  final bool showLowHealth;
  final bool showInkCloud;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _AtmosphereImage(path: WuxiaUi.overlayMistLayer, opacity: 0.18),
          const _AtmosphereImage(
            path: WuxiaUi.overlayLanternGlow,
            opacity: 0.16,
          ),
          if (showInkCloud)
            const _AtmosphereImage(
              path: WuxiaUi.overlayInkCloud,
              opacity: 0.16,
            ),
          if (showLowHealth)
            const _AtmosphereImage(
              path: WuxiaUi.overlayLowHealth,
              opacity: 0.34,
            ),
        ],
      ),
    );
  }
}

class _AtmosphereImage extends StatelessWidget {
  const _AtmosphereImage({required this.path, required this.opacity});

  final String path;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
