# 开锋槽 3 专属技内容化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 给装备开锋第三槽补真正的装备专属技能候选、配置与 UI 空状态,增强装备 build 深度。

**Architecture:** 复用现有 `EquipmentDef.specialSkillCandidates`、`ForgingSlotType.specialSkill`、`SkillSource.special` 与 `BattleState` 已有专属技注入路径。新增内容只落 `data/skills.yaml` 与 `data/equipment.yaml` 候选映射,不改 schema/saveVersion/numbers.yaml;UI 只补专属候选可读性和空状态文案。

**Tech Stack:** Flutter Desktop, Riverpod 3.x, Isar, YAML data, existing forging/equipment/battle skill pipeline.

---

## Scope And Constraints

- 分支:`codex/next-special-skill-slot3-content`
- 不改 `numbers.yaml` / Isar schema / saveVersion。
- 不新增开锋槽字段;不改变开锋消耗、解锁等级或已有一二槽数值。
- 装备专属技使用 `source: special`、`parentTechniqueDefId: null`、`tier: 1..7`、`style` 对齐装备 `schoolBias`。
- 候选只给 weapon,armor/accessory 继续空候选并显示空状态。
- 需守倍率 ≤8000;专属技 `tier` 让 `SkillDef.canEquipAtRealm` 继续守三系锁死。

## Current Findings

- `lib/data/defs/equipment_def.dart` 已支持 `specialSkillCandidates` 缺省空 list。
- `lib/features/equipment/application/forging_service.dart` 已校验候选非空、id 在候选内、槽 3 仅 `specialSkill`。
- `lib/features/battle/domain/battle_state.dart` 已把已开锋装备的 `specialSkillId` 注入 `availableSkills`,并按 `canEquipAtRealm` 过滤。
- `data/equipment.yaml` 当前 36 件 weapon 都映射到既有心法招式候选,属于内容占位。
- `data/skills.yaml` 当前 184 招;`test/data/game_repository_test.dart` 固定总数 224(含 40 encounter),需随新增招式更新。
- `forging_panel.dart` 已有“该装备无专属技能”空状态;需要补“候选说明/空候选原因”可读性。
- CodeGraph 在本 worktree 未初始化,本次使用 `rg` 与定点文件读取。

## Tasks

### Task 1: Data Content

**Files:**
- Modify: `data/skills.yaml`
- Modify: `data/equipment.yaml`
- Modify: `test/data/game_repository_test.dart`

- [x] Add 21 equipment-special skills to `data/skills.yaml`: 7 tiers × 3 styles, all `source: special`, no parent technique, `targetType: single`, `tier` filled.
- [x] Replace each weapon's `specialSkillCandidates` with matching equipment-special ids by tier/style.
- [x] Update repository count test from 224 to 245 and assert weapon candidates point only to `SkillSource.special` skills with non-null `tier/style`.
- [x] Run `flutter test --no-pub test/data/game_repository_test.dart test/data/skill_source_redline_test.dart`.

### Task 2: UI Empty/Candidate State

**Files:**
- Modify: `lib/features/equipment/presentation/forging_panel.dart`
- Modify: `lib/shared/strings.dart`
- Modify: `test/features/equipment/presentation/forging_panel_test.dart`

- [x] In slot 3 candidate picker, show each candidate's name plus tier/style/power summary.
- [x] Replace the generic empty text for slot 3 with a clearer empty state saying this weapon has not recorded a dedicated edge skill.
- [x] Keep all Chinese strings in `UiStrings`; do not inline presentation text.
- [x] Add/adjust widget tests for empty state and candidate summary.
- [x] Run `flutter test --no-pub test/features/equipment/presentation/forging_panel_test.dart`.

### Task 3: Battle Gate Regression

**Files:**
- Modify: `test/features/battle/domain/battle_character_forging_bake_test.dart`

- [x] Add a regression test proving a low realm character does not receive a higher-tier slot 3 special skill even if the equipment instance contains that skill id.
- [x] Run `flutter test --no-pub test/features/battle/domain/battle_character_forging_bake_test.dart`.

### Task 4: Final Verification And Commit

- [x] Run targeted tests from Tasks 1-3.
- [x] Run `flutter analyze`.
- [x] Update this plan's recovery point.
- [x] Commit with a concise Chinese message.

## Acceptance Criteria

- Weapon slot 3 candidates are real equipment-special skills, not direct aliases to ordinary technique skills.
- Armor/accessory empty candidates remain valid and UI explains the empty state.
- Slot 3 selected skill still enters battle through existing forging path.
- Low realm characters cannot use high-tier slot 3 special skills.
- No schema/saveVersion/numbers.yaml changes.

## Current Recovery Point

- 状态:实现、验证、提交完成。
- 最后完成:新增 21 个开锋槽 3 装备专属技,36 件武器候选切到 `skill_edge_*`,UI 候选摘要/空状态与三系锁死回归测试已补。
- 下一步:等待主窗口复核/合并;本分支不 push。
- 已跑验证:
  - `flutter pub get`
  - `dart run build_runner build --delete-conflicting-outputs`
  - `flutter test --no-pub test/data/game_repository_test.dart test/data/skill_source_redline_test.dart`
  - `flutter test --no-pub test/features/equipment/presentation/forging_panel_test.dart`
  - `flutter test --no-pub test/features/battle/domain/battle_character_forging_bake_test.dart`
  - `flutter analyze`
- 阻塞项:无。首次 `flutter test --no-pub` 在缺 `.dart_tool/package_config.json` 时触发 Flutter tool native_assets `Bad state: No element`,已通过 `flutter pub get` + build_runner 生成本地元数据/part 文件后恢复。
