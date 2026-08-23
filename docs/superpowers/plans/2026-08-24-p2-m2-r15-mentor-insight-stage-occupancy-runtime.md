# P2-M2-R15：随行听剑单关占用运行时

## 目标与边界

从 Batch14 READY `7bc31c5f5463aac26e127912576350487ac0a8d3` 出发，在
R02 已冻结的单关占用、四类互斥与四种释放原因上，建立一个
owner-bound immutable predecessor → prepared successor → successor runtime。

- 工作树：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r15-mentor-insight-stage-occupancy-runtime`
- 分支：`codex/phase2-m2-r15-mentor-insight-stage-occupancy-runtime-20260824`
- owned files 仅本 plan、新 source 和新 test；不改 registry、audit、main。
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

## 验收 checklist（CLAUDE §8.2）

- [ ] 计划恢复点先独立提交；Pi 0.84.x + exact
  `deepseek/deepseek-v4-flash` + thinking high 完成编码前和最终 diff
  两轮只读审查并记录真实结果。
- [ ] TDD 红→绿：empty/no-op、acquire、四种 release、ordered batch、restore、
  lazy throw、互斥拒绝、重复/错配、foreign/stale/double commit、sibling fork、
  prepared input 不可修改与失败零发布全覆盖。
- [ ] 生产接线证据如实标记为「未接」：本任务只交付 R02 的可组合
  application runtime，不冒充 host / shared occupancy / durable claim 已上线。
- [ ] 新测试 + mentor policy / claim / reward claim key 去重 targeted 全绿；
  scoped analyze 0 issue；format、`git diff --check` 和 owned-files audit 通过。
- [ ] 红线：0 数值/YAML/文案，0 三系/在线离线/反主流/reward/save/UI/
  host 变更；source guard 证明无 claim、成长、活动查询或 tuning 依赖。
- [ ] 中文动宾小切片 commit，最终追加精确 READY 空提交。

## 任务切片

1. 复读 CLAUDE 红线/§8/§11、已否清单、GDD/decision registry、R02 与
   现有 owner-bound runtime 体例，提交本计划。
2. 调用指定 Pi 做编码前设计审查，主 agent 证伪 findings 后冻结 API。
3. 先写新测试并跑出目标 API 缺失的红灯，提交测试切片。
4. 实现最小 runtime，运行 targeted 和 scoped analyze，修正后提交。
5. 调用同一 Pi 做最终 diff 只读审查，完成 format/diff/path/status
   收口与 READY。

## 当前恢复点

- 状态：已核对精确基线与三份 owned files，已复读 R02 决策/合同和
  owner-bound runtime 原子性体例；待提交计划后做 Pi 设计审查。
- 最后完成：确认 `HEAD=7bc31c5f5463aac26e127912576350487ac0a8d3`、
  工作树初始干净、Pi CLI `0.84.1`；确认 rate/cap 与 production
  host/persistence 均不属于本切片。
- 下一步：提交本计划，调用指定 Pi 只读审查冻结 API，再写红测。
- 已跑验证：仅基线/分支/工作树/Pi 版本只读检查；尚未运行测试。
- 阻塞项：无。
- 生产接线：未接；当前是供后续 host/shared occupancy 消费的显式
  application runtime。
- 残留 Gate：成长比例/每关 cap、durable claim、shared occupancy 反向接线与
  production host 仍需独立任务与适用证据，不属于 R15。
