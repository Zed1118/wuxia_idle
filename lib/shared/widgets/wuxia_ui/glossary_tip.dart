import 'package:flutter/material.dart';

import '../../theme/wuxia_tokens.dart';

/// 术语释义气泡（M4 · 2026-06-14）。
///
/// §5.7 框架下「气泡 / 百科」而非教程弹窗：把 [child] 包进一个水墨样式的
/// [Tooltip]，桌面端鼠标悬停、触屏长按即弹出 [definition] 释义。纯展示，
/// 不引入任何 domain 依赖。
///
/// 与默认 Material 深灰 tooltip 不同，这里走宣纸黄底 + 墨字 + 描边，贴合
/// 项目水墨克制基调。
class GlossaryTip extends StatelessWidget {
  const GlossaryTip({
    super.key,
    required this.definition,
    required this.child,
    this.preferBelow = true,
  });

  /// 释义文案（调用方传入已格式化字符串，文案集中在 [UiStrings]）。
  final String definition;

  /// 被包裹的展示内容（通常是术语标签）。
  final Widget child;

  /// 气泡相对锚点偏好方向（默认下方；贴顶部的术语可传 false 改上方）。
  final bool preferBelow;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: definition,
      preferBelow: preferBelow,
      // 触屏长按即弹；桌面端 Tooltip 默认随鼠标悬停弹出。
      triggerMode: TooltipTriggerMode.longPress,
      waitDuration: const Duration(milliseconds: 300),
      showDuration: const Duration(seconds: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: WuxiaUi.paper2,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: WuxiaUi.ink.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: WuxiaUi.ink.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: WuxiaUi.ink,
        fontSize: 12.5,
        height: 1.4,
      ),
      child: child,
    );
  }
}

/// 带可发现性标记的术语标签：渲染 [label] 文字 + 柔灰上标 [marker]（「?」），
/// 整体包进 [GlossaryTip]。桌面端用户见到 [marker] 即知可悬停查看释义。
///
/// 标签字体走调用方 [style]（与所在卡片标题保持一致），[marker] 永远柔灰小字，
/// 不抢主文视觉。
class GlossaryLabel extends StatelessWidget {
  const GlossaryLabel({
    super.key,
    required this.label,
    required this.definition,
    this.style,
    this.markerColor,
    this.preferBelow = true,
  });

  /// 可发现性标记字符（柔灰上标），测试与调用方共用此常量。
  static const String marker = '?';

  final String label;
  final String definition;
  final TextStyle? style;
  final Color? markerColor;
  final bool preferBelow;

  @override
  Widget build(BuildContext context) {
    final markerSize = ((style?.fontSize ?? 14) * 0.6).clamp(9.0, 13.0);
    return GlossaryTip(
      definition: definition,
      preferBelow: preferBelow,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              label,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 2),
          Padding(
            // 上标式微抬，贴术语右上角。
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              marker,
              style: TextStyle(
                color: markerColor ?? WuxiaUi.muted,
                fontSize: markerSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
