import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/utils/desktop_focus_highlight.dart';

/// 桌面端焦点高亮策略的守卫。
///
/// 立项背景(2026-07-30 桌面语义真机走查):默认 `automatic` 策略开局按 touch
/// 模式处理,`onShowFocusHighlight` 不回调 → `autofocus: true` 的确认弹窗主按钮
/// 持有焦点却画不出焦点环,玩家按回车前看不出落点。发布目标 Windows,
/// 键盘玩家必须看得见落点。
void main() {
  // FocusManager 构造要读 WidgetsBinding.instance,纯 test() 下 binding 未初始化。
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  for (final platform in const [
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  ]) {
    test('$platform:钉成 alwaysTraditional', () {
      debugDefaultTargetPlatformOverride = platform;
      final manager = FocusManager();
      addTearDown(manager.dispose);
      expect(
        manager.highlightStrategy,
        FocusHighlightStrategy.automatic,
        reason: 'Flutter 默认应是 automatic;若上游改了默认值,本测的前提要重估',
      );

      applyDesktopFocusHighlightStrategy(manager: manager);

      expect(
        manager.highlightStrategy,
        FocusHighlightStrategy.alwaysTraditional,
      );
    });
  }

  for (final platform in const [
    TargetPlatform.android,
    TargetPlatform.iOS,
    TargetPlatform.fuchsia,
  ]) {
    test('$platform:不动策略(触屏端不该常显焦点环)', () {
      debugDefaultTargetPlatformOverride = platform;
      final manager = FocusManager();
      addTearDown(manager.dispose);

      applyDesktopFocusHighlightStrategy(manager: manager);

      expect(manager.highlightStrategy, FocusHighlightStrategy.automatic);
    });
  }

  test('重复调用幂等', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final manager = FocusManager();
    addTearDown(manager.dispose);
    applyDesktopFocusHighlightStrategy(manager: manager);
    applyDesktopFocusHighlightStrategy(manager: manager);
    expect(manager.highlightStrategy, FocusHighlightStrategy.alwaysTraditional);
  });
}
