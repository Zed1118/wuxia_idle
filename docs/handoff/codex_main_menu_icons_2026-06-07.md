# 主菜单入口图标与场所感 polish

日期：2026-06-07  
分支：`codex/t11-inventory-section-header`

## 范围

本切片延续 `docs/UI_WORK_REMAINING_2026-06-06.md` 的 T8 主菜单入口体验优化，只做视觉包装：

- `WuxiaInkButton` 新增可选 `icon` 参数；未传入时保持原布局与行为。
- 主菜单 18 个入口传入语义图标，形成左侧入口识别牌。
- 保留原状态 chip、锁定态、透明度、导航目标和 provider 推导逻辑。

## 结论

总判：通过。1280x720 截图下主菜单三栏无 overflow；图标牌没有挤压标题、hint 或状态 chip；锁定入口仍清晰呈现灰显与锁印。

| 验收点 | 结果 | 说明 |
|---|---|---|
| 入口辨识度 | 通过 | 主线、角色、装备、心法、闭关、爬塔、师徒、百科等入口均有左侧图标牌。 |
| 状态 chip 保留 | 通过 | 主线 / 爬塔 / 装备 / 心法 / 闭关状态仍在标题行右侧显示。 |
| 锁定态不回归 | 通过 | 未开放入口仍灰显，右侧锁图标保留。 |
| 导航不变 | 通过 | `onTap` 目标未改，测试仍覆盖主要入口 push。 |
| 1280x720 无 overflow | 通过 | 正式截图未见 RenderFlex overflow 或文字重叠。 |

## 截图

- `docs/handoff/codex_main_menu_icons_2026-06-07/01_main_menu_icons_1280x720.png`

## 验证

```bash
flutter test test/shared/widgets/wuxia_ink_button_test.dart test/features/main_menu/presentation/main_menu_test.dart
flutter analyze lib/features/main_menu/presentation/main_menu.dart lib/shared/widgets/wuxia_ink_button.dart test/shared/widgets/wuxia_ink_button_test.dart test/features/main_menu/presentation/main_menu_test.dart
flutter build macos --debug --dart-define=VISUAL_ROUTE=main_menu
```

以上均通过。
