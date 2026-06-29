import 'package:flutter/material.dart';

import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_image.dart';

/// 剧情阅读场景背景层(出版美术):背景图 + scrim 压暗遮罩。
/// path 空/缺图 → SizedBox.shrink(降级到 reader 纯色底兜底)。
/// Image.asset 挂 errorBuilder(widget 测不加载 assets,守测不破)。
class NarrativeSceneBackground extends StatelessWidget {
  final String? path;
  const NarrativeSceneBackground({super.key, this.path});

  @override
  Widget build(BuildContext context) {
    final p = path;
    if (p == null || p.isEmpty) return const SizedBox.shrink();
    return Stack(
      fit: StackFit.expand,
      children: [
        WuxiaImage(p, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink()),
        const ColoredBox(color: WuxiaColors.narrativeSceneScrim),
      ],
    );
  }
}
