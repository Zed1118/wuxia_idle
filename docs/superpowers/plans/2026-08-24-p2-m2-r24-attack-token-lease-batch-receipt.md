# P2-M2-R24：攻击令牌租约批次回执

## 目标与边界

从 Batch18 登记 tip `1d64c04c` 出发，为 R12b `Phase0aCombatSession`
成功提交的 caller-declared lease mutations 发布 immutable
before/mutations/after receipt。回执只观察同一批已冻结输入与已提交快照；
不生成 action fact，不代表 durable log、exactly-once 或 host transaction。

- 分支：`codex/phase2-m2-r24-attack-token-lease-batch-receipt-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r24-attack-token-lease-batch-receipt`
- owned files 仅：
  - `lib/features/battle/application/phase0a/phase0a_attack_token_lease_batch_receipt.dart`
  - `lib/features/battle/application/phase0a/phase0a_combat_session.dart`
  - `test/features/battle/application/phase0a/phase0a_attack_token_lease_session_wiring_test.dart`
  - 本计划文件

## 冻结合同

- `Phase0aAttackTokenLeaseBatchReceipt` 仅持有：
  - exact immutable `AttackTokenLeaseSnapshot before`；
  - 防御性物化且不可修改的
    `List<AttackTokenLeaseMutation> mutations`，保留 caller 原始声明顺序；
  - exact committed `AttackTokenLeaseSnapshot after`。
- Session 仅公开 nullable `lastAttackTokenLeaseBatchReceipt`，不暴露 runtime
  owner，不提供外部 receipt 注入参数。
- 批次顺序固定：adapters → per-intent gate → planner/materialize → R12a
  validation → identity-stable subsequence validation → observer → reducer →
  prepared lease commit → receipt construction → 无抛尾段同时发布
  state/runtime/diagnostic/receipt。
- planner、lazy materialization、R12a validation、batch output validation、observer、
  reducer、lease commit 或 receipt construction 任一失败，Session 旧
  state/runtime/diagnostic/receipt 均不变。caller-owned planner/observer/resolver
  外部副作用仍不承诺回滚。
- 非空 mutations：receipt.before 必须在 runtime 赋值之前从 exact
  predecessor 捕获；receipt.after 为 committed runtime snapshot，revision 仅由
  R12a 推进。
- 空 mutations 也发布 fresh receipt；mutations 为空，before/after 是
  same exact snapshot，runtime 是 same exact predecessor，revision 不变。
- null/stateless path 不生成 receipt，旧路径不变。

## fork 最小一致语义

- 公开 constructor 始终以 null receipt 创建新 Session；它委托唯一个
  library-private constructor，成对/互斥校验只保留一份。
- `forkWithState` 继续委托 `forkWithStateAndEnemyIntentGate`；后者给私有
  constructor 原样传入 exact `_lastAttackTokenLeaseBatchReceipt` identity。
- 这使 EncounterFlow 的 fork1 → advance → fork2 在成功时保留 candidate
  receipt；若后置 objective/source/order 抛错，整个 candidate 丢弃，old
  Session 的 exact receipt 保留。不修改 EncounterFlow 或更改既有
  enemy-intent diagnostic 的 fork-reset 语义。

## 不做与 Gate

- 不从 `ActionTimeline`、hit、defeat、cooldown、actor disappearance、
  cancel/interrupt/completion/fail 推断 mutation 或 action/lease ID。
- 不定义 capacity、budget、priority、default、tuning 或时间线数值。
- 不接 production host/data/repository/save/schema/persistence/CAS/outbox/UI/
  candidate，不声称 durable transaction。

## TDD 验收矩阵

1. receipt 防御性冻结 caller mutation list，字段不可重赋。
2. acquire 成功：before same 旧 snapshot，after same 新 runtime snapshot，mutation
   exact 且 revision +1。
3. release 成功：before same acquired snapshot，after same released snapshot，原始顺序
   与 request facts 不变。
4. no-op 成功发布 fresh receipt，before/after same snapshot，runtime/snapshot
   identity 与 revision 不变；连续 no-op receipt 彼此 fresh。
5. null/stateless 旧路径 receipt 恒 null。
6. planner 失败保留旧 state/runtime/diagnostic/receipt。
7. lazy mutation materialization 失败保留旧值。
8. R12a validation 失败保留旧值。
9. injected/duplicated/reordered output 失败保留旧值。
10. observer 失败保留旧值。
11. reducer 失败保留旧值。
12. lease commit 失败用公开自定义 gate 返回绑定 foreign predecessor 的
    prepared batch 诚实触发，不伪造 R12a/private prepared；旧值不变。
13. 先成功再失败时，exact 旧 receipt 不被 null/候选值覆盖。
14. fork 保留 gate/runtime/receipt identity；candidate 成功不改 original。
15. fork1 → advance → fork2 保留 exact successful receipt；后续 candidate
    发布 fresh receipt 不改 fork1。
16. EncounterFlow 既有后置失败重试回归保持，不修改 flow。
17. source guard 锁四 owned paths、constructor 唯一校验、commit → receipt
    construction → four-field publication 顺序、fork receipt 传递，并禁越界语义。

## CLAUDE §8.2 验收 checklist

- [ ] 生产接线如实：receipt 只接 R12b Session 成功尾段；R12c
  assembler 已能透传 gate/runtime，host 激活仍为 Gate。
- [ ] 有效红灯后完成 R24 + R12b/R12c/session/observer 逐项 targeted；
  禁止 full suite。
- [ ] changed Dart scoped analyze 0 issue；format/diff/path/status clean。
- [ ] 红线影响为 0：零 YAML/数值/玩家文案/三系/在线离线/反主流/
  save/UI 变更。
- [ ] Pi CLI 0.84.1 exact `deepseek/deepseek-v4-flash` thinking high
  完成实现前和最终两轮 Read/Grep/Find/Ls-only 审查；Codex 独立
  P0/P1/P2 归零。
- [ ] 中文动宾小提交，最后追加精确 READY 空提交。

## Pi 实现前只读审查

- 版本/模型：Pi CLI 0.84.1，exact
  `deepseek/deepseek-v4-flash`，thinking high，只启用
  `read,grep,find,ls`，`--no-session --no-skills`，零写入。
- 首轮完整 prompt 连续 5 分钟零输出，按纪律主动中止，exit 130；
  同一 exact 配置精简 prompt 重试后正常 exit 0。
- 结论：`DESIGN PASS（有条件）`，P0=0、P1=2，P2=5。
- 两项 P1 全采纳：commit failure 通过公开 foreign-predecessor gate 触发；
  before snapshot 必须在 runtime 赋值前捕获并用非空 mutation identity/
  revision 测试锁定。
- P2 采纳：receipt source 守卫、session 内二次 fork 模拟、私有
  constructor 单一校验、最小三字段 receipt、no-op fresh receipt。

## 任务切片与当前恢复点

1. 读取 Batch18/R12b/R12c 与现有源码测试，完成 Pi 实现前审查并
   提交本计划。
2. 在既有 wiring test 先补 receipt 矩阵，跑缺失 API 红灯并提交。
3. 新建最小 receipt 值并修改 Session 原子尾段/fork，跑定向回归并
   提交。
4. 运行 changed analyze/format/diff/path/status，Pi 最终 diff 只读审查，回填
   证据并追加 READY。

- 状态：实现前审查完成，计划已冻结，待进入红测。
- 最后完成：Pi 两项 P1 与五项 P2 已转为实现/测试约束。
- 下一步：补 R24 测试并获取缺失 receipt API 有效红灯。
- 已跑验证：Pi 实现前只读审查；未跑测试。
- 阻塞：无；host/durable/timeline/tuning 如上继续 Gate。
