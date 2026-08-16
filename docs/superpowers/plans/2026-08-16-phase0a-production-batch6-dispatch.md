# Phase 0A 根应用生产化第六批协调计划

## 目标

新增唯一生产装配器，把第五批 `BattleCharacter` 快照工厂、第三批真实伤害 adapter、会话与第四批波次 flow 一次性装配为 `Phase0aWaveBattleFlow`，消除调用方手工接线与延迟到首击才暴露配置错误的问题。

## 已冻结边界

- 装配输入显式包含：`Phase0aArenaState initialState`、`List<Phase0aWave> waves`、`List<Phase0aCombatantInput> combatants`、完整 `moveBindings`、`NumbersConfig`、显式 `Random`、玩家输入 adapter、敌方 AI adapter。
- 只组合既有 `Phase0aBattleSnapshotFactory` → `Phase0aDamageCalculatorAdapter` → `Phase0aCombatSession` → `Phase0aWaveBattleFlow`；不得复制伤害、移动、AI、CD、真气、波次或终局规则。
- 构造期验证全场 actor id 精确覆盖：expected = 首态 player + 所有波次 enemy；combatants 缺失或多余均 fail-fast，错误信息列出稳定排序后的 id。
- `playerAdapter.playerId` 必须与 `initialState.player.id` 一致；全部 `Phase0aDamageKind.values` 必须在 `moveBindings` 中显式出现，null 仍是合法 control-only。
- 首态/波次 side、首波一致性、全场 actor id 唯一继续复用 `Phase0aWaveBattleFlow` 自身验证，不在装配器复制其规则。
- 输入 list/map 必须在装配期间解析/防御复制；装配完成后外部 mutation 不改变 flow 的快照、波次或 binding。
- 同一个显式 RNG 实例只交给唯一伤害 adapter；换波重建 session 时必须保持 RNG 连续，不重置、不按波创建新 RNG。
- 不接 UI、奖励、掉落、成长、伤势、存档、YAML/schema、旧 3v3、生产路由；不支持动态护法/脆弱/踉跄或吸血，继续由第五批工厂 fail-fast。

## 验收

1. 至少一项两波真实链路：装配器 → factory → damage adapter → session → wave flow；同 seed 与 direct `calculateResolved` 调用序列逐击同值，并证明第二波使用连续 RNG 而非重置序列。
2. 精确覆盖的 missing/extra actor、player id mismatch、缺任一 kind binding 均在装配期 fail-fast 且不消费 RNG。
3. null control-only binding 合法；外部 combatants/waves/bindings mutation 不污染已装配 flow。
4. 第五批动态机制 fail-fast 通过装配器真实穿透；错误不被包装或延迟。
5. Phase0a 全套、damage calculator 51、probe 8、analyze、diff-check 与禁用依赖契约全绿。

## 切片

1. [x] 主窗口冻结装配边界与启动期证伪点。
2. [ ] Kimi 独立 worktree：计划 → 红测 → 最小装配器 → 两波 RNG 连续穿透 → `[READY]`。
3. [ ] 主窗口独立复核精确覆盖、零 RNG 消费与同 seed 序列。
4. [ ] 合入协调分支，复验并冻结 `[READY]`。

## 当前恢复点

- 状态：第六批派单冻结中。
- 最后完成：第五批 `[READY] 7cc62093`，真实 `BattleCharacter` 已能确定性映射为生产伤害快照。
- 下一步：提交派单并创建 Kimi 独立 worktree。
- 阻塞项：无；动态机制与终局副作用继续留在明确边界之外。
