# Project Health Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the actionable project-health debts found in the 2026-07-10 full review without mixing behavioral changes into mechanical maintenance.

**Architecture:** Work in independently verifiable batches: mechanical formatting and CI first, then focused regression coverage, documentation corrections, narrow dependency and type-safety cleanup, and finally small internal extractions that preserve public APIs. Keep `GameRepository` and `IsarSetup` as composition-facing entry points while moving only cohesive implementation details behind typed collaborators.

**Tech Stack:** Flutter 3.41.5, Dart 3.11.3, Riverpod 3, Isar Community, GitHub Actions.

---

### Task 1: Baseline And Mechanical Formatting

**Files:**
- Modify: `lib/**/*.dart`
- Modify: `docs/**/*.dart`
- Modify: `.github/workflows/ci.yml`

- [x] Generate ignored source files with `dart run build_runner build`.
- [x] Run `flutter analyze lib/ test/` and record the clean baseline.
- [x] Run `dart format --output=none --set-exit-if-changed lib test docs` and confirm the current format debt.
- [x] Run `dart format lib test docs` as one behavior-neutral mechanical change.
- [x] Add a CI step that runs `dart format --output=none --set-exit-if-changed lib test docs` before analysis.
- [x] Verify the formatter check and `flutter analyze lib/ test/` pass.
- [x] Commit the batch with a Chinese action-oriented message.

### Task 2: Critical Flow Coverage

**Files:**
- Modify/Create: `test/features/mainline/presentation/stage_entry_flow_test.dart`
- Create: `test/features/sweep/application/sweep_settlement_test.dart`
- Create: `test/features/sweep/application/sweep_unit_test.dart`
- Modify/Create: focused tests under `test/features/recruitment/`, `test/features/ascension/`, and `test/features/mass_battle/`
- Modify: `.github/workflows/ci.yml`
- Modify: `.gitignore`

- [ ] Map public behavior and existing fixtures for each low-coverage flow before choosing cases.
- [ ] Add one behavior-focused failing test at a time and run it to confirm the expected failure.
- [ ] Add only the fixture seam or production correction required to make each test pass.
- [ ] Run each focused test after its red-green cycle.
- [ ] Add `coverage/` to `.gitignore`.
- [ ] Add a CI coverage run that emits `coverage/lcov.info` and uploads it as an artifact; do not impose a global percentage gate until all executable files are represented consistently.
- [ ] Run the complete focused test group and commit the batch.

### Task 3: macOS Build Gate

**Files:**
- Modify: `.github/workflows/ci.yml`

- [ ] Add a separate `macos-latest` job using the pinned Flutter version.
- [ ] Generate ignored code before compiling.
- [ ] Run `flutter build macos --debug` as a platform smoke gate.
- [ ] Validate workflow syntax structurally and run the same build locally.
- [ ] Commit the batch.

### Task 4: Documentation And Repository Hygiene

**Files:**
- Modify: `README.md`
- Modify: `docs/spec/full_review_2026-07-02_followup_backlog.md`
- Modify: `docs/superpowers/plans/2026-07-10-test-format-normalization.md`
- Modify: this plan

- [ ] Correct the README's current architecture, test inventory, visual-test terminology, and measured runtime guidance.
- [ ] Replace the incorrect `docs/handoff` Git-history diagnosis with measured tracked, ignored-local, and historical-object figures.
- [ ] Mark the completed 2026-07-10 formatting plan as completed/archived without rewriting its history.
- [ ] Record which local ignored visual artifacts remain user-owned and require explicit approval before deletion.
- [ ] Run documentation consistency searches and commit the batch.

### Task 5: Narrow Coupling And Type-Safety Cleanup

**Files:**
- Modify: `lib/features/recruitment/presentation/recruitment_dialog.dart`
- Modify: `lib/features/save_management/application/save_management_service.dart`
- Create/Modify: focused collaborators and tests beside save management
- Modify: selected internal files under `lib/data/` only if a cohesive validator/loader extraction has a small verified impact radius

- [ ] Replace the recruitment `dynamic` profile access with the existing `AttributeProfile` type and remove the lint suppression.
- [ ] Write a failing test proving save restore uses an injected recovery boundary.
- [ ] Introduce a typed recovery collaborator while preserving `SaveManagementService` behavior and public call sites.
- [ ] Use CodeGraph impact analysis before any `GameRepository` extraction; extract only one cohesive internal concern if the impact stays local.
- [ ] Run focused tests and analysis, then commit the batch.

### Task 6: Battle Configuration And Compatibility Debt

**Files:**
- Modify: `lib/features/battle/presentation/battle_screen.dart`
- Modify: battle call sites and focused tests
- Modify/Delete: `lib/features/battle/domain/battle_engine.dart`
- Modify: tests that still depend on `BattleEngine`

- [ ] Introduce a typed presentation/debug configuration only where it reduces groups of related boolean parameters without altering defaults.
- [ ] Migrate remaining `BattleEngine` tests to `DefaultGroundStrategy` or `BattleStrategy` behavior.
- [ ] Remove the pass-through wrapper only after CodeGraph and literal import scans show no production or test callers.
- [ ] Run battle-focused tests and analysis, then commit the batch.

### Task 7: Dependency Maintenance

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`

- [ ] Re-run `flutter pub outdated` and separate compatible upgrades from constraint changes.
- [ ] Apply compatible direct/dev dependency upgrades first.
- [ ] Evaluate `intl 0.20.x` separately against analyzer and tests.
- [ ] Document the transitive discontinued `js` dependency as upstream-bound if `isar_community` still owns it.
- [ ] Run code generation, analysis, focused tests, and commit the batch.

### Task 8: Full Verification And Recovery Closeout

**Files:**
- Modify: this plan
- Modify: `PROGRESS.md`

- [ ] Run `dart run build_runner build`.
- [ ] Run `dart format --output=none --set-exit-if-changed lib test docs`.
- [ ] Run `flutter analyze lib/ test/`.
- [ ] Run `flutter test --no-pub`.
- [ ] Run `flutter test --coverage --no-pub` and summarize critical-flow coverage.
- [ ] Run `flutter build macos --debug`.
- [ ] Inspect `git diff --check`, tracked/untracked files, and generated artifacts.
- [ ] Update `PROGRESS.md` and this plan with completed, verified, residual-risk, and next-batch states.
- [ ] Create a final `[READY]` commit once the worktree is clean.

## Recovery Point

- Branch: `codex/project-health-hardening`
- Worktree: `.worktrees/project-health-hardening`
- Current state: Task 1 verified and ready to commit; first full run had one non-reproducible failure, JSON diagnostic rerun completed successfully. Task 2 is next.
- Resume command: `git status --short --branch && sed -n '1,260p' docs/superpowers/plans/2026-07-11-project-health-hardening.md`
