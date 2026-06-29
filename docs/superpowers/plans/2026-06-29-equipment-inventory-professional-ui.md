# 2026-06-29 装备仓库与装备详情专业化

## 目标

覆盖装备仓库相关优化：

1. 装备仓库信息层级重排。
2. 装备筛选与排序按钮优化。
3. 装备详情面板专业化。
4. 仓库操作按钮语义优化。
5. 装备描述文案统一规范。

## 分支

`codex/equipment-inventory-professional-ui`

## 验收标准

- 生产接线证据：改动接入 `InventoryScreen` 装备 Tab、`EquipmentDetailScreen` 详情页与 `UiStrings` 文案集中层，真实入口为主菜单「装备仓库」与装备格子点击详情。
- Targeted tests：至少运行 `flutter analyze`、`test/features/inventory/application/inventory_organization_test.dart`、`test/features/inventory/presentation/inventory_screen_test.dart`、`test/features/inventory/presentation/equipment_detail_screen_test.dart`、`test/features/equipment/presentation/equipment_detail_screen_test.dart`。
- UI/UX 加码：仓库与详情覆盖 1280x720 / 1440x900 常规桌面视口 smoke；交互按钮保留 `PlaqueButton`/`InkWell` 语义、focus、mouse cursor 与键盘激活能力，不改成裸 `GestureDetector`。
- 红线影响：不改数值公式、掉落、在线/离线收益、三系锁死校验；UI 文案只进 `UiStrings`，装备典故仍走 `data/lore`；不实装装备目标追踪、高阶装备暂存柜等 rejected registry 方向。
- 就绪信号：完成时工作区干净，tip commit 消息前缀为 `[READY]`；若需人类拍板则使用 `[BLOCKED]` 并写阻塞点。
- 残留风险：列明未覆盖视觉目检、测试环境限制或外部工具异常。

## 任务切片

1. 读取约束、初始化/查询 CodeGraph，建立计划文件。
2. 仓库装备卡片改为专业摘要：名称、品阶、部位、境界门槛、核心属性、状态 badge。
3. 筛选与排序文案短化，并补充当前条件/结果摘要。
4. 详情页按「基础信息 / 属性与养成 / 操作 / 来源 / 典故」分区。
5. 统一仓库与详情按钮语义：查看、强化、开锋、锁定、出售、分解。
6. 更新/新增 targeted widget 与 unit tests。
7. 运行 analyze、targeted tests、常规桌面视口 smoke，修复回归。
8. 整理提交，最终 `[READY]` 标记并保持工作区干净。

## 当前恢复点

- 状态：进行中。
- 最后完成：已读取 `AGENTS.md`、`CLAUDE.md` §8.2/§8.3、`GDD.md`、`docs/spec/rejected_task_registry.md`；CodeGraph 初始查询发现未初始化，执行 `codegraph init -i` 后进程 OOM 退出，但数据库可用，`codegraph_status` 显示 460 files / 8655 nodes；已用 CodeGraph 定位 inventory 文件和 `InventoryScreen` / `EquipmentDetailScreen`。
- 下一步：提交计划文件后实施仓库摘要与文案切片。
- 已跑验证：`codegraph_status`、`codegraph_files lib/features/inventory`、`codegraph_context`、`codegraph_search InventoryScreen`、`codegraph_search EquipmentDetailScreen`。
- 阻塞项：无。CodeGraph 初始化命令退出码 133/OOM，但索引已可查询，后续以已可用查询结果作为结构定位依据。
