# Phase 2 U14 特殊模式允许矩阵与地点入口全状态路由阻塞审计

## 结论

`P2-M6-U14-SPECIAL-MODE-MATRIX-AND-ROUTE-STATES` 固定验收门保持 `0/1 BLOCKED`。心魔 manual-only、九霄塔首通后 headless admission 与入口全状态路由子门均已完成；轻功和守城仍缺含 durable 差遣的完整 production admission。路由证据不能替代两条缺失生产路径。

- branch: `codex/phase2-u14-special-mode-matrix-requalified-blocked-2modes-20260825`
- base: `eb247d7f72610534f39b6ca5281b044252d2bc34`
- requalified base: `d9801ef48d725d25ea9b626b272abb5f44cc34a1`
- 顶层 M0–M9：仍 `1/10`
- M6 / U14 / Phase 2：仍开放

## 六模式生产矩阵审计

| 模式 | typed request 生产消费者 | 独立 admission/policy | 当前可证明路径 | U14 结论 |
| --- | --- | --- | --- | --- |
| 九霄塔 | 有 | `TowerAutomationPolicy` + `TowerAutomationAdmissionService` | 已首通层 typed headless 经玩家可达 sweep runner、共享结算与实际参与者回顾 | 塔 automation 子门 READY |
| 轻功 | 无 | 无 | 逐次选人手动亲战；即时 headless 技术可复用 | 缺 durable 差遣/session/occupancy/offline/report owner |
| 守城 | 无 | 无 | 逐次选人手动亲战；即时 headless 技术可复用 | 缺 durable 差遣/session/阵型/occupancy/offline/report owner |
| 心魔 | 有 | `InnerDemonParticipationPolicy` | 角色面板目标本人 direct + human + realtime 首通/重打 | manual-only 子门已 READY，其他组合全拒绝 |
| 断魂庄 | 有 | `GauntletAutomationPolicy` | 手动亲战；完整首通后 headless replay | 已有局部门，但不是六模式矩阵 |
| 百草岭 | 有 | `ExpeditionService` 内 exact tuple 断言 | typed dispatch + headless/offline | 已有局部门，但不是六模式矩阵 |

冻结方案要求分别表达 `dispatchAllowed`、`offlineAdvanceAllowed`、`realtimeBotAllowed`、`headlessReplayAllowed`、`sweepAllowed`。当前已有四类 typed production consumer，但轻功、守城完整允许项仍未实现。U14 是测试/验收门，不能代替缺失的 M5/M6 production admission，也不能把塔的 sweep 许可外推为差遣许可。

## 地点/入口状态审计

- 九霄塔：开放、登顶重打、provider error、原门禁路由已有测试；零 eligible 的生产禁用已有独立 widget 回归。
- 轻功：锁定、开放、全通重打、零 eligible、provider error、掌门闭关而空闲门人可进均已有测试。
- 守城：锁定、开放、全通重打、provider error、闭关门禁已有测试；零 eligible 的生产禁用已有独立 widget 回归。
- 断魂庄：隐藏/开放/active/provider error/原整备路由已有测试；idle 且 `availableCandidateCount == 0` 时 CTA 禁用，active 会话即使当前候选为零仍可恢复。
- 百草岭：隐藏/开放/active/defeated/provider error/原总览路由已有测试；idle 且 `availableCandidateCount == 0` 时 CTA 禁用，active 会话即使当前候选为零仍可恢复。
- 心魔按冻结规则不在江湖地图，角色突破页是唯一入口；本人首通/重打与替代/差遣/bot/headless/扫荡/离线恢复已有 typed admission 穷举证据。

五地点 `zero-eligible` 路由子门现已达到 `5/5`，但它本身不能解除六模式生产矩阵缺失。

入口异步边界已达到 `12/12`：五地点 loading/error 时地图 CTA 均禁用且回调置空，心魔 loading/error 时角色入口隐藏。结合上述既有证据，适用的 `loading/hidden/locked/open/active/complete/error/zero-eligible` 路由子门已关闭，但仍不代表六模式 automation 矩阵通过。

## 验证证据

以下现有回归合计 `96/96 PASS`：

- `ActivityParticipationRequest` 值对象合同；
- 断魂庄 automation policy 与 admission；
- 百草岭真实 typed dispatch 合同；
- 心魔 manual-only typed admission 穷举合同；
- `test/features/jianghu_map/presentation` 全目录。

该结果只证明当时已有局部门未回归，不等于 U14 通过。九霄塔本轮另有定向 `18/18`、塔+sweep `177/177`、相邻域 `22/22`、truth guard `9/9` 与 analyze 0 的 READY 证据。

入口全状态路由集合另有 `117/117 PASS`，江湖地图、角色面板与心魔相邻域 `256/256 PASS`。

## 解阻顺序

1. 获得 schema/saveVersion/共享 occupancy 授权，为轻功建立含 durable 差遣的 bot/headless/dispatch production admission；或明确移除其差遣分母。
2. 同标准为守城建立含阵型快照的完整 admission；不得沿用运行时默认阵型。
3. 六模式真实消费者齐备后，把现有全状态路由证据与真实允许矩阵合并复核，关闭 U14。

## 非变更边界

本审计未新增 reducer、session、headless 内核、provider、settlement 真相源，未改 schema/saveVersion、YAML、TUNING、奖励、经济、解锁、叙事、战斗规则或 main。
