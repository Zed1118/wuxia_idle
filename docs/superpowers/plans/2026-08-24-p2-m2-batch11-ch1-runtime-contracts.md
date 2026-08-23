# P2 M2 Batch11：Ch1 候选目录与 runtime 合同

## 目标

从 Batch10 READY `611f0a89` 出发，整合 R03 objective controller、R04 catalog→runtime 薄映射和 D01 Ch1 非生产候选目录，形成下一步 production actor/roster 与 host 任务可消费的冻结合同。

## 来源与顺序

1. R03：扁平 `all | any` 的 owner-bound objective controller。
2. R04 / Qoder Qwen3.8-Max high：显式 enemy-id resolver 的 spawn/token/objective runtime bundle mapper。
3. D01 / Pi DeepSeek V4 Flash：四个 canonical 山匪角色、五关模板和 reference-closed candidate fixtures。

## 硬边界

- 不创建或修改 production catalog YAML，不切 host，不构造 actor/roster，不改 UI/save/reward/injury/formula。
- D01 的敌量、active limit、token budget、warning/grace 与 role multiplier 全部是候选，不因测试通过提升为生产值。
- R04 不得从 `entryId` 推导 runtime enemy ID；production caller 必须从权威 actor/roster 显式解析。
- 本批只验收可组合合同与 test-only fixture；真人试玩、双平台 profile 和 tuning Gate 仍在后续。

## 验收

- 主控逐个审查来源 diff，独立审查 P0/P1/P2=0。
- 联合 targeted、scoped analyze、YAML/Markdown/diff/path 检查通过。
- 记录集成 commit 与残留风险，追加空 `[READY][CODEX][P2-M2-BATCH11]`。
