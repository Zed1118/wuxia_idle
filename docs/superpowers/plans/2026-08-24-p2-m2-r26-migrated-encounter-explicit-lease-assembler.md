# P2-M2-R26 显式租约遭遇装配计划

## 目标与边界

- 在 `Phase0aProductionFlowAssembler` 增加独立入口
  `assembleMigratedEncounterPlanWithAttackTokenLease`，仅组合已冻结的
  migrated mapping、caller 显式 lease gate/runtime 与 objective source。
- 每次调用从 `plan.runtimeContracts.objectiveController` 构造 fresh
  `Phase0aObjectiveRuntimeTracker`；其余参数原样透传给
  `assembleEncounterFromMapping`。
- 保持旧 `assembleMigratedEncounterPlan` 的 stateless gate 签名与语义完全
  不变。新入口不传 `enemyIntentBatchGate`，不默认构造 gate/runtime，
  不校验 caller gate policy 与 plan token budgets 等价，不依赖 R25。
- 本切片不接 production host、durable store/schema/CAS/outbox、reward 或
  tuning/Profile/G2。caller 仍拥有 lease planner 策略、RNG 与外部副作。

## 精确 API

```dart
static Phase0aEncounterFlow assembleMigratedEncounterPlanWithAttackTokenLease({
  required Phase0aMigratedEncounterPlan plan,
  required NumbersConfig numbers,
  required Random rng,
  required Phase0aAttackTokenLeaseBatchGate attackTokenLeaseBatchGate,
  required AttackTokenLeaseRuntime attackTokenLeaseRuntime,
  required Phase0aEncounterObjectiveEventSource objectiveEventSource,
  Phase0aEnemyIntentObserver? enemyIntentObserver,
})
```

方法体只调用 `assembleEncounterFromMapping`：`mapping: plan.mapping`，显式
透传 `numbers/rng/observer/gate/runtime/source`，并内联创建 fresh objective
tracker。为避免改变现有非 owned source-guard 对旧 stateless 方法的切片，
新入口放在类末尾。

## TDD 与验证

1. 先增加编译失败的红测并提交：精确参数透传、装配时零
   RNG/runtime mutation、同一 plan 两次装配的 fresh objective lineage。
2. 覆盖 planner throw、lease validation throw、objective source throw 均零发布
   并在重试时观察原 predecessor；晚失败不声称回滚 caller RNG 或外部
   副作。
3. 用缺 actor combatant 的 plan 证明构造期 coverage failure 早于
   planner/runtime/RNG；用 source guard 锁定新旧方法的互不污染。
4. 运行 migrated composition、production lease wiring、assembler、mapping、
   objective integration 针对测试；对两个 Dart owned files 运行 analyze，
   再做 format、diff check、owned-path/status 审计，不运行 full。

## Qoder 前置审查证据

- CLI: `qoderclicn 1.1.28`
- selector: `Qwen3.8-Max`
- reasoning: `high`
- tools: `Read Grep Glob`（只读）
- 结论：组合设计成立；必须避开现有 source-guard 切片；精确透传
  用 direct mapping 等价流与 recording gate 证明；fresh lineage 必须复用
  同一 plan；失败后只声称 flow-owned state 零发布。

## 实现与验证证据

- 计划提交：`784d76b6`
- 红测提交：`e8891ddb`；失败唯一原因为缺少
  `assembleMigratedEncounterPlanWithAttackTokenLease`。
- 实现提交：`e5816b23`；新方法仅调用
  `assembleEncounterFromMapping`，旧 stateless 方法没有改动。
- targeted tests：60 passed
  - migrated composition: 10
  - production lease wiring: 10
  - production assembler: 23
  - encounter mapping: 15
  - production objective integration: 2
- `dart analyze` 两个 owned Dart files：`No issues found!`
- 环境：`build_runner` 产生 126 个 ignored outputs（63 个 `.g.dart`）；
  ignored `libisar.dylib` SHA-256 =
  `f22f60782156ff3205c4ef72ff157337640604a8a0c4c416555a2432c764742d`。

零发布结论仅覆盖 flow-owned arena/spawn/outcome/ordered records 与
session-owned lease successor。既有 damage resolver 可在晚失败前消费 caller RNG，
本切片不声称 RNG 回滚，也不对 caller planner/objective source/observer 的
外部副作提供事务。caller gate policy 与 plan budgets 的匹配仍是未在
此 host-neutral assembler 内判定的上层责任。
