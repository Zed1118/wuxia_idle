# P2-M6 断魂庄亲战结算报告闭环计划

## 结果门与基线

- 固定验收门：断魂庄“主菜单 → 江湖地图 → 地点详情 → 选实际参与者 → 三关亲战 → 共享结算 → 胜负报告”从 `WIP 0/1` 变为 `PASS/READY 1/1`。
- 基线：`8671f8920a9e2ef3cd7bf869a047808d0fd742b1`，继承九霄塔实际参与者 clean READY。
- 最大阻塞：当前 Phase 0A 终局只把 HP/真气检查点推进到 `BossGauntletRun`，没有产出/消费 `CombatSettlementSnapshot`，装备战斗次数、招式使用和主修修炼账本未进入共享 `CombatResolutionService`；胜利奖励页也不显示实际参与者。

## 完成定义

1. live controller 与 headless runner 都从同一 Phase 0A mapping、终态和语义事件生成共享 `CombatSettlementSnapshot`。
2. `GauntletService` 在推进关次的同一事务内复核 run 的单一实际参与者，调用 `CombatResolutionService` 并持久化该角色的装备/心法账本；错人、悬空角色或未完成快照 fail closed。
3. 断魂庄继续只在会话末结算伤势、经验、领悟、奖励和补给；逐关共享结算不得重复这些副作用。
4. Boss 胜利奖励页从 active run 与 Character 真表读取并展示实际参与者；悬空身份不猜测、不回退。
5. 生产路由、两视口、定向与相邻域、scoped/root analyze、白名单、一次必要全量和 clean 状态通过。

## 非目标与成本上限

- 不改远征报告、轻功/守城选人、统一归来摘要、每角色塔层最好成绩。
- 不新增 reducer/session/结算源，不改 schema/saveVersion、YAML、数值、奖励、经济、解锁、叙事或 main。
- 预计 45–75 分钟，硬上限 120 分钟；30/60/96 分钟检查 gate 增量。周用量不可直接观测，不伪造百分比。

## 精确白名单

- registry 中本任务 `owned_files` 列表；没有证据需要时不扩展。
