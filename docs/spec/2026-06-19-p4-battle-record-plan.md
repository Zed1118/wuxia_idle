# P4 战绩册 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 Boss 首胜战斗的高光（战绩/英雄/掉落/阵容）永久收藏成一本「战绩册」，主菜单首胜后解锁、未击败 Boss 显剩影占位。

**Architecture:** 新建 `BossMemory` Isar collection（一档一 Boss 一条，~27 封顶）+ `BossMemoryService`（纯逻辑：首胜建 / 重打累加 / 老档回填）。victory 留档仿现有 `runDiscipleJoinHookAfterVictory` 在 `runStageFlow` caller 层后置调用，**不动 900 行结算函数内部**。展示走独立 feature `lib/features/battle_record/` 只读 provider。纯表现层，0 数值/0 伤害公式（守红线 §5.1/§5.4/§5.5/§5.6/§5.7）。

**Tech Stack:** Flutter Desktop / Riverpod 3 / Isar(isar_community) / build_runner codegen。

**设计依据:** `docs/spec/2026-06-19-p4-battle-record-design.md`。

**全局约束（每 task 必守）:**
- 数值进 numbers.yaml（本功能无新数值）、中文 UI 文案进 `UiStrings`、枚举显示名进 `EnumL10n`、叙事进 data/。Dart 代码不散写中文。
- 枚举/schema 改动后**必跑全量 `flutter test`**（scoped 漏跨文件回归，memory `feedback_subagent_implementer_full_analyze`）。
- schema 改动后**必跑 `dart run build_runner build --delete-conflicting-outputs`**（.g.dart gitignored）。
- 每 task 收尾 `flutter analyze`（0 issue）+ 跑相关测试贴输出。
- `flutter build/run -d macos` 禁加 `DEVELOPER_DIR=`；git 命令才用该前缀。

---

### Task 1: `BossMemorySource` 枚举 + EnumL10n 显示名

**Files:**
- Create: `lib/features/battle_record/domain/boss_memory_source.dart`
- Modify: `lib/features/battle/domain/enum_localizations.dart`（追加 switch 方法）
- Test: `test/features/battle/domain/enum_localizations_test.dart`（若存在则追加；否则在该目录新建）

- [ ] **Step 1: 写枚举**

```dart
// lib/features/battle_record/domain/boss_memory_source.dart
/// 战绩册 Boss 来源维度（分组用）。
enum BossMemorySource { mainline, tower }
```

- [ ] **Step 2: 写失败测试（EnumL10n 穷尽）**

```dart
// enum_localizations_test.dart 追加
import 'package:wuxia_idle/features/battle_record/domain/boss_memory_source.dart';

test('BossMemorySource 显示名穷尽', () {
  expect(EnumL10n.bossMemorySource(BossMemorySource.mainline), '主线征程');
  expect(EnumL10n.bossMemorySource(BossMemorySource.tower), '爬塔问鼎');
});
```

- [ ] **Step 3: 跑测试确认 FAIL**

Run: `flutter test test/features/battle/domain/enum_localizations_test.dart`
Expected: FAIL（`bossMemorySource` 未定义）

- [ ] **Step 4: 加 EnumL10n 方法**（照该文件现有 switch 穷尽体例，import 枚举）

```dart
static String bossMemorySource(BossMemorySource s) => switch (s) {
      BossMemorySource.mainline => '主线征程',
      BossMemorySource.tower => '爬塔问鼎',
    };
```

- [ ] **Step 5: 跑测试确认 PASS + analyze**

Run: `flutter test test/features/battle/domain/enum_localizations_test.dart && flutter analyze lib/features/battle_record/ lib/features/battle/domain/enum_localizations.dart`
Expected: PASS / No issues

- [ ] **Step 6: Commit**

```bash
git add lib/features/battle_record/domain/boss_memory_source.dart lib/features/battle/domain/enum_localizations.dart test/features/battle/domain/enum_localizations_test.dart
git commit -m "feat(battle_record): BossMemorySource 枚举 + EnumL10n 显示名"
```

---

### Task 2: `BossMemory` @collection + 注册 schema + saveVer bump

**Files:**
- Create: `lib/features/battle_record/domain/boss_memory.dart`
- Modify: `lib/data/isar_setup.dart`（`_allSchemas` 加 `BossMemorySchema`；`_currentSaveVersion` `0.25.0`→`0.26.0`；`_migrateSaveData` 末尾加注释段）

**参考样板:** `lib/features/tower/domain/tower_progress.dart`（`@collection` + `Id id = Isar.autoIncrement` + `late int saveDataId`）；enum 字段用 `@Enumerated(EnumType.name)`（见 `lib/core/domain/character.dart`）。

- [ ] **Step 1: 写 collection 类**

```dart
// lib/features/battle_record/domain/boss_memory.dart
import 'package:isar_community/isar.dart';
import '../../../core/domain/enums.dart'; // EquipmentTier 所在（实现时确认路径）
import 'boss_memory_source.dart';

part 'boss_memory.g.dart';

/// 一档一 Boss 一条「首胜纪念」。Boss-only，~27 封顶。纯展示数据，无数值语义。
@collection
class BossMemory {
  Id id = Isar.autoIncrement;

  late int saveDataId;

  /// 稳定键：主线=stageId / 爬塔=`tower_floor_<N>`。同档唯一。
  @Index()
  late String bossKey;

  @Enumerated(EnumType.name)
  late BossMemorySource source;

  /// 分组排序序号：主线由 stageId 派生 section 序（Ch1-6 前，心魔/轻功/群战各成 section 其后）/ 爬塔=层号。
  late int groupIndex;

  late String bossName;

  DateTime? firstClearedAt;

  /// 回填骨架标记（true=本功能上线前击败，战绩不详）。
  late bool isPreRecord;

  int? totalDamage;
  int? critCount;
  int? totalTicks;

  String? topContributorName;
  int? topContributorDamage;

  String? treasureName;
  @Enumerated(EnumType.name)
  EquipmentTier? treasureTier;

  List<String> rosterNames = [];
  List<String> rosterPortraits = [];

  /// 击败次数（重打累加，不覆盖首胜快照）。
  late int defeatCount;
}
```

- [ ] **Step 2: 注册 schema**（`lib/data/isar_setup.dart` `_allSchemas` 末尾，import BossMemory）

```dart
  // ...既有 schema 列表末尾
  BossMemorySchema,
```

- [ ] **Step 3: bump 版本号 + 迁移注释**

```dart
static const _currentSaveVersion = '0.26.0';
```
`_migrateSaveData` 函数末尾追加：
```dart
// 段(0.26.0 战绩册):新 BossMemory collection,旧档天然空(正确初始态)。
// 老档已击败 Boss 的回填骨架在 Task 4 由 BossMemoryService.backfillFromProgress 处理,
// 此处仅 bump 版本号,无 collection 操作。
```

- [ ] **Step 4: 生成 .g.dart + 编译验证**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter analyze lib/`
Expected: `boss_memory.g.dart` 生成 / No issues

- [ ] **Step 5: 全量 test 确认 0 回归**（schema 改动必跑全量）

Run: `flutter test`
Expected: 全绿（baseline +0，仅新增 collection 不动既有测）

- [ ] **Step 6: Commit**

```bash
git add lib/features/battle_record/domain/boss_memory.dart lib/features/battle_record/domain/boss_memory.g.dart lib/data/isar_setup.dart
git commit -m "feat(battle_record): BossMemory collection + 注册 + saveVer 0.26.0"
```

---

### Task 3: `BossMemoryService.recordBossVictory`（首胜建 / 重打累加 / 幂等）

**Files:**
- Create: `lib/features/battle_record/application/boss_memory_service.dart`
- Test: `test/features/battle_record/application/boss_memory_service_test.dart`

**输入约定:** service 纯逻辑，不依赖 Flutter。treasure 由调用方（hook）算好传 name+tier（service 不碰 pickTreasureHighlight）。

- [ ] **Step 1: 写失败测试**（Isar temp 样板照 `test/features/tower/application/tower_progress_service_test.dart` 的 setUpAll/setUp/tearDown）

```dart
// 关键断言：
test('首胜建完整纪念', () async {
  final svc = BossMemoryService(isar: IsarSetup.instance);
  await svc.recordBossVictory(
    saveDataId: IsarSetup.currentSlotId,
    bossKey: 'stage_01_05',
    source: BossMemorySource.mainline,
    groupIndex: 1,
    bossName: '撑伞高人',
    totalDamage: 18000, critCount: 5, totalTicks: 40,
    topContributorName: '祖师', topContributorDamage: 9000,
    treasureName: '天问剑', treasureTier: EquipmentTier.shenWu,
    rosterNames: ['祖师', '大弟子'], rosterPortraits: ['a.png', 'b.png'],
    now: DateTime(2026, 6, 19),
  );
  final all = await svc.allMemories(IsarSetup.currentSlotId);
  expect(all, hasLength(1));
  expect(all.first.bossName, '撑伞高人');
  expect(all.first.isPreRecord, isFalse);
  expect(all.first.defeatCount, 1);
});

test('重打仅累加 defeatCount 不覆盖快照', () async {
  final svc = BossMemoryService(isar: IsarSetup.instance);
  // 先首胜（totalDamage 18000），再以不同 stats 重打
  // ...recordBossVictory(...18000...)
  // ...recordBossVictory(...同 bossKey, 99999...)
  final m = (await svc.allMemories(IsarSetup.currentSlotId)).single;
  expect(m.defeatCount, 2);
  expect(m.totalDamage, 18000, reason: '首胜快照冻结，重打不覆盖');
});
```

- [ ] **Step 2: 跑确认 FAIL**

Run: `flutter test test/features/battle_record/application/boss_memory_service_test.dart`
Expected: FAIL（`BossMemoryService` 未定义）

- [ ] **Step 3: 实现 service**

```dart
// lib/features/battle_record/application/boss_memory_service.dart
import 'package:isar_community/isar.dart';
import '../../../core/domain/enums.dart';
import '../domain/boss_memory.dart';
import '../domain/boss_memory_source.dart';

class BossMemoryService {
  BossMemoryService({required this.isar});
  final Isar isar;

  Future<BossMemory?> _find(int saveDataId, String bossKey) => isar.bossMemorys
      .filter()
      .saveDataIdEqualTo(saveDataId)
      .bossKeyEqualTo(bossKey)
      .findFirst();

  /// 首胜建完整纪念；已存在同 bossKey → 仅 defeatCount++（幂等不覆盖快照）。
  Future<void> recordBossVictory({
    required int saveDataId,
    required String bossKey,
    required BossMemorySource source,
    required int groupIndex,
    required String bossName,
    required int totalDamage,
    required int critCount,
    required int totalTicks,
    String? topContributorName,
    int? topContributorDamage,
    String? treasureName,
    EquipmentTier? treasureTier,
    required List<String> rosterNames,
    required List<String> rosterPortraits,
    required DateTime now,
  }) async {
    await isar.writeTxn(() async {
      final existing = await _find(saveDataId, bossKey);
      if (existing != null) {
        existing.defeatCount += 1;
        await isar.bossMemorys.put(existing);
        return;
      }
      final m = BossMemory()
        ..saveDataId = saveDataId
        ..bossKey = bossKey
        ..source = source
        ..groupIndex = groupIndex
        ..bossName = bossName
        ..firstClearedAt = now
        ..isPreRecord = false
        ..totalDamage = totalDamage
        ..critCount = critCount
        ..totalTicks = totalTicks
        ..topContributorName = topContributorName
        ..topContributorDamage = topContributorDamage
        ..treasureName = treasureName
        ..treasureTier = treasureTier
        ..rosterNames = rosterNames
        ..rosterPortraits = rosterPortraits
        ..defeatCount = 1;
      await isar.bossMemorys.put(m);
    });
  }

  Future<List<BossMemory>> allMemories(int saveDataId) => isar.bossMemorys
      .filter()
      .saveDataIdEqualTo(saveDataId)
      .findAll();
}
```

- [ ] **Step 4: 跑确认 PASS + analyze**

Run: `flutter test test/features/battle_record/application/boss_memory_service_test.dart && flutter analyze lib/features/battle_record/`
Expected: PASS / No issues

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle_record/application/boss_memory_service.dart test/features/battle_record/application/boss_memory_service_test.dart
git commit -m "feat(battle_record): BossMemoryService 首胜建/重打累加/幂等"
```

---

### Task 4: 老档回填骨架 + 迁移接线

**Files:**
- Modify: `lib/features/battle_record/application/boss_memory_service.dart`（加 `backfillFromProgress`）
- Modify: `lib/data/isar_setup.dart`（迁移后调一次回填；或启动 ensure 后调用——实现时选与既有迁移调用点一致的位置）
- Test: `test/features/battle_record/application/boss_memory_backfill_test.dart`

**回填来源:** `MainlineProgress.clearedStageIds` + 同序 `clearedAt`（过滤 `GameRepository.instance.stageDefs[id].isBossStage`）；`TowerProgress.highestClearedFloor`（≤ 它的 Boss 层 5/10/15/20/25/30）。塔层无 per-floor 日期 → `firstClearedAt=null`。

- [ ] **Step 1: 写失败测试**

```dart
test('回填：已通关 Boss 关 → isPreRecord 骨架，战绩字段空', () async {
  // 种 MainlineProgress.clearedStageIds=['stage_01_01','stage_01_05'], clearedAt 对应
  // (stage_01_01 非 Boss → 不回填；stage_01_05 是 Boss → 回填)
  final svc = BossMemoryService(isar: IsarSetup.instance);
  await svc.backfillFromProgress(IsarSetup.currentSlotId);
  final all = await svc.allMemories(IsarSetup.currentSlotId);
  expect(all.where((m) => m.bossKey == 'stage_01_05'), hasLength(1));
  final m = all.firstWhere((m) => m.bossKey == 'stage_01_05');
  expect(m.isPreRecord, isTrue);
  expect(m.totalDamage, isNull, reason: '记录前·战绩不详');
  expect(m.defeatCount, 1);
  expect(all.any((m) => m.bossKey == 'stage_01_01'), isFalse, reason: '非 Boss 关不回填');
});

test('回填幂等：已存在纪念不重建/不覆盖', () async {
  // 先 recordBossVictory(stage_01_05 完整) → 再 backfill → 仍是完整非骨架
  // expect isPreRecord == false
});

test('塔层 Boss 回填日期为空', () async {
  // 种 TowerProgress.highestClearedFloor=10 → 回填 floor5/10 两条 tower_floor_*
  // expect firstClearedAt == null && isPreRecord
});
```

- [ ] **Step 2: 跑确认 FAIL**

Run: `flutter test test/features/battle_record/application/boss_memory_backfill_test.dart`
Expected: FAIL（`backfillFromProgress` 未定义）

- [ ] **Step 3: 实现 backfillFromProgress**（读 MainlineProgress/TowerProgress，幂等：`_find` 已存在则跳过；groupIndex 由 stageId/层号派生——主线 Ch index 取 stageId 段，心魔/轻功/群战给固定大序号；塔 = floorIndex）。bossName 从 `GameRepository.instance.stageDefs[id].enemyTeam.last.name` / 塔 floorDef 取。

- [ ] **Step 4: 接线迁移**（`isar_setup.dart` 迁移完成 / ensureSaveData 之后调 `BossMemoryService(isar: isar).backfillFromProgress(currentSlotId)`，与既有迁移调用点风格一致；幂等保证多次启动安全）

- [ ] **Step 5: 跑确认 PASS + 全量 test**（迁移逻辑改动）

Run: `flutter test`
Expected: 全绿

- [ ] **Step 6: Commit**

```bash
git add lib/features/battle_record/application/boss_memory_service.dart lib/data/isar_setup.dart test/features/battle_record/application/boss_memory_backfill_test.dart
git commit -m "feat(battle_record): 老档回填骨架 + 迁移接线"
```

---

### Task 5: 查询 provider + UiStrings 文案

**Files:**
- Create: `lib/features/battle_record/application/boss_memory_providers.dart`（Riverpod codegen，照项目 `@riverpod` 体例）
- Modify: `lib/shared/strings.dart`（追加战绩册文案）
- Test: `test/features/battle_record/application/boss_memory_providers_test.dart`

- [ ] **Step 1: 加 UiStrings 文案**（照现有静态串 + 带参方法体例，全中文集中此处）

```dart
// 主菜单
static const String mainMenuBattleRecord = '战绩册';
static const String mainMenuBattleRecordHint = '回顾历战，名垂江湖';
// 屏标题/分区
static const String battleRecordTitle = '战绩册';
static const String battleRecordLockedBoss = '未会之敌';
static const String battleRecordPreRecord = '此役不详 · 记录之前';
static const String battleRecordTopContributorTitle = '此战之最';
static const String battleRecordRosterTitle = '出战';
static const String battleRecordTreasureTitle = '所获';
static const String battleRecordStatsTitle = '首胜战绩';
static String battleRecordDefeatCount(int n) => '击败 $n 次';
static String battleRecordDamage(int d) => '总伤害 $d';
static String battleRecordCrits(int c) => '暴击 $c';
static String battleRecordTurns(int t) => '$t 回合';
static String battleRecordClearedAt(String date) => '初胜 $date';
```

- [ ] **Step 2: 写 provider 失败测试**（count + grouped）

```dart
test('bossMemoryCount = 非占位纪念数', () async {
  // 种 1 完整 + 1 骨架（isPreRecord） → count 谓词用于入口门控：
  // 入口谓词 = 「存在 ≥1 条已击败（含骨架，因为骨架=已击败）」→ count = 全部纪念数
  // expect count == 2（骨架也算已击败，入口该显）
});
```

> 注：入口门控谓词 = 「存在 ≥1 条 BossMemory」（骨架=老档已击败，也应解锁入口）。

- [ ] **Step 3: 实现 providers**（`bossMemoryCountProvider`→int / `bossMemoriesGroupedProvider`→按 source+groupIndex 分组列表；读 `BossMemoryService.allMemories`）

- [ ] **Step 4: 跑确认 PASS + analyze + build_runner**（codegen provider）

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/features/battle_record/application/boss_memory_providers_test.dart && flutter analyze lib/features/battle_record/ lib/shared/strings.dart`
Expected: PASS / No issues

- [ ] **Step 5: Commit**

```bash
git add lib/features/battle_record/application/ lib/shared/strings.dart test/features/battle_record/application/boss_memory_providers_test.dart
git commit -m "feat(battle_record): 查询 provider + UiStrings 文案"
```

---

### Task 6: 主线 victory 留档接线

**Files:**
- Create: `lib/features/battle_record/application/boss_memory_hook.dart`（`runBossMemoryHookAfterVictory`，仿 `disciple_join_hook.dart` 体例）
- Modify: `lib/features/mainline/presentation/stage_entry_flow.dart`（生产 `else` 块内、`skillDrop=...` 之后约 219 行 + `outcome != null` 守卫）
- Test: `test/features/battle_record/application/boss_memory_hook_test.dart`

**接线点（已核实）:** `stage_entry_flow.dart:184` 取 `outcome`；`:199` `clearedBeforeVictory` 已是首胜前快照；生产路径在 `else`（test stub `victoryRecorderForTest` 跳过，与 recordVictory/skillDrop 一致）。

- [ ] **Step 1: 写 hook**

```dart
// boss_memory_hook.dart
/// Boss 首胜 → 战绩册留档（纯数据写，无 UI）。非 Boss / 非首胜 / Isar 未 ready → no-op。
/// treasure 在此层从 drops 算（取最高阶装备掉落），service 只存 name+tier。
Future<void> runBossMemoryHookAfterVictory({
  required WidgetRef ref,
  required StageDef stage,
  required BattleStatsSummary stats,
  required DropResult drops,
  required TopDamageContributor? topContributor,
  required bool isFirstClear,
}) async {
  final isar = IsarSetup.instanceOrNull;
  if (isar == null || !stage.isBossStage) return;
  // 首胜建 / 重打累加都进 service（service 内幂等）；但首胜才有完整快照价值——
  // 非首胜也调用以累加 defeatCount（service 判已存在 → ++）。
  // 组装 roster（active 角色 name+portrait）、treasure（最高阶装备掉落）、source/groupIndex。
  // bossName = stage.enemyTeam.last.name（空则 stage.name）。
  await BossMemoryService(isar: isar).recordBossVictory(... 见下 ...);
}
```

- [ ] **Step 2: 写失败测试**（hook：非 Boss no-op / Boss 首胜落账 / 重打累加）。用 Isar temp + 构造 Boss StageDef + 假 stats/drops。

- [ ] **Step 3: 跑确认 FAIL**

Run: `flutter test test/features/battle_record/application/boss_memory_hook_test.dart`
Expected: FAIL

- [ ] **Step 4: 实现 hook 内组装逻辑 + 接线 stage_entry_flow**

`stage_entry_flow.dart` 约 219 行（`skillDrop = await runStageSkillDropHookAfterVictory(...)` 之后、`}` 关闭 else 之前）插入：
```dart
    // P4 战绩册:Boss 首胜/重打 → 留档(纯数据写,test stub 路径跳过,同 recordVictory)。
    if (stage.isBossStage && outcome != null) {
      final isFirstClear = !clearedBeforeVictory.contains(stage.id);
      await runBossMemoryHookAfterVictory(
        ref: ref,
        stage: stage,
        stats: outcome.stats,
        drops: outcome.drops,
        topContributor: TopDamageContributor.from(/* finalState 来源:见下 */),
        isFirstClear: isFirstClear,
      );
    }
```
> 注：`outcome` 不含 finalState；topContributor 可从 `outcome.heroCamera`（HeroCameraData 已含最高输出者 name+damage）派生，避免重算。实现时确认 `HeroCameraData` 字段名，用它填 topContributorName/Damage。

- [ ] **Step 5: 跑确认 PASS + 全量 test**（改生产结算流）

Run: `flutter test`
Expected: 全绿

- [ ] **Step 6: Commit**

```bash
git add lib/features/battle_record/application/boss_memory_hook.dart lib/features/mainline/presentation/stage_entry_flow.dart test/features/battle_record/application/boss_memory_hook_test.dart
git commit -m "feat(battle_record): 主线 victory 留档接线"
```

---

### Task 7: 爬塔 victory 留档接线

**Files:**
- Modify: `lib/features/tower/presentation/tower_entry_flow.dart`（`_applyTowerVictoryResolution` 调用点之后，对称接 `runBossMemoryHookAfterVictory`，bossKey=`tower_floor_<N>` / source=tower / groupIndex=floorIndex）
- Test: `test/features/battle_record/application/boss_memory_tower_hook_test.dart`

- [ ] **Step 1: 写失败测试**（仅 Boss 层 [5/10/15/20/25/30] 落账；普通层 no-op）
- [ ] **Step 2: 跑确认 FAIL**
- [ ] **Step 3: 接线 tower_entry_flow**（floor.bossKind 非空才记；bossName 从 floorDef enemy 取）。复用 Task 6 的 `runBossMemoryHookAfterVictory`（加 source/bossKey 参数支持 tower 形态——实现时把 hook 参数泛化为接 `source/bossKey/groupIndex/bossName` 显式入参，主线/塔各自传）。
- [ ] **Step 4: 跑确认 PASS + 全量 test**

Run: `flutter test`
Expected: 全绿

- [ ] **Step 5: Commit**

```bash
git commit -am "feat(battle_record): 爬塔 victory 留档接线"
```

---

### Task 8: `BattleRecordScreen`（主屏 · 分组 + 剩影占位）

**Files:**
- Create: `lib/features/battle_record/presentation/battle_record_screen.dart`
- Test: `test/features/battle_record/presentation/battle_record_screen_test.dart`

**展示:** 分组列（主线按章 + 心魔/轻功/群战；爬塔按层）。已击败=纪念缩略卡（立绘+名+初胜日期+「击败 N 次」）；未击败=剩影占位（剪影 + 章节位 + `UiStrings.battleRecordLockedBoss`「未会之敌」，不显总数）。全 Boss 列表从 `GameRepository`（stageDefs isBossStage + towers bossKind）取「应有 27 条」，与已存纪念 join，缺的显剩影。立绘 `Image.asset` 必带 errorBuilder（memory `feedback_image_asset_error_builder`）。WuxiaPaperPanel 滚动列 tile 包 IntrinsicHeight（memory `feedback_wuxia_paper_panel_scroll_tile`）。ListView widget 测扩 viewport `setSurfaceSize(800,2000)`（memory `feedback_listview_widget_test_viewport`）。

- [ ] **Step 1: 写 widget 失败测试**（种 1 完整纪念 + 全 Boss 列表 → 断言：已击败卡显 bossName + 「击败 N 次」；未击败显「未会之敌」剩影；pre-record 不崩）
- [ ] **Step 2: 跑确认 FAIL**
- [ ] **Step 3: 实现 screen**（WuxiaTitleBar + 分组 ListView，读 `bossMemoriesGroupedProvider` + 全 Boss 目录派生 helper）
- [ ] **Step 4: 跑确认 PASS + analyze**
- [ ] **Step 5: Commit**

```bash
git commit -am "feat(battle_record): 战绩册主屏 分组+剩影占位"
```

---

### Task 9: `BossMemoryDetailScreen`（单 Boss 详情 + pre-record 态）

**Files:**
- Create: `lib/features/battle_record/presentation/boss_memory_detail_screen.dart`
- Test: `test/features/battle_record/presentation/boss_memory_detail_screen_test.dart`

**展示:** 立绘 + 首胜战报卡（总伤害/暴击/回合）+ 最高输出者（英雄）+ 掉落宝物 + 出战阵容 + 击败次数。`isPreRecord` → 战绩区显 `UiStrings.battleRecordPreRecord`「此役不详 · 记录之前」，stats 区不渲染数字。

- [ ] **Step 1: 写 widget 失败测试**（完整态显伤害/英雄/掉落/阵容；pre-record 态显「此役不详」且不显伤害数字）
- [ ] **Step 2: 跑确认 FAIL**
- [ ] **Step 3: 实现 screen**（入参 `BossMemory`，纯只读渲染）
- [ ] **Step 4: 跑确认 PASS + analyze**
- [ ] **Step 5: Commit**

```bash
git commit -am "feat(battle_record): Boss 纪念详情屏 + pre-record 态"
```

---

### Task 10: 主菜单 gated 入口

**Files:**
- Modify: `lib/features/main_menu/presentation/main_menu.dart`（加「战绩册」`WuxiaInkButton`，门控谓词 = `bossMemoryCountProvider > 0`，首胜前隐藏，守 §5.7）
- Test: `test/features/main_menu/presentation/main_menu_test.dart`（若存在则追加）

**参考:** main_menu 现有 `WuxiaInkButton` 体例 + `cleared.contains(...)` / `step <` 条件显示模式。入口跳 `BattleRecordScreen`。

- [ ] **Step 1: 写 widget 失败测试**（0 纪念 → 无「战绩册」按钮；≥1 纪念 → 有按钮且可点进 BattleRecordScreen）
- [ ] **Step 2: 跑确认 FAIL**
- [ ] **Step 3: 实现按钮 + 门控谓词**（read `bossMemoryCountProvider`，>0 才加入 items；icon 用既有素材或 `Icons.menu_book_outlined` 占位 + 注释待美术）
- [ ] **Step 4: 跑确认 PASS + 全量 test**（改主菜单）
- [ ] **Step 5: Commit**

```bash
git commit -am "feat(battle_record): 主菜单战绩册入口(首胜后解锁)"
```

---

### Task 11: VISUAL_ROUTE 目检入口

**Files:**
- Modify: `lib/features/debug/application/visual_route.dart`（加 `battleRecord` + `bossMemoryDetail` 两枚举值）
- Modify: `lib/features/debug/presentation/visual_route_host.dart`（import + switch case，种数据后挂屏）
- Test: `test/features/debug/visual_route_test.dart`（追加 parse 断言）

**参考:** 本会话已加 `disciple_join_ceremony` route 的体例（枚举值 + buildVisualTarget case + 种纪念数据预览 widget）。`battle_record` 种「1 完整 + 剩影混合」；`boss_memory_detail` 种「完整 + pre-record 两态」。

- [ ] **Step 1: 加枚举值 + parse 测**
- [ ] **Step 2: 跑确认 FAIL**
- [ ] **Step 3: 加 switch case + 预览（种 BossMemory 数据 → 挂 BattleRecordScreen / BossMemoryDetailScreen）**
- [ ] **Step 4: 跑确认 PASS + analyze**
- [ ] **Step 5: Commit**

```bash
git commit -am "feat(debug): VISUAL_ROUTE battle_record + boss_memory_detail 目检"
```

---

### Task 12: 红线测 + 整批收口

**Files:**
- Create: `test/features/battle_record/battle_record_redline_test.dart`
- Test: 全量

- [ ] **Step 1: 写红线测**
  - §5.4：grep/静态断言 battle_record/ 下 0 处 import damage_calculator / 0 处写 numbers 数值（断言 feature 目录不引战斗公式层）。
  - §5.5：离线路径不触发——断言 `runBossMemoryHookAfterVictory` 仅由 victory flow 调用，offline_recap 路径无引用（grep offline_recap 不含 BossMemory）。
- [ ] **Step 2: 跑红线测确认 PASS**
- [ ] **Step 3: 全量 analyze + test 收口**

Run: `flutter analyze && flutter test`
Expected: analyze 0 / 全量全绿（贴 baseline → 新增数）

- [ ] **Step 4: Commit**

```bash
git commit -am "test(battle_record): 红线测 + 整批收口"
```

---

## Self-Review（已核对）

- **Spec 覆盖:** §2 数据模型→T1/T2；§3 留档(首胜/重打/回填)→T3/T4/T6/T7；§4 展示(主屏/详情/入口/route)→T8/T9/T10/T11；§5 文案→T1/T5；§6 红线→T12 + 各 task 守则；§7 测试→各 task TDD。无遗漏。
- **类型一致:** `BossMemorySource{mainline,tower}`、`recordBossVictory(...)` 参数、`bossMemoryCountProvider`、`runBossMemoryHookAfterVictory` 全 task 引用一致。
- **占位扫描:** 接线点带已核实 file:line；hook/screen 给契约 + 关键断言 + 必守 memory 配方。T6/T7 的 topContributor 来源与 treasure 组装在 Step 标注「实现时确认字段名」（HeroCameraData / DropResult 真实字段），属诚实的实现期确认点非占位。
- **风险点:** 接线不动 900 行结算函数内部（仿 disciple_join_hook caller 层）；schema 改动每次跑 build_runner + 全量 test 已写入 task。
