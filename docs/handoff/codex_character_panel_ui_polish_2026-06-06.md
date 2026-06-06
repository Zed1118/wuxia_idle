## 结论

总判：通过。角色面板已从 Material 深色外框改为与装备线一致的水墨 UI-kit 外框，视觉上接入宣纸顶栏、木牌页签、宣纸面板；浅底文字同步改为墨色系，未发现本轮新增 overflow 或功能回归。

## 改动范围

| 区域 | 处理 | 结果 |
|---|---|---|
| 顶栏 | `AppBar` 改为 `WuxiaTitleBar` | 与装备线顶栏体系一致 |
| 角色切换 | 自定义深色 `_LineageTab` 改为 `PlaqueTab` | 木牌页签居中显示，选中态更明确 |
| 外层卡片 | `_PanelCard` 改为 `PaperPanel` | 档案、数值、装备、心法、师承外框统一宣纸底 |
| 浅底文字 | 档案头、段标题、标签值改用 `WuxiaUi.ink/muted` | 修正白字落在宣纸底上的低对比问题 |
| 测试 | 增加 `WuxiaTitleBar/PlaqueTab/PaperPanel` 断言 | 防止外框组件被无意回退 |

## 验证

- `flutter test test/features/character_panel/presentation/character_panel_screen_test.dart test/features/character_panel/presentation/character_panel_screen_edge_test.dart`：通过，28 passed。
- `flutter analyze`：通过，No issues found。
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=character_panel`：通过。
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=hub`：通过。

## 截图清单

- `docs/handoff/codex_character_panel_ui_polish_2026-06-06/01_character_panel.png`

## 备注

- 本轮只统一角色面板外层框架和浅底文字色值，未深入重做装备槽、心法槽、奇遇招式等深色信息块。
- 当前工作仍在独立分支 `codex/t11-inventory-section-header`，未合并 `main`。
