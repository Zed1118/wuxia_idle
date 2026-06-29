# 装备对比与视觉一致性基线

## 目标

- 优化装备槽对话框的当前装备 vs 候选装备对比，明确显示提升 / 下降 / 持平 / 新增。
- 为装备仓库与角色面板后续合并提供小型共享视觉基线：状态 pill、克制的增减色、统一按钮/分隔/字体密度。
- 保持生产路径：角色面板装备槽弹出 `EquipSlotDialog`，确认仍走 `EquipmentService.equip` / `unequip`，不绕境界锁和保护校验。

## 分支

- `codex/equipment-compare-visual-baseline`

## 验收标准（CLAUDE.md §8.2 / §8.3 转写）

- [x] 生产接线证据：说明入口、消费方、真实 service 路径，不停在 demo / fixture。
- [x] Targeted test 结果：至少 `flutter analyze`、装备对比 domain test、装备槽 dialog widget test。
- [x] 红线影响说明：不触及数值硬红线；三系锁死只增强提示，不放宽；不引入在线 / 离线差异、反主流机制、散写 UI 文案。
- [x] 残留风险：列出未做全量测试、未做人工截图目检等风险。
- [x] UI 视口：覆盖 1280x720 与 1440x900 常规桌面视口 smoke，不用超高视口替代。
- [x] 桌面语义：保留 `IconButton` tooltip、`ListTile`/InkWell 选择语义、按钮 focus/keyboard/mouse cursor 默认行为。
- [x] Git 就绪：所有改动 commit，worktree 干净，tip commit message 前缀为 `[READY]`；若需拍板则 `[BLOCKED]`。

## 任务切片

1. 读取 AGENTS / CLAUDE / GDD / rejected registry，确认红线与交付 gate。
2. 用 CodeGraph 定位 `EquipSlotDialog`、`equipmentFullDiff`、`UiStrings` 与测试入口。
3. 新增小型共享 `WuxiaStatusPill` 与克制增减色 token。
4. 将装备对比 UI 文案集中到 `UiStrings`，domain 只引用集中 sink。
5. 优化候选行和对比行：状态 pill、增减值、境界锁提示、克制按钮样式。
6. 补充 1280x720 / 1440x900 widget smoke 与锁定提示断言。
7. 运行格式化、analyze、targeted tests，修复问题。
8. 小切片提交并打 `[READY]` tip。

## 当前恢复点

- 状态：完成，待主窗口评审 / 合并。
- 最后完成：新增 `WuxiaStatusPill`、装备对比克制状态色、候选行/对比行视觉优化、境界锁提示、UI 文案集中迁移与视口 smoke 测试。
- 下一步：主窗口按 CLAUDE.md §8.2 gate 评审该 `[READY]` tip。
- 已跑验证：`dart run build_runner build --delete-conflicting-outputs`；`flutter analyze`；`flutter test test/features/character_panel/equipment_stat_diff_test.dart`；`flutter test test/features/character_panel/presentation/equip_slot_dialog_test.dart`；`flutter test test/shared/widgets/wuxia_ui/wuxia_status_pill_test.dart`。
- 阻塞项：无。
