# 主线三 · 掉落传闻 UI 实装计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 给主线关卡 + 爬塔层加「掉落传闻」展示(卡片简版「可能收获」一行 + info 角标弹水墨 PaperDialog 分组列),只读现有 `dropTable` 派生玩家侧稀有度桶,不动 schema / 掉落逻辑 / 奖励经济。

**Architecture:** 新建独立 feature `lib/features/loot_preview/`：纯函数桶映射(`domain/drop_rumor.dart`)+ 薄名称解析(`domain/drop_name_resolver.dart`,复用现有 `GameRepository`/`EnumL10n`)+ 两个 presentation widget(dialog + summary line)。接入 `stage_list_screen`(`isFirstClearGated:false`)与 `tower_floor_card`(`isFirstClearGated:true`)。

**Tech Stack:** Flutter Desktop / Riverpod 3.x / Isar / `flutter test`。设计源 `docs/spec/2026-06-18-phase5-mainline3-loot-rumors-design.md`。

---

## 关键事实(实装时直接用 · 已核实 file:line)

- `DropEntry` sealed（`lib/data/defs/drop_entry.dart`）：`EquipmentDrop{String equipmentDefId, double dropChance}` / `ItemDrop{String inventoryItemDefId, int quantityMin, int quantityMax, double dropChance}`。
- `EquipmentTier`（`enums.dart:61`）：`xunChang < xiangYang < haoJiaHuo < liQi < zhongQi < baoWu < shenWu`（7 阶，`.index` 升序）。
- `RealmTier`（`enums.dart:22`）：`xueTu < sanLiu < erLiu < yiLiu < jueDing < zongShi < wuSheng`（7 阶）。三系锁死：装备可用 ⇔ `equipmentTier.index <= realmTier.index`（`equipment.dart:107`）。
- `StageDef`（`stage_def.dart`）：`List<DropEntry> dropTable`（:39）/ `RealmTier requiredRealm`（:18）/ `int? chapterIndex`（:16）。
- `TowerFloorDef`（`lib/features/tower/domain/tower_floor_def.dart`）：`List<DropEntry> dropTable`（:47）/ `int floorIndex`（:26）/ `RealmTier requiredRealm`（:29）。
- 名称解析（`stage_victory_dialog.dart:214-256` 体例）：
  - guard：`if (!GameRepository.isLoaded) return rawDefId;`
  - 装备：`GameRepository.instance.getEquipment(defId).name` + 阶名 `EnumL10n.equipmentTier(def.tier)` + 阶色 `tierColorForEquipment(def.tier)`。
  - 物品：`EnumL10n.itemType(ItemType.fromDefId(defId))`（未知 defId 兜底 `miscMaterial`，`enums.dart:341`）。
- 弹窗：`PaperDialog.show<T>(context, title:, body:, actions:)`（`lib/shared/widgets/wuxia_ui/paper_dialog.dart`），maxWidth 420。
- 当前主修角色境界：`activeCharacterIds` provider（`character_providers.dart:42`）首个 id → `characterByIdProvider(id)` → `Character.realmTier`。**dialog 不直接读 provider**：接入层 watch 后把 `RealmTier? currentRealm` 传进去（dialog 保持纯/可测；null 时跳过越阶提示）。
- 关卡 tap → `runStageFlow`（`stage_list_screen.dart:92`，行为不变）；塔层 tap → 确认 dialog（`tower_floor_card.dart:93`，行为不变）。

## 文件结构

| 文件 | 职责 |
|---|---|
| `lib/features/loot_preview/domain/drop_rumor.dart`（新建） | `DropRumorBucket` enum + `bucketOf` + `DropRumorEntry` + `DropRumorTable`（fromDropTable/grouped/topRepresentatives）。纯 Dart 无 Flutter。 |
| `lib/features/loot_preview/domain/drop_name_resolver.dart`（新建） | 薄封装：装备名/物品名/装备阶/越阶判定，复用现有 repo+EnumL10n，repo 未加载降级 raw defId。 |
| `lib/features/loot_preview/presentation/loot_rumor_dialog.dart`（新建） | info 角标点击弹的分组列 dialog（含越阶提示 + tower 脚注 + 空态）。 |
| `lib/features/loot_preview/presentation/loot_summary_line.dart`（新建） | 卡片简版「可能收获：X · Y · Z」一行 + info 角标。 |
| `lib/shared/strings.dart`（改） | 新增 10 条 `UiStrings` 词条。 |
| `lib/features/mainline/presentation/stage_list_screen.dart`（改） | `_StageRow` 接入简版行 + info 角标。 |
| `lib/features/tower/presentation/tower_floor_card.dart`（改） | 接入简版行 + info 角标（`isFirstClearGated:true`）。 |
| `test/features/loot_preview/*`（新建） | 纯函数测 + 数据完整性测 + 越阶守卫测 + 白名单测 + widget 测。 |

---

## Task 0: worktree 环境就绪(无 commit)

- [ ] **Step 1: build_runner 重建 .g.dart（worktree 内 gitignored）**

Run:
```bash
cd /Users/a10506/Desktop/Projects/挂机武侠/.claude/worktrees/phase5-mainline3-loot-rumors
dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -5
```
Expected: `Succeeded` 收尾，无 error。

- [ ] **Step 2: 校验 isar dylib 完整（fresh worktree 可能截断）+ baseline**

Run:
```bash
flutter test test/data/passive_idle_config_test.dart 2>&1 | tail -3
```
Expected: `All tests passed!`。若报 `libisar.dylib` dlopen 失败 → 从主仓拷：`cp ../../../`（主 checkout 路径）下完整 dylib（参照 memory `feedback_fresh_worktree_libisar_dylib`）。

---

## Task 1: DropRumorBucket + bucketOf 纯函数

**Files:**
- Create: `lib/features/loot_preview/domain/drop_rumor.dart`
- Test: `test/features/loot_preview/drop_rumor_bucket_test.dart`

- [ ] **Step 1: 写失败测**

```dart
// test/features/loot_preview/drop_rumor_bucket_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/features/loot_preview/domain/drop_rumor.dart';

void main() {
  group('bucketOf · 主线上下文(isFirstClearGated=false)', () {
    test('1.0 → 常可得', () {
      expect(bucketOf(1.0, isFirstClearGated: false), DropRumorBucket.changKeDe);
    });
    test('0.99 / 0.30 → 偶可得（>=0.30 闭下界）', () {
      expect(bucketOf(0.99, isFirstClearGated: false), DropRumorBucket.ouKeDe);
      expect(bucketOf(0.30, isFirstClearGated: false), DropRumorBucket.ouKeDe);
    });
    test('0.2999 / 0.08 → 少有人得（>=0.08 闭下界）', () {
      expect(bucketOf(0.2999, isFirstClearGated: false), DropRumorBucket.shaoYouRenDe);
      expect(bucketOf(0.08, isFirstClearGated: false), DropRumorBucket.shaoYouRenDe);
    });
    test('0.0799 → 江湖传闻', () {
      expect(bucketOf(0.0799, isFirstClearGated: false), DropRumorBucket.jiangHuChuanWen);
    });
  });

  group('bucketOf · 塔层上下文(isFirstClearGated=true)', () {
    test('1.0 → 首通必得（取代常可得）', () {
      expect(bucketOf(1.0, isFirstClearGated: true), DropRumorBucket.shouTongBiDe);
    });
    test('<1.0 仍按概率分桶', () {
      expect(bucketOf(0.30, isFirstClearGated: true), DropRumorBucket.ouKeDe);
      expect(bucketOf(0.08, isFirstClearGated: true), DropRumorBucket.shaoYouRenDe);
      expect(bucketOf(0.05, isFirstClearGated: true), DropRumorBucket.jiangHuChuanWen);
    });
  });
}
```

- [ ] **Step 2: 跑测确认失败**

Run: `flutter test test/features/loot_preview/drop_rumor_bucket_test.dart`
Expected: 编译失败（`drop_rumor.dart` 不存在 / `bucketOf` 未定义）。

- [ ] **Step 3: 写最小实现**

```dart
// lib/features/loot_preview/domain/drop_rumor.dart
/// 玩家侧掉落「传闻」稀有度桶（GDD §2.1 反主流：不用传奇/SSR 等网游词）。
/// 纯由 dropChance + 是否首通门控派生，不引入 DropEntry schema 字段。
enum DropRumorBucket {
  shouTongBiDe, // 首通必得（仅首通门控上下文 + dropChance==1.0）
  changKeDe,    // 常可得（非门控 + dropChance==1.0）
  ouKeDe,       // 偶可得（>=0.30）
  shaoYouRenDe, // 少有人得（>=0.08）
  jiangHuChuanWen, // 江湖传闻（<0.08）
}

/// 桶映射规则（设计 §2）。判定顺序：首条命中即返回。
DropRumorBucket bucketOf(double dropChance, {required bool isFirstClearGated}) {
  if (dropChance >= 1.0) {
    return isFirstClearGated
        ? DropRumorBucket.shouTongBiDe
        : DropRumorBucket.changKeDe;
  }
  if (dropChance >= 0.30) return DropRumorBucket.ouKeDe;
  if (dropChance >= 0.08) return DropRumorBucket.shaoYouRenDe;
  return DropRumorBucket.jiangHuChuanWen;
}
```

- [ ] **Step 4: 跑测确认通过**

Run: `flutter test test/features/loot_preview/drop_rumor_bucket_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/loot_preview/domain/drop_rumor.dart test/features/loot_preview/drop_rumor_bucket_test.dart
git commit -m "主线三:加 DropRumorBucket 桶映射纯函数 + 边界测"
```

---

## Task 2: DropRumorEntry + DropRumorTable

**Files:**
- Modify: `lib/features/loot_preview/domain/drop_rumor.dart`（追加）
- Test: `test/features/loot_preview/drop_rumor_table_test.dart`

- [ ] **Step 1: 写失败测**

```dart
// test/features/loot_preview/drop_rumor_table_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/features/loot_preview/domain/drop_rumor.dart';

void main() {
  final table = <DropEntry>[
    const EquipmentDrop(equipmentDefId: 'weapon_a', dropChance: 1.0),
    const EquipmentDrop(equipmentDefId: 'weapon_b', dropChance: 0.30),
    const ItemDrop(
      inventoryItemDefId: 'item_mojianshi',
      quantityMin: 1,
      quantityMax: 3,
      dropChance: 0.05,
    ),
  ];

  test('fromDropTable 映射类型 + 桶（主线）', () {
    final t = DropRumorTable.fromDropTable(table, isFirstClearGated: false);
    expect(t.entries.length, 3);
    expect(t.entries[0].defId, 'weapon_a');
    expect(t.entries[0].isEquipment, true);
    expect(t.entries[0].bucket, DropRumorBucket.changKeDe);
    expect(t.entries[1].bucket, DropRumorBucket.ouKeDe);
    expect(t.entries[2].isEquipment, false);
    expect(t.entries[2].bucket, DropRumorBucket.jiangHuChuanWen);
  });

  test('grouped 按桶排序（首通必得/常可得 → 偶可得 → 少有人得 → 江湖传闻）', () {
    final g = DropRumorTable.fromDropTable(table, isFirstClearGated: false).grouped();
    expect(g.keys.first, DropRumorBucket.changKeDe);
    expect(g.keys.last, DropRumorBucket.jiangHuChuanWen);
  });

  test('topRepresentatives 取最高桶 N 个', () {
    final reps = DropRumorTable.fromDropTable(table, isFirstClearGated: false)
        .topRepresentatives(2);
    expect(reps.length, 2);
    expect(reps[0].defId, 'weapon_a'); // 常可得优先
    expect(reps[1].defId, 'weapon_b'); // 偶可得次之
  });

  test('空表 isEmpty=true', () {
    expect(
      DropRumorTable.fromDropTable(const [], isFirstClearGated: false).isEmpty,
      true,
    );
  });

  test('塔层 1.0 → 首通必得', () {
    final t = DropRumorTable.fromDropTable(table, isFirstClearGated: true);
    expect(t.entries[0].bucket, DropRumorBucket.shouTongBiDe);
  });
}
```

- [ ] **Step 2: 跑测确认失败**

Run: `flutter test test/features/loot_preview/drop_rumor_table_test.dart`
Expected: 编译失败（`DropRumorTable` 未定义）。

- [ ] **Step 3: 写实现（追加到 drop_rumor.dart 末尾）**

```dart
// lib/features/loot_preview/domain/drop_rumor.dart（追加；顶部加 import）
// import 'package:wuxia_idle/data/defs/drop_entry.dart';  // 注意改成相对路径 ../../../data/defs/drop_entry.dart

/// 桶展示优先级（高 → 低）：grouped 与 topRepresentatives 共用。
const List<DropRumorBucket> _bucketDisplayOrder = [
  DropRumorBucket.shouTongBiDe,
  DropRumorBucket.changKeDe,
  DropRumorBucket.ouKeDe,
  DropRumorBucket.shaoYouRenDe,
  DropRumorBucket.jiangHuChuanWen,
];

class DropRumorEntry {
  final String defId;
  final bool isEquipment;
  final DropRumorBucket bucket;

  const DropRumorEntry({
    required this.defId,
    required this.isEquipment,
    required this.bucket,
  });
}

class DropRumorTable {
  final List<DropRumorEntry> entries;
  final bool isFirstClearGated;

  const DropRumorTable({
    required this.entries,
    required this.isFirstClearGated,
  });

  bool get isEmpty => entries.isEmpty;

  factory DropRumorTable.fromDropTable(
    List<DropEntry> table, {
    required bool isFirstClearGated,
  }) {
    final entries = <DropRumorEntry>[];
    for (final e in table) {
      final bucket = bucketOf(e.dropChance, isFirstClearGated: isFirstClearGated);
      switch (e) {
        case EquipmentDrop(:final equipmentDefId):
          entries.add(DropRumorEntry(
            defId: equipmentDefId,
            isEquipment: true,
            bucket: bucket,
          ));
        case ItemDrop(:final inventoryItemDefId):
          entries.add(DropRumorEntry(
            defId: inventoryItemDefId,
            isEquipment: false,
            bucket: bucket,
          ));
      }
    }
    return DropRumorTable(entries: entries, isFirstClearGated: isFirstClearGated);
  }

  /// 按桶分组，桶顺序固定为展示优先级；空桶不出现。entry 原序保留。
  Map<DropRumorBucket, List<DropRumorEntry>> grouped() {
    final map = <DropRumorBucket, List<DropRumorEntry>>{};
    for (final bucket in _bucketDisplayOrder) {
      final hits = entries.where((e) => e.bucket == bucket).toList();
      if (hits.isNotEmpty) map[bucket] = hits;
    }
    return map;
  }

  /// 简版代表：按桶优先级展平，取前 n（默认 3）。
  List<DropRumorEntry> topRepresentatives(int n) {
    final flat = <DropRumorEntry>[];
    for (final bucket in _bucketDisplayOrder) {
      flat.addAll(entries.where((e) => e.bucket == bucket));
    }
    return flat.take(n).toList();
  }
}
```

> 注：import 用项目相对路径风格（参照同目录其他 feature），`package:` 仅测试文件用。

- [ ] **Step 4: 跑测确认通过**

Run: `flutter test test/features/loot_preview/drop_rumor_table_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/loot_preview/domain/drop_rumor.dart test/features/loot_preview/drop_rumor_table_test.dart
git commit -m "主线三:加 DropRumorTable fromDropTable/grouped/topRepresentatives"
```

---

## Task 3: UiStrings 词条

**Files:**
- Modify: `lib/shared/strings.dart`（在文件末尾 `}` 前追加；定位现有 `stageVictoryDropLabel` 附近同风格）
- Test: `test/features/loot_preview/loot_strings_whitelist_test.dart`

- [ ] **Step 1: 写白名单失败测**

```dart
// test/features/loot_preview/loot_strings_whitelist_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/shared/strings.dart';

void main() {
  test('掉落传闻词条不含网游稀有词 + 不含百分号', () {
    final strings = [
      UiStrings.lootBucketChangKeDe,
      UiStrings.lootBucketOuKeDe,
      UiStrings.lootBucketShaoYouRenDe,
      UiStrings.lootBucketJiangHuChuanWen,
      UiStrings.lootBucketShouTongBiDe,
      UiStrings.lootSummaryPrefix,
      UiStrings.lootRumorDialogTitle,
      UiStrings.lootNoFixedDrop,
      UiStrings.lootAboveRealmHint,
      UiStrings.lootTowerFirstClearOnlyFooter,
    ];
    const banned = ['传奇', '史诗', 'SSR', 'SR', 'legendary', 'epic', '%'];
    for (final s in strings) {
      for (final b in banned) {
        expect(s.toLowerCase().contains(b.toLowerCase()), false,
            reason: '词条「$s」含禁用词「$b」');
      }
    }
  });
}
```

- [ ] **Step 2: 跑测确认失败**

Run: `flutter test test/features/loot_preview/loot_strings_whitelist_test.dart`
Expected: 编译失败（`UiStrings.lootBucketChangKeDe` 未定义）。

- [ ] **Step 3: 加词条（strings.dart，`class UiStrings` 内）**

```dart
  // === 主线三 · 掉落传闻 UI ===
  static const String lootBucketChangKeDe = '常可得';
  static const String lootBucketOuKeDe = '偶可得';
  static const String lootBucketShaoYouRenDe = '少有人得';
  static const String lootBucketJiangHuChuanWen = '江湖传闻';
  static const String lootBucketShouTongBiDe = '首通必得';
  static const String lootSummaryPrefix = '可能收获：';
  static const String lootRumorDialogTitle = '本关传闻';
  static const String lootNoFixedDrop = '本关无固定收获';
  static const String lootAboveRealmHint = '机缘可遇，火候未到';
  static const String lootTowerFirstClearOnlyFooter = '塔层传闻仅首通可得，错过不补';
```

- [ ] **Step 4: 跑测确认通过**

Run: `flutter test test/features/loot_preview/loot_strings_whitelist_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/shared/strings.dart test/features/loot_preview/loot_strings_whitelist_test.dart
git commit -m "主线三:加掉落传闻 UiStrings 词条 + 白名单测"
```

---

## Task 4: drop_name_resolver

**Files:**
- Create: `lib/features/loot_preview/domain/drop_name_resolver.dart`
- Test: `test/features/loot_preview/drop_name_resolver_test.dart`

- [ ] **Step 1: 写失败测（只测 repo 未加载降级 + 越阶，避免依赖 Isar）**

```dart
// test/features/loot_preview/drop_name_resolver_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/loot_preview/domain/drop_name_resolver.dart';

void main() {
  test('repo 未加载 → 装备名降级 raw defId、阶为 null', () {
    // GameRepository 未 load（轻量测无 Isar）。
    expect(DropNameResolver.equipmentName('weapon_x'), 'weapon_x');
    expect(DropNameResolver.equipmentTier('weapon_x'), isNull);
  });

  test('物品名走 EnumL10n（known→磨剑石 / unknown→杂项材料）', () {
    expect(DropNameResolver.itemName('item_mojianshi'), '磨剑石');
    expect(DropNameResolver.itemName('item_unknown_xyz'), '杂项材料');
  });

  test('isAboveRealm：tier.index > currentRealm.index', () {
    // shenWu(6) > sanLiu(1) → true
    expect(DropNameResolver.isAboveRealm(EquipmentTier.shenWu, RealmTier.sanLiu), true);
    // xunChang(0) <= wuSheng(6) → false
    expect(DropNameResolver.isAboveRealm(EquipmentTier.xunChang, RealmTier.wuSheng), false);
  });
}
```

- [ ] **Step 2: 跑测确认失败**

Run: `flutter test test/features/loot_preview/drop_name_resolver_test.dart`
Expected: 编译失败（`DropNameResolver` 未定义）。

- [ ] **Step 3: 写实现**

```dart
// lib/features/loot_preview/domain/drop_name_resolver.dart
import '../../../core/domain/enums.dart';
import '../../battle/domain/enum_localizations.dart';
import '../../../data/game_repository.dart';

/// 薄封装 defId → 显示名 / 阶 / 越阶判定。复用 victory dialog 同源解析，
/// `GameRepository` 未加载时降级 raw defId（护轻量 widget 测）。
abstract final class DropNameResolver {
  static String equipmentName(String defId) {
    if (!GameRepository.isLoaded) return defId;
    return GameRepository.instance.getEquipment(defId).name;
  }

  static EquipmentTier? equipmentTier(String defId) {
    if (!GameRepository.isLoaded) return null;
    return GameRepository.instance.getEquipment(defId).tier;
  }

  static String itemName(String defId) =>
      EnumL10n.itemType(ItemType.fromDefId(defId));

  static bool isAboveRealm(EquipmentTier tier, RealmTier currentRealm) =>
      tier.index > currentRealm.index;
}
```

> 校验 import 路径：`GameRepository` 在 `lib/data/game_repository.dart`；`EnumL10n`/`ItemType` 分别在 `enum_localizations.dart`/`enums.dart`。

- [ ] **Step 4: 跑测确认通过**

Run: `flutter test test/features/loot_preview/drop_name_resolver_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/loot_preview/domain/drop_name_resolver.dart test/features/loot_preview/drop_name_resolver_test.dart
git commit -m "主线三:加 DropNameResolver 薄名称/阶/越阶解析 + 降级测"
```

---

## Task 5: loot_rumor_dialog

**Files:**
- Create: `lib/features/loot_preview/presentation/loot_rumor_dialog.dart`
- Test: `test/features/loot_preview/loot_rumor_dialog_test.dart`

- [ ] **Step 1: 写 widget 失败测（repo 未加载降级路径，setSurfaceSize 扩 viewport）**

```dart
// test/features/loot_preview/loot_rumor_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/features/loot_preview/domain/drop_rumor.dart';
import 'package:wuxia_idle/features/loot_preview/presentation/loot_rumor_dialog.dart';
import 'package:wuxia_idle/shared/strings.dart';

Widget _host(Widget body) => MaterialApp(home: Scaffold(body: body));

void main() {
  testWidgets('空表显「本关无固定收获」', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_host(LootRumorContent(
      table: DropRumorTable.fromDropTable(const [], isFirstClearGated: false),
      currentRealm: RealmTier.sanLiu,
    )));
    expect(find.text(UiStrings.lootNoFixedDrop), findsOneWidget);
  });

  testWidgets('分组列渲染桶名 + 无 % 文本', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final table = DropRumorTable.fromDropTable(const [
      EquipmentDrop(equipmentDefId: 'weapon_a', dropChance: 1.0),
      ItemDrop(inventoryItemDefId: 'item_mojianshi', quantityMin: 1, quantityMax: 1, dropChance: 0.05),
    ], isFirstClearGated: false);
    await tester.pumpWidget(_host(LootRumorContent(table: table, currentRealm: RealmTier.sanLiu)));
    expect(find.text(UiStrings.lootBucketChangKeDe), findsOneWidget);
    expect(find.text(UiStrings.lootBucketJiangHuChuanWen), findsOneWidget);
    // 无百分比
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('塔层上下文显脚注', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final table = DropRumorTable.fromDropTable(const [
      EquipmentDrop(equipmentDefId: 'weapon_a', dropChance: 1.0),
    ], isFirstClearGated: true);
    await tester.pumpWidget(_host(LootRumorContent(table: table, currentRealm: RealmTier.sanLiu)));
    expect(find.text(UiStrings.lootTowerFirstClearOnlyFooter), findsOneWidget);
    expect(find.text(UiStrings.lootBucketShouTongBiDe), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测确认失败**

Run: `flutter test test/features/loot_preview/loot_rumor_dialog_test.dart`
Expected: 编译失败（`LootRumorContent` 未定义）。

- [ ] **Step 3: 写实现**

```dart
// lib/features/loot_preview/presentation/loot_rumor_dialog.dart
import 'package:flutter/material.dart';

import '../../../core/domain/enums.dart';
import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/wuxia_ui/paper_dialog.dart';
import '../../equipment/domain/equipment_tier_color.dart'; // tierColorForEquipment（实装时确认路径，见下注）
import '../domain/drop_name_resolver.dart';
import '../domain/drop_rumor.dart';

const Map<DropRumorBucket, String> _bucketLabels = {
  DropRumorBucket.shouTongBiDe: UiStrings.lootBucketShouTongBiDe,
  DropRumorBucket.changKeDe: UiStrings.lootBucketChangKeDe,
  DropRumorBucket.ouKeDe: UiStrings.lootBucketOuKeDe,
  DropRumorBucket.shaoYouRenDe: UiStrings.lootBucketShaoYouRenDe,
  DropRumorBucket.jiangHuChuanWen: UiStrings.lootBucketJiangHuChuanWen,
};

/// 分组列正文（dialog body / 可独立测，不含 PaperDialog 外壳）。
class LootRumorContent extends StatelessWidget {
  const LootRumorContent({super.key, required this.table, this.currentRealm});

  final DropRumorTable table;
  final RealmTier? currentRealm;

  @override
  Widget build(BuildContext context) {
    if (table.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(UiStrings.lootNoFixedDrop),
      );
    }
    final grouped = table.grouped();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              _bucketLabels[entry.key]!,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: WuxiaColors.textMuted,
              ),
            ),
          ),
          for (final e in entry.value) _RumorItemRow(entry: e, currentRealm: currentRealm),
        ],
        if (table.isFirstClearGated)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              UiStrings.lootTowerFirstClearOnlyFooter,
              style: TextStyle(fontSize: 11, color: WuxiaColors.textMuted),
            ),
          ),
      ],
    );
  }
}

class _RumorItemRow extends StatelessWidget {
  const _RumorItemRow({required this.entry, this.currentRealm});

  final DropRumorEntry entry;
  final RealmTier? currentRealm;

  @override
  Widget build(BuildContext context) {
    final String name;
    Color? color;
    bool aboveRealm = false;
    if (entry.isEquipment) {
      name = DropNameResolver.equipmentName(entry.defId);
      final tier = DropNameResolver.equipmentTier(entry.defId);
      if (tier != null) {
        color = tierColorForEquipment(tier);
        if (currentRealm != null) {
          aboveRealm = DropNameResolver.isAboveRealm(tier, currentRealm!);
        }
      }
    } else {
      name = DropNameResolver.itemName(entry.defId);
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 2),
      child: Row(
        children: [
          Flexible(child: Text('· $name', style: TextStyle(color: color))),
          if (aboveRealm) ...[
            const SizedBox(width: 6),
            const Text(
              UiStrings.lootAboveRealmHint,
              style: TextStyle(fontSize: 11, color: WuxiaColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// 便捷弹窗：info 角标点击调用。
Future<void> showLootRumorDialog(
  BuildContext context, {
  required DropRumorTable table,
  RealmTier? currentRealm,
}) {
  return PaperDialog.show<void>(
    context,
    title: UiStrings.lootRumorDialogTitle,
    body: LootRumorContent(table: table, currentRealm: currentRealm),
    actions: const [],
  );
}
```

> **实装注**：① `tierColorForEquipment` 路径要现 grep 确认（`grep -rn "tierColorForEquipment\|Color tierColor" lib/`，victory dialog 已 import，照它的 import 写）。② `WuxiaColors.textMuted` 已在 stage_list_screen 用，路径 `shared/theme/colors.dart`。③ 若 `LootRumorContent` 在窄 PaperDialog（maxWidth 420）内分组多导致超高，正文外层在 dialog 调用处可包 `SingleChildScrollView`（PaperDialog body 接任意 widget）。④ const 拼接：`UiStrings.lootAboveRealmHint` 是 const String 可直接进 const Text。

- [ ] **Step 4: 跑测确认通过**

Run: `flutter test test/features/loot_preview/loot_rumor_dialog_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/loot_preview/presentation/loot_rumor_dialog.dart test/features/loot_preview/loot_rumor_dialog_test.dart
git commit -m "主线三:加 LootRumorContent 分组列 dialog + widget 测"
```

---

## Task 6: loot_summary_line

**Files:**
- Create: `lib/features/loot_preview/presentation/loot_summary_line.dart`
- Test: `test/features/loot_preview/loot_summary_line_test.dart`

- [ ] **Step 1: 写 widget 失败测**

```dart
// test/features/loot_preview/loot_summary_line_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/drop_entry.dart';
import 'package:wuxia_idle/features/loot_preview/domain/drop_rumor.dart';
import 'package:wuxia_idle/features/loot_preview/presentation/loot_summary_line.dart';
import 'package:wuxia_idle/shared/strings.dart';

Widget _host(Widget body) => MaterialApp(home: Scaffold(body: body));

void main() {
  testWidgets('空表显「本关无固定收获」', (tester) async {
    await tester.pumpWidget(_host(LootSummaryLine(
      table: DropRumorTable.fromDropTable(const [], isFirstClearGated: false),
    )));
    expect(find.textContaining(UiStrings.lootNoFixedDrop), findsOneWidget);
  });

  testWidgets('有掉落显前缀「可能收获：」+ 无 %', (tester) async {
    final table = DropRumorTable.fromDropTable(const [
      ItemDrop(inventoryItemDefId: 'item_mojianshi', quantityMin: 1, quantityMax: 1, dropChance: 1.0),
    ], isFirstClearGated: false);
    await tester.pumpWidget(_host(LootSummaryLine(table: table)));
    expect(find.textContaining(UiStrings.lootSummaryPrefix), findsOneWidget);
    expect(find.textContaining('磨剑石'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });
}
```

- [ ] **Step 2: 跑测确认失败**

Run: `flutter test test/features/loot_preview/loot_summary_line_test.dart`
Expected: 编译失败（`LootSummaryLine` 未定义）。

- [ ] **Step 3: 写实现**

```dart
// lib/features/loot_preview/presentation/loot_summary_line.dart
import 'package:flutter/material.dart';

import '../../../shared/strings.dart';
import '../../../shared/theme/colors.dart';
import '../domain/drop_name_resolver.dart';
import '../domain/drop_rumor.dart';

/// 卡片简版「可能收获：X · Y · Z」一行（最多 3 代表）。空表显无固定收获。
class LootSummaryLine extends StatelessWidget {
  const LootSummaryLine({super.key, required this.table, this.maxItems = 3});

  final DropRumorTable table;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    if (table.isEmpty) {
      return const Text(
        UiStrings.lootNoFixedDrop,
        style: TextStyle(fontSize: 12, color: WuxiaColors.textMuted),
      );
    }
    final reps = table.topRepresentatives(maxItems);
    final names = reps
        .map((e) => e.isEquipment
            ? DropNameResolver.equipmentName(e.defId)
            : DropNameResolver.itemName(e.defId))
        .join(' · ');
    return Text(
      '${UiStrings.lootSummaryPrefix}$names',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12, color: WuxiaColors.textMuted),
    );
  }
}
```

- [ ] **Step 4: 跑测确认通过**

Run: `flutter test test/features/loot_preview/loot_summary_line_test.dart`
Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/loot_preview/presentation/loot_summary_line.dart test/features/loot_preview/loot_summary_line_test.dart
git commit -m "主线三:加 LootSummaryLine 卡片简版收获行 + widget 测"
```

---

## Task 7: 数据完整性 + 越阶守卫测(test-only · 守红线)

**Files:**
- Test: `test/features/loot_preview/loot_data_integrity_test.dart`

> 此测加载真实 yaml（`GameRepository`），跑前确保 Task 0 build_runner 已就绪。参照现有 `test/data/game_repository_test.dart` 的加载体例（同目录找 `GameRepository.load` / setUpAll 写法照搬）。

- [ ] **Step 1: 先 grep 现有 yaml 加载体例**

Run:
```bash
grep -rn "GameRepository\|loadFromAssets\|setUpAll\|TestWidgetsFlutterBinding" test/data/game_repository_test.dart | head
```
照搬其 setUpAll / 加载方式（避免重造加载逻辑）。

- [ ] **Step 2: 写测（按上一步体例补全加载，断言如下）**

```dart
// test/features/loot_preview/loot_data_integrity_test.dart
// （顶部 import + setUpAll 加载 GameRepository，照 test/data/game_repository_test.dart 体例）
import 'package:flutter_test/flutter_test.dart';
// ... 加载相关 import ...

void main() {
  // setUpAll(() async { ...照搬体例加载 GameRepository... });

  test('每主线关 dropTable 非空（或显式标注无掉落）', () {
    // final stages = GameRepository.instance.allStages.where((s) => s.chapterIndex != null);
    // for (final s in stages) {
    //   expect(s.dropTable.isNotEmpty, true, reason: '${s.id} dropTable 为空');
    // }
  });

  test('每塔层 dropTable 非空', () {
    // for (final f in GameRepository.instance.allTowerFloors) {
    //   expect(f.dropTable.isNotEmpty, true, reason: 'floor ${f.floorIndex} dropTable 为空');
    // }
  });

  test('不越阶：dropTable 装备 tier.index <= requiredRealm.index', () {
    // for (final s in GameRepository.instance.allStages) {
    //   for (final e in s.dropTable.whereType<EquipmentDrop>()) {
    //     final def = GameRepository.instance.getEquipment(e.equipmentDefId);
    //     expect(def.tier.index <= s.requiredRealm.index, true,
    //         reason: '${s.id} 掉落 ${def.id} tier 越阶');
    //   }
    // }
  });
}
```

> **实装注**：上面注释体的精确 API（`allStages` / `allTowerFloors` / 遍历入口）要现 grep `game_repository.dart` 确认真实 getter 名再填实（不要照搬注释占位）。若发现某关 dropTable 确为空但设计上「无固定掉落」，把该关 id 加入测内显式白名单并注释原因（spec 4.5「或显式标注无掉落」）。

- [ ] **Step 3: 跑测**

Run: `flutter test test/features/loot_preview/loot_data_integrity_test.dart`
Expected: `All tests passed!`（若越阶/空表暴露真实数据问题 → 停下报告人类，不擅自改 yaml 数值；按 §10 拿不准停下问）。

- [ ] **Step 4: Commit**

```bash
git add test/features/loot_preview/loot_data_integrity_test.dart
git commit -m "主线三:加掉落传闻数据完整性 + 不越阶守卫测"
```

---

## Task 8: 接入 stage_list_screen `_StageRow`

**Files:**
- Modify: `lib/features/mainline/presentation/stage_list_screen.dart`（`_StageRow` build + 把 stage 传进去）
- Test: `test/features/loot_preview/stage_row_loot_wiring_test.dart`（或扩现有 stage_list 测）

- [ ] **Step 1: 先读 `_StageRow` 现状 + 怎么拿当前 realm**

Run:
```bash
sed -n '283,402p' lib/features/mainline/presentation/stage_list_screen.dart
grep -rn "realmTier\|activeCharacterIds\|characterById" lib/features/mainline/presentation/stage_list_screen.dart
```
确认 `_StageRow` 是否已有 `StageDef`（看 onTap 处 `entries[i]` 是否带 def）；当前 realm 用 `activeCharacterIds`→首个→`characterByIdProvider`→`.realmTier`（接入处 watch，传 `RealmTier?`，拿不到传 null）。

- [ ] **Step 2: 写 widget 测（简版行出现 + info 角标 tap 弹 dialog）**

```dart
// test/features/loot_preview/stage_row_loot_wiring_test.dart
// 构造一个带 dropTable 的 StageDef fixture，pump _StageRow（若 _StageRow 私有，
// 测可改为 pump StageListScreen 并 override chapterStagesProvider；
// 体例照搬现有 stage_list 相关 widget 测）。断言：
//   - find.textContaining(UiStrings.lootSummaryPrefix) findsOneWidget
//   - tap info icon → find.text(UiStrings.lootRumorDialogTitle) findsOneWidget
```

> 实装注：先 grep `test/` 下是否已有 stage_list_screen 的 widget 测可扩；`_StageRow` 私有则走 screen 级 + provider override（参照现有体例）。

- [ ] **Step 3: 跑测确认失败**

Run: `flutter test test/features/loot_preview/stage_row_loot_wiring_test.dart`
Expected: FAIL（简版行未渲染）。

- [ ] **Step 4: 改 `_StageRow`：加简版行 + info 角标**

在 `_StageRow` 内（需把 `StageDef stage` 与 `RealmTier? currentRealm` 传入，build 出的 `_StageRow(...)` 处补参数）：
```dart
// 在状态徽章行下方插入：
final rumor = DropRumorTable.fromDropTable(stage.dropTable, isFirstClearGated: false);
// ... Row 末尾或副标题区：
LootSummaryLine(table: rumor),
// info 角标（IconButton，紧凑）：
IconButton(
  icon: const Icon(Icons.info_outline, size: 16),
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints(),
  tooltip: UiStrings.lootRumorDialogTitle,
  onPressed: () => showLootRumorDialog(context, table: rumor, currentRealm: currentRealm),
),
```
顶部加 import：
```dart
import '../../loot_preview/domain/drop_rumor.dart';
import '../../loot_preview/presentation/loot_rumor_dialog.dart';
import '../../loot_preview/presentation/loot_summary_line.dart';
```
`StageListScreen.build` 处 watch 当前 realm 并下传到 `_StageRow`（`activeCharacterIds` → 首个 → `characterByIdProvider`；async 未就绪传 null）。

- [ ] **Step 5: 跑测确认通过 + 改动文件全 analyze**

Run:
```bash
flutter test test/features/loot_preview/stage_row_loot_wiring_test.dart
flutter analyze lib/features/mainline lib/features/loot_preview
```
Expected: 测 PASS；analyze `No issues found!`。

- [ ] **Step 6: Commit**

```bash
git add lib/features/mainline/presentation/stage_list_screen.dart test/features/loot_preview/stage_row_loot_wiring_test.dart
git commit -m "主线三:stage_list 关卡卡片接入掉落传闻简版行 + info 角标"
```

---

## Task 9: 接入 tower_floor_card

**Files:**
- Modify: `lib/features/tower/presentation/tower_floor_card.dart`
- Test: `test/features/loot_preview/tower_card_loot_wiring_test.dart`

- [ ] **Step 1: 读 tower_floor_card 现状（卡片主体在哪、是否带 TowerFloorDef、怎么拿 realm）**

Run:
```bash
sed -n '140,260p' lib/features/tower/presentation/tower_floor_card.dart
grep -rn "TowerFloorDef\|realmTier\|activeCharacterIds" lib/features/tower/presentation/tower_floor_card.dart
```

- [ ] **Step 2: 写 widget 测（同 Task 8，但 `isFirstClearGated:true` → 弹 dialog 显首通必得/脚注）**

```dart
// test/features/loot_preview/tower_card_loot_wiring_test.dart
// 构造带 dropTable(含 1.0 项) 的 TowerFloorDef fixture，pump 卡片；断言：
//   - 简版行出现
//   - tap info → dialog 显 UiStrings.lootTowerFirstClearOnlyFooter
```

- [ ] **Step 3: 跑测确认失败**

Run: `flutter test test/features/loot_preview/tower_card_loot_wiring_test.dart`
Expected: FAIL。

- [ ] **Step 4: 改 tower_floor_card：同 Task 8 模式，`isFirstClearGated: true`**

```dart
final rumor = DropRumorTable.fromDropTable(floor.dropTable, isFirstClearGated: true);
// 简版行 LootSummaryLine(table: rumor) + info 角标 showLootRumorDialog(..., table: rumor, currentRealm: currentRealm)
```
import 同 Task 8 三行（路径相对 tower 目录调整为 `../../loot_preview/...`）。

- [ ] **Step 5: 跑测 + analyze**

Run:
```bash
flutter test test/features/loot_preview/tower_card_loot_wiring_test.dart
flutter analyze lib/features/tower lib/features/loot_preview
```
Expected: PASS + `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/features/tower/presentation/tower_floor_card.dart test/features/loot_preview/tower_card_loot_wiring_test.dart
git commit -m "主线三:tower 塔层卡片接入掉落传闻(首通必得上下文)"
```

---

## Task 10: 全量验证 + 文档收尾

**Files:**
- Modify: `docs/spec/phase5_battle_experience_loot_spec_2026-06-17.md`（§4.3 去「⚠️ 待拍板」标记 B 决议）
- Modify: `PROGRESS.md`（顶段新增续22 一段）

- [ ] **Step 1: 全量 analyze**

Run: `flutter analyze`
Expected: `No issues found!`（不止 scoped，守 memory `feedback_verify_full_ci_not_scoped_lint`）。

- [ ] **Step 2: 全量测试**

Run: `flutter test 2>&1 | tail -5`
Expected: `All tests passed!`，计数 = baseline 2326 + 本批新增（贴实测数字，不转抄）。

- [ ] **Step 3: 更新 phase5 spec §4.3**

把 `### 4.3 「首通必得」数据源（⚠️ 待拍板 · 可能涉 schema）` 段改为「✅ 已拍板 = B（派生不加字段）」+ 一句决议摘要，删「开工 4.x 前需用户拍板」行。

- [ ] **Step 4: 更新 PROGRESS.md 顶段（续22）**

追加一段：续22（第五阶段主线三掉落传闻 UI · B 决议派生 · subagent-driven TDD），列 commit 区间 + 实测 analyze/test 计数 + 「主线三闭环，主线二待开」。

- [ ] **Step 5: Commit**

```bash
git add docs/spec/phase5_battle_experience_loot_spec_2026-06-17.md PROGRESS.md docs/spec/2026-06-18-phase5-mainline3-loot-rumors-*.md
git commit -m "主线三:收尾 — 全量验证 + spec §4.3 B 决议 + PROGRESS 续22"
```

---

## 自检(已过)

- **spec 覆盖**：4.2 桶映射→T1；4.3 B 派生→T1/T2 `isFirstClearGated`；4.4 dialog+简版→T5/T6+接入 T8/T9；越阶提示→T4/T5；4.5 五类测→T1(边界)/T7(完整性+越阶)/T3(白名单)/T5/T6(无%+降级)；tower 脚注→T5。全覆盖。
- **类型一致**：`DropRumorBucket`/`bucketOf`/`DropRumorTable.fromDropTable`/`grouped`/`topRepresentatives`/`DropNameResolver.equipmentName|equipmentTier|itemName|isAboveRealm`/`LootRumorContent`/`showLootRumorDialog`/`LootSummaryLine` 跨 task 命名一致。
- **placeholder**：T7/T8/T9 的 fixture/加载体例标注「现 grep 体例补全」属**有意**留给实装时核对真实 API（getter 名/私有 widget 测路径不可凭记忆),非偷懒占位；其余 task 代码完整。
- **红线**：全程不动 dropTable 数值/DropService/battle_resolution；文案全 UiStrings；不显%、不引网游词。
