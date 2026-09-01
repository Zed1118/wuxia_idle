# Phase 2 M5 断魂庄持久差遣审计

日期：2026-09-01

任务：`P2-M5-GAUNTLET-DURABLE-OWNER`

基线：`72b0190320177ebb5ce9e6dfd80db10f42d11624`

## 结论

断魂庄原有真实首通和已首通后的 `direct + playerBot + headless + replay`，但快速推演没有中断恢复 owner、统一 occupancy/receipt，也不能证明 exact participant/loadout 在恢复前仍未漂移。

本切片复用既有 `BossGauntletRun` 作为三连战检查点、复用 `DurableActivityCombatRun` 作为调度身份和终局 receipt。真实整备页现提交 `dispatch + playerBot + headless + offlineResume`；扣帖、补给托管、Boss 会话和 durable owner 同事务创建，胜败业务结算与 durable receipt 同事务提交。该工程格由 BLOCKED 形成候选，M5 固定矩阵由 `39/42` 推进到 `40/42`；百草岭两格仍 BLOCKED，顶层 M5 保持 `0/1 BLOCKED`。

## 生产与恢复合同

- `GauntletLoadoutScreen` 保留“完整首通后才开放自动化”的门槛，但生产 CTA 改走 `GauntletService.enterDurableDispatch`，请求绑定本次实际选中的唯一角色和 `gauntlet-plan-<characterId>`。
- `GauntletService` 在同一 Isar 事务内校验首通、exact participant、占用、装配、断魂帖和补给，再创建 `BossGauntletRun` 与伴随 durable row；任一步失败都不留下半条 owner。
- `DurableActivityKind.gauntlet` 只扩展既有 name enum，不新增 collection/字段，不提升 `schemaVersion/saveVersion`。实际角色/装备占用继续以 `BossGauntletRun` 为唯一 owner，durable row 只承载恢复身份与 receipt，避免同一活动自占用。
- 恢复先核对 durable request、Boss run link、角色 `createdAt/name`、冻结装备/心法和其它活动占用；漂移必须在更新 `lastAdvancedAt` 或进入战斗前 fail closed。
- 自动战斗继续复用既有 admission、Phase 0A headless driver、三关边界和结算。胜利只推进到既有三选一，不替玩家选奖；战败仍走既有精英经验、伤势和补给返还。
- 胜利的 Boss 边界写入与 victory receipt 同事务；战败结算、Boss 会话删除和 defeat receipt 同事务。`settlementApplied` 恢复卡展示事实报告或继续既有奖励选择，确认后才 close 并释放 unified durable row。

## 破坏证红

1. 临时让 `enterDurableDispatch` 不创建 durable owner：持久差遣域精确 `4` 条失败。
2. 初次只移除新增装配比较时，用例仍绿，暴露原断言会被更晚的战斗装配解析异常替代，不能证明“执行前拦截”。补强为同时断言 `lastAdvancedAt` 未变化后，再移除守卫精确 `1` 条失败；该假绿已被消除。
3. 临时断开 `_commitDurableDispatchInTxn` 的 Isar 写入：三选一 victory receipt 与战败 defeat receipt 精确 `2` 条失败。
4. 临时断开生产恢复卡的 `_resume` 回调：生产 widget 精确 `1` 条失败。

每次破坏均用精确反向补丁恢复；恢复后的核心生产测试重新通过。

## 当前验证

- policy、durable owner、生产整备/恢复入口：`29/29 PASS`；
- 断魂庄全目录：`199/199 PASS`；
- 共享 activity/occupancy：`20/20 PASS`；
- `flutter analyze --no-pub lib test tool`：`No issues found!`；
- 测试契约迁移：旧“仅一条 direct replay”矩阵和生产 CTA 的 direct/replay 字段迁为“两条精确 allowlist + 生产 durable dispatch”；`expect 删 4 / 增 46，用例删 2 / 增 10，登记 6 条`，专用 Gate `PASS`；
- 锁保护整仓全量、整仓 format 与 exact-tip 项目 Gate 必须在最终候选提交后执行，不在执行前预写 PASS。

## 范围

- 未新增 Isar collection/字段，未提升 schemaVersion/saveVersion；未改玩家数值、技能、奖励、经济、解锁、周目、战斗规则、YAML 或 `strings.dart`。
- 未自动选择三选一奖励，未改变断魂帖和补给消耗，未把旧 direct replay 删除为不可用策略。
- 真人桌面交互、视觉和 Windows 实机继续挂账；本证据只关闭 M5 一格工程合同，不支持正式 M5 或 Phase 2 PASS。
