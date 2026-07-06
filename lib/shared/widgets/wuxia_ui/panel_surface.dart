import 'package:flutter/widgets.dart';
import '../../theme/colors.dart';
import '../../theme/wuxia_tokens.dart';

/// 面板底色 → 文字色语义角色的向下供应。共享组件读 [of] 取正确文字色，
/// 深/浅由所在面板(DarkParchmentPanel/LightPaperPanel)自动决定，调用方无需传色。
class PanelSurface extends InheritedWidget {
  final Color primary;   // 标题/正文
  final Color secondary; // 次要/副描述/分隔线
  final Color accent;    // value 强调/下一阶

  const PanelSurface({
    super.key,
    required this.primary,
    required this.secondary,
    required this.accent,
    required super.child,
  });

  const PanelSurface.light({super.key, required super.child})
      : primary = WuxiaUi.ink,
        secondary = WuxiaUi.muted,
        accent = WuxiaUi.jiang;

  const PanelSurface.dark({super.key, required super.child})
      : primary = WuxiaColors.textPrimary,
        secondary = WuxiaColors.textSecondary,
        accent = WuxiaUi.gold;

  static const PanelSurface _fallback =
      PanelSurface.light(child: SizedBox.shrink());

  static PanelSurface of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PanelSurface>() ?? _fallback;

  static PanelSurface? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PanelSurface>();

  @override
  bool updateShouldNotify(PanelSurface old) =>
      primary != old.primary ||
      secondary != old.secondary ||
      accent != old.accent;
}
