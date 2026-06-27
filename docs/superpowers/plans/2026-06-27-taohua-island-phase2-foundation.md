# Taohua Island Phase 2 Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand 桃花岛 from a four-building card list into a medium-depth经营据点 foundation with 6-8 buildings, two-layer production chains, and a denser island-style screen.

**Architecture:** Reuse the existing `source / processor / recipes / cap / upgrade` model. Keep all production math in `IslandProductionService`, all Isar writes in settle/action services, and keep the first UI pass data-driven so later scene art can replace layout without changing services.

**Tech Stack:** Flutter Desktop, Riverpod 3, Isar, YAML config via `NumbersConfig`, existing `WuxiaUi` widgets.

---

## Branch

Create and work only on:

```bash
git switch main
git pull --ff-only
git switch -c codex/taohua-island-phase2-foundation
```

## Files

- Modify: `data/items.yaml` — add raw materials and processed island outputs.
- Modify: `data/numbers.yaml` — expand `taohua_island.buildings`.
- Modify: `lib/features/taohua_island/domain/island_building_type.dart` — add pinyin building enum values, following existing `tieJiangChang / caoYaoYuan / daZaoTai / danFang` style.
- Modify: `lib/features/battle/domain/enum_localizations.dart` — add building display names if this file currently owns building labels.
- Modify: `lib/shared/strings.dart` — add UI strings for new building states and section labels.
- Modify: `lib/features/taohua_island/domain/taohua_island_config.dart` — validate 6-8 building config, no behavior fork unless validation requires it.
- Modify: `lib/features/taohua_island/presentation/taohua_island_screen.dart` — replace linear card list with grouped据点 layout.
- Test: `test/features/taohua_island/taohua_island_config_test.dart`
- Test: `test/features/taohua_island/island_production_service_test.dart`
- Test: `test/features/taohua_island/taohua_island_screen_test.dart`
- Test: `test/data/item_def_test.dart`

## Tasks

### Task 1: Add Building Types

**Files:**
- Modify: `lib/features/taohua_island/domain/island_building_type.dart`
- Modify: `test/features/taohua_island/taohua_island_config_test.dart`

- [ ] **Step 1: Inspect current enum and parser**

Run:

```bash
sed -n '1,220p' lib/features/taohua_island/domain/island_building_type.dart
```

Expected: existing enum includes the four phase-one buildings and a YAML key parser.

- [ ] **Step 2: Write failing parser coverage**

Add test cases that assert the new YAML keys parse. Keep the existing pinyin naming style:

```dart
test('phase 2 island building yaml keys parse', () {
  expect(buildingTypeFromYamlKey('mu_gong_fang'), BuildingType.muGongFang);
  expect(buildingTypeFromYamlKey('ling_quan'), BuildingType.lingQuan);
  expect(buildingTypeFromYamlKey('zhu_zao_tai'), BuildingType.zhuZaoTai);
});
```

Run:

```bash
flutter test test/features/taohua_island/taohua_island_config_test.dart
```

Expected: FAIL because the new enum values do not exist.

- [ ] **Step 3: Implement enum values and parser mapping**

Add these values to `BuildingType`:

```dart
muGongFang,
lingQuan,
zhuZaoTai,
```

Map YAML keys:

```dart
'mu_gong_fang' => BuildingType.muGongFang,
'ling_quan' => BuildingType.lingQuan,
'zhu_zao_tai' => BuildingType.zhuZaoTai,
```

- [ ] **Step 4: Run targeted test**

Run:

```bash
flutter test test/features/taohua_island/taohua_island_config_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/taohua_island/domain/island_building_type.dart test/features/taohua_island/taohua_island_config_test.dart
git commit -m "feat(island): add phase two building types"
```

### Task 2: Add Item and Building Config

**Files:**
- Modify: `data/items.yaml`
- Modify: `data/numbers.yaml`
- Modify: `test/data/item_def_test.dart`
- Modify: `test/features/taohua_island/taohua_island_config_test.dart`

- [ ] **Step 1: Add item definition test**

Add assertions for these def IDs:

```dart
const ids = [
  'item_mucai',
  'item_lingquanshui',
  'item_liaoshangdan',
  'item_duancai',
  'item_kaifeng_fucai',
  'item_xingnang_buji',
];
for (final id in ids) {
  expect(repo.itemDefs.containsKey(id), isTrue, reason: id);
}
```

Run:

```bash
flutter test test/data/item_def_test.dart
```

Expected: FAIL for missing item defs.

- [ ] **Step 2: Add item YAML**

Add items with existing item schema. Use conservative names and item types already accepted by `ItemType.fromDefId`; if a new type would be required, keep IDs under existing material/misc conventions instead of adding schema.

Required item IDs:

```yaml
- id: item_mucai
  name: 木材
- id: item_lingquanshui
  name: 灵泉水
- id: item_liaoshangdan
  name: 疗伤丹
- id: item_duancai
  name: 锻材
- id: item_kaifeng_fucai
  name: 开锋辅材
- id: item_xingnang_buji
  name: 行囊补给
```

Match all required fields from neighboring item entries.

- [ ] **Step 3: Add building config coverage**

Extend `taohua_island_config_test.dart` to assert:

```dart
final cfg = GameRepository.instance.numbers.taohuaIsland;
expect(cfg.buildings.length, greaterThanOrEqualTo(7));
expect(cfg.buildings[BuildingType.muGongFang]!.kind, BuildingKind.source);
expect(cfg.buildings[BuildingType.lingQuan]!.kind, BuildingKind.source);
expect(cfg.buildings[BuildingType.zhuZaoTai]!.kind, BuildingKind.processor);
```

Run:

```bash
flutter test test/features/taohua_island/taohua_island_config_test.dart
```

Expected: FAIL until `numbers.yaml` is expanded.

- [ ] **Step 4: Expand `data/numbers.yaml`**

Under `taohua_island.buildings`, add configs:

- `mu_gong_fang`: source → `item_mucai`
- `ling_quan`: source → `item_lingquanshui`
- `zhu_zao_tai`: processor input `item_mucai`, recipes to `item_kaifeng_fucai` and `item_xingnang_buji`

Keep the existing four buildings unchanged:

- `tie_jiang_chang`: source → `item_jingtie`
- `cao_yao_yuan`: source → `item_yaocao`
- `da_zao_tai`: processor input `item_jingtie`
- `dan_fang`: processor input `item_yaocao`

Keep `max_level: 5`, monotonic `upgrade_realm_levels`, and conservative `base_rate_per_hour` so `cap_hours` remains the long-idle cap.

- [ ] **Step 5: Run config tests**

Run:

```bash
flutter test test/data/item_def_test.dart test/features/taohua_island/taohua_island_config_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add data/items.yaml data/numbers.yaml test/data/item_def_test.dart test/features/taohua_island/taohua_island_config_test.dart
git commit -m "feat(island): add phase two production config"
```

### Task 3: Preserve Offline Equals Online Production

**Files:**
- Modify: `test/features/taohua_island/island_production_service_test.dart`
- Modify: `lib/features/taohua_island/application/island_production_service.dart` only if the test exposes a real bug.

- [ ] **Step 1: Add multi-source production invariant test**

Create a test with all phase-two buildings initialized at level 1. Compare one 8-hour settlement with two 4-hour settlements:

```dart
final once = IslandProductionService.settle(
  states: initialStates,
  config: cfg,
  elapsedHours: 8,
  founderRealmIndex: 6,
);
final first = IslandProductionService.settle(
  states: initialStates,
  config: cfg,
  elapsedHours: 4,
  founderRealmIndex: 6,
);
final twice = IslandProductionService.settle(
  states: first,
  config: cfg,
  elapsedHours: 4,
  founderRealmIndex: 6,
);
expect(twice.map((s) => s.stored.floor()).toList(),
    once.map((s) => s.stored.floor()).toList());
```

Run:

```bash
flutter test test/features/taohua_island/island_production_service_test.dart
```

Expected: PASS. If it fails due processor ordering with multiple source types, fix production order without changing public API.

- [ ] **Step 2: Commit**

```bash
git add test/features/taohua_island/island_production_service_test.dart lib/features/taohua_island/application/island_production_service.dart
git commit -m "test(island): cover phase two offline production invariant"
```

### Task 4:据点式桃花岛 Screen

**Files:**
- Modify: `lib/features/taohua_island/presentation/taohua_island_screen.dart`
- Modify: `lib/shared/strings.dart`
- Modify: `lib/features/battle/domain/enum_localizations.dart`
- Modify: `test/features/taohua_island/taohua_island_screen_test.dart`

- [ ] **Step 1: Add widget test for grouped screen**

Add expectations for section labels:

```dart
expect(find.text(UiStrings.taohuaIslandSectionRaw), findsOneWidget);
expect(find.text(UiStrings.taohuaIslandSectionWorkshop), findsOneWidget);
expect(find.text(UiStrings.taohuaIslandSectionDock), findsOneWidget);
```

Run:

```bash
flutter test test/features/taohua_island/taohua_island_screen_test.dart
```

Expected: FAIL because the section strings/layout do not exist.

- [ ] **Step 2: Add centralized strings**

In `UiStrings`, add:

```dart
static const taohuaIslandSectionRaw = '物产';
static const taohuaIslandSectionWorkshop = '作坊';
static const taohuaIslandSectionDock = '码头';
```

Add building labels to `EnumL10n.buildingType` for all new enum values.

- [ ] **Step 3: Replace plain list with grouped layout**

Keep `_BuildingCard` behavior. Replace `_IslandBody` with grouped sections:

```dart
final raw = [
  BuildingType.tieJiangChang,
  BuildingType.caoYaoYuan,
  BuildingType.muGongFang,
  BuildingType.lingQuan,
];
final workshops = [
  BuildingType.daZaoTai,
  BuildingType.danFang,
  BuildingType.zhuZaoTai,
];
```

Use the existing `PaperPanel`/`PlaqueButton` visual language. Do not add new package dependencies.

- [ ] **Step 4: Run widget test**

Run:

```bash
flutter test test/features/taohua_island/taohua_island_screen_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/taohua_island/presentation/taohua_island_screen.dart lib/shared/strings.dart lib/features/battle/domain/enum_localizations.dart test/features/taohua_island/taohua_island_screen_test.dart
git commit -m "feat(island): present taohua island as a production outpost"
```

### Task 5: Final Verification

**Files:**
- Update: `PROGRESS.md` only if this branch is merged by the owning thread.

- [ ] **Step 1: Run targeted tests**

```bash
flutter test test/features/taohua_island test/data/item_def_test.dart
```

Expected: PASS.

- [ ] **Step 2: Run analyze**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Run full tests if branch is ready to merge**

```bash
flutter test
```

Expected: PASS with the current project baseline.

- [ ] **Step 4: Commit verification notes**

If only docs changed, no commit is needed. If implementation files changed after verification:

```bash
git status --short
git add <changed-files>
git commit -m "chore(island): verify phase two foundation"
```

## Self-Review

- Spec coverage: covers 桃花岛 building expansion, 2-layer production, no daily loop, and据点 screen foundation.
- Placeholders: no implementation step depends on an unspecified future file.
- Type consistency: uses existing `BuildingType`, `BuildingKind`, `TaohuaIslandConfig`, `IslandProductionService`, and `UiStrings` naming.
