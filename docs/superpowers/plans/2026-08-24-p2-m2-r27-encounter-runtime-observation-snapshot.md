# P2-M2-R27：遭遇运行时观测快照

## 目标与基线

从登记冻结基线 `44032d62021504541a70fe2fe13064f779231783`
出发，将 R25 已有的 objective progress 与 lease batch receipt 组合成
一个 immutable typed observation value，并让具体
`Phase0aEncounterFlow` 实现窄只读 source capability。R26 已返回
concrete flow，因此不再包装 advance/state/outcome facade，也不修改
assembler。

- branch：`codex/phase2-m2-r27-encounter-runtime-observation-snapshot-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r27-encounter-runtime-observation-snapshot`
- owned files 严格仅 5 个：
  - 新 `lib/features/battle/application/phase0a/phase0a_encounter_runtime_observation.dart`
  - `lib/features/battle/application/phase0a/phase0a_encounter_flow.dart`
  - `test/features/battle/application/phase0a/phase0a_encounter_flow_runtime_observation_test.dart`
  - `test/features/battle/application/phase0a/phase0a_migrated_encounter_composition_test.dart`
  - 本计划文件

## 精确 API

```dart
final class Phase0aEncounterRuntimeObservation {
  const Phase0aEncounterRuntimeObservation({
    required this.objectiveProgress,
    required this.lastAttackTokenLeaseBatchReceipt,
  });

  final ObjectiveControllerProgress? objectiveProgress;
  final Phase0aAttackTokenLeaseBatchReceipt?
  lastAttackTokenLeaseBatchReceipt;
}

abstract interface class Phase0aEncounterRuntimeObservationSource {
  Phase0aEncounterRuntimeObservation get runtimeObservation;
}
```

`Phase0aEncounterFlow` 仅增加精确 interface 实现与单表达式 getter：

```dart
Phase0aEncounterRuntimeObservation get runtimeObservation =>
    Phase0aEncounterRuntimeObservation(
      objectiveProgress: objectiveProgress,
      lastAttackTokenLeaseBatchReceipt:
          lastAttackTokenLeaseBatchReceipt,
    );
```

- 每次读取都是 fresh 容器，包括 compatibility 和 all-null runtime；
  public const constructor 只供 caller 自建 value，flow getter 不用 `const`。
- 两个成员必须 exact 转发当前 R25 getter identity，不复制、不重建。
- compatibility/unconfigured 返回非空 snapshot，两字段 null；
  objective-only、lease-only 与 both 均合法。
- snapshot 是 point-in-time value；旧 snapshot 不随之后 advance 漂移。
- 失败/terminal 后重读容器仍 fresh，但成员保留失败/终局前
  exact identity。fresh 不代表新 commit/event/transaction。

## TDD 验收矩阵

1. value public const 构造，两 nullable final fields 保留 exact input。
2. concrete flow 可赋给 `Phase0aEncounterRuntimeObservationSource`。
3. compatibility、unconfigured 在 advance 前后每次 fresh，两成员 null。
4. objective-only 在 fresh/成功后容器 fresh，progress same direct getter，receipt null。
5. lease-only 在 acquire/no-op 后容器 fresh，receipt same direct getter，
   progress null。
6. both-configured 在 advance 前后每次 fresh，两成员同时 exact。
7. advance 前已捕获 snapshot 的 final 成员不随 advance 漂移。
8. planner/lease validation/batch output/observer/reducer/objective source 失败后，
   新容器 fresh，两成员保留失败前 identity。
9. terminal 重放返回 fresh 容器，成员保留 terminal identity。
10. R26 真实 `assembleMigratedEncounterPlanWithAttackTokenLease` 产物是 source；
    success 与 planner/validation/objective-source failure 均锁 fresh/exact。
11. source guard 锁新文件两条精确 import、value/source 形状、flow
    单表达式 getter；`Phase0aBattleFlow` 不出现新 API。
12. R25 既有 getter/order/owner guard 原样保留，新测试只增量追加。

## Pi 实现前只读审查

- 实际配置：Pi CLI 0.84.1，exact
  `deepseek/deepseek-v4-flash`，thinking high，Read/Grep/Find/Ls-only，
  `--no-session --no-skills`，约 3 分钟正常退出。
- 结论：`DESIGN PASS`，P0=0、P1=3、P2=5。
- P1 全采纳：不弱化 R25 守卫；全变体同时锁 fresh container 与
  exact member identity；R26 真实装配路径补 narrow source 与失败观测。
- P2 全纳入：精确 source guard、getter 形状、五变体、诚实措辞与
  source 层 targeted 纪律。用户登记的 6 文件影响集与 4 changed
  Dart analyze 优先于 Pi 的最小建议。

## 验证命令

逐文件运行，不跑 full：

1. `phase0a_encounter_flow_runtime_observation_test.dart`
2. `phase0a_migrated_encounter_composition_test.dart`
3. `phase0a_attack_token_lease_session_wiring_test.dart`
4. `phase0a_dynamic_encounter_objective_flow_test.dart`
5. `phase0a_production_attack_token_lease_wiring_test.dart`
6. `phase0a_production_encounter_objective_integration_test.dart`

对新 source、flow 与两个 changed tests 运行 scoped analyze；再做 format、
`git diff --check`、exact 5-path guard 与 clean status。

## 禁止项与 Gate

- 不修改 `Phase0aBattleFlow`、assembler、session、receipt 或 `advance`。
- value/source 禁 controller/session/tracker/runtime/prepare/commit/callback/tick/
  revision/epoch/seq/eventId/listener/stream/history/ledger/codec/durable/owner/
  setter/copyWith 与 mutation capability。
- 不接 host/data/repository/save/schema/persistence/CAS/outbox/candidate/tuning/
  Profile/G2/UI，不推断 ActionTimeline/capacity/budget/default/lifecycle。
- 不声称 caller RNG、planner/source/observer 调用或其他外部副作用回滚。
- 无用户决策依赖；production/candidate/durable/tuning 继续 Gate。

## CLAUDE §8.2 checklist

- [x] 有效缺 API 红灯后最小实现，小提交按 plan → red →
  implementation → fix/evidence。
- [x] 6 文件 targeted 全绿，4 changed Dart analyze 0，format/diff/path/status
  clean，未跑 full。
- [ ] Pi 同配置完成最终只读审查，triage 后 P0/P1/P2=0。
- [ ] 红线影响 0，Gate 诚实；最后追加精确 READY 空提交。

## 恢复点

- 状态：计划、红测、实现、守卫加固、6 文件 targeted 与 scoped
  analyze 已完成；待 Pi 最终只读审查、triage、最终证据与 READY。
- 提交：`8fc8a28e` plan；`33748337` red；`3bc33cb1`
  implementation；`19938f32` source guard 加固。
- 有效红灯：两个 owned tests 仅因新
  `phase0a_encounter_runtime_observation.dart` 不存在，value/source/getter 类型
  无法解析而编译失败；最小生产实现后转绿。
- targeted 合计 83/83：R25 runtime observation 25/25，R26 migrated
  composition 14/14，lease session 17/17，dynamic objective 15/15，
  production lease wiring 10/10，production objective integration 2/2；
  未跑 full。守卫加固后又复跑 R25 25/25。
- 静态验证：4 changed Dart items `flutter analyze --no-pub` 0 issue；
  `dart format` 4 items 0 changed；`git diff --check`、exact 5-path guard 与
  status clean。R25 测试相对基线仅新增行，既有 getter/order/owner
  guard 未删改。
- 环境：`flutter pub get` 成功；build_runner 写 126 ignored outputs；
  `libisar.dylib` SHA-256 =
  `f22f60782156ff3205c4ef72ff157337640604a8a0c4c416555a2432c764742d`，
  与 Batch19 READY `cmp -s` 一致；Git clean。
- 阻塞：无。
