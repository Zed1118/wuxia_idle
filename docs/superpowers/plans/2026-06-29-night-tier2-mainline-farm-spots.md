# Mainline Chapter Farm Spots Implementation Plan

**Goal:** 每章通关后，在主线章节内标出 1-2 个适合刷装备、材料或招式熟练度的关卡，让玩家知道通章后可回头刷哪里。

**Branch:** `codex/night-tier2-mainline-farm-spots`

**Architecture:** 复用第一梯队 `MainlineReplayRewardRoute.fromStage(StageDef)` 的纯派生路线，不改收益规则、掉落结算、数值、schema、saveVersion 或 `numbers.yaml`。只在章节已全通后显示推荐刷点；不追踪个人缺口，不做关卡整备条二期，不引入日课/体力/限时/在线加成。

**Tech Stack:** Flutter Desktop, Dart, Riverpod 3.x, existing `GameRepository` defs, targeted `flutter test`, `flutter analyze`.

---

## Acceptance Criteria

- 每章所有主线关卡通关后，章节页展示 1-2 个推荐刷点。
- 未通完章节不展示章节推荐刷点，避免干扰首通推进。
- 推荐刷点只从本章已通关卡和 `MainlineReplayRewardRoute` 派生，区分「刷装备」「刷材料」「练熟练度」。
- 不做个人材料/装备/心法缺口追踪，不接背包、角色 build 或商店需求。
- 不改关卡收益、掉落结算、扫荡、周目回报或自动战斗规则。
- 中文 UI 文案集中在 `lib/shared/strings.dart`。
- 覆盖纯 domain 测试和主线章节页 widget 测试。
- 完成 targeted tests/analyze，并按小切片 commit。

## Task Slices

- [x] **Task 0: Orientation and branch**
  - Read `AGENTS.md`, `CLAUDE.md`, `GDD.md`, `PROGRESS.md`, `docs/spec/playability_phase2_backlog.md`, and `/Users/a10506/Desktop/挂机武侠_已否任务.md`.
  - Create branch `codex/night-tier2-mainline-farm-spots` from the provided detached worktree HEAD.
  - Confirm first-tier mainline replay rewards are present and do not depend on the deferred tower/Boss 03 branch.
  - Note: CodeGraph is not initialized in this worktree; continue with targeted reads without running index init.

- [ ] **Task 1: Pure chapter farm spot model**
  - Add a domain helper that returns up to 2 recommended spots only when the full chapter is cleared.
  - Score candidates from `MainlineReplayRewardRoute.fromStage`; prefer richer routes and Boss/proficiency spots without hardcoded per-chapter tables.
  - Add focused domain tests for hidden-before-complete, capped recommendations, and route-kind reuse.

- [ ] **Task 2: Stage list UI wiring**
  - Render the chapter-level recommendation under the journey map / before sweep controls.
  - Use compact `Wrap` chips and stable dimensions; keep row taps and info buttons unchanged.
  - Centralize all new Chinese strings in `UiStrings`.

- [ ] **Task 3: Widget coverage**
  - Extend `stage_list_screen_test.dart` for hidden incomplete chapter and visible completed chapter states.
  - Assert 1-2 spot names and route labels render, without introducing personal gap language.

- [ ] **Task 4: Verification and closeout**
  - Run targeted domain/widget tests and touched-file analyze.
  - Update `PROGRESS.md` and this recovery point.
  - Commit implementation slice(s) with concise messages.

## Current Recovery Point

- **Status:** Plan written; implementation not started.
- **Last completed:** Read required docs, created branch, confirmed existing `MainlineReplayRewardRoute` and `StageListScreen` extension point.
- **Next step:** Implement pure chapter farm spot model and tests.
- **Verification run:** None yet.
- **Blockers:** CodeGraph is not initialized in this worktree; not blocking because the relevant files are already identified.
