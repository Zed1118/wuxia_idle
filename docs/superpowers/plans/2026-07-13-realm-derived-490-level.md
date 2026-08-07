# Realm-Derived 490-Level Implementation Plan

> 📋 计划态存档 · 本文是实施前的计划,文中路径与文件名为**当时的规划意图**,以实际落地为准;`lib/` 路径的新旧对照见 `docs/PATH_MIGRATION_MAP.md`。

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** 将独立的角色 Lv 经验账退役，用现有 49 个境界层和唯一境界经验实时派生可见的 Lv1～Lv490。

**Architecture:** 新增无副作用的 `RealmProgressDisplay` 作为数字等级、进度和心魔封顶状态的唯一派生单元；`CharacterAdvancementService` 仍是唯一经验写入与境界推进服务，其结果附带派生等级前后快照供 UI 使用。保留 Isar `Character.level/levelExp` 字段但彻底退出生产读写，同时删除 `LevelService`/`LevelConfig` 及其属性加成。

**Tech Stack:** Flutter Desktop、Dart、Riverpod、Isar Community、YAML、flutter_test

**Workspace:** `/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/realm-derived-490-level`

**Branch / Baseline:** `codex/realm-derived-490-level` / `main@dd303f70`

**Approved Spec:** `docs/superpowers/specs/2026-07-13-realm-derived-490-level-design.md`

---

## File map

- `lib/features/cultivation/domain/realm_progress_display.dart`: 新建纯派生模型，只计算 Lv1～490、层内进度、待破境/已臻巅峰状态。
- `lib/features/cultivation/application/character_advancement_service.dart`: 继续独占经验写入，返回展示等级前后快照，守住心魔锁和终局边界。
- `lib/features/cultivation/presentation/advancement_summary.dart`: 把旧的独立 `LevelUpSummary` 收敛为同一修为进度反馈。
- `lib/features/character_panel/presentation/character_panel_screen.dart`: 用境界+派生等级+唯一经验替换旧 Lv chip。
- `lib/features/{mainline,tower,seclusion,inventory}/...`: 删除双写 `levelExp`，仅保留 `CharacterAdvancementService.applyExperience`。
- `lib/features/battle/domain/derived_stats.dart`: 删除旧 `Character.level` 的生命/内力/速度加成。
- `lib/data/numbers_config.dart` + `data/numbers.yaml`: 删除旧 `level` 配置，将武圣·登峰终局刻度改为 1,250,000。
- `lib/core/domain/character.dart`: 仅修订兼容字段注释，不删字段、不改 schema/saveVersion。
- `lib/data/isar_setup.dart`: 退役旧 Lv 启动修复链，不新增 schema 迁移。
- `lib/features/debug/application/redline_audit.dart`: 极值探针不再伪造旧 Lv100，仍直接验证当前真实战力红线。

### Task 1: 建立 Lv1～Lv490 纯派生模型

**Files:**
- Create: `lib/features/cultivation/domain/realm_progress_display.dart`
- Create: `test/features/cultivation/domain/realm_progress_display_test.dart`

- [x] **Step 1: Write the failing boundary tests**

```dart
void main() {
  RealmProgressDisplay display({
    required int absoluteLevel,
    required int experience,
    required int experienceToNext,
    required bool hasNextRealmLayer,
  }) => RealmProgressDisplay.fromSnapshot(
    absoluteRealmLevel: absoluteLevel,
    experience: experience,
    experienceToNext: experienceToNext,
    hasNextRealmLayer: hasNextRealmLayer,
  );

  test('first realm starts at Lv1 and advances by ten segments', () {
    expect(display(absoluteLevel: 1, experience: 0,
      experienceToNext: 1000, hasNextRealmLayer: true).level, 1);
    expect(display(absoluteLevel: 1, experience: 500,
      experienceToNext: 1000, hasNextRealmLayer: true).level, 6);
    expect(display(absoluteLevel: 1, experience: 999,
      experienceToNext: 1000, hasNextRealmLayer: true).level, 10);
  });

  test('locked overflow stays at the tenth level and preserves real exp', () {
    final value = display(absoluteLevel: 42, experience: 1800,
      experienceToNext: 1200, hasNextRealmLayer: true);
    expect(value.level, 420);
    expect(value.state, RealmProgressDisplayState.waitingForBreakthrough);
    expect(value.experience, 1800);
    expect(value.progress, 1.0);
  });

  test('final realm advances from Lv481 to Lv490 without Lv491', () {
    expect(display(absoluteLevel: 49, experience: 0,
      experienceToNext: 1250000, hasNextRealmLayer: false).level, 481);
    final peak = display(absoluteLevel: 49, experience: 1250000,
      experienceToNext: 1250000, hasNextRealmLayer: false);
    expect(peak.level, 490);
    expect(peak.state, RealmProgressDisplayState.peak);
    expect(display(absoluteLevel: 49, experience: 9999999,
      experienceToNext: 1250000, hasNextRealmLayer: false).level, 490);
  });

  test('defensive inputs never produce Lv0 or Lv491', () {
    expect(display(absoluteLevel: -1, experience: -5,
      experienceToNext: 0, hasNextRealmLayer: true).level, 1);
    expect(display(absoluteLevel: 99, experience: 999,
      experienceToNext: 0, hasNextRealmLayer: false).level, 490);
  });
}
```

- [x] **Step 2: Run the new test and verify RED**

Run: `flutter test --no-pub test/features/cultivation/domain/realm_progress_display_test.dart`

Expected: FAIL because `RealmProgressDisplay` does not exist.

- [x] **Step 3: Implement the pure model**

```dart
import 'dart:math' as math;

enum RealmProgressDisplayState { progressing, waitingForBreakthrough, peak }

final class RealmProgressDisplay {
  const RealmProgressDisplay({
    required this.level,
    required this.experience,
    required this.experienceToNext,
    required this.progress,
    required this.state,
  });

  final int level;
  final int experience;
  final int experienceToNext;
  final double progress;
  final RealmProgressDisplayState state;

  bool get didReachPeak => state == RealmProgressDisplayState.peak;
  bool get isWaitingForBreakthrough =>
      state == RealmProgressDisplayState.waitingForBreakthrough;

  factory RealmProgressDisplay.fromSnapshot({
    required int absoluteRealmLevel,
    required int experience,
    required int experienceToNext,
    required bool hasNextRealmLayer,
  }) {
    final safeAbsolute = absoluteRealmLevel.clamp(1, 49).toInt();
    final safeExperience = math.max(0, experience).toInt();
    final safeThreshold = math.max(0, experienceToNext).toInt();
    final segment = safeThreshold > 0
        ? (safeExperience * 10 ~/ safeThreshold).clamp(0, 9).toInt()
        : (hasNextRealmLayer ? 0 : 9);
    final atThreshold = safeThreshold > 0 && safeExperience >= safeThreshold;
    final state = !hasNextRealmLayer && atThreshold
        ? RealmProgressDisplayState.peak
        : hasNextRealmLayer && atThreshold
        ? RealmProgressDisplayState.waitingForBreakthrough
        : RealmProgressDisplayState.progressing;
    return RealmProgressDisplay(
      level: ((safeAbsolute - 1) * 10 + segment + 1)
          .clamp(1, 490)
          .toInt(),
      experience: safeExperience,
      experienceToNext: safeThreshold,
      progress: safeThreshold > 0
          ? (safeExperience / safeThreshold).clamp(0.0, 1.0).toDouble()
          : (hasNextRealmLayer ? 0.0 : 1.0),
      state: state,
    );
  }
}

final class RealmProgressChange {
  const RealmProgressChange({required this.before, required this.after});
  final RealmProgressDisplay before;
  final RealmProgressDisplay after;
  bool get didLevelUp => after.level > before.level;
}
```

- [x] **Step 4: Run tests and format**

Run: `dart format lib/features/cultivation/domain/realm_progress_display.dart test/features/cultivation/domain/realm_progress_display_test.dart && flutter test --no-pub test/features/cultivation/domain/realm_progress_display_test.dart`

Expected: all new tests PASS.

- [x] **Step 5: Commit**

```bash
git add lib/features/cultivation/domain/realm_progress_display.dart test/features/cultivation/domain/realm_progress_display_test.dart
git commit -m "feat: derive display levels from realm progress"
```

### Task 2: 接入终局刻度与境界推进结果

**Files:**
- Modify: `data/numbers.yaml`
- Modify: `lib/features/cultivation/application/character_advancement_service.dart`
- Modify: `test/features/cultivation/application/character_advancement_service_test.dart`
- Modify: `test/data/defs/defs_test.dart`
- Modify: `test/data/game_repository_test.dart`

- [x] **Step 1: Write RED tests for terminal progress and result snapshots**

Add to `character_advancement_service_test.dart`:

```dart
test('wuSheng dengFeng uses terminal scale but never enters layer 50', () {
  final ch = _mkChar(
    tier: RealmTier.wuSheng,
    layer: RealmLayer.dengFeng,
    experienceToNextLayer: 1250000,
  );
  final result = CharacterAdvancementService.applyExperience(
    ch,
    1250000,
    realmLookup: _realmLookup,
  );
  expect(ch.realmTier, RealmTier.wuSheng);
  expect(ch.realmLayer, RealmLayer.dengFeng);
  expect(ch.experience, 1250000);
  expect(result.layersGained, 0);
  expect(result.progressChange.before.level, 481);
  expect(result.progressChange.after.level, 490);
});

test('locked realm preserves overflow and caps display level', () {
  final ch = _mkChar(experienceToNextLayer: 50);
  final result = CharacterAdvancementService.applyExperience(
    ch,
    80,
    realmLookup: _realmLookup,
    isLayerLocked: (_, _) => true,
  );
  expect(ch.experience, 80);
  expect(result.progressChange.after.isWaitingForBreakthrough, isTrue);
  expect(result.progressChange.after.level, 10);
});
```

Add production-data assertions to `game_repository_test.dart`:

```dart
final finalRealm = repo.getRealm(RealmTier.wuSheng, RealmLayer.dengFeng);
expect(finalRealm.absoluteLevel, 49);
expect(finalRealm.experienceToNext, 1250000);
```

- [x] **Step 2: Run tests and verify RED**

Run: `flutter test --no-pub test/features/cultivation/application/character_advancement_service_test.dart test/data/defs/defs_test.dart test/data/game_repository_test.dart`

Expected: FAIL because the final YAML threshold is `0` and `AdvancementResult` has no `progressChange`.

- [x] **Step 3: Change the terminal config and capture before/after displays**

Change only the final realm row:

```yaml
- layer: dengFeng
  absolute_level: 49
  internal_force_max: 15000
  experience_to_next: 1250000  # 终局修为刻度，不产生第 50 层
```

In `applyExperience`, derive the current display from `realmLookup` before the existing `delta <= 0` return. Preserve that return as a true no-op. Immediately after it, synchronize the stored threshold so old final-realm saves whose stored threshold is `0` use the new scale on their next positive gain:

```dart
final beforeDef = realmLookup(ch.realmTier, ch.realmLayer);
final progressBefore = RealmProgressDisplay.fromSnapshot(
  absoluteRealmLevel: beforeDef.absoluteLevel,
  experience: ch.experience,
  experienceToNext: beforeDef.experienceToNext,
  hasNextRealmLayer: nextLayer(ch.realmTier, ch.realmLayer) != null,
);
if (delta <= 0) {
  return AdvancementResult(
    layersGained: 0,
    tierBefore: tierBefore,
    layerBefore: layerBefore,
    tierAfter: tierBefore,
    layerAfter: layerBefore,
    internalForceMaxBefore: maxBefore,
    internalForceMaxAfter: maxBefore,
    experienceGained: 0,
    progressChange: RealmProgressChange(
      before: progressBefore,
      after: progressBefore,
    ),
  );
}
ch.experienceToNextLayer = beforeDef.experienceToNext;
```

After the loop, use the final `RealmDef` to create `progressAfter`. Add both `RealmProgressChange progressChange` and `int experienceGained` as required `AdvancementResult` fields; positive calls report the input reward and the no-op return reports zero:

```dart
final afterDef = realmLookup(ch.realmTier, ch.realmLayer);
final progressAfter = RealmProgressDisplay.fromSnapshot(
  absoluteRealmLevel: afterDef.absoluteLevel,
  experience: ch.experience,
  experienceToNext: afterDef.experienceToNext,
  hasNextRealmLayer: nextLayer(ch.realmTier, ch.realmLayer) != null,
);

progressChange: RealmProgressChange(
  before: progressBefore,
  after: progressAfter,
),
experienceGained: delta,
```

Keep `nextLayer(wuSheng, dengFeng) == null`; the while-loop must break before deducting terminal experience.

- [x] **Step 4: Run the focused tests**

Run: `flutter test --no-pub test/features/cultivation/domain/realm_progress_display_test.dart test/features/cultivation/application/character_advancement_service_test.dart test/data/defs/defs_test.dart test/data/game_repository_test.dart`

Expected: PASS, including Lv490 and no-layer-50 assertions.

- [x] **Step 5: Commit**

```bash
git add data/numbers.yaml lib/features/cultivation/application/character_advancement_service.dart test/features/cultivation/application/character_advancement_service_test.dart test/data/defs/defs_test.dart test/data/game_repository_test.dart
git commit -m "feat: add terminal realm progress scale"
```

### Task 3: 主线与爬塔只写唯一经验账

**Files:**
- Modify: `lib/features/mainline/presentation/stage_entry_flow.dart`
- Modify: `lib/features/tower/presentation/tower_entry_flow.dart`
- Modify: `lib/features/cultivation/presentation/advancement_summary.dart`
- Modify: `lib/features/mainline/presentation/stage_victory_dialog.dart`
- Modify: `lib/features/debug/presentation/visual_route_host.dart`
- Modify: `lib/shared/strings.dart`
- Delete: `test/features/cultivation/level_up_summary_test.dart`
- Modify: `test/features/cultivation/presentation/advancement_summary_test.dart`
- Modify: `test/features/mainline/presentation/stage_victory_dialog_test.dart`
- Modify: relevant tower tests under `test/features/tower/`
- Modify: `test/features/sweep/application/sweep_settlement_test.dart`

- [x] **Step 1: Write RED contracts for single-write settlement and unified feedback**

Add widget cases using an `AdvancementResult` whose `progressChange` is Lv186→Lv187:

```dart
testWidgets('derived level change renders inside cultivation summary', (tester) async {
  await _pump(tester, [AdvancementEntry(chName: '甲', result: levelOnlyResult())]);
  expect(find.text(UiStrings.cultivationLevelChanged('甲', 186, 187)), findsOneWidget);
  expect(find.textContaining('晋 ·'), findsNothing);
});

testWidgets('experience without a display level change shows gain only', (tester) async {
  await _pump(tester, [AdvancementEntry(chName: '甲', result: expOnlyResult(50))]);
  expect(find.text(UiStrings.cultivationExperienceGained('甲', 50)), findsOneWidget);
  expect(find.textContaining('→ Lv'), findsNothing);
});

testWidgets('realm and level change share one experience section', (tester) async {
  await _pumpContent(tester, _emptyDrops(), [
    AdvancementEntry(chName: '甲', result: crossedRealmResult()),
  ]);
  expect(find.text(UiStrings.stageVictoryExperienceSection), findsOneWidget);
  expect(find.textContaining('Lv190 → Lv191'), findsOneWidget);
  expect(find.textContaining('境界精进至'), findsOneWidget);
});
```

Add source/behavior assertions in the existing mainline and tower settlement tests:

```dart
expect(saved.experience, expectedRealmExperience);
expect(saved.level, legacyLevelBefore);
expect(saved.levelExp, legacyLevelExpBefore);
```

In `sweep_settlement_test.dart`, seed the same sentinels and assert mainline sweep
inherits the unified `applyVictoryResolution` path without touching them:

```dart
expect(saved.experience, greaterThan(experienceBefore));
expect(saved.level, 77);
expect(saved.levelExp, 4321);
```

- [x] **Step 2: Run focused tests and verify RED**

Run: `flutter test --no-pub test/features/cultivation/presentation/advancement_summary_test.dart test/features/mainline/presentation/stage_victory_dialog_test.dart test/features/tower test/features/sweep/application/sweep_settlement_test.dart`

Expected: FAIL because the old paths still call `LevelService` and render `LevelUpSummary` separately.

- [x] **Step 3: Remove dual writes and collapse the UI model**

In both settlement loops, keep only:

```dart
final result = CharacterAdvancementService.applyExperience(
  character,
  experienceReward,
  realmLookup: GameRepository.instance.getRealm,
  isLayerLocked: layerLock,
);
advancements.add(AdvancementEntry(chName: character.name, result: result));
```

Delete `AdvancementEntry.levelUp`, `LevelUpResult`, and `LevelUpSummary` dependencies. `AdvancementSummary` now keeps entries with `experienceGained > 0` and selects exactly one row per character: realm+level change, level-only change, or experience-only. When realm also advances, append both facts to the same row using `UiStrings` methods:

```dart
static String cultivationLevelChanged(String name, int before, int after) =>
    '$name·修为等级 Lv$before → Lv$after';
static String cultivationExperienceGained(String name, int amount) =>
    '$name·修为经验 +$amount';
static String cultivationRealmAndLevelChanged(
  String name,
  int before,
  int after,
  String realm,
) => '$name·Lv$before → Lv$after·境界精进至$realm';
```

`StageVictoryContent` and tower victory content should test only:

```dart
final hasCultivationProgress = advancements.any(
  (entry) => entry.result.experienceGained > 0,
);
```

- [x] **Step 4: Run mainline/tower/cultivation tests**

Run: `flutter test --no-pub test/features/cultivation/presentation/advancement_summary_test.dart test/features/mainline test/features/tower test/features/sweep/application/sweep_settlement_test.dart`

Expected: PASS; no second Lv ceremony remains.

- [x] **Step 5: Commit**

```bash
git add lib/features/mainline lib/features/tower lib/features/cultivation/presentation/advancement_summary.dart lib/features/debug/presentation/visual_route_host.dart lib/shared/strings.dart test/features/cultivation test/features/mainline test/features/tower test/features/sweep/application/sweep_settlement_test.dart
git commit -m "refactor: unify combat cultivation feedback"
```

### Task 4: 闭关、离线与经验丹只写唯一经验账

**Files:**
- Modify: `lib/features/seclusion/application/seclusion_service.dart`
- Modify: `lib/features/seclusion/application/offline_passive_service.dart`
- Modify: `lib/features/inventory/application/item_use_service.dart`
- Modify: `lib/features/inventory/presentation/inventory_screen.dart`
- Modify: `test/features/seclusion/application/seclusion_service_test.dart`
- Modify: `test/features/seclusion/application/offline_passive_service_test.dart`
- Modify: `test/features/inventory/item_use_service_test.dart`
- Modify: `test/features/inventory/item_use_invalidation_test.dart`

- [x] **Step 1: Write RED tests proving legacy fields stay untouched**

Seed each character with unmistakable compatibility values before settlement:

```dart
character
  ..level = 77
  ..levelExp = 4321;
```

After closed retreat, offline settlement, and experience-pill use, assert:

```dart
expect(saved.experience, greaterThan(experienceBefore));
expect(saved.level, 77);
expect(saved.levelExp, 4321);
```

Add an old-final-save experience-pill case:

```dart
founder
  ..realmTier = RealmTier.wuSheng
  ..realmLayer = RealmLayer.dengFeng
  ..experienceToNextLayer = 0;
final result = await ItemUseService.use(
  isar,
  def: experiencePill,
  realmLookup: repo.getRealm,
);
expect(result.kind, ItemUseKind.experienceApplied);
expect((await isar.characters.get(founder.id))!.experience, greaterThan(0));
```

- [x] **Step 2: Run focused tests and verify RED**

Run: `flutter test --no-pub -j1 test/features/seclusion/application/seclusion_service_test.dart test/features/seclusion/application/offline_passive_service_test.dart test/features/inventory/item_use_service_test.dart test/features/inventory/item_use_invalidation_test.dart`

Expected: FAIL because current paths mutate `level/levelExp`; the old-final pill computes gain from stored zero.

- [x] **Step 3: Delete LevelService calls and fix pill scaling**

Remove every `LevelService.applyLevelExp` call and every `LevelConfig` parameter/import. For experience pills, calculate from the current realm definition instead of the potentially stale stored threshold:

```dart
final currentRealm = realmLookup(founder.realmTier, founder.realmLayer);
final gain = (currentRealm.experienceToNext * def.layerFraction!).round();
```

Call `CharacterAdvancementService.applyExperience` exactly once and consume the item only after a positive configured gain. The terminal `RealmDef.experienceToNext=1250000` makes old final-realm saves safe without a schema bump.

- [x] **Step 4: Run all affected tests**

Run: `flutter test --no-pub -j1 test/features/seclusion test/features/inventory`

Expected: PASS, including legacy-field sentinels and old-final-save pill behavior.

- [x] **Step 5: Commit**

```bash
git add lib/features/seclusion lib/features/inventory test/features/seclusion test/features/inventory
git commit -m "refactor: remove duplicate experience writes"
```

### Task 5: 退役 LevelService、LevelConfig 与旧等级战力

**Files:**
- Delete: `lib/features/level/application/level_service.dart`
- Delete: `lib/features/level/domain/level_config.dart`
- Delete: `test/features/level/level_service_test.dart`
- Modify: `lib/data/numbers_config.dart`
- Modify: `data/numbers.yaml`
- Modify: `lib/features/battle/domain/derived_stats.dart`
- Modify: `lib/features/debug/application/redline_audit.dart`
- Modify: `lib/shared/strings.dart`
- Delete: `test/combat/level_derived_stats_test.dart`
- Create: `test/combat/legacy_level_stats_independence_test.dart`
- Modify: `test/balance/maxhp_extremum_redline_test.dart`
- Modify: `test/features/equipment/application/enhancement_service_test.dart`

- [x] **Step 1: Write RED tests for stat independence and config removal**

```dart
test('legacy level values do not affect combat stats', () {
  final low = character()..level = 1;
  final corrupt = character()..level = 1000000;
  expect(CharacterDerivedStats.maxHp(low, [], numbers),
      CharacterDerivedStats.maxHp(corrupt, [], numbers));
  expect(CharacterDerivedStats.internalForceMaxWithLineage(low, [], numbers),
      CharacterDerivedStats.internalForceMaxWithLineage(corrupt, [], numbers));
  expect(CharacterDerivedStats.speed(low, [], technique, numbers),
      CharacterDerivedStats.speed(corrupt, [], technique, numbers));
});
```

Add a raw-config contract:

```dart
final yaml = await File('data/numbers.yaml').readAsString();
expect(yaml, isNot(contains('\nlevel:\n')));
expect(yaml, isNot(contains('bonus_max_hp_per_level')));
```

Keep the existing enhancement cap assertions and add a named guard that the realm
absolute level, not display Lv490 or legacy `Character.level`, remains the input:

```dart
test('display Lv490 does not raise the hard enhancement cap above 49', () {
  final equipment = newEq(enhanceLevel: 49);
  final result = EnhancementService.tryEnhance(
    eq: equipment,
    characterAbsoluteLevel: 490,
    rng: rngFixed(0.0),
    currentMojianshi: 999999,
    config: cfg,
  );
  expect(result.outcome, EnhanceOutcome.capped);
  expect(equipment.enhanceLevel, 49);
});
```

- [x] **Step 2: Run tests and verify RED**

Run: `flutter test --no-pub test/combat/legacy_level_stats_independence_test.dart test/balance/maxhp_extremum_redline_test.dart test/features/equipment/application/enhancement_service_test.dart`

Expected: FAIL because derived stats still read `Character.level` and `numbers.level`.

- [x] **Step 3: Remove the independent system**

Delete the `level` field/import/constructor argument/parser call from `NumbersConfig`; remove the complete top-level `level:` YAML section. Delete these three terms from derived-stat formulas:

```dart
((c.level < 1 ? 1 : c.level) - 1) * n.level.bonusMaxHpPerLevel
((c.level < 1 ? 1 : c.level) - 1) * n.level.bonusSpeedPerLevel
((c.level < 1 ? 1 : c.level) - 1) * n.level.bonusInternalForceMaxPerLevel
```

In `redline_audit.dart`, stop assigning a synthetic level and update redline notes to describe the actual full realm/build probe rather than Lv100. Preserve all existing hard limits.

- [x] **Step 4: Run stat, redline, and config tests**

Run: `flutter test --no-pub test/combat test/balance/maxhp_extremum_redline_test.dart test/data/numbers_config_red_lines_test.dart test/features/debug test/features/equipment/application/enhancement_service_test.dart`

Expected: PASS with no production dependency on `LevelConfig`.

- [x] **Step 5: Commit**

```bash
git add lib/features/level lib/data/numbers_config.dart data/numbers.yaml lib/features/battle/domain/derived_stats.dart lib/features/debug/application/redline_audit.dart lib/shared/strings.dart test/features/level test/combat test/balance/maxhp_extremum_redline_test.dart test/features/equipment/application/enhancement_service_test.dart
git commit -m "refactor: retire independent level combat power"
```

### Task 6: 角色面板统一为修为等级卡

**Files:**
- Modify: `lib/features/character_panel/presentation/character_panel_screen.dart`
- Modify: `lib/shared/strings.dart`
- Modify: `test/features/character_panel/presentation/character_panel_screen_test.dart`

- [x] **Step 1: Replace the old Lv fixture test with three RED UI states**

```dart
testWidgets('profile derives level and exp from realm progress only', (tester) async {
  final character = fixture()
    ..realmTier = RealmTier.erLiu
    ..realmLayer = RealmLayer.yuanShu
    ..experience = 650
    ..experienceToNextLayer = 1200
    ..level = 99
    ..levelExp = 99999;
  await pumpPanel(tester, character);
  expect(find.textContaining('修为等级'), findsOneWidget);
  expect(find.textContaining('经验 650 / 1200'), findsOneWidget);
  expect(find.textContaining('Lv99'), findsNothing);
});

testWidgets('locked overflow shows waiting for inner demon', (tester) async {
  final character = lockedFixture(experience: 1800, threshold: 1200);
  await pumpPanel(tester, character);
  expect(find.text(UiStrings.profileWaitingForInnerDemon), findsOneWidget);
  expect(find.textContaining('1800 / 1200'), findsOneWidget);
});

testWidgets('terminal scale shows Lv490 peak', (tester) async {
  await pumpPanel(tester, finalRealmFixture(experience: 1250000));
  expect(find.textContaining('Lv490'), findsOneWidget);
  expect(find.text(UiStrings.profileCultivationPeak), findsOneWidget);
});
```

- [x] **Step 2: Run the panel test and verify RED**

Run: `flutter test --no-pub test/features/character_panel/presentation/character_panel_screen_test.dart`

Expected: FAIL because `_LevelChip` reads legacy fields.

- [x] **Step 3: Replace `_LevelChip` with `_CultivationProgressCard`**

Look up the current `RealmDef` through `GameRepository`, then derive:

```dart
final realmDef = GameRepository.instance.getRealm(
  character.realmTier,
  character.realmLayer,
);
final display = RealmProgressDisplay.fromSnapshot(
  absoluteRealmLevel: realmDef.absoluteLevel,
  experience: character.experience,
  experienceToNext: realmDef.experienceToNext,
  hasNextRealmLayer: CharacterAdvancementService.nextLayer(
    character.realmTier,
    character.realmLayer,
  ) != null,
);
```

Render `UiStrings.profileCultivationLevel(display.level)`, `EnumL10n.realm(...)`, real experience numerator/denominator, and a clamped progress bar. Use `profileWaitingForInnerDemon` for nonterminal overflow and `profileCultivationPeak` for final threshold completion. Keep text in `UiStrings`.

- [x] **Step 4: Run panel and viewport tests**

Run: `flutter test --no-pub test/features/character_panel/presentation/character_panel_screen_test.dart test/features/character_panel/presentation/character_panel_screen_edge_test.dart`

Expected: PASS at the existing 1280×720 and 1440×900 test viewports.

- [x] **Step 5: Commit**

```bash
git add lib/features/character_panel/presentation/character_panel_screen.dart lib/shared/strings.dart test/features/character_panel
git commit -m "feat: unify profile cultivation progress"
```

### Task 7: 锁死旧存档字段仅兼容、生产零读写

**Files:**
- Modify: `lib/core/domain/character.dart`
- Modify: `lib/data/isar_setup.dart`
- Delete: `test/data/character_level_repair_test.dart`
- Create: `test/data/legacy_level_schema_compatibility_test.dart`
- Create: `test/data/legacy_level_production_usage_contract_test.dart`

- [x] **Step 1: Write compatibility and production-usage RED tests**

Schema round-trip test:

```dart
test('legacy level fields still round-trip without affecting gameplay', () async {
  final character = fixture()
    ..level = -9223372036854775808
    ..levelExp = 777;
  await isar.writeTxn(() => isar.characters.put(character));
  final saved = await isar.characters.get(character.id);
  expect(saved!.level, -9223372036854775808);
  expect(saved.levelExp, 777);
});
```

Source contract scans the exact former character-level consumers and allows declarations/constructor compatibility in `character.dart`:

```dart
final forbidden = <String>[
  'LevelService',
  'LevelConfig',
  '.numbers.level',
  'levelExp',
  'c.level',
];
final formerConsumers = <File>[
  File('lib/features/mainline/presentation/stage_entry_flow.dart'),
  File('lib/features/tower/presentation/tower_entry_flow.dart'),
  File('lib/features/seclusion/application/seclusion_service.dart'),
  File('lib/features/seclusion/application/offline_passive_service.dart'),
  File('lib/features/inventory/application/item_use_service.dart'),
  File('lib/features/battle/domain/derived_stats.dart'),
  File('lib/features/character_panel/presentation/character_panel_screen.dart'),
  File('lib/data/numbers_config.dart'),
];
for (final file in formerConsumers) {
  final source = await file.readAsString();
  for (final token in forbidden) {
    expect(source, isNot(contains(token)), reason: '${file.path}: $token');
  }
}
```

- [x] **Step 2: Run tests and verify RED**

Run: `flutter test --no-pub -j1 test/data/legacy_level_schema_compatibility_test.dart test/data/legacy_level_production_usage_contract_test.dart`

Expected: FAIL while `repairCharacterLevels` and stale production references still exist.

- [x] **Step 3: Retire the startup repair and rewrite compatibility comments**

Remove the `repairCharacterLevels` invocation/method. Keep both Isar fields and constructor arguments, with this explicit contract:

```dart
/// Legacy schema compatibility only (saveVer 0.31).
/// Production progression, UI, combat stats, and unlocks must not read or write
/// these fields. Remove only in a future schema-cleanup migration.
int level = 1;
int levelExp = 0;
```

Do not bump `_currentSaveVersion`; this batch changes no collection schema.

- [x] **Step 4: Run compatibility, migration, and generated-schema tests**

Run: `flutter test --no-pub -j1 test/data/legacy_level_schema_compatibility_test.dart test/data/legacy_level_production_usage_contract_test.dart test/data/inner_force_qi_migration_test.dart test/data/isar_setup_test.dart`

Expected: PASS; old fields still deserialize, but no gameplay path consumes them.

- [x] **Step 5: Commit**

```bash
git add lib/core/domain/character.dart lib/data/isar_setup.dart test/data
git commit -m "refactor: isolate legacy level schema fields"
```

### Task 8: 文档、全量门禁与视觉验收

**Files:**
- Modify: `GDD.md`
- Modify: `CLAUDE.md`
- Modify: `PROGRESS.md`
- Modify: `docs/superpowers/specs/2026-07-13-realm-derived-490-level-design.md` only if implementation names differ from the approved spec
- Verify: all changed production/test/data files

- [x] **Step 1: Update the truth-source documentation**

Record these exact truths:

- `Character.experience` is the only writable character experience account.
- 49 realm layers × 10 display segments = Lv1～Lv490.
- final `wuSheng/dengFeng.experience_to_next=1,250,000` is a display scale, not layer 50.
- legacy `level/levelExp` remain schema-only.
- display Lv adds no stats and does not participate in equipment/technique locks or enhancement caps.
- mainline, tower, retreat, passive idle, and experience pills use the same advancement service.

- [x] **Step 2: Run structural scans**

Run:

```bash
rg -n "LevelService|LevelConfig|numbers\.level|levelExp|c\.level|character\.level" lib --glob '*.dart' --glob '!*.g.dart'
rg -n "^level:|bonus_max_hp_per_level|bonus_internal_force_max_per_level|bonus_speed_per_level" data/numbers.yaml
```

Expected: first command finds only schema-compatible `Character.level` declarations/constructor assignments where applicable; second command returns no matches.

- [x] **Step 3: Run targeted tests**

Run:

```bash
flutter test --no-pub -j1 \
  test/features/cultivation/domain/realm_progress_display_test.dart \
  test/features/cultivation/application/character_advancement_service_test.dart \
  test/features/cultivation/presentation/advancement_summary_test.dart \
  test/features/mainline \
  test/features/tower \
  test/features/sweep/application/sweep_settlement_test.dart \
  test/features/seclusion \
  test/features/inventory \
  test/features/character_panel \
  test/combat/legacy_level_stats_independence_test.dart \
  test/data/legacy_level_schema_compatibility_test.dart \
  test/data/legacy_level_production_usage_contract_test.dart
```

Expected: all focused suites PASS with 0 failures.

- [x] **Step 4: Run repository gates**

Run:

```bash
dart run build_runner build
dart format --output=none --set-exit-if-changed .
flutter analyze --no-pub
flutter test --no-pub
flutter build macos --debug
git diff --check
git status --short
```

Expected: 114 generated outputs; formatter 0 changed; analyzer 0 issues; full suite 0 failures; macOS debug build succeeds; diff check clean; status contains only this task's intended committed work.

- [x] **Step 5: Perform visual acceptance**

Use the existing `character_panel` and a deterministic final-realm debug fixture at both 1280×720 and 1440×900. Verify:

- one cultivation card only;
- `Lv1`, a mid-progress level, locked-overflow level 10 of its band, and `Lv490` text fit;
- real experience can exceed the denominator while the bar stays at 100%;
- no overflow, clipped text, default Material saturated blue, or duplicate experience bars.

- [x] **Step 6: Record the final recovery point and commit**

Append to this plan:

```markdown
## 当前恢复点（2026-07-13）

- **状态**：八个任务已完成，分支待评审/合并。
- **最后完成**：Lv1～Lv490 统一修为等级全量门禁与双视口验收。
- **下一步**：审核分支差异，确认后合入 `main`。
- **已跑验证**：填入本次真实 format/analyze/targeted/full/build/视觉结果。
- **阻塞项**：无，或写明具体外部阻塞。
```

Then:

```bash
git add CLAUDE.md GDD.md PROGRESS.md docs/superpowers/plans/2026-07-13-realm-derived-490-level.md docs/superpowers/specs/2026-07-13-realm-derived-490-level-design.md
git commit -m "docs: complete realm-derived level verification"
git commit --allow-empty -m "[READY] complete realm-derived 490-level batch"
```

## §8.2 acceptance checklist

- [x] `docs/spec/rejected_task_registry.md` 无命中禁做项。
- [x] `Character.experience` 是唯一生产可写角色经验账。
- [x] Lv1～Lv490 全边界、心魔锁溢出、终局 1,250,000 刻度有纯测试。
- [x] 武圣·登峰不会进入第 50 境界层，也不会显示 Lv491。
- [x] `Character.level/levelExp` 保留 Isar schema 兼容，生产读写为 0。
- [x] `LevelService` / `LevelConfig` / `numbers.yaml level` 已删除。
- [x] 数字等级不再增加生命、内力、速度或其他战力。
- [x] 装备阶、心法阶、强化上限和玩法解锁仍只读真实境界。
- [x] 主线、爬塔、闭关、离线和经验丹对旧 Lv 字段无双写。
- [x] 角色面板只显示一套修为等级/经验进度。
- [x] 旧终局存档的门槛 0 不会导致经验丹 0 收益。
- [x] 数值红线、三系锁死、在线=离线、反主流红线全部保持。
- [x] `dart format`、`flutter analyze`、targeted、full suite、macOS debug build、`git diff --check` 全绿。
- [x] 1280×720 与 1440×900 角色面板视觉验收通过。
- [x] 工作树仅包含本批文件，恢复点与小切片提交完整。

## 当前恢复点（2026-07-13）

- **状态**：八个任务已完成，分支待评审/合并。
- **最后完成**：Lv1～Lv490 统一修为等级全量门禁与双视口验收。
- **下一步**：审核分支差异，确认后合入 `main`。
- **已跑验证**：build_runner 增量 66 outputs；format 1103/0 changed；analyze 0；跨模块专项 593 pass / 0 fail；全量 3878 pass / 0 fail；macOS debug build 成功；角色面板 31 条测试含 Lv490 @1280×720/1440×900；结构扫描与 `git diff --check` 通过。
- **阻塞项**：无。
