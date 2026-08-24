# P2 M2/M6 U01 第一章持久结算恢复收口记录

- 日期：2026-08-24
- 分支：`codex/phase2-m2-m6-u01-durable-settlement-20260824`
- 基线：`d134f68d6b3f5a239554a33df5970d26a8a3a7ee`
- 代码候选：`9712bdc9da01d41df892fd2134b17ce28d77e244`
- 范围：仅第一章连续首通的持久权威结算与崩溃恢复，不代表 U01、M2、M6 或二阶段整体完成。

## 生产合同

1. 存档 schema 从 `0.39.0` 加法迁移至 `0.40.0`；旧档不伪造 active journal，未来版本仍 fail closed。
2. 专用 `MainlineSettlementJournal`/outbox 以 `runId + stageId + loadoutVersion + participantId` 作为 canonical 持久身份，每存档只允许一个 active journal。
3. 进关前写入 `prepared`；若权威结算前崩溃，重启只恢复同一关、同一参与者与完整版本化装配快照。
4. 权威核心写入与 `coreApplied` receipt 同一 Isar 事务提交；任一写入失败时整体回滚，不留虚假 receipt。
5. `coreApplied` 后的“返回江湖/进入下一关”先持久化再导航。下一关准备在同一事务内关闭旧 receipt 并创建新 `prepared`，强制同 run/同参与者、快照版本 `+1` 且历史前缀一致。

## 权威事务写入

本切片在同一核心事务内落库：角色成长与伤势、装备掉落/归属、心法/残页获得、主线进度、教程事实、技能真解、Boss 战绩、兵器图鉴、奇遇击杀计数、确定性章末声望变化及 journal receipt。为复用现有真相源，相关 service 只新增 transaction-owned 变体，未新建第二套 reducer、session、headless 内核或奖励账本。

## 恢复矩阵

| 持久状态 | 重启行为 | 去重保证 |
| --- | --- | --- |
| 无 active journal | 按既有入口开始新 run | 不伪造 receipt |
| `prepared` | 同关、同人、同版本快照重试 | 权威结算尚未发布 |
| `coreApplied` + 无动作 | 显示事实性恢复提示并恢复结算后选择 | 不重放成长、伤势、掉落、进度 |
| `coreApplied` + 返回 | 返回地图并关闭 journal | 动作重放幂等 |
| `coreApplied` + 下一关 | 原子交接为下一关 `prepared` | 旧 receipt 关闭与新准备不留窗口 |
| `closed` | 无恢复动作 | 不再消费 effect |

## 验证证据

- journal/run/事务状态机：`44/44 PASS`
- 生产 Isar 接线与恢复对话框：`2/2 PASS`
- 受影响 service 回归：`57/57 PASS`
- `test/features/mainline`：`387/387 PASS`
- `flutter analyze --no-pub lib test tool`：`0 issues`
- `flutter test --no-pub --no-test-assets`：`5295/5295 PASS`
- 独立语义复核：`P0/P1 = 0`

## 明确未关闭边界

- 互动奇遇与招降回调仍是即时路径，崩溃后不会伪造选择；它们属于 U04 持久待处理江湖事队列的后续工作。
- 随行听剑的生产占用/成长接线与仍为 `TUNING` 的比例/cap 未处理。
- replay/manual/auto/headless/扫荡的参与者、记录、成长、伤势与奖励一致性未由本批验收。
- U05 四入口、M2/M6 其余任务与二阶段其他里程碑仍开放。
- 未改奖励数值/概率、解锁表、叙事、20 项 `TUNE-*`、听剑比例/cap、七心魔 AI 或其他候选调优；未修改、合并或 push `main`/`origin/main`。
