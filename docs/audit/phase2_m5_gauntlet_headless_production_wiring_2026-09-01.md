# Phase 2 M5 断魂庄快速推演生产接线审计

日期：2026-09-01

任务：`P2-M5-GAUNTLET-HEADLESS-PRODUCTION-WIRING`

基线：`fe2a287f29285ab9988b0c3387765fc6f04a5b3f`

实现提交：`b787209a`

## 结论

前一版 M5 审计将断魂庄“完整首通后 headless replay”计为 `PASS`，但复核生产消费者后发现：`GauntletAutomationPolicy`、`GauntletAutomationAdmissionService` 和 `GauntletService.driveHeadlessReplayToRewardChoice` 只被测试调用，真实 `GauntletLoadoutScreen` 只进入 live flow。因此已发布的 `37/42` 曾包含一格假阳性，严格施工基线应暂降为 `36/42`。

本切片把现有 headless replay 接入已首通后的真实整备页，并把策略校验放入扣帖、建会话的同一 `GauntletService.enter` 事务前置边界。断魂庄自动化格因而恢复为可证的 `PASS`，M5 有效矩阵回到 `37/42`，没有净新增权重；断魂庄 durable dispatch 仍不存在，顶层 M5 保持 `0/1 BLOCKED`。

## 生产路径

- 可达入口：`GauntletLoadoutScreen`。
- 可见门：只有 `GauntletLoadoutInfo.clearedCyclesMax >= 1` 显示“快速推演”；未选人、无帖、active run 或正在提交时继续禁用。
- canonical request：`gauntletHeadlessReplayRequest(characterId)` 固定 exact `contentId`/participant/loadout 与 `direct + playerBot + headless + replay`。
- 原子准入：`GauntletService.enter(automationRequest: ...)` 在同一 Isar 事务中重读 `clearedGauntletIds`，先经既有 policy 校验 exact gauntlet 首通、exact loadout 和参与者，再扣帖并建 run；拒绝后帖和 run 均零变化。
- 推演：入场和 `driveHeadlessReplayToRewardChoice` 复用同一 request 快照，复用现有 Phase 0A runner、admission、共享 settlement、伤势/失败结算和奖励三选一边界。
- 语义分隔：该路径仍是 direct replay，不持久化世界时长，不冒充方案要求的 durable dispatch。

## 破坏证红

1. 把生产 CTA 的首通门强制退化为永真，“首通前不显示”用例精确 `1` 条失败。
2. 把生产页 request 的 participant 临时改为玩家选中者 `+1`，exact participant 路由用例精确 `1` 条失败。
3. 临时去掉 `enter` 事务内自动准入守卫，未首通请求真实建立 run，“扣帖前 fail closed”用例精确 `1` 条失败。

三向都以精确反向补丁还原，还原后 `git diff --exit-code` 为 0。

## 验证

- 实现前 RED：新增两条生产页用例精确 `2` 条失败，原因均为找不到“快速推演”。
- 核心定向：策略、原子入场与整备页 `40/40 PASS`。
- 断魂庄全域：`192/192 PASS`。
- `flutter analyze --no-pub lib test tool`：`No issues found!`。
- `dart format .`：`1699 files / 0 changed`。
- 锁保护整仓全量：`5833/5833 PASS`，退出码 `0`，`[E]=0`，末行 `All tests passed!`；锁已精确释放。
- 最终树相对基线的 `test/` 删除行为 `0`，不需要测试契约迁移例外。
- 项目 Gate 必须在最终 READY tip 再跑且全通过后才可合并。

## 范围

- 未改 schema/saveVersion、玩家数值、技能、奖励金额或概率、经济、解锁阈值、YAML TUNING 或战斗规则。
- 未新建 reducer、runner、settlement 或 durable owner，未启动 M3/M7。
- 真人桌面交互、视觉与 Windows 实机继续挂账；本证据只修复 M5 工程矩阵真实性，不支持正式 M5 或 Phase 2 PASS。
