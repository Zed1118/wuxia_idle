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
| 奇遇招式 | `EncounterSkillSection` 改为 `PaperPanel` + `SectionHeader` + `PlaqueButton` | 底部子区块不再脱离宣纸卡片体系 |
| 装备/辅修槽 | `_EquipmentSlotShell` / `_SlotShell` 改为宣纸纹理浅底，文字改墨色系 | 中部三装备槽和辅修槽从黑色条块转为器物签 |
| 可读性强化 | 派生数值改为大号数值签；装备图框放大到 112px；基础属性字号上调；分区标题统一 `SectionHeader` | 解决装备图过小、派生属性文字轻、颜色不明显的问题 |
| 档案头画像 | 头像改为画像签，叠宣纸覆层、墨色内框、门派色窄条与身份压条；姓名、境界、门派、四属性重排为档案牌 | 角色头像不再像独立贴图，顶部档案区更贴近水墨包装 |
| 测试交互 | picker 相关测试先滚动到装备槽再点击 | 适配档案头变高后的可滚动首屏布局 |

## 验证

- `flutter test test/features/character_panel/presentation/character_panel_screen_test.dart test/features/character_panel/presentation/character_panel_screen_edge_test.dart`：通过，28 passed。
- `flutter analyze`：通过，No issues found。
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=character_panel`：通过。
- `flutter build macos --debug --dart-define=VISUAL_ROUTE=hub`：通过。

## 截图清单

- `docs/handoff/codex_character_panel_ui_polish_2026-06-06/01_character_panel.png`
- `docs/handoff/codex_character_panel_ui_polish_2026-06-06/02_character_panel_encounter_skill.png`
- `docs/handoff/codex_character_panel_ui_polish_2026-06-06/03_character_panel_slots.png`
- `docs/handoff/codex_character_panel_ui_polish_2026-06-06/04_character_panel_readability.png`
- `docs/handoff/codex_character_panel_ui_polish_2026-06-06/05_character_panel_profile_header.png`

## 备注

- 本轮统一角色面板外层框架、浅底文字色值，收拢奇遇招式段外框，并将装备槽/辅修槽浅底化；最新补强了装备图尺寸、派生数值层级、分区段头和档案头画像签。主修心法大卷面仍保留原结构，后续可单独打磨。
- 当前工作仍在独立分支 `codex/t11-inventory-section-header`，未合并 `main`。
