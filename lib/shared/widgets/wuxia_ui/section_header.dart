import 'package:flutter/material.dart';

import '../../theme/wuxia_tokens.dart';

/// 分区小标（UI kit · demo `.wx .shead`）：墨笔标题 + 底部枯笔分隔线。
///
/// 分隔线用 `ink_divider.png` 贴底（缺失走 errorBuilder shrink，退化为细墨线兜底）。
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.dividerMaxWidth = 560,
    this.dividerOpacity = 0.68,
  });

  final String title;
  final double dividerMaxWidth;
  final double dividerOpacity;

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
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: dividerMaxWidth),
              child: SizedBox(
                width: double.infinity,
                height: 8,
                child: Opacity(
                  opacity: dividerOpacity,
                  child: Image.asset(
                    WuxiaUi.inkDivider,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, _, _) => const DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: WuxiaUi.ink, width: 1),
                        ),
                      ),
                    ),
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
