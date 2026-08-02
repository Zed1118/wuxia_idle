import 'package:flutter/material.dart';

import '../../../../shared/theme/wuxia_tokens.dart';
import '../battle_layout_tokens.dart';
import '../battle_typography_tokens.dart';

enum BattleSkillSlipVisualState {
  empty,
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

/// 冷却拍数的淡墨批注牌。
///
/// 它刻意不是圆环、徽章或第二枚朱印：不规则纸痕只负责给剩余拍数一个
/// 视觉落点，层级低于招名与流派印，避免数字像临时浮在签面上。
class BattleSkillCooldownMark extends StatelessWidget {
  const BattleSkillCooldownMark({
    super.key,
    required this.count,
    required this.width,
    required this.height,
    required this.fontSize,
  });

  final int count;
  final double width;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: CustomPaint(
      key: const ValueKey('battle.skillSlipCooldownMarkPaper'),
      painter: const _BattleSkillCooldownMarkPainter(),
      child: Center(
        child: Text(
          '$count',
          key: const ValueKey('battle.skillSlipCooldownCount'),
          style: TextStyle(
            color: const Color(0xFFE0D0AE),
            fontFamily: BattleTypography.displayFamily,
            fontFamilyFallback: BattleTypography.displayFallback,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: 1,
            fontFeatures: BattleTypography.tabularFigures,
            shadows: const [
              Shadow(
                color: Color(0x66302820),
                blurRadius: 1,
                offset: Offset(0.5, 0.5),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BattleSkillCooldownMarkPainter extends CustomPainter {
  const _BattleSkillCooldownMarkPainter();

  Path _paperPath(Size size, {Offset offset = Offset.zero}) {
    final left = offset.dx;
    final top = offset.dy;
    final right = left + size.width;
    final bottom = top + size.height;
    return Path()
      ..moveTo(left + 2, top + 3)
      ..lineTo(left + size.width * 0.38, top + 1)
      ..lineTo(right - 2, top + 2.5)
      ..lineTo(right - 1, top + size.height * 0.42)
      ..lineTo(right - 2.5, bottom - 1.5)
      ..lineTo(left + size.width * 0.55, bottom - 2.5)
      ..lineTo(left + 1, bottom - 1)
      ..lineTo(left + 2.5, top + size.height * 0.58)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = _paperPath(size, offset: const Offset(1, 1));
    canvas.drawPath(shadow, Paint()..color = const Color(0x3D171411));

    final paper = _paperPath(size);
    canvas.drawPath(paper, Paint()..color = const Color(0xB33B342C));
    canvas.drawPath(
      paper,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0x8F79684F),
    );

    final brush = Paint()
      ..color = const Color(0x304F4335)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.30),
      Offset(size.width * 0.78, size.height * 0.24),
      brush,
    );
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.74),
      Offset(size.width * 0.72, size.height * 0.79),
      brush,
    );
  }

  @override
  bool shouldRepaint(covariant _BattleSkillCooldownMarkPainter oldDelegate) =>
      false;
}

Path battleSkillSlipPaperPath(Rect rect) {
  final left = rect.left;
  final top = rect.top;
  final right = rect.right;
  final bottom = rect.bottom;
  return Path()
    ..moveTo(left + 0.5, top + 6)
    ..lineTo(left + 3, top + 1.5)
    ..lineTo(left + rect.width * 0.27, top + 0.5)
    ..lineTo(left + rect.width * 0.55, top + 2.2)
    ..lineTo(right - 5, top + 0.8)
    ..lineTo(right - 0.5, top + 6)
    ..lineTo(right - 2.4, top + rect.height * 0.22)
    ..lineTo(right - 0.5, top + rect.height * 0.43)
    ..lineTo(right - 2.2, top + rect.height * 0.68)
    ..lineTo(right - 0.5, bottom - 7)
    ..lineTo(right - 5, bottom - 0.8)
    ..lineTo(left + rect.width * 0.68, bottom - 0.5)
    ..lineTo(left + rect.width * 0.44, bottom - 2.2)
    ..lineTo(left + 5, bottom - 0.5)
    ..lineTo(left + 0.5, bottom - 6)
    ..lineTo(left + 2.4, top + rect.height * 0.72)
    ..lineTo(left + 0.5, top + rect.height * 0.48)
    ..lineTo(left + 2.3, top + rect.height * 0.21)
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
    this.activeTrace = false,
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
  final bool activeTrace;

  @override
  Widget build(BuildContext context) {
    final style = BattleDeskResponsiveStyle.fromSlipHeight(height);
    final cooldownWashWidth = (height * 0.18).clamp(24.0, 38.0);
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
        if (visualState == BattleSkillSlipVisualState.interrupt)
          const Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                key: ValueKey('battle.skillSlipSelectedWash'),
                color: Color(0x1AFFECD0),
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
          Positioned(
            top: style.value(8, 10),
            right: 3,
            width: cooldownWashWidth,
            height: style.value(64, 86),
            child: const IgnorePointer(
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
        highlighted:
            activeTrace || visualState == BattleSkillSlipVisualState.interrupt,
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
            offset: Offset.zero,
            child: slip,
          )
        : slip;
    final traced = activeTrace
        ? KeyedSubtree(
            key: const ValueKey('battle.skillSlip.autoActiveTrace'),
            child: staged,
          )
        : staged;
    return KeyedSubtree(
      key: ValueKey('battle.skillSlip.state.${visualState.name}'),
      child: traced,
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
          ..color = accent.withValues(alpha: 0.62)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFF3D38B).withValues(alpha: 0.58)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFE4BF72).withValues(alpha: 0.88)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      final spark = Paint()
        ..color = const Color(0xFFF2CC79).withValues(alpha: 0.92)
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 24; i++) {
        final onVertical = i.isEven;
        final x = onVertical
            ? (i % 4 == 0 ? 1.0 : size.width - 1.0)
            : 3.0 + ((i * 17) % 83) / 83 * (size.width - 6);
        final y = onVertical
            ? 4.0 + ((i * 23) % 97) / 97 * (size.height - 8)
            : (i % 4 == 1 ? 1.0 : size.height - 1.0);
        canvas.drawCircle(Offset(x, y), i % 5 == 0 ? 1.0 : 0.55, spark);
      }
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
    final washBounds = Rect.fromLTWH(
      -size.width * 0.30,
      size.height * 0.02,
      size.width * 1.42,
      size.height * 0.94,
    );
    canvas.drawOval(
      washBounds,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0.32, -0.10),
          radius: 0.92,
          colors: [
            Color(0xB8443C33),
            Color(0x71362F28),
            Color(0x2E29241F),
            Color(0x0029241F),
          ],
          stops: [0, 0.36, 0.72, 1],
        ).createShader(washBounds)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2),
    );

    final feather = Paint()
      ..color = const Color(0xFF29241E).withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
    for (var i = 0; i < 6; i++) {
      final y = size.height * (0.14 + i * 0.12);
      canvas.drawPath(
        Path()
          ..moveTo(size.width * (0.12 + (i % 2) * 0.10), y)
          ..quadraticBezierTo(
            size.width * 0.50,
            y + (i.isEven ? 3 : -2),
            size.width * (0.88 - (i % 3) * 0.06),
            y + 1,
          ),
        feather..strokeWidth = 2.8 - i * 0.20,
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
    final y = size.height - 9.5;
    final dryQing = Paint()
      ..color = const Color(0xFF486B68).withValues(alpha: 0.52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(8, y + 0.8)
        ..lineTo(size.width * 0.19, y - 0.5)
        ..lineTo(size.width * 0.37, y + 0.4),
      dryQing,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.58, y - 0.3)
        ..lineTo(size.width * 0.76, y + 0.7)
        ..lineTo(size.width - 8, y - 0.6),
      dryQing,
    );

    final brokenStroke = Paint()
      ..color = const Color(0xFF486B68).withValues(alpha: 0.30)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final leftHalf = i < 4;
      final x = leftHalf
          ? 10 + i * size.width * 0.075
          : size.width * 0.60 + (i - 4) * size.width * 0.08;
      canvas.drawLine(
        Offset(x, y - 2 + (i % 3)),
        Offset(x + 4 + (i % 2) * 3, y - 1 + ((i + 1) % 3)),
        brokenStroke..strokeWidth = 0.45 + (i % 3) * 0.25,
      );
    }

    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.43, y - 3)
        ..lineTo(size.width * 0.49, y + 1.5)
        ..lineTo(size.width * 0.54, y - 1.5),
      dryQing
        ..color = const Color(0xFF486B68).withValues(alpha: 0.34)
        ..strokeWidth = 0.9,
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
        ..color = const Color(0xFF33281F).withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.7),
    );
    canvas.drawPath(
      roughEdge,
      Paint()
        ..color = const Color(0xFF403126).withValues(alpha: 0.76)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.35,
    );

    final ink = Paint()
      ..color = const Color(0xFF59452F).withValues(alpha: 0.48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.85;
    canvas.drawPath(
      battleSkillSlipPaperPath(
        Rect.fromLTWH(3.5, 3.5, size.width - 7, size.height - 7),
      ),
      ink,
    );

    final accentPaint = Paint()
      ..color = accent.withValues(alpha: 0.58)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      const Offset(4.5, 7),
      Offset(4.5, size.height - 7),
      accentPaint,
    );

    final fiber = Paint()
      ..color = const Color(0xFF5D4D38).withValues(alpha: 0.085)
      ..strokeWidth = 0.48
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 24; i++) {
      final y = 9.0 + ((i * 37) % 101) / 101 * (size.height - 18);
      final start = 6.0 + ((i * 23) % 61) / 61 * size.width * 0.55;
      final length = size.width * (0.10 + (i % 5) * 0.045);
      canvas.drawLine(
        Offset(start, y),
        Offset(
          (start + length).clamp(0, size.width - 5),
          y + (i.isEven ? 0.8 : -0.6),
        ),
        fiber,
      );
    }

    final fleck = Paint()
      ..color = const Color(0xFF4C3F30).withValues(alpha: 0.19)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 108; i++) {
      final x = 5.0 + ((i * 29) % 83) / 83 * (size.width - 10);
      final y = 7.0 + ((i * 47) % 97) / 97 * (size.height - 14);
      canvas.drawCircle(
        Offset(x, y),
        i % 7 == 0 ? 0.8 : (i % 3 == 0 ? 0.5 : 0.32),
        fleck,
      );
    }

    final mottle = Paint()
      ..color = const Color(0xFF66533D).withValues(alpha: 0.09)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    final paleMottle = Paint()
      ..color = const Color(0xFFF1DEC0).withValues(alpha: 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    for (var i = 0; i < 18; i++) {
      final x = 10.0 + ((i * 31) % 73) / 73 * (size.width - 20);
      final y = 12.0 + ((i * 43) % 89) / 89 * (size.height - 24);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 12 + (i % 3) * 7,
          height: 7 + (i % 4) * 4,
        ),
        i.isEven ? mottle : paleMottle,
      );
    }

    final edgeGrime = Paint()
      ..color = const Color(0xFF3A2D22).withValues(alpha: 0.16)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 11; i++) {
      final x = 5.0 + i * ((size.width - 10) / 10);
      final y = i.isEven ? 3.4 : size.height - 3.2;
      canvas.drawLine(
        Offset(x - 2.5, y),
        Offset(x + 2 + (i % 3), y + (i.isEven ? 0.7 : -0.6)),
        edgeGrime,
      );
    }

    final edgeNick = Paint()
      ..color = const Color(0xFF32261D).withValues(alpha: 0.40)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i++) {
      final y = 8.0 + i * ((size.height - 16) / 17);
      final leftLength = 1.8 + (i % 4) * 0.8;
      final rightLength = 1.4 + ((i + 2) % 4) * 0.75;
      canvas.drawLine(
        Offset(1.2, y),
        Offset(1.2 + leftLength, y + (i.isEven ? 0.7 : -0.5)),
        edgeNick,
      );
      canvas.drawLine(
        Offset(size.width - 1.2, y + 1),
        Offset(size.width - 1.2 - rightLength, y + (i.isEven ? 0.4 : 1.6)),
        edgeNick,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BattleSkillSlipFramePainter oldDelegate) =>
      oldDelegate.accent != accent;
}
