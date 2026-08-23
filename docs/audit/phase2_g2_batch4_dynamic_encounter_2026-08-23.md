# Phase 2 G2 Batch4 真实动态遭遇运行时审计

## 结论

G2 Batch4 已完成真实 `Phase0aEncounterFlow.runtime` 的集成、主控修正和独立复审，可进入 READY。运行时只使用当前 `Phase0aCombatSession -> reducePhase0aTick` 结算核，由 `SpawnDirector` 确定性驱动预警、入场、攻击宽限、离场与下拍补兵。

## 交付内容

- D05：session 无副作用 fork 和逐 intent grace gate；每拍原子更新 state/gate，保留 adapters、resolvers、observer 与 RNG 所有权。wave transition 不再丢失 observe-only observer。
- D06：immutable encounter roster 和 warning/entered/grace-expired `Phase0aEvent` 投影；对 identity、ID、side、存活、tick 与 payload 不一致均 fail closed。
- E03：runtime 每拍仅推进 director 一次，先预留 spawn seq，再组装 active-only arena 和 grace gate，最后调用唯一 session/reducer。击败只驱动 exit，补兵最早下拍。
- 终局：`player death > surviveTicks > defeat-all` 优先级固化；spawn/combat/terminal 共用严格连续 seq，终局后幂等空返回。

## 主控修正

- 将 enemy intent gate 从可任意重写整个列表收窄为 `allows(intent)` 谓词，由 session 构造稳定不可变子序列。
- 增加 state + gate 原子 fork，保持其他依赖 identity。
- spawn event adapter 拒绝已知 entry 搭配错误 enemyId；roster 拒绝 playerId 内任何空白。
- runtime 构造增加玩家/敌人阵营和 active 敌人存活校验；补齐 warning、实际宽限伤害、survive/死亡优先级、terminal seq 和终局幂等直接测试。

## 模型派单与复审

- Pi + DeepSeek `deepseek-v4-flash` 完成 D05，最终 READY `cef3bf60`。
- Qoder CLI + `Qwen3.8-Max` 完成 D06，最终 READY `c770f74c`。
- Codex 子 agent 完成 E03，最终 READY `00e0d628`；主控在集成分支补强为 `39b4bbf9`。
- 两路独立 Codex 终审均给出 READY，0 P0 / 0 P1；留下 1 项不阻断 P2：后续补 runtime + AttackToken observer 连续两拍组合回归。

## 验证

- 动态 encounter、D05/D06 合同、director/roster/token-observer 定向集：120/120 通过。
- production assembler、retry、mainline wiring 和 battle screen 回归：60/60 通过。
- 合计：180/180 通过。
- application phase0a、domain phase0a 与 dynamic-flow 测试范围 `dart analyze`：0 issues。
- `git diff --check`：通过。
- 全仓 `flutter analyze --no-pub` 因独立 `tools/phase0minus_probe` 包未解析其自身 package/Flame 依赖而失败；错误全部位于本批未修改的该工具目录，不归因于 Batch4。

## 边界与下一步

本 READY 代表真实动态 runtime 合同已成立，不代表 production assembler 已装配它，也不代表黑风岭关卡数据、tuning、UI 预警、奖励或存档纵切已完成。`AttackTokenDirector` 仍只 observe-only，未 enforce。

下一批应为 `Phase0aProductionFlowAssembler` 增加显式 encounter 装配入口，复用完整 actor 快照和当前 resolver/RNG 依赖；在关卡数据合同冻结前，不自行猜测黑风岭生产数据或 token 语义。
