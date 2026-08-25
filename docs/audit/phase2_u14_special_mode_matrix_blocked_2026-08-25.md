# Phase 2 U14 特殊模式允许矩阵与地点入口全状态路由阻塞审计

## 结论

`P2-M6-U14-SPECIAL-MODE-MATRIX-AND-ROUTE-STATES` 固定验收门保持 `0/1`，状态 `BLOCKED`。地点详情已经覆盖多项锁定、开放、进行中、完成和 provider error 的生产路由，但六模式允许矩阵没有六条真实 production admission 可供统一验证；新增孤立 policy 表或只测 enum 会制造假闭环。

- branch: `codex/phase2-u14-special-mode-matrix-blocked-audit-20260825`
- base: `eb247d7f72610534f39b6ca5281b044252d2bc34`
- 顶层 M0–M9：仍 `1/10`
- M6 / U14 / Phase 2：仍开放

## 六模式生产矩阵审计

| 模式 | typed request 生产消费者 | 独立 admission/policy | 当前可证明路径 | U14 结论 |
| --- | --- | --- | --- | --- |
| 九霄塔 | 无 | 无 | 逐次选人手动亲战 | 缺首通后 bot/headless/差遣 production admission |
| 轻功 | 无 | 无 | 逐次选人手动亲战 | 缺首通后 bot/headless/差遣 production admission |
| 守城 | 无 | 无 | 逐次选人手动亲战 | 缺首通后 bot/headless/差遣 production admission |
| 心魔 | 无 | 无 | 本人手动入口 | 缺 typed manual-only admission，无法穷举拒绝替代/差遣/扫荡 |
| 断魂庄 | 有 | `GauntletAutomationPolicy` | 手动亲战；完整首通后 headless replay | 已有局部门，但不是六模式矩阵 |
| 百草岭 | 有 | `ExpeditionService` 内 exact tuple 断言 | typed dispatch + headless/offline | 已有局部门，但不是六模式矩阵 |

冻结方案要求分别表达 `dispatchAllowed`、`offlineAdvanceAllowed`、`realtimeBotAllowed`、`headlessReplayAllowed`、`sweepAllowed`。当前生产没有一份被六模式真实入口消费的合同，也没有可证明塔、轻功、守城允许项已实现的 runner/admission。U14 是测试/验收门，不能代替缺失的 M5/M6 生产纵切。

## 地点/入口状态审计

- 九霄塔：开放、登顶重打、provider error、原门禁路由已有测试；零 eligible 的生产禁用逻辑存在，但缺独立 widget 回归。
- 轻功：锁定、开放、全通重打、零 eligible、provider error、掌门闭关而空闲门人可进均已有测试。
- 守城：锁定、开放、全通重打、provider error、闭关门禁已有测试；零 eligible 的生产禁用逻辑存在，但缺独立 widget 回归。
- 断魂庄：隐藏/开放/active/provider error/原整备路由已有测试；idle 且 `availableCandidateCount == 0` 时详情 CTA 当前没有显式禁用。
- 百草岭：隐藏/开放/active/defeated/provider error/原总览路由已有测试；idle 且 `availableCandidateCount == 0` 时详情 CTA 当前没有显式禁用。
- 心魔按冻结规则不在江湖地图，角色突破页是唯一入口；其本人/替代/差遣/扫荡全状态尚无 typed admission 矩阵。

这些地点侧缺口可以在相应生产 admission 建立后一次补齐，但它们本身不能解除六模式生产矩阵缺失。

## 验证证据

以下现有回归合计 `90/90 PASS`：

- `ActivityParticipationRequest` 值对象合同；
- 断魂庄 automation policy 与 admission；
- 百草岭真实 typed dispatch 合同；
- `test/features/jianghu_map/presentation` 全目录。

该结果只证明现有局部门未回归，不等于 U14 通过。

## 解阻顺序

1. 塔：每层首通门槛后的 visible bot/headless/当值或差遣 production admission。
2. 轻功、守城：每路线/关首通后的 bot/headless/差遣 production admission。
3. 心魔：本人 direct + human + realtime + manual-only typed admission，其他组合全拒绝。
4. 在六模式真实消费者齐备后，新增穷举矩阵和 loading/hidden/locked/open/active/complete/error/zero-eligible 路由回归，关闭 U14。

## 非变更边界

本审计未新增 reducer、session、headless 内核、provider、settlement 真相源，未改 schema/saveVersion、YAML、TUNING、奖励、经济、解锁、叙事、战斗规则或 main。
