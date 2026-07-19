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
          padding: const EdgeInsets.symmetric(
            horizontal: BattleLayoutTokens.commandDeskHorizontalPadding,
            vertical: BattleLayoutTokens.commandDeskVerticalPadding,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF211D18),
            image: DecorationImage(
              image: AssetImage(WuxiaUi.paperBg),
              fit: BoxFit.cover,
              opacity: 0.12,
              colorFilter: ColorFilter.mode(
                Color(0xFF33291F),
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
          child: builder(context, metrics),
        );
      },
    );
  }
}
