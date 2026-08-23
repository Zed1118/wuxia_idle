# P2 M1 C02-C10 Batch7 重验计划

## 元数据

- taskId：`P2-M1-REVALIDATION`
- branch：`codex/phase2-m1-revalidation-20260823`
- frozen baseline：`1a7ddbf9b52ea1de161df242e2e0ee68f8fe82a3`
- baseline ref at dispatch：`codex/phase2-g2-batch7-data-contracts-20260823`
- old integration：`f93c29e6c5130ba1a95f56fe93c3c5ef343f680b`
- 性质：只重验并在确有缺口时选择性重放；不合并或 push `main`

## 目标与范围

在 Batch7 委派快照上独立复核 M1 C02-C10 九个纯领域合同：

- `combat_geometry`
- `action_timeline`
- `defense_resolution`
- `posture`
- `status_effects`
- `qi_resource`
- `basic_attack_chain`
- `combat_modifiers`
- `combat_event_order`

允许修改仅为上述九个实现、对应九个测试，以及本计划和新的重验审计。公共 `phase0a_combat_model` / reducer、`data/**`、save、UI、host、数值、task registry 均禁止修改。

## 重验方法

1. 读取 `CLAUDE.md`、`GDD.md`、《二阶段优化方案》M1、旧候选审计、task registry 与已否任务清单。
2. 验证旧集成是否为当前基线祖先，并逐文件比较旧集成与当前 18 个目标对象。
3. 仅对当前基线缺失且仍符合纯领域、调用方注入、无最终平衡值边界的提交执行重放。
4. 对已有后续演进的合同审查其来源、兼容性和测试；禁止用旧对象覆盖有效补强。
5. 运行九文件 targeted；旧核心 `77/77`、C16 加固 `4/4` 与 P2 有限值回归 `1/1` 均须通过；运行 18 文件 scoped analyze、`git diff --check` 和范围 diff check。
6. 由未参与实现的独立子 agent 终审实际 diff、祖先/对象证据、范围和验证结果。

## 验收 checklist

- [x] 旧 M1 集成 tip 是冻结基线祖先。
- [x] Batch7 基线中九个实现与九个测试全部存在。
- [x] 每个合同均记录对象相等性或后续漂移来源与保留理由。
- [x] 不引入产品语义、生产接线、数据、存档、UI、host 或数值改动。
- [x] 旧核心 `77/77`、C16 加固 `4/4` 与 P2 有限值回归 `1/1` 均通过；当前完整 targeted 为 `82/82`。
- [x] 18 文件 scoped analyze 为 0 issue。
- [x] `git diff --check` 与范围 diff check 通过。
- [x] 独立子 agent 终审无 P0/P1；其发现的基线既有 P2 已按主控要求闭环并复验。
- [x] 工作区全部提交，tip 以 `[READY][CODEX][P2-M1-REVALIDATION]` 空提交收口。

## 当前恢复点

- 状态：全部重验、P2 闭环、动态验证与 Git 收口完成；分支以新的 READY 空提交冻结。
- 最后完成：slow `movementMultiplier` 现在对 `NaN`、`+Infinity`、`-Infinity` fail closed；C06 `13/13`、九合同 `82/82`、18 文件 scoped analyze 0 issue。
- 下一步：无实现待办；仅待上游只读评审与按需集成，本任务不合并 main、不 push。
- 已跑验证：祖先关系、目标文件存在性、对象哈希、import/禁区扫描、测试声明计数、漂移来源、C06 targeted、完整 targeted、scoped analyze、diff/scope check 和独立终审均完成。
- 阻塞项：无。首轮测试因 fresh worktree 缺 `.dart_tool/package_config.json` 在 0 测试时触发 Flutter native-assets 工具崩溃；执行 `flutter pub get --offline` 仅生成忽略元数据后复跑通过，未改 lockfile/依赖。
