# Zangjuange Hub And Clues Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 藏卷阁 as a long-term archive hub that gathers existing records and exposes equipment, fragment, and Boss-cycle clues without creating task rewards.

**Architecture:** Build a new feature folder for the hub and clue view models. Reuse existing providers/screens for 战绩册、兵器谱、奇遇录、藏经阁 instead of rewriting detail pages.

**Tech Stack:** Flutter Desktop, Riverpod 3, Isar-backed existing catalog providers, existing `WuxiaUi` widgets.

---

## Branch

Create and work only on:

```bash
git switch main
git pull --ff-only
git switch -c codex/zangjuange-hub-clues
```

## Files

- Create: `lib/features/zangjuange/domain/archive_clue.dart`
- Create: `lib/features/zangjuange/application/zangjuange_providers.dart`
- Create: `lib/features/zangjuange/presentation/zangjuange_screen.dart`
- Modify: `lib/features/main_menu/presentation/main_menu.dart`
- Modify: `lib/shared/strings.dart`
- Modify: `lib/features/debug/application/visual_route.dart`
- Modify: `lib/features/debug/presentation/visual_route_host.dart`
- Test: `test/features/zangjuange/archive_clue_test.dart`
- Test: `test/features/zangjuange/zangjuange_screen_test.dart`
- Test: `test/features/main_menu/presentation/main_menu_test.dart`

## Tasks

### Task 1: Archive Clue Domain Model

**Files:**
- Create: `lib/features/zangjuange/domain/archive_clue.dart`
- Create: `test/features/zangjuange/archive_clue_test.dart`

- [ ] **Step 1: Write failing model test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/zangjuange/domain/archive_clue.dart';

void main() {
  test('archive clue carries category and target metadata', () {
    const clue = ArchiveClue(
      category: ArchiveClueCategory.equipment,
      title: '缺少兵器',
      summary: '传闻可在边塞关卡寻得。',
      targetKind: ArchiveClueTargetKind.stage,
      targetId: 'stage_04_03',
    );

    expect(clue.category, ArchiveClueCategory.equipment);
    expect(clue.targetKind, ArchiveClueTargetKind.stage);
    expect(clue.targetId, 'stage_04_03');
  });
}
```

Run:

```bash
flutter test test/features/zangjuange/archive_clue_test.dart
```

Expected: FAIL because `ArchiveClue` does not exist.

- [ ] **Step 2: Create domain model**

```dart
enum ArchiveClueCategory { equipment, skillFragment, bossCycle }

enum ArchiveClueTargetKind { stage, towerFloor, bossRecord, none }

class ArchiveClue {
  final ArchiveClueCategory category;
  final String title;
  final String summary;
  final ArchiveClueTargetKind targetKind;
  final String? targetId;

  const ArchiveClue({
    required this.category,
    required this.title,
    required this.summary,
    this.targetKind = ArchiveClueTargetKind.none,
    this.targetId,
  });
}
```

- [ ] **Step 3: Run test**

```bash
flutter test test/features/zangjuange/archive_clue_test.dart
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/zangjuange/domain/archive_clue.dart test/features/zangjuange/archive_clue_test.dart
git commit -m "feat(zangjuange): add archive clue model"
```

### Task 2: Clue Provider

**Files:**
- Create: `lib/features/zangjuange/application/zangjuange_providers.dart`
- Modify: `test/features/zangjuange/archive_clue_test.dart`

- [ ] **Step 1: Add provider behavior tests**

Add a pure helper test if Riverpod setup is heavy:

```dart
test('clue builder limits first slice to three clue categories', () {
  final clues = buildZangjuangeClues(
    missingEquipmentCount: 2,
    missingFragmentCount: 1,
    unbrokenBossCycleCount: 3,
  );

  expect(clues.map((c) => c.category).toSet(), {
    ArchiveClueCategory.equipment,
    ArchiveClueCategory.skillFragment,
    ArchiveClueCategory.bossCycle,
  });
});
```

Run:

```bash
flutter test test/features/zangjuange/archive_clue_test.dart
```

Expected: FAIL because `buildZangjuangeClues` does not exist.

- [ ] **Step 2: Implement clue builder**

In `zangjuange_providers.dart`, add:

```dart
List<ArchiveClue> buildZangjuangeClues({
  required int missingEquipmentCount,
  required int missingFragmentCount,
  required int unbrokenBossCycleCount,
}) {
  final clues = <ArchiveClue>[];
  if (missingEquipmentCount > 0) {
    clues.add(ArchiveClue(
      category: ArchiveClueCategory.equipment,
      title: UiStrings.zangjuangeClueEquipmentTitle,
      summary: UiStrings.zangjuangeClueEquipmentSummary(missingEquipmentCount),
    ));
  }
  if (missingFragmentCount > 0) {
    clues.add(ArchiveClue(
      category: ArchiveClueCategory.skillFragment,
      title: UiStrings.zangjuangeClueFragmentTitle,
      summary: UiStrings.zangjuangeClueFragmentSummary(missingFragmentCount),
    ));
  }
  if (unbrokenBossCycleCount > 0) {
    clues.add(ArchiveClue(
      category: ArchiveClueCategory.bossCycle,
      title: UiStrings.zangjuangeClueBossCycleTitle,
      summary: UiStrings.zangjuangeClueBossCycleSummary(unbrokenBossCycleCount),
    ));
  }
  return clues;
}
```

Add the referenced strings to `UiStrings`.

- [ ] **Step 3: Run tests**

```bash
flutter test test/features/zangjuange/archive_clue_test.dart
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/zangjuange/application/zangjuange_providers.dart lib/shared/strings.dart test/features/zangjuange/archive_clue_test.dart
git commit -m "feat(zangjuange): derive first archive clues"
```

### Task 3: Hub Screen

**Files:**
- Create: `lib/features/zangjuange/presentation/zangjuange_screen.dart`
- Modify: `lib/shared/strings.dart`
- Create: `test/features/zangjuange/zangjuange_screen_test.dart`

- [ ] **Step 1: Write screen test**

Test that the hub renders four archive entries:

```dart
expect(find.text(UiStrings.zangjuangeTitle), findsOneWidget);
expect(find.text(UiStrings.mainMenuBattleRecord), findsOneWidget);
expect(find.text(UiStrings.mainMenuWeaponCodex), findsOneWidget);
expect(find.text(UiStrings.mainMenuBaike), findsOneWidget);
expect(find.text(UiStrings.mainMenuSkillLibrary), findsOneWidget);
```

Run:

```bash
flutter test test/features/zangjuange/zangjuange_screen_test.dart
```

Expected: FAIL because the screen does not exist.

- [ ] **Step 2: Implement `ZangjuangeScreen`**

Create a `ConsumerWidget` with:

- AppBar title `UiStrings.zangjuangeTitle`
- A top `PaperPanel` for clues
- Four `PlaqueButton` or existing ink buttons for 战绩册、兵器谱、奇遇录/百科、藏经阁
- Navigation to existing screens:
  - `BattleRecordScreen`
  - `WeaponCodexScreen`
  - `BaikeScreen`
  - `CangJingGeScreen(characterId: 1)`

- [ ] **Step 3: Run screen test**

```bash
flutter test test/features/zangjuange/zangjuange_screen_test.dart
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/zangjuange/presentation/zangjuange_screen.dart lib/shared/strings.dart test/features/zangjuange/zangjuange_screen_test.dart
git commit -m "feat(zangjuange): add archive hub screen"
```

### Task 4: Main Menu Entry

**Files:**
- Modify: `lib/features/main_menu/presentation/main_menu.dart`
- Modify: `test/features/main_menu/presentation/main_menu_test.dart`

- [ ] **Step 1: Add main menu expectation**

Add an assertion that 藏卷阁 appears after the social unlock condition or is hidden before unlock, matching the current hidden-entry pattern.

Run:

```bash
flutter test test/features/main_menu/presentation/main_menu_test.dart
```

Expected: FAIL before adding the entry.

- [ ] **Step 2: Add entry**

Import `ZangjuangeScreen` and add a `WuxiaInkButton` in the jianghu/archive section:

```dart
WuxiaInkButton(
  label: UiStrings.mainMenuZangjuange,
  hint: UiStrings.mainMenuZangjuangeHint,
  icon: Icons.library_books_outlined,
  thumbnailPath: WuxiaUi.entryCodex,
  onTap: () => _push(context, const ZangjuangeScreen()),
),
```

Use the same social lock behavior as 江湖/门派 if the UI would otherwise expose too many early entries.

- [ ] **Step 3: Run test**

```bash
flutter test test/features/main_menu/presentation/main_menu_test.dart
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/main_menu/presentation/main_menu.dart lib/shared/strings.dart test/features/main_menu/presentation/main_menu_test.dart
git commit -m "feat(zangjuange): expose archive hub from main menu"
```

### Task 5: Visual Route

**Files:**
- Modify: `lib/features/debug/application/visual_route.dart`
- Modify: `lib/features/debug/presentation/visual_route_host.dart`
- Modify: `test/features/debug/visual_route_test.dart`

- [ ] **Step 1: Add visual route test**

Add enum/parse coverage for `zangjuange`.

Run:

```bash
flutter test test/features/debug/visual_route_test.dart
```

Expected: FAIL before route exists.

- [ ] **Step 2: Add route**

Add route enum member and render `ZangjuangeScreen` in the host.

- [ ] **Step 3: Run route test**

```bash
flutter test test/features/debug/visual_route_test.dart
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/debug/application/visual_route.dart lib/features/debug/presentation/visual_route_host.dart test/features/debug/visual_route_test.dart
git commit -m "feat(debug): add zangjuange visual route"
```

### Task 6: Final Verification

- [ ] **Step 1: Targeted tests**

```bash
flutter test test/features/zangjuange test/features/main_menu/presentation/main_menu_test.dart test/features/debug/visual_route_test.dart
```

Expected: PASS.

- [ ] **Step 2: Analyze**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Commit final fixes if any**

```bash
git status --short
git add <changed-files>
git commit -m "chore(zangjuange): verify archive hub"
```

## Self-Review

- Spec coverage: covers 藏卷阁 Hub, archive aggregation, and first three clue categories.
- Placeholders: no task says to invent later behavior; all first-slice behavior is defined.
- Type consistency: `ArchiveClue`, `ArchiveClueCategory`, and `ArchiveClueTargetKind` are introduced before use.
