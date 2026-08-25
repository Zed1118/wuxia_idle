# Phase 2 U14 特殊模式允许矩阵与地点入口全状态路由阻塞审计

## 结论

`P2-M6-U14-SPECIAL-MODE-MATRIX-AND-ROUTE-STATES` 固定验收门保持 `0/1`，状态 `BLOCKED`。心魔本人 manual-only typed admission 已完成，但塔、轻功、守城仍缺玩家可达的自动 runner 与 production admission。地点详情已经覆盖多项锁定、开放、进行中、完成和 provider error 路由，但不能用孤立 policy 表或 enum 测试替代三条缺失的生产路径。

- branch: `codex/phase2-u14-special-mode-matrix-requalified-blocked-audit-20260825`
- base: `eb247d7f72610534f39b6ca5281b044252d2bc34`
- requalified base: `ffbb7e0c`
- 顶层 M0–M9：仍 `1/10`
- M6 / U14 / Phase 2：仍开放

## 六模式生产矩阵审计

| 模式 | typed request 生产消费者 | 独立 admission/policy | 当前可证明路径 | U14 结论 |
| --- | --- | --- | --- | --- |
| 九霄塔 | 无 | 无 | 逐次选人手动亲战 | 缺首通后 bot/headless/差遣 production admission |
| 轻功 | 无 | 无 | 逐次选人手动亲战 | 缺首通后 bot/headless/差遣 production admission |
| 守城 | 无 | 无 | 逐次选人手动亲战 | 缺首通后 bot/headless/差遣 production admission |
| 心魔 | 有 | `InnerDemonParticipationPolicy` | 角色面板目标本人 direct + human + realtime 首通/重打 | manual-only 子门已 READY，其他组合全拒绝 |
| 断魂庄 | 有 | `GauntletAutomationPolicy` | 手动亲战；完整首通后 headless replay | 已有局部门，但不是六模式矩阵 |
| 百草岭 | 有 | `ExpeditionService` 内 exact tuple 断言 | typed dispatch + headless/offline | 已有局部门，但不是六模式矩阵 |

冻结方案要求分别表达 `dispatchAllowed`、`offlineAdvanceAllowed`、`realtimeBotAllowed`、`headlessReplayAllowed`、`sweepAllowed`。当前已有三类 typed production consumer，但仍没有可证明塔、轻功、守城允许项已实现的 runner/admission。U14 是测试/验收门，不能代替缺失的 M5/M6 生产纵切。

## 地点/入口状态审计

- 九霄塔：开放、登顶重打、provider error、原门禁路由已有测试；零 eligible 的生产禁用已有独立 widget 回归。
- 轻功：锁定、开放、全通重打、零 eligible、provider error、掌门闭关而空闲门人可进均已有测试。
- 守城：锁定、开放、全通重打、provider error、闭关门禁已有测试；零 eligible 的生产禁用已有独立 widget 回归。
- 断魂庄：隐藏/开放/active/provider error/原整备路由已有测试；idle 且 `availableCandidateCount == 0` 时 CTA 禁用，active 会话即使当前候选为零仍可恢复。
- 百草岭：隐藏/开放/active/defeated/provider error/原总览路由已有测试；idle 且 `availableCandidateCount == 0` 时 CTA 禁用，active 会话即使当前候选为零仍可恢复。
- 心魔按冻结规则不在江湖地图，角色突破页是唯一入口；本人首通/重打与替代/差遣/bot/headless/扫荡/离线恢复已有 typed admission 穷举证据。

五地点 `zero-eligible` 路由子门现已达到 `5/5`，但它本身不能解除六模式生产矩阵缺失。

## 验证证据

以下现有回归合计 `96/96 PASS`：

- `ActivityParticipationRequest` 值对象合同；
- 断魂庄 automation policy 与 admission；
- 百草岭真实 typed dispatch 合同；
- 心魔 manual-only typed admission 穷举合同；
- `test/features/jianghu_map/presentation` 全目录。

该结果只证明现有局部门未回归，不等于 U14 通过。

## 解阻顺序

1. 获得产品/架构授权后，为塔建立首通后的权威 automation runner 与 production admission。
2. 在同样授权下，为轻功、守城建立 bot/headless/差遣 runner 与 production admission。
3. 六模式真实消费者齐备后，再补齐 loading/hidden/locked/open/active/complete/error/zero-eligible 全状态回归，关闭 U14。

## 非变更边界

本审计未新增 reducer、session、headless 内核、provider、settlement 真相源，未改 schema/saveVersion、YAML、TUNING、奖励、经济、解锁、叙事、战斗规则或 main。
