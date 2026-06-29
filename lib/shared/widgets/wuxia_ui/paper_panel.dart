import 'package:flutter/material.dart';

import '../../theme/wuxia_tokens.dart';
import '../wuxia_image.dart';

/// 宣纸浅色面板（UI kit · demo `.wx .panel`）。
///
/// 纸色半透底 [WuxiaUi.panelFill] + 宣纸纹理 + 墨边圆角。区别于深色
/// `WuxiaPaperPanel`（战斗/心法面板）。纹理图缺失走 errorBuilder shrink，
/// 退化纯纸色不露空底（memory feedback_image_asset_error_builder）。
/// 用作滚动列 tile 时外层包 [IntrinsicHeight]（StackFit.expand 需有界高度，
/// memory feedback_wuxia_paper_panel_scroll_tile）。
class PaperPanel extends StatelessWidget {
  const PaperPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.paperOpacity = 0.18,
    this.showBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double paperOpacity;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: WuxiaUi.panelFill,
        borderRadius: BorderRadius.circular(WuxiaUi.radius),
        border: showBorder
            ? Border.all(color: WuxiaUi.ink, width: WuxiaUi.borderWidth)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WuxiaUi.radius),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: paperOpacity,
                child: WuxiaImage(
                  WuxiaUi.paperBg,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
