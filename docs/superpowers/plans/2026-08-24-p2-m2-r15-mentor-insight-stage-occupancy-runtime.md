# P2-M2-R15：随行听剑单关占用运行时

## 目标与边界

从 Batch14 READY `7bc31c5f5463aac26e127912576350487ac0a8d3` 出发，在
R02 已冻结的单关占用、四类互斥与四种释放原因上，建立一个
owner-bound immutable predecessor → prepared successor → successor runtime。

- 工作树：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r15-mentor-insight-stage-occupancy-runtime`
- 分支：`codex/phase2-m2-r15-mentor-insight-stage-occupancy-runtime-20260824`
- owned files 仅：
  - `lib/features/mainline/application/mentor_insight_stage_occupancy_runtime.dart`
  - `test/features/mainline/application/mentor_insight_stage_occupancy_runtime_test.dart`
  - `docs/superpowers/plans/2026-08-24-p2-m2-r15-mentor-insight-stage-occupancy-runtime.md`
  不改 registry、audit、main。
- 本切片不查询活动、不接 host / persistence / data / UI，不执行
  `MentorInsightClaimPolicy`、`RewardClaimKey` 或成长 grant。
- 比例、每关 cap 与所有 tuning 继续受 Gate 锁定。

## 冻结合同

- `MentorInsightStageOccupancySnapshot` 仅携带非负 `revision` 与可选
  `MentorInsightCompanion`。
- `MentorInsightStageOccupancyRuntime.empty/restore` 创建独立 owner lineage；
  restore 不声称 durable persistence。
- `MentorInsightStageOccupancyMutation` 密封 acquire / release。acquire 只消费
  caller 已构造的 `MentorInsightChoice` 与 `MentorInsightBlockingStatus`；空
  choice 为严格 no-op，不查 blocking status，revision 不变。
- 有门人的 acquire 必须通过 `MentorInsightPolicy.canAccompany`；任一互斥
  状态、重复 active 或 stage/character 错配全部 fail closed。
- release 只接受 R02 `MentorInsightReleaseReason` 的四个枚举值，并要求
  exact active stage/character；unknown/mismatch 不产生 successor。
- `prepare` 先完整物化 lazy iterable，再在局部状态按声明顺序验证。
  全 no-op batch 的 next 继续指向 base snapshot；任一有效变更仅使 revision
  增加一次。
- `commit` 仅允许 exact predecessor、同 owner、未消费 prepared；foreign/
  stale/double commit 拒绝。同一 predecessor 可显式产生隔离的 sibling
  successors，不冒充全局 CAS。

### 编码前冻结 API

- `sealed class MentorInsightStageOccupancyMutation`
- `AcquireMentorInsightStageOccupancy({required MentorInsightChoice choice,
  required MentorInsightBlockingStatus blockingStatus})`
- `ReleaseMentorInsightStageOccupancy({required MentorInsightCompanion companion,
  required MentorInsightReleaseReason reason})`
- `MentorInsightStageOccupancyRuntime.empty()`
- `MentorInsightStageOccupancyRuntime.restore({required int revision,
  MentorInsightCompanion? companion})`
- `MentorInsightStageOccupancyPreparedSuccessor prepare(
  Iterable<MentorInsightStageOccupancyMutation> mutations)`
- `MentorInsightStageOccupancyRuntime commit(
  MentorInsightStageOccupancyPreparedSuccessor prepared)`

`MentorInsightStageOccupancySnapshot` 与
`MentorInsightStageOccupancyPreparedSuccessor` 均仅能由 runtime 内部构造。
source 唯一 import 冻结为 `../domain/mentor_insight_policy.dart`。

### 二义性决议

- D1：unknown/mismatched release 抛 `StateError`，整批拒绝；不作静默 no-op。
- D2：批内只要发生过一次成功 acquire/release，即使净状态未变，
  revision 也只增加一次。
- D3：no-op prepared 的 `next` 与 `base` 为同一 snapshot；成功 commit
  仍消费 prepared 并返回同 owner 的新 runtime，与 owner-bound runtime
  现有体例一致。

## Pi 证据

### 编码前设计审查

- CLI：`pi 0.84.1`
- model：`deepseek/deepseek-v4-flash`
- thinking：`high`
- 命令摘要：`--no-session --no-skills --no-prompt-templates --tools
  read,grep,find,ls --print`，读取本 plan、R02 policy/claim 与现有
  owner-bound runtime/test；无 bash/edit/write。
- 结果：`PASS`，无 P0 阻塞；建议冻结 D1/D2/D3，已按上述决议采纳。
- 独立校验：Pi 建议的 `../../domain/mentor_insight_policy.dart` 与实际
  `application`/`domain` 目录为 sibling 的拓扑不符，已更正为 `../domain/...`；
  其余接口与不变量结论通过主 agent 对照。

### 最终 diff 审查

- CLI：`pi 0.84.1`
- model：`deepseek/deepseek-v4-flash`
- thinking：`high`
- 命令摘要：同样仅启用 `read,grep,find,ls`，完整读取 baseline
  diff 的三份 owned files，并对照 R02 policy/claim 和 attack-token lease
  runtime/test；无 bash/edit/write。
- 结果：`PASS`，P0/P1 均无；确认 18 个新测试无假绿、API 未过宽、
  source guard 合理。唯一 P2 为本 plan checklist/恢复点停在中途状态，
  已在本次更新修正。

## 验收 checklist（CLAUDE §8.2）

- [x] 计划恢复点先独立提交；Pi 0.84.x + exact
  `deepseek/deepseek-v4-flash` + thinking high 完成编码前和最终 diff
  两轮只读审查并记录真实结果。
- [x] TDD 红→绿：empty/no-op、acquire、四种 release、ordered batch、restore、
  lazy throw、互斥拒绝、重复/错配、foreign/stale/double commit、sibling fork、
  prepared input 不可修改与失败零发布全覆盖。
- [x] 生产接线证据如实标记为「未接」：本任务只交付 R02 的可组合
  application runtime，不冒充 host / shared occupancy / durable claim 已上线。
- [x] 新测试 + mentor policy / claim / reward claim key 去重 targeted 全绿；
  scoped analyze 0 issue；format、`git diff --check` 和 owned-files audit 通过。
- [x] 红线：0 tuning 数值/YAML/玩家文案，0 三系/在线离线/反主流/reward/save/UI/
  host 变更；source guard 证明无 claim、成长、活动查询或 tuning 依赖。
- [x] 中文动宾小切片 commit 已完成；本 plan 的直接后继将追加
  精确 READY 空提交，最终状态以分支 tip subject 为准。

## 任务切片

1. 复读 CLAUDE 红线/§8/§11、已否清单、GDD/decision registry、R02 与
   现有 owner-bound runtime 体例，提交本计划。
2. 调用指定 Pi 做编码前设计审查，主 agent 证伪 findings 后冻结 API。
3. 先写新测试并跑出目标 API 缺失的红灯，提交测试切片。
4. 实现最小 runtime，运行 targeted 和 scoped analyze，修正后提交。
5. 调用同一 Pi 做最终 diff 只读审查，完成 format/diff/path/status
   收口与 READY。

## 当前恢复点

- 状态：R15 source/test/plan 已完成，两轮指定 Pi 只读审查均
  `PASS`，已修正最终审查指出的中途文档漂移。
- 已完成 commits：`a10edae6` 计划恢复点、`535b59e2` API/Pi 证据冻结、
  `cfe1e5c7` 红测、`a29206d5` 最小实现。
- 下一步：提交本收口恢复点，复跑最终验证，然后追加精确
  `[READY][PI][P2-M2-R15] 建立随行听剑单关占用运行时` 空提交。
- 已跑验证：红灯精确为缺失目标 source；新测试 18/18；新测试 + mentor
  policy/claim + reward claim key 去重 targeted 65/65；scoped analyze 8 items
  0 issue；format 2 files 无变化；`git diff --check` 与三份 owned-files
  audit 通过。按任务约束未跑 full suite。
- 阻塞项：无。
- 生产接线：未接；当前是供后续 host/shared occupancy 消费的显式
  application runtime。
- 残留 Gate：成长比例/每关 cap、durable claim、shared occupancy 反向接线与
  production host 仍需独立任务与适用证据，不属于 R15。
