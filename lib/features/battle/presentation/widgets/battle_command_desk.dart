import 'package:flutter/material.dart';

import '../../../../shared/theme/wuxia_tokens.dart';
import '../battle_layout_tokens.dart';

typedef BattleCommandDeskBuilder =
    Widget Function(BuildContext context, BattleLayoutMetrics metrics);

/// 武学案台的响应布局与墨案底座；交互编排由 [BottomBar] 保持。
class BattleCommandDeskSurface extends StatelessWidget {
  const BattleCommandDeskSurface({super.key, required this.builder});

  final BattleCommandDeskBuilder builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaSize = MediaQuery.sizeOf(context);
        final metrics = BattleLayoutMetrics.resolve(
          Size(constraints.maxWidth, mediaSize.height),
        );
        return Container(
          key: const ValueKey('battle_command_desk'),
          height: metrics.commandDeskHeight,
          padding: const EdgeInsets.fromLTRB(
            BattleLayoutTokens.commandDeskHorizontalPadding,
            BattleLayoutTokens.commandDeskVerticalPadding,
            BattleLayoutTokens.commandDeskRightPadding,
            BattleLayoutTokens.commandDeskVerticalPadding,
          ),
          decoration: const BoxDecoration(
            color: WuxiaUi.battleDeskBase,
            image: DecorationImage(
              image: AssetImage(WuxiaUi.paperBg),
              fit: BoxFit.cover,
              opacity: 0.04,
              colorFilter: ColorFilter.mode(
                WuxiaUi.battleDeskTextureTint,
                BlendMode.multiply,
              ),
            ),
            border: Border(
              top: BorderSide(color: Color(0xFF756047), width: 1.2),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black54, blurRadius: 18, spreadRadius: 3),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const IgnorePointer(
                child: CustomPaint(
                  key: ValueKey('battle.commandDeskMottle'),
                  painter: _BattleCommandDeskMottlePainter(),
                ),
              ),
              builder(context, metrics),
            ],
          ),
        );
      },
    );
  }
}

/// 样板案台不是纯色木板，而是低对比、低频率的灰墨旧化。
///
/// 使用确定性的斑驳位置，既保留水墨材质，也避免每帧随机纹理造成截图漂移。
class _BattleCommandDeskMottlePainter extends CustomPainter {
  const _BattleCommandDeskMottlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final darkMottle = Paint()
      ..color = const Color(0xFF101210).withValues(alpha: 0.105)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final lightMottle = Paint()
      ..color = const Color(0xFF777169).withValues(alpha: 0.040)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    for (var i = 0; i < 28; i++) {
      final x = ((i * 137 + 41) % 997) / 997 * size.width;
      final y = ((i * 83 + 17) % 389) / 389 * size.height;
      final width = 54.0 + (i % 5) * 27;
      final height = 18.0 + (i % 4) * 13;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: width, height: height),
        i.isEven ? darkMottle : lightMottle,
      );
    }

    final fiber = Paint()
      ..color = const Color(0xFFAEA69A).withValues(alpha: 0.052)
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 13; i++) {
      final y = 8.0 + i * ((size.height - 16) / 13);
      final start = ((i * 97) % 241) / 241 * size.width * 0.55;
      canvas.drawLine(
        Offset(start, y),
        Offset((start + size.width * (0.10 + (i % 4) * 0.035)), y + 1),
        fiber,
      );
    }

    final grain = Paint()
      ..color = const Color(0xFFB8B0A4).withValues(alpha: 0.065)
      ..strokeCap = StrokeCap.round;
    final darkGrain = Paint()
      ..color = const Color(0xFF080A09).withValues(alpha: 0.11)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 180; i++) {
      final x = ((i * 149 + 31) % 1151) / 1151 * size.width;
      final y = ((i * 71 + 19) % 431) / 431 * size.height;
      canvas.drawCircle(
        Offset(x, y),
        i % 11 == 0 ? 1.0 : 0.52,
        i.isEven ? grain : darkGrain,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BattleCommandDeskMottlePainter oldDelegate) =>
      false;
}
