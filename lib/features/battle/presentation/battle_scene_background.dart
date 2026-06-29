import 'package:flutter/material.dart';

import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_image.dart';

enum BattleSceneBackgroundStyle {
  generic,
  mainline,
  tower,
  boss,
  innerDemon,
  lightFoot,
  massBattle,
}

/// 战斗场景背景层(出版美术 B1):背景图 + scrim 压暗遮罩 + 水墨层次兜底。
/// path 空时仍渲染远山、雾气、地面纹理和暗角,避免露出纯黑/纯白空底。
/// Image.asset 挂 errorBuilder(widget 测不加载 assets,守测不破)。
class BattleSceneBackground extends StatelessWidget {
  final String? path;
  final BattleSceneBackgroundStyle style;

  const BattleSceneBackground({
    super.key,
    this.path,
    this.style = BattleSceneBackgroundStyle.generic,
  });

  @override
  Widget build(BuildContext context) {
    final p = path;
    final hasImage = p != null && p.isNotEmpty;
    final profile = _SceneDepthProfile.resolve(path: p, style: style);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          key: const ValueKey('battle_scene_ink_fallback'),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [profile.skyTop, profile.skyMid, WuxiaColors.background],
              stops: const [0.0, 0.58, 1.0],
            ),
          ),
        ),
        CustomPaint(
          key: const ValueKey('battle_scene_distant_mountains'),
          painter: _DistantMountainPainter(profile),
        ),
        if (hasImage)
          WuxiaImage(
            p,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        CustomPaint(
          key: const ValueKey('battle_scene_mist_layers'),
          painter: _MistLayerPainter(profile),
        ),
        CustomPaint(
          key: const ValueKey('battle_scene_ground_texture'),
          painter: _GroundTexturePainter(profile),
        ),
        DecoratedBox(
          key: const ValueKey('battle_scene_glow_vignette'),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: profile.glowCenter,
              radius: profile.glowRadius,
              colors: [
                profile.glowColor.withValues(alpha: profile.glowAlpha),
                WuxiaColors.background.withValues(alpha: 0.0),
                WuxiaColors.background.withValues(alpha: profile.vignetteAlpha),
              ],
              stops: const [0.0, 0.48, 1.0],
            ),
          ),
        ),
        if (hasImage) const ColoredBox(color: WuxiaColors.battleSceneScrim),
      ],
    );
  }
}

class _SceneDepthProfile {
  const _SceneDepthProfile({
    required this.skyTop,
    required this.skyMid,
    required this.mountainColor,
    required this.mistColor,
    required this.groundColor,
    required this.glowColor,
    required this.glowCenter,
    required this.glowRadius,
    required this.mountainAlpha,
    required this.mistAlpha,
    required this.groundAlpha,
    required this.glowAlpha,
    required this.vignetteAlpha,
  });

  final Color skyTop;
  final Color skyMid;
  final Color mountainColor;
  final Color mistColor;
  final Color groundColor;
  final Color glowColor;
  final Alignment glowCenter;
  final double glowRadius;
  final double mountainAlpha;
  final double mistAlpha;
  final double groundAlpha;
  final double glowAlpha;
  final double vignetteAlpha;

  static _SceneDepthProfile resolve({
    required String? path,
    required BattleSceneBackgroundStyle style,
  }) {
    final resolvedStyle = style == BattleSceneBackgroundStyle.generic
        ? _styleFromPath(path)
        : style;
    switch (resolvedStyle) {
      case BattleSceneBackgroundStyle.tower:
        return const _SceneDepthProfile(
          skyTop: Color(0xFF151A22),
          skyMid: Color(0xFF202536),
          mountainColor: WuxiaColors.yinRou,
          mistColor: WuxiaColors.textMuted,
          groundColor: WuxiaColors.panel,
          glowColor: WuxiaColors.yinRou,
          glowCenter: Alignment(0.0, -0.35),
          glowRadius: 1.22,
          mountainAlpha: 0.18,
          mistAlpha: 0.22,
          groundAlpha: 0.22,
          glowAlpha: 0.12,
          vignetteAlpha: 0.36,
        );
      case BattleSceneBackgroundStyle.innerDemon:
        return const _SceneDepthProfile(
          skyTop: Color(0xFF120F18),
          skyMid: Color(0xFF1D1A25),
          mountainColor: WuxiaColors.yinRou,
          mistColor: WuxiaColors.textMuted,
          groundColor: WuxiaColors.sidebar,
          glowColor: WuxiaColors.yinRou,
          glowCenter: Alignment(0.15, -0.18),
          glowRadius: 1.08,
          mountainAlpha: 0.12,
          mistAlpha: 0.3,
          groundAlpha: 0.18,
          glowAlpha: 0.16,
          vignetteAlpha: 0.44,
        );
      case BattleSceneBackgroundStyle.lightFoot:
        return const _SceneDepthProfile(
          skyTop: Color(0xFF121C20),
          skyMid: Color(0xFF1B2B2F),
          mountainColor: WuxiaColors.internalForce,
          mistColor: WuxiaColors.textSecondary,
          groundColor: WuxiaColors.internalForce,
          glowColor: WuxiaColors.internalForce,
          glowCenter: Alignment(-0.35, -0.12),
          glowRadius: 1.3,
          mountainAlpha: 0.16,
          mistAlpha: 0.26,
          groundAlpha: 0.2,
          glowAlpha: 0.14,
          vignetteAlpha: 0.3,
        );
      case BattleSceneBackgroundStyle.massBattle:
        return const _SceneDepthProfile(
          skyTop: Color(0xFF181715),
          skyMid: Color(0xFF28241E),
          mountainColor: WuxiaColors.gangMeng,
          mistColor: WuxiaColors.textMuted,
          groundColor: WuxiaColors.gangMeng,
          glowColor: WuxiaColors.resultHighlight,
          glowCenter: Alignment(0.42, -0.08),
          glowRadius: 1.2,
          mountainAlpha: 0.14,
          mistAlpha: 0.2,
          groundAlpha: 0.22,
          glowAlpha: 0.11,
          vignetteAlpha: 0.38,
        );
      case BattleSceneBackgroundStyle.boss:
        return const _SceneDepthProfile(
          skyTop: Color(0xFF171315),
          skyMid: Color(0xFF261B1B),
          mountainColor: WuxiaColors.gangMeng,
          mistColor: WuxiaColors.textMuted,
          groundColor: WuxiaColors.sealCrimson,
          glowColor: WuxiaColors.gangMeng,
          glowCenter: Alignment(0.0, -0.2),
          glowRadius: 1.16,
          mountainAlpha: 0.2,
          mistAlpha: 0.18,
          groundAlpha: 0.22,
          glowAlpha: 0.13,
          vignetteAlpha: 0.42,
        );
      case BattleSceneBackgroundStyle.mainline:
      case BattleSceneBackgroundStyle.generic:
        return const _SceneDepthProfile(
          skyTop: Color(0xFF151B1D),
          skyMid: Color(0xFF1F2827),
          mountainColor: WuxiaColors.internalForce,
          mistColor: WuxiaColors.textMuted,
          groundColor: WuxiaColors.border,
          glowColor: WuxiaColors.resultHighlight,
          glowCenter: Alignment(0.32, -0.28),
          glowRadius: 1.26,
          mountainAlpha: 0.16,
          mistAlpha: 0.22,
          groundAlpha: 0.2,
          glowAlpha: 0.09,
          vignetteAlpha: 0.34,
        );
    }
  }

  static BattleSceneBackgroundStyle _styleFromPath(String? path) {
    final p = path ?? '';
    if (p.contains('innerrealm')) return BattleSceneBackgroundStyle.tower;
    if (p.contains('dock') || p.contains('waterfall') || p.contains('bamboo')) {
      return BattleSceneBackgroundStyle.lightFoot;
    }
    if (p.contains('frontier') ||
        p.contains('citywall') ||
        p.contains('drillground')) {
      return BattleSceneBackgroundStyle.massBattle;
    }
    return BattleSceneBackgroundStyle.mainline;
  }
}

class _DistantMountainPainter extends CustomPainter {
  const _DistantMountainPainter(this.profile);

  final _SceneDepthProfile profile;

  @override
  void paint(Canvas canvas, Size size) {
    final far = Paint()
      ..color = profile.mountainColor.withValues(
        alpha: profile.mountainAlpha * 0.46,
      );
    final mid = Paint()
      ..color = profile.mountainColor.withValues(
        alpha: profile.mountainAlpha * 0.72,
      );
    final near = Paint()
      ..color = profile.mountainColor.withValues(alpha: profile.mountainAlpha);

    canvas.drawPath(_ridge(size, 0.28, 0.09, 0.84), far);
    canvas.drawPath(_ridge(size, 0.36, 0.14, 0.88), mid);
    canvas.drawPath(_ridge(size, 0.46, 0.2, 0.92), near);
  }

  Path _ridge(Size size, double y, double lift, double floorY) {
    return Path()
      ..moveTo(0, size.height * floorY)
      ..lineTo(0, size.height * y)
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * (y - lift),
        size.width * 0.34,
        size.height * (y + lift * 0.22),
      )
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * (y - lift * 0.86),
        size.width * 0.72,
        size.height * (y + lift * 0.14),
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * (y - lift * 0.54),
        size.width,
        size.height * (y + lift * 0.2),
      )
      ..lineTo(size.width, size.height * floorY)
      ..close();
  }

  @override
  bool shouldRepaint(covariant _DistantMountainPainter oldDelegate) =>
      oldDelegate.profile != profile;
}

class _MistLayerPainter extends CustomPainter {
  const _MistLayerPainter(this.profile);

  final _SceneDepthProfile profile;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = profile.mistColor.withValues(alpha: profile.mistAlpha);

    canvas.drawOval(
      Rect.fromLTWH(
        -size.width * 0.12,
        size.height * 0.18,
        size.width * 0.7,
        size.height * 0.14,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.28,
        size.width * 0.9,
        size.height * 0.12,
      ),
      paint
        ..color = profile.mistColor.withValues(alpha: profile.mistAlpha * 0.7),
    );
    canvas.drawOval(
      Rect.fromLTWH(
        -size.width * 0.08,
        size.height * 0.52,
        size.width * 1.16,
        size.height * 0.16,
      ),
      paint
        ..color = profile.mistColor.withValues(alpha: profile.mistAlpha * 0.54),
    );
  }

  @override
  bool shouldRepaint(covariant _MistLayerPainter oldDelegate) =>
      oldDelegate.profile != profile;
}

class _GroundTexturePainter extends CustomPainter {
  const _GroundTexturePainter(this.profile);

  final _SceneDepthProfile profile;

  @override
  void paint(Canvas canvas, Size size) {
    final groundTop = size.height * 0.68;
    final groundRect = Rect.fromLTWH(
      0,
      groundTop,
      size.width,
      size.height - groundTop,
    );
    final groundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          profile.groundColor.withValues(alpha: profile.groundAlpha * 0.36),
          profile.groundColor.withValues(alpha: profile.groundAlpha),
        ],
      ).createShader(groundRect);
    canvas.drawRect(groundRect, groundPaint);

    final linePaint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..color = profile.mistColor.withValues(alpha: profile.groundAlpha * 0.36);
    for (var i = 0; i < 9; i++) {
      final y = groundTop + size.height * (0.025 + i * 0.034);
      final start = Offset(size.width * ((i % 3) - 1) * 0.12, y);
      final end = Offset(size.width * (1.08 - (i % 2) * 0.1), y + i * 1.4);
      canvas.drawLine(start, end, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GroundTexturePainter oldDelegate) =>
      oldDelegate.profile != profile;
}
