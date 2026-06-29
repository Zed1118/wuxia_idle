# 2026-06-29 角色信息面板专业化

## 目标

- 重排角色信息面板结构：身份信息、境界修为、基础属性、战斗属性、装备概况、心法概况、状态效果。
- 优化属性说明：基础属性与派生战斗属性分区展示，标签走 GlossaryTip / Tooltip 轻量解释入口。
- 增强装备总览：武器 / 护甲 / 饰品显示空槽、装备名、品阶、强化、共鸣、当前境界可用性与是否低于当前境界。

## 分支

- `codex/character-panel-professional-info`

## 验收标准

- [ ] 生产接线证据：`CharacterPanelScreen` 的真实主菜单入口继续消费该 UI；装备槽仍只打开 `EquipSlotDialog`，不改仓库和装备详情。
- [ ] targeted test：运行 `flutter test test/features/character_panel/presentation/character_panel_screen_test.dart test/features/character_panel/presentation/character_panel_screen_edge_test.dart` 并记录结果。
- [ ] analyze：运行 `flutter analyze`。
- [ ] UI 视口 smoke：覆盖 1280x720 与 1440x900 常规桌面视口。
- [ ] 红线影响：不触及战斗数值、在线/离线收益、反主流机制；三系锁死只读展示 `Equipment.isEquippableAtRealm`；新增 UI 文案全部进入 `UiStrings`。
- [ ] 残留风险：记录未覆盖的视觉/交互风险。
- [ ] Git 就绪：所有改动提交，工作区干净，tip commit 前缀为 `[READY]`；若需用户拍板则改用 `[BLOCKED]`。

## 任务切片

1. 读取 AGENTS / CLAUDE / GDD / rejected registry，确认本轮边界。
2. 用 CodeGraph 定位 `CharacterPanelScreen` / `LineageCharacterDetailScreen` / `UiStrings` 与影响范围。
3. 新增本计划文件并提交恢复点。
4. 重排角色页结构与属性分区。
5. 增强装备槽总览状态。
6. 更新集中 UI 文案与相关 widget tests。
7. 运行 analyze、targeted tests、桌面视口 smoke。
8. 更新恢复点并打 `[READY]` 提交。

## 当前恢复点

- 状态：进行中。
- 最后完成：已读必需文档；CodeGraph 在原项目索引定位到角色面板、门人详情页和 `UiStrings`；当前 worktree 已建分支。
- 下一步：实现角色页结构重排与装备总览增强。
- 已跑验证：尚未运行。
- 阻塞项：无。
