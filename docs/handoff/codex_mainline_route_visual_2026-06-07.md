# 主线路线图第二切片视觉验收

日期：2026-06-07
分支：`codex/t11-inventory-section-header`

## 范围

本轮处理 T3「P1-1 主线完整路线图」的第二切片，只升级章节列表顶部的江湖路引，不改主线进度、关卡解锁、关卡进入、战斗与剧情流程。

- 将原 6 个小圆点改为 6 个章节区域。
- 每个章节区域接入章节封面图、章节名、当前状态。
- 每章显示 5 个关卡节点，Boss 关使用朱印/徽章式节点。
- 锁定章节整块弱化，但仍保留图像轮廓与关卡结构。
- 下方原章节卡列表保留，原点击进入章节与卷首/卷尾入口不变。

## 结论

总判：通过。1280x720 与当前宽屏窗口下未发现 overflow；不读说明也能看出 6 章推进路径、每章 5 关、Boss 节点、已通/当前/未至状态。

| 验收点 | 结果 | 说明 |
|---|---|---|
| 6 章路线可见 | 通过 | 六个章节区域同屏展示，连接线表达推进路径。 |
| 关卡节点可见 | 通过 | 每章 5 个节点，前三关圆点，Boss 关为特殊朱印节点。 |
| 状态一致 | 通过 | 路线图沿用 `MainlineProgressService.availableStages` 和章节完成判断，只读展示。 |
| 原流程不变 | 通过 | 原章节卡、章节点击、卷首/卷尾入口未改。 |
| 1280x720 无 overflow | 通过 | 截图自验未见红黄 overflow。 |

## 截图清单

- `docs/handoff/codex_mainline_route_visual_2026-06-07/01_chapter_route_full.png`
- `docs/handoff/codex_mainline_route_visual_2026-06-07/02_chapter_route_1280x720.png`

## 验证

```bash
flutter test test/features/mainline/presentation/chapter_list_screen_test.dart test/features/mainline/presentation/stage_list_screen_test.dart
flutter analyze lib/features/mainline/presentation/chapter_list_screen.dart lib/shared/strings.dart test/features/mainline/presentation/chapter_list_screen_test.dart
flutter build macos --debug --dart-define=VISUAL_ROUTE=chapter_list
```

以上均通过。
