# 2026-06-29 Night UI B1 Foundation

## Scope

批次 1：按钮/热区基础层。分支 `codex/night-ui-b1-foundation`，worktree `.worktrees/night-ui-b1-foundation`，基于 `ec55031feffeb0d3aed705549ecfbc096ca01922`。

只做表现层/UI/测试/计划文档；未修改 `numbers.yaml`、存档 schema、结算逻辑、`GDD.md`、`CLAUDE.md`。

## Checklist

1. `hitbox-map`：已审计 `TextButton` / `ElevatedButton` / `OutlinedButton` / `IconButton` / `InkWell` / `GestureDetector` / dialog usage。重点问题：共享页签仍有 Material 水波纹；存档页图标按钮热区依赖 Material `IconButton`；设置/存档确认动作仍是 `AlertDialog/TextButton`；设置滑条行缺少稳定最小热区。
2. `plaque-button`：`PlaqueButton` 补 `minWidth=72`、`minHeight=44`，`onTap == null` 视为 disabled，保持 pressed/focus/keyboard 语义。
3. `wuxia-ink-button`：`WuxiaInkButton` 改为无 `InkWell` 的 `GestureDetector + FocusableActionDetector`，统一最小高度、hover/pressed/focus overlay、disabled 语义、status chip 测试。
4. `plaque-tab`：`PlaqueTab` 改为无 `InkWell`，补固定热区、语义、keyboard activate、focus ring。
5. `icon-button-spec`：新增 `WuxiaIconButton`，固定 44x44 热区、20px 图标、tooltip、semantics、hover/pressed/focus、disabled 与 destructive 色。
6. `text-button-policy`：低风险替换设置面板关闭/切档确认/备份删除确认、存档新建/重命名/删除确认中的 `TextButton`；保留非本批目标页面和测试支架中的 Material 按钮。
7. `dialog-actions`：设置/存档动作区统一到 `PaperDialog + PlaqueButton`。存档删除仍用 `showDialog + StatefulBuilder` 承载输入保护，但内容外壳是 `PaperDialog`。
8. `settings-controls`：音量滑条行补 `minHeight=48` 和水平 padding；备份管理动作改 `PlaqueButton`。
9. `save-slot-actions`：存档卡片重命名/删除改 `WuxiaIconButton`，保留整张卡片 `InkWell` 作为大面积入档热区。
10. `shared-widget-tests`：补 `PlaqueButton` / `PlaqueTab` / `WuxiaInkButton` / `WuxiaIconButton` 尺寸、语义、disabled、focus/keyboard 测试；同步存档页测试。

## Changed Files

- `lib/shared/widgets/wuxia_ui/plaque_button.dart`
- `lib/shared/widgets/wuxia_ui/plaque_tab.dart`
- `lib/shared/widgets/wuxia_ink_button.dart`
- `lib/shared/widgets/wuxia_ui/wuxia_icon_button.dart`
- `lib/shared/widgets/wuxia_ui/wuxia_ui.dart`
- `lib/shared/widgets/wuxia_ui/paper_dialog.dart`
- `lib/features/settings/presentation/settings_panel.dart`
- `lib/features/save_slot/presentation/save_select_screen.dart`
- `test/shared/widgets/wuxia_ui/plaque_button_test.dart`
- `test/shared/widgets/wuxia_ui/plaque_tab_test.dart`
- `test/shared/widgets/wuxia_ink_button_test.dart`
- `test/shared/widgets/wuxia_ui/wuxia_icon_button_test.dart`
- `test/features/save_slot/save_select_screen_test.dart`
- `test/features/main_menu/presentation/main_menu_test.dart`

## Verification

- `dart run build_runner build --delete-conflicting-outputs`：通过；worktree 本地生成被 `.gitignore` 忽略的 `*.g.dart` 以供分析/测试。
- `flutter test test/shared/widgets/wuxia_ui/plaque_button_test.dart test/shared/widgets/wuxia_ui/plaque_tab_test.dart test/shared/widgets/wuxia_ink_button_test.dart test/shared/widgets/wuxia_ink_button_height_test.dart test/shared/widgets/wuxia_ui/wuxia_icon_button_test.dart test/shared/widgets/wuxia_ui/paper_dialog_test.dart test/features/save_slot/save_select_screen_test.dart test/features/settings/settings_panel_slot_switch_test.dart test/features/settings/settings_panel_overflow_test.dart`：44/44 passed。
- `flutter test test/features/main_menu/presentation/main_menu_test.dart`：54/54 passed；同步 `WuxiaInkButton` 去 `InkWell` 后的旧计数断言。
- `flutter analyze`：No issues found。

## Residual Risks

- 仍有非本批目标的 Material/Ink 入口：`shared/app_exit.dart`、`wuxia_title_bar.dart`、`item_slot.dart`、`stage_progress_row.dart`、`main_menu.dart` 右上退出键等。已记录为后续批次，不在本批扩大重构。
- 存档卡片整体点击仍用 `InkWell`，因为它是大面积入档热区且替换可能影响手势竞争；本批只修正卡片内小图标动作。
- `WuxiaInkButton` 去掉 `InkWell` 后已同步主菜单直接计数测试；若其它后续批次仍按 `InkWell` 数量做间接断言，需要继续改为组件语义/点击路径断言。
