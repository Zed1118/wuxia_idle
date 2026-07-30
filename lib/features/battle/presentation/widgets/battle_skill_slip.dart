import 'package:flutter/material.dart';

import '../../../../shared/theme/wuxia_tokens.dart';

enum BattleSkillSlipVisualState {
  available,
  cooldown,
  insufficientQi,
  pending,
  interrupt,
}

double battleSkillSlipTilt(String skillId) {
  final signature = skillId.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
  return switch (signature % 3) {
    0 => -0.010,
    1 => 0.0,
    _ => 0.010,
  };
}

Path battleSkillSlipPaperPath(Rect rect) {
  final left = rect.left;
  final top = rect.top;
  final right = rect.right;
  final bottom = rect.bottom;
  return Path()
    ..moveTo(left + 5, top + 2)
    ..lineTo(left + rect.width * 0.28, top + 1)
    ..lineTo(left + rect.width * 0.56, top + 3)
    ..lineTo(right - 6, top + 1)
    ..lineTo(right - 2, top + 7)
    ..lineTo(right - 4, top + rect.height * 0.22)
    ..lineTo(right - 1, top + rect.height * 0.42)
    ..lineTo(right - 3, top + rect.height * 0.67)
    ..lineTo(right - 1, bottom - 8)
    ..lineTo(right - 7, bottom - 2)
    ..lineTo(left + rect.width * 0.68, bottom - 1)
    ..lineTo(left + rect.width * 0.43, bottom - 3)
    ..lineTo(left + 7, bottom - 1)
    ..lineTo(left + 2, bottom - 7)
    ..lineTo(left + 4, top + rect.height * 0.72)
    ..lineTo(left + 1, top + rect.height * 0.48)
    ..lineTo(left + 3, top + rect.height * 0.21)
    ..close();
}

class BattleSkillSlipPaperClipper extends CustomClipper<Path> {
  const BattleSkillSlipPaperClipper();

  @override
  Path getClip(Size size) => battleSkillSlipPaperPath(Offset.zero & size);

  @override
  bool shouldReclip(covariant BattleSkillSlipPaperClipper oldClipper) => false;
}

class BattleSkillSlipShapeBorder extends OutlinedBorder {
  const BattleSkillSlipShapeBorder({super.side});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) =>
      BattleSkillSlipShapeBorder(side: side.scale(t));

  @override
  OutlinedBorder copyWith({BorderSide? side}) =>
      BattleSkillSlipShapeBorder(side: side ?? this.side);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      battleSkillSlipPaperPath(rect.deflate(side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      battleSkillSlipPaperPath(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(
      getOuterPath(rect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = side.width
        ..color = side.color,
    );
  }
}

/// 保留原生按钮的桌面交互语义，同时把外观收束成旧纸武学签。
class BattleSkillSlipSurface extends StatelessWidget {
  const BattleSkillSlipSurface({
    super.key,
    required this.height,
    required this.tiltAngle,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.border,
    required this.accent,
    required this.visualState,
    required this.onPressed,
    required this.onLongPress,
    required this.child,
    this.interactive = true,
  });

  final double height;
  final double tiltAngle;
  final Color backgroundColor;
  final Color foregroundColor;
  final BorderSide border;
  final Color accent;
  final BattleSkillSlipVisualState visualState;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final Widget child;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final contents = Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.40,
            child: Image.asset(
              WuxiaUi.paperBg,
              fit: BoxFit.cover,
              color: const Color(0xFF806C50),
              colorBlendMode: BlendMode.multiply,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              key: const ValueKey('battle.skillSlipRoughPaper'),
              painter: _BattleSkillSlipFramePainter(accent: accent),
            ),
          ),
        ),
        if (visualState == BattleSkillSlipVisualState.cooldown)
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                key: ValueKey('battle.skillSlip.inkCooldown'),
                painter: _BattleSkillCooldownWashPainter(),
              ),
            ),
          ),
        if (visualState == BattleSkillSlipVisualState.insufficientQi)
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                key: ValueKey('battle.skillSlip.qiGap'),
                painter: _BattleSkillQiGapPainter(),
              ),
            ),
          ),
        child,
      ],
    );
    final clippedContents = ClipPath(
      key: const ValueKey('battle.skillSlipTornPaperClip'),
      clipper: const BattleSkillSlipPaperClipper(),
      child: contents,
    );
    final surface = interactive
        ? ElevatedButton(
            onPressed: onPressed,
            onLongPress: onLongPress,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              disabledBackgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              padding: EdgeInsets.zero,
              side: border,
              elevation: 0,
              shadowColor: Colors.transparent,
              enabledMouseCursor: SystemMouseCursors.click,
              disabledMouseCursor: SystemMouseCursors.basic,
              shape: const BattleSkillSlipShapeBorder(),
            ),
            child: clippedContents,
          )
        : Material(
            color: backgroundColor,
            shape: BattleSkillSlipShapeBorder(side: border),
            clipBehavior: Clip.antiAlias,
            child: clippedContents,
          );
    final glowingSurface = CustomPaint(
      key: const ValueKey('battle.skillSlipOuterFinish'),
      painter: _BattleSkillSlipOuterFinishPainter(
        accent: accent,
        highlighted: visualState == BattleSkillSlipVisualState.interrupt,
      ),
      child: surface,
    );
    final slip = Transform.rotate(
      key: const ValueKey('battle.skillSlipNaturalTilt'),
      angle: tiltAngle,
      child: SizedBox(height: height, child: glowingSurface),
    );
    final staged = visualState == BattleSkillSlipVisualState.interrupt
        ? Transform.translate(
            key: const ValueKey('battle.skillSlip.interruptLift'),
            offset: const Offset(0, -3),
            child: slip,
          )
        : slip;
    return KeyedSubtree(
      key: ValueKey('battle.skillSlip.state.${visualState.name}'),
      child: staged,
    );
  }
}

class _BattleSkillSlipOuterFinishPainter extends CustomPainter {
  const _BattleSkillSlipOuterFinishPainter({
    required this.accent,
    required this.highlighted,
  });

  final Color accent;
  final bool highlighted;

  @override
  void paint(Canvas canvas, Size size) {
    final path = battleSkillSlipPaperPath(Offset.zero & size);
    if (highlighted) {
      canvas.drawPath(
        path,
        Paint()
          ..color = accent.withValues(alpha: 0.52)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFF3D38B).withValues(alpha: 0.52)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFE4BF72).withValues(alpha: 0.88)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _BattleSkillSlipOuterFinishPainter oldDelegate,
  ) => oldDelegate.accent != accent || oldDelegate.highlighted != highlighted;
}

class _BattleSkillCooldownWashPainter extends CustomPainter {
  const _BattleSkillCooldownWashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wash = Path()
      ..moveTo(size.width * 0.55, 2)
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.08,
        size.width * 0.69,
        size.height * 0.30,
      )
      ..quadraticBezierTo(
        size.width * 0.90,
        size.height * 0.46,
        size.width * 0.70,
        size.height * 0.70,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.87,
        size.width * 0.59,
        size.height - 3,
      )
      ..lineTo(size.width - 1, size.height - 2)
      ..lineTo(size.width - 1, 1)
      ..close();
    canvas.drawPath(
      wash,
      Paint()
        ..color = const Color(0xFF29241E).withValues(alpha: 0.52)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    for (var i = 0; i < 6; i++) {
      final x = size.width * (0.61 + i * 0.058);
      final dryBrush = Paint()
        ..color = const Color(
          0xFF211D18,
        ).withValues(alpha: 0.10 + (i.isEven ? 0.08 : 0))
        ..strokeWidth = 2.2 + (i % 3) * 1.4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
      canvas.drawLine(
        Offset(x, 9 + i * 5),
        Offset(x - 8 + (i % 2) * 5, size.height - 12 - i * 4),
        dryBrush,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BattleSkillCooldownWashPainter oldDelegate) =>
      false;
}

class _BattleSkillQiGapPainter extends CustomPainter {
  const _BattleSkillQiGapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF486B68).withValues(alpha: 0.78)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.square;
    final y = size.height - 9;
    canvas.drawLine(Offset(8, y), Offset(size.width * 0.38, y), paint);
    canvas.drawLine(
      Offset(size.width * 0.56, y),
      Offset(size.width - 8, y),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.42, y - 3),
      Offset(size.width * 0.52, y + 3),
      paint..color = paint.color.withValues(alpha: 0.44),
    );
  }

  @override
  bool shouldRepaint(covariant _BattleSkillQiGapPainter oldDelegate) => false;
}

/// 技能签内墨线；基础纸签形态与后续五态在此单点演进。
class BattleSkillSlipInkFrame extends StatelessWidget {
  const BattleSkillSlipInkFrame({super.key, required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BattleSkillSlipFramePainter(accent: accent));
  }
}

class _BattleSkillSlipFramePainter extends CustomPainter {
  const _BattleSkillSlipFramePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final roughEdge = battleSkillSlipPaperPath(Offset.zero & size);
    canvas.drawPath(
      roughEdge,
      Paint()
        ..color = const Color(0xFF4B3B2B).withValues(alpha: 0.48)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    final ink = Paint()
      ..color = const Color(0xFF5B4934).withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRect(
      Rect.fromLTWH(4.5, 4.5, size.width - 9, size.height - 9),
      ink,
    );

    final accentPaint = Paint()
      ..color = accent.withValues(alpha: 0.82)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      const Offset(4.5, 7),
      Offset(4.5, size.height - 7),
      accentPaint,
    );

    final corner = Paint()
      ..color = const Color(0xFF382E24).withValues(alpha: 0.54)
      ..strokeWidth = 1.1;
    canvas.drawLine(const Offset(9, 9), const Offset(20, 9), corner);
    canvas.drawLine(const Offset(9, 9), const Offset(9, 18), corner);
    canvas.drawLine(
      Offset(size.width - 9, size.height - 9),
      Offset(size.width - 20, size.height - 9),
      corner,
    );
    canvas.drawLine(
      Offset(size.width - 9, size.height - 9),
      Offset(size.width - 9, size.height - 18),
      corner,
    );

    final fiber = Paint()
      ..color = const Color(0xFF5D4D38).withValues(alpha: 0.12)
      ..strokeWidth = 0.55
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 14; i++) {
      final y = 13.0 + i * ((size.height - 26) / 14);
      final start = 8.0 + (i % 4) * 3.0;
      final length = size.width * (0.22 + (i % 3) * 0.09);
      canvas.drawLine(
        Offset(start, y),
        Offset(
          (start + length).clamp(0, size.width - 8),
          y + (i.isEven ? 1 : -1),
        ),
        fiber,
      );
    }

    final fleck = Paint()
      ..color = const Color(0xFF4C3F30).withValues(alpha: 0.17)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 36; i++) {
      final x = 8.0 + ((i * 29) % 83) / 83 * (size.width - 16);
      final y = 9.0 + ((i * 47) % 97) / 97 * (size.height - 18);
      canvas.drawCircle(Offset(x, y), i % 5 == 0 ? 0.6 : 0.325, fleck);
    }

    final mottle = Paint()
      ..color = const Color(0xFF66533D).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final paleMottle = Paint()
      ..color = const Color(0xFFF1DEC0).withValues(alpha: 0.055)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    for (var i = 0; i < 14; i++) {
      final x = 10.0 + ((i * 31) % 73) / 73 * (size.width - 20);
      final y = 12.0 + ((i * 43) % 89) / 89 * (size.height - 24);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 18 + (i % 3) * 9,
          height: 10 + (i % 4) * 6,
        ),
        i.isEven ? mottle : paleMottle,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BattleSkillSlipFramePainter oldDelegate) =>
      oldDelegate.accent != accent;
}
