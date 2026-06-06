# 主线章内行程视觉验收

日期：2026-06-07
分支：`codex/t11-inventory-section-header`

## 范围

本轮继续处理 T3「主线完整路线图」的章内切片，只包装 `StageListScreen` 的视觉结构，不改关卡解锁、点击进入、剧情阅读或战斗流程。

- 将章节内页面从“封面 + 普通列表”改为“章内行程图 + 关卡行”。
- 顶部行程图展示 5 关路径，Boss 关使用特殊节点。
- 下方关卡行加入左侧关卡节点、Boss 标记、状态 badge。
- 新增 `VISUAL_ROUTE=stage_list`，fixture 固定为第一章 1-4 已通、5 关 Boss 可挑战。

## 结论

总判：通过。1280x720 下未发现 overflow；5 关路径、Boss 节点、已通/可挑战状态清楚；原点击 available 关卡进入剧情阅读流程测试通过。

| 验收点 | 结果 | 说明 |
|---|---|---|
| 章内路径可见 | 通过 | 顶部行程图展示 5 个节点与连接线。 |
| Boss 节点明确 | 通过 | 第 4 / 5 关使用 Boss 徽章节点，行内也有 Boss 标记。 |
| 状态清楚 | 通过 | 1-4 已通、5 可挑战的 fixture 截图稳定。 |
| 原流程不变 | 通过 | `runStageFlow` 入口未改，widget test 仍进入真实剧情阅读屏。 |
| 1280x720 无 overflow | 通过 | 截图自验未见红黄 overflow。 |

## 截图清单

- `docs/handoff/codex_stage_journey_visual_2026-06-07/01_stage_journey_1280x720.png`

## 验证

```bash
flutter test test/features/mainline/presentation/stage_list_screen_test.dart test/features/mainline/presentation/chapter_list_screen_test.dart
flutter analyze lib/features/mainline/presentation/stage_list_screen.dart lib/features/debug/application/visual_route.dart lib/features/debug/presentation/visual_route_host.dart lib/shared/strings.dart test/features/mainline/presentation/stage_list_screen_test.dart
flutter build macos --debug --dart-define=VISUAL_ROUTE=stage_list
```

以上均通过。
