# P2-M2-R04：Catalog → runtime 合同映射

## 目标与边界

在 C01 catalog schema 与 R03 objective controller 之上，新增一个极薄的纯 data → runtime bundle mapper：把单个 `CombatEncounterDef` 原样映射为现有 `SpawnDirector` / `AttackTokenBudgets` / `ObjectiveController`。本切片不接 production host，不构造 actor/roster/`Phase0aEncounterMapping`。

- 分支：`codex/phase2-m2-r04-runtime-contract-mapper-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r04-runtime-contract-mapper`
- 基线：`02ab6df5` （C01 + R03）
- 只允许：`lib/data/validation/combat_encounter_runtime_contract_mapper.dart`、`test/data/validation/combat_encounter_runtime_contract_mapper_test.dart`、本计划。
- 禁止：registry、`GDD.md` / `CLAUDE.md` / `PROGRESS.md`、其他 lib/test、production data/host/UI/save/reward/injury/tuning。

## 冻结合同

- spawn config 四字段与 token budget 四字段一对一原样传递，mapper 不写默认、clamp 或调优值。
- runtime enemy instance ID 必须由 caller 对每个 `CombatEncounterSpawnEntry` 显式解析；`entryId` 只作 `SpawnEntry.entryId`，不冒充 `enemyId`。
- 空白/重复 enemy ID 直接交给现有 `SpawnEntry` / `SpawnDirector` fail closed；resolver 的未知 ID 异常原样向外传播，mapper 不兜底。
- `tickDuration` 为显式 caller input，直接复用 R03 `mapCombatObjectiveComposition`。
- 每次映射创建 fresh spawn director、budget value 与 objective/controller owners；不缓存 caller 容器。

## 验收 checklist（CLAUDE §8.2）

- [x] 先红后绿：红测明确由新 mapper API 缺失触发。
- [x] 覆盖 spawn 四字段、token 四 budget、entry callback 顺序与 ID 一对一。
- [x] 覆盖 all/any 语义、显式 tick duration 换算与每次 fresh owner。
- [x] 覆盖 caller map 后续突变不回渗，未知/空白/重复 enemy ID fail closed。
- [x] 边界审计证明无 mapper 默认、无 production import，且只改三个白名单文件。
- [x] 生产接线证据：按授权明确不接 production host；交付供后续 host 消费的 runtime contract gateway，不冒充上线。
- [x] targeted mapper + R03 mapper/controller + spawn/token 回归全绿；scoped analyze 0 issue；format 与 `git diff --check` 通过。
- [x] 红线：0 production 数值、0 Dart 玩家文案、0 三系/奖励/伤势/save/UI/在线离线/反主流触点。
- [x] 普通实现 commit 后追加 `[READY][QODER][P2-M2-R04] catalog runtime 合同映射完成` 空提交，树干净。

## 任务切片

1. 读取 CLAUDE、rejected registry、C01/R03 plans 与现有 defs/runtime/mapper 合同。
2. Qoder CLI 无密钥泄漏连接/模型确认；新增测试并跑出红测。
3. 用 Qwen3.8-Max / high 在白名单内完成薄 mapper 主实现，主 agent 复核 diff。
4. 运行 targeted + R03 suites、scoped analyze、format、diff/path 审计。
5. 更新恢复点，普通提交并追加 READY 空提交。

## 当前恢复点

- 状态：实现、验证与分支冻结完成，待主控独立评审。
- 最后完成：新增纯 mapper/bundle；一对一映射 spawn/token/objective，caller resolver 按 content entry order 为每项提供 runtime enemy instance ID，不派生/不兜底。红测先因目标文件与 API 缺失编译失败，实现后转绿。
- 下一步：主控核对 diff、targeted 证据、runtime ID 边界与 P0/P1 风险后决定整合。
- 已跑验证：新 mapper 8/8、R03 mapper 11/11、R03 controller 8/8、SpawnDirector 33/33、AttackTokenDirector 26/26，共 86/86 通过；scoped analyze 8 files 0 issue；Dart format 2 files 0 changed。
- Qoder 实际使用：`qoderclicn` 1.1.28 的 `--list-models` 连接成功，实际以 `Qwen3.8-Max` + `--reasoning-effort high` + `accept_edits` 生成 mapper 主实现；文件写入完整，但 CLI 在总结阶段长时无输出，已主动中止会话并由主 agent 独立审查/修正测试与验收。全程未输出或传入凭据。
- 阻塞项：无。
- 生产接线：依任务授权不接 production host，不构造 actor/roster/`Phase0aEncounterMapping`；本交付是后续 host 的纯 runtime contract gateway。
- 红线影响：无 production data/数值、玩家文案、奖励、伤势、save、UI、三系、在线离线或反主流触点；mapper 不写默认/clamp/tuning。
- 残留风险：本切片不接 production host，故未跑全仓测试；后续 host 必须提供权威 roster/actor 解析，未知 ID 必须由 resolver fail closed，不得用 content `entryId` 替代 runtime enemy instance ID。
