# P2 M2 V02B：Ch1 候选可观测事务组合上限矩阵

## 目标与边界

从 Batch20 登记提交 `44032d62021504541a70fe2fe13064f779231783`
出发，在 candidate-only 测试中组合五关 fixture loader → R11 plan →
R22 explicit defeat source → R26 transactional assembler → R25 read-only
observations。每关只执行一拍 caller 明示的 idle、drop-all intents、empty
lease mutations，不新增 production API，不把结构组合证据冒充完整战斗执行。

本任务机械搬运 V02A 的 95 条 declaration 到单一 test-support；内容、顺序、
67 Target / 3 Commander / 25 empty 均不得变化。V02A 的 70 条独立 expected
events 留在原测试，继续独立约束 payload、类型与顺序。

## 分支与 owned files

- 分支：
  `codex/phase2-m2-v02b-ch1-candidate-observable-transactional-composition-matrix-20260824`
- 基线：`44032d62021504541a70fe2fe13064f779231783`
- 严格只改：
  - 新 `test/support/ch1_candidate_defeat_projection_declarations.dart`
  - 改
    `test/data/phase2/ch1_candidate_defeat_objective_execution_matrix_test.dart`
  - 新
    `test/data/phase2/ch1_candidate_observable_transactional_composition_matrix_test.dart`
  - 本计划

## 冻结组合合同

- test-support 只公开既有类型的常量：

  ```dart
  const ch1CandidateDefeatProjectionEntriesByStageId = <
    String,
    List<
      MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>
    >,
  >{...};
  ```

  不新增 domain model，不从 entry/actor/role/position/objective/字符串生成
  projection。
- source 只经
  `mapCombatEncounterDefeatObjectiveEventSource(plan.encounter, plan.roster,
  defeatProjectionEntries: ...)` 构造；其 `externalProjectors` 仍由 R22 固定为空。
- flow 只经
  `Phase0aProductionFlowAssembler
  .assembleMigratedEncounterPlanWithAttackTokenLease(...)` 构造。caller 显式
  提供 `AttackTokenLeaseRuntime.empty()` 与
  `Phase0aExplicitAttackTokenLeaseBatchGate`；planner 返回 identity-stable empty
  enemy-intent subsequence 和 empty mutations，不推断 lifecycle/budget。
- 每关用同一个封装点调用一次
  `flow.advance(..., command: const Phase0aPlayerCommand())`；源码中 `.advance(`
  恰好一处。可能产生 spawn events，但 drop-all + idle 不产生 combat defeat；测试
  不断言总事件数、伤害或性能。
- 装配前 `objectiveProgress` 非空、receipt 为空；同一 plan 两次装配的 progress
  identity 不同，证明 R26 fresh tracker。
- 一拍成功后 receipt 非空、mutations 为空，before/after 均为 caller initial
  runtime 的 exact revision-0 snapshot；R22 source 收到零 defeat facts，progress
  保持拍前 exact identity，全部 clause 与 aggregate 仍未完成。
- 选一关先成功，再让 planner 抛错；flow-owned state/spawn/outcome/records/
  progress/receipt exact identity 均不替换。caller RNG、planner/source 调用与外部
  副作用不承诺回滚。

## TDD 与验收 checklist

- [ ] declaration helper 机械搬运精确 95 / 67 / 3 / 25，V02A 独立 70 expected
  events 与五关进度断言原样回归。
- [ ] 五关逐一装配、fresh-progress、idle receipt 与 unchanged-progress 通过。
- [ ] success 后 planner failure 保留所有 flow-owned exact observations/state。
- [ ] source guard 锁 helper markers/counts/禁推断，V02B `.advance(` 恰好一处；
  禁止 defeat execution 声明、Checkpoint/Anchor、Acquire/Release、ActionTimeline、
  host/IO/default/write/promotion/tuning。
- [ ] targeted 至少覆盖 V02B、V02A、V01、candidate catalog、R11、R22、R13、
  R26、R25、R24、R06；逐文件确认 pass 数，不跑 full。
- [ ] 三个 changed Dart items scoped analyze 0 issue；format、diff check、精确四
  owned paths 与 clean status 通过。
- [ ] 生产接线证据如实：本任务只消费既有 production contracts，不改 host/
  production source，不宣称 candidate promotion。
- [ ] 红线影响为 0：不改 YAML/数值/公式/玩家文案/三系/在线离线/反主流项；
  测试 harness 常量不进入生产。
- [ ] 残留风险如实保留：defeat-in-flow、checkpoint/anchor projector、真实 lease
  lifecycle/budget、完整 simulation、balance/performance、host/promotion、durable、
  Profile/G2/真人试玩均继续 Gate。
- [ ] Qoder CLI 1.1.28 exact `Qwen3.8-Max`、reasoning high、Read/Grep/Glob-only
  完成最终 actual-diff 只读审查并经 Codex triage 清零 P0/P1/P2。

## 外部设计审查证据

- CLI/model/权限已核验：Qoder CLI 1.1.28，exact `Qwen3.8-Max`，reasoning
  `high`，`dont_ask`，只允许 Read/Grep/Glob，禁 session persistence。
- 首次完整设计 prompt 与同配置精简重试均在约五分钟内零模型输出；分别按
  有界策略 Ctrl-C，最终 `exit 1 / Operation aborted`。没有伪造模型结论，也不做
  第三次设计重试。
- Codex 已逐项核对 R22/R25/R26/receipt/session 实际 API；主控独立设计复核
  P0/P1/P2=0，确认 drop-all intents + empty mutations + default command 只可能有
  spawn events、不会产生 `Phase0aEnemyDefeated`，因此 R22 source 返回零 events、
  progress 保持 initial identity，session 发布 before/after 同 revision-0 snapshot
  的 no-op receipt。
- 最终 diff 阶段重新尝试相同 exact Qoder 配置；若仍受服务阻塞，必须如实记录
  连接证据并由 Codex/主控独立代码审查决定 Gate，不能伪造 Qoder PASS。

## 任务切片与当前恢复点

1. 恢复 pub/build_runner/ignored `libisar.dylib`，核对 tracked clean。
2. 完成实现前只读审查，提交计划。
3. 新增引用尚不存在 helper/V02B 的红测并提交。
4. 机械迁声明、实现最小组合矩阵，运行 targeted/analyze/guards。
5. Qoder 最终只读审查、Codex triage、回填证据并追加 READY。

- 状态：环境与设计审查已完成；待提交计划并进入红测。
- 最后完成：`flutter pub get --enforce-lockfile` 成功；build_runner 写入 126 个
  ignored outputs；`libisar.dylib` SHA-256 为
  `f22f60782156ff3205c4ef72ff157337640604a8a0c4c416555a2432c764742d`；
  tracked worktree clean。
- 下一步：提交计划，添加缺少 helper/V02B source 的有效红测。
- 已跑验证：仅环境恢复与只读 API/设计审查；尚未跑任务测试。
- 阻塞项：Qoder 设计端两次限时零输出，已按有限等待策略处理；不阻塞已获独立
  设计放行的 TDD，最终审查阶段复测。
