# P2 M5 断魂庄持久差遣 Owner

## 结果合同

- 单一目标：把已首通断魂庄的自动入口从同步 `direct + headless + replay` 升为可恢复的 `dispatch + playerBot + headless + offlineResume`，关闭 M5 矩阵第 40/42 格。
- 基线：`72b0190320177ebb5ce9e6dfd80db10f42d11624`，分支 `codex/p2-m5-gauntlet-durable-owner-20260901`。
- 生产边界：继续复用 `BossGauntletRun`、`GauntletService`、Phase 0A runner、`chooseReward`/`settleDefeat`；统一 `DurableActivityCombatRun` 只增加 gauntlet kind 与可恢复 receipt，不创建第二套战斗或奖励 owner。
- 原子边界：扣帖、托管补给、Boss 会话和 durable run 同事务创建；胜负终局与 durable receipt 同事务提交。胜利只停到既有三选一，绝不自动选奖。
- 身份边界：durable run 持久保存 exact participant、创建时间、姓名和装备/心法预留；恢复时与 Boss 会话、当前角色和 canonical request 逐项复核，禁止猜人或换装。
- 兼容边界：复用现有 collection 字段，`DurableActivityKind` 以 name 落库；不提升 schemaVersion/saveVersion，不改奖励、数值、概率、解锁、周目、战斗规则、玩家属性、YAML 或 `strings.dart`。
- 验证门：真实 RED、双向破坏证红、断魂庄/activity/UI 定向、analyze、整仓 format、锁保护全量、exact-tip receipt 与 Gate；真人桌面/视觉继续挂账。

## 切片

1. 先写 exact dispatch allowlist、原子双 run、恢复身份和胜负 receipt RED。
2. 扩展 durable kind 与所有穷尽分支，保持轻功/守城/塔原合同不变。
3. 接入断魂庄生产整备入口与恢复卡；首通仍真人，已首通才显示差遣。
4. 验证胜利保留三选一、战败不发最终奖励、重放不重复结算。
5. 完成破坏证红、整仓验证、审计与 READY；不合并、不 push，等待用户授权。

## 当前恢复点

- 状态：只读生产审计完成，准备写 RED。
- 已确认缺口：现有快速推演请求不进入 durable receipt；战败后 Boss 会话删除，统一差遣恢复口没有事实可读。
- 阻塞：无；用户已授权无人值守推进与所需本地工程决策，范围仍受本结果合同约束。
