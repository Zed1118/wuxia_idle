import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/wuxia_tokens.dart';
import 'phase0a_presentation_tokens.dart';

/// A distant battle line, with no actor, input, RNG or simulation ownership.
/// The battle screen supplies its existing, pausable presentation clock.
final class Phase0aBackgroundCrowds extends StatelessWidget {
  const Phase0aBackgroundCrowds({
    super.key,
    required this.cameraOffset,
    required this.phase,
  });

  final Offset cameraOffset;
  final ValueListenable<double> phase;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          key: const ValueKey('phase0a_background_crowd_paint'),
          painter: _BackgroundCrowdPainter(
            cameraOffset: cameraOffset,
            phase: phase,
          ),
        ),
      ),
    ),
  );
}

final class _BackgroundCrowdPainter extends CustomPainter {
  _BackgroundCrowdPainter({required this.cameraOffset, required this.phase})
    : super(repaint: phase);

  final Offset cameraOffset;
  final ValueListenable<double> phase;

  // Shared normalized ink shapes: no textures or per-figure animation objects.
  static final _coat = Path()
    ..moveTo(-2.2, -26)
    ..quadraticBezierTo(-6, -25, -8, -19)
    ..lineTo(-10, -12)
    ..lineTo(-7, -11)
    ..lineTo(-4, -18)
    ..lineTo(-5, -10)
    ..lineTo(-8, -2)
    ..lineTo(-3, -3)
    ..lineTo(-3, 0)
    ..lineTo(0, 0)
    ..lineTo(1, -7)
    ..lineTo(4, -1)
    ..lineTo(7, 0)
    ..lineTo(5, -5)
    ..lineTo(7, -4)
    ..lineTo(4, -14)
    ..lineTo(4, -20)
    ..lineTo(8, -16)
    ..lineTo(11, -18)
    ..lineTo(5, -25)
    ..close();

  static final _hood = Path()
    ..moveTo(-4, -29)
    ..quadraticBezierTo(-2, -34, 1, -33)
    ..quadraticBezierTo(4, -32, 4, -29)
    ..lineTo(6, -28)
    ..lineTo(-5, -28)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final scale = (size.width / Phase0aPresentationTokens.crowdReferenceWidth)
        .clamp(
          Phase0aPresentationTokens.crowdMinScale,
          Phase0aPresentationTokens.crowdMaxScale,
        );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(
      -cameraOffset.dx * Phase0aPresentationTokens.crowdParallaxFactor,
      -cameraOffset.dy * Phase0aPresentationTokens.crowdParallaxFactor,
    );
    _rank(
      canvas,
      size,
      count: Phase0aPresentationTokens.crowdFarFigures,
      baseline: Phase0aPresentationTokens.crowdFarBaseline,
      scale: scale * Phase0aPresentationTokens.crowdFarScale,
      opacity: Phase0aPresentationTokens.crowdFarOpacity,
      offset: 0,
    );
    _rank(
      canvas,
      size,
      count: Phase0aPresentationTokens.crowdNearFigures,
      baseline: Phase0aPresentationTokens.crowdNearBaseline,
      scale: scale,
      opacity: Phase0aPresentationTokens.crowdNearOpacity,
      offset: Phase0aPresentationTokens.crowdFarFigures,
    );
    canvas.restore();
  }

  void _rank(
    Canvas canvas,
    Size size, {
    required int count,
    required double baseline,
    required double scale,
    required double opacity,
    required int offset,
  }) {
    final ink = Paint()..color = WuxiaUi.ink.withValues(alpha: opacity);
    final weapon = Paint()
      ..color = ink.color
      ..strokeWidth = Phase0aPresentationTokens.crowdWeaponStroke
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < count; index++) {
      final slot = index ~/ 2;
      final side = index.isEven ? -1 : 1;
      final lateral =
          Phase0aPresentationTokens.crowdInnerInset +
          slot / (count / 2 - 1) * Phase0aPresentationTokens.crowdBandWidth;
      final identity = index + offset;
      final sway = math.sin(phase.value * math.pi * 2 + identity * 0.73);
      final heightVariation = 1 + (identity % 5 - 2) * 0.045;
      final y = size.height * baseline + (identity % 3 - 1) * 3 * scale;
      canvas.save();
      canvas.translate(size.width * (0.5 + side * lateral), y);
      canvas.scale(scale * side * heightVariation, scale * heightVariation);
      canvas.skew(sway * Phase0aPresentationTokens.crowdSwaySkew, 0);
      canvas.drawPath(_coat, ink);
      canvas.drawOval(const Rect.fromLTWH(-2.8, -30, 5.4, 6), ink);
      canvas.drawPath(_hood, ink);
      final banner = identity % Phase0aPresentationTokens.crowdBannerEvery == 0;
      final top = banner ? -50.0 : -41.0;
      canvas.drawLine(const Offset(9, -1), Offset(11, top), weapon);
      if (banner) {
        final flutter = sway * Phase0aPresentationTokens.crowdFlagFlutter;
        final flag = Path()
          ..moveTo(11, top)
          ..quadraticBezierTo(18, top - 2 + flutter, 25, top + 2)
          ..lineTo(22, top + 7)
          ..lineTo(26, top + 12)
          ..quadraticBezierTo(18, top + 8 + flutter, 11, top + 10)
          ..close();
        canvas.drawPath(flag, ink);
      } else {
        canvas.drawLine(Offset(11, top), Offset(9, top + 5), weapon);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundCrowdPainter oldDelegate) =>
      oldDelegate.cameraOffset != cameraOffset || oldDelegate.phase != phase;
}
