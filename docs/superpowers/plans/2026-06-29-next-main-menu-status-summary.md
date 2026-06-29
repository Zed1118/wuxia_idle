# Main Menu Status Summary Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在主菜单标题下方显示 3-5 个当前最重要的只读状态：闭关中、桃花岛可收、伤势待处理、主线目标/卡点、修为已满可查看突破瓶颈。

**Architecture:** 新增本分支内的窄接口 `mainMenuStatusSummaryProvider`，从现有 provider / SaveData 快照派生摘要，不调用桃花岛 settle、不改闭关/战斗/经验结算。展示层新增 `MainMenuStatusSummaryPanel`，点击条目只导航到既有页面。

**Tech Stack:** Flutter Desktop, Riverpod 3.x, Isar snapshot reads, existing `UiStrings`, existing Wuxia visual tokens.

---

## 文件结构

- Create: `lib/features/main_menu/application/main_menu_status_summary_provider.dart`
  - 定义摘要 item kind / route / 文案派生 provider。
  - 只读 `activeRetreatSessionProvider`、`mainlineProgressProvider`、`activeCharacterIdsProvider`、`characterByIdProvider`、`SaveData.islandBuildings`。
- Create: `lib/features/main_menu/presentation/main_menu_status_summary.dart`
  - 渲染最多 5 条摘要 chip/card。
  - 将 route 映射到已有 screen，不新增行为入口。
- Modify: `lib/features/main_menu/presentation/main_menu.dart`
  - 标题、节日 chip、tutorial banner 后接入摘要面板。
- Modify: `lib/shared/strings.dart`
  - 集中新增主菜单摘要 UI 文案。
- Create: `test/features/main_menu/main_menu_status_summary_test.dart`
  - provider 与 widget targeted tests。

## 验收标准

- [x] 主菜单最多显示 5 条摘要，优先级固定：闭关 > 桃花岛 > 伤势 > 修为已满 > 主线。
- [x] 无 active 闭关、无可收桃花岛库存、无伤势、无修为已满时，仍显示主线下一关；全通时显示主线已收束。
- [x] 桃花岛摘要只读 `SaveData.islandBuildings.stored.floor()`，不调用 `IslandSettleService.settle`。
- [x] 文案全部在 `UiStrings`，presentation/domain 不散写中文。
- [x] 不改收益、门槛、结算、saveVersion、schema、numbers.yaml。
- [x] targeted tests 通过，`flutter analyze` 通过。

## 任务切片

### Task 1: 只读摘要 provider

- [x] **Step 1: 新增 provider 和 value object**

Create `lib/features/main_menu/application/main_menu_status_summary_provider.dart`:

```dart
enum MainMenuStatusKind { retreat, island, injury, breakthrough, mainline }

enum MainMenuStatusRoute { retreat, island, character, mainline }

class MainMenuStatusSummaryItem {
  final MainMenuStatusKind kind;
  final MainMenuStatusRoute route;
  final String title;
  final String detail;
  const MainMenuStatusSummaryItem({
    required this.kind,
    required this.route,
    required this.title,
    required this.detail,
  });
}
```

- [x] **Step 2: 派生逻辑**

Implement `mainMenuStatusSummaryProvider` as `FutureProvider.autoDispose<List<MainMenuStatusSummaryItem>>`.

Rules:
- active retreat: use `activeRetreatSessionProvider`, map name from `GameRepository.instance.getSeclusionMap`.
- island: read `mainMenuSaveSnapshotProvider`; sum `islandBuildings.map((b) => b.stored.floor())`.
- injury: read active characters; count `injuryHoursRemaining > 0 || lightInjuryStacks > 0 || innerDemonResidueHoursRemaining > 0`.
- breakthrough: first active character with `experienceToNextLayer > 0 && experience >= experienceToNextLayer`.
- mainline: reuse `MainlineProgressService.availableStages` to find first available stage; fallback complete.
- cap list with `.take(5)`.

### Task 2: 摘要展示组件

- [x] **Step 1: 新增 widget**

Create `lib/features/main_menu/presentation/main_menu_status_summary.dart`.

Behavior:
- Loading/empty returns `SizedBox.shrink`.
- Data renders a constrained, responsive wrap of 3-5 rows/chips.
- Icons are mapped in presentation from `MainMenuStatusKind`.
- Tap maps route to existing pages: retreat map list / TaoHuaIslandScreen / CharacterPanelScreen / ChapterListScreen.

- [x] **Step 2: 接入主菜单**

Modify `main_menu.dart`:
- import new widget.
- insert `const MainMenuStatusSummaryPanel()` below `MainMenuRetreatBanner`.

### Task 3: 文案集中化

- [x] Add `UiStrings.mainMenuStatusSummaryTitle`, title/detail helpers for five statuses.
- [x] Avoid inline Chinese in new Dart files outside `strings.dart`.

### Task 4: Tests

- [x] Provider test: mixed fixture returns exactly 5 items in priority order.
- [x] Provider test: no urgent statuses falls back to next mainline stage.
- [x] Widget test: rendered panel shows title and item title/detail, tap triggers `Navigator.push`.

### Task 5: Verification and commit

- [x] Run targeted test:

```bash
flutter test --no-pub test/features/main_menu/main_menu_status_summary_test.dart
```

- [x] Run existing main menu targeted tests:

```bash
flutter test --no-pub test/features/main_menu/presentation/main_menu_test.dart test/features/main_menu/main_menu_retreat_banner_test.dart
```

- [x] Run analyzer:

```bash
flutter analyze
```

- [x] Commit:

```bash
git add docs/superpowers/plans/2026-06-29-next-main-menu-status-summary.md lib/features/main_menu lib/shared/strings.dart test/features/main_menu
git commit -m "主菜单增加状态摘要"
```

## 当前恢复点

- 状态:实现、验证、提交完成。
- 最后完成:新增只读摘要 provider、主菜单摘要面板、集中字符串与 targeted tests；接入主菜单标题区并提交。
- 下一步:等待主窗口复核/合并。
- 已跑验证:`flutter pub get`、`dart run build_runner build --delete-conflicting-outputs`、`flutter test --no-pub test/features/main_menu/main_menu_status_summary_test.dart`、`flutter test --no-pub test/features/main_menu/presentation/main_menu_test.dart test/features/main_menu/main_menu_retreat_banner_test.dart`、`flutter analyze`。
- 阻塞项:CodeGraph 未初始化，已改用定向文件读取；不阻塞实现。
