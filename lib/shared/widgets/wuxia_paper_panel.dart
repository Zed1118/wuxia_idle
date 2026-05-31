import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// 宣纸底面板（Phase B 出版美术 · 心法/秘籍面板「卷轴感」底层）。
///
/// 在 [child] 之下铺一层 `paper_bg.png` 宣纸纹理（[paperOpacity] 控浓淡），
/// 撑满父容器；可选墨边外框（[showBorder]，[WuxiaColors.inkPanelEdge]）。
/// 宣纸图缺失 / widget test 不加载 pubspec assets 时走 errorBuilder shrink，
/// 退化为暖宣纸兜底 [WuxiaColors.paperUnderlay]，不露冷黑空底
/// （memory feedback_image_asset_error_builder）。
///
/// 用法：包面板 body；内容通常自带 padding，故本组件 [padding] 默认 zero。
/// 体例承自 `equipment_detail_screen` 的 paper_bg 铺法 + `WuxiaInkButton` 墨边。
class WuxiaPaperPanel extends StatelessWidget {
  const WuxiaPaperPanel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.paperOpacity = 0.24,
    this.showBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// 宣纸纹理不透明度（默认 0.24，让暖宣纸在深色底上铺出出版感，不留深色空底）。
  final double paperOpacity;

  /// 是否画墨边外框（[WuxiaColors.inkPanelEdge]）。
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaColors.paperUnderlay,
        border: showBorder ? Border.all(color: WuxiaColors.inkPanelEdge) : null,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: paperOpacity,
              child: Image.asset(
                'assets/ui/paper_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
