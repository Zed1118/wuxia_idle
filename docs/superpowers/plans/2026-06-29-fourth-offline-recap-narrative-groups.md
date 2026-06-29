# Offline Recap Narrative Groups Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Present offline return rewards in narrative groups without changing reward calculation, probability, persistence, or economy.

**Architecture:** Reuse the existing `OfflineRecapDetailFormatter` view model as the only grouping layer. `OfflineRecapService`, `OfflinePassiveService`, Isar schema, YAML numbers, and reward settlement remain untouched. Chinese UI text is centralized in `UiStrings`.

**Tech Stack:** Flutter, Dart, Riverpod/Isar existing app stack, `flutter_test`.

---

## Acceptance Criteria

- Active retreat recap groups existing reward fields into narrative categories such as travel/accounting, cultivation accumulation, supplies/materials, and collect-time reveal.
- Passive offline recap uses the same narrative language while preserving its existing constraint: no collect button, no silver, no skill proficiency, no equipment drop row.
- No new reward type, probability, save field, YAML number, online bonus, acceleration, login reward, daily-task framing, or forced claim language is introduced.
- No Dart Chinese strings are added outside `lib/shared/strings.dart`.
- Existing zero-value hiding behavior remains intact.
- Targeted seclusion recap tests pass.
- `flutter analyze` passes.

## Tasks

- [x] **Task 1: Update plan and inspect current recap path**
  - Files: this plan, `lib/features/seclusion/application/offline_recap_detail.dart`, `lib/features/seclusion/presentation/offline_recap_card.dart`, `lib/shared/strings.dart`, existing seclusion recap tests.
  - Verification: CodeGraph context and targeted file reads confirm grouping is presentation-only.

- [x] **Task 2: Add narrative labels and row builders**
  - Modify `lib/shared/strings.dart`.
  - Add group titles and row text helpers for travel/accounting, cultivation, materials, and collect-time reveal.
  - Keep old helper names where useful to minimize blast radius.

- [x] **Task 3: Regroup active retreat recap**
  - Modify `OfflineRecapDetailFormatter.forRetreat`.
  - Keep all totals sourced from the incoming `OfflineRecap`.
  - Split rows by existing fields:
    - time/limit rows: `awayHours`, `settledHours`, `limitReason`
    - cultivation rows: `estimatedExperience`, `estimatedTechniqueLearnPoints`
    - material rows: `estimatedSilver`, `estimatedMojianshi`, `estimatedItemRewards`
    - collect reveal row: pending equipment/drop wording only

- [x] **Task 4: Regroup passive recap**
  - Modify `OfflineRecapDetailFormatter.forPassive`.
  - Keep fields limited to existing `PassiveYield`: `experience`, `mojianshi`, `awayHours`, `settledHours`, `isCapped`.
  - Preserve no-claim/no-collect posture.

- [x] **Task 5: Update tests**
  - Modify `test/features/seclusion/application/offline_recap_detail_test.dart`.
  - Modify presentation tests only where asserted text/group names changed.
  - Add assertions that passive recap does not show collect/claim/drop/silver/skill rows.

- [x] **Task 6: Verify and commit**
  - Run targeted tests:
    - `flutter test --no-pub test/features/seclusion/application/offline_recap_detail_test.dart test/features/seclusion/presentation/offline_recap_card_test.dart test/features/seclusion/presentation/offline_recap_passive_card_test.dart test/features/seclusion/application/offline_recap_service_test.dart test/features/seclusion/application/offline_passive_service_test.dart`
  - Run `flutter analyze`.
  - Self-check rejected-task registry and red lines.
  - Commit with `[READY] feat(offline): group return rewards narratively`.

## Current Recovery Point

- Status: implemented and verified; ready to commit.
- Last completed: active/passive offline recap grouping now uses narrative groups from existing reward fields only; tests updated.
- Next step: commit `[READY] feat(offline): group return rewards narratively`.
- Verification run: `dart run build_runner build --delete-conflicting-outputs` (tool ignored removed flag; generated local ignored files), `flutter test --no-pub test/features/seclusion/application/offline_recap_detail_test.dart test/features/seclusion/presentation/offline_recap_card_test.dart test/features/seclusion/presentation/offline_recap_passive_card_test.dart test/features/seclusion/application/offline_recap_service_test.dart test/features/seclusion/application/offline_passive_service_test.dart` (26 passed), `flutter analyze` (No issues found), `git diff --check`.
- Blockers: none.
