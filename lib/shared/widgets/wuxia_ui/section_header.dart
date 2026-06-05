import 'package:flutter/material.dart';

import '../../theme/wuxia_tokens.dart';

/// 分区小标（UI kit · demo `.wx .shead`）：墨笔标题 + 底部枯笔分隔线。
///
/// 分隔线用 `ink_divider.png` 贴底（缺失走 errorBuilder shrink，退化为细墨线兜底）。
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: WuxiaUi.ink,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 6,
            child: Image.asset(
              WuxiaUi.inkDivider,
              fit: BoxFit.fill,
              errorBuilder: (_, _, _) => const DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: WuxiaUi.ink, width: 1),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
