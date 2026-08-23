# P2 G2 Batch4：真实动态 Encounter Flow

## 目标

从 READY `61b7bb85` 出发，把 `Phase0aEncounterFlow` 从 legacy compatibility wrapper 推进为真实动态遭遇运行时：由 `SpawnDirector` 驱动预警、入场、攻击宽限、离场与补兵，所有战斗结算仍只走当前 `Phase0aCombatSession -> reducePhase0aTick`。

## 并行切片

1. D05（Pi + DeepSeek `deepseek-v4-flash`）：增加 session 安全 fork 和显式 enemy-intent gate，修复 wave transition 丢失 observe-only observer 的回归。
2. D06（Qoder CLI + `Qwen3.8-Max`）：建立 immutable encounter roster 和 spawn warning/entered/grace-expired 的 `Phase0aEvent` 投影。
3. E03（Codex 子 agent）：在 D05/D06 复审集成后实现真实 runtime，补 controller/headless sync/async 生产消费证据。

## 冻结的逐拍语义

1. 终局后 `advance` 返回空，不调 director/session/AI/resolver。
2. director 每拍在 reducer 前仅 `advance()` 一次；director `nextTick` 与本次 reducer 的 combat tick 相同。
3. warning/entered/grace-expired 事件在 reducer 前预留 seq，排在本拍 combat events 之前。
4. `entered` 敌人在本拍 reducer 前加入 arena；宽限期可移动，但普攻和 enemy skill intents 必须被显式 grace gate 拒绝。
5. 仅本拍 reducer 发出的 `Phase0aEnemyDefeated` 可把对应 entry `markExited`；补兵最早发生在下一拍。
6. 终局优先级：玩家死亡 defeat > survive 达成 > defeat-all 的 pending/warning/active 全空 victory > ongoing。
7. compatibility 构造器保留，但真实 runtime 不委托 wave flow，不创建第二 reducer/headless 内核。

## 验收 checklist

- [x] roster 全覆盖、ID/side/player 冲突、不可变与输入顺序无关。
- [x] session fork 保留 adapters/resolvers/observer，不额外创建 RNG。
- [x] 默认 session 路径与 Batch3 parity，wave 换波后 observer 仍工作。
- [x] warning → entered → graceExpired 事件 tick/seq 严格有序。
- [x] grace 敌人可移动不可攻击，到期边界首拍恢复进攻。
- [x] death → exit → next-tick reinforcement 计数守恒，arena 不含 pending/warning/removed actor。
- [x] spawn/combat/terminal 事件共用严格递增 seq，event records 可投影。
- [x] victory/defeat/survive/同拍优先级/终局幂等覆盖。
- [x] controller 和 headless sync/async 消费同一 runtime，同 seed/同 commands 结果一致。
- [x] AttackTokenDirector 仍为 observe-only，不猜 request kind/offscreen/highImpact/telegraph。
- [x] 不改 tuning、生产关卡数据、UI、奖励、伤势、存档或中文文案。
- [x] 主控逐 diff 复审，180 项集成回归、本批范围 analyze 与 `git diff --check` 通过，两路独立复审 0 P0/P1。

## 当前恢复点

- 状态：D05/D06/E03 实现、主控修正、集成回归与两路独立复审已完成，等待 Batch4 READY tip。
- 最后完成：主控验收补强 `39b4bbf9`；180/180 回归通过，本批范围 analyze 0 issues。
- 下一步：封签 Batch4 READY；后续批次建立 production assembler 的 encounter 装配入口，不猜测黑风岭数据。
- 阻塞项：无；全仓 analyze 被独立 `tools/phase0minus_probe` 包的既存依赖缺失污染，与本批无关。token enforce 与关卡 tuning 仍不在本批范围。
