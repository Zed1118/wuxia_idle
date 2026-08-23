# P2 G1 第一批生产差距修复

## 元数据

- taskId：`P2-G1-BATCH1-INTEGRATION`
- branch：`codex/phase2-g1-production-batch1-20260823`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-g1-integration`
- base：`f93c29e6c5130ba1a95f56fe93c3c5ef343f680b`

## 目标

把已经 FROZEN/IMPLEMENTATION-GAP 的合同接入现有生产路径：

1. C15：同关换波保留技能冷却，配置化间歇只自然推进剩余冷却；
2. C17A：心魔失败不产生物理伤势，仍保留内息紊乱与当前主修修炼度行为；
3. A01：当前掌门指针为空、悬空或角色缺失时 fail closed，不静默选择首角色。
4. C17B：清理与冻结心魔失败事实冲突的五个零读方旧字段和注释。

## 硬边界

- `MAINLINE-REPLAY-PARTICIPANT-01`、`INNER-DEMON-CULTIVATION-01` 等 PROPOSED 不拍板、不改变。
- C17B 已在 C15 合入后串行执行，未与 C15 并发修改 `data/numbers.yaml`。
- 不新增 MainlineRun、听剑占用、个人记录、奖励或 UI。
- 三执行分支 READY 后由主审检查实际 diff，再进入本集成分支。

## 验证计划

- 每个切片先跑专项 targeted；
- C15 触及 `numbers.yaml`，整合后跑 `test/data`；
- C17A 触及统一战斗结算，整合后跑 combat_shared/inner_demon 对照测试；
- A01 跑 shared resolver 和三宿主 wiring；
- 批末补生成依赖、全仓 analyze、受影响联合测试和 `git diff --check`。

## 当前恢复点

- 状态：四个切片均已 READY、主审并合入；最终联合测试 173/173、全仓 analyze 0。
- 主审修正：联合回归发现 C17B 曾把缺省 `main_cultivation_multiplier` 改为报错；已恢复缺省 0.90，同时继续拒绝五个退役 key。
- 外部复核：Pi + DeepSeek Flash 结论无阻断、无 PROPOSED 越界；Qoder + Qwen3.8-Max 找到 sweep/headless 波间 policy 漏传，已修复并通过专项回归。
- 下一步：写入批次审计、冻结 READY tip；`main` 与 `origin/main` 保持不动。
- 停止条件：任何切片需要改变 PROPOSED policy、存档 schema 或白名单外公共 API 时停止并回报。
