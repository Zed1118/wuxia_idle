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
5. 运行九文件 targeted，验收固定为 `77/77`；运行 18 文件 scoped analyze、`git diff --check` 和范围 diff check。
6. 由未参与实现的独立子 agent 终审实际 diff、祖先/对象证据、范围和验证结果。

## 验收 checklist

- [x] 旧 M1 集成 tip 是冻结基线祖先。
- [x] Batch7 基线中九个实现与九个测试全部存在。
- [ ] 每个合同均记录对象相等性或后续漂移来源与保留理由。
- [ ] 不引入产品语义、生产接线、数据、存档、UI、host 或数值改动。
- [ ] targeted tests 为 `77/77`。
- [ ] 18 文件 scoped analyze 为 0 issue。
- [ ] `git diff --check` 与范围 diff check 通过。
- [ ] 独立子 agent 终审无阻断项。
- [ ] 工作区全部提交，tip 以 `[READY][CODEX][P2-M1-REVALIDATION]` 空提交收口。

## 当前恢复点

- 状态：文档与 Git 事实核对完成，进入当前基线合同复验。
- 最后完成：确认旧集成 `f93c29e6` 是冻结基线 `1a7ddbf9` 的祖先；18 个目标文件全部存在，六组对象与旧集成完全一致，防御/状态/真气存在有来源的后续演进。
- 下一步：审查四个漂移对象，运行 `77/77` targeted 与 18 文件 scoped analyze，形成新审计并交独立子 agent 终审。
- 已跑验证：祖先关系检查通过；目标文件存在性和对象哈希比较完成。
- 阻塞项：无。Batch7 分支在派发后继续前移，因此本任务固定使用派发快照 `1a7ddbf9`，不追逐并发 WIP。

