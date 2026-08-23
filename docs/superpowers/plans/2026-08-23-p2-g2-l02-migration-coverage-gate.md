# P2 G2 L02：Migration Coverage Gate

## 目标

在 `CombatCatalogManifestDef` 之上新增纯内存 migration coverage validator。调用方必须显式提供 `knownStageIds`、`legacyAllowlist`、`legacyContentStageIds` 与 manifest；Gate 将这些事实交给 Batch6 E05 `Phase0aEncounterMigrationResolver` 复核联合迁移形状。本切片不读取生产文件、不接 `GameRepository` / production host，也不选择任何黑风岭 objective、数量或 tuning。

## 分支与基线

- 分支：`codex/phase2-g2-l02-migration-coverage-gate-20260823`
- 基线：`codex/phase2-g2-batch7-data-contracts-20260823`
- 基线 tip（开工前 fast-forward 后）：`e2c3da76`
- `main` / `origin/main`：禁止修改、合并或推送

## 验收标准

- validator 仅接受 caller 显式输入，不做文件 IO、生产加载或 stage 推断。
- `knownStageIds` 非空；known、allowlist 与 legacy-content ID 均非空且无空白、不得重复，后两者必须属于 known。
- 每个 known stage 恰有一个 manifest assignment；未知 assignment、未知 allowlist/content stage、遗漏与重复全部 fail closed。
- `migrated` 必须解析到 encounter、不得残留 legacy allowlist、不得仍有 legacy content；`legacy` 必须在 allowlist、必须仍有 legacy content 且不得携带 encounter。
- Gate 为每个 known assignment 映射 E05 state，派生 `encounterCount`（0/1）与 `hasLegacyContent` 并实际调用 resolver；无更具体结构化错误时用稳定的 `resolverRejectedStage` 兜底。
- 成功报告中的 known / migrated / legacy / legacy-content stage ID 排序稳定且不可变；聚合错误按固定 code + stage ID 稳定排序。
- fixture 仅使用中性测试 ID，不引用真实 `stages.yaml` / `data/combat`，不定义黑风岭产品内容。
- targeted test、scoped analyze、`git diff --check`、严格白名单检查通过。
- 纯合同切片按任务要求明确不接生产路径；不触及数值红线、三系锁死、在线=离线、反主流项、UI/reward/save。
- 工作区最终 clean，先提交实现，再以 `[READY][CODEX][P2-G2-L02]` 空提交封签；不 merge `main`、不 push。

## 任务切片

1. fixture 驱动写红测，覆盖成功报告、未知/遗漏/重复/脏 ID、allowlist/content 漂移与稳定排序。
2. 实现纯 validator、报告、结构化错误与 E05 联合合同调用。
3. 运行 targeted test 与 scoped analyze，检查 diff/白名单。
4. 独立只读审查后修正，提交实现并追加 READY 空提交。

## 当前恢复点

- 状态：主控复审指出的第一版 P1 缺口已关闭；补强实现、动态验证、独立只读复审与主会话验收均完成，准备提交 fix 与新 READY 空提交。
- 最后完成：Gate 已接收并验证 caller-provided `legacyContentStageIds`，并为每个 known assignment 实际执行 E05 resolver 联合合同；独立只读终审 0 findings（P0-P3）。
- 下一步：主会话按批次节奏复核并集成新 tip；本分支不 merge `main`、不 push。
- 已跑验证：第一版有效 RED 为目标文件/API 不存在；第一版 GREEN 为 6/6。P1 补强有效 RED 为缺少 required `legacyContentStageIds` API 而编译失败；补强 GREEN 为 `flutter test --no-pub --no-test-assets -j 1 test/data/validation/combat_catalog_migration_gate_test.dart` 通过 7/7；`flutter analyze --no-pub lib/data/validation/combat_catalog_migration_gate.dart test/data/validation/combat_catalog_migration_gate_test.dart` 为 0 issues；`dart format`、JSON 解析、`git diff --check` 与严格 5 文件白名单检查通过；独立只读终审 0 findings。
- 阻塞项：无。L02 当前未登记在 task registry，本切片不需要且不会修改 registry。
