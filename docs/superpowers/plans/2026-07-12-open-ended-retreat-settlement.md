# Open-Ended Retreat Settlement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace preset 1/4/12-hour retreats with player-ended retreats whose first 72 hours use full map rewards and whose overflow time earns uncapped passive rewards, while adding deterministic 12-hour equipment rolls and preserving all progression red lines.

**Architecture:** Add a pure settlement calculator that splits elapsed time and produces a stable preview/result; keep `SeclusionService` as the single transactional writer. Persist the realm snapshot needed for stable scaling, retain legacy `durationHours` only for old-save decoding, and reuse the existing battle-entry guard and provider invalidation paths. Presentation consumes the pure preview so the active screen, return card, and final result share one calculation source.

**Tech Stack:** Flutter Desktop, Dart, Riverpod 3, Isar Community, YAML configuration, `flutter_test`.

---

## Scope, branch, and acceptance

- **Design source:** `docs/superpowers/specs/2026-07-12-open-ended-retreat-settlement-design.md`
- **Execution branch:** `codex/open-ended-retreat-settlement`
- **Worktree:** `.worktrees/open-ended-retreat-settlement`
- **Production entry:** `SeclusionSetupScreen` starts an open-ended session; `ActiveRetreatScreen` previews and collects it; `SeclusionService.completeRetreat` writes the combined result.
- **Consumers:** main-menu retreat banner, startup return card, battle-entry guard, result screen, inventory/character/equipment providers.

### CLAUDE.md §8.2 delivery checklist

- [ ] Production wiring reaches setup → active session → preview → transactional collect → result UI.
- [ ] Targeted tests cover time boundaries, uncapped passive yield, deterministic equipment tiers, migration, transaction idempotence, gates, and 1280×720 / 1440×900 UI.
- [ ] Red lines: online=offline, no same-hour double reward, no login/daily/paid acceleration, no Chinese/numeric literals scattered outside approved sinks, three-system equip lock remains enforced.
- [ ] Residual risks recorded: long-duration economy, stable-seed compatibility, Isar migration, UI quantity formatting, full-suite isolation flakes.

## File map

**Create**

- `lib/features/seclusion/application/retreat_settlement_calculator.dart` — pure time split, combined preview, and deterministic equipment-node calculation.
- `test/features/seclusion/application/retreat_settlement_calculator_test.dart` — time, tier-weight, and deterministic-seed contract.

**Modify**

- `lib/features/seclusion/domain/retreat_session.dart` — add start-realm snapshot; retain legacy duration field.
- `lib/features/seclusion/application/offline_passive_service.dart` — remove reward cap and `999999` truncation.
- `lib/features/seclusion/application/seclusion_service.dart` — open-ended start, capped full-rate computation, combined transactional collect, stable equipment drops, baseline reset.
- `lib/features/seclusion/application/offline_recap_service.dart` — replace planned-duration recap semantics with two-phase preview.
- `lib/features/seclusion/presentation/{seclusion_setup_screen,active_retreat_screen,offline_recap_card,offline_recap_gate,retreat_result_screen,seclusion_gate}.dart` — new interaction and split presentation.
- `lib/features/main_menu/presentation/main_menu_retreat_banner.dart` — elapsed/two-phase banner instead of remaining duration.
- `lib/data/{numbers_config.dart,isar_setup.dart}` and `data/numbers.yaml` — drop-weight config, passive cap removal, save version 0.35 migration.
- `lib/shared/strings.dart` — all new Chinese UI copy in the approved sink.
- Existing seclusion/main-menu/data tests listed in the tasks below.
- `GDD.md`, `CLAUDE.md`, `PROGRESS.md` — behavior truth and verification record.

## Task 1: Pure time split and uncapped passive yield

**Files:**
- Create: `lib/features/seclusion/application/retreat_settlement_calculator.dart`
- Create: `test/features/seclusion/application/retreat_settlement_calculator_test.dart`
- Modify: `lib/features/seclusion/application/offline_passive_service.dart`
- Modify: `test/features/seclusion/application/offline_passive_service_test.dart`
- Modify: `test/features/seclusion/application/offline_passive_redline_test.dart`

- [ ] **Step 1: Write failing boundary and no-cap tests**

```dart
test('split: 72h01m = 72h retreat + 1m passive', () {
  final split = RetreatSettlementCalculator.splitHours(
    elapsedHours: 72 + 1 / 60,
    fullRateHours: 72,
  );
  expect(split.retreatHours, 72);
  expect(split.passiveHours, closeTo(1 / 60, 1e-9));
});

test('passive yield stays linear beyond the former 72h cap', () {
  final y = OfflinePassiveService.compute(
    awayHours: 24 * 100,
    realmTier: RealmTier.xueTu,
    config: cfg,
  );
  expect(y.settledHours, 2400);
  expect(y.experience, 50 * 2400);
  expect(y.isCapped, isFalse);
});
```

- [ ] **Step 2: Run tests and verify RED**

Run:
`flutter test --no-pub test/features/seclusion/application/retreat_settlement_calculator_test.dart test/features/seclusion/application/offline_passive_service_test.dart`

Expected: compile failure for missing calculator and/or assertion failure because passive settlement still clamps to 72 hours.

- [ ] **Step 3: Implement the minimal pure split and uncapped passive computation**

```dart
typedef RetreatTimeSplit = ({double retreatHours, double passiveHours});

abstract final class RetreatSettlementCalculator {
  static RetreatTimeSplit splitHours({
    required double elapsedHours,
    required double fullRateHours,
  }) {
    final safe = elapsedHours < 0 ? 0.0 : elapsedHours;
    final retreat = math.min(safe, fullRateHours);
    return (retreatHours: retreat, passiveHours: safe - retreat);
  }
}
```

In `OfflinePassiveService.compute`, use `safeHours = max(awayHours, 0)` directly, return `settledHours: safeHours`, `isCapped: false`, and remove the per-result `999999` clamp.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run:
`flutter test --no-pub test/features/seclusion/application/retreat_settlement_calculator_test.dart test/features/seclusion/application/offline_passive_service_test.dart test/features/seclusion/application/offline_passive_redline_test.dart`

Expected: all tests pass; 100-day yield is exactly linear.

- [ ] **Step 5: Commit**

```bash
git add lib/features/seclusion/application/retreat_settlement_calculator.dart \
  lib/features/seclusion/application/offline_passive_service.dart \
  test/features/seclusion/application/retreat_settlement_calculator_test.dart \
  test/features/seclusion/application/offline_passive_service_test.dart \
  test/features/seclusion/application/offline_passive_redline_test.dart
git commit -m "取消普通挂机时长上限"
```

## Task 2: Persist start-realm snapshot and migrate old active retreats

**Files:**
- Modify: `lib/features/seclusion/domain/retreat_session.dart`
- Modify: `lib/features/seclusion/application/seclusion_service.dart`
- Modify: `lib/data/isar_setup.dart`
- Modify: `test/data/save_migration_version_gate_test.dart`
- Modify: `test/features/seclusion/application/seclusion_service_test.dart`

- [ ] **Step 1: Write failing session and migration tests**

```dart
test('startRetreat stores realm snapshot and ignores planned duration', () async {
  final session = await service.startRetreat(
    mapType: RetreatMapType.shanLin,
    saveDataId: 1,
    characterId: character.id,
    charRealmTier: RealmTier.erLiu,
    maps: maps,
    now: now,
  );
  expect(session.realmTierAtStart, RealmTier.erLiu);
  expect(session.durationHours, 0, reason: 'legacy field is decode-only');
});

test('0.34 active retreat gains a realm snapshot during 0.35 migration', () async {
  // Seed saveVersion=0.34.0 and an active legacy session, reopen through IsarSetup.
  expect(migrated.realmTierAtStart, founder.realmTier);
  expect(migrated.startedAt, originalStartedAt);
  expect(migrated.status, RetreatStatus.active);
});
```

- [ ] **Step 2: Run tests and verify RED**

Run:
`flutter test --no-pub test/data/save_migration_version_gate_test.dart test/features/seclusion/application/seclusion_service_test.dart --plain-name 'realm snapshot'`

Expected: missing `realmTierAtStart` and obsolete required `durationHours` API.

- [ ] **Step 3: Add schema field and open-ended start API**

```dart
@enumerated
RealmTier? realmTierAtStart;

/// Legacy serialized field. New sessions write 0 and never use it as a cap.
int durationHours = 0;
```

Remove `durationHours` from `startRetreat` parameters; set `realmTierAtStart = charRealmTier` and `durationHours = 0`.

- [ ] **Step 4: Add versioned 0.35 migration**

Set `_currentSaveVersion = '0.35.0'`. For saves `<0.35.0`, find active retreats with a null snapshot, resolve the linked character through `currentRetreatSessionId` (fallback founder), and write exactly one snapshot without changing `startedAt`, map, or status.

```dart
if (_compareVersion(fromVersion, '0.35.0') < 0) {
  for (final session in activeRetreats) {
    session.realmTierAtStart ??= linkedCharacter?.realmTier ?? RealmTier.xueTu;
    await isar.retreatSessions.put(session);
  }
}
```

- [ ] **Step 5: Regenerate Isar code and verify GREEN**

Run:
`dart run build_runner build --delete-conflicting-outputs`

Then:
`flutter test --no-pub -j1 test/data/save_migration_version_gate_test.dart test/features/seclusion/application/seclusion_service_test.dart`

Expected: migration and start tests pass; generated files remain gitignored.

- [ ] **Step 6: Commit**

```bash
git add lib/features/seclusion/domain/retreat_session.dart \
  lib/features/seclusion/application/seclusion_service.dart \
  lib/data/isar_setup.dart test/data/save_migration_version_gate_test.dart \
  test/features/seclusion/application/seclusion_service_test.dart
git commit -m "[schema] 固化闭关开始境界快照"
```

## Task 3: Configure and calculate deterministic 12-hour equipment rolls

**Files:**
- Modify: `data/numbers.yaml`
- Modify: `lib/data/numbers_config.dart`
- Modify: `lib/features/seclusion/application/retreat_settlement_calculator.dart`
- Modify: `test/features/seclusion/application/retreat_settlement_calculator_test.dart`
- Modify: `test/features/seclusion/application/seclusion_drop_test.dart`

- [ ] **Step 1: Write failing node, weight, tier-clamp, and stable-seed tests**

```dart
test('equipment nodes are floor(hours / 12), capped at six', () {
  expect(equipmentRollCount(11 + 59 / 60), 0);
  expect(equipmentRollCount(12), 1);
  expect(equipmentRollCount(71 + 59 / 60), 5);
  expect(equipmentRollCount(72), 6);
  expect(equipmentRollCount(240), 6);
});

test('same session and node always return the same equipment', () {
  final a = calculator.rollEquipment(session: session, node: 6, defs: defs);
  final b = calculator.rollEquipment(session: session, node: 6, defs: defs);
  expect(b.map((e) => e.defId), a.map((e) => e.defId));
});
```

- [ ] **Step 2: Run tests and verify RED**

Run:
`flutter test --no-pub test/features/seclusion/application/retreat_settlement_calculator_test.dart test/features/seclusion/application/seclusion_drop_test.dart`

Expected: existing one-roll-per-session behavior fails node-count and tier-weight assertions.

- [ ] **Step 3: Add YAML-driven weight table**

```yaml
retreat:
  equipment_roll_interval_hours: 12
  equipment_roll_max_count: 6
  equipment_tier_weights:
    - {hour: 12, base: 0.80, current: 0.18, above_1: 0.02, above_2: 0.00}
    - {hour: 24, base: 0.70, current: 0.25, above_1: 0.05, above_2: 0.00}
    - {hour: 36, base: 0.60, current: 0.30, above_1: 0.08, above_2: 0.02}
    - {hour: 48, base: 0.50, current: 0.34, above_1: 0.12, above_2: 0.04}
    - {hour: 60, base: 0.40, current: 0.38, above_1: 0.16, above_2: 0.06}
    - {hour: 72, base: 0.30, current: 0.40, above_1: 0.20, above_2: 0.10}
```

Parse into immutable `RetreatEquipmentTierWeights`; validate six ordered nodes, each row sum `1.0 ± 1e-9`, non-negative weights, interval 12, and max count 6.

- [ ] **Step 4: Implement deterministic roll selection**

Use stable seed material `(saveDataId, session.id, startedAt.microsecondsSinceEpoch, nodeIndex)` with 32-bit FNV-1a (not Dart `Object.hash`, whose stability is not a persistence contract):

```dart
int stableRetreatSeed(Iterable<int> values) {
  var hash = 0x811c9dc5;
  for (final value in values) {
    for (var shift = 0; shift < 64; shift += 8) {
      hash ^= (value >> shift) & 0xff;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
  }
  return hash;
}
```

The calculation must:

1. Roll map probability `equipmentDropRate * baseEquipDropProbability`.
2. Select slot tendency from the map drop table.
3. Compute `baseTier = max(mapTier, max(xunChang, realmTierAtStart.index - 1))`.
4. Apply the approved row; merge overflow weights into `shenWu`.
5. Pick uniformly from global defs matching target tier and slot; fall back down to the nearest populated tier.

- [ ] **Step 5: Verify GREEN and red lines**

Run:
`flutter test --no-pub test/features/seclusion/application/retreat_settlement_calculator_test.dart test/features/seclusion/application/seclusion_drop_test.dart test/data/game_repository_test.dart`

Expected: all pass; no guarantee test confirms six misses remain possible; high-tier inventory objects retain normal equip-lock behavior.

- [ ] **Step 6: Commit**

```bash
git add data/numbers.yaml lib/data/numbers_config.dart \
  lib/features/seclusion/application/retreat_settlement_calculator.dart \
  test/features/seclusion/application/retreat_settlement_calculator_test.dart \
  test/features/seclusion/application/seclusion_drop_test.dart
git commit -m "[schema] 增加闭关分段装备判定"
```

## Task 4: Build combined preview and transactional collection

**Files:**
- Modify: `lib/features/seclusion/application/retreat_settlement_calculator.dart`
- Modify: `lib/features/seclusion/application/seclusion_service.dart`
- Modify: `lib/features/seclusion/application/offline_recap_service.dart`
- Modify: `test/features/seclusion/application/seclusion_service_test.dart`
- Modify: `test/features/seclusion/application/offline_recap_service_test.dart`
- Modify: `test/features/seclusion/application/offline_passive_settle_test.dart`

- [ ] **Step 1: Write failing combined-result tests**

```dart
test('10 days = 72h retreat plus 168h passive without overlap', () {
  final preview = calculator.preview(
    session: session,
    now: start.add(const Duration(days: 10)),
    realmTier: RealmTier.xueTu,
    retreatConfig: retreatConfig,
    passiveConfig: passiveConfig,
    maps: maps,
  );
  expect(preview.retreatHours, 72);
  expect(preview.passiveHours, 168);
  expect(preview.passive.experience, 8400); // 50 exp/h × 168h × xueTu 1.0
});

test('collect completes once and resets lastOnlineAt to collect time', () async {
  Future<RetreatResult> collect() => service.completeRetreat(
    session: session,
    characterId: kCharId,
    config: retreatConfig,
    maps: maps,
    now: collectAt,
  );

  final first = await collect();
  expect(first.passiveHours, 168);
  expect((await isar.saveDatas.get(0))!.lastOnlineAt, collectAt);
  await expectLater(collect, throwsStateError);
});
```

- [ ] **Step 2: Run tests and verify RED**

Run:
`flutter test --no-pub -j1 test/features/seclusion/application/seclusion_service_test.dart test/features/seclusion/application/offline_recap_service_test.dart test/features/seclusion/application/offline_passive_settle_test.dart`

Expected: result lacks split fields; current service truncates at planned duration and does not award passive overflow.

- [ ] **Step 3: Define one shared preview/result shape**

```dart
typedef RetreatSettlement = ({
  double elapsedHours,
  double retreatHours,
  double passiveHours,
  RetreatOutputs retreat,
  PassiveYield passive,
  List<RetreatEquipmentReward> equipmentRewards,
});
```

`RetreatEquipmentReward` includes `nodeHour`, `Equipment equipment`, and `isAboveCurrentTier`. `RetreatResult` carries the same split plus advancement.

- [ ] **Step 4: Make `completeRetreat` consume the shared calculation in one write transaction**

Remove `charRealmTier` from `completeRetreat`; all reward scale and tier decisions read `session.realmTierAtStart` (a null value is a migration/data error on a new session). Write all deterministic resources, overflow passive experience/stones, equipment, character progression, session completion, and `SaveData.lastOnlineAt = now` atomically. Check `session.status == active` inside the transaction before any reward mutation. Feed encounter minutes only for `retreatHours` after the transaction; do not count passive overflow as map biome time.

- [ ] **Step 5: Replace recap planned-duration semantics**

Remove `OfflineRecapLimitReason.plannedDuration`; expose `retreatHours`, `passiveHours`, guaranteed resource previews, equipment roll count, next-node remaining time, and `fullRateComplete`.

- [ ] **Step 6: Verify GREEN**

Run:
`flutter test --no-pub -j1 test/features/seclusion/application/seclusion_service_test.dart test/features/seclusion/application/offline_recap_service_test.dart test/features/seclusion/application/offline_passive_settle_test.dart test/features/seclusion/injury_recovery_test.dart test/features/seclusion/seclusion_residue_test.dart`

Expected: split, idempotence, injuries, residue, advancement, encounter minutes, and baseline assertions all pass.

- [ ] **Step 7: Commit**

```bash
git add lib/features/seclusion/application/retreat_settlement_calculator.dart \
  lib/features/seclusion/application/seclusion_service.dart \
  lib/features/seclusion/application/offline_recap_service.dart \
  test/features/seclusion/application/seclusion_service_test.dart \
  test/features/seclusion/application/offline_recap_service_test.dart \
  test/features/seclusion/application/offline_passive_settle_test.dart \
  test/features/seclusion/injury_recovery_test.dart \
  test/features/seclusion/seclusion_residue_test.dart
git commit -m "接续闭关与普通挂机结算"
```

## Task 5: Replace duration selection and active-retreat presentation

**Files:**
- Modify: `lib/features/seclusion/presentation/seclusion_setup_screen.dart`
- Modify: `lib/features/seclusion/presentation/active_retreat_screen.dart`
- Modify: `lib/shared/strings.dart`
- Modify: `test/features/seclusion/presentation/seclusion_e2e_test.dart`
- Modify: `test/features/seclusion/presentation/active_retreat_exit_test.dart`

- [ ] **Step 1: Write failing widget tests at desktop viewports**

```dart
testWidgets('setup removes duration choices and explains the two phases', (tester) async {
  await pumpSetup(tester, size: const Size(1280, 720));
  expect(find.text(UiStrings.seclusionDurationLabel(12)), findsNothing);
  expect(find.text(UiStrings.seclusionOpenEndedRule), findsOneWidget);
});

testWidgets('active screen at 10 days shows 72h full-rate and 7d passive', (tester) async {
  await pumpActive(tester, elapsed: const Duration(days: 10));
  expect(find.text(UiStrings.activeRetreatFullRateComplete), findsOneWidget);
  expect(find.textContaining('7天'), findsOneWidget);
  expect(find.text(UiStrings.activeRetreatEquipmentRolls(6, 6)), findsOneWidget);
});
```

- [ ] **Step 2: Run tests and verify RED**

Run:
`flutter test --no-pub test/features/seclusion/presentation/seclusion_e2e_test.dart test/features/seclusion/presentation/active_retreat_exit_test.dart`

Expected: old duration cards, end time, early/done states, and fixed progress bar violate new assertions.

- [ ] **Step 3: Implement setup and live active screen**

Remove `_selectedHours`, `_durations`, and `_DurationButton`. Add the two-phase explanatory panel. Remove `charRealmTier` from `ActiveRetreatScreen`; its preview uses `session.realmTierAtStart`. In active screen, use a one-minute ticker only to refresh display; settlement remains derived from wall-clock `startedAt`. Replace end-time UI with elapsed time, full-rate `min(elapsed,72)` progress, passive overflow, exact guaranteed preview, equipment node count, next-node countdown, and current node tier weights. Keep one always-enabled `收功` action and its confirmation dialog.

- [ ] **Step 4: Verify semantics and desktop interaction**

Run:
`flutter test --no-pub test/features/seclusion/presentation/seclusion_e2e_test.dart test/features/seclusion/presentation/active_retreat_exit_test.dart`

Expected: pass at 1280×720 and 1440×900; Escape/back works, Enter activates collect, focus and mouse semantics remain intact, no overflow exceptions.

- [ ] **Step 5: Commit**

```bash
git add lib/features/seclusion/presentation/seclusion_setup_screen.dart \
  lib/features/seclusion/presentation/active_retreat_screen.dart \
  lib/shared/strings.dart \
  test/features/seclusion/presentation/seclusion_e2e_test.dart \
  test/features/seclusion/presentation/active_retreat_exit_test.dart
git commit -m "改造开放式闭关交互"
```

## Task 6: Update return card, main-menu banner, result screen, and gates

**Files:**
- Modify: `lib/features/seclusion/presentation/offline_recap_card.dart`
- Modify: `lib/features/seclusion/presentation/offline_recap_gate.dart`
- Modify: `lib/features/seclusion/presentation/retreat_result_screen.dart`
- Modify: `lib/features/seclusion/presentation/seclusion_gate.dart`
- Modify: `lib/features/main_menu/presentation/main_menu_retreat_banner.dart`
- Modify: `lib/shared/strings.dart`
- Modify: `test/features/seclusion/presentation/offline_recap_card_test.dart`
- Modify: `test/features/seclusion/presentation/offline_recap_gate_test.dart`
- Modify: `test/features/seclusion/presentation/retreat_result_screen_test.dart`
- Modify: `test/features/seclusion/presentation/seclusion_gate_test.dart`
- Modify: `test/features/main_menu/main_menu_retreat_banner_test.dart`
- Modify: `test/features/main_menu/presentation/main_menu_test.dart`

- [ ] **Step 1: Write failing presentation and gate tests**

```dart
testWidgets('return card does not auto-collect and offers dismiss or inspect', (tester) async {
  await pumpReturnCard(tester, elapsed: const Duration(days: 10));
  expect(find.text(UiStrings.offlineRecapDismiss), findsOneWidget);
  expect(find.text(UiStrings.offlineRecapGoCollect), findsOneWidget);
  expect(fakeWriter.calls, 0);
});

testWidgets('result separates retreat and passive rewards', (tester) async {
  await pumpResult(tester, result: tenDayResult);
  expect(find.text(UiStrings.seclusionResultRetreatSection), findsOneWidget);
  expect(find.text(UiStrings.seclusionResultPassiveSection), findsOneWidget);
  expect(find.text(UiStrings.equipmentLockedUntilRealm), findsWidgets);
});
```

- [ ] **Step 2: Run tests and verify RED**

Run:
`flutter test --no-pub test/features/seclusion/presentation/offline_recap_card_test.dart test/features/seclusion/presentation/offline_recap_gate_test.dart test/features/seclusion/presentation/retreat_result_screen_test.dart test/features/seclusion/presentation/seclusion_gate_test.dart test/features/main_menu/main_menu_retreat_banner_test.dart`

Expected: old capped/planned copy and combined result list fail.

- [ ] **Step 3: Implement two-phase summaries and stable locks**

Return card and banner show elapsed/full-rate/passive phases and never collect automatically. Result screen renders separate resource sections; each equipment row includes its node hour and an above-realm lock label. Keep `guardBattleEntry` as the shared main-menu gate, change copy from “提前出关” to “前去收功”, and verify all battle/mainline/tower/sweep/inner-demon entries still call it.

- [ ] **Step 4: Verify GREEN and viewport semantics**

Run the command from Step 2 plus:
`flutter test --no-pub test/features/main_menu/presentation/main_menu_test.dart`

Expected: all pass at both desktop viewports; dismissal leaves session active; battle remains blocked until a successful collect.

- [ ] **Step 5: Commit**

```bash
git add lib/features/seclusion/presentation/offline_recap_card.dart \
  lib/features/seclusion/presentation/offline_recap_gate.dart \
  lib/features/seclusion/presentation/retreat_result_screen.dart \
  lib/features/seclusion/presentation/seclusion_gate.dart \
  lib/features/main_menu/presentation/main_menu_retreat_banner.dart \
  lib/shared/strings.dart test/features/seclusion/presentation \
  test/features/main_menu/main_menu_retreat_banner_test.dart \
  test/features/main_menu/presentation/main_menu_test.dart
git commit -m "展示闭关与接续挂机分段收益"
```

## Task 7: Remove stale caps and synchronize design truth

**Files:**
- Modify: `data/numbers.yaml`
- Modify: `lib/data/numbers_config.dart`
- Modify: `test/features/seclusion/domain/seclusion_map_def_test.dart`
- Modify: `test/features/seclusion/presentation/offline_recap_passive_card_test.dart`
- Modify: `GDD.md`
- Modify: `CLAUDE.md`
- Modify: `PROGRESS.md`

- [ ] **Step 1: Write failing config truth tests**

```dart
test('passive idle has no cap while retreat full-rate phase remains 72h', () {
  expect(repo.numbers.retreat.capHours, 72);
  expect(repo.numbers.passiveIdle.hasTimeCap, isFalse);
});
```

- [ ] **Step 2: Run test and verify RED**

Run:
`flutter test --no-pub test/features/seclusion/domain/seclusion_map_def_test.dart test/features/seclusion/presentation/offline_recap_passive_card_test.dart`

Expected: passive config/UI still exposes a 72-hour cap and capped copy.

- [ ] **Step 3: Remove stale passive cap schema and copy**

Delete `passive_idle.cap_hours` and its `PassiveIdleConfig.capHours` consumer. Replace `isCapped` UI branches with uncapped settled-time copy. Keep `retreat.cap_hours: 72`, but rename comments/docs from “超出不累积” to “闭关地图全收益阶段，超出转普通挂机”.

- [ ] **Step 4: Synchronize GDD/CLAUDE/PROGRESS**

Document the approved formula, open-ended manual collect, six deterministic rolls with no guarantee, three-system lock, old-save migration, verification status, and explicit exclusion of Taohua Island caps. Remove the old `durationHours [1,4,12]` and “72h stops” statements where they describe production behavior.

- [ ] **Step 5: Verify and commit**

Run:
`flutter test --no-pub test/features/seclusion/domain/seclusion_map_def_test.dart test/features/seclusion/presentation/offline_recap_passive_card_test.dart`

Expected: all pass; literal search finds no production statement claiming passive rewards stop at 72 hours.

```bash
git add data/numbers.yaml lib/data/numbers_config.dart \
  test/features/seclusion/domain/seclusion_map_def_test.dart \
  test/features/seclusion/presentation/offline_recap_passive_card_test.dart \
  GDD.md CLAUDE.md PROGRESS.md
git commit -m "[GDD] 同步开放式闭关规则"
```

## Task 8: Full verification, visual smoke, and READY handoff

**Files:**
- Modify: `docs/superpowers/plans/2026-07-12-open-ended-retreat-settlement.md` (recovery point only)

- [ ] **Step 1: Format and run static analysis**

Run:

```bash
dart format lib test
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 2: Run the full seclusion and migration suite**

Run:

```bash
flutter test --no-pub -j1 test/features/seclusion test/features/main_menu/main_menu_retreat_banner_test.dart test/data/save_migration_version_gate_test.dart
```

Expected: all pass with zero failures.

- [ ] **Step 3: Run full repository tests**

Run:
`flutter test --no-pub`

Expected: all tests pass. If the known concurrent data isolation flake appears, record the failing test and rerun that file with `-j1`; do not hide a feature-related failure.

- [ ] **Step 4: Run macOS visual smoke**

At 1280×720 and 1440×900 verify:

1. Setup page has no duration cards and clearly explains both phases.
2. Active page at <12h, 72h, and 10d fixtures has no overflow and shows correct nodes.
3. Return card dismisses without collecting.
4. Battle entry remains blocked and routes to active retreat.
5. Result page separates both phases and labels locked high-tier equipment.
6. Keyboard Enter/Escape, focus rings, and mouse cursor remain functional.

- [ ] **Step 5: Inspect diff and red lines**

Run:

```bash
git diff --check
git status --short
rg -n "durationHours|cap_hours|999999" lib/features/seclusion data/numbers.yaml
```

Expected: only intentional legacy/schema references remain; no untracked capture files; no scattered Chinese strings or balance constants in Dart.

- [ ] **Step 6: Update recovery point and commit READY marker**

```bash
git add docs/superpowers/plans/2026-07-12-open-ended-retreat-settlement.md
git commit -m "更新开放式闭关交付恢复点"
git commit --allow-empty -m "[READY] 完成开放式闭关与无上限接续挂机"
```

## Current recovery point

- **Status:** Plan written; implementation not started.
- **Last completed:** Approved design committed at `5c9c205b`; implementation plan created on `main`.
- **Next step:** Commit this plan, create `.worktrees/open-ended-retreat-settlement` on `codex/open-ended-retreat-settlement`, then execute Task 1 RED test.
- **Verification run:** Design self-review only; no implementation tests yet.
- **Blockers:** None.
