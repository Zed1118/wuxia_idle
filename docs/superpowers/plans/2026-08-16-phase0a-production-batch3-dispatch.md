# Phase 0A 根应用生产化第三批协调计划

## 目标

把第二批的 `Phase0aDamageResolver` 接到根应用 `DamageCalculator.calculateResolved` 单一公式源，交付可注入真实角色数值快照、招式绑定和 seeded RNG 的生产适配器；不扩 UI、胜负结算、存档或旧 3v3。

## 已冻结边界

- 输出严格映射：`isHit = !AttackResult.isDodged`、`isCritical` 原样、`damage = finalDamage`，表现层不得重算。
- adapter 只解析字段并调用 `calculateResolved`，禁止复制闪避/基础伤害/修炼/克制/暴击/防御/境界差公式。
- basic / gather / clear 的招式语义由调用方显式绑定；允许明确的 control-only 零伤绑定，禁止把 probe 固定伤害迁入生产。
- 所有 actor、move binding、配置与 RNG 显式注入；缺 actor/绑定与非法快照 fail-fast。
- 当前 reducer 不消费吸血结果；非零吸血配置必须显式拒绝，禁止静默丢效果。其他 `appliedEffects` 只登记残留风险，不在本片扩状态系统。
- 不依赖旧 `BattleState` / `BattleAI`，不改 `DamageCalculator` 数学、YAML、schema、saveVersion、GDD、probe。

## 验收

1. 真实 numbers fixture 下与直接调用 `DamageCalculator.calculateResolved` 精确同值。
2. 命中、闪避、暴击、最终伤害映射正确；同 seed + 同调用序列可复现。
3. control-only 不消费 RNG、不伪造伤害；多目标稳定顺序沿 reducer 保持。
4. 缺 actor/招式、负或非有限快照、非零吸血明确失败，零状态污染。
5. 第二批 81 项、damage calculator 定向回归、probe 8 项与根 analyze 全绿。
6. Kimi 与协调分支均形成干净 `[READY]` 恢复点。

## 切片

1. [x] 主窗口定位公式与旧战中 adapter，冻结本契约。
2. [x] Kimi 独立 worktree：计划 → 红测 → 最小实现 → 验证 → `[READY]`。
3. [x] 主窗口交叉复核映射和 RNG/效果丢失边界。
4. [x] 合入协调分支，复跑验证并冻结。

## 当前恢复点

- 状态：**已交付，待本计划恢复点提交并创建协调 `[READY]` tip**。
- 最后完成：合入 Kimi `[READY] 3cecfb68`；适配器仅调用 `calculateResolved`，锁定 `finalDamage` 映射、seeded RNG、control-only、per-skill 熟练度与快照防御性副本。
- 下一步：提交本恢复点，复跑协调分支最终验证并创建 `[READY]` tip。
- 已跑验证（主窗口独立于 Kimi）：Phase0a **99/99**、damage calculator **51/51**、probe **8/8**、analyze 0 issue、禁用依赖搜索与 `git diff --check` 干净。
- 阻塞项：无。

## 残留风险

- `AttackResult.appliedEffects` 尚无 Phase 0A 消费方；本批不扩状态系统。
- 非零吸血在 reducer 支持回血输出前保持 fail-fast，禁止静默丢失。
- 本批完成 simulation session 的真实伤害链路，尚未切根应用 UI/旧 3v3 入口，也未接胜负结算与存档。
