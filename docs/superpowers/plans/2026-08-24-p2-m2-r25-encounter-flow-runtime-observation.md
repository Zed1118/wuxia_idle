# P2-M2-R25：遭遇流运行时只读观测

## 目标与边界

从 Batch19 登记提交 `cc09030ce371be064425f3fef929f53f0c562a33`
出发，只给 `Phase0aEncounterFlow` 增加两个 nullable 只读 getter，转发
exact immutable objective progress 与最近一次成功提交的 lease batch receipt。
不修改 `Phase0aBattleFlow`，不暴露 session/tracker/runtime owner 或任何
prepare/commit 能力。

- 分支：`codex/phase2-m2-r25-encounter-flow-runtime-observation-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r25-encounter-flow-runtime-observation`
- owned files 仅：
  - `lib/features/battle/application/phase0a/phase0a_encounter_flow.dart`
  - `test/features/battle/application/phase0a/phase0a_encounter_flow_runtime_observation_test.dart`
  - 本计划文件

## 冻结 API

```dart
ObjectiveControllerProgress? get objectiveProgress =>
    _objectiveTracker?.progress;

Phase0aAttackTokenLeaseBatchReceipt?
get lastAttackTokenLeaseBatchReceipt =>
    _session?.lastAttackTokenLeaseBatchReceipt;
```

- `ObjectiveControllerProgress` 从 domain `objective_controller.dart` 精确 import。
- receipt 必须从 application
  `phase0a_attack_token_lease_batch_receipt.dart` 精确 import。
- compatibility flow、未配置 objective 的 runtime flow 与未配置 lease 的
  runtime flow 均返回 null。
- getter 只返回 exact 已拥有对象；不复制、不重建、不缓存、不改变 advance。

## 原子观测语义

- fresh objective flow 的 getter 与 exact `tracker.progress` identity 相同。
- 成功 objective transition 后 getter 与提交后的 exact progress 相同。
- 成功 lease batch 后 receipt 是 Session 已发布的 exact receipt identity；
  receipt snapshot identity 必须锚定 recording gate 见到的内部 runtime lineage，
  不能错误锚定 caller 持有的初始 runtime。
- planner、lease validation、batch output validation、observer、reducer、
  objective source 即时/惰性失败，均不得替换旧 progress/receipt identity。
- event-order adapter 的失败在正常 flow seq/tick 构造下结构不可达；不得为
  满足矩阵伪造重复/倒序事件。order 验收由真实可达失败点在管线中的前后顺序
  与现有 event-order 回归覆盖。
- terminal advance 是 strict no-op：events 为空、records 按既有合同清空，
  progress/receipt 仍保持 terminal 前 exact identity。
- caller-owned RNG、planner/observer/source 调用计数或其他外部副作用不承诺
  回滚；只承诺 flow-owned session/director/outcome/records/tracker 不发布候选值。

## TDD 验收矩阵

1. compatibility advance 前后两个 getter 均 null。
2. runtime 未配置 objective/lease 时 advance 前后均 null。
3. fresh configured objective progress 与 tracker progress same identity。
4. objective 成功提交后 progress same identity，并保持不可修改。
5. lease 成功后 receipt exact identity；before/after 锚内部 snapshot lineage。
6. no-op lease 发布 fresh receipt，before/after same snapshot，连续 receipt fresh。
7. 先成功再触发 planner failure，旧 progress/receipt identity 不变。
8. lease validation failure 保留旧 identity。
9. batch output validation failure 保留旧 identity。
10. observer failure 保留旧 identity。
11. reducer failure保留旧 identity。
12. objective source 即时与惰性失败均保留旧 identity。
13. terminal/no-op advance 保留 progress/receipt exact identity。
14. source guard 锁两个单表达式 getter、两条精确 import 与只读 capability；
    禁止 getter 返回 session/tracker/runtime owner 或暴露 mutation API。
15. caller-owned side effect 测试如实证明失败不会倒带外部计数/RNG。

## CLAUDE §8.2 验收 checklist

- [ ] 有效红灯后完成新 R25、dynamic objective、lease session、production
  lease wiring 与 compatibility 逐文件 targeted；不跑 full。
- [ ] 两个 changed Dart items scoped analyze 0 issue；format/diff/path/status clean。
- [ ] 生产接线证据如实：getter 位于真实 `Phase0aEncounterFlow`，但本任务
  不修改 assembler/host，不冒充 production host 已接入。
- [ ] 红线影响为 0：零 YAML/数值/玩家文案/三系/在线离线/反主流/save/UI。
- [ ] Pi CLI 0.84.1 exact `deepseek/deepseek-v4-flash` thinking high，
  Read/Grep/Find/Ls-only 完成设计与最终 diff 审查，triage 后 P0/P1/P2=0。
- [ ] 小提交按 plan → red → implementation → fix/evidence；最后追加精确
  `[READY][PI][P2-M2-R25] 冻结遭遇流运行时观测` 空提交。

## Pi 实现前只读审查

- 实际配置：Pi CLI 0.84.1，exact `deepseek/deepseek-v4-flash`，thinking
  high，仅 Read/Grep/Find/Ls，`--no-session --no-skills`，零写入。
- 结论：`DESIGN PASS`；P0=0、P1=2、P2=6。
- P1 全采纳：event-order failure 结构不可达且不得伪造；receipt identity
  必须锚 recording gate 的内部 snapshot lineage。
- P2 全纳入：补 exact progress domain import；source guard 只切 getter 片段；
  progress 必须用 `same()`；terminal 前后读 getter；保留独立 R25 plan；
  测试直构 flow、不引入 GameRepository。

## 不做与 Gate

- 不返回 `_session`、`_objectiveTracker`、lease runtime/owner、prepared
  transition/batch 或 mutation/commit callback。
- 不接 production host/data/repository/save/schema/persistence/CAS/outbox/UI。
- 不推断 ActionTimeline、capacity、budget、default、lifecycle、candidate 或 tuning。
- 不声称 caller RNG/外部副作用可回滚，也不声称 durable transaction。

## 任务切片与当前恢复点

1. 恢复依赖、ignored generated files 与 `libisar.dylib`，核对环境不进 Git。
2. 读取 Batch19/R25 与 flow/session/objective/lease 合同，完成 Pi 设计审查。
3. 提交计划；新增 R25 matrix，跑缺失 getter 的有效红灯并提交。
4. 实现两个最小 getter，运行 targeted/analyze/format/diff/path/status。
5. Pi 最终只读 diff 审查、Codex triage、回填证据并追加 READY。

- 状态：环境与设计审查完成，计划冻结，待进入红测。
- 最后完成：Pi DESIGN PASS；两项 P1 与六项 P2 已转为测试/实现约束。
- 下一步：提交计划，新增 R25 测试并获取缺失 API 编译红灯。
- 已跑验证：`flutter pub get`；build_runner 126 ignored outputs；Batch18
  `libisar.dylib` SHA-256 与 `cmp` 一致；未跑测试。
- 阻塞：无；host/durable/timeline/tuning 与外部副作用回滚继续 Gate。
