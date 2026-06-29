import 'package:flutter/material.dart';

import '../../theme/wuxia_tokens.dart';
import 'plaque_button.dart';

enum InkEmptyStateVariant { empty, locked, unavailable }

class InkEmptyState extends StatelessWidget {
  const InkEmptyState({
    super.key,
    required this.variant,
    required this.title,
    required this.body,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    this.showFrame = true,
  });

  final InkEmptyStateVariant variant;
  final String title;
  final String body;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;
  final bool showFrame;

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 34 : 42,
          height: compact ? 34 : 42,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: accent.withValues(alpha: 0.36)),
          ),
          child: Icon(_icon(), color: accent, size: compact ? 19 : 23),
        ),
        SizedBox(width: compact ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: compact ? 15 : 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: compact ? 1.2 : 1.8,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                body,
                maxLines: compact ? 2 : 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: WuxiaUi.ink2,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                SizedBox(height: compact ? 8 : 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PlaqueButton(label: actionLabel!, onTap: onAction),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (!showFrame) return content;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.paper.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: WuxiaUi.ink.withValues(alpha: 0.28),
          width: WuxiaUi.borderWidth,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 14),
        child: content,
      ),
    );
  }

  IconData _icon() {
    if (icon != null) return icon!;
    return switch (variant) {
      InkEmptyStateVariant.empty => Icons.inbox_outlined,
      InkEmptyStateVariant.locked => Icons.lock_outline,
      InkEmptyStateVariant.unavailable => Icons.hourglass_empty_outlined,
    };
  }

  Color _accentColor() {
    return switch (variant) {
      InkEmptyStateVariant.empty => WuxiaUi.qing,
      InkEmptyStateVariant.locked => WuxiaUi.jiang,
      InkEmptyStateVariant.unavailable => WuxiaUi.muted,
    };
  }
}
