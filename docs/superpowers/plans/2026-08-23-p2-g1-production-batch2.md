# P2 G1 第二批高速并行候选

## 元数据

- taskId：`P2-G1-BATCH2-INTEGRATION`
- branch：`codex/phase2-g1-batch2-integration-20260823`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-g1-batch2-integration`
- base：`29f04073`（G1 Batch1 READY）

## 并行布局

1. Codex Terra / C11：冷却秒字段与安全迁移切片；
2. Codex Luna / C12：玩家 bot 三战术 typed policy；
3. Codex Luna / C16：防御反制安全差距收口；
4. Pi + DeepSeek V4 Flash / C13：FailurePolicyResolver 纯合同；
5. Qoder + Qwen3.8-Max / C14：RewardPolicy 与 claim key 纯合同。

五条执行线使用互不重叠的 worktree 和文件白名单。外部模型产物视为不可信候选，主窗口必须先看 diff、再测试、最后合并。

## 边界

- 不拍板 MainlineRun 参与者/换装/中断策略，不写 injury 权重。
- 不填写奖励数额、模式奖励表或新持久化 schema。
- C11 遇到无法证明等价的 turns→seconds 映射必须缩片，不猜 tuning。
- C12 默认战术保持当前 bot 行为；三策略只生成同型 intent，不另开结算规则。
- C16 只补已有纯领域实现的真实缺口，不重复重写。
- 不修改 `main`、`origin/main`、GDD.md、CLAUDE.md、PROGRESS.md。

## 验证与恢复点

- 状态：五路任务已创建并开始执行。
- 下一步：外部与 Codex 分支出 READY 后，主窗口检查白名单、决策边界、targeted tests 和接口冲突。
- 集成顺序：C16 → C12 → C13 → C14 → C11；C11 公共 SkillDef 改动最后进入，降低其他分支 stale 风险。
- 批末：联合 targeted、全仓 analyze、YAML、diff-check、外部交叉复核、READY tip。
