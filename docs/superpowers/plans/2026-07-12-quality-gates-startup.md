# Quality Gates and Startup Reliability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add conservative first-clear experience ratchets, deterministic Splash lifecycle tests, and approved repository hygiene without changing game balance or save data.

**Architecture:** Reuse the existing production-data tempo diagnostic as the only simulation source and add assertions over its aggregated rows. Add two optional constructor seams to `SplashScreen` so tests can control loading and destination while production defaults remain unchanged. Keep hygiene changes independent from behavior changes.

**Tech Stack:** Flutter 3.41.5, Dart 3.11.3, flutter_test, Riverpod 3.x, YAML-driven battle configuration.

---

## Recovery Point

- **Status:** plan ready; implementation not started.
- **Branch:** `codex/final-quality-optimization`.
- **Worktree:** `/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/final-quality-optimization`.
- **Last completed:** generated 114 `.g.dart` outputs and verified baseline `flutter analyze --no-pub` with 0 issues.
- **Next:** Task 1, add first-clear ratchet assertions.
- **Verification run:** `dart run build_runner build`; `flutter analyze --no-pub`.
- **Blockers:** none. Windows/performance/beta are outside this subproject.

## Acceptance Checklist (CLAUDE.md §8.2)

- [ ] Production wiring evidence documented for Splash default loader and destination.
- [ ] Targeted test commands and passing results recorded.
- [ ] Red-line statement confirms no numbers/schema/save/three-tier/online-offline changes.
- [ ] Residual risks list includes no visual smoke and no Windows run.
- [ ] UI behavior retains semantics, keyboard/focus/mouse behavior because no interactive control type changes.
- [ ] `flutter analyze --no-pub` passes.
- [ ] `flutter test --no-pub` passes at batch end.
- [ ] Worktree is clean and tip commit starts with `[READY]` at handoff.

### Task 1: First-clear experience ratchet

**Files:**
- Modify: `test/tools/readable_first_clear_tempo_diagnostic_test.dart`

- [ ] **Step 1: Add aggregation helpers inside the test body**

After collecting `rows`, build a `Map<String, List<_TempoRun>>` keyed by `stageId/profile` and a local average helper. Do not add a second simulator.

```dart
final byStageProfile = <String, List<_TempoRun>>{};
for (final row in rows) {
  byStageProfile
      .putIfAbsent('${row.stageId}/${row.profile.name}', () => [])
      .add(row);
}
double averageActions(String stageId, _TempoProfile profile) {
  final samples = byStageProfile['$stageId/${profile.name}'] ?? const [];
  expect(samples, isNotEmpty, reason: 'missing tempo samples');
  return samples.fold<double>(0, (sum, row) => sum + row.actionRows) /
      samples.length;
}
```

- [ ] **Step 2: Add conservative chapter-end assertions**

```dart
for (var chapter = 1; chapter <= 6; chapter++) {
  final stageId = 'stage_${chapter.toString().padLeft(2, '0')}_05';
  final floor = averageActions(stageId, _TempoProfile.floor);
  final ceiling = averageActions(stageId, _TempoProfile.ceiling);
  expect(floor, greaterThanOrEqualTo(6), reason: '$stageId floor=$floor');
  expect(floor, greaterThanOrEqualTo(ceiling), reason: '$stageId floor/ceiling');
}
expect(
  averageActions('stage_06_05', _TempoProfile.floor),
  greaterThanOrEqualTo(8),
);
```

- [ ] **Step 3: Promote existing configured-mechanic candidate to a gate**

Refactor `_summarize` to return a small `_TempoSummary` containing report text and `missingBossMechanic`, or compute the same list once before report writing. Assert that the list is empty while preserving the Markdown output.

- [ ] **Step 4: Run the diagnostic test**

Run:

```bash
flutter test --no-pub test/tools/readable_first_clear_tempo_diagnostic_test.dart
```

Expected: PASS; output still lists known too-short candidates and no missing configured mechanics.

- [ ] **Step 5: Commit the ratchet**

```bash
git add test/tools/readable_first_clear_tempo_diagnostic_test.dart
git commit -m "增加首通体验渐进门禁"
```

### Task 2: Splash deterministic lifecycle tests (RED)

**Files:**
- Create: `test/features/splash/presentation/splash_screen_test.dart`
- Modify later: `lib/features/splash/presentation/splash_screen.dart`

- [ ] **Step 1: Write the failing tests against the wished-for seam**

Use a `Completer<void>` and a destination widget with a stable key. Cover load-before-tap, automatic navigation, tap-to-skip, and duplicate tap behavior. Construct `SplashScreen` with:

```dart
SplashScreen(
  minDisplay: minDisplay,
  loadDefinitions: () => loadCompleter.future,
  nextScreenBuilder: (_) => const Scaffold(
    body: SizedBox(key: Key('splash-next')),
  ),
)
```

Do not wait 2.2 real seconds; use tester virtual time.

- [ ] **Step 2: Run RED and confirm the expected failure**

Run:

```bash
flutter test --no-pub test/features/splash/presentation/splash_screen_test.dart
```

Expected: compile failure because `loadDefinitions` and `nextScreenBuilder` do not exist.

### Task 3: Splash seam implementation (GREEN)

**Files:**
- Modify: `lib/features/splash/presentation/splash_screen.dart`
- Test: `test/features/splash/presentation/splash_screen_test.dart`

- [ ] **Step 1: Add optional constructor fields**

```dart
final Future<void> Function()? loadDefinitions;
final WidgetBuilder? nextScreenBuilder;
```

Keep existing defaults by leaving both null in production callers.

- [ ] **Step 2: Preserve the production loader**

In `_bootstrap`, call the injected loader when present. Otherwise execute the existing `GameRepository.loadAllDefs` and debug logging unchanged.

- [ ] **Step 3: Preserve the production destination**

In `_go`, use `widget.nextScreenBuilder?.call(context) ?? const SaveSelectScreen()` as the page.

- [ ] **Step 4: Run GREEN**

Run:

```bash
flutter test --no-pub test/features/splash/presentation/splash_screen_test.dart
```

Expected: all four lifecycle tests pass, with no pending timers or exceptions.

- [ ] **Step 5: Run related save-slot tests**

Run:

```bash
flutter test --no-pub \
  test/features/splash/presentation/splash_screen_test.dart \
  test/features/save_slot/save_select_screen_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit Splash work**

```bash
git add lib/features/splash/presentation/splash_screen.dart \
  test/features/splash/presentation/splash_screen_test.dart
git commit -m "补齐启动闪屏生命周期测试"
```

### Task 4: Repository hygiene

**Files:**
- Modify: `.gitignore`
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`

- [ ] **Step 1: Add the shared Builds ignore**

Add `/Builds/` near `build/` with a comment that it contains local distributable artifacts.

- [ ] **Step 2: Remove the unused dependency**

Run:

```bash
flutter pub remove cupertino_icons
```

Expected: `pubspec.yaml` and `pubspec.lock` update; no production imports are affected.

- [ ] **Step 3: Update the stale pubspec asset comment**

Replace the retired DeepSeek wording with “Mac 单端维护数值与文案”. Do not modify asset declarations.

- [ ] **Step 4: Verify hygiene**

Run:

```bash
git check-ignore -v Builds/example
rg -n 'cupertino_icons|CupertinoIcons' lib test pubspec.yaml pubspec.lock
flutter analyze --no-pub
```

Expected: Builds is ignored by `.gitignore`; `rg` has no matches; analyze passes.

- [ ] **Step 5: Commit hygiene**

```bash
git add .gitignore pubspec.yaml pubspec.lock
git commit -m "收口仓库忽略与未用依赖"
```

### Task 5: Batch verification and recovery point

**Files:**
- Modify: `docs/superpowers/plans/2026-07-12-quality-gates-startup.md`

- [ ] **Step 1: Format touched Dart files**

```bash
dart format lib/features/splash/presentation/splash_screen.dart \
  test/features/splash/presentation/splash_screen_test.dart \
  test/tools/readable_first_clear_tempo_diagnostic_test.dart
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze --no-pub
```

Expected: 0 issues.

- [ ] **Step 3: Run targeted tests**

```bash
flutter test --no-pub \
  test/tools/readable_first_clear_tempo_diagnostic_test.dart \
  test/features/splash/presentation/splash_screen_test.dart \
  test/features/save_slot/save_select_screen_test.dart
```

Expected: all pass.

- [ ] **Step 4: Run full suite**

```bash
flutter test --no-pub
```

Expected: all tests pass; no `-1` loader crashes.

- [ ] **Step 5: Update this plan's recovery point**

Record completed commits, exact test counts, analyze result, red-line impact, residual risks, and next subproject (`GameRepository/NumbersConfig` design).

- [ ] **Step 6: Create READY tip**

```bash
git status --short
git commit --allow-empty -m "[READY] 完成质量门禁与启动可靠性首批优化"
```

Expected: clean worktree and READY-prefixed tip.

