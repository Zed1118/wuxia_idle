# P2-M2-R12b：攻击令牌租约事务会话接缝

## 目标与边界

从 Batch14 READY `7bc31c5f5463aac26e127912576350487ac0a8d3` 出发，把 R12a 的不可变 lease prepared-successor 作为 `Phase0aCombatSession` 候选状态的一部分，由 caller 显式 planner 提供每拍稳定子序列与 lease mutations。该切片只证明 session/EncounterFlow 自有状态的事务发布，不接 production assembler/host，不接 `ActionTimeline`，不推断 acquire/release 生命周期。

- 分支：`codex/phase2-m2-r12b-attack-token-lease-session-wiring-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r12b-attack-token-lease-session-wiring`
- owned files：
  - `lib/features/battle/application/phase0a/phase0a_attack_token_lease_batch_gate.dart`
  - `lib/features/battle/application/phase0a/phase0a_combat_session.dart`
  - `test/features/battle/application/phase0a/phase0a_attack_token_lease_session_wiring_test.dart`
  - `test/features/battle/application/phase0a/phase0a_enemy_intent_observer_test.dart`
  - 本计划
- 禁止：assembler、现有 stateless batch gate、R12a runtime、EncounterFlow、ActionTimeline、host/repository/data/save/UI/tuning/candidate。

## 冻结合同

- `Phase0aAttackTokenLeaseBatchPlan` 防御性冻结 caller 提供的 enemy intent iterable 与 mutation iterable。
- `Phase0aAttackTokenLeaseBatchPlanner` 只接 immutable current lease snapshot 与 session 已经过逐 intent gate 的不可修改 enemy intents；所有 lifecycle identity/facts 由 caller 显式提供。
- `Phase0aExplicitAttackTokenLeaseBatchGate.prepare` 先完整执行/materialize planner；非空 mutations 委托 R12a `runtime.prepare`，空 mutations 不调用 R12a prepare、不增加 revision。
- prepared batch 绑定 exact predecessor；commit 只允许一次，foreign/stale predecessor 与 double commit fail closed。commit 返回 immutable successor；空 mutations 返回 exact predecessor。
- Session 的 transactional gate/runtime 必须成对配置，并与现有 stateless `enemyIntentBatchGate` 互斥。未配置时旧路径保持不变。
- Session fork 保留 transactional gate identity 与当前 immutable runtime identity/value；只公开 nullable `attackTokenLeaseSnapshot`，不暴露 mutable owner。
- 每拍顺序固定：adapters → per-intent gate → transactional prepare/materialize → identity-stable unique subsequence validation → observer success → reducer local success → prepared commit → 无抛尾段同时发布 state/runtime/diagnostic。
- outer `Phase0aEncounterFlow` 继续 fork candidate Session；objective/source/order 后置失败时丢弃候选，因此 old session 的 arena/lease/diagnostic 均不变化。外部 observer 自身副作用不可回滚，本切片只承诺 Session 自有字段。

## 继续保持 Gate 的语义

- 不推断 intent 是新 action 还是延续 action，不生成 action/lease ID。
- 不从 hit、cooldown、defeat、actor disappearance、缺失 intent、position、role 推断 release。
- 不实现 completion/cancel/interrupt/fail 自动释放、timeline tick/cooldown marker 或 `ActionTimeline` snapshot/fork/CAS。
- 不声称任意 caller planner 已满足 active-lease budget/fairness，不写预算/优先级/telegraph/grace/timeline 数值。
- 不接 production assembler/host/data/repository/save，`TUNE-WEAPON-TIMELINE-01` 保持 tuning。

## TDD 验收

1. constructor 成对约束、与 stateless gate 互斥；null/stateless path 不变。
2. acquire/release 显式成功，全部 request facts 原样保留，revision 每个非空 successor 只增一次。
3. 空 mutations 严格 no-op，runtime/snapshot identity 与 revision 不变。
4. planner 输入与 plan lists 均不可修改；lazy planner/mutation 中途 throw 零发布。
5. 注入、替换、重排、重复 intent 在 observer/reducer/commit 前拒绝。
6. planner/R12a prepare/observer/reducer 失败均不发布 Session 自有 state/lease/diagnostic。
7. fork 保留 gate/runtime identity；成功 candidate 只改变 candidate，原 session 不变。
8. EncounterFlow 后置 objective/source 失败后可用同一显式 acquire 重试，证明 lease 未泄漏；成功重试只发布一次。
9. source guard 禁止 timeline/lifecycle inference、host/repository/data/default/candidate/tuning。
10. 变更/受影响 targeted、scoped analyze、format/diff/path/status 全绿；独立复审后 READY。

全量预检发现既有 observer source guard 仍把任意 `AttackToken` 字样视为
director 推断。R12b 现在显式依赖 lease runtime/gate，但仍不依赖 director 或
offscreen/telegraph 事实，因此本切片同步该 guard 为精确禁止 director/inference，
不扩大 production 行为。

## 当前恢复点

- [x] Batch14 READY 精确基线与 owned files 已冻结。
- [x] 独立只读预检确认 shared mutable gate 会破坏 outer-flow rollback，runtime 必须属于 candidate Session。
- [x] worktree 完成 lockfile pub get、build_runner 126 outputs、63 个 `.g.dart` 与 dylib SHA 恢复。
- [ ] 提交本计划，先写有效红测，再实现最小 gate/session 接缝。
- [ ] targeted/analyze/format/diff/path、独立复审与 READY。

## READY

最终空提交固定为：`[READY][CODEX][P2-M2-R12B] 接通攻击令牌租约事务会话`。
