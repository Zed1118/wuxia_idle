import 'package:flutter/material.dart';
import 'package:wuxia_idle/shared/strings.dart';
import 'package:wuxia_idle/shared/theme/wuxia_tokens.dart';

/// 残页收集进度展示行（藏经阁主屏 · P1b Task7）。
///
/// 显示一本秘籍的名称、方块进度（实心 ▣ + 空心 ▢）和数字文案。
/// 无状态组件，由上层传入所有数据。
class FragmentProgressRow extends StatelessWidget {
  /// 秘籍名称。
  final String name;

  /// 当前已收集残页数。
  final int has;

  /// 解锁所需总残页数。
  final int total;

  const FragmentProgressRow({
    super.key,
    required this.name,
    required this.has,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final clampedHas = has.clamp(0, total);
    final blocks = StringBuffer();
    for (var i = 0; i < clampedHas; i++) {
      blocks.write('▣');
    }
    for (var i = clampedHas; i < total; i++) {
      blocks.write('▢');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // 秘籍名
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: WuxiaUi.ink,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // 方块进度
          Text(
            blocks.toString(),
            style: const TextStyle(
              color: WuxiaUi.qing,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: 8),
          // 数字文案
          Text(
            UiStrings.cangjingFragmentProgress(clampedHas, total),
            style: const TextStyle(color: WuxiaUi.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
