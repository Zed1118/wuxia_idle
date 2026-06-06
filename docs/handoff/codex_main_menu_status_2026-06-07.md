# 主菜单入口状态提示验收

日期：2026-06-07
分支：`codex/t11-inventory-section-header`

## 范围

本切片处理 `docs/UI_WORK_REMAINING_2026-06-06.md` 的 T8 第一段：只给主菜单核心入口补状态提示，不改入口解锁、导航、存档或结算逻辑。

- 主线入口：显示当前可挑战章节与下一关名称。
- 爬塔入口：显示最高已通层与下一层；下一层为 Boss 时标记 Boss。
- 闭关入口：显示未开放 / 可择地图 / 闭关中地点 / 可收功地点。
- `WuxiaInkButton` 新增可选 `status` chip，未传入时保持原样。

## 结论

总判：通过。1280x720 窗口下主菜单三栏仍无 overflow；状态 chip 没有挤压标题与 hint；锁定态透明度与原门控逻辑保留。

| 验收点 | 结果 | 说明 |
|---|---|---|
| 主线入口状态 | 通过 | 从 `MainlineProgress` 和真实 stage defs 推导下一关。 |
| 爬塔入口状态 | 通过 | 从 `TowerProgress` 推导最高层与下一层，Boss 层额外提示。 |
| 闭关入口状态 | 通过 | loading / tutorial lock 优先级不变；service 可用时读取 active session。 |
| 不堆小字 | 通过 | 状态放在标题行右侧短 chip，不替代原 hint。 |
| 导航不变 | 通过 | 所有入口 `onTap` 目标未改。 |

## 截图清单

- `docs/handoff/codex_main_menu_status_2026-06-07/01_main_menu_status_1280x720.png`

## 验证

```bash
flutter test test/features/main_menu/presentation/main_menu_test.dart
flutter analyze lib/features/main_menu/presentation/main_menu.dart lib/shared/widgets/wuxia_ink_button.dart lib/shared/strings.dart test/features/main_menu/presentation/main_menu_test.dart
flutter build macos --debug --dart-define=VISUAL_ROUTE=main_menu
```

以上均通过。
