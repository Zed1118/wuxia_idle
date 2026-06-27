# Island Prep Advice Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Connect 藏卷阁 clues back into 桃花岛 by showing low-pressure整备建议 and adding an 岛务工程碑 first slice for long-term projects.

**Architecture:** Depend on the merged APIs from `codex/taohua-island-phase2-foundation` and `codex/zangjuange-hub-clues`. Keep advice as read-only view models; do not create daily tasks or new reward loops.

**Tech Stack:** Flutter Desktop, Riverpod 3, Isar, existing 桃花岛 and 藏卷阁 feature APIs.

---

## Recovery Point

- 2026-06-27: `codex/island-prep-advice-integration` 已合并 `codex/taohua-island-phase2-foundation` (`5a4dd839`) 与 `codex/zangjuange-hub-clues` (`5d1a97ec`)。
- 2026-06-27: Task 1-2 已完成，本地新增 `IslandPrepAdvice` 与 `IslandPrepAdviceService.fromClues`，`flutter test test/features/taohua_island/island_prep_advice_service_test.dart` 通过。当前下一步：Task 3，接入 `taohuaIslandViewProvider`。
- 2026-06-27: Task 3-4 已完成，`IslandView.prepAdvice` 从 `zangjuangeCluesProvider` 映射并在桃花岛顶部只读展示，`flutter test test/features/taohua_island/island_prep_advice_service_test.dart test/features/taohua_island/taohua_island_screen_test.dart` 通过。当前下一步：Task 5，岛务工程碑 read-only first slice。
- 2026-06-27: Task 5 已完成，岛务工程碑以只读 `PaperPanel` 渲染，不接 action/service/save；同一 targeted test 命令通过。当前下一步：Task 6，运行 `test/features/taohua_island`、`test/features/zangjuange`、`flutter analyze`，条件允许跑全量 `flutter test`。
- 2026-06-27: Task 3-4 质量审查反馈已修复：`islandPrepAdviceProvider` best-effort 降级为空建议；藏卷阁 Boss 周目线索改为只读查询现有进度行，不经 `getOrCreate` 写入缺失行。`flutter test test/features/taohua_island/island_prep_advice_service_test.dart test/features/taohua_island/taohua_island_screen_test.dart test/features/zangjuange` 通过。
- 2026-06-27: 最终审查反馈已修复：`_ProjectStelePanel` const lint 清零，并补 4 条建议只渲染前三条的 widget test。`flutter test test/features/taohua_island/taohua_island_screen_test.dart` 与 `flutter analyze` 通过。

---

## Branch

Start this branch only after the first two branches are merged:

```bash
git switch main
git pull --ff-only
git switch -c codex/island-prep-advice-integration
```

## Files

- Create: `lib/features/taohua_island/domain/island_prep_advice.dart`
- Create: `lib/features/taohua_island/application/island_prep_advice_service.dart`
- Modify: `lib/features/taohua_island/application/island_providers.dart`
- Modify: `lib/features/taohua_island/presentation/taohua_island_screen.dart`
- Modify: `lib/shared/strings.dart`
- Modify: `lib/features/taohua_island/presentation/taohua_island_screen.dart` for 岛务工程碑 first slice. Prefer a read-only panel over a `BuildingType` unless implementation needs persistent building state.
- Test: `test/features/taohua_island/island_prep_advice_service_test.dart`
- Test: `test/features/taohua_island/taohua_island_screen_test.dart`

## Tasks

### Task 1: Prep Advice Domain

**Files:**
- Create: `lib/features/taohua_island/domain/island_prep_advice.dart`
- Create: `test/features/taohua_island/island_prep_advice_service_test.dart`

- [ ] **Step 1: Write failing domain test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_prep_advice.dart';

void main() {
  test('prep advice carries severity and source clue', () {
    const advice = IslandPrepAdvice(
      kind: IslandPrepAdviceKind.bossCycle,
      title: '备破招',
      body: '此 Boss 常以真气蓄势，建议整备破招材料。',
      sourceId: 'boss:stage_05_05#cycle2',
      priority: IslandPrepAdvicePriority.high,
    );

    expect(advice.kind, IslandPrepAdviceKind.bossCycle);
    expect(advice.priority, IslandPrepAdvicePriority.high);
  });
}
```

Run:

```bash
flutter test test/features/taohua_island/island_prep_advice_service_test.dart
```

Expected: FAIL because `IslandPrepAdvice` does not exist.

- [ ] **Step 2: Create domain model**

```dart
enum IslandPrepAdviceKind { equipment, skillFragment, bossCycle }

enum IslandPrepAdvicePriority { normal, high }

class IslandPrepAdvice {
  final IslandPrepAdviceKind kind;
  final String title;
  final String body;
  final String? sourceId;
  final IslandPrepAdvicePriority priority;

  const IslandPrepAdvice({
    required this.kind,
    required this.title,
    required this.body,
    this.sourceId,
    this.priority = IslandPrepAdvicePriority.normal,
  });
}
```

- [ ] **Step 3: Run test**

```bash
flutter test test/features/taohua_island/island_prep_advice_service_test.dart
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/taohua_island/domain/island_prep_advice.dart test/features/taohua_island/island_prep_advice_service_test.dart
git commit -m "feat(island): add prep advice model"
```

### Task 2: Map Archive Clues To Advice

**Files:**
- Create: `lib/features/taohua_island/application/island_prep_advice_service.dart`
- Modify: `test/features/taohua_island/island_prep_advice_service_test.dart`

- [ ] **Step 1: Write mapping tests**

```dart
test('equipment clue maps to equipment prep advice', () {
  const clue = ArchiveClue(
    category: ArchiveClueCategory.equipment,
    title: '兵器缺口',
    summary: '某件兵器尚未收录。',
  );

  final advice = IslandPrepAdviceService.fromClues([clue]);

  expect(advice.single.kind, IslandPrepAdviceKind.equipment);
  expect(advice.single.title, UiStrings.islandPrepEquipmentTitle);
});
```

Run:

```bash
flutter test test/features/taohua_island/island_prep_advice_service_test.dart
```

Expected: FAIL because the service does not exist.

- [ ] **Step 2: Implement service**

```dart
class IslandPrepAdviceService {
  const IslandPrepAdviceService._();

  static List<IslandPrepAdvice> fromClues(List<ArchiveClue> clues) {
    return [
      for (final clue in clues)
        switch (clue.category) {
          ArchiveClueCategory.equipment => IslandPrepAdvice(
              kind: IslandPrepAdviceKind.equipment,
              title: UiStrings.islandPrepEquipmentTitle,
              body: UiStrings.islandPrepEquipmentBody,
              sourceId: clue.targetId,
            ),
          ArchiveClueCategory.skillFragment => IslandPrepAdvice(
              kind: IslandPrepAdviceKind.skillFragment,
              title: UiStrings.islandPrepFragmentTitle,
              body: UiStrings.islandPrepFragmentBody,
              sourceId: clue.targetId,
            ),
          ArchiveClueCategory.bossCycle => IslandPrepAdvice(
              kind: IslandPrepAdviceKind.bossCycle,
              title: UiStrings.islandPrepBossCycleTitle,
              body: UiStrings.islandPrepBossCycleBody,
              sourceId: clue.targetId,
              priority: IslandPrepAdvicePriority.high,
            ),
        },
    ];
  }
}
```

Add all referenced strings to `UiStrings`.

- [ ] **Step 3: Run tests**

```bash
flutter test test/features/taohua_island/island_prep_advice_service_test.dart
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/taohua_island/application/island_prep_advice_service.dart lib/shared/strings.dart test/features/taohua_island/island_prep_advice_service_test.dart
git commit -m "feat(island): map archive clues to prep advice"
```

### Task 3: Provider Integration

**Files:**
- Modify: `lib/features/taohua_island/application/island_providers.dart`
- Modify: `test/features/taohua_island/island_prep_advice_service_test.dart`

- [ ] **Step 1: Inspect existing island view provider**

Run:

```bash
sed -n '1,260p' lib/features/taohua_island/application/island_providers.dart
```

Expected: find the island view model type and provider that backs `TaohuaIslandScreen`.

- [ ] **Step 2: Extend view model**

Add a field:

```dart
final List<IslandPrepAdvice> prepAdvice;
```

Default it to `const []` in tests/fakes.

- [ ] **Step 3: Wire from 藏卷阁 clues**

Inside the provider, read the clue provider from `zangjuange_providers.dart`, then:

```dart
final advice = IslandPrepAdviceService.fromClues(clues);
```

Pass it into the island view model.

- [ ] **Step 4: Run targeted provider tests**

```bash
flutter test test/features/taohua_island/island_prep_advice_service_test.dart test/features/taohua_island/taohua_island_screen_test.dart
```

Expected: PASS after fakes are updated.

- [ ] **Step 5: Commit**

```bash
git add lib/features/taohua_island/application/island_providers.dart test/features/taohua_island/island_prep_advice_service_test.dart test/features/taohua_island/taohua_island_screen_test.dart
git commit -m "feat(island): expose prep advice in island view"
```

### Task 4: Render Advice Panel

**Files:**
- Modify: `lib/features/taohua_island/presentation/taohua_island_screen.dart`
- Modify: `test/features/taohua_island/taohua_island_screen_test.dart`

- [ ] **Step 1: Add widget test**

Arrange an island view with one `IslandPrepAdvice` and assert:

```dart
expect(find.text(UiStrings.islandPrepSectionTitle), findsOneWidget);
expect(find.text(UiStrings.islandPrepBossCycleTitle), findsOneWidget);
```

Run:

```bash
flutter test test/features/taohua_island/taohua_island_screen_test.dart
```

Expected: FAIL before rendering is added.

- [ ] **Step 2: Render panel**

At the top of island body, render a compact `PaperPanel` only when advice is non-empty:

```dart
if (view.prepAdvice.isNotEmpty)
  _PrepAdvicePanel(advice: view.prepAdvice.take(3).toList(growable: false)),
```

Keep it read-only. Do not add claim buttons or timers.

- [ ] **Step 3: Run widget test**

```bash
flutter test test/features/taohua_island/taohua_island_screen_test.dart
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/taohua_island/presentation/taohua_island_screen.dart test/features/taohua_island/taohua_island_screen_test.dart
git commit -m "feat(island): show prep advice on taohua island"
```

### Task 5: 岛务工程碑 First Slice

**Files:**
- Modify: `lib/features/taohua_island/presentation/taohua_island_screen.dart`
- Modify: `lib/shared/strings.dart`
- Modify: `test/features/taohua_island/taohua_island_screen_test.dart`

- [ ] **Step 1: Add widget test**

Assert the first-slice panel appears:

```dart
expect(find.text(UiStrings.islandProjectSteleTitle), findsOneWidget);
expect(find.text(UiStrings.islandProjectSteleLockedLine), findsOneWidget);
```

Run:

```bash
flutter test test/features/taohua_island/taohua_island_screen_test.dart
```

Expected: FAIL until the panel exists.

- [ ] **Step 2: Add read-only panel**

Add centralized strings:

```dart
static const islandProjectSteleTitle = '岛务工程碑';
static const islandProjectSteleLockedLine = '长期工程尚在筹备，只记录此番整备方向。';
```

Render a read-only `PaperPanel` after prep advice and before building groups. It must not consume resources or mutate save data.

- [ ] **Step 3: Run test**

```bash
flutter test test/features/taohua_island/taohua_island_screen_test.dart
```

Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/features/taohua_island/presentation/taohua_island_screen.dart lib/shared/strings.dart test/features/taohua_island/taohua_island_screen_test.dart
git commit -m "feat(island): add island project stele first slice"
```

### Task 6: Final Verification

- [ ] **Step 1: Targeted tests**

```bash
flutter test test/features/taohua_island test/features/zangjuange
```

Expected: PASS.

- [ ] **Step 2: Analyze**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Full test before merge**

```bash
flutter test
```

Expected: PASS with current baseline.

- [ ] **Step 4: Commit final fixes if any**

```bash
git status --short
git add <changed-files>
git commit -m "chore(island): verify prep advice integration"
```

## Self-Review

- Spec coverage: covers 桃花岛整备建议, 藏卷阁线索联动, and 岛务工程碑 first slice.
- Placeholders: implementation explicitly avoids resource-consuming engineering projects in this branch; first slice is defined as read-only.
- Type consistency: depends on `ArchiveClue` from the 藏卷阁 branch and introduces `IslandPrepAdvice` before provider/UI usage.
