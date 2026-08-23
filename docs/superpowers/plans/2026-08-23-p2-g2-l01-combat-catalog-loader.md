# P2-G2-L01：战斗目录 Loader 与结构校验

## 目标

在 S01 typed schema 之上建立纯数据加载边界：由 caller 提供多个 archetype YAML、多个 encounter YAML 与一个 stage-assignment manifest YAML，加载为单一 `CombatCatalogManifestDef`。本任务不读取 production bundle、不接 `GameRepository`，也不创建 `data/combat/**`。

## 文件边界

- `lib/data/combat_encounter_catalog_loader.dart`
- `lib/data/validation/combat_encounter_catalog_validator.dart`
- 两份对应测试
- `test/fixtures/phase2/combat/catalog_loader/**`
- 本计划文件

禁止修改 S01/O01 类型、`GameRepository`、production host、任何 production YAML、registry 或其他测试；禁止 build_runner 与全量测试。

## 合同

- loader 只消费 caller 显式提供的具名 YAML source；不捕获错误、不生成 placeholder、不猜默认值。
- archetype 文档顶层仅允许 `archetypes`，encounter 文档仅允许 `encounters`，manifest 仅允许 `stage_assignments`；未知 key、缺 key、错误类型、非整数、未知 enum 全部带 source context 抛 `FormatException`。
- loader 在构造 typed manifest 前执行带 source + 叶子字段路径的 contextual preflight，提前定位重复 ID 与未知 archetype/role/encounter；S01 `CombatCatalogManifestDef` 仍是最终 authoritative gate，统一关闭跨目录引用、stage↔encounter 一对一、legacy/migrated both/neither 与外部 mutation。两层不得采用不同产品语义。
- 显式解析四类 attack token、四项 spawn config、四项 token budget、八类 objective ref；不选择具体关卡目标或填写任何平衡数值。
- YAML 命名使用 snake_case，Dart 类型和 ID 语义保持 S01 单一来源；加载结果不保留 caller 可变集合。

## 验收

- 有效的多文件 fixture 确定性生成 typed manifest，并覆盖全部八类 objective ref。
- malformed/unknown-key/wrong-type/non-integer/unknown-enum/duplicate/cross-reference/migration fixture fail closed，错误包含 source 名与字段路径。
- targeted tests、scoped analyze、`git diff --check` 通过。
- worktree clean，tip 为 `[READY][QODER][P2-G2-L01] 完成战斗目录加载与校验`。

## 当前恢复点

- 状态：实现和两轮主控补强完成；第一轮独立终审指出的重复 ID 叶子定位 P1 已修复，准备复审。
- 已验证：两份 targeted tests 57/57；scoped analyze 4 文件 0 issue；`dart format` 与 `git diff --check` 通过。
- 主控补强：所有 identifier、非有限 multiplier、migrated null encounter 与 malformed YAML 均在 source + 精确字段路径 fail closed；parsed DTO 集合不可变；archetype/encounter/role/spawn entry/objective item/stage/assignment encounter 重复均携带当前与首次声明位置；typed semantic `ArgumentError` 映射回 snake_case 叶子字段。
- 下一步：提交修复和新的 READY 标记，由独立 reviewer 复核增量；通过后才允许主控整合。
