# P2-G2-D09：Typed Encounter Mapping

## 目标

在 Batch5 `assembleEncounter` 已冻结的输入之上，新增不可变
`Phase0aEncounterMapping`（`lib/features/battle/application/phase0a/phase0a_encounter_mapping.dart`），
并为 `Phase0aProductionFlowAssembler` 增加 typed bridge（委托既有
`assembleEncounter`）。本切片只打包已冻结的动态 runtime 输入，不切换
production host、不猜黑风岭 encounter 数据、不 token enforce。

## 分支

`codex/phase2-g2-d09-typed-encounter-mapping-20260823`（当前 worktree，HEAD `eb121aea`）。

## 冻结契约（Batch6 协调计划 + 本切片）

- mapping 只携带 Batch5 `assembleEncounter` 已接受的：`initialState` /
  `director` / `roster` / `combatants` / `moveBindings` /
  `playerAdapter` / `enemyAiAdapter`；列表与映射做防御性不可修改副本。
- mapping/bridge 不复制伤害、AI、移动、spawn、终局或 RNG 规则；caller 仍
  显式传 `NumbersConfig` 与单一 `Random`，可选 observe-only observer 也由
  caller 在 bridge 处显式传入（不冻结进 mapping）。
- 构造期至少验证：director 与 roster identity、player id 一致性、
  combatant actor id 重复；全场 actor 精确覆盖与 move binding 校验仍由
  既有 assembler fail closed，避免行为漂移。
- 保留 legacy `assemble` 与直接 `assembleEncounter` 源码兼容（签名/返回
  类型/默认路径零改动）。
- 不实现 loader、stage id、host route、数据、调参、objective、token
  enforce、UI、reward 或 save；英文 Dart 注释与错误文本优先，不新增依赖。

## 验收 checklist（本切片）

- [ ] `Phase0aEncounterMapping` 构造期对 director/roster identity、
      player id 一致性、combatant actor id 重复 fail-fast，错误文本英文且
      重复 id 稳定排序。
- [ ] combatants 列表与 moveBindings 映射防御性不可修改：外部 mutation
      不污染已冻结 mapping，mapping 自身集合不可变。
- [ ] typed bridge 与直接 `assembleEncounter` 同 seed 回放全等
      （events/state/outcome/records），observer 经 bridge 透传生效。
- [ ] bridge 委托路径上 assembler 原有 fail-closed（actor 覆盖 /
      playerAdapter id / move binding）仍生效且零 RNG 消费。
- [ ] legacy `assemble` 与直接 `assembleEncounter` 回归继续通过。
- [ ] targeted test、关联 assembler/encounter 回归、scoped analyze、
      `dart format`、`git diff --check` 通过。
- [ ] 不触及数值硬红线、三系锁死、在线=离线、反主流机制；无中文文案/
      数值常量散写进 Dart（新代码全英文注释/错误文本）。

## 任务切片

1. 计划文件落盘（本文件）。
2. 新增 `Phase0aEncounterMapping`（构造期三校验 + 防御性副本）。
3. 在 assembler 增加 `assembleEncounterFromMapping` typed bridge，
   委托既有 `assembleEncounter`，caller 显式传 numbers/rng/observer。
4. 新增 `test/.../phase0a_encounter_mapping_test.dart`：构造校验、
   防御性不可修改、bridge parity、bridge fail-closed 透传与零 RNG 消费。
5. `dart format` → targeted test（mapping + assembler + encounter 回归）
   → scoped `dart analyze` → `git diff --check`。
6. diff 复审 → 普通中文动宾小切片 commit → 空 commit
   `[READY][PI][P2-G2-D09] 完成类型化遭遇映射桥接` → 工作树干净。

## 当前恢复点

- 状态：**D09 已完成**（mapping + bridge + 测试 + 验证全绿，待合并评审）。
- 最后完成：`Phase0aEncounterMapping` 不可变 carrier（三校验 + 防御性副本）、
  assembler `assembleEncounterFromMapping` bridge、mapping 专项测试
  （构造校验 / 不可修改性 / bridge parity / fail-closed 透传）。
- 下一步：由 Batch6 主控复审三路 diff（D09/D10/E05）并整合。
- 已跑验证：targeted mapping 测试 + assembler/encounter 关联回归全 PASS；
  scoped `dart analyze` 0 issue；`dart format` 0 changed；`git diff --check` 净。
- 阻塞项：无；黑风岭 encounter 内容与 objective/token enforce 语义仍
  未冻结，但不阻塞本批纯合同。
