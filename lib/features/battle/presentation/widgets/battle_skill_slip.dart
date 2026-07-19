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
  });

  final double height;
  final double tiltAngle;
  final Color backgroundColor;
  final Color foregroundColor;
  final BorderSide border;
  final Color accent;
  final BattleSkillSlipVisualState visualState;
  final VoidCallback? onPressed;
  final VoidCallback onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final slip = Transform.rotate(
      key: const ValueKey('battle.skillSlipNaturalTilt'),
      angle: tiltAngle,
      child: SizedBox(
        height: height,
        child: ElevatedButton(
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
            shape: const BeveledRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(3)),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.20,
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
                    child: DecoratedBox(
                      key: ValueKey('battle.skillSlip.inkCooldown'),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0x8A211D18),
                            Color(0x401B1814),
                            Colors.transparent,
                          ],
                          stops: [0, 0.58, 1],
                        ),
                      ),
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
          ),
        ),
      ),
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
    final roughEdge = Path()
      ..moveTo(3, 5)
      ..lineTo(size.width - 5, 2)
      ..lineTo(size.width - 2, size.height - 6)
      ..lineTo(size.width - 7, size.height - 2)
      ..lineTo(4, size.height - 4)
      ..lineTo(1.5, 8)
      ..close();
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
  }

  @override
  bool shouldRepaint(covariant _BattleSkillSlipFramePainter oldDelegate) =>
      oldDelegate.accent != accent;
}
