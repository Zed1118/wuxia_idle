# 兵器谱 Implementation Plan(P4 长期档案·子项2)

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development。逐 task 实装,checkbox 跟踪。
> spec: `docs/spec/2026-06-20-p4-weapon-codex-design.md`。姊妹参照:`lib/features/battle_record/`(战绩册,全程照体例)。

**Goal:** 收集式装备图鉴——记录玩家曾获得的全部 80 件装备,已获得点亮/未获得剪影,详情卡含个人获得历程。

**Architecture:** 新建 `lib/features/weapon_codex/` feature(domain/application/presentation 三层,对称 battle_record)。新 `EquipmentCatalogEntry` @collection 持久化。写入双策略:`reconcileFromInventory` 扫当前库存为骨干(存档加载触发,兼老档回填+漏点安全网),高价值路径(主线/爬塔掉落、奇遇)挂获得 hook 提供首得来源。纯收集/展示层,不碰伤害/掉落经济。

**Tech Stack:** Flutter + Isar + Riverpod codegen(@riverpod)。TDD:service/迁移用 `test()`(非 testWidgets,防 Isar 死锁),UI 用 `testWidgets`。

---

## Phase 0 已确认事实(开工前读,无需重查)

- 装备 def:`EquipmentDef`(`lib/data/defs/equipment_def.dart`),`GameRepository.instance.equipmentDefs`(Map),共 **80 件**(weapon 36/armor 22/accessory 22)。`GameRepository.isLoaded` 守卫。
- tier 枚举 `EquipmentTier`(7 档),label `EnumL10n.equipmentTier(tier)`;slot 枚举 `EquipmentSlot`(weapon/armor/accessory)。
- 装备实例 `Equipment`(`lib/core/domain/equipment.dart`),字段 `defId`/`tier`/`slot`/`obtainedFrom`。当前库存 = `isar.equipments`(当前存档实例)。
- Isar:`IsarSetup.instance`/`instanceOrNull`/`currentSlotId`;schema 注册 `_allSchemas`(isar_setup.dart:71);版本 `_currentSaveVersion = '0.26.0'`(isar_setup.dart:131)。
- **装备进库存散落多点**(无单一 chokepoint):mainline `stage_entry_flow.dart:820`、tower `tower_entry_flow.dart:588`、奇遇 `game_event_service.dart:147,257`、招募/开局/飞升/闭关。→ 故用 reconcile 兜底 + 高价值路径 hook。
- `.g.dart` gitignored,改 @collection / @riverpod 后**必跑 build_runner**。

---

## File Structure

| 文件 | 职责 |
|------|------|
| `lib/features/weapon_codex/domain/equipment_catalog_entry.dart` | @collection entity |
| `lib/features/weapon_codex/application/equipment_catalog_service.dart` | recordAcquisitions(幂等)+ reconcileFromInventory + 查询 |
| `lib/features/weapon_codex/application/equipment_catalog_hook.dart` | best-effort 获得钩子 |
| `lib/features/weapon_codex/application/equipment_catalog_providers.dart` | list/count/progress provider |
| `lib/features/weapon_codex/presentation/weapon_codex_screen.dart` | 主屏 |
| `lib/features/weapon_codex/presentation/equipment_catalog_detail_screen.dart` | 详情屏 |
| `lib/shared/strings.dart`(改) | UiStrings 文案 |
| `lib/data/isar_setup.dart`(改) | schema 注册 + 版本 bump + reconcile-on-load |
| `lib/features/main_menu/presentation/main_menu.dart`(改) | 入口 + 解锁门控 |
| `lib/features/mainline/presentation/stage_entry_flow.dart`(改) | 主线掉落 hook |
| `lib/features/tower/presentation/tower_entry_flow.dart`(改) | 爬塔掉落 hook |
| `lib/features/event/application/game_event_service.dart`(改) | 奇遇掉落 hook |
| `lib/features/debug/application/visual_route.dart` + host(改) | VISUAL_ROUTE 验收路由 |

---

## Task 1: EquipmentCatalogEntry @collection

**Files:**
- Create: `lib/features/weapon_codex/domain/equipment_catalog_entry.dart`

- [ ] **Step 1: 写 collection 类**(照 BossMemory 体例 `lib/features/battle_record/domain/boss_memory.dart`)

```dart
import 'package:isar/isar.dart';

part 'equipment_catalog_entry.g.dart';

/// 兵器谱图鉴条目:玩家曾获得过的某件装备 def 的留档。
///
/// 「曾获得即永久点亮」:一旦建档不删,卖掉/分解不影响。
/// 回填档(isPreRecord=true)= 本功能上线前已持有,来历不详。
@collection
class EquipmentCatalogEntry {
  Id id = Isar.autoIncrement;
  late int saveDataId;

  /// 装备 def 唯一键(= EquipmentDef.id)。同档唯一。
  @Index()
  late String defId;

  /// 首次获得时间;回填档为 null。
  DateTime? firstObtainedAt;

  /// 首次获得来源(如关卡名/「宝塔第N层」/奇遇名);回填档=「来历不详」。
  late String firstObtainedFrom;

  /// 历史累计获得次数(重得 ++)。
  late int obtainedCount;

  /// 回填骨架标记(true=上线前已持有)。
  late bool isPreRecord;
}
```

- [ ] **Step 2: 跑 build_runner 生成 .g.dart**

Run: `flutter pub run build_runner build --delete-conflicting-outputs 2>&1 | tail -5`
Expected: `Succeeded`,生成 `equipment_catalog_entry.g.dart`(含 `EquipmentCatalogEntrySchema`)

- [ ] **Step 3: analyze 确认无错**

Run: `flutter analyze lib/features/weapon_codex/ 2>&1 | tail -3`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/weapon_codex/domain/
git commit -m "feat(weapon_codex): EquipmentCatalogEntry @collection"
```

---

## Task 2: Isar 注册 + 存档版本 bump

**Files:**
- Modify: `lib/data/isar_setup.dart`(`_allSchemas` 末尾 + `_currentSaveVersion`)

- [ ] **Step 1: _allSchemas 追加 schema**

在 `_allSchemas` list 末尾(BossMemorySchema 之后)加:

```dart
    EquipmentCatalogEntrySchema,
```

文件顶部加 import:

```dart
import '../features/weapon_codex/domain/equipment_catalog_entry.dart';
```

- [ ] **Step 2: bump 版本号**

```dart
static const _currentSaveVersion = '0.27.0';
```

并在版本历史注释段(isar_setup.dart:91-130 区)末尾追加一行:

```dart
//   段(0.27.0 兵器谱):新 EquipmentCatalogEntry collection,旧档天然空。
//   老档当前持有装备的回填在 reconcileFromInventory 处理(Task 4 接 load 钩子)。
```

- [ ] **Step 3: analyze**

Run: `flutter analyze lib/data/isar_setup.dart 2>&1 | tail -3`
Expected: `No issues found!`(EquipmentCatalogEntrySchema 已由 Task 1 build_runner 生成)

- [ ] **Step 4: Commit**

```bash
git add lib/data/isar_setup.dart
git commit -m "feat(weapon_codex): 注册 collection + saveVer 0.27.0"
```

---

## Task 3: EquipmentCatalogService(幂等写入 + reconcile)

**Files:**
- Create: `lib/features/weapon_codex/application/equipment_catalog_service.dart`
- Test: `test/features/weapon_codex/equipment_catalog_service_test.dart`

- [ ] **Step 1: 写失败测试**(用 `test()` 非 testWidgets,防 Isar 死锁;照 battle_record 测体例建临时 Isar)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:wuxia_idle/core/domain/equipment.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/weapon_codex/domain/equipment_catalog_entry.dart';
import 'package:wuxia_idle/features/weapon_codex/application/equipment_catalog_service.dart';
// 复用既有测试 Isar harness(参照 boss_memory_service_test.dart 的 setUp/tearDown 写法)

void main() {
  late Isar isar;
  setUp(() async {
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open(
      [EquipmentCatalogEntrySchema, EquipmentSchema],
      directory: '', // 临时目录,照 boss_memory_service_test
      name: 'wcat_${DateTime.now().microsecondsSinceEpoch}',
    );
  });
  tearDown(() async => isar.close(deleteFromDisk: true));

  test('首得建档:firstObtainedAt/from 写入,count=1,非 preRecord', () async {
    final svc = EquipmentCatalogService(isar: isar);
    final now = DateTime(2026, 6, 20);
    await svc.recordAcquisitions(
      saveDataId: 1, defIds: ['weapon_a'], from: '黑风寨之战', now: now,
    );
    final e = await svc.entryFor(1, 'weapon_a');
    expect(e, isNotNull);
    expect(e!.firstObtainedAt, now);
    expect(e.firstObtainedFrom, '黑风寨之战');
    expect(e.obtainedCount, 1);
    expect(e.isPreRecord, false);
  });

  test('重得:仅 count++,不覆盖 firstObtained*', () async {
    final svc = EquipmentCatalogService(isar: isar);
    final t1 = DateTime(2026, 6, 20);
    await svc.recordAcquisitions(saveDataId: 1, defIds: ['weapon_a'], from: '黑风寨之战', now: t1);
    await svc.recordAcquisitions(saveDataId: 1, defIds: ['weapon_a'], from: '另一处', now: DateTime(2026, 7, 1));
    final e = await svc.entryFor(1, 'weapon_a');
    expect(e!.obtainedCount, 2);
    expect(e.firstObtainedFrom, '黑风寨之战'); // 不变
    expect(e.firstObtainedAt, t1);
  });

  test('reconcileFromInventory:库存中未入册的 def → 建 preRecord 来历不详', () async {
    // 先放一件库存装备(未入册)
    await isar.writeTxn(() async {
      await isar.equipments.put(Equipment.create(
        defId: 'weapon_old', tier: EquipmentTier.liQi, slot: EquipmentSlot.weapon,
        school: null, baseAttack: 10, baseHealth: 10, baseSpeed: 10,
        obtainedAt: DateTime(2026, 1, 1), obtainedFrom: 'x', ownerCharacterId: null,
      ));
    });
    final svc = EquipmentCatalogService(isar: isar);
    await svc.reconcileFromInventory(1);
    final e = await svc.entryFor(1, 'weapon_old');
    expect(e, isNotNull);
    expect(e!.isPreRecord, true);
    expect(e.firstObtainedFrom, UiStringsBackfillSource); // 见实现:'来历不详'
    expect(e.firstObtainedAt, isNull);
  });

  test('reconcile 幂等:已入册的 def 不被覆盖为 preRecord', () async {
    final svc = EquipmentCatalogService(isar: isar);
    await svc.recordAcquisitions(saveDataId: 1, defIds: ['weapon_a'], from: '真来源', now: DateTime(2026, 6, 20));
    await isar.writeTxn(() async {
      await isar.equipments.put(Equipment.create(
        defId: 'weapon_a', tier: EquipmentTier.liQi, slot: EquipmentSlot.weapon,
        school: null, baseAttack: 10, baseHealth: 10, baseSpeed: 10,
        obtainedAt: DateTime(2026, 1, 1), obtainedFrom: 'x', ownerCharacterId: null,
      ));
    });
    await svc.reconcileFromInventory(1);
    final e = await svc.entryFor(1, 'weapon_a');
    expect(e!.isPreRecord, false); // 真来源未被 reconcile 降级
    expect(e.firstObtainedFrom, '真来源');
  });
}
```

> 注:`UiStringsBackfillSource` 在测试里直接写字面 `'来历不详'` 比对(实现引用 `UiStrings.weaponCodexBackfillSource`,Task 6 定义)。Task 6 前此测临时用字面量,Task 6 后改引用常量。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/weapon_codex/equipment_catalog_service_test.dart 2>&1 | tail -5`
Expected: FAIL(EquipmentCatalogService 未定义)

- [ ] **Step 3: 写 service 实现**(照 BossMemoryService 体例)

```dart
import 'package:isar/isar.dart';
import '../../../core/domain/equipment.dart';
import '../domain/equipment_catalog_entry.dart';

class EquipmentCatalogService {
  EquipmentCatalogService({required this.isar});
  final Isar isar;

  /// 回填来源标签(老档/漏点 reconcile 时用)。
  static const backfillSource = '来历不详';

  Future<EquipmentCatalogEntry?> entryFor(int saveDataId, String defId) =>
      isar.equipmentCatalogEntrys
          .filter()
          .saveDataIdEqualTo(saveDataId)
          .defIdEqualTo(defId)
          .findFirst();

  /// 记录获得(幂等):首得建档,重得仅 count++。
  Future<void> recordAcquisitions({
    required int saveDataId,
    required List<String> defIds,
    required String from,
    required DateTime now,
  }) async {
    if (defIds.isEmpty) return;
    await isar.writeTxn(() async {
      for (final defId in defIds) {
        final existing = await entryFor(saveDataId, defId);
        if (existing != null) {
          existing.obtainedCount += 1;
          await isar.equipmentCatalogEntrys.put(existing);
          continue;
        }
        final e = EquipmentCatalogEntry()
          ..saveDataId = saveDataId
          ..defId = defId
          ..firstObtainedAt = now
          ..firstObtainedFrom = from
          ..obtainedCount = 1
          ..isPreRecord = false;
        await isar.equipmentCatalogEntrys.put(e);
      }
    });
  }

  /// 从当前库存兜底回填:每个未入册的 owned defId → 建 preRecord 来历不详条目。
  /// 幂等:已入册的 defId 跳过(不降级)。兼任老档回填 + 漏点安全网。
  Future<void> reconcileFromInventory(int saveDataId) async {
    final owned = await isar.equipments.where().findAll();
    final ownedDefIds = owned.map((e) => e.defId).toSet();
    if (ownedDefIds.isEmpty) return;
    await isar.writeTxn(() async {
      for (final defId in ownedDefIds) {
        final existing = await entryFor(saveDataId, defId);
        if (existing != null) continue;
        final e = EquipmentCatalogEntry()
          ..saveDataId = saveDataId
          ..defId = defId
          ..firstObtainedAt = null
          ..firstObtainedFrom = backfillSource
          ..obtainedCount = 1
          ..isPreRecord = true;
        await isar.equipmentCatalogEntrys.put(e);
      }
    });
  }

  Future<List<EquipmentCatalogEntry>> allEntries(int saveDataId) =>
      isar.equipmentCatalogEntrys.filter().saveDataIdEqualTo(saveDataId).findAll();
}
```

> 测试 Step 1 里 `UiStringsBackfillSource` 比对处先写字面 `EquipmentCatalogService.backfillSource`。

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/features/weapon_codex/equipment_catalog_service_test.dart 2>&1 | tail -5`
Expected: All tests passed

- [ ] **Step 5: Commit**

```bash
git add lib/features/weapon_codex/application/equipment_catalog_service.dart test/features/weapon_codex/
git commit -m "feat(weapon_codex): EquipmentCatalogService 幂等写入 + reconcile + 测试"
```

---

## Task 4: reconcile-on-load 接存档加载

**Files:**
- Modify: `lib/data/isar_setup.dart`(加载流程末尾,照 0.26 backfillFromProgress 体例 isar_setup.dart:162-169)

- [ ] **Step 1: 在 open 后加载段接 reconcile**

找到 0.26 战绩册 backfill 段(isar_setup.dart:162),其后追加:

```dart
// 0.27.0 兵器谱:扫当前库存兜底回填图鉴(幂等,新档库存空时 no-op)。
// 兼任老档当前持有装备的点亮 + 任何漏 hook 路径的安全网。
try {
  await EquipmentCatalogService(isar: isar).reconcileFromInventory(currentSlotId);
} catch (_) {
  // 库存异常时静默 skip,不阻塞启动
}
```

文件顶部加 import:

```dart
import '../features/weapon_codex/application/equipment_catalog_service.dart';
```

- [ ] **Step 2: analyze**

Run: `flutter analyze lib/data/isar_setup.dart 2>&1 | tail -3`
Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/data/isar_setup.dart
git commit -m "feat(weapon_codex): 存档加载时 reconcileFromInventory 兜底回填"
```

---

## Task 5: 获得 hook + 高价值路径接线

**Files:**
- Create: `lib/features/weapon_codex/application/equipment_catalog_hook.dart`
- Modify: `lib/features/mainline/presentation/stage_entry_flow.dart:820` 附近
- Modify: `lib/features/tower/presentation/tower_entry_flow.dart:588` 附近
- Modify: `lib/features/event/application/game_event_service.dart:147,257` 附近

- [ ] **Step 1: 写 hook**(照 boss_memory_hook 体例,best-effort try-catch)

```dart
import 'package:flutter/foundation.dart';
import '../../../data/isar_setup.dart';
import 'equipment_catalog_service.dart';

/// 获得装备后留册(best-effort,失败不打断获得主流程)。
/// [defIds] 本次获得的装备 def id 列表;[from] 来源展示名(关卡/塔层/奇遇)。
Future<void> runEquipmentCatalogHookAfterObtain({
  required List<String> defIds,
  required String from,
}) async {
  final isar = IsarSetup.instanceOrNull;
  if (isar == null || defIds.isEmpty) return;
  try {
    await EquipmentCatalogService(isar: isar).recordAcquisitions(
      saveDataId: IsarSetup.currentSlotId,
      defIds: defIds,
      from: from,
      now: DateTime.now(),
    );
  } catch (e, s) {
    debugPrint('runEquipmentCatalogHookAfterObtain 留册失败(降级): $e\n$s');
  }
}
```

- [ ] **Step 2: 主线掉落接线**(stage_entry_flow.dart:819-820 持久化掉落后)

在 `await isar.equipments.putAll(result.dropResult.equipments);` 之后追加:

```dart
await runEquipmentCatalogHookAfterObtain(
  defIds: [for (final e in result.dropResult.equipments) e.defId],
  from: stage.name, // 当前关卡名作来源(stage 变量在该作用域可见,实装时确认字段名)
);
```

文件顶部 import:

```dart
import '../../weapon_codex/application/equipment_catalog_hook.dart';
```

> 实装注意:`stage.name` 字段名以实际 StageDef 为准(Task 实装时 grep `class StageDef` 确认,若为 `title`/`displayName` 则换)。

- [ ] **Step 3: 爬塔掉落接线**(tower_entry_flow.dart:588 之后)

在 `await isar.equipments.putAll(drops.equipments);` 之后追加(来源用「宝塔第N层」,floor 变量在作用域内):

```dart
await runEquipmentCatalogHookAfterObtain(
  defIds: [for (final e in drops.equipments) e.defId],
  from: UiStrings.weaponCodexSourceTowerFloor(floor), // Task 6 定义
);
```

- [ ] **Step 4: 奇遇掉落接线**(game_event_service.dart:147 单件 + :257 warbornEquipment 批量)

各持久化后追加 hook,`from` 用通用来源常量 `UiStrings.weaponCodexSourceEncounter`(「奇遇所得」,Task 6 定义——奇遇 event 名在该作用域不一定易取,用通用来源避免脆引用)。单件:

```dart
await runEquipmentCatalogHookAfterObtain(
  defIds: [equipment.defId], from: UiStrings.weaponCodexSourceEncounter);
```
批量:
```dart
await runEquipmentCatalogHookAfterObtain(
  defIds: [for (final e in warbornEquipment) e.defId],
  from: UiStrings.weaponCodexSourceEncounter);
```

- [ ] **Step 5: 全量 analyze + 全量 test(防跨文件回归)**

Run: `flutter analyze 2>&1 | tail -3 && flutter test 2>&1 | tail -8`
Expected: analyze `No issues found!`;test 全过零回归

- [ ] **Step 6: Commit**

```bash
git add lib/features/weapon_codex/application/equipment_catalog_hook.dart lib/features/mainline/ lib/features/tower/ lib/features/event/
git commit -m "feat(weapon_codex): 获得 hook + 主线/爬塔/奇遇接线"
```

---

## Task 6: UiStrings 文案

**Files:**
- Modify: `lib/shared/strings.dart`(battleRecord 那批附近,strings.dart:1618 区)

- [ ] **Step 1: 加文案常量**(照 battleRecord 体例)

```dart
// ── 兵器谱 ──
static const String mainMenuWeaponCodex = '兵器谱';
static const String mainMenuWeaponCodexHint = '历观神兵,谱录江湖';
static const String weaponCodexTitle = '兵器谱';
static const String weaponCodexBackfillSource = '来历不详';
static const String weaponCodexLockedItem = '未得之器';
static const String weaponCodexHistoryUnknown = '来历已不可考';
static const String weaponCodexFilterAll = '全部';
static const String weaponCodexFilterWeapon = '兵器';
static const String weaponCodexFilterArmor = '护甲';
static const String weaponCodexFilterAccessory = '饰品';
static const String weaponCodexNotObtained = '尚未得手';
static String weaponCodexProgress(int got, int total) => '已录 $got / $total';
static String weaponCodexTierProgress(int got, int total) => '$got/$total';
static String weaponCodexFirstObtainedAt(String date) => '首得 $date';
static String weaponCodexFirstObtainedFrom(String src) => '得于 $src';
static String weaponCodexObtainedCount(int n) => '历得 $n 件';
static String weaponCodexSourceTowerFloor(int floor) => '宝塔第 $floor 层';
static const String weaponCodexSourceEncounter = '奇遇所得';
```

- [ ] **Step 2: 把 service 测试里的 backfillSource 比对改引用常量**

`test/.../equipment_catalog_service_test.dart` 中 `'来历不详'` 字面量处保持不变(值相同),无需改;service 的 `backfillSource` 改为引用 `UiStrings.weaponCodexBackfillSource`:

在 `equipment_catalog_service.dart` 顶部 import strings,`static const backfillSource = UiStrings.weaponCodexBackfillSource;`

- [ ] **Step 3: analyze + service 测试**

Run: `flutter analyze lib/shared/strings.dart lib/features/weapon_codex/ 2>&1 | tail -3 && flutter test test/features/weapon_codex/equipment_catalog_service_test.dart 2>&1 | tail -3`
Expected: `No issues found!` + tests passed

- [ ] **Step 4: Commit**

```bash
git add lib/shared/strings.dart lib/features/weapon_codex/application/equipment_catalog_service.dart
git commit -m "feat(weapon_codex): UiStrings 文案"
```

---

## Task 7: Providers

**Files:**
- Create: `lib/features/weapon_codex/application/equipment_catalog_providers.dart`
- Test: `test/features/weapon_codex/equipment_catalog_providers_test.dart`

- [ ] **Step 1: 写 providers**(照 boss_memory_providers @riverpod 体例)

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/isar_setup.dart';
import '../domain/equipment_catalog_entry.dart';
import 'equipment_catalog_service.dart';

part 'equipment_catalog_providers.g.dart';

/// 当前存档全部图鉴条目。
@Riverpod(dependencies: [])
Future<List<EquipmentCatalogEntry>> equipmentCatalogList(Ref ref) async {
  final isar = IsarSetup.instance;
  return EquipmentCatalogService(isar: isar).allEntries(IsarSetup.currentSlotId);
}

/// 已录条目数(主菜单解锁门控:>0 显入口)。
@Riverpod(dependencies: [])
Future<int> equipmentCatalogCount(Ref ref) async {
  final list = await ref.watch(equipmentCatalogListProvider.future);
  return list.length;
}
```

- [ ] **Step 2: build_runner**

Run: `flutter pub run build_runner build --delete-conflicting-outputs 2>&1 | tail -3`
Expected: Succeeded(生成 providers.g.dart)

- [ ] **Step 3: 写 provider 测试**(经 ProviderContainer,照 battle_record provider 测体例,用 test())

```dart
// 验 equipmentCatalogListProvider 读出 service 写入的条目数。
// (建临时 Isar + 设 IsarSetup,ProviderContainer 读,期望 count == 写入数)
```

> 具体 harness 照 `test/features/battle_record/` 下对应 provider 测照搬(同 IsarSetup 注入方式)。

- [ ] **Step 4: 跑测试**

Run: `flutter test test/features/weapon_codex/equipment_catalog_providers_test.dart 2>&1 | tail -3`
Expected: tests passed

- [ ] **Step 5: Commit**

```bash
git add lib/features/weapon_codex/application/equipment_catalog_providers.dart lib/features/weapon_codex/application/equipment_catalog_providers.g.dart test/features/weapon_codex/equipment_catalog_providers_test.dart
git commit -m "feat(weapon_codex): list/count providers + 测试"
```

---

## Task 8: 主屏 weapon_codex_screen

**Files:**
- Create: `lib/features/weapon_codex/presentation/weapon_codex_screen.dart`
- Test: `test/features/weapon_codex/weapon_codex_screen_test.dart`

- [ ] **Step 1: 写主屏**(ConsumerStatefulWidget,slot 筛选态;照 battle_record_screen 结构)

结构要点:
- `Scaffold(backgroundColor: WuxiaColors.background, appBar: WuxiaTitleBar(title: UiStrings.weaponCodexTitle, onBack: ...))`
- watch `equipmentCatalogListProvider`(AsyncValue,`.when` loading/error/data)
- data 段:
  - `acquired = {for (e in entries) e.defId}`(Set)——已点亮集合
  - 守 `GameRepository.isLoaded`,`defs = GameRepository.instance.equipmentDefs.values`
  - slot 筛选态 `_slot`(null=全部),顶部 chips 行(全部/兵器/护甲/饰品),`filtered = _slot==null ? defs : defs.where((d)=>d.slot==_slot)`
  - 总进度:`UiStrings.weaponCodexProgress(filtered.where((d)=>acquired.contains(d.id)).length, filtered.length)`
  - 按 tier 分组(照 baike _LoreTab byTier 体例,`EquipmentTier.values` 顺序),每档标题带 `weaponCodexTierProgress`
  - 每 def 卡:`acquired.contains(def.id)` ? 点亮卡(图标 `def.iconPath` + `def.name` + tier 色边,onTap→push detail) : 剪影卡(`_ShadowCard`:水墨色块 + `UiStrings.weaponCodexLockedItem`,onTap→SnackBar `weaponCodexNotObtained`)
- 点亮卡导航:
```dart
onTap: () => Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => EquipmentCatalogDetailScreen(
    def: def, entry: entryMap[def.id]!),
));
```
其中 `entryMap = {for (e in entries) e.defId: e}`。

> 完整卡片/剪影/分组 widget 照 `battle_record_screen.dart` 的 `_BossGroup`/`_ShadowTile` 体例改写(tier 分组 + IntrinsicHeight 包裹,守 WuxiaPaperPanel 滚动列约定)。

- [ ] **Step 2: 写 widget 测**(testWidgets;扩 viewport 防 ListView 截断:`setSurfaceSize(Size(800,2000))`+addTearDown)

```dart
// 测 1:给 catalog 注入部分点亮 → 已点亮 def 显名字,未点亮显 weaponCodexLockedItem 剪影
// 测 2:点 slot=兵器 chip → 只剩 weapon 部位卡
// (用 ProviderScope override equipmentCatalogListProvider 注入固定 entries;GameRepository 需 loadAllDefs 或 mock)
```

> GameRepository 加载:照其它依赖 def 的 widget 测体例(setUpAll loadAllDefs)。

- [ ] **Step 3: 跑测试**

Run: `flutter test test/features/weapon_codex/weapon_codex_screen_test.dart 2>&1 | tail -5`
Expected: tests passed

- [ ] **Step 4: analyze + Commit**

```bash
flutter analyze lib/features/weapon_codex/ 2>&1 | tail -3
git add lib/features/weapon_codex/presentation/weapon_codex_screen.dart test/features/weapon_codex/weapon_codex_screen_test.dart
git commit -m "feat(weapon_codex): 主屏 tier 分组 + 剪影/点亮 + slot 筛选"
```

---

## Task 9: 详情屏 equipment_catalog_detail_screen

**Files:**
- Create: `lib/features/weapon_codex/presentation/equipment_catalog_detail_screen.dart`
- Test: `test/features/weapon_codex/equipment_catalog_detail_screen_test.dart`

- [ ] **Step 1: 写详情屏**(StatelessWidget,接 `EquipmentDef def` + `EquipmentCatalogEntry entry`;照 boss_memory_detail_screen)

结构:
- `Scaffold + WuxiaTitleBar(title: def.name)`,body `ListView`
- 静态档案 PaperPanel:detail 大图(`def.detailPath ?? def.iconPath`,**Image.asset 必加 errorBuilder** 退化)/ tier(`EnumL10n.equipmentTier(def.tier)`)/ 部位 / 属性范围(`def.baseAttackMin~Max` 等)/ schoolBias(有则显)/ 开锋候选技(`def.specialSkillCandidates`)/ 师承遗物(`def.isLineageHeritage` 时显说明)
- 个人历程 PaperPanel:
```dart
if (entry.isPreRecord || entry.firstObtainedAt == null)
  Text(UiStrings.weaponCodexHistoryUnknown)  // 来历已不可考
else ...[
  Text(UiStrings.weaponCodexFirstObtainedFrom(entry.firstObtainedFrom)),
  Text(UiStrings.weaponCodexFirstObtainedAt(_fmtDate(entry.firstObtainedAt!))),
],
Text(UiStrings.weaponCodexObtainedCount(entry.obtainedCount)),
```

- [ ] **Step 2: 写 widget 测**(双态:正常 entry 显来源+日期;preRecord entry 显「来历已不可考」)

```dart
// 测 1:正常 entry → 找到 weaponCodexFirstObtainedFrom 文本
// 测 2:isPreRecord entry → 找到 weaponCodexHistoryUnknown,不显日期
// def 用 GameRepository 真 def 或构造最小 EquipmentDef fixture
```

- [ ] **Step 3: 跑测试**

Run: `flutter test test/features/weapon_codex/equipment_catalog_detail_screen_test.dart 2>&1 | tail -5`
Expected: tests passed

- [ ] **Step 4: analyze + Commit**

```bash
flutter analyze lib/features/weapon_codex/ 2>&1 | tail -3
git add lib/features/weapon_codex/presentation/equipment_catalog_detail_screen.dart test/features/weapon_codex/equipment_catalog_detail_screen_test.dart
git commit -m "feat(weapon_codex): 详情屏 静态档案 + 个人历程双态"
```

---

## Task 10: 主菜单入口 + 解锁门控

**Files:**
- Modify: `lib/features/main_menu/presentation/main_menu.dart`(jianghuItems 区 + 门控区,照战绩册 main_menu.dart:161,333)

- [ ] **Step 1: 加门控判定**(战绩册 bossCount 判定附近)

```dart
final weaponCodexCount = ref
    .watch(equipmentCatalogCountProvider)
    .maybeWhen(data: (n) => n, orElse: () => 0);
final weaponCodexUnlocked = weaponCodexCount > 0;
```

- [ ] **Step 2: 加入口按钮**(战绩册入口附近 jianghuItems)

```dart
if (weaponCodexUnlocked)
  WuxiaInkButton(
    label: UiStrings.mainMenuWeaponCodex,
    hint: UiStrings.mainMenuWeaponCodexHint,
    icon: Icons.auto_stories_outlined,
    onTap: () => _push(context, const WeaponCodexScreen()),
  ),
```

顶部 import providers + screen。

- [ ] **Step 3: analyze + 全量 test**

Run: `flutter analyze 2>&1 | tail -3 && flutter test 2>&1 | tail -8`
Expected: `No issues found!` + 全量零回归

- [ ] **Step 4: Commit**

```bash
git add lib/features/main_menu/presentation/main_menu.dart
git commit -m "feat(weapon_codex): 主菜单入口 + 获得任一装备解锁"
```

---

## Task 11: VISUAL_ROUTE 验收路由(真机目检用)

**Files:**
- Modify: `lib/features/debug/application/visual_route.dart`(加 route 常量)
- Modify: `lib/features/debug/presentation/visual_route_host.dart`(加 case:`weapon_codex` 主屏 + `weapon_codex_detail` 详情屏,注入 mock 点亮态)

- [ ] **Step 1: 加两个路由**(照 battle_record/boss_memory_detail 路由体例,visual_route_host 内构造混合点亮态 + 一条 preRecord entry override provider)

- [ ] **Step 2: build + 自截**

Run: `flutter run -d macos --dart-define=VISUAL_ROUTE=weapon_codex`(主屏)/ `=weapon_codex_detail`(详情屏),截 720p/1080p,Read 自验:剪影/点亮混排、tier 分组进度、slot 筛选、详情双态(正常/来历不详)无溢出。

- [ ] **Step 3: Commit**

```bash
git add lib/features/debug/
git commit -m "feat(weapon_codex): VISUAL_ROUTE 验收路由"
```

---

## 收尾验证(全部 task 后)

- [ ] 全量 `flutter test 2>&1 | tail -8` 零回归(baseline 当前 2676 +1skip,记录净增)
- [ ] 全量 `flutter analyze 2>&1 | tail -3` = 0
- [ ] 红线套件 `flutter test test/redlines/ 2>&1 | tail -3`(若存在)全过——本功能纯展示层不应触动
- [ ] 真机目检 weapon_codex / weapon_codex_detail PASS
- [ ] 更新 PROGRESS.md 顶段(续33)

## 红线自检
- 纯收集/展示层:0 处改伤害公式/掉落 roll/min_tier/概率 ✓
- 文案全 UiStrings,无硬编码中文/网游词/% ✓
- hook best-effort try-catch,失败不打断获得主流程 ✓
- 离线/挂机不触动(reconcile 在 load 兜底,不依赖墙钟) ✓
- saveVer 0.27.0,旧档空 + reconcile 回填 ✓
