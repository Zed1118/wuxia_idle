# P2-M2-R21：听剑持久领取观察边界

## 目标与边界

从 Batch17 provisional R19 code tip `edf7f206` 出发，消费 R19 已冻结的
nullable `admittedCompanion` provenance，把当前关卡与 exact 听剑同伴
组成 shared canonical `RewardClaimKey`，再将 caller 显式提供的 exact-key
durable observation 交给 R02 既有 claim policy。本层不查询、不保存
durable 事实，不实现 grant/store/CAS/outbox/host 或 settlement identity。

- 分支：`codex/phase2-m2-r21-mentor-insight-durable-claim-boundary-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r21-mentor-insight-durable-claim-boundary`
- 来源事实：R19 已正式 READY `45faccd0`（45/45、Pi final 与 Codex
  终审 P0/P1/P2=0）；本分支 `edf7f206` 的 R19 code blob 与 READY code
  blob 一致，但不引入后续 R19 plan 证据提交。
- owned files 仅：
  - `lib/features/mainline/application/mentor_insight_stage_claim_boundary.dart`
  - `test/features/mainline/application/mentor_insight_stage_claim_boundary_test.dart`
  - 本计划文件

## 冻结 API

- `MentorInsightDurableClaimObservation` 是 public const 值，仅持有
  `RewardClaimKey claimKey` 与 `bool durablyClaimed`。
- `MentorInsightStageClaimCandidate` 仅有 private const constructor，持有
  exact `MentorInsightCompanion companion` 与 canonical `RewardClaimKey claimKey`。
- `MentorInsightStageClaimDecision` 仅有 private const constructor，持有
  candidate 的 exact companion/key 与 `MentorInsightClaimOutcome outcome`。
- `prepareMentorInsightStageClaimCandidate({required
  MainlineStageRuntimeAdmission admission})` 仅在 no admitted companion 时返回
  null。非空 provenance 先按原始字面精确检查 companion stage 等于
  `admission.runAdmission.run.currentStageId`，不等立即 `StateError`；之后且
  仅之后调用一次 `RewardClaimKey.mentorInsight(stageId: currentStageId,
  characterId: companion.characterId)`。
- `decideMentorInsightStageClaim({required candidate, required bool
  isSuccessfulSettlement, MentorInsightDurableClaimObservation?
  durableObservation})` 每次返回 fresh decision，不保留 observation。

## 决策表与诚实 Gate

observation 是 exact 当且仅当
`durableObservation.claimKey == candidate.claimKey`；比较复用 shared canonical
`==`，禁止 `identical`。实现不访问 observation key 的 `stageId` /
`characterId` getter，因此 wrong kind 必然 fail closed 而不抛错。

| settlement | observation | policy 入口 / 结果 |
|---|---|---|
| failure | missing / wrong key | `decide(false, false)` → failClosed |
| failure | exact + false | `decide(false, false)` → failClosed |
| failure | exact + true | `decide(false, true)` → failClosed |
| success | missing / wrong kind / wrong stage / wrong character | 直接 failClosed，不调 policy，不伪造 first-clear 事实 |
| success | exact + false | `decide(true, false)` → grant |
| success | exact + true | `decide(true, true)` → skip |

恢复重放由 caller 诚实传入：成功结算 + exact true → skip；成功结算 +
exact false → grant（本层无 ledger，不猜测旧发放）；失败结算 →
failClosed。

## TDD 与源码守卫

21 项核心矩阵覆盖：

1. candidate 保留 exact companion identity。
2. key 使用 run current stage 与 exact character。
3. key canonical 稳定。
4. key shared parser round-trip。
5. empty choice 返回 null。
6. empty + occupied predecessor 仍返回 null。
7. stage drift 在构键前 `StateError`；由于公开 R18 构造路径已保证
   stage 一致，该分支不可达，用 source ordering guard 冻结，不伪造 admission。
8. prepare 不改变 admission / companion / occupancy 输入。
9. failure + missing 观察。
10. failure + wrong kind。
11. failure + wrong stage。
12. failure + wrong character。
13. failure + exact false。
14. failure + exact true。
15. success + missing 直接 failClosed。
16. success + wrong kind/stage/character 均直接 failClosed，wrong kind 不抛错。
17. success + exact false → grant。
18. success + exact true → skip。
19. equal-but-not-identical key 按 canonical 命中。
20. 重复决策返回 fresh decision，但保留 same candidate companion/key。
21. recovery replay 的 true/false 显式观察及输入不变。

source guard 额外锁定：四个精确 import；
`RewardClaimKey.mentorInsight(` 恰一次；stage drift check 文本位于 factory 之前；
`MentorInsightClaimPolicy.decide(` 恰一处；source 仅以该函数进入 policy；
observation 键零 `stageId` / `characterId` getter；禁止 parse/手写 codec/
store/ledger/repository/Isar/SaveData/CAS/outbox/RewardGrantGuard/callback/rate/cap/
amount/host/ActivityOccupancy/release 绑定。

## CLAUDE §8.2 验收 checklist

- [ ] 生产接线证据如实：本任务仅交付 R19 → R02 的 host-neutral
  candidate/decision seam，production host 未接且仍为 Gate。
- [ ] 先跑缺失 API 有效红灯，再跑 R21、新 R19、R18、R02 claim、shared
  key targeted 全绿；不跑 full suite。
- [ ] 两个 changed Dart item scoped analyze 0 issue；format/diff/path/status 通过。
- [ ] 红线影响为 0：不改 tuning/YAML/玩家文案/数值/三系/在线离线/
  反主流规则，不引入存档或 UI。
- [ ] 残留风险如实：durable truth source、CAS、grant/outbox、settlement
  identity、release/grant/claim 原子性、host/persistence/data/tuning 继续 Gate。
- [ ] Pi CLI 0.84.1 exact `deepseek/deepseek-v4-flash` thinking high 用
  Read/Grep/Find/Ls-only 完成实现前与最终 diff 两轮只读审查；Codex
  独立自审 P0/P1/P2 归零。
- [ ] 中文动宾小提交，最后追加精确 READY 空提交。

## Pi 实现前只读审查

- 实际使用：Pi CLI 0.84.1，精确
  `--model deepseek/deepseek-v4-flash --thinking high --tools
  read,grep,find,ls --no-session --no-skills`；零写入。
- 原始结论：`DESIGN FAIL`，P0=1、P1=2、P2=3。
- triage：P0 只是编码前 owned files 尚不存在，正是 TDD 预期状态；
  建议从新 integration tip 重建分支与用户明确给定
  `edf7f206` 恢复点冲突，且已获主控确认 R19 code blob 一致，不采纳。
  两项 P1 与 drift/replay 两项 P2 有效，已逐项写入决策表、源码守卫和
  矩阵。

## 任务切片与当前恢复点

1. 完整读取规约和 R02/R18/R19，运行 Pi 实现前只读审查，提交本计划。
2. 先写 21 项矩阵测试，跑缺失 API 红灯并提交。
3. 最小实现 candidate/decision seam，跑定向回归并提交。
4. 运行 analyze/format/diff/path/status，Pi 最终 diff 只读审查，回填证据并
   追加 READY。

- 状态：实现前 Pi 审查已完成，计划已冻结，待进入红测。
- 最后完成：将有效 Pi findings 转成决策表与 source guard。
- 下一步：新建 R21 测试并跑缺失 API 红灯。
- 已跑验证：Pi 实现前只读审查；未跑测试。
- 阻塞：无；外部 Gate 如上。
