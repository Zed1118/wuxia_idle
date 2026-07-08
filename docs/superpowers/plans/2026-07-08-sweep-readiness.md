# Sweep Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a non-daily “扫荡战备” resource that limits online repeated mainline chapter sweeping without affecting first clears, offline idle, Taohua Island, tower repeat rules, or normal combat.

**Architecture:** Store per-save sweep readiness on `SaveData`, recover it by real elapsed time, and expose it through a small sweep application service/provider. Mainline chapter sweep entry checks that the player has enough readiness for the whole chapter; each mainline sweep settlement spends one readiness before awarding rewards. Tower sweep remains unchanged because it already only pays fragments on repeat.

**Tech Stack:** Flutter, Riverpod 3, Isar, yaml-driven `NumbersConfig`, existing sweep/mainline services.

---

### File Structure

- Create `lib/features/sweep/domain/sweep_readiness.dart`: pure config/status/recovery math.
- Create `lib/features/sweep/application/sweep_readiness_service.dart`: Isar-backed read/recover/spend service.
- Create `lib/features/sweep/application/sweep_readiness_providers.dart`: Riverpod provider for current readiness.
- Modify `lib/core/domain/save_data.dart`: add nullable readiness fields.
- Modify `lib/data/isar_setup.dart`: bump save schema version.
- Modify `lib/data/numbers_config.dart`: parse `sweep_readiness`.
- Modify `data/numbers.yaml`: add `sweep_readiness` tuning values.
- Modify `lib/features/sweep/application/sweep_settlement.dart`: spend readiness before mainline sweep rewards.
- Modify `lib/features/mainline/presentation/stage_list_screen.dart`: show readiness status and disable chapter sweep when insufficient.
- Modify `lib/shared/strings.dart`: add centralized UI strings.
- Add/update tests under `test/features/sweep/` and affected widget tests.

---

### Task 1: Pure Readiness Math

**Files:**
- Create: `lib/features/sweep/domain/sweep_readiness.dart`
- Test: `test/features/sweep/domain/sweep_readiness_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
test('旧档未初始化时按满战备处理', () {
  const config = SweepReadinessConfig(
    enabled: true,
    maxPoints: 60,
    recoverMinutesPerPoint: 60,
    mainlineStageCost: 1,
  );
  final now = DateTime(2026, 7, 8, 12);
  final state = SweepReadinessState.normalize(
    points: null,
    lastRecoveredAt: null,
    now: now,
    config: config,
  );
  expect(state.points, 60);
  expect(state.lastRecoveredAt, now);
});

test('按真实时间恢复并保留不足一格的剩余时间', () {
  const config = SweepReadinessConfig(
    enabled: true,
    maxPoints: 60,
    recoverMinutesPerPoint: 60,
    mainlineStageCost: 1,
  );
  final state = SweepReadinessState.normalize(
    points: 10,
    lastRecoveredAt: DateTime(2026, 7, 8, 10, 15),
    now: DateTime(2026, 7, 8, 12, 45),
    config: config,
  );
  expect(state.points, 12);
  expect(state.lastRecoveredAt, DateTime(2026, 7, 8, 12, 15));
});

test('整章扫荡费用 = 关数 * mainlineStageCost', () {
  const config = SweepReadinessConfig(
    enabled: true,
    maxPoints: 60,
    recoverMinutesPerPoint: 60,
    mainlineStageCost: 1,
  );
  expect(config.mainlineSweepCostFor(5), 5);
});
```

- [ ] **Step 2: Implement domain objects**

Create `SweepReadinessConfig`, `SweepReadinessState`, and helpers:

```dart
class SweepReadinessConfig {
  final bool enabled;
  final int maxPoints;
  final int recoverMinutesPerPoint;
  final int mainlineStageCost;

  const SweepReadinessConfig({
    required this.enabled,
    required this.maxPoints,
    required this.recoverMinutesPerPoint,
    required this.mainlineStageCost,
  });

  int mainlineSweepCostFor(int stageCount) => stageCount * mainlineStageCost;
}
```

- [ ] **Step 3: Run pure tests**

Run: `flutter test --no-pub test/features/sweep/domain/sweep_readiness_test.dart`

Expected: all tests pass.

---

### Task 2: Config and Save State

**Files:**
- Modify: `lib/core/domain/save_data.dart`
- Modify: `lib/data/isar_setup.dart`
- Modify: `lib/data/numbers_config.dart`
- Modify: `data/numbers.yaml`

- [ ] **Step 1: Add save fields**

Add nullable fields to `SaveData`:

```dart
int? sweepReadinessPoints;
DateTime? sweepReadinessLastRecoveredAt;
```

- [ ] **Step 2: Bump schema version**

In `IsarSetup`, bump the current schema version and add a comment noting sweep readiness fields. Do not add destructive migration logic; nullable fields are normalized by the service.

- [ ] **Step 3: Parse config**

Add `final SweepReadinessConfig sweepReadiness;` to `NumbersConfig`, parse `sweep_readiness`, and give test-safe defaults.

- [ ] **Step 4: Add yaml config**

Add to `data/numbers.yaml`:

```yaml
sweep_readiness:
  enabled: true
  max_points: 60
  recover_minutes_per_point: 60
  mainline_stage_cost: 1
```

- [ ] **Step 5: Regenerate Isar code**

Run: `dart run build_runner build --delete-conflicting-outputs`

Expected: `lib/core/domain/save_data.g.dart` updates cleanly.

---

### Task 3: Isar Service and Provider

**Files:**
- Create: `lib/features/sweep/application/sweep_readiness_service.dart`
- Create: `lib/features/sweep/application/sweep_readiness_providers.dart`
- Test: `test/features/sweep/application/sweep_readiness_service_test.dart`

- [ ] **Step 1: Write service tests**

Cover:
- old save with null fields reads as full;
- spending one point persists;
- spending more than available returns false and does not go negative;
- recovery uses elapsed real time.

- [ ] **Step 2: Implement service**

`SweepReadinessService` should expose:

```dart
Future<SweepReadinessState> getStatus({DateTime? now});
Future<bool> trySpendMainlineStages(int stageCount, {DateTime? now});
```

It must read `SaveData` id `0`, normalize recovery, persist normalized values, and write updates inside Isar transactions.

- [ ] **Step 3: Add provider**

Create an `@riverpod` or plain `FutureProvider` matching local provider style:

```dart
final sweepReadinessStatusProvider =
    FutureProvider<SweepReadinessState>((ref) async {
  final config = ref.watch(numbersConfigProvider).sweepReadiness;
  return SweepReadinessService(
    isar: IsarSetup.instance,
    config: config,
  ).getStatus();
});
```

- [ ] **Step 4: Run service tests**

Run: `flutter test --no-pub test/features/sweep/application/sweep_readiness_service_test.dart`

Expected: all tests pass.

---

### Task 4: Gate Mainline Sweep Rewards

**Files:**
- Modify: `lib/features/sweep/application/sweep_settlement.dart`
- Modify: `lib/features/sweep/domain/sweep_recap.dart`
- Test: `test/features/sweep/application/sweep_settlement_test.dart` or nearest existing sweep settlement test.

- [ ] **Step 1: Spend before rewards**

At the start of `settleMainlineSweepVictory`, spend one mainline stage cost before `applyVictoryResolution`.

If spend fails, return a `SweepBattleOutcome` with no drops and `ignoredDrops: 1`.

- [ ] **Step 2: Invalidate provider**

After successful spend, invalidate `sweepReadinessStatusProvider` along with existing post-combat invalidations.

- [ ] **Step 3: Keep tower unchanged**

Do not spend readiness in `settleTowerSweepVictory`.

- [ ] **Step 4: Run sweep settlement tests**

Run relevant sweep tests and ensure tower behavior still passes.

---

### Task 5: Mainline UI

**Files:**
- Modify: `lib/features/mainline/presentation/stage_list_screen.dart`
- Modify: `lib/shared/strings.dart`
- Test: `test/features/mainline/presentation/stage_list_screen_test.dart` or existing nearby widget tests.

- [ ] **Step 1: Add strings**

Add strings for:
- current readiness count;
- chapter sweep cost;
- insufficient readiness disabled button;
- next recovery hint.

- [ ] **Step 2: Show readiness near sweep button**

In `_ChapterSweepButton`, watch `sweepReadinessStatusProvider` via a small `Consumer` boundary or convert the button to `ConsumerWidget`.

Display a compact status row:

```text
战备 42 / 60 · 本章消耗 5
```

- [ ] **Step 3: Disable when insufficient**

If `eligible == true` but readiness is lower than `entries.length * mainlineStageCost`, disable the sweep button and show:

```text
战备不足，暂缓扫荡
```

- [ ] **Step 4: Keep locked-copy distinct**

If the chapter is not sweep-eligible because the current cycle has not been hand-cleared, keep the existing lock copy. Do not mention readiness in that state.

---

### Task 6: Verification

**Files:** all changed files

- [ ] **Step 1: Analyze**

Run: `flutter analyze`

Expected: no issues.

- [ ] **Step 2: Focused tests**

Run:

```bash
flutter test --no-pub -j1 \
  test/features/sweep \
  test/features/mainline/presentation/stage_list_screen_test.dart
```

Expected: all tests pass. If the exact widget test file does not exist, run the nearest mainline presentation test suite.

- [ ] **Step 3: Build app**

Run: `flutter build macos --debug`

Expected: build succeeds.

---

### Self-Review

- Spec coverage: the plan implements the approved GDD boundary for `扫荡战备` only. `副本凭证` and `劳损调息` remain documented future systems and are intentionally out of scope.
- Placeholder scan: no task depends on unspecified future design.
- Type consistency: `SweepReadinessConfig`, `SweepReadinessState`, and `SweepReadinessService` are the planned names used consistently across tasks.
