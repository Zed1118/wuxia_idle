# Phase 2 U10 事实性失败与新增伤势展示收口审计

## 结论

`P2-M6-U10-FACTUAL-FAILURE-INJURY-DISPLAY` 固定验收门已由 `4/7` 提升为 `7/7`，状态 `ready_reviewed`。本门关闭 U10，但 U09 仍因 durable reward receipt/outbox 需 schema/共享真相源授权而 `BLOCKED`，U14、M6 与 Phase 2 仍开放；顶层 M0–M9 仍 `1/10`。

- branch: `codex/phase2-u10-factual-failure-injury-display-20260825`
- base: `38a61a0b`
- code candidate: `ac34d50b`

## 七内容矩阵

| 内容 | 事实 owner | 展示结果 | 验收 |
| --- | --- | --- | --- |
| mainline | shared stage settlement / Boss loss entries | 放弃重试后显示 actual participant 与本次新增伤势；Boss 保留散功事实 | PASS |
| tower | `applyTowerCombatResolution` | 共享战斗账本落库后显示 actual participant 与本次新增轻/重伤 | PASS |
| innerDemon | 既有 inner-demon failure owner | 只显示角色与内息紊乱，不冒称物理伤势/修炼度回退 | PASS |
| expedition | `ExpeditionService.recall` | 独立返程行记显示主动召回/战败、实际参与者与伤势 | PASS |
| gauntlet | `GauntletService.settleDefeat` | 独立战败屏显示已破精英与逐参与者轻/重伤 | PASS |
| lightFoot | shared stage settlement | 逐次选人的 exact participant 与本次新增伤势 | PASS |
| massBattle | shared stage settlement | 逐次选人的 exact participant 与本次新增伤势 | PASS |

## 关键语义

- 伤势展示只使用结算前后 `injuryHoursRemaining` / `lightInjuryStacks` 差分；入场前既有伤势不计为本次。
- 同次同时新增轻伤与重伤时两者均显示，不二选一丢事实。
- 参与者不匹配、消失或 settlement 不完整时延续既有 fail-closed，不回退其他角色。
- 重试框删除“换装备/先历练”建议型文案；源码守卫确认该文案和标识符出现次数为 0。
- 没有新建统一完成报告；断魂庄与远征继续各自的专用摘要。

## 验证

- 初始 RED：`0/4`（缺 before/after 伤势合同、塔 fact presenter，建议文案仍渲染）。
- 定向失败/伤势测试：`24/24 PASS`。
- 主线+塔展示域：`213/213 PASS`。
- 七内容失败/伤势相关域：`551/551 PASS`。
- `flutter analyze --no-pub lib test`：0 issue。
- `git diff --check`：0 issue。
- 建议型重试文案源码出现：0。
- 未重跑既知约 5 小时的整仓全量，不冒称全量全绿。

## 非变更边界

零伤势数值、FailurePolicy 权重、schema/saveVersion、YAML、TUNING/candidate、奖励、经济、解锁、战斗规则或 main 变更。
