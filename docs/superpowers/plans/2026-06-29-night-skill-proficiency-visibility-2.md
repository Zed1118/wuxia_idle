# 招式熟练度可视化二期 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 统一战报、角色页、心法页与武学详情中的招式熟练度收益说明，让玩家知道同一招为什么越用越强。

**Architecture:** 复用一期 `SkillProficiencyFormatter` 与 `StageProgressRow`；战报只读取战斗快照里已有 `BattleCharacter.skillUses` 与 `NumbersConfig.skillProficiency`，不重算伤害公式；角色/心法/武学详情用同一 formatter 派生文案。UI 文案新增到 `UiStrings`，presentation 层不散写中文。

**Tech Stack:** Flutter Desktop · Riverpod 3 · Isar · Dart unit/widget tests · `flutter analyze`

---

## 任务范围

**分支:** `codex/night-skill-proficiency-visibility-2`

**验收标准:**
- 战报关键攻击行能显示该招当前熟练阶段与当前效果，例如伤害加成、冷却、破招减防/窗口，且信息来自 `BattleCharacter.skillUses` + `SkillProficiencyFormatter`。
- 角色页主修卡展示主修心法内熟练度最高的一招，并用 `StageProgressRow` 说明当前效果、下一阶和来源。
- 心法页每本心法展示该心法内熟练度最高的一招，并用同一格式说明收益。
- 武学详情页不只显示阶段名，也显示当前效果、下一阶效果和战斗放招来源。
- 不复制熟练度公式；新增格式化能力集中在 `SkillProficiencyFormatter`，文案集中在 `UiStrings` / `BattleLog` 合法集中层。
- 不修改 `data/numbers.yaml`、战斗结算公式、Isar schema 或 saveVersion。
- targeted tests 与 touched-file analyze 通过。

## 预计修改文件

- Modify: `lib/features/cultivation/application/skill_proficiency_formatter.dart`
  - 增加可复用的 compact 文案与从多招中选择最高熟练度摘要的 helper。
- Modify: `lib/features/battle/domain/battle_log.dart`
  - 在攻击 markers 中追加当前招式熟练度说明。
- Modify: `lib/features/character_panel/presentation/character_panel_screen.dart`
  - 主修卡追加主修招式熟练度 `StageProgressRow`。
- Modify: `lib/features/technique_panel/presentation/technique_panel_screen.dart`
  - 心法 tile 追加心法内招式熟练度 `StageProgressRow`。
- Modify: `lib/features/baike/presentation/skill_codex_detail_screen.dart`
  - 武学详情页显示当前/下一阶效果说明。
- Modify: `lib/shared/strings.dart`
  - 新增集中 UI 文案。
- Test: `test/features/cultivation/skill_proficiency_formatter_test.dart`
- Test: `test/combat/battle_log_test.dart`
- Test: `test/features/character_panel/presentation/character_panel_screen_test.dart`
- Test: `test/features/technique_panel/presentation/technique_panel_screen_test.dart`
- Test: `test/features/cangjingge/cangjingge_widgets_test.dart` 或 `test/features/cultivation/presentation/skill_treasure_overlay_test.dart` 若现有 widget 受影响。

## 任务切片

### Task 1: 计划与恢复点

- [x] **Step 1: 读取必读文档**

Read:
`AGENTS.md`
`CLAUDE.md`
`GDD.md`
`PROGRESS.md`
`docs/spec/playability_phase2_backlog.md`

- [x] **Step 2: 切分支**

Run:
```bash
git switch -c codex/night-skill-proficiency-visibility-2
```

- [x] **Step 3: 保存计划**

Create:
`docs/superpowers/plans/2026-06-29-night-skill-proficiency-visibility-2.md`

- [x] **Step 4: Commit 计划**

Run:
```bash
git add docs/superpowers/plans/2026-06-29-night-skill-proficiency-visibility-2.md
git commit -m "docs: 写招式熟练度可视化二期计划"
```

### Task 2: Formatter 二期能力

- [x] **Step 1: 写 formatter 测试**

Add tests that assert:
- `compactEffect` includes stage and current effect.
- `bestSkillSummaryForTechnique` returns the skill with the highest use count among a supplied skill list.
- Empty skill list or no matching usage returns null.

Run:
```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/cultivation/skill_proficiency_formatter_test.dart
```

- [x] **Step 2: 实现 formatter helper**

Modify `SkillProficiencyFormatter` to expose:
- `compactEffect({required SkillDef skill, required int uses, required SkillProficiencyConfig cfg})`
- `bestSkillSummaryForTechnique({required Iterable<SkillDef> skills, required Map<String, int> usage, required SkillProficiencyConfig cfg})`

- [x] **Step 3: Run formatter test**

Run:
```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/cultivation/skill_proficiency_formatter_test.dart
```

- [x] **Step 4: Commit**

Run:
```bash
git add lib/features/cultivation/application/skill_proficiency_formatter.dart test/features/cultivation/skill_proficiency_formatter_test.dart
git commit -m "feat: 扩展招式熟练度展示 formatter"
```

### Task 3: 战报熟练度说明

- [x] **Step 1: 写战报测试**

Add a `BattleLog.formatAction` test where actor has `skillUses[skill.id] = 300`; assert the output contains the configured stage/effect.

- [x] **Step 2: 实现战报 marker**

Modify `BattleLog.formatAction`:
- Read actor snapshot from `_findChar`.
- If action skill exists, call `SkillProficiencyFormatter.compactEffect`.
- Append returned text to `markers`.
- Keep this purely presentational; do not call damage calculator.

- [x] **Step 3: Run battle log test**

Run:
```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/combat/battle_log_test.dart
```

- [ ] **Step 4: Commit**

Run:
```bash
git add lib/features/battle/domain/battle_log.dart test/combat/battle_log_test.dart
git commit -m "feat: 战报显示招式熟练度效果"
```

### Task 4: 角色页与心法页展示

- [ ] **Step 1: 写/扩 widget tests**

Assert character panel and technique panel render at least one `StageProgressRow` whose current/next text matches `SkillProficiencyFormatter` output for a seeded technique usage.

- [ ] **Step 2: 实现角色页主修卡展示**

In `_MainTechniqueTile`, resolve current technique skill defs from `GameRepository.instance.skillDefs`, pick highest usage via formatter, render a compact `StageProgressRow` below cultivation row.

- [ ] **Step 3: 实现心法页 tile 展示**

In `_TechniqueTile`, use the same formatter helper and render the same `StageProgressRow` below the cultivation row.

- [ ] **Step 4: Run widget tests**

Run:
```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/character_panel/presentation/character_panel_screen_test.dart test/features/technique_panel/presentation/technique_panel_screen_test.dart
```

- [ ] **Step 5: Commit**

Run:
```bash
git add lib/features/character_panel/presentation/character_panel_screen.dart lib/features/technique_panel/presentation/technique_panel_screen.dart test/features/character_panel/presentation/character_panel_screen_test.dart test/features/technique_panel/presentation/technique_panel_screen_test.dart
git commit -m "feat: 角色与心法页显示招式熟练度"
```

### Task 5: 武学详情页展示

- [ ] **Step 1: 写/扩详情页测试**

Add or extend an existing widget test for `SkillCodexDetailScreen` so a practiced skill displays current effect, next effect, and source text.

- [ ] **Step 2: 实现详情页 StageProgressRow**

Use `SkillProficiencyFormatter.summarize` when `maxStage != null`; render `StageProgressRow` after base stat lines. If only `maxStage` is available without exact uses, use `maxStage.minUses` so the displayed effect is consistent with the shown stage.

- [ ] **Step 3: Run targeted test**

Run the relevant detail/widget test file.

- [ ] **Step 4: Commit**

Run:
```bash
git add lib/features/baike/presentation/skill_codex_detail_screen.dart test/features/cangjingge/cangjingge_widgets_test.dart
git commit -m "feat: 武学详情显示熟练度效果"
```

### Task 6: 验证与收口

- [ ] **Step 1: Run targeted tests**

Run:
```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/cultivation/skill_proficiency_formatter_test.dart test/combat/battle_log_test.dart test/features/character_panel/presentation/character_panel_screen_test.dart test/features/technique_panel/presentation/technique_panel_screen_test.dart test/features/cangjingge/cangjingge_widgets_test.dart
```

- [ ] **Step 2: Run touched-file analyze**

Run:
```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter analyze lib/features/cultivation/application/skill_proficiency_formatter.dart lib/features/battle/domain/battle_log.dart lib/features/character_panel/presentation/character_panel_screen.dart lib/features/technique_panel/presentation/technique_panel_screen.dart lib/features/baike/presentation/skill_codex_detail_screen.dart lib/shared/strings.dart test/features/cultivation/skill_proficiency_formatter_test.dart test/combat/battle_log_test.dart test/features/character_panel/presentation/character_panel_screen_test.dart test/features/technique_panel/presentation/technique_panel_screen_test.dart test/features/cangjingge/cangjingge_widgets_test.dart
```

- [ ] **Step 3: 更新 backlog 与 PROGRESS**

Mark `docs/spec/playability_phase2_backlog.md` 十二「招式熟练度可视化打磨」done and add a concise `PROGRESS.md` line if the implementation is complete.

- [ ] **Step 4: 更新恢复点并提交收口**

Run:
```bash
git add docs/superpowers/plans/2026-06-29-night-skill-proficiency-visibility-2.md docs/spec/playability_phase2_backlog.md PROGRESS.md
git commit -m "docs: 记录招式熟练度可视化二期完成"
```

## 当前恢复点

**状态:** Task 3 战报 marker 已完成，准备提交代码切片。

**最后完成:** 已提交 formatter 切片；`BattleLog.formatAction` 在 repo 已加载时从 actor `skillUses` 读取当前招式使用次数，追加熟练度阶段与当前效果 marker；`battle_log_test` 覆盖精通阶段输出。

**下一步:** 提交战报切片，然后执行 Task 4 角色页与心法页展示。

**已跑验证:** `mcp__codegraph.codegraph_status` 返回当前 worktree 未初始化；`DEVELOPER_DIR=/Library/Developer/CommandLineTools dart run build_runner build --delete-conflicting-outputs` 生成缺失 Isar/Riverpod 文件且未留下 git 变更；`DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/features/cultivation/skill_proficiency_formatter_test.dart` 通过；`DEVELOPER_DIR=/Library/Developer/CommandLineTools flutter test test/combat/battle_log_test.dart` 通过。

**阻塞项:** 无。CodeGraph 未初始化，按项目规则记录；本切片用 `rg` 和直接读文件继续。
