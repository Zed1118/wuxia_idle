# P2-M2-R10：Stage encounter route selector

## 目标与边界

在 typed `CombatCatalogManifestDef` 与现有
`Phase0aEncounterMigrationResolver` 之间新增 host-neutral pure selector。调用方显式提供
`stageId` 与 `hasLegacyContent`；selector 只复核一个 stage 的迁移形状并返回 sealed immutable
route，不读取文件、不接 production host、不复制全量 coverage gate。

- 分支：`codex/phase2-m2-r10-stage-encounter-route-selector-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r10-stage-encounter-route-selector`
- 精确基线：`81d47f16880b2b9d7a860379cf308cca3f6110e2`
- 白名单：selector、对应测试、本计划共 3 文件。
- 禁止：registry/audit/host/repository/data/main、IO/rootBundle/GameRepository、默认 state、stageId
  推断、coverage gate 复制、candidate/production promotion。

## 冻结合同

- assignment 必须在 manifest 中存在；selector 从 exact assignment 与 exact manifest encounter
  派生 `encounterCount`。
- `CombatEncounterMigrationState` 以 exhaustive switch 一一映射为
  `Phase0aEncounterMigrationState`，并实际调用 caller 提供的现有 resolver。
- legacy 只返回 `LegacyCombatStageEncounterRoute(stageId)`；migrated 只返回
  `MigratedCombatStageEncounterRoute(stageId, exact manifest encounter identity)`。
- unknown、allowlist/state/content shape mismatch 全部 fail closed；migrated 失败绝不 fallback
  legacy。
- valid typed manifest 已在构造期禁止 migrated missing encounter、legacy 携 encounter、同 stage
  多 assignment；selector 保持防御式 fail closed，但不伪造 manifest、不重复 schema。
- 每次成功调用返回 fresh route；相同输入的 value equality/hashCode 稳定，migrated equality 保持
  encounter identity 语义。

## 验收 checklist（CLAUDE §8.2）

- [x] TDD 红测由目标 selector/API 缺失触发，后续转绿。
- [x] 覆盖 valid legacy/migrated、unknown、allowlist/state mismatch、legacy missing content、
  migrated has legacy 且不 fallback。
- [x] `identical()` 证明 route 携 exact manifest encounter；重复调用 fresh、确定且不可变。
- [x] typed manifest constructor failure 证明 missing/multi encounter shape 在 selector 前不可达。
- [x] source guard 禁止 IO/rootBundle/GameRepository/loader/coverage gate/candidate ID 与 catch fallback。
- [x] targeted selector + resolver + manifest + migration gate 回归全绿；scoped analyze 0 issue；
  format、`git diff --check`、严格白名单检查通过。
- [x] 生产接线证据：本切片按授权只交付后续 host 消费的纯 route seam，明确不接 production
  host，不冒充已经上线。
- [x] 红线：0 production 数值/公式/文案/数据，0 三系、在线离线、反主流、奖励、伤势、save、
  UI 触点。
- [x] 实现与证据提交后追加精确 `[READY][QODER][P2-M2-R10]` 空提交，工作树干净。

## Qoder 审查

- CLI：`qoderclicn` 1.1.28；模型精确标识 `Qwen3.8-Max`；reasoning
  `high`；只读 Read/Grep/Glob；不持久化 session，未输出或记录任何 key/token。
- 设计边界审查：PASS，P0=0。要求 exhaustive state mapping、exact encounter identity、失败不
  catch/fallback、fresh route 的等价语义明确化；missing/multi 以 typed schema 构造失败证明，
  不为测试篡改 production schema。
- 最终 diff 审查：同一 CLI/模型/reasoning 实际执行并 PASS；P0=0、P1=0、P2=0
  blocking。两条 informational 已接受：typed schema 使两个 defensive `StateError` 分支
  不可直达；测试侧 `dart:io` 仅用于 source guard，不进入 production selector。

## 任务切片

1. 完整读取项目红线、已否清单、manifest/assignment/state、resolver、coverage gate 与测试。
2. Qoder/Qwen3.8-Max high 完成只读设计边界审查。
3. 新增测试并跑出有效红灯；用 `apply_patch` 实现薄 selector。
4. 跑 targeted 回归与 scoped 静态检查；Qoder 审查最终 diff，主 agent 复核 findings。
5. 更新恢复点，提交实现与证据，追加精确 READY 空提交。

## 当前恢复点

- 状态：实现、验证、Qoder 最终审查与证据均完成；按下一步提交并以 READY 空提交冻结。
- 最后完成：纯 selector、sealed immutable routes、10 组测试均已实现；有效红灯由目标文件/API
  缺失触发，随后转绿。Qoder 设计与最终审查均 PASS；P0=0、P1=0、P2=0 blocking。
- 下一步：提交当前 3 文件实现/证据，立即追加精确 `[READY][QODER][P2-M2-R10]`
  空提交；随后主控按 CLAUDE §8.2 评审。
- 已跑验证：`flutter pub get` 成功；`dart run build_runner build` 成功并写 126 个 ignored
  generated outputs；selector 10/10、resolver 5/5、manifest 15/15、migration gate 7/7、
  schema gateway 8/8，共 45/45 通过；scoped analyze 0 issue；format、staged
  `git diff --check` 与 3 文件严格白名单检查通过；`main == origin/main == e292d3a0`，未改 refs。
- 阻塞项：无。
