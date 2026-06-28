# Mainline Replay Rewards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在已通关主线关卡中突出重打价值，让玩家能区分刷装备、刷材料、刷招式熟练度三类回头打理由。

**Branch:** `codex/night-mainline-replay-rewards`

**Architecture:** 只做展示层和纯派生模型，不改掉落结算、数值、schema、saveVersion 或 `numbers.yaml`。从 `StageDef.dropTable`、`dropSkillManualId/dropSkillFragmentId`、敌方 `chargeSkillId` 和既有掉落传闻/整备条派生重打路线；在 `StageListScreen` 的已通关主线行展示紧凑提示，继续复用 info 图标战前情报入口。

**Tech Stack:** Flutter Desktop, Dart, Riverpod 3.x, existing `GameRepository` defs, targeted `flutter test`, `flutter analyze`.

---

## Acceptance Criteria

- 已通关主线行直接显示重打收益路线，至少区分「刷装备」「刷材料」「练熟练度」。
- 未通关 / 锁定关卡不显示重打路线，避免首通目标被二次信息干扰。
- 派生逻辑复用现有 `StageDef` / dropTable / 技能掉落与敌阵信息，不新增硬编码副本表。
- 不新增日课、体力、限时奖励、在线加成或任何新收益结算。
- 新增中文 UI 文案集中在 `lib/shared/strings.dart`。
- 覆盖纯 domain 测试和主线关卡行 widget 测试。
- 完成后跑 targeted tests 和 analyze，并提交小切片 commit。

## Task Slices

- [x] **Task 0: Orientation and branch**
  - Read `AGENTS.md`, `CLAUDE.md`, `GDD.md`, `PROGRESS.md`, and `docs/spec/playability_phase2_backlog.md`.
  - Use isolated worktree `/Users/a10506/.codex/worktrees/1d44/挂机武侠`.
  - Create branch `codex/night-mainline-replay-rewards`.
  - Note: CodeGraph is not initialized here; per project instruction, do not run `codegraph init` without user approval, continue with `rg` and targeted reads.

- [ ] **Task 1: Pure replay reward route model**
  - Create `lib/features/mainline/domain/mainline_replay_reward_route.dart`.
  - Add `MainlineReplayRewardRoute.fromStage(StageDef)` that derives route kinds from:
    - equipment drops in `dropTable` → equipment route;
    - item drops in `dropTable` except first-clear-only scrolls → material route;
    - `dropSkillFragmentId`, `dropSkillManualId`, or enemy `chargeSkillId` → proficiency route.
  - Add tests in `test/features/mainline/domain/mainline_replay_reward_route_test.dart`.

- [ ] **Task 2: UiStrings and compact row widget**
  - Add `UiStrings` labels for replay route title, per-kind labels, and empty fallback.
  - Create a compact widget or private row in `stage_list_screen.dart` that renders route chips only when `status == StageStatus.cleared`.
  - Keep layout stable on compact width with `Wrap`.

- [ ] **Task 3: Stage list wiring**
  - Wire the route row below the existing整备/弱点 area for cleared mainline stages.
  - Preserve row tap behavior: clicking the row still enters replay; info icon still opens战前情报.
  - Do not change drop rumor, sweep, battle flow, or reward settlement.

- [ ] **Task 4: Verification and commit**
  - Run `flutter test` for the new domain test and relevant stage list widget tests.
  - Run `flutter analyze` on touched Dart files.
  - Update this recovery point and commit.

## Current Recovery Point

- **Status:** Plan written; implementation not started.
- **Last completed:** Required docs read; branch created; existing stage list / drop rumor / material source lookup / proficiency UI scanned.
- **Next step:** Implement Task 1 pure replay reward route model and tests.
- **Verification run:** None yet.
- **Blockers:** CodeGraph is not initialized in this worktree; continuing without it unless user approves indexing.
