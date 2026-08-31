# Phase 2 M5 六模式工程集成审计

日期：2026-09-01

原审计基线：`22afa6d3831b4dfb0d20df7d6694f6f7c13ff968`

本轮复核实现：`9a861386344e868428abb5fb101bd794c3c795dc`

任务：`P2-M5-ENGINEERING-INTEGRATION-AUDIT`

## 结论

M5 不能从历史纵切 READY 或已经关闭的 M6 工程接线直接推导为完成。按二阶段方案 M5 的六模式 × 七项合同重新建立固定分母后，本轮轻功、守城自动化矩阵候选把工程证据由 `34/42` 推至 `36/42`，仍有 `6/42 BLOCKED`，因此顶层 M5 工程 Gate 保持 `0/1 BLOCKED`。

轻功与守城现在只在已首通后开放三条精确通道：可见 `direct + playerBot + realtime + replay`、快速推演 `direct + playerBot + headless + replay`、既有差遣 `dispatch + playerBot + headless + offlineResume`。它们复用真实 Host、headless runner、durable receipt 与共享 settlement；首通仍为人控。其余缺口涉及个人记录持久作用域、尚未实现的 durable owner 和百草岭首次关键节点手动接管，不能由本批外推。

## 42 格生产映射

| 模式 | production entry | 首通门槛 | 自动解锁 | 奖励 | 伤势/失败 | 记录 | 离线/差遣允许矩阵 | 小计 |
|---|---|---|---|---|---|---|---|---:|
| 九霄塔 | PASS `TowerFloorListScreen → runTowerFlow` | PASS `TowerProgressService` 每层首通 | PASS `TowerAutomationAdmissionService` 已通层 sweep | PASS `applyTowerVictoryResolution` + `RewardClaimReceipt` | PASS exact participant 共享结算 | **BLOCKED** 只有存档级 `TowerProgress`，缺每角色塔层记录 | **BLOCKED** 只有已通层 sweep，缺方案中的当值/差遣通道 | 5/7 |
| 轻功 | PASS `LightFootScreen → runStageFlow` | PASS `LightFootService` 路线链 | PASS 已通路线 durable dispatch | PASS 共享 stage/durable receipt | PASS 通用伤势归 exact participant | PASS `MainlineProgress` 路线通关 + 个人战斗账本 | PASS 已首通后三通道精确接入前台 bot、即时 headless 与既有差遣 | 7/7 |
| 守城 | PASS `MassBattleScreen → runStageFlow` | PASS `MassBattleService` 关卡链 | PASS 已通关 durable dispatch | PASS 共享 stage/durable receipt | PASS 通用伤势归 exact participant | PASS `MainlineProgress` 守城通关 + 个人战斗账本 | PASS 已首通后三通道精确接入；headless 持久化本次阵型 | 7/7 |
| 心魔 | PASS 角色突破页本人进入 `InnerDemonScreen` | PASS 每次均本人手动 | PASS 自动化全禁的 fail-closed 策略 | PASS personal-scope receipt | PASS 只结内息紊乱、无物理伤势 | **BLOCKED** `InnerDemonProgress` 明确使用全局 `MainlineProgress.clearedStageIds`，不是个人心境进度 | PASS direct + human + realtime，其他组合全拒绝 | 6/7 |
| 断魂庄 | PASS `GauntletLoadoutScreen → GauntletService` | PASS 首次完整通关手动 | PASS 完整首通后 headless replay | PASS `chooseReward` 原子奖励与 receipt | PASS 会话末统一伤势/部分收益 | PASS durable run、通关事实与战报 | **BLOCKED** 已有 direct headless replay，但方案中的完整首通后差遣没有 durable owner | 6/7 |
| 百草岭 | PASS `ExpeditionOverviewScreen → ExpeditionService.dispatchRequest` | **BLOCKED** 普通/险关均由 headless runner 推进，未实现首次关键里程碑手动接管 | **BLOCKED** 没有 `routeId + milestoneId` 的手动已通过记录与后续自动门 | PASS 暂存账本 + return receipt | PASS 实际参与者伤势并保留已完成节点 | PASS durable run、深度、返程报告 | PASS 核心形态为单人 dispatch + headless + offline | 5/7 |

合计：`5 + 7 + 7 + 6 + 6 + 5 = 36/42`。

## 六个真实阻塞

1. 九霄塔缺每角色塔层/最好成绩记录；既有 `TowerProgress` 是每存档单行，旧审计已明确不能拿 Boss 纪念替代。
2. 九霄塔缺首通后的当值/差遣 durable owner；当前只冻结并实现 sweep。
3. 心魔通关事实是存档全局 `clearedStageIds`，未形成角色个人心境进度。
4. 断魂庄缺完整首通后的差遣/离线 durable owner；现有 headless replay 是 direct，不占用真实世界时长。
5. 百草岭没有首次关键里程碑必须手动的接管边界。
6. 百草岭没有 `routeId + milestoneId` 的自动化解锁记录，因而也无法证明“首次手动、以后自动”。

其中 1—4 很可能需要新的或扩展的持久 owner；5、6 还需要生产 UI/恢复状态机与离线遇门自动返程。它们不是本次“集成守卫”可以诚实补齐的测试缺口。

## 已重跑的生产基线

组合命令覆盖 `activity/tower/light_foot/mass_battle/boss_gauntlet/expedition/inner_demon` 全目录，以及共享 `apply_victory_resolution` 和 `stage_entry_flow`：`565/565 PASS`，退出码 0，末行 `All tests passed!`。

本轮轻功/守城候选另完成扩展定向 `82/82 PASS`、破坏证红 `4 + 1 + 2` 条失败并精确还原、`flutter analyze --no-pub lib test tool` 0 issue，以及锁保护整仓全量 `5828/5828 PASS`、`[E]=0`、末行 `All tests passed!`。

这些绿色证据关闭轻功、守城两格，不证明剩余六个不存在的 owner 已完成。

最终工程检查：

- `flutter analyze --no-pub lib test`：0 issue，末行 `No issues found! (ran in 13.5s)`；
- `dart format .`：`1699 files / 0 changed`；
- 锁保护整仓全量：`5822/5822 PASS`，退出码 0，`[E]=0`，末行 `05:02 +5822: All tests passed!`；
- 项目 Gate 必须在最终 `[READY]` 审计 tip 上独立通过后才允许合并。

## 推荐施工顺序

1. 先补个人记录作用域：塔个人层记录与心魔个人进度共用一次版本化加法迁移，先解决“换角色继承个人成就”的事实错误。
2. 再补长时 owner：塔当值/差遣与断魂庄差遣先冻结 durable session/占用/奖励选择边界，再做迁移。
3. 最后补百草岭手动里程碑接管；它跨离线推进、可见战斗、返程报告和恢复，是六项中风险最高的一组。

每批都必须独立分支/worktree、可编译破坏证红、targeted、analyze、format、锁保护全量、Gate、合并 push 与精确 SHA CI。真人桌面和 Windows 实机继续挂账，不能替代工程门，也不被工程门替代。
