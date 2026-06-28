# Equipment Filter Lock Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand the equipment inventory filters so players can explicitly filter by school and lock/protection state before selling or disassembling equipment.

**Architecture:** Keep this as a presentation/query-layer slice: no schema, no saveVersion, no numbers.yaml. Add new filter enums and pure matching logic in `inventory_organization.dart`, then wire them into the existing inventory filter bar and centralized `UiStrings`.

**Tech Stack:** Flutter Desktop, Riverpod 3.x, Isar domain entities, pure Dart unit tests with `flutter test`.

---

## Scope

This slice implements the backlog item **装备筛选与锁定优化** only. It does not implement material source lookup, target tracking, or artisan commissions.

## Branch

- Branch: `codex/equipment-filter-lock`
- Worktree: `/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/codex-equipment-filter-lock`

## Validation

- `flutter test --no-pub test/features/inventory/application/inventory_organization_test.dart`
- `flutter analyze lib/features/inventory/application/inventory_organization.dart lib/features/inventory/presentation/inventory_screen.dart lib/shared/strings.dart`

## Current Recovery Point

- Status: implementation complete.
- Last completed: school, locked, and protection filters added and wired.
- Next step: review/merge decision.
- Verification run: `flutter test --no-pub test/features/inventory/application/inventory_organization_test.dart` passed 6/6; `flutter analyze lib/features/inventory/application/inventory_organization.dart lib/features/inventory/presentation/inventory_screen.dart lib/shared/strings.dart` passed with no issues.
- Blockers: none.

## File Map

- Modify `lib/features/inventory/application/inventory_organization.dart`: add `InventorySchoolFilter` and extend `InventoryOwnershipFilter` with `locked` and `protected`; query matching stays pure and testable.
- Modify `lib/features/inventory/presentation/inventory_screen.dart`: add local `_schoolFilter` state, pass it to `InventoryEquipmentQuery`, render school chips, and label new filters.
- Modify `lib/shared/strings.dart`: add centralized UI labels for school filter and lock/protection filters.
- Modify `test/features/inventory/application/inventory_organization_test.dart`: cover school, locked, and protected filtering.

### Task 1: Query Model Tests

**Files:**
- Modify: `test/features/inventory/application/inventory_organization_test.dart`

- [ ] **Step 1: Extend the local `eq` test helper**

Add a `TechniqueSchool? school` parameter and pass it into `Equipment.create`:

```dart
TechniqueSchool? school,
...
school: school,
```

- [ ] **Step 2: Add school filter test**

Add this test under `group('organizeInventoryEquipments', ...)`:

```dart
test('按流派筛选装备，空流派可单独查出', () {
  final result = organizeInventoryEquipments(
    [
      eq(
        id: 1,
        tier: EquipmentTier.liQi,
        slot: EquipmentSlot.weapon,
        school: TechniqueSchool.gangMeng,
      ),
      eq(
        id: 2,
        tier: EquipmentTier.liQi,
        slot: EquipmentSlot.weapon,
        school: TechniqueSchool.lingQiao,
      ),
      eq(id: 3, tier: EquipmentTier.liQi, slot: EquipmentSlot.weapon),
    ],
    const InventoryEquipmentQuery(school: InventorySchoolFilter.gangMeng),
  );

  expect(result.map((e) => e.id), [1]);

  final none = organizeInventoryEquipments(
    [
      eq(
        id: 1,
        tier: EquipmentTier.liQi,
        slot: EquipmentSlot.weapon,
        school: TechniqueSchool.gangMeng,
      ),
      eq(id: 3, tier: EquipmentTier.liQi, slot: EquipmentSlot.weapon),
    ],
    const InventoryEquipmentQuery(school: InventorySchoolFilter.none),
  );

  expect(none.map((e) => e.id), [3]);
});
```

- [ ] **Step 3: Add lock/protection state test**

Add this test under the same group:

```dart
test('可显式筛出锁定与批量受保护装备', () {
  final locked = eq(
    id: 1,
    tier: EquipmentTier.xunChang,
    slot: EquipmentSlot.weapon,
    isLocked: true,
  );
  final highTier = eq(
    id: 2,
    tier: EquipmentTier.zhongQi,
    slot: EquipmentSlot.weapon,
  );
  final free = eq(
    id: 3,
    tier: EquipmentTier.xunChang,
    slot: EquipmentSlot.weapon,
  );

  final lockedResult = organizeInventoryEquipments(
    [locked, highTier, free],
    const InventoryEquipmentQuery(ownership: InventoryOwnershipFilter.locked),
  );
  expect(lockedResult.map((e) => e.id), [1]);

  final protectedResult = organizeInventoryEquipments(
    [locked, highTier, free],
    const InventoryEquipmentQuery(ownership: InventoryOwnershipFilter.protected),
    equippedEquipmentIds: const {},
  );
  expect(protectedResult.map((e) => e.id), [2, 1]);
});
```

- [ ] **Step 4: Run test and confirm it fails before implementation**

Run:

```bash
flutter test --no-pub test/features/inventory/application/inventory_organization_test.dart
```

Expected: compile failure for missing `InventorySchoolFilter`, missing query field, and missing ownership enum values.

### Task 2: Pure Filter Implementation

**Files:**
- Modify: `lib/features/inventory/application/inventory_organization.dart`
- Test: `test/features/inventory/application/inventory_organization_test.dart`

- [ ] **Step 1: Add school filter enum**

Add after `InventoryTierFilter`:

```dart
enum InventorySchoolFilter { all, gangMeng, lingQiao, yinRou, none }
```

- [ ] **Step 2: Extend ownership filter**

Add values to `InventoryOwnershipFilter`:

```dart
locked,
protected,
```

- [ ] **Step 3: Extend query object**

Add field and constructor default:

```dart
final InventorySchoolFilter school;
...
this.school = InventorySchoolFilter.all,
```

- [ ] **Step 4: Pass equipped ids and policy into organization function**

Change signature:

```dart
List<Equipment> organizeInventoryEquipments(
  Iterable<Equipment> equipments,
  InventoryEquipmentQuery query, {
  RealmTier? realm,
  Set<int> equippedEquipmentIds = const {},
  Set<int> activeFormationEquipmentIds = const {},
  EquipmentProtectionPolicy policy = EquipmentProtectionPolicy.defaultPolicy,
})
```

Update predicate to include `_matchesSchool` and pass the protection inputs into `_matchesOwnership`.

- [ ] **Step 5: Add `_matchesSchool`**

```dart
bool _matchesSchool(Equipment eq, InventorySchoolFilter filter) {
  return switch (filter) {
    InventorySchoolFilter.all => true,
    InventorySchoolFilter.gangMeng => eq.school == TechniqueSchool.gangMeng,
    InventorySchoolFilter.lingQiao => eq.school == TechniqueSchool.lingQiao,
    InventorySchoolFilter.yinRou => eq.school == TechniqueSchool.yinRou,
    InventorySchoolFilter.none => eq.school == null,
  };
}
```

- [ ] **Step 6: Extend `_matchesOwnership`**

Add parameters:

```dart
Set<int> equippedEquipmentIds,
Set<int> activeFormationEquipmentIds,
EquipmentProtectionPolicy policy,
```

Add cases:

```dart
InventoryOwnershipFilter.locked => eq.isLocked,
InventoryOwnershipFilter.protected =>
  equipmentProtectionReason(
        eq,
        equippedEquipmentIds: equippedEquipmentIds,
        activeFormationEquipmentIds: activeFormationEquipmentIds,
        policy: policy,
      ) !=
      null,
```

- [ ] **Step 7: Run target test**

Run:

```bash
flutter test --no-pub test/features/inventory/application/inventory_organization_test.dart
```

Expected: all tests pass.

- [ ] **Step 8: Commit pure filter layer**

```bash
git add lib/features/inventory/application/inventory_organization.dart test/features/inventory/application/inventory_organization_test.dart
git commit -m "feat: extend inventory equipment filters"
```

### Task 3: Inventory UI Wiring

**Files:**
- Modify: `lib/features/inventory/presentation/inventory_screen.dart`
- Modify: `lib/shared/strings.dart`

- [ ] **Step 1: Add strings**

Add near existing inventory filter labels:

```dart
static const String inventoryFilterSchoolAll = '流派：全部';
static const String inventoryFilterSchoolNone = '流派：无';
static String inventoryFilterSchoolLabel(String name) => '流派：$name';
static const String inventoryFilterLocked = '已锁定';
static const String inventoryFilterProtected = '受保护';
```

- [ ] **Step 2: Add `_schoolFilter` state**

In `_EquipmentTabState`:

```dart
InventorySchoolFilter _schoolFilter = InventorySchoolFilter.all;
```

- [ ] **Step 3: Pass filter and protection context into query**

When calling `organizeInventoryEquipments`, pass:

```dart
school: _schoolFilter,
...
equippedEquipmentIds: equippedIds,
activeFormationEquipmentIds: equippedIds,
```

- [ ] **Step 4: Extend `_OrganizationBar` constructor and fields**

Add:

```dart
final InventorySchoolFilter schoolFilter;
final ValueChanged<InventorySchoolFilter> onSchoolSelect;
```

Wire them from `_EquipmentTabState`.

- [ ] **Step 5: Render school chips**

In `_OrganizationBar.build`, between tier and ownership filters, add:

```dart
for (final f in InventorySchoolFilter.values)
  _FilterChip(
    label: _schoolFilterLabel(f),
    selected: f == schoolFilter,
    onTap: () => onSchoolSelect(f),
  ),
```

- [ ] **Step 6: Add label helpers**

Add:

```dart
String _schoolFilterLabel(InventorySchoolFilter filter) {
  return switch (filter) {
    InventorySchoolFilter.all => UiStrings.inventoryFilterSchoolAll,
    InventorySchoolFilter.gangMeng => UiStrings.inventoryFilterSchoolLabel(
      EnumL10n.school(TechniqueSchool.gangMeng),
    ),
    InventorySchoolFilter.lingQiao => UiStrings.inventoryFilterSchoolLabel(
      EnumL10n.school(TechniqueSchool.lingQiao),
    ),
    InventorySchoolFilter.yinRou => UiStrings.inventoryFilterSchoolLabel(
      EnumL10n.school(TechniqueSchool.yinRou),
    ),
    InventorySchoolFilter.none => UiStrings.inventoryFilterSchoolNone,
  };
}
```

Extend `_ownershipFilterLabel` with:

```dart
InventoryOwnershipFilter.locked => UiStrings.inventoryFilterLocked,
InventoryOwnershipFilter.protected => UiStrings.inventoryFilterProtected,
```

- [ ] **Step 7: Analyze touched files**

Run:

```bash
flutter analyze lib/features/inventory/application/inventory_organization.dart lib/features/inventory/presentation/inventory_screen.dart lib/shared/strings.dart
```

Expected: no issues.

- [ ] **Step 8: Run target test**

Run:

```bash
flutter test --no-pub test/features/inventory/application/inventory_organization_test.dart
```

Expected: all tests pass.

- [ ] **Step 9: Commit UI wiring**

```bash
git add lib/features/inventory/presentation/inventory_screen.dart lib/shared/strings.dart
git commit -m "feat: wire equipment school and protection filters"
```

### Task 4: Recovery Point Update

**Files:**
- Modify: `docs/superpowers/plans/2026-06-28-equipment-filter-lock.md`

- [ ] **Step 1: Update current recovery point**

Set:

```markdown
- Status: implementation complete.
- Last completed: school, locked, and protection filters added and wired.
- Next step: review/merge decision.
- Verification run: target test passed; analyze touched files passed.
- Blockers: none.
```

- [ ] **Step 2: Commit plan recovery update**

```bash
git add docs/superpowers/plans/2026-06-28-equipment-filter-lock.md
git commit -m "docs: update equipment filter recovery point"
```
