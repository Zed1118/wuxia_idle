# Phase 2 M5 九霄塔持久差遣审计

日期：2026-09-01

任务：`P2-M5-TOWER-DURABLE-DISPATCH`

基线：`09533ce357344559e6bf0b7594084b18ad107562`

实现提交：`2fa570aa`

## 结论

九霄塔原有真实手动挑战和已通层 direct headless sweep，但没有可恢复、会占用 exact participant/loadout、能与奖励结算原子提交的 durable dispatch，因此 M5“离线/差遣允许矩阵”此前为 `BLOCKED`。

本切片在不新增 Isar collection/字段、不提升 schemaVersion/saveVersion 的前提下，把 `tower` 作为既有名称枚举字段的新值接入 `DurableActivityCombatRun`。已通层现在可从真实塔列表选择空闲掌门或门人，建立 active run，经既有 `mapTower` 和 Phase 0A headless 内核执行，再与塔进度、成长/伤势、掉落、图鉴、奖励 receipt 同事务结算。该格可计为工程 `PASS`，M5 有效矩阵由 `37/42` 推至 `38/42`；塔个人最好成绩、断魂庄 durable owner、百草岭两个首次手动里程碑合同仍未实现，顶层 M5 保持 `0/1 BLOCKED`。

## 生产路径

- 可达入口：`TowerFloorListScreen → TowerFloorCard → startTowerDurableDispatch`；仅已通层且不存在其它 outstanding durable run 时显示“差遣历练”。
- 准入：`towerDurableDispatchRequest` 固定 exact `contentId`、participant/loadout 和 `dispatch + playerBot + headless + offlineResume`；`TowerAutomationPolicy` 同时保留旧 direct sweep，但拒绝两条路径的混合 tuple。
- 持久 owner：`DurableActivityAutomationService.startTower/admitTower` 复用既有 `DurableActivityCombatRun` 字段、seed、游标、成员/装配快照与 `CharacterOccupancyService`，恢复时不回退掌门或猜默认装配。
- 执行：`Phase0aSweepHeadlessRunner.runTowerDurable` 消费 admission 的 exact snapshot，调用既有 `Phase0aStageContentMapper.mapTower` 与共享 Phase 0A runner。
- 结算：胜利由 `applyTowerVictorySettlement` 在 durable receipt 外层事务内调用 U09 `claimBatchInTxn`、塔进度、战斗成长/伤势、掉落与图鉴；败北在同一 durable 事务写战斗结算和 `recordDefeatInTxn`。
- 恢复：timeout 保留 active；settlementApplied 报告使用持久 participant/outcome，确认后 close 并释放占用。

## 破坏证红

1. 把 dispatch allowlist 临时改成 direct + offlineResume，策略、六模式矩阵与真实 service 共精确 `4` 条失败，同时证明错误混合 tuple 会被守卫捕获。
2. 把生产塔列表的差遣条件临时改为 locked，生产 widget 用例精确 `1` 条失败：找不到“差遣历练”。
3. 临时断开塔胜利结算的 durable settlement context，coordinator 用例精确 `1` 条失败：`Tower durable receipt was not persisted`。

三向均用精确反向补丁还原；还原后 `git diff --exit-code` 为 0。

## 当前验证

- 扩展定向：activity/occupancy、塔 policy/service/coordinator/UI、真实 `mapTower` runner、结算、宗门行止与门人调度共 `79/79 PASS`。
- 独立真实 runner：durable tower admission 进入 `mapTower` 并产生 exact participant 终局，`1/1 PASS`。
- 原子结算：durable tower 胜利落 `settlementApplied` 与 tower reward receipt，`1/1 PASS`。
- scoped analyze：`No issues found!`。
- 最终整仓 format、锁保护全量、项目 Gate 与精确 SHA CI 在最终 READY tip 记录。

## 范围

- 未改 Isar collection 字段、schemaVersion/saveVersion、玩家数值、技能、奖励金额或概率、经济、解锁阈值、YAML TUNING 或战斗规则。
- 未新增 reducer、headless 内核或结算 owner；未启动 M3/M7。
- 真人桌面交互、视觉与 Windows 实机继续挂账；本证据只关闭一格工程合同，不支持正式 M5 或 Phase 2 PASS。
