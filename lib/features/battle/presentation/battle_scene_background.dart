import 'package:flutter/material.dart';

import '../../../shared/theme/colors.dart';

/// 战斗场景背景层(出版美术 B1):背景图 + scrim 压暗遮罩。
/// path 空 → SizedBox.shrink(降级到 battle_screen 兜底色)。
/// Image.asset 挂 errorBuilder(widget 测不加载 assets,守测不破)。
class BattleSceneBackground extends StatelessWidget {
  final String? path;
  const BattleSceneBackground({super.key, this.path});

  @override
  Widget build(BuildContext context) {
    final p = path;
    if (p == null || p.isEmpty) return const SizedBox.shrink();
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(p, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink()),
        const ColoredBox(color: WuxiaColors.battleSceneScrim),
      ],
    );
  }
}
