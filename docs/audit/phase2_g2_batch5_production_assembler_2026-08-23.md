# Phase 2 G2 Batch5 生产遭遇装配入口审计

## 结论

G2 Batch5 已完成 `Phase0aProductionFlowAssembler.assembleEncounter` 的实现、集成与独立复审，可进入 READY。动态 encounter runtime 现已能显式复用生产快照工厂、真实伤害 adapter 和 caller 唯一 RNG，但本批主动未切换任何 production host 或关卡数据。

## 交付内容

- D07：新增显式 `assembleEncounter`，参数为 initial state/director/roster/combatants/move bindings/numbers/caller RNG/player+enemy adapters/可选 observer。
- expected actor IDs 固定为玩家 + roster 全部敌人，而不是当前 active 子集；missing/extra、playerId 和 move bindings 在首拍前 fail closed。
- 只创建一个 `Phase0aDamageCalculatorAdapter` 和一个初始 `Phase0aCombatSession`；同一 resolver 同时接普通与 enemy-skill damage，同一 caller RNG 跨敌人/拍连续消费。
- D08：新增真实 `AttackTokenObserveOnlyObserver` 五拍组合回归，锁定 warning → entered → grace → graceExpired/首次攻击，以及 runtime 每拍 fork 保留原 observer identity。
- D08 逐拍对比有/无 observer 的 events/state/outcome/ordered records/spawn state，并精确验证两次真实命中的四次 RNG roll 与尾值一致。

## 模型派单与异常处置

- Pi + DeepSeek `deepseek-v4-flash` 完成 D07，实现 `26353882`，READY `cf91c73f`，集成为 `68cd0c4d`。
- Qoder CLI + `Qwen3.8-Max` 原计划完成 D08；两次非交互调用分别持续约 4 分 35 秒和 5 分 10 秒，均无输出且零文件改动，主控安全取消。
- D08 改由 Codex 子 agent 接管，实现 `2b93beb1`，READY `cbb1147e`，集成为 `07b04075`。
- D07 和整体 Batch5 均经两路独立 Codex 复审，结论为 READY，0 P0 / 0 P1。

## 验证

- D07/D08 与相邻 runtime/session/observer/token 定向集：84/84 通过（独立复审环境）。
- assembler、dynamic encounter、spawn/roster、legacy wave、headless、retry、mainline 和 battle screen 集成回归：193/193 通过（主控集成态）。
- application/domain phase0a 和改动测试 scoped analyze：0 issues。
- `git diff --check`：通过。
- 全仓 analyze 的非 `tools/phase0minus_probe` 诊断文件集为空；既存工具包仍缺自身 package/Flame 依赖，与 Batch5 无关。

## 边界与下一步

本 READY 不代表黑风岭 production 宿主已切换，不代表 attack token 已 enforce，也不代表伏击 objective、入口预警表现、encounter loader 或 tuning 已完成。主线宿主仍显式调 legacy `assemble`。

下一批应先建 host-ready 的 typed encounter mapping、从全量 combatants 构造的 visual roster 工厂，以及显式 `legacy | migrated` resolver 合同。在伏击 objective、token enforce 和可读入场预警未冻结前，不能切 production host；也不能猜测黑风岭总量、活跃上限、补兵阈值、入口、山匪配比或 token 语义。

## 已登记非阻断债务

- legacy/encounter 两个 assembler 入口各保留一段 factory → adapter → session 重复组合，当前参数对齐且无行为分叉；后续可在不扩大生产改动时抽私有 helper。
- runtime 的局部状态 rollback 无法回滚 caller `Random` 已消费的序列；若 resolver 消费 RNG 后本拍后续异常，重试可能漂移。本批不扩大到可回滚 RNG 架构，后续应以显式设计任务处理。
