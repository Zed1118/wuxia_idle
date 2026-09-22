# 断魂庄招式冷却跨关保留 + 在庄禁装卸 · 设计草案（待拍板）

- 状态：`DRAFT_AWAITING_DECISION`（两条玩法语义 🔴，用户未拍前不派单、不实装）
- 日期：2026-09-22 · 基线 `8d8ae9195`（main）
- 来源：m4 worktree 未提交半成品（`docs/audit/m4_worktree_uncommitted_summary_2026-09-21.md`），处置选项 A「收编」的前置 spec
- 体量上限：本文 ≤150 行；实装单另出派单包

## 1. 现状实况（2026-09-22 现查）

- 断魂庄一局三关，关间边界由 `GauntletMemberCheckpoint`（`lib/features/boss_gauntlet/application/gauntlet_controller.dart:66`）承载：**只带 HP / 真气**。
- `ActivityMemberSnapshot` 已有 `skillCooldownKeys` / `skillCooldownTurns` 两字段，`gauntlet_service.dart:824-827` 会把它们塞进 `openingSkillCooldowns`；但 `gauntlet_controller.dart:61-62` 关末只是 `List.from(prior.…)` 原样复制，**从不写入关末剩余冷却**——两字段事实上恒为初值，招式冷却**每关清零**。
- Phase 0A 侧 `openingSkillCooldowns` 是「回合数 × 秒」口径（`phase0a_stage_content_mapper.dart:864-868`，仅敌方消费），玩家槽位没有按秒恢复冷却的入口。
- 装卸招式：`SkillLoadoutService`（技能槽）与 `EncounterService`（奇遇招式装/卸）当前**不读**活动占用；角色在庄期间（会话 active）仍可在藏经阁/角色面板换招，下一关开场按新装配生成快照——等于关间无代价洗牌。
- `saveVersion` 现为 `0.50.0`（`lib/data/isar_setup.dart:252`），GDD/CLAUDE.md 头部写的 0.45.0 已 drift。

## 2. 两条玩法语义（🔴 逐条拍 是/否）

| # | 语义 | 现状 | 改后 | 玩家可见影响 |
|---|---|---|---|---|
| S1 | **招式冷却按秒跨关保留**：关末各槽剩余冷却秒数写进检查点，下一关开场按槽位恢复；HP/真气本就跨关 | 每关冷却清零 | 上一关末尾放的大招，下一关开场仍在冷却 | 断魂庄整体更难；「三关一口气」的连贯感增强；与「波间保留 HP/真气」（GDD v1.49 主线扩波）同向 |
| S2 | **在庄期间禁止手动装卸招式**：角色处于断魂庄 active 会话时，技能槽与奇遇招式装/卸在写事务内被拒，UI 灰显并提示「该角色正在断魂庄，离庄后方可装卸招式」 | 关间可任意换招 | 入庄前的装配即整局装配 | 关闭关间洗牌；与既有「装备/心法在活动占用中不可动」（`CharacterOccupancyService` 对闭关/远征/断魂庄的占用语义）对齐 |

- 两条独立可拍：`S1 是 / S2 是` 最完整；只拍其一也可实装（S1 不依赖 S2；S2 单独成立但意义减半——冷却每关清零时锁装配只防「换更强招」）。
- 推荐 **两条都要**：断魂庄是「首通亲战 + 完整首通后 headless 重刷」的高难连续挑战（GDD §决议 2026-08-24），三关连续性正是它区别于塔/主线单关的设计点；两条都不改数值、不改奖励、不改解锁。

## 3. 数据与 schema（S1 成立时）

- `ActivityMemberSnapshot` 加三字段（Isar 嵌入/collection 加法）：`phase0aCooldownsRecorded: bool`（默认 false）、`phase0aCooldownKeys: List<String>`、`phase0aCooldownSeconds: List<double>`。旧档缺字段读 false/空 → 视为「未记录」，下一关开场冷却全空（与现状一致）；旧 `skillCooldownTurns` 保留不换算、不删。
- `saveVersion 0.50.0 → 0.51.0`，纯加法，迁移段只写注释与版本号，不回填、不推断历史冷却。**🔴 schema 加法需用户拍板**（与 S1 一并拍）。
- 兼容夹具 `test/fixtures/legacy_gauntlet_cooldown.dart` 冻结旧 schema 做「旧档缺字段 → 未记录」回归；`build.yaml` 排除其代码生成。

## 4. 实装形态（收编 m4 patch）

- 派 codex：在 main 新 worktree `git apply` 已存 patch（`~/.claude/jobs/51cd6f8f/tmp/m4.patch`，可从原 worktree `git diff` + 4 个未跟踪文件重生成），仅 `test/tools/compare_phase0a_headless_baseline_test.dart:45` 一处冲突；补 `saveVersion` bump（段 21）+ 迁移注释；按用户拍板结果**删掉未批准的那条腿**（S1 或 S2 任一否决则整腿不进）。
- 触点（patch 实测 20 文件 `+704 −121` + 4 新文件）：`activity_member_snapshot.dart` / `combatant_snapshot.dart`（`openingSlotCooldownSeconds`）/ `phase0a_stage_content_mapper.dart`（`_skillSlots` 按槽恢复，非法槽位/负数 fail-fast）/ `gauntlet_controller.dart`（关末写检查点）/ `gauntlet_service.dart` / `phase0a_gauntlet_stage_runner.dart`（headless 同路径）/ `skill_loadout_service.dart` / `encounter_service.dart` / `cangjingge_screen.dart` / `encounter_skill_section.dart` / `strings.dart`（一条 `UiStrings`）。
- 在线 = 离线：live `GauntletController` 与 headless `Phase0aGauntletStageRunner` 必须走同一检查点写/读路径，`gauntlet_live_headless_parity_test.dart` 断言两者关末冷却快照逐槽相等。

## 5. 红线自检

- §5.1 反主流：无（不是体力/日课/付费恢复）。§5.4 数值：零改。§5.5 在线=离线：live/headless 同核同检查点，parity 测试守。§5.6 硬编码：文案走 `UiStrings`；秒数来自 reducer 运行态，无常量。§5.3 三系锁死：不涉及。
- GDD 合同：S1/S2 任一通过后须在 GDD 断魂庄段补一句（🔴 GDD 修改随实装单一并提交，标题 `[GDD]`）。

## 6. 验收（实装单）

1. RED：新增 `phase0a_gauntlet_cooldown_checkpoint_test` / `gauntlet_skill_loadout_occupancy_test` / `gauntlet_cooldown_compatibility_test` 在基线上必红（patch 自带，协调者复跑）。
2. 破坏证红双向：① 摘掉关末写检查点 → 跨关恢复断言红；② 把 `phase0aCooldownsRecorded` 写死 `false` → 兼容夹具外的恢复断言红；③ 摘掉占用读 → 禁装卸断言红。各自还原后绿。
3. 定向：`test/features/boss_gauntlet/` 全目录 + `test/features/activity/` + `test/shared/battle_shared/` 逐文件 `All tests passed!`；`compare_phase0a_headless_baseline_test` 冲突解后绿。
4. 全量 `flutter test --no-pub` 绿，analyze 0，format 0 changed；`[schema]` 前缀 commit，PR 描述列 `ActivityMemberSnapshot` 三字段与 `0.51.0`。
5. 真机一次：断魂庄第一关末放大招 → 第二关开场该槽显示剩余冷却；庄内打开藏经阁，装卸按钮灰显+提示。

## 7. 明确不做

- 不改断魂庄敌人数值、奖励、门票、周目、解锁；不改冷却时长本身（仍 `turns × 0.55s` 物化口径）；不开放前台可见 bot；不把冷却跨关推广到主线/塔（各自既有编排不动，GDD v1.49 口径）。
