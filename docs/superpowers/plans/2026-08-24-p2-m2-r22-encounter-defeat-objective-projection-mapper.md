# P2-M2-R22：遭遇败北目标投影映射

## 目标与边界

从 Batch18 登记 tip `1d64c04c78a729074fc387db64375cecd3704dfd` 出发，
新增一个纯 data-validation 薄映射：调用方按 encounter `entryId`
显式声明零个或多个既有 Target/Commander defeat projection，mapper
先闭合 encounter、R07 roster 与声明 entry，再闭合当前 objective 的
typed defeat payload，最后仅经 `Phase0aEncounterRoster.bindingByEntryId`
转成 R13 需要的 runtime actor map，返回既有
`Phase0aExplicitObjectiveEventSource`。

- 分支：`codex/phase2-m2-r22-encounter-defeat-objective-projection-mapper-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r22-encounter-defeat-objective-projection-mapper`
- 只允许：
  - `lib/data/validation/combat_encounter_defeat_projection_mapper.dart`
  - `test/data/validation/combat_encounter_defeat_projection_mapper_test.dart`
  - 本计划
- 禁止：R07/R13/objective defs/validator、fixture、registry、audit、
  assembler/host/repository/YAML/UI/save/reward/injury/tuning/candidate promotion。

## 冻结 API

```dart
Phase0aExplicitObjectiveEventSource
mapCombatEncounterDefeatObjectiveEventSource(
  CombatEncounterDef definition,
  Phase0aEncounterRoster roster, {
  required Iterable<
    MapEntry<String, Iterable<Phase0aDefeatObjectiveProjection>>
  >
  defeatProjectionEntries,
});
```

- `Iterable<MapEntry<...>>` 保留重复 entry 声明的 fail-closed 证据，
  不让 `Map` 在 API 边界前静默覆盖。
- 只复用 R13 既有 `Phase0aDefeatObjectiveProjection`、
  `Phase0aTargetDefeatProjection`、`Phase0aCommanderDefeatProjection`；
  mapper 绝不构造 projection。
- 仅扫描 `CombatDefeatTargetsRef` 与 `CombatDefeatCommanderRef`。
  其他六类 objective ref 不映射、不驱动 external projector。
- 返回 R13 source 时 `externalProjectors: const []`。

## 闭合与 fail-closed

1. `definition.spawnEntries.entryId` 必须与 `roster.bindings.entryId`
   双向精确相等；missing / extra / 等数替换均拒绝。
2. caller 每个 encounter entry 必须恰好声明一次；无投影也必须
   显式给空 iterable。missing / extra / duplicate entry 均拒绝。
3. required 和 actual 以 typed identity 比较：Target 与 Commander 的
   同文本 ID 不是同一投影。
4. 同一 typed payload 在同 entry 或跨 entry 重复声明均拒绝；
   objective 多 clause 重复引用同一 typed payload 沿用现有 controller
   语义，required set 去重后只需一个投影。
5. required missing、actual foreign 或 wrong kind 均拒绝。即使 payload
   存在于 catalog 其他 encounter，也是当前 definition 的 foreign。
6. payload 不需等于 entryId；Ch1 当前字面相等只是 fixture 事实，
   不是映射规则。
7. 通过闭合后，每个 entry 仅用
   `roster.bindingByEntryId(entryId)!.actorId` 得到 R13 map key。

## TDD 与 source guard

- exact 映射经真实 R13 `eventsFor` 产生 caller payload，证明
  entry 只通过 R07 binding 转 actor。
- 覆盖显式空投影、单 entry 多 payload、同 ID 的 Target+Commander。
- 覆盖 encounter/roster drift，声明 missing/extra/duplicate，typed
  required missing/foreign/wrong-kind/同 entry 重复/跨 entry 重复。
- 覆盖重复 objective ref 只需一个 projection，caller lazy iterable
  完整物化，中途 throw 不返回 partial source，输入后续突变不污染 R13。
- 证明 role/archetype/position/entrance/behavior/actorId 字面、
  defeat kind 不产生 objective 语义。
- import allowlist 仅 R13 source、roster、combat encounter def。
- 禁止 mapper 调用 Target/Commander projection constructor，禁止
  role/archetype/position/defeat kind/string-shape/candidate/host/IO/default
  推断；必须存在 `bindingByEntryId` 与空 external projector。

## CLAUDE §8.2 验收 checklist

- [x] TDD 先因 mapper/API 缺失跑出有效红灯，实现后转绿。
- [x] R22/R07/R13/objective mapper/schema/V01 按独立文件运行
  targeted，每份均确认 `All tests passed`，不跑 full。
- [x] 两个 changed Dart item scoped analyze 0 issue；format/diff/path/status
  全绿。
- [x] Pi CLI 0.84.1 精确 `deepseek/deepseek-v4-flash` thinking high，
  Read/Grep/Find/Ls-only 完成实现前与最终 diff 两轮只读审查。
- [x] 生产接线证据如实：交付 R13 真实 event source 映射网关，
  但 production host 未调用，不冒充上线。
- [x] 红线影响为 0：无 YAML/数值/玩家文案/三系/在线离线/
  反主流/reward/save/UI 触点。
- [x] 残留 Gate 诚实：checkpoint/anchor 等六类 projector、objective
  全流程 executable、Ch1 candidate promotion、production route/host、
  tuning/Profile/G2/真人验收均未解决。
- [x] Pi findings 经 Codex 证伪/修复后 P0/P1/P2 清零；小提交
  使用中文动宾，tip 追加指定 READY 空提交。

## 任务切片与当前恢复点

1. 完整读取项目规约、Batch18 plan/audit/registry 与 R07/R13/
   objective/V01 真实类型。
2. 运行 Pi 实现前只读审查，triage 后先写测试。
3. 跑出 API 缺失红灯，提交测试；实现最小 mapper，定向转绿并提交。
4. 运行 Pi 最终 diff 只读审查与 Codex 独立复核，完成全部 Gate。
5. 回填恢复点和证据，提交后追加 READY。

- 状态：实现、定向 Gate 与最终审查完成，待 READY 空提交。
- 最后完成：实现三层 exact cover、typed defeat closure、单次物化和
  `bindingByEntryId` 唯一组装；Pi 最终首轮两个 P2（独立 wrong-kind
  证据与 sealed switch）已修复，修正后复审 P0/P1/P2 均为 0。
- 已跑验证：R22 9、R07 8、R13 15、objective mapper 11、schema 8、
  V01 7，合计 58 tests 通过；V01 首跑因 fresh worktree 缺忽略的
  `*.g.dart` 失败，依 CLAUDE 要求运行 `dart run build_runner build` 后 7/7
  通过，生成物未进 Git。两个 Dart item analyze 0 issue，未跑 full。
- Pi 证据：0.84.1；实现前审查 P0=0/P1=0/P2=6（均纳入实现/测试）；
  最终首轮 P0=0/P1=0/P2=2；修正后 exact 配置复审 P0=0/P1=0/P2=0。
- 非空提交：`88b11641`、`670b4999`、`079d073d`、`f74ab37e`、
  `5151a900`；计划证据将单独提交。
- 下一步：核对 format/diff/path/status 后追加指定 READY 空提交。
- 阻塞：无。
