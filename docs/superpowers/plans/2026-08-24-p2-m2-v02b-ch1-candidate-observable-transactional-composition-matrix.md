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
- 选一关先成功，再让 planner 抛错；flow-owned state/records/progress/receipt
  exact identity 均不替换，outcome 保持同一 enum 值。`SpawnDirector.state` getter
  按实际 API 每次物化 fresh snapshot，故逐项比较 tick/counts/units 等值而不伪造
  snapshot identity；caller RNG、planner/source 调用与外部副作用不承诺回滚。

## TDD 与验收 checklist

- [x] declaration helper 机械搬运精确 95 / 67 / 3 / 25，V02A 独立 70 expected
  events 与五关进度断言原样回归。
- [x] 五关逐一装配、fresh-progress、idle receipt 与 unchanged-progress 通过。
- [x] success 后 planner failure 保留所有 flow-owned observations/state；spawn
  依其物化 getter 合同比较完整值。
- [x] source guard 锁 helper markers/counts/禁推断，V02B `.advance(` 恰好一处；
  禁止 defeat execution 声明、Checkpoint/Anchor、Acquire/Release、ActionTimeline、
  host/IO/default/write/promotion/tuning。
- [x] targeted 至少覆盖 V02B、V02A、V01、candidate catalog、R11、R22、R13、
  R26、R25、R24、R06；逐文件确认 pass 数，不跑 full。
- [x] 三个 changed Dart items scoped analyze 0 issue；format、diff check、精确四
  owned paths 与 clean status 通过。
- [x] 生产接线证据如实：本任务只消费既有 production contracts，不改 host/
  production source，不宣称 candidate promotion。
- [x] 红线影响为 0：不改 YAML/数值/公式/玩家文案/三系/在线离线/反主流项；
  测试 harness 常量不进入生产。
- [x] 残留风险如实保留：defeat-in-flow、checkpoint/anchor projector、真实 lease
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

- 状态：TDD、targeted、analyze 与本地 guards 已完成；待 Qoder 最终只读审查、
  Codex triage 与 READY。
- 最后完成：计划 `a6a6f8b0`；有效红测 `48a9baee`，唯一失败是缺少新 helper
  URI/符号；实现 `d441f6d7`。V02A declarations 与基线经去掉 formatter 统一缩进
  后的内容 diff 为 0，计数仍为 95 / 67 / 3。
- 下一步：提交本验证恢复点，用 exact Qoder 配置审查 actual diff。
- 已跑验证：V02B 7/7、V02A 8/8、V01 7/7、candidate catalog 9/9、
  R11 7/7、R22 9/9、R13 15/15、R26 10/10、R25 12/12、R24 17/17、
  R06 15/15，合计 116/116；三个 changed Dart items scoped analyze 0 issue；
  `dart format` 3 items 0 changed、`git diff --check` 与精确 owned-path guard 通过。
- API 最小校正：首轮 V02B 仅 failure case 的 `same(spawn)` 失败；源码确认
  `SpawnDirector.state` 每读 fresh materialize，且 R25/R26 既有测试均比较
  tick/units。本实现改为完整 scalar counts + units 等值；其余 exact identity 断言
  不变。
- 阻塞项：Qoder 设计端两次限时零输出，已按有限等待策略处理；不阻塞已获独立
  设计放行的 TDD，最终审查阶段复测。
