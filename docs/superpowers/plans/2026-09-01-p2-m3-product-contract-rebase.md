# M3 产品合同重定向计划

## 结果合同

- 单一目标：在不恢复已被用户否决的三段位移普攻与护盾/化解入口的前提下，核清 M3“五武器 × 三特性”的实时生产基线，并确定可实施的新产品合同。
- 基线：`9b05f44a97d3a7d31a645e62d0be9615fdb122dd`；正式 Phase 2 仍为 `1/10`，M3 为 `0/5` 武器画像。
- 固定玩家合同：基础普攻为可连续按住的单段远程掌风，不产生链段或攻击位移；玩家主动防御只保留 `Space` 闪避。
- 验收分母：五种武器身份、三种特性生产消费、三种 Bot 战术、Boss 响应、每武器“清杂 + 精英 + Boss”画像与四类漏洞守卫。
- 本门增量：只读核对并冻结冲突，不把 parked schema、测试夹具或历史 READY 计作生产完成。
- 成本上限：不改生产代码、数据 schema、YAML、数值、存档或产品文档；产品合同未明确前不实施。

## 工作区与所有权

- 分支：`codex/p2-m3-product-contract-rebase-20260901`
- worktree：`/Users/a10506/.codex/worktrees/p2-m3-product-contract-rebase-20260901`
- owned files：
  - `docs/superpowers/plans/2026-09-01-p2-m3-product-contract-rebase.md`
  - `docs/audit/phase2_m3_product_contract_rebase_2026-09-01.md`
  - `docs/dispatch/phase0a_overhaul/task_registry.yaml`

## 验收门

1. 生产普攻装配、武器身份来源、三特性消费者、Bot 战术入口、Boss 响应和玩家防御入口逐项有当前代码证据。
2. 明确旧二阶段方案与后续用户批准产品方向的冲突，禁止以时间先后相反的旧方案覆盖新决定。
3. 给出不改数值即可判定的已完成项、真实缺口和最小授权集合。
4. 产品合同未解前以 `BLOCKED` 收口，不写玩家可见行为，不宣称 M3 工程或正式通过。

## 恢复点

- 恢复时先核对本分支、worktree clean 与 `9b05f44a` 祖先关系。
- 若用户批准新合同，另起实现分支；本审计分支不承载生产实现。
