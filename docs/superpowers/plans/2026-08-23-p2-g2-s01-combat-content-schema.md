# P2-G2-S01：战斗内容类型合同

## 范围

本切片建立三份不可变 typed def，与既有叙事 `EncounterDef`（encounter_def.dart）明确分名，不复用其类型或叙事语义：

- `lib/data/defs/combat_enemy_archetype_def.dart` — 敌人 archetype + variant role（含显式调优乘子）。
- `lib/data/defs/combat_encounter_def.dart` — encounter：spawn entries/config、attack-token budgets、内容中立 objective 原语引用、warning/grace。
- `lib/data/defs/combat_catalog_manifest_def.dart` — catalog manifest：archetype/encounter 目录 + stage↔encounter 唯一关联 + 跨目录引用解析。

只做数据类型与单测：不改 GameRepository、不读取生产 YAML、不接 host、不决定黑风岭 objective 或任何具体数值。

## 合同约定

- **显式 migrationState**：`CombatStageEncounterAssignment` 逐 stage 显式声明 `legacy | migrated`（无默认路由）；`migrated` 必须恰有一个 encounterId，`legacy` 必须无 encounterId（both/neither fail closed）。S01 只保证 manifest 内部形状；E05 resolver 与后续 migration Gate 负责 allowlist、legacy content、migrated content 和 assignment 的联合一致性，不由 schema 单独证明完整迁移语义。
- **archetype variant role 引用**：`CombatEncounterSpawnEntry(entryId, archetypeId, roleId)` 引用 archetype 的 variant role；manifest 构造期解析 archetypeId 与 roleId，未知引用形态 fail closed。
- **spawn entries/config**：`CombatEncounterSpawnConfig` 四项（activeLimit > 0、reinforcementThreshold ∈ [0, activeLimit)、entryWarningTicks ≥ 0、attackGraceTicks ≥ 0）全由 caller 显式输入，镜像 D01 `SpawnDirectorConfig`；encounter 至少一个 spawn entry，entryId 不重复。
- **attack-token budgets**：`CombatEncounterTokenBudgets` 四项（melee/ranged/charge/support）全显式、非负，镜像 D02 `AttackTokenBudgets`。
- **warning/grace**：由 spawn config 的 entryWarningTicks / attackGraceTicks 表达，全部 caller 输入、无默认值。
- **内容中立 objective 原语引用**：`CombatObjectivePrimitiveRef` sealed 八类（defeatTargets / destroyAnchors / reachCheckpoint / touchMarkers / surviveDuration / defendEntity / pursueTarget / defeatCommander），镜像 O01 八原语；kind 由具体 sealed subtype 表示，只携带显式参数（id 集合非空唯一干净、ticks 为正），不硬编码任何 stage/内容 ID，不选择黑风岭胜利条件。
- **stage 与 encounter 唯一关联**：manifest 中 stageId 唯一、encounterId 唯一（双向 1:1）；每个 catalog encounter 必须被恰一个 migrated stage 引用；migrated assignment 的 encounterId 必须存在于目录。
- **构造期 fail closed**：空白 ID、重复 ID/引用、未知引用形态、非有限乘子（NaN/±Infinity）、负值、数量/阈值/token 自洽违规全部抛 `ArgumentError`；错误文本英文、重复 id 排序稳定（与输入顺序无关）。
- **集合外部 mutation fail closed**：所有输入集合构造期防御性复制为不可变；暴露的 list/set 不可变（外部 add/clear 抛 `UnsupportedError`），构造后改调用方输入不影响 def。
- **无默认数值**：所有调优数值（乘子、阈值、budget、ticks）均由 caller 显式输入，schema 不提供任何数值默认。

## 验证

三份 targeted test 覆盖：合法构造与 lookup、空白/空白字符 ID、重复 roleId/entryId/archetypeId/encounterId/stageId/encounter 引用、未知 archetype/role/encounter 引用、非有限与负乘子、零 hp 乘子、负数 budget/阈值、空 spawn entries、空/重复/空白 objective id 集合、非正 ticks、legacy/migrated both/neither、外部 mutation 与不可变性。

## 冻结边界

- 不修改 `data/combat/**`、`data/stages.yaml`、`GameRepository` 或任何 production host。
- 不选择黑风岭伏击终局条件，不定义 40 敌人配比、补兵阈值、warning/grace 或 token enforce 语义。
- 不新增 UI/VFX、奖励、伤势、存档或导航逻辑；不新增依赖、不跑 build_runner。
- 新类型不携带中文玩家文案；所有数值字段由 caller 显式提供且构造期 fail closed。

## 当前恢复点

- 状态：实现、验证、独立审查和主控整合均已完成；任务 tip 为 READY `d7cc6531`。
- 最后完成：三份 typed def + 三份单测已整合到 Batch7；与 O01 八原语 subtype 对齐。
- 后续验证：L01 已消费 schema，O02 穷尽映射与 L02 migration Gate 已完成跨合同验证并整合；S01 仍不切 production host。
- 已跑验证：三份 targeted test 48/48 全过；scoped analyze（6 文件）0 issue；`dart format` 0 changed；`git diff --check` 净。全仓 analyze 4512 issue 均为 fresh worktree 缺 gitignored `.g.dart` 的既有基线（build_runner 被本任务禁止），0 条涉及本切片文件。
- 阻塞项：production objective、具体调优值与 host 路由仍未冻结；不阻塞 L01 loader、O01 映射或 L02 migration Gate。
