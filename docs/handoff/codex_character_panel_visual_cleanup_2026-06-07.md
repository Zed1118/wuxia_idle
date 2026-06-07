# 角色页视觉清理：分隔线、装备白底、全局字号

日期：2026-06-07
分支：`codex/t11-inventory-section-header`

## 背景

用户在角色页截图中标注了两类共性视觉问题：

- 装备素材里有不少白底图，直接贴在宣纸 UI 上显得突兀。
- 多处标题下方的细长位图分隔线裁到了白灰伪底。
- 后续反馈：不是单个属性字号小，而是很多地方文字整体偏小。

## 改动

- `SectionHeader` 不再使用 `assets/ui/ink_divider.png` 裁切做标题线，改为 `CustomPainter` 绘制细墨线，避免位图白底/伪文字进入标题下方。
- 新增 `EquipmentArtImage`，装备图统一使用纸色 `multiply` 融合白底。
- 接入位置：
  - `ItemSlot` 背包装备格。
  - `CharacterPanelScreen` 角色页三装备槽。
  - `EquipmentDetailScreen` 装备详情大图。
- 角色页基础四维与派生属性卡局部放大，增强层级。
- 新增 `WuxiaUi.textScale = 1.12`，在正常 app 入口和视觉验收入口统一套 `MediaQuery.textScaler`，解决显式 `fontSize: 11/12/13` 大量散写导致的全局偏小问题。

## 验证

- `flutter analyze lib/main.dart lib/features/debug/presentation/visual_route_host.dart lib/shared/theme/wuxia_tokens.dart lib/shared/widgets/equipment_art_image.dart lib/shared/widgets/wuxia_ui/item_slot.dart lib/shared/widgets/wuxia_ui/section_header.dart lib/features/character_panel/presentation/character_panel_screen.dart lib/features/inventory/presentation/equipment_detail_screen.dart test/shared/widgets/wuxia_ui/section_header_test.dart test/shared/widgets/wuxia_ui/item_slot_test.dart test/features/character_panel/presentation/character_panel_screen_test.dart`
- `flutter test test/shared/widgets/wuxia_ui/section_header_test.dart test/shared/widgets/wuxia_ui/item_slot_test.dart test/features/character_panel/presentation/character_panel_screen_test.dart test/features/main_menu/presentation/main_menu_test.dart`
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=character_panel`

## 截图

- `docs/handoff/codex_character_panel_visual_cleanup_2026-06-07/01_character_panel_equipment_art_section_divider.png`
- `docs/handoff/codex_character_panel_visual_cleanup_2026-06-07/02_character_panel_global_text_scale.png`

## 注意

- macOS debug 热重启时出现 objective_c framework 重复类警告，但 app 正常启动并输出 `VISUAL_ROUTE_READY: character_panel`。本批未处理该工具链警告。
