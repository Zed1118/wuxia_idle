# 2026-06-29 角色信息面板专业化

## 目标

- 重排角色信息面板结构：身份信息、境界修为、基础属性、战斗属性、装备概况、心法概况、状态效果。
- 优化属性说明：基础属性与派生战斗属性分区展示，标签走 GlossaryTip / Tooltip 轻量解释入口。
- 增强装备总览：武器 / 护甲 / 饰品显示空槽、装备名、品阶、强化、共鸣、当前境界可用性与是否低于当前境界。

## 分支

- `codex/character-panel-professional-info`

## 验收标准

- [x] 生产接线证据：`CharacterPanelScreen` 的真实主菜单入口继续消费该 UI；装备槽仍只打开 `EquipSlotDialog`，不改仓库和装备详情。
- [x] targeted test：`flutter test test/features/character_panel/presentation/character_panel_screen_test.dart test/features/character_panel/presentation/character_panel_screen_edge_test.dart` 通过 33/33。
- [x] analyze：`flutter analyze` 通过，0 issue。
- [x] UI 视口 smoke：1280x720 由角色面板 widget test 默认 surface 覆盖；1440x900 新增 smoke 用例覆盖，均无布局异常。
- [x] 红线影响：不触及战斗数值、在线/离线收益、反主流机制；三系锁死只读展示 `Equipment.isEquippableAtRealm`；新增 UI 文案全部进入 `UiStrings`。
- [x] 残留风险：未做人工截图目检；本轮 smoke 以 widget 布局异常检测为准。
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

- 状态：实现完成，待 `[READY]` tip 提交。
- 最后完成：角色页已重排为身份信息、境界修为、基础属性、战斗属性、装备概况、心法概况、状态效果；装备槽已显示空槽、装备名/品阶、强化、共鸣、可用性与境界匹配状态。
- 下一步：提交实现切片，追加 `[READY]` tip，确认工作区干净。
- 已跑验证：`dart run build_runner build --delete-conflicting-outputs`；`flutter analyze` 0 issue；`flutter test test/features/character_panel/presentation/character_panel_screen_test.dart test/features/character_panel/presentation/character_panel_screen_edge_test.dart` 33/33 通过。
- 阻塞项：无。
