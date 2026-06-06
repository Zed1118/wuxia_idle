# 主菜单二次包装 · 三栏门面

日期：2026-06-06  
分支：`codex/t11-inventory-section-header`

## 结论

总判：PASS。

- 宽屏主菜单从三组纵向长列改为修行 / 演武 / 江湖三栏并排，首屏信息密度明显改善。
- 入口按钮从深色功能卡改为宣纸木牌质感：暖色牌面、纸纹叠层、墨色侧边、朱印角标。
- 窄屏仍保留原双列纵向布局，避免小窗口回归。
- 未见文字溢出或 RenderFlex overflow。

## 验证

- `flutter test test/shared/widgets/wuxia_ink_button_test.dart test/features/main_menu/presentation/main_menu_test.dart`
- `flutter analyze lib/features/main_menu/presentation/main_menu.dart lib/shared/widgets/wuxia_ink_button.dart test/shared/widgets/wuxia_ink_button_test.dart`
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=main_menu`

## 截图

- `docs/handoff/codex_main_menu_second_pass_2026-06-06/01_main_menu_three_columns.png`

## 备注

- 当前仍使用既有 `mountain_bg.png` 门面背景，未新增素材。
- debug build 仍显示调试组，符合当前开发验收入口需求。
