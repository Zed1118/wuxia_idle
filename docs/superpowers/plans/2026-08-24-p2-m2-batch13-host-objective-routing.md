# P2 M2 Batch13：装配、目标与路由接缝

## 目标

从 Batch12 READY `81d47f16` 出发，补齐 Ch1 production-ready 所需的三个显式 opt-in 接缝：production encounter assembler 的 token gate 透传、objective-aware dynamic encounter flow，以及 host-neutral stage encounter route selector。本批仍不创建生产 catalog、不晋升候选数值、不切 production host。

## 并行任务

1. R08 / Pi + DeepSeek V4 Flash：只在 `assembleEncounter` 与 mapping bridge 增加可选 batch gate 透传，证明 null 路径与真实 token gate 行为。
2. R09 / Codex：为 objective tracker 增加 prepared transition/单次 commit，并让 dynamic encounter flow 通过显式 event source 消费 objective；配置后 objective completion 是唯一胜利真相源。
3. R10 / Qoder CLI + Qwen3.8-Max high：依据 typed manifest assignment、现有 migration resolver 与 caller legacy-content fact，返回 sealed legacy/migrated route。

## 硬边界

- R08 不构造预算、mapper、director 或默认值，不修改 legacy `assemble(...)`，不接任何 host。
- R09 不从 combat delta、位置、ID、role 或 defeat kind 推断 objective event；玩家死亡优先。null objective runtime 完全保留当前 flow 语义。现有 RNG/resolver 不具备 rewind 合同，本任务不得虚构异常后的 RNG 回滚保证。
- R10 不做 IO、不读 `GameRepository`/`rootBundle`、不调用 host builder，不根据 stage ID 猜模式；migrated 错误永不 fallback legacy。
- 三项均不修改 production YAML、mainline stage mapper/host、UI/save/reward/injury/failure policy、GDD/CLAUDE/PROGRESS 或 candidate fixture。

## 集成与验收

- 三项在独立 branch/worktree TDD 实现；Pi/Qoder 需留下实际版本、确切模型和最终 PASS 证据。
- 主控逐项审 diff、独立来源复审；集成后由主控在 R08 assembler 上只增加显式成对的 objective tracker/event-source 透传，并补最小联合接缝测试，但不启用 production route。
- 联合 targeted、变更 Dart analyze、YAML/Markdown/diff/path 检查、full Flutter test 与集成独立终审全部通过后追加 Batch13 READY。

## 当前状态

- [x] 从 Batch12 READY 创建三实现 worktree 与一集成 worktree。
- [x] 冻结所有权、冲突面、RNG 真实边界和 promotion Gate。
- [ ] R08 / R09 / R10 实现、来源验证与 READY。
- [ ] 主控集成、联合/全量验证、独立终审与 Batch13 READY。
