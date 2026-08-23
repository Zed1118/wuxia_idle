# P2-G2-D04 AttackToken observe-only 接缝

## 目标与分支

- 分支：`codex/phase2-g2-d04-token-observe-20260823`
- 执行：Qoder CLI + `Qwen3.8-Max`
- 目标：在 `Phase0aCombatSession` 的 enemy AI intents 和 reducer 之间建立只读 observer，使 `AttackTokenDirector` 可生成诊断 allocation，但不过滤、重排、改写 intent。

## 冻结 API 边界

- `Phase0aEnemyIntentObserver.observe` 只接收 enemy intents 的防御性不可修改副本，不返回替换 intents。
- `AttackTokenObserveOnlyObserver` 构造必须显式注入 director、budgets、request mapper。mapper 返回 null 代表调用方明确标记非候选。
- request actorId 必须与对应 intent.actorId 一致，否则 reducer 前 fail closed。
- session 仅加可选 observer 和只读 `lastEnemyIntentObservation`；null 时不构造 budget/request、不调 director。

## 验收

- session 不根据 intent 推断 kind/offscreen/highImpact/telegraph/grace。
- observer 即使 allocation 全拒绝，reducer 仍消费原始 enemy intents，player -> enemy 顺序不变。
- 测试 default vs observe 同初态/同命令的 state/events/nextSeq/resolver 调用完全相等。
- 测试 intent 列表不可修改、actor mismatch fail closed 且 reducer 未执行、null mapper 语义。
- 不实现 enforce/mode switch，不改 reducer、AI、数值、data、UI、存档或奖励。
- 跑 targeted tests、限定 analyze、`git diff --check`。
- 提交中文动宾 commit，最后追加 `[READY][QODER][P2-G2-D04]` 空 commit，工作树必须 clean。

## 当前恢复点

- 状态：实现、主控修正与验证已完成，待提交 READY。
- 基线：`1150c56a`。
- 已完成：
  - `lib/.../phase0a_enemy_intent_observer.dart`:`Phase0aEnemyIntentObserver` 接口 + `Phase0aEnemyIntentObservation`(tick + `List.unmodifiable` 防御副本,无返回值)。
  - `lib/.../attack_token_observe_only_observer.dart`:显式注入 director、budgets、mapper;mapper 返回 null = 非候选;`request.actorId != intent.actorId` 抛 `ArgumentError` fail closed;结果只记录 `lastAllocation`。
  - `phase0a_combat_session.dart`:可选 `enemyIntentObserver` + 只读 `lastEnemyIntentObservation`;observer 为 null 时不构造观测对象;观测在 reducer 之前、不改 intents 与顺序。
  - `test/.../phase0a_enemy_intent_observer_test.dart`:不可修改副本、全拒绝仍消费原始双方 intents、default vs observe 等价、mismatch fail closed 且 reducer 未执行、null mapper、null observer、session 源码不引用 AttackToken 语义。
  - 主控修正：`lastAllocation` 改为只读 getter；observer 成功后才提交 `lastEnemyIntentObservation`，fail closed 不污染会话诊断状态。
- 下一步：提交并追加 `[READY][QODER][P2-G2-D04]` 空 commit。
- 验证：targeted tests 7/7；限定 analyze 0 issue；`git diff --check` 通过。
- 阻塞：无。
