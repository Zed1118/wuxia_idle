# 仓库页布局重排 · 装备柜版本

日期：2026-06-06  
分支：`codex/t11-inventory-section-header`

## 结论

总判：PASS。

本次针对用户反馈「仓库界面不好看」做布局级重排：

- 顶栏从 Material `AppBar/TabBar` 改为 `WuxiaTitleBar + PlaqueTab`。
- 装备 Tab 从单张巨型宣纸面板改为响应式装备柜：宽屏三列分柜（武器 / 护甲 / 饰品），窄屏纵向堆叠。
- 装备格从黑底素材卡改为 `ItemSlot` 宣纸物品格，保留强化朱印、师承星标、境界封条、点击进详情。
- T11 段头验收仍保持：无计数、可读、真实枯笔分隔线、无 overflow。

## 截图

- `docs/handoff/codex_inventory_layout_redesign_2026-06-06/01_inventory_cabinet.png`

## 验证

- `flutter test test/features/inventory/presentation/inventory_screen_test.dart`
- `flutter test test/features/inventory/presentation/inventory_screen_test.dart test/shared/widgets/wuxia_ui/item_slot_test.dart test/shared/widgets/wuxia_ui/plaque_tab_test.dart test/shared/widgets/wuxia_ui/section_header_test.dart`
- `flutter analyze`
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=inventory`
