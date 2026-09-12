# yaml 清单补记 — 8bb82d2c4 / 341f94e9f

2026-09-12。项目 CLAUDE.md 要求「涉及配置 schema 变化：标题前加 `[schema]`，
并在 PR 描述中列影响的 yaml 文件」。下面两个 commit 的 body 缺这份清单。

**不走 `git commit --amend`**：两个 SHA 已被 7 处证据引用（task_registry.yaml、
dispatch yaml、audit 文档、PROGRESS.md，以及 `~/Documents/Codex/2026-09-12/
tower-first-batch/` 下的 delivery.json / candidate-commit.json /
candidate-manifest.json），改写历史会把这些引用全部打断。改用 `git notes` 附加
（不动 SHA），并在此落一份不依赖 notes ref 的持久记录。

`git notes` 存在 `refs/notes/commits`，默认不随 `git push` 推送。要带走需显式
`git push origin refs/notes/commits`；本文件是它的兜底副本。

## 8bb82d2c4 `[schema] 整合收益存档修复与塔目标及战斗接线`

数值 / schema 层：

| 文件 | 变更 | 内容 |
|---|---|---|
| `data/numbers.yaml` | +43 | 新增 `phase0a_arena.weapon_mapping`（timeline B / qi C / M3 CD 组合，M0 已拍板） |
| `data_schema.md` | +17 | 随上条同步 schema 文档 |

内容 / 构建层：

| 文件 | 变更 |
|---|---|
| `data/narratives/stages/stage_02_01_defend_guidance.yaml` | +5 |
| `build.yaml` | +1 |

派单台账（非数值层）：`docs/dispatch/phase0a_overhaul/decision_registry.yaml`、
`docs/dispatch/phase0a_overhaul/task_registry.yaml`。

## 341f94e9f `补齐塔机制验证并迁移首批七层`

影响的 yaml 均为派单 / 契约台账，不含数值 schema，故标题无需 `[schema]` 前缀：

- `docs/dispatch/phase0a_overhaul/task_registry.yaml`
- `docs/dispatch/phase2_wiring/test_contract_migrations/2026-09-12-tower-first-seven.yaml`

该 commit 把三条工作流合并落了一次（评审已记：应拆分提交）：塔机制验证补齐
（A/B 平价）、首批七层迁移（`Phase0aTowerEncounterRouteAuthority.production`
的 `migratedFloorIndices = {1..7}`）、契约迁移台账登记。

闸门提示：`review_gaps_block_floor_migration` 本批由执行链自清，非用户拍板。
下一批迁层前该闸门必须由用户翻转，见 `task_registry.yaml` 的
`next_batch_floor_migration_requires_user_signoff`。
