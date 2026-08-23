# P2 G2 Batch5：Production Encounter Assembler

## 目标

从 READY `21e17ecc` 出发，为 `Phase0aProductionFlowAssembler` 增加显式 `assembleEncounter` 入口，将 Batch4 动态 runtime 接入已有生产快照、真实伤害 resolver 和单一 RNG 所有权。本批只建装配入口，不切换主线宿主，不猜黑风岭 encounter 数据。

## 切片

1. D07（Pi + DeepSeek `deepseek-v4-flash`）：实现 `assembleEncounter`，复用 snapshot factory / damage adapter / caller RNG，保留 legacy `assemble` 行为与返回类型。
2. D08（Qoder CLI + `Qwen3.8-Max`）：在 D07 集成后补 runtime + observe-only observer 连续多拍组合回归，证明 grace gate 与每拍 fork 不丢 observer。
3. Codex 主控/独立 agent：冻结结构校验顺序，复审真实 resolver/RNG 穿透与回归，不提前进入 content loader 或 host routing。

## 冻结合同

- `assembleEncounter` 显式接收 `initialState` / `director` / `roster` / `combatants` / `moveBindings` / `numbers` / `rng` / player+enemy adapters，以及可选 observe-only enemy-intent observer。
- expected actor IDs = `initialState.player.id` + roster 全部 enemy IDs；missing/extra 稳定排序后 fail closed。
- player adapter ID 和 move binding 校验复用既有口径，不复制伤害或数值逻辑。
- 只创建一个 `Phase0aDamageCalculatorAdapter` 和一个 `Phase0aCombatSession`；同一 caller RNG 跨所有敌人和拍连续消费。
- runtime 构造继续负责 director/roster identity、tick、active arena 和 side/alive 的 fail-closed 校验。
- legacy `assemble` 签名、返回类型、默认路径、两波 RNG 连续性和主线路由均不改。

## 验收 checklist

- [ ] encounter 全 actor 真实快照覆盖，missing/extra/playerId/move-binding 异常在首拍前失败。
- [ ] 真实 damage adapter 产生的伤害与 direct adapter 同 seed 对齐，RNG 不按敌人或拍重置。
- [ ] warning/entry/grace/kill/reinforcement/terminal 通过 assembler 入口完成，不只测手工 session fixture。
- [ ] observe-only observer 连续多拍存活，只观察 grace gate 后 intents，不改 events/state/RNG。
- [ ] existing assembler、wave、headless、retry、mainline 回归继续通过。
- [ ] 不改 mapper/stage data/host routing/tuning/UI/reward/injury/save。
- [ ] 主控 diff 复审、targeted tests、scoped analyze、`git diff --check` 与独立审查通过。

## 当前恢复点

- 状态：D07 已交付 READY 并集成；D08 已派给 Qoder CLI + `Qwen3.8-Max`。
- 最后完成：D07 外部 READY `cf91c73f`，集成提交 `68cd0c4d`；主控定向集 57/57 通过。
- 下一步：回收 D08，对 D07/D08 做独立复审和生产回归。
- 阻塞项：无；content loader 和黑风岭 tuning 未进入本批。
