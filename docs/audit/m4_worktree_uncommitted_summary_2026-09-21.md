# m4 worktree 未提交改动摘要（只读，供拍板）

- 位置：`~/Documents/Codex/2026-09-13/p2-ci-recovery/m4-54aed-worktree`，分支 `codex/p2-boss-label-layout-20260915`（tip `e743b6026` 2026-09-15）。**该分支已完整进 main**（`origin/main...HEAD` = 117/0），只有工作区脏。
- 未提交内容最后编辑 2026-09-14 19:21；无对应 `docs/superpowers/plans/` 计划文件、无收据、无 `[READY]`，属半成品。
- 体量：20 个跟踪文件 `+704 −121`（lib 12 / test 7 / build.yaml 1）+ 4 个未跟踪文件（3 测试 + 1 夹具 `test/fixtures/legacy_gauntlet_cooldown.dart`）。

## 它在做什么（一个主题，两条腿）

**断魂庄（gauntlet）招式冷却按「秒」跨关保留 + 在庄期间禁止手动装卸招式。**

1. **冷却检查点（含 schema 加法）**：`ActivityMemberSnapshot` 新增 `phase0aCooldownsRecorded` / `phase0aCooldownKeys` / `phase0aCooldownSeconds` 三个 Isar 字段（旧档缺字段读 false/空；旧的 `skillCooldownTurns` 保留、不换算成秒）；`GauntletController` 关末把各槽剩余秒数写入检查点，`CombatantSnapshot.openingSlotCooldownSeconds` 与 `Phase0aStageContentMapper._skillSlots` 在下一关开场按槽位恢复冷却（非法槽位/负数 fail-fast）。夹具 `legacy_gauntlet_cooldown.dart` 冻结旧 schema 做兼容测（`build.yaml` 把它加进生成排除）。
2. **占用锁**：`SkillLoadoutService`（技能槽）与 `EncounterService`（奇遇招式装/卸）在写事务内读 `CharacterOccupancyService` 快照，角色在断魂庄会话中则返回 `SlotEquipOccupied` / `EquipOccupied`、卸招抛 `EncounterSkillOccupiedError`；藏经阁与角色面板奇遇招式区显示 `UiStrings.gauntletSkillLoadoutOccupied`（「该角色正在断魂庄，离庄后方可装卸招式」）。

## 红线与风险

- 🔴 **schema 加法**（三字段），需拍板；未见 saveVersion 变更（当前代码只加字段，旧档读默认值）。
- 🔴 玩法语义：冷却跨关保留会让断魂庄比现状更难（现状每关重置）；「在庄禁装卸」是新限制。两者都改变玩家可见行为，不在任何已批 spec/plan 中。
- 与当前 main 的可合性：`git apply --check` 只在 `test/tools/compare_phase0a_headless_baseline_test.dart:45` 冲突一处（其余 19 文件干净）。
- 未跑过任何验证（无收据）；`+704` 中 test 约 550 行，说明作者按 TDD 写了大半。

## 三个处置选项

| 选项 | 做法 | 代价 |
|---|---|---|
| A 收编 | 先补一份 spec 让你拍冷却跨关 + 在庄禁装卸两条语义，再派 codex 在 main 新 worktree 上 `git apply` 这份 patch（已存 `~/.claude/jobs/51cd6f8f/tmp/m4.patch`，也可从原 worktree 重生成）、解 1 处冲突、补 saveVersion 与收据，走 Gate | 一次 spec 拍板 + 一单 |
| B 存档弃置 | 把 patch 存到 `docs/_archive/` 或打 `archive/` tag 后 `worktree remove --force` | 零风险，保留可追溯 |
| C 直接丢弃 | `worktree remove --force`（TCC 限制需走 Finder） | 最省，内容进历史即无 |

推荐 **A**（改动方向与二阶段 M5 断魂庄 durable 语义一致、测试已大半写好），但语义必须你先拍。
