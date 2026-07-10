import 'package:flutter/material.dart';

import '../../strings.dart';
import '../../theme/wuxia_tokens.dart';
import '../wuxia_image.dart';
import 'panel_surface.dart';
import 'wuxia_icon_button.dart';

/// 宣纸顶栏（UI kit · demo `.titlebar`）：替 Material AppBar。
///
/// 纸色渐变底 + 墨色底边 + 卷轴题字标题；[onBack] 非空显绛红返回钮，
/// [showSeal] 为真右侧贴朱印。实现 [PreferredSizeWidget] 可直接挂 Scaffold.appBar。
class WuxiaTitleBar extends StatelessWidget implements PreferredSizeWidget {
  const WuxiaTitleBar({
    super.key,
    required this.title,
    this.onBack,
    this.onHome,
    this.showHome = true,
    this.showSeal = true,
    this.titleStyle,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;

  /// 「回主菜单」动作。默认 `popUntil(isFirst)`(MainMenu 为栈底首路由);可覆盖。
  final VoidCallback? onHome;

  /// 是否显示「回主菜单」键。子屏默认开;主菜单本身不挂顶栏,无需关。
  final bool showHome;
  final bool showSeal;
  final TextStyle? titleStyle;

  /// 标题右侧的附加动作槽(位于「回主菜单」键左侧),用于注入页面级帮助入口
  /// (`ContextHelpButton`)等。保持本组件在 shared 层不依赖 features:由调用方注入。
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEFE3C7), Color(0xFFE0CEA6)],
        ),
        border: Border(bottom: BorderSide(color: WuxiaUi.ink, width: 2)),
      ),
      // 顶栏自带固定浅色纸渐变底（恒浅底），故 provide 自身 PanelSurface.light，
      // 标题读自身 surface → 恒深墨 ink，即便被放进深色面板也不随外层翻白
      // （同 error_fallback 模式）。用内层 Builder 拿到本 surface 的 context。
      child: PanelSurface.light(
        child: Builder(
          builder: (context) {
            final surface = PanelSurface.of(context);
            return Row(
              children: [
                if (onBack != null)
                  WuxiaIconButton(
                    icon: Icons.arrow_back,
                    tooltip: UiStrings.titleBarBack,
                    onPressed: onBack,
                  ),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: surface.primary,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                    ).merge(titleStyle),
                  ),
                ),
                if (trailing != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: trailing,
                  ),
                if (showHome)
                  WuxiaIconButton(
                    icon: Icons.home_outlined,
                    tooltip: UiStrings.titleBarHome,
                    onPressed:
                        onHome ??
                        () => Navigator.of(context).popUntil((r) => r.isFirst),
                  ),
                if (showSeal)
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: WuxiaImage(
                      WuxiaUi.sealRed,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
