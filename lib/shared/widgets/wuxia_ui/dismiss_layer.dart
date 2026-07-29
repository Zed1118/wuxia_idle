import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 整屏「点一下就跳过/关掉」的遮罩层——在点击之外补上键盘等价物。
///
/// 立项背景(2026-07-30 桌面语义专项量测):过场题字、英雄镜头、拜入浮层、
/// 闪屏、日志抽屉遮罩等 8 处整屏跳过器,此前一律只有裸 `GestureDetector.onTap`,
/// **零键盘处理**——发布目标是 Windows,只用键盘的玩家跳不过过场、关不掉抽屉。
///
/// 这类遮罩**不该**当按钮报给无障碍树(整屏报成 button 会污染语义),
/// 故本组件只补「键盘可达」这一维,不加 `Semantics(button: true)`、
/// 也不改鼠标光标(整屏区域给 click 光标同样是噪音)。真按钮请用
/// [PlaqueButton] / [WuxiaIconButton],那两个基元四项桌面语义齐全。
///
/// 用法:把原来的
/// ```dart
/// GestureDetector(behavior: HitTestBehavior.opaque, onTap: _finish, child: x)
/// ```
/// 换成
/// ```dart
/// DismissLayer(onDismiss: _finish, child: x)
/// ```
class DismissLayer extends StatelessWidget {
  const DismissLayer({
    super.key,
    required this.onDismiss,
    required this.child,
    this.autofocus = true,
    this.behavior = HitTestBehavior.opaque,
  });

  /// 点击或按下 [dismissKeys] 任一键时触发。
  final VoidCallback onDismiss;

  final Widget child;

  /// 是否自动抢焦点。整屏遮罩默认 true(它盖住了一切,本就该拿焦点);
  /// 嵌在别的可聚焦内容里时传 false,免抢走输入焦点。
  final bool autofocus;

  final HitTestBehavior behavior;

  /// 触发跳过的按键集合。
  ///
  /// Esc = 通用「关掉/退出」;Enter/空格 = 通用「确认/继续」。
  /// 三者都收,是因为玩家跳过过场时手会落在哪个键上并不确定。
  /// 注:不能写 `const Set` —— `LogicalKeyboardKey` 重写了 `==`/`hashCode`,
  /// const 集合元素不允许(analyzer const_set_element_not_primitive_equality)。
  static final Set<LogicalKeyboardKey> dismissKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.escape,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.space,
  };

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: autofocus,
      // 只吃 KeyDownEvent:KeyRepeatEvent 会让长按连发、KeyUpEvent 会让
      // 「在上一屏按下、本屏收到抬起」误触发。
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (!dismissKeys.contains(event.logicalKey)) {
          return KeyEventResult.ignored;
        }
        onDismiss();
        return KeyEventResult.handled;
      },
      child: GestureDetector(
        behavior: behavior,
        onTap: onDismiss,
        child: child,
      ),
    );
  }
}
