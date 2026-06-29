import 'package:flutter/material.dart';

import '../../theme/wuxia_tokens.dart';
import '../wuxia_image.dart';

/// 朱印角标（UI kit · demo `.islot .enh`）：`seal_red.png` 朱印底 + 居中题字。
///
/// 用于强化 +N / 师承烙印 / tier 标记等小角标。朱印图缺失走 errorBuilder
/// 退化为绛红实心圆底，文字始终可读。
class SealBadge extends StatelessWidget {
  const SealBadge({
    super.key,
    required this.text,
    this.size = 24,
    this.fontSize = 10,
  });

  final String text;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: WuxiaImage(
              WuxiaUi.sealRed,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const DecoratedBox(
                decoration: BoxDecoration(
                  color: WuxiaUi.jiang,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Text(
            text,
            style: TextStyle(
              color: WuxiaUi.paper,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
