# 心法三系关系盘视觉验收

日期：2026-06-07
分支：`codex/t11-inventory-section-header`

## 范围

本轮处理 T7「心法与三流派关系可视化」第一切片，只在心法面板加入三系关系展示，不改心法修炼、主辅修、散功、凝练领悟或相生检测逻辑。

- 在主修 hero 与心法列表之间新增「三系相克」关系盘。
- 展示 `刚猛 → 阴柔 → 灵巧 → 刚猛` 的克制环。
- 三个流派节点展示对应战斗倾向：震伤 / 暴击 / 内伤。
- 当前主修流派高亮；无主修时显示未定。
- 原心法列表、设为主修、散功确认、凝练领悟入口不变。

## 结论

总判：通过。1280x720 截图未见 overflow；关系盘能在首屏直接解释三流派关系；当前主修流派高亮清楚。

| 验收点 | 结果 | 说明 |
|---|---|---|
| 三系关系可见 | 通过 | 三角关系盘显示刚猛、灵巧、阴柔三节点和克制方向。 |
| 当前主修高亮 | 通过 | `VISUAL_ROUTE=technique_panel_hero` 中当前刚猛节点以金色高亮。 |
| 原交互不变 | 通过 | 设为主修、散功 dialog、凝练领悟测试仍通过。 |
| 1280x720 无 overflow | 通过 | 截图自验未见红黄 overflow。 |

## 截图清单

- `docs/handoff/codex_technique_school_matrix_2026-06-07/01_technique_school_matrix_1280x720.png`

## 验证

```bash
flutter test test/features/technique_panel/presentation/technique_panel_screen_test.dart
flutter analyze lib/features/technique_panel/presentation/technique_panel_screen.dart lib/shared/strings.dart test/features/technique_panel/presentation/technique_panel_screen_test.dart
flutter build macos --debug --dart-define=VISUAL_ROUTE=technique_panel_hero
```

以上均通过。
