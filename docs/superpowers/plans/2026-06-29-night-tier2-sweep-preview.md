# 扫荡前收益预估 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 一键扫荡前显示本章预计主收益类型、可能掉落、熟练度方向和材料缺口命中，只提升决策可读性，不改变收益。

**Architecture:** 新增只读 domain service，从 `StageDef.dropTable`、`MainlineReplayRewardRoute`、`MaterialSourceLookupService`、`ItemUsageLookupService` 聚合预估信息。UI 只挂在主线章节扫荡入口，不碰 `SweepScreen` 结算和 `settleMainlineSweepVictory`。

**Tech Stack:** Flutter Desktop, Riverpod 3.x, Dart domain services, widget tests.

---

## File Structure

- Create: `lib/features/sweep/domain/sweep_reward_preview.dart`  
  聚合一章扫荡的主收益类型、可能掉落 item/equipment 数、熟练度方向、材料缺口命中。
- Modify: `lib/features/mainline/presentation/stage_list_screen.dart`  
  在 `_ChapterSweepButton` 的 eligible 状态下渲染紧凑预估行，并沿现有点击流程进入 `SweepScreen`。
- Modify: `lib/shared/strings.dart`  
  集中新增预估 UI 文案，避免 presentation 散写中文。
- Test: `test/features/sweep/domain/sweep_reward_preview_test.dart`  
  覆盖聚合逻辑、缺口命中和不依赖结算。
- Test: `test/features/mainline/presentation/stage_list_screen_test.dart`  
  覆盖扫荡按钮前出现收益预估，未 eligible 时不显示。
- Modify: `PROGRESS.md`  
  任务完成后登记分支、提交、验证和风险。

## Acceptance Criteria

- 主线整章 eligible 的一键扫荡入口显示：
  - 主收益类型：刷装备 / 刷材料 / 练熟练度，复用 `MainlineReplayRewardRoute`。
  - 可能掉落：来自章内 `dropTable` 的装备件数与物品名称。
  - 熟练度方向：来自技能书、残页、敌方蓄力技的方向摘要。
  - 材料缺口命中：本章会掉且 `ItemUsageLookupService` 判定有消费用途的材料，使用 `MaterialSourceLookupService` 反查确认本章确实是来源之一。
- 不改收益结算、不新增掉落、不做日课/体力/加速。
- 不做逐关「关卡掉落缺口标记」（已否方向），只做章级扫荡前总览。
- targeted tests 与 touched-file analyze 通过。

## Task 1: Plan And Domain Preview

**Files:**
- Create: `lib/features/sweep/domain/sweep_reward_preview.dart`
- Test: `test/features/sweep/domain/sweep_reward_preview_test.dart`

- [x] **Step 1: Write failing domain tests**

Create `test/features/sweep/domain/sweep_reward_preview_test.dart` with fixtures:

```dart
test('aggregates route kinds, possible drops, proficiency direction, material hits', () {
  final preview = SweepRewardPreview.fromMainlineStages(
    stages: [
      stage(
        dropTable: const [
          EquipmentDrop(equipmentDefId: 'eq_a', dropChance: 0.3),
          ItemDrop(inventoryItemDefId: 'item_mojianshi', quantityMin: 1, quantityMax: 2, dropChance: 1),
        ],
        dropSkillFragmentId: 'skill_frag_a',
        enemies: const [chargeEnemy],
      ),
    ],
    repo: FakeRepoWithMoJianShiUsageAndSource(),
  );

  expect(preview.primaryKinds, const [
    MainlineReplayRewardKind.equipment,
    MainlineReplayRewardKind.material,
    MainlineReplayRewardKind.proficiency,
  ]);
  expect(preview.equipmentDropCount, 1);
  expect(preview.possibleItemNames, contains('磨剑石'));
  expect(preview.proficiencyHints, contains(SweepProficiencyHint.skillFragment));
  expect(preview.materialHits.map((e) => e.itemId), contains('item_mojianshi'));
});
```

- [x] **Step 2: Run test to verify it fails**

Run: `flutter test --no-pub test/features/sweep/domain/sweep_reward_preview_test.dart`

Expected: FAIL because `sweep_reward_preview.dart` does not exist. Actual first run hit Flutter native-assets tool initialization crash before generated files existed; after `build_runner` generated providers, targeted tests exercised the new domain/UI code.

- [x] **Step 3: Implement preview service**

Implement:

```dart
class SweepRewardPreview {
  factory SweepRewardPreview.fromMainlineStages({
    required Iterable<StageDef> stages,
    required GameRepository repo,
  }) { ... }
}
```

Rules:
- Iterate stages once.
- Union `MainlineReplayRewardRoute.fromStage(stage).kinds` in stable order.
- Count unique equipment def ids from `EquipmentDrop`.
- Collect item display names from `repo.itemDefs[itemId]?.name ?? itemId`.
- Add proficiency hints for `dropSkillManualId`, `dropSkillFragmentId`, and enemies with `chargeSkillId`.
- Material hit = item in chapter drop table where usages are non-empty and material source includes a matching mainline stage id in the same chapter.

- [x] **Step 4: Run domain test**

Run: `flutter test --no-pub test/features/sweep/domain/sweep_reward_preview_test.dart`

Expected: PASS.

- [x] **Step 5: Commit domain slice**

Run:

```bash
git add docs/superpowers/plans/2026-06-29-night-tier2-sweep-preview.md lib/features/sweep/domain/sweep_reward_preview.dart test/features/sweep/domain/sweep_reward_preview_test.dart
git commit -m "feat: add sweep reward preview domain"
```

## Task 2: Mainline Sweep Entry UI

**Files:**
- Modify: `lib/shared/strings.dart`
- Modify: `lib/features/mainline/presentation/stage_list_screen.dart`
- Modify: `test/features/mainline/presentation/stage_list_screen_test.dart`

- [x] **Step 1: Write/extend widget tests**

Add expectations:

```dart
expect(find.text(UiStrings.sweepPreviewTitle), findsOneWidget);
expect(find.textContaining(UiStrings.stageReplayRouteEquipment), findsOneWidget);
expect(find.textContaining(UiStrings.sweepPreviewMaterialHitsPrefix), findsOneWidget);
```

Also assert locked current-cycle sweep state does not render preview.

- [x] **Step 2: Run widget test to verify it fails**

Run: `flutter test --no-pub test/features/mainline/presentation/stage_list_screen_test.dart`

Expected: FAIL because preview UI is not rendered.

- [x] **Step 3: Add strings and UI widget**

Add centralized strings:

```dart
static const String sweepPreviewTitle = '扫荡前预估';
static const String sweepPreviewDropsPrefix = '可能掉落';
static const String sweepPreviewProficiencyPrefix = '熟练度方向';
static const String sweepPreviewMaterialHitsPrefix = '命中缺口';
```

In `_ChapterSweepButton`, when `eligible == true`, build:

```dart
final preview = GameRepository.isLoaded
    ? SweepRewardPreview.fromMainlineStages(
        stages: entries.map((e) => e.def),
        repo: GameRepository.instance,
      )
    : null;
```

Render a compact panel above the button with primary chips and summary lines. Keep button behavior unchanged.

- [x] **Step 4: Run widget test**

Run: `flutter test --no-pub test/features/mainline/presentation/stage_list_screen_test.dart`

Expected: PASS.

- [x] **Step 5: Commit UI slice**

Run:

```bash
git add lib/shared/strings.dart lib/features/mainline/presentation/stage_list_screen.dart test/features/mainline/presentation/stage_list_screen_test.dart
git commit -m "feat: show preview before chapter sweep"
```

## Task 3: Verification And Recovery Point

**Files:**
- Modify: `PROGRESS.md`
- Modify: `docs/superpowers/plans/2026-06-29-night-tier2-sweep-preview.md`

- [x] **Step 1: Run targeted verification**

Run:

```bash
flutter test --no-pub test/features/sweep/domain/sweep_reward_preview_test.dart test/features/mainline/presentation/stage_list_screen_test.dart test/features/mainline/domain/mainline_replay_reward_route_test.dart test/features/inventory/material_source_lookup_service_test.dart test/features/inventory/item_usage_lookup_service_test.dart
dart analyze lib/features/sweep/domain/sweep_reward_preview.dart lib/features/mainline/presentation/stage_list_screen.dart lib/shared/strings.dart
```

Expected: tests PASS and analyze 0 issues.

- [x] **Step 2: Update recovery point**

Set current recovery point below to complete with final commit hash and verification output.

- [x] **Step 3: Commit docs/progress**

Run:

```bash
git add PROGRESS.md docs/superpowers/plans/2026-06-29-night-tier2-sweep-preview.md
git commit -m "docs: record sweep preview completion"
```

## Current Recovery Point

Status: complete.

Last completed: docs/progress closeout committed.

Next step: hand off branch for review/merge.

Verification run: `dart run build_runner build --delete-conflicting-outputs` PASS (flag ignored by current build_runner, 112 gitignored outputs); `flutter test --no-pub test/features/sweep/domain/sweep_reward_preview_test.dart test/features/mainline/presentation/stage_list_screen_test.dart test/features/mainline/domain/mainline_replay_reward_route_test.dart test/features/inventory/material_source_lookup_service_test.dart test/features/inventory/item_usage_lookup_service_test.dart` PASS, 26 tests; `flutter analyze lib/features/sweep/domain/sweep_reward_preview.dart lib/features/mainline/presentation/stage_list_screen.dart lib/shared/strings.dart` PASS, 0 issues.

Blocked: none.
