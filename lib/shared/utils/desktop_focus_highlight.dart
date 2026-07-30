import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// 桌面端可运行的目标平台(发布目标 Windows,开发/验收 macOS)。
const Set<TargetPlatform> _desktopPlatforms = <TargetPlatform>{
  TargetPlatform.windows,
  TargetPlatform.macOS,
  TargetPlatform.linux,
};

/// 桌面端把焦点高亮策略钉成 [FocusHighlightStrategy.alwaysTraditional]。
///
/// ## 为什么需要
///
/// Flutter 默认策略是 [FocusHighlightStrategy.automatic]:进程开局按 **touch**
/// 模式处理,直到出现第一次键盘/方向键交互才切成 traditional。在 touch 模式下
/// `FocusableActionDetector.onShowFocusHighlight` **不会回调 true**,于是
/// `autofocus: true` 的主按钮虽然确实持有键盘焦点,却**画不出焦点环** ——
/// 玩家在按第一个键之前看不出回车会落在哪。
///
/// 2026-07-30 桌面语义真机走查实录:`PlaqueButton` 的
/// `FocusableActionDetector(onShowFocusHighlight:)` + `if (_focused)` 金边环
/// 实现是对的(`plaque_button_focus_ring_test` 在 traditional 模式下逐条绿),
/// 但真机上确认弹窗按 Tab ×3 后内容区零像素变化 —— 差就差在这条策略。
///
/// 发布目标是 Windows,键盘玩家必须一眼看到落点,故桌面端不用 automatic。
///
/// ## 调用时机
///
/// 在 `main()` 里 `WidgetsFlutterBinding.ensureInitialized()` 之后立刻调用,
/// 早于 visual-route 短路 —— 否则验收路由拿不到同一套焦点表现,真机走查会
/// 复现不出生产行为。
///
/// [manager] 只为测试注入,生产留空走 [FocusManager.instance]。
void applyDesktopFocusHighlightStrategy({FocusManager? manager}) {
  if (kIsWeb || !_desktopPlatforms.contains(defaultTargetPlatform)) return;
  (manager ?? FocusManager.instance).highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
}
