import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/wuxia_tokens.dart';
import '../domain/battle_state.dart';
import 'battle_typography_tokens.dart';

/// 人物名帖旁的蓄势小印。每个蓄势者都保留自己的拍数，与只选
/// 最近发动者的顶部横幅互补；不使用圆环，避免遮住头脸。
class BattleChargeSeal extends StatelessWidget {
  const BattleChargeSeal({super.key, required this.character, this.size = 20});

  final BattleCharacter character;
  final double size;

  @override
  Widget build(BuildContext context) {
    final skill = character.chargingSkill;
    if (skill == null) return const SizedBox.shrink();
    return Semantics(
      key: ValueKey('battle.chargeSeal.${character.characterId}'),
      container: true,
      label: UiStrings.battleDangerCharging(
        character.name,
        skill.name,
        character.chargeTicksRemaining,
      ),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          key: const ValueKey('battle.chargeSealInk'),
          painter: const BattleChargeSealPainter(),
          child: Center(
            child: Text(
              '${character.chargeTicksRemaining}',
              style: TextStyle(
                color: WuxiaUi.paper,
                fontFamily: BattleTypography.displayFamily,
                fontFamilyFallback: BattleTypography.displayFallback,
                fontSize: math.max(10, size * 0.58),
                fontWeight: FontWeight.w700,
                height: 1,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 1)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BattleChargeSealPainter extends CustomPainter {
  const BattleChargeSealPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.17)
      ..lineTo(size.width * 0.28, size.height * 0.06)
      ..lineTo(size.width * 0.61, size.height * 0.10)
      ..lineTo(size.width * 0.92, size.height * 0.20)
      ..lineTo(size.width * 0.88, size.height * 0.48)
      ..lineTo(size.width * 0.95, size.height * 0.78)
      ..lineTo(size.width * 0.70, size.height * 0.92)
      ..lineTo(size.width * 0.36, size.height * 0.88)
      ..lineTo(size.width * 0.10, size.height * 0.78)
      ..lineTo(size.width * 0.13, size.height * 0.51)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = WuxiaUi.jiang.withValues(alpha: 0.88),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = WuxiaUi.paper2.withValues(alpha: 0.64)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.7, size.shortestSide * 0.055)
        ..strokeJoin = StrokeJoin.bevel,
    );
    final dry = Paint()
      ..color = WuxiaUi.ink.withValues(alpha: 0.24)
      ..strokeWidth = math.max(0.45, size.shortestSide * 0.035)
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(size.width * 0.20, size.height * 0.29),
      Offset(size.width * 0.72, size.height * 0.23),
      dry,
    );
    canvas.drawLine(
      Offset(size.width * 0.26, size.height * 0.76),
      Offset(size.width * 0.82, size.height * 0.69),
      dry,
    );
  }

  @override
  bool shouldRepaint(covariant BattleChargeSealPainter oldDelegate) => false;
}
