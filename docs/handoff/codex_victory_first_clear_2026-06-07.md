# 首通胜利封签视觉验收

## 结论

总判：通过。首通 / Boss 首胜在胜利弹窗顶部有独立“朱印封记”封签，掉落、升层、共鸣提示仍沿用原弹窗内容结构；普通重打不显示首通封签。

| 验收点 | 结果 | 说明 |
|---|---:|---|
| 主线首胜封签 | 通过 | `StageVictoryContent` 支持 `firstClearTitle`，顶部显示朱印封记。 |
| 爬塔首通封签 | 通过 | 首通显示“首通 · 第 N 层”，Boss 层显示“破阵 · 第 N 层 Boss”。 |
| 重打不误显 | 通过 | `isFirstClear == false` 路径仍只显示重打无奖励提示。 |
| 既有奖励内容 | 通过 | 掉落、升层、共鸣三段仍可见，布局不互相遮挡。 |
| 视觉路由 | 通过 | 新增 `VISUAL_ROUTE=battle_victory_first_clear` 便于截图验收。 |

## 截图清单

- `docs/handoff/codex_victory_first_clear_2026-06-07/01_boss_first_clear_banner_1280x720.png`

## 验证命令

- `flutter test test/features/mainline/presentation/stage_victory_dialog_test.dart test/features/tower/presentation/tower_entry_flow_test.dart`
- `flutter analyze lib/features/mainline/presentation/stage_victory_dialog.dart lib/features/tower/presentation/tower_entry_flow.dart lib/features/debug/application/visual_route.dart lib/features/debug/presentation/visual_route_host.dart lib/shared/strings.dart test/features/mainline/presentation/stage_victory_dialog_test.dart test/features/tower/presentation/tower_entry_flow_test.dart`
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=battle_victory_first_clear`

## 备注

- 截图由临时 widget capture 生成，当前桌面处于 macOS 锁屏，无法直接截取真实窗口；临时脚本已删除，未纳入提交。
