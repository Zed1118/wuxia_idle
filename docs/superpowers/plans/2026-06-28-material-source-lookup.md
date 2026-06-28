# Material Source Lookup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the first slice of material source lookup for equipment material UI, covering query service, tests, and a lightweight readable entry in enhancement/forging surfaces.

**Branch:** `codex/material-source-lookup`

**Architecture:** Add a pure material-source lookup service/model beside existing inventory/equipment lookup code. Reuse `GameRepository` drop tables, shop definitions, item definitions, seclusion maps, tower floors, and known equipment disposal rules without changing schema, saveVersion, `numbers.yaml`, or economy values. UI renders short source summaries through `UiStrings`.

**Tech Stack:** Flutter Desktop, Dart, Riverpod, existing `GameRepository`, existing YAML defs, `flutter test`, `dart analyze`.

---

## Acceptance Criteria

- `item_mojianshi` returns source summaries including combat/drop-style sources, seclusion, equipment disassembly, and shop where configured.
- `item_xinxuejiejing` returns source summaries including enhancement failure guarantee, equipment disassembly, and shop where configured.
- Experience pills and technique scrolls return source summaries from configured stage/tower/seclusion/shop drop data where present.
- Pure Dart tests cover at least three material classes.
- Enhancement/forging related UI shows a lightweight readable source entry for materials without a new complex page.
- Chinese display strings are centralized in `UiStrings`.
- No changes to schema, saveVersion, `numbers.yaml`, or numeric balance constants.
- Verification runs targeted tests and analyze on touched Dart files.

## Task Slices

- [x] **Task 0: Orientation and branch**
  - Read `AGENTS.md`, `CLAUDE.md` §8.0, relevant `GDD.md` redlines, and `docs/spec/playability_phase2_backlog.md` §十二.
  - Create/use branch `codex/material-source-lookup`.
  - Note: CodeGraph is not initialized in this worktree; fallback to direct file reads/`rg` without running `codegraph init`.

- [x] **Task 1: Pure service/model TDD**
  - Add failing tests for material source lookup over `item_mojianshi`, `item_xinxuejiejing`, one experience pill, and one technique scroll.
  - Create a focused domain model and service that returns deduplicated source entries from repository data and known material production paths.
  - Run the new targeted test until green.

- [x] **Task 2: UiStrings formatting**
  - Add `UiStrings` helpers for material source labels and compact summaries.
  - Keep all new Chinese UI copy in `lib/shared/strings.dart`.
  - Cover formatting through the service/UI tests where practical.

- [x] **Task 3: Lightweight UI wiring**
  - Render a compact “主要来源” line/card in the enhancement material metrics area for 磨剑石/心血结晶.
  - Render the same compact source note in the forging tab because opening forging is reached from the same equipment build surface.
  - Avoid new route/page/dialog complexity in this slice.

- [x] **Task 4: Verification and commit**
  - Run targeted tests for new service and touched widget tests if feasible.
  - Run analyze on touched Dart files.
  - Commit the completed slice.

## Current Recovery Point

- **Status:** Complete.
- **Last completed:** Current branch commit adds pure material source lookup service/model, `UiStrings` source summary formatting, and lightweight source notes in enhancement/forging UI.
- **Next step:** Main window review; do not merge or push from this worktree.
- **Verification run:** `flutter test test/features/inventory/material_source_lookup_service_test.dart`; `flutter test test/features/inventory/material_source_lookup_service_test.dart test/features/equipment/presentation/enhance_dialog_test.dart`; `dart analyze lib/core/domain/item_source.dart lib/features/inventory/application/material_source_lookup_service.dart lib/features/inventory/presentation/material_source_note.dart lib/features/equipment/presentation/enhance_dialog.dart lib/features/equipment/presentation/forging_panel.dart lib/shared/strings.dart test/features/inventory/material_source_lookup_service_test.dart test/features/equipment/presentation/enhance_dialog_test.dart`.
- **Blockers:** CodeGraph is not initialized in this worktree. Per project instructions, initialization should be user-approved first; continuing with direct file reads.
