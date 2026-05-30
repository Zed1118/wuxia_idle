import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// 水墨入口按钮（Phase A 出版美术 · 从 `main_menu` 的 `_MenuButton` 抽出共用）。
///
/// 行为与原 `_MenuButton` 等价：panel 底 + border + 标题 + hint 双行；
/// `disabled` 时半透明（0.4）且拦截点击。`locked` 为真时在右侧显锁印图标
/// （§5.7 未解锁系统克制提示），通常与 `disabled` 同时为真。
/// 视觉精修（木牌/卷轴质感）留后续迭代（spec A5）。
class WuxiaInkButton extends StatelessWidget {
  const WuxiaInkButton({
    super.key,
    required this.label,
    required this.hint,
    required this.onTap,
    this.disabled = false,
    this.locked = false,
  });

  final String label;
  final String hint;
  final VoidCallback? onTap;
  final bool disabled;

  /// 锁态:右侧显锁印图标（§5.7 未解锁系统）。不影响点击/透明（由 [disabled] 控）。
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: WuxiaColors.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: WuxiaColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: WuxiaColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hint,
                      style: const TextStyle(
                        color: WuxiaColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (locked)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: WuxiaColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
