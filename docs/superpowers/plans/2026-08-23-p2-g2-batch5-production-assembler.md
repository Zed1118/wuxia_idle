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

- [x] encounter 全 actor 真实快照覆盖，missing/extra/playerId/move-binding 异常在首拍前失败。
- [x] 真实 damage adapter 产生的伤害与 direct adapter 同 seed 对齐，RNG 不按敌人或拍重置。
- [x] warning/entry/grace/kill/reinforcement/terminal 通过 assembler 入口完成，不只测手工 session fixture。
- [x] observe-only observer 连续多拍存活，只观察 grace gate 后 intents，不改 events/state/RNG。
- [x] existing assembler、wave、headless、retry、mainline 回归继续通过。
- [x] 不改 mapper/stage data/host routing/tuning/UI/reward/injury/save。
- [x] 主控 diff 复审、193 项集成回归、scoped analyze、`git diff --check` 与两路独立审查通过。

## 当前恢复点

- 状态：D07/D08 实现、集成、主控回归与两路独立终审已完成，等待 Batch5 READY tip。
- 最后完成：D07 集成 `68cd0c4d`，D08 集成 `07b04075`；193/193 回归、范围 analyze 0 issues。
- 下一步：封签 Batch5 READY；后续先建 encounter mapping / visual roster / migration resolver 的 host-ready 合同，不在 objective、token enforce 和预警表现未冻结时切 production host。
- 阻塞项：无；全仓 analyze 仍只被独立 `tools/phase0minus_probe` 依赖基线污染。content loader 和黑风岭 tuning 未进入本批。
