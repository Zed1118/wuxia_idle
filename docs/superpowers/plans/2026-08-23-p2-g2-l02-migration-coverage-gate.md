# P2 G2 L02：Migration Coverage Gate

## 目标

在 `CombatCatalogManifestDef` 之上新增纯内存 migration coverage validator。调用方必须显式提供 `knownStageIds`、`legacyAllowlist` 与 manifest；本切片不读取生产文件、不接 `GameRepository` / production host，也不选择任何黑风岭 objective、数量或 tuning。

## 分支与基线

- 分支：`codex/phase2-g2-l02-migration-coverage-gate-20260823`
- 基线：`codex/phase2-g2-batch7-data-contracts-20260823`
- 基线 tip（开工前 fast-forward 后）：`e2c3da76`
- `main` / `origin/main`：禁止修改、合并或推送

## 验收标准

- validator 仅接受 caller 显式输入，不做文件 IO、生产加载或 stage 推断。
- `knownStageIds` 非空、ID 非空且无空白、不得重复；`legacyAllowlist` 同样保持 ID 干净且不得重复。
- 每个 known stage 恰有一个 manifest assignment；未知 assignment、未知 allowlist stage、遗漏与重复全部 fail closed。
- `migrated` 必须解析到 encounter 且不得残留 legacy allowlist；`legacy` 必须在 allowlist 且不得携带 encounter。
- 成功报告中的 known / migrated / legacy stage ID 排序稳定且不可变；聚合错误按固定 code + stage ID 稳定排序。
- fixture 仅使用中性测试 ID，不引用真实 `stages.yaml` / `data/combat`，不定义黑风岭产品内容。
- targeted test、scoped analyze、`git diff --check`、严格白名单检查通过。
- 纯合同切片按任务要求明确不接生产路径；不触及数值红线、三系锁死、在线=离线、反主流项、UI/reward/save。
- 工作区最终 clean，先提交实现，再以 `[READY][CODEX][P2-G2-L02]` 空提交封签；不 merge `main`、不 push。

## 任务切片

1. fixture 驱动写红测，覆盖成功报告、未知/遗漏/重复/脏 ID、allowlist 漂移与稳定排序。
2. 实现纯 validator、报告与结构化错误。
3. 运行 targeted test 与 scoped analyze，检查 diff/白名单。
4. 独立只读审查后修正，提交实现并追加 READY 空提交。

## 当前恢复点

- 状态：实现与验证完成，准备提交实现并追加 READY 空提交。
- 最后完成：targeted test 使用 `--no-test-assets -j 1` 通过 6/6；scoped analyze 检查 2 个目标文件且 0 issues；实现后独立只读终审 0 findings（P0-P3）。
- 下一步：主会话独立复核本切片并按批次节奏集成；本分支不 merge `main`、不 push。
- 已跑验证：开工前 HEAD/指定基线均为 `e2c3da76`；有效 RED 为 `flutter test --no-pub test/data/validation/combat_catalog_migration_gate_test.dart` 因目标文件/API 不存在而失败；GREEN 为 `flutter test --no-pub --no-test-assets -j 1 test/data/validation/combat_catalog_migration_gate_test.dart` 通过 6/6；`flutter analyze --no-pub lib/data/validation/combat_catalog_migration_gate.dart test/data/validation/combat_catalog_migration_gate_test.dart` 为 0 issues；`dart format`、JSON 解析、`git diff --check` 与严格新文件白名单检查通过；独立只读终审 0 findings。
- 阻塞项：无。L02 当前未登记在 task registry，本切片不需要且不会修改 registry。
