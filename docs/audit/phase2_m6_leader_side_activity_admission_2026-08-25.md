# P2-M6 掌门支线准入生产纵切审计

## 交付身份

- 任务：`P2-M6-LEADER-SIDE-ACTIVITY-ADMISSION`
- 基线：`8d63c62105b9bf35f111259673edaf8fea3fdcd3`
- 分支：`codex/phase2-m6-leader-side-activity-admission-20260825`
- 代码/语义复核候选：`4aadbea75225216b867b69806a158c62f7f8a2c1`
- 状态：`ready_reviewed`

## 生产语义

- 百草岭与断魂庄候选 provider 先经 `CurrentLeaderResolver` 核实当前掌门，再从全部存活角色中只纳入当前掌门和非祖师角色；历史祖师不进入候选。
- 当前掌门存活、空闲且有主修时，可从真实 `ExpeditionOverviewScreen` / `GauntletLoadoutScreen` 选中；两个 service 在各自写事务内再次核验掌门身份、存活、占用和主修后，建立真实单人会话并把成员 ID 绑定到该掌门。
- 闭关、百草岭、断魂庄重复占用由 `CharacterOccupancyService` 统一判定；身份悬空、历史祖师、死亡、无主修、重复占用或 provider 异常均 fail closed，不回退其他角色。
- 原单人、方针、周目、补给、恢复、战斗、离线推进、结算、召回、奖励和返程语义不变；不写 `activeCharacterIds` / `isActive`，也不新建活动或结算真相源。

## 红绿与验证

- 环境元数据与 Isar 生成件就绪后，首个有效 RED 为六个目标文件 `53 PASS / 4 FAIL`：两个 provider 均排除当前掌门，两个 service 均硬拒绝当前掌门；历史祖师与闭关拒绝控制项保持绿色。
- 主控语义复核发现断魂庄 service 只在 provider 隐藏死亡角色，直接 service 路径仍可入场；新增守卫测试修复前 `0/1`，修复后事务内 fail closed。这是本纵切唯一生产语义返工。
- 最终目标集当前 diff 覆盖 `60/60 PASS`；相邻 expedition、boss gauntlet、统一占用、江湖地图详情 provider/UI 和真实 gauntlet 入口流 `324/324 PASS`。
- 相关页面覆盖 `1280x720` / `1440x900` 选择与禁用状态；这些 widget 证据不外推为完整 Desktop 视觉验收。
- scoped `flutter analyze --no-pub lib/features/expedition lib/features/boss_gauntlet lib/features/jianghu_map lib/features/activity lib/shared/strings.dart` 与根应用 `flutter analyze --no-pub lib test tool`：均 `0 issue`。
- 最终全量只运行一次：`flutter test --no-pub --reporter compact` → `5523/5523 PASS`，耗时 `6:45`。
- 主控最终语义复核 `P0=0 / P1=0 / P2=0`；`git diff --check`、YAML、陈旧文案、精确白名单、lineage、primary 与 U08 工作树保护均在 READY 前复核。本轮未启用子 Agent，因此不把主控复核冒称为独立 Agent 复审。

## 结果驱动记录

- 验收门变化：掌门支线准入必要生产子门 `WIP 0/1 → READY 1/1`；M6 顶层四门不由此晋升。
- 可观测耗时：WIP 登记 `09:53` 到最终全量结束并开始治理约 `18 分钟`，低于 90 分钟路线上限的 25% 检查点。
- 可观测用量：无可靠周用量读数，未伪造百分比；仅记录墙钟时间。
- 集成返工：1 个断魂庄 service 死亡角色 fail-closed 缺口；在相邻域与最终全量前关闭。初始化时缺 package metadata / 生成件的两次失败发生在测试执行前，不计作 RED 或 PASS。
- 这是新工作流第 2 个可比 gate：第 1 门约 14 分钟，本门约 18 分钟；样本仍小且本门验证面不同，不宣称 40%-70% 效率提升。

## 边界与未关闭项

- 本结论只关闭“空闲当前掌门可参加百草岭/断魂庄，忙碌或身份异常时双层 fail closed”子门，不代表 U08、所有角色全模式占用、M6 或二阶段完成。
- 不修改 schema/saveVersion、YAML、`TUNING/candidate`、数值、奖励、经济、解锁、叙事、战斗或 main。
- 塔、轻功、守城及其他可见模式的逐入口选人、主菜单到亲战/差遣/结算/报告统一闭环、主线五关无强制文本的组合验收仍开放。
