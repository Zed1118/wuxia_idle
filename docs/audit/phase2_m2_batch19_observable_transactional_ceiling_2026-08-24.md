# 二阶段 M2 Batch19 可观测事务与执行上限审计（2026-08-24）

## 基线与授权

- 集成基线：Batch18 READY `b6fd77242d8d72fd75822b70e7353e60b9542e0a`。
- 用户已授权持续自动推进并充分并行使用 Pi + DeepSeek Flash、Qoder CLI + Qwen3.8-Max 与 Codex 多 Agent；本批只做 frozen host-neutral 合同与 candidate-only 验证。
- main/origin main 初始均为 `e292d3a069fbc0e129dd74fafc1ebb3746f53557`，禁止直接修改。

## 预检结论

- EncounterFlow 已独占 runtime session 与 objective tracker，但缺少不泄露 mutation capability 的只读 progress/receipt 观测；两个 nullable getter 可直接转发 exact immutable 状态。
- 旧 migrated assembler 固定创建 stateless gate，不能再附加 transactional lease pair；R26 必须新增独立显式方法，复用 `assembleEncounterFromMapping` 并在方法体内 fresh objective tracker。
- Ch1 candidate 真实 fixture 为 5 stages / 95 entries；逐 entry 明示 67 Target、3 Commander、25 empty 后，R22→R13 可产生 70 defeat events 并由 R06 执行，无需用户决策。

## 风险控制

- observation 过权：R25 只读转发 `_objectiveTracker?.progress` 与 `_session?.lastAttackTokenLeaseBatchReceipt`；不得返回 session/tracker/runtime owner。
- gate 互斥：R26 使用独立方法，不改变旧 stateless assembler；不得同时传 `enemyIntentBatchGate` 与 transactional lease gate。
- fake-green：V02A 的 95 条声明必须逐 entry 硬编码，不能从 objective、ID 前缀、role 或 position 生成；runtime actor 必须与 entry ID 不同。
- objective 过报：stage 01 的 defeat clause 完成但 aggregate 因 checkpoint 为 false；stage 02 只由 commander `any` 分支完成，anchor 仍未执行。
- production/candidate promotion/checkpoint-anchor host/timeline/durable/tuning/Profile/G2/真人验收继续 Gate。

## 待完成验证

待三来源 READY 后补充外部工具证据、来源/集成提交、targeted/analyze/format/full、仓库闸门、独立终审与最终 READY。
