# P2 M2 Batch12：运行时执行接缝

## 目标

从 Batch11 READY `57f04b39` 出发，并行完成攻击令牌批次执行门、目标运行时进度跟踪器，以及显式 actor 构造的遭遇 roster 映射器。Batch12 只把已经冻结的领域合同接到可验证的应用/数据边界，不切 production host，不晋升候选数值。

## 并行任务

1. R05 / Pi + DeepSeek V4 Flash：在逐 intent 宽限门之后、观察器和 reducer 之前增加可选批次 gate；用 `AttackTokenDirector` 对显式 request 做真实裁决，并保持输入稳定子序列。
2. R06 / Codex：为一个 owner-bound `ObjectiveController` 持有原子进度，接收显式 objective event，并把 combat defeat 经调用方显式分类后再转成 objective event。
3. R07 / Qoder CLI + Qwen3.8-Max high：校验 content entry 与既有 `SpawnDirector` 完全一致后，通过显式回调构建精确 `Phase0aEncounterRoster`。

## 冻结合同

- R05 的 null 路径保持现有行为；批次 gate 只能保留稳定子序列，不能注入、替换或重排 intent。request 映射、预算和导演均由调用方显式提供；任何不一致在 reducer 前 fail closed。
- R06 不推断普通目标与 commander 身份；分类由调用方显式返回零或多个 objective event。转换或 controller 失败时不提交部分进度，terminal 后保持同一快照。
- R07 在调用 actor factory 前先比较 definition 与 director 的 entry-id 全集；factory 得到显式 content entry 与 runtime enemy id，返回 actor 后继续由 roster 领域合同校验。
- 三项均不得修改 production YAML、host route、UI、save、reward、injury、公式或 candidate tuning。

## 集成与验收

- 每项在独立 branch/worktree TDD 实现，来源 commit 与空 READY marker 可恢复。
- 主控逐项审查实际 diff，集成后执行联合 targeted、变更 Dart analyze、YAML/Markdown/diff/path 检查与 full Flutter test。
- 使用独立 Agent 复审来源与最终集成；P0/P1/P2 清零后记录证据，追加空 `[READY][CODEX][P2-M2-BATCH12]`。

## 当前状态

- [x] 从 Batch11 READY 创建三个实现 worktree 与一个集成 worktree。
- [x] 冻结任务所有权、依赖、生产隔离和 promotion Gate。
- [ ] R05 / R06 / R07 实现、来源验证与 READY。
- [ ] 主控集成、全量验证、独立终审与 Batch12 READY。
