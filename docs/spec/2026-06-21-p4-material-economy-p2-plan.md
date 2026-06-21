# 材料经济 P2 — 新材料用途 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 激活经验丹（3 档加角色经验推境界）+ 秘籍（9 本解锁 fragment 秘传招）两种占位材料用途，让江湖商店货架不薄、材料背包有"使用"语义。

**Architecture:** 新建 `data/items.yaml` 道具效果配置层（当前缺口：ShopItemDef 只映射 defId，无效果配置）+ `ItemDef` def 类 + `ItemUseService` 单一派发点（消费与效果同一 Isar writeTxn 原子，秘籍解锁逻辑 inline 避免嵌套 txn）。经验丹复用 `CharacterAdvancementService.applyExperience`、秘籍复用 `skillUnlockProgress` 扩展。`ItemType.fromDefId` 改前缀匹配以覆盖 12 个新 defId。

**Tech Stack:** Flutter Desktop · Riverpod 3.x · Isar(isar_community) · YAML 配置 · TDD（普通 `test()` 不走 testWidgets，memory `feedback_isar_widget_test_deadlock`）

**设计来源:** `docs/spec/2026-06-21-p4-material-economy-p2-design.md`

**红线沿用:** §5.1 不随机不抽卡 · §5.3 秘籍解锁招仍受境界锁 · §5.4 道具补课非膨胀 · §5.5 掉落离线=在线 · §5.6 数值进 yaml/文案进 UiStrings+items.yaml name · §5.7 秘籍仅掉落保磨砺感

---

## 文件结构

| 文件 | 职责 | 动作 |
|---|---|---|
| `data/items.yaml` | 道具效果真相源（经验丹经验值 / 秘籍 unlockSkillId / 道具名） | 新建 |
| `lib/data/defs/item_def.dart` | `ItemDef` 不可变 def + fromYaml + 字段校验 | 新建 |
| `lib/data/game_repository.dart` | 加载 items.yaml → `itemDefs` map + `_enforceItemRedLines` | 改 |
| `lib/core/domain/enums.dart` | `ItemType.fromDefId` 改前缀匹配 | 改 |
| `lib/features/inventory/application/item_use_service.dart` | `ItemUseService.use` 派发消费+效果（原子 txn） + `ItemUseResult` | 新建 |
| `lib/features/inventory/presentation/inventory_screen.dart` | `_MaterialRow` 解析 def 名 + "使用"按钮 + 确认弹窗 + 结果浮层 | 改 |
| `lib/shared/strings.dart`（`UiStrings`） | 使用按钮/确认/结果文案 | 改 |
| `data/shop.yaml` | 加经验丹小/中 2 条 | 改 |
| `data/stages.yaml` / `data/towers.yaml` | 加经验丹大档 + 9 秘籍掉落（dropChance 占位） | 改 |
| `test/...` | 各 task TDD 测 | 新建 |

---

## Task 0: Worktree 准备 + baseline

**Files:** 无代码改动（环境准备）

- [ ] **Step 1: 拷 libisar.dylib（fresh worktree 缺，否则 Isar 测 dlopen 失败）**

Run:
```bash
cp /Users/a10506/Desktop/Projects/挂机武侠/libisar.dylib /Users/a10506/Desktop/Projects/挂机武侠/.claude/worktrees/p4-material-economy-p2/libisar.dylib
```
Expected: 文件存在（`ls -la libisar.dylib` 显 ~2.1MB）。

- [ ] **Step 2: 跑 build_runner（.g.dart gitignored，fresh worktree 需生成）**

Run: `dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -3`
Expected: `Succeeded`（无 error）。

- [ ] **Step 3: 记录 baseline 测试数（净增长锚点）**

Run: `flutter test 2>&1 | tail -3`
Expected: `All tests passed!`，记下总数（spec 锚点 = 2728 测 +1 skip；以实测为准，禁转抄）。

---

## Task 1: ItemDef + items.yaml + GameRepository 加载/红线

**Files:**
- Create: `data/items.yaml`
- Create: `lib/data/defs/item_def.dart`
- Modify: `lib/data/game_repository.dart`（字段 + 加载 + `_enforceItemRedLines`）
- Test: `test/data/item_def_test.dart`

- [ ] **Step 1: 写 `data/items.yaml`**

```yaml
# 道具效果定义（材料经济 P2）。
# 经验丹 experience / 秘籍 unlockSkillId 是道具用途真相源；
# 道具显示名 name 集中此处（3 档经验丹共享 ItemType.jingYanDan，EnumL10n 分不开）。
# experience 占位待 balance pass 校准（同 P1 银两数值策略）。
# 字段：
#   defId        : 对应 InventoryItem.defId
#   type         : ItemType 枚举名（jingYanDan / techniqueScroll）
#   name         : 道具显示名（文案）
#   experience   : jingYanDan 专用，使用时加的角色经验
#   unlockSkillId: techniqueScroll 专用，使用时解锁的秘传招 id
items:
  - { defId: item_jingyandan_small, type: jingYanDan, name: 凝神丹, experience: 200 }
  - { defId: item_jingyandan_mid,   type: jingYanDan, name: 培元丹, experience: 600 }
  - { defId: item_jingyandan_large, type: jingYanDan, name: 大还丹, experience: 1800 }
  - { defId: item_scroll_kai_bei_shou,        type: techniqueScroll, name: 开碑手·秘籍,     unlockSkillId: skill_kai_bei_shou }
  - { defId: item_scroll_yan_zi_san_chao,     type: techniqueScroll, name: 燕子三抄·秘籍,   unlockSkillId: skill_yan_zi_san_chao }
  - { defId: item_scroll_zhu_ying_yao_hong,   type: techniqueScroll, name: 烛影摇红·秘籍,   unlockSkillId: skill_zhu_ying_yao_hong }
  - { defId: item_scroll_jin_gang_fu_mo,      type: techniqueScroll, name: 金刚伏魔·秘籍,   unlockSkillId: skill_jin_gang_fu_mo }
  - { defId: item_scroll_jing_hong_zhao_ying, type: techniqueScroll, name: 惊鸿照影·秘籍,   unlockSkillId: skill_jing_hong_zhao_ying }
  - { defId: item_scroll_yue_luo_wu_sheng,    type: techniqueScroll, name: 月落无声·秘籍,   unlockSkillId: skill_yue_luo_wu_sheng }
  - { defId: item_scroll_guan_shan_ba_ji,     type: techniqueScroll, name: 关山拔戟·秘籍,   unlockSkillId: skill_guan_shan_ba_ji }
  - { defId: item_scroll_ma_ta_fei_yan,       type: techniqueScroll, name: 马踏飞燕·秘籍,   unlockSkillId: skill_ma_ta_fei_yan }
  - { defId: item_scroll_ye_yu_shi_nian_deng, type: techniqueScroll, name: 夜雨十年灯·秘籍, unlockSkillId: skill_ye_yu_shi_nian_deng }
```

- [ ] **Step 2: 写失败测 `test/data/item_def_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/data/defs/item_def.dart';

void main() {
  test('经验丹 def fromYaml: type/name/experience 解析', () {
    final d = ItemDef.fromYaml({
      'defId': 'item_jingyandan_small',
      'type': 'jingYanDan',
      'name': '凝神丹',
      'experience': 200,
    });
    expect(d.defId, 'item_jingyandan_small');
    expect(d.type, ItemType.jingYanDan);
    expect(d.name, '凝神丹');
    expect(d.experience, 200);
    expect(d.unlockSkillId, isNull);
  });

  test('秘籍 def fromYaml: unlockSkillId 解析', () {
    final d = ItemDef.fromYaml({
      'defId': 'item_scroll_kai_bei_shou',
      'type': 'techniqueScroll',
      'name': '开碑手·秘籍',
      'unlockSkillId': 'skill_kai_bei_shou',
    });
    expect(d.type, ItemType.techniqueScroll);
    expect(d.unlockSkillId, 'skill_kai_bei_shou');
    expect(d.experience, isNull);
  });

  test('经验丹缺 experience → 抛错', () {
    expect(
      () => ItemDef.fromYaml(
          {'defId': 'x', 'type': 'jingYanDan', 'name': 'x'}),
      throwsStateError,
    );
  });

  test('秘籍缺 unlockSkillId → 抛错', () {
    expect(
      () => ItemDef.fromYaml(
          {'defId': 'x', 'type': 'techniqueScroll', 'name': 'x'}),
      throwsStateError,
    );
  });
}
```

- [ ] **Step 3: 跑测验证失败**

Run: `flutter test test/data/item_def_test.dart`
Expected: FAIL（`item_def.dart` 不存在 / `ItemDef` undefined）。

- [ ] **Step 4: 写 `lib/data/defs/item_def.dart`**

```dart
import '../../core/domain/enums.dart';

/// 道具效果定义（材料经济 P2，`data/items.yaml`）。
///
/// - [type] == jingYanDan：必有 [experience]（使用时加角色经验）。
/// - [type] == techniqueScroll：必有 [unlockSkillId]（使用时解锁秘传招）。
/// 缺对应字段 → fromYaml 抛 StateError（fail fast，沿强校验体例）。
class ItemDef {
  final String defId;
  final ItemType type;
  final String name;
  final int? experience;
  final String? unlockSkillId;

  const ItemDef({
    required this.defId,
    required this.type,
    required this.name,
    this.experience,
    this.unlockSkillId,
  });

  factory ItemDef.fromYaml(Map<String, dynamic> y) {
    final defId = y['defId'] as String;
    final type = ItemType.values.byName(y['type'] as String);
    final name = y['name'] as String;
    final experience = (y['experience'] as num?)?.toInt();
    final unlockSkillId = y['unlockSkillId'] as String?;
    if (type == ItemType.jingYanDan && experience == null) {
      throw StateError('ItemDef $defId: jingYanDan 必须配 experience');
    }
    if (type == ItemType.techniqueScroll && unlockSkillId == null) {
      throw StateError('ItemDef $defId: techniqueScroll 必须配 unlockSkillId');
    }
    return ItemDef(
      defId: defId,
      type: type,
      name: name,
      experience: experience,
      unlockSkillId: unlockSkillId,
    );
  }
}
```

- [ ] **Step 5: 跑测验证通过**

Run: `flutter test test/data/item_def_test.dart`
Expected: PASS（4 测）。

- [ ] **Step 6: GameRepository 接 items.yaml**

`lib/data/game_repository.dart`：
1. import：`import 'defs/item_def.dart';`
2. 字段（在 `shopItemDefs` 后加）：
```dart
  /// 道具效果 def（`data/items.yaml`，材料经济 P2）。
  /// 经验丹经验值 / 秘籍 unlockSkillId / 道具名。fixture 不带 yaml 时空 map。
  final Map<String, ItemDef> itemDefs;
```
3. 构造器 `GameRepository._({...})` 加 `required this.itemDefs,`
4. 加载段（仿 shop.yaml，在 shopItemDefs 加载后）：
```dart
    // 材料经济 P2 items.yaml(graceful;fixture 不带 yaml 时空 map)。
    Map<String, ItemDef> itemDefs = const {};
    try {
      final itemsRaw = parseYamlMap(await load('data/items.yaml'));
      itemDefs = _parseDefMap(
        itemsRaw['items'] as List,
        ItemDef.fromYaml,
        idOf: (d) => d.defId,
      );
    } catch (_) {}
```
5. `GameRepository._(...)` 调用处加 `itemDefs: itemDefs,`
6. `_enforceRedLines()` 末尾加 `_enforceItemRedLines();`
7. 新方法（仿 `_enforceShopRedLines`）：
```dart
  /// 材料经济 P2：道具经验值红线（防经验丹变相破数值红线）。
  void _enforceItemRedLines() {
    if (itemDefs.isEmpty) return; // test fixture 兼容
    for (final d in itemDefs.values) {
      final exp = d.experience;
      if (exp != null && (exp <= 0 || exp > 100000)) {
        throw StateError('红线:道具 ${d.defId} experience $exp 应 ∈ (0, 100000]');
      }
    }
  }
```

- [ ] **Step 7: 写 GameRepository 加载测 `test/data/item_def_test.dart` 追加**

```dart
  test('GameRepository 加载 items.yaml: 12 条 def', () async {
    final repo = await GameRepository.loadAllDefs();
    expect(repo.itemDefs.length, 12);
    expect(repo.itemDefs['item_jingyandan_small']?.experience, 200);
    expect(repo.itemDefs['item_scroll_kai_bei_shou']?.unlockSkillId,
        'skill_kai_bei_shou');
  });
```
（顶部加 `import 'package:wuxia_idle/data/game_repository.dart';` + `setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());` —— loadAllDefs 走 rootBundle 需 binding。参考 `test/data/shop_def_test.dart` 的 loadAllDefs 测体例。）

- [ ] **Step 8: 跑测 + commit**

Run: `flutter test test/data/item_def_test.dart`
Expected: PASS（5 测）。
```bash
git add data/items.yaml lib/data/defs/item_def.dart lib/data/game_repository.dart test/data/item_def_test.dart
git commit -m "材料经济P2 T1:ItemDef + items.yaml + GameRepository 加载/红线"
```

---

## Task 2: `ItemType.fromDefId` 前缀匹配

**Files:**
- Modify: `lib/core/domain/enums.dart:358-372`（fromDefId switch）
- Test: `test/core/item_type_from_defid_test.dart`

> 背景：新增 12 个 defId，逐个 case 冗长易漏静默吞 miscMaterial（memory `feedback_enum_fromdefid_default_swallow`）。改前缀判。`fromDefId` 是入库唯一映射点（tower_entry_flow:601 / stage_entry_flow:833 / drop_name_resolver:20 / stage_victory_dialog:122 / visual_route_host:548 全走它），改这一处即覆盖所有获得点。

- [ ] **Step 1: 写失败测 `test/core/item_type_from_defid_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';

void main() {
  test('既有精确 case 不回归', () {
    expect(ItemType.fromDefId('item_mojianshi'), ItemType.moJianShi);
    expect(ItemType.fromDefId('item_xinxuejiejing'), ItemType.xinXueJieJing);
    expect(ItemType.fromDefId('item_silver'), ItemType.silver);
  });

  test('经验丹前缀 → jingYanDan', () {
    expect(ItemType.fromDefId('item_jingyandan_small'), ItemType.jingYanDan);
    expect(ItemType.fromDefId('item_jingyandan_mid'), ItemType.jingYanDan);
    expect(ItemType.fromDefId('item_jingyandan_large'), ItemType.jingYanDan);
  });

  test('秘籍前缀 → techniqueScroll', () {
    expect(ItemType.fromDefId('item_scroll_kai_bei_shou'),
        ItemType.techniqueScroll);
    expect(ItemType.fromDefId('item_scroll_ye_yu_shi_nian_deng'),
        ItemType.techniqueScroll);
  });

  test('未知 id → miscMaterial 兜底', () {
    expect(ItemType.fromDefId('item_unknown_xyz'), ItemType.miscMaterial);
  });
}
```

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/core/item_type_from_defid_test.dart`
Expected: FAIL（`item_jingyandan_small` / `item_scroll_*` 当前落 miscMaterial）。

- [ ] **Step 3: 改 `fromDefId`（`lib/core/domain/enums.dart`）**

```dart
  static ItemType fromDefId(String defId) {
    // 前缀匹配优先（材料经济 P2：经验丹 3 档 + 秘籍 9 本共 12 defId，
    // 避免逐个 case 冗长易漏静默吞 miscMaterial）。
    if (defId.startsWith('item_scroll_')) return ItemType.techniqueScroll;
    if (defId.startsWith('item_jingyandan')) return ItemType.jingYanDan;
    switch (defId) {
      case 'item_mojianshi':
        return ItemType.moJianShi;
      case 'item_xinxuejiejing':
        return ItemType.xinXueJieJing;
      case 'item_silver':
        return ItemType.silver;
      default:
        return ItemType.miscMaterial;
    }
  }
```

- [ ] **Step 4: 跑测验证通过 + commit**

Run: `flutter test test/core/item_type_from_defid_test.dart`
Expected: PASS（4 测）。
```bash
git add lib/core/domain/enums.dart test/core/item_type_from_defid_test.dart
git commit -m "材料经济P2 T2:fromDefId 前缀匹配(经验丹/秘籍 12 defId)"
```

---

## Task 3: `ItemUseService` + `ItemUseResult`（核心）

**Files:**
- Create: `lib/features/inventory/application/item_use_service.dart`
- Test: `test/features/inventory/item_use_service_test.dart`

> 关键约束：消费（InventoryItem 扣减）+ 效果同一 `writeTxn` 原子（防扣了没生效，沿 ShopService.purchase 体例）。秘籍解锁逻辑 **inline**（`skillUnlockProgress` 扩展）而非调 `SkillUnlockService.grantManual`——后者自开 writeTxn，嵌套会抛（memory `feedback_isar_pitfalls` 嵌套 writeTxn）。经验丹用 `applyExperience`（纯 static 函数，txn 内安全）作用于 founder 角色。秘籍已解锁则 **不消费**（不浪费秘籍）。

- [ ] **Step 1: 写失败测 `test/features/inventory/item_use_service_test.dart`**

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wuxia_idle/core/domain/attributes.dart';
import 'package:wuxia_idle/core/domain/character.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/data/defs/item_def.dart';
import 'package:wuxia_idle/data/game_repository.dart';
import 'package:wuxia_idle/data/isar_setup.dart';
import 'package:wuxia_idle/features/inventory/application/item_use_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late Isar isar;
  late GameRepository repo;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
    repo = await GameRepository.loadAllDefs();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wuxia_itemuse_');
    await IsarSetup.init(directory: tempDir, inspector: false);
    isar = IsarSetup.instance;
  });

  tearDown(() async {
    if (Isar.getInstance('wuxia_save_slot1') != null) await IsarSetup.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  // 预置 founder 角色（低境界，留升层空间）。Character.create 7 required 命名参
  // (name/realmTier/realmLayer/attributes/rarity/lineageRole/createdAt)，
  // experience/experienceToNextLayer/internalForceMax/isFounder 为命名可选。
  Future<int> seedFounder() async {
    late int id;
    await isar.writeTxn(() async {
      final c = Character.create(
        name: '主角',
        realmTier: RealmTier.xueTu,
        realmLayer: RealmLayer.qiMeng,
        attributes: Attributes(),
        rarity: RarityTier.values.first,
        lineageRole: LineageRole.founder,
        createdAt: DateTime(2026, 1, 1),
        isFounder: true,
        experience: 0,
        experienceToNextLayer: 100,
        internalForceMax: 800,
      );
      id = await isar.characters.put(c);
    });
    return id;
  }

  Future<void> seedItem(String defId, ItemType type, int qty) async {
    await isar.writeTxn(() async {
      await isar.inventoryItems.put(InventoryItem()
        ..defId = defId
        ..itemType = type
        ..quantity = qty
        ..firstObtainedAt = DateTime(2026, 1, 1)
        ..lastObtainedAt = DateTime(2026, 1, 1));
    });
  }

  test('经验丹：经验入账 + 升层 + 消费 1', () async {
    await seedFounder();
    await seedItem('item_jingyandan_large', ItemType.jingYanDan, 2);
    final def = repo.itemDefs['item_jingyandan_large']!; // experience 1800

    final r = await ItemUseService.use(
      isar,
      def: def,
      realmLookup: repo.getRealm,
    );

    expect(r.kind, ItemUseKind.experienceApplied);
    expect(r.layersGained, greaterThan(0)); // 1800 经验跨多层
    final item = await isar.inventoryItems.getByDefId('item_jingyandan_large');
    expect(item?.quantity, 1); // 消费 1
    final founder =
        await isar.characters.filter().isFounderEqualTo(true).findFirst();
    expect(founder?.experience ?? -1, greaterThanOrEqualTo(0));
  });

  test('经验丹：isLayerLocked 拦截 → 入账不升层', () async {
    await seedFounder();
    await seedItem('item_jingyandan_large', ItemType.jingYanDan, 1);
    final def = repo.itemDefs['item_jingyandan_large']!;

    final r = await ItemUseService.use(
      isar,
      def: def,
      realmLookup: repo.getRealm,
      isLayerLocked: (_, _) => true, // 全锁
    );

    expect(r.kind, ItemUseKind.experienceApplied);
    expect(r.layersGained, 0); // 锁住不升层
    final founder =
        await isar.characters.filter().isFounderEqualTo(true).findFirst();
    expect(founder?.experience, 1800); // 经验仍入账
  });

  test('秘籍：解锁招 + 消费 1', () async {
    await seedFounder();
    await seedItem('item_scroll_kai_bei_shou', ItemType.techniqueScroll, 1);
    final def = repo.itemDefs['item_scroll_kai_bei_shou']!;

    final r = await ItemUseService.use(isar, def: def, realmLookup: repo.getRealm);

    expect(r.kind, ItemUseKind.skillUnlocked);
    final save = await isar.saveDatas.get(0);
    expect(save!.skillUnlockProgress.isUnlocked('skill_kai_bei_shou'), isTrue);
    final item = await isar.inventoryItems.getByDefId('item_scroll_kai_bei_shou');
    expect(item?.quantity ?? 0, 0); // 消费 1 归 0
  });

  test('秘籍幂等：已解锁 → 不消费、返 alreadyKnown', () async {
    await seedFounder();
    await seedItem('item_scroll_kai_bei_shou', ItemType.techniqueScroll, 1);
    final def = repo.itemDefs['item_scroll_kai_bei_shou']!;
    await ItemUseService.use(isar, def: def, realmLookup: repo.getRealm);
    await seedItem('item_scroll_kai_bei_shou', ItemType.techniqueScroll, 1);

    final r = await ItemUseService.use(isar, def: def, realmLookup: repo.getRealm);

    expect(r.kind, ItemUseKind.alreadyKnown);
    final item = await isar.inventoryItems.getByDefId('item_scroll_kai_bei_shou');
    expect(item?.quantity, 1); // 不消费
  });

  test('无库存 → 返 noStock 不写入', () async {
    await seedFounder();
    final def = repo.itemDefs['item_jingyandan_small']!;
    final r = await ItemUseService.use(isar, def: def, realmLookup: repo.getRealm);
    expect(r.kind, ItemUseKind.noStock);
  });
}
```

> 注：`Character.create` 命名构造与字段以 `lib/core/domain/character.dart` 实际为准（实装前 grep 确认 create 工厂签名 + `getByDefId` 索引方法名；若 `Character` 无 `create` 工厂，用现有测试 fixture 体例如 `test/features/...` 既有 Character 构造）。`repo.getRealm` 签名 = `RealmDef getRealm(RealmTier, RealmLayer)`（grep 确认）。

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/features/inventory/item_use_service_test.dart`
Expected: FAIL（`item_use_service.dart` 不存在）。

- [ ] **Step 3: 写 `lib/features/inventory/application/item_use_service.dart`**

```dart
import 'package:isar_community/isar.dart';

import '../../../core/domain/enums.dart';
import '../../../data/defs/item_def.dart';
import '../../../data/defs/realm_def.dart';
import '../../cultivation/application/character_advancement_service.dart';

/// 材料经济 P2：道具"使用"派发服务。
///
/// 消费（InventoryItem 扣减）+ 效果同一 [Isar.writeTxn] 原子（沿 ShopService）。
/// - jingYanDan → [CharacterAdvancementService.applyExperience]（founder 角色）。
/// - techniqueScroll → inline 解锁 `skillUnlockProgress`（**不调 grantManual**：
///   后者自开 writeTxn，嵌套会抛 — memory feedback_isar_pitfalls）。已解锁则不消费。
class ItemUseService {
  /// 使用一份道具 [def]。
  ///
  /// - [realmLookup]：升层时查下一档 RealmDef（生产传 `GameRepository.instance.getRealm`）。
  /// - [isLayerLocked]：心魔余毒锁层 hook（可选，null=不锁）。
  static Future<ItemUseResult> use(
    Isar isar, {
    required ItemDef def,
    required RealmDef Function(RealmTier, RealmLayer) realmLookup,
    bool Function(RealmTier, RealmLayer)? isLayerLocked,
  }) async {
    return isar.writeTxn(() async {
      final item = await isar.inventoryItems.getByDefId(def.defId);
      if (item == null || item.quantity <= 0) {
        return const ItemUseResult(kind: ItemUseKind.noStock);
      }

      switch (def.type) {
        case ItemType.jingYanDan:
          final founder = await isar.characters
              .filter()
              .isFounderEqualTo(true)
              .findFirst();
          if (founder == null) {
            return const ItemUseResult(kind: ItemUseKind.noTarget);
          }
          final result = CharacterAdvancementService.applyExperience(
            founder,
            def.experience!,
            realmLookup: realmLookup,
            isLayerLocked: isLayerLocked,
          );
          await isar.characters.put(founder);
          await _consumeOne(isar, item);
          return ItemUseResult(
            kind: ItemUseKind.experienceApplied,
            layersGained: result.layersGained,
            itemName: def.name,
          );

        case ItemType.techniqueScroll:
          final save = await isar.saveDatas.get(0);
          if (save == null) {
            return const ItemUseResult(kind: ItemUseKind.noTarget);
          }
          // @embedded list 取出 fixed-length → 转 growable 再 mutate。
          save.skillUnlockProgress = List.of(save.skillUnlockProgress);
          if (save.skillUnlockProgress.isUnlocked(def.unlockSkillId!)) {
            // 已解锁：不消费、不写。
            return ItemUseResult(
              kind: ItemUseKind.alreadyKnown,
              itemName: def.name,
            );
          }
          save.skillUnlockProgress.markUnlocked(def.unlockSkillId!);
          await isar.saveDatas.put(save);
          await _consumeOne(isar, item);
          return ItemUseResult(
            kind: ItemUseKind.skillUnlocked,
            itemName: def.name,
            unlockedSkillId: def.unlockSkillId,
          );

        default:
          // 磨剑石/心血结晶/银两/杂项无"使用"语义。
          return const ItemUseResult(kind: ItemUseKind.notUsable);
      }
    });
  }

  /// 扣 1（归 0 删行）。
  static Future<void> _consumeOne(Isar isar, item) async {
    item.quantity -= 1;
    if (item.quantity <= 0) {
      await isar.inventoryItems.delete(item.id);
    } else {
      item.lastObtainedAt = DateTime.now();
      await isar.inventoryItems.put(item);
    }
  }
}

/// 使用结果类型。
enum ItemUseKind {
  experienceApplied, // 经验丹入账（layersGained 区分是否升层）
  skillUnlocked,     // 秘籍新解锁
  alreadyKnown,      // 秘籍已解锁（未消费）
  noStock,           // 无库存
  noTarget,          // 无 founder / SaveData
  notUsable,         // 该 ItemType 无使用语义
}

/// 使用结果。
class ItemUseResult {
  final ItemUseKind kind;
  final int layersGained;
  final String? itemName;
  final String? unlockedSkillId;

  const ItemUseResult({
    required this.kind,
    this.layersGained = 0,
    this.itemName,
    this.unlockedSkillId,
  });
}
```

> import `skillUnlockProgress` 扩展（`MapLikeOnSkillUnlock on List<SkillUnlockEntry>` 的 `isUnlocked`/`markUnlocked`）来自 `lib/core/domain/skill_unlock_entry.dart`（已核实，参考 `skill_unlock_service.dart` 顶部 import `skill_unlock_entry.dart`）。`realm_def.dart` 路径 = `lib/data/defs/realm_def.dart`（已核实）。`getByDefId` 是 InventoryItem 的 Isar 生成索引方法（已核实，tower/seclusion 在用）。`_consumeOne` 的 `item` 参数类型 = `InventoryItem`（显式标注，避免 dynamic）。

- [ ] **Step 4: 跑测验证通过**

Run: `flutter test test/features/inventory/item_use_service_test.dart`
Expected: PASS（5 测）。修编译错（import 路径 / Character 构造 / extension import）直到绿。

- [ ] **Step 5: 全项目 analyze（跨文件签名回归雷达，memory `feedback_subagent_implementer_full_analyze`）**

Run: `flutter analyze 2>&1 | tail -5`
Expected: `No issues found!`

- [ ] **Step 6: commit**

```bash
git add lib/features/inventory/application/item_use_service.dart test/features/inventory/item_use_service_test.dart
git commit -m "材料经济P2 T3:ItemUseService 原子派发(经验丹/秘籍)+ItemUseResult"
```

---

## Task 4: 背包"使用" UI 入口

**Files:**
- Modify: `lib/features/inventory/presentation/inventory_screen.dart`（`_MaterialRow` → 解析 def 名 + "使用"按钮 + 确认 + 结果浮层）
- Modify: `lib/shared/strings.dart`（`UiStrings`：按钮/确认/结果文案）
- Test: `test/features/inventory/inventory_use_button_test.dart`

> UI 沿 `shop_screen.dart` 购买弹窗体例（`PaperDialog.show<bool>` 确认 → service → 结果 PaperDialog → invalidate providers）。`_MaterialRow` 当前用 `EnumL10n.itemType(type)` 作名；经验丹/秘籍要显 per-item def 名（凝神丹/开碑手·秘籍），从 `itemDefsProvider`/`GameRepository.instance.itemDefs[defId]` 解析，回退 group 名。"使用"按钮仅 jingYanDan/techniqueScroll 出现。

- [ ] **Step 1: UiStrings 文案**

`lib/shared/strings.dart` `UiStrings` 加（沿既有静态 const/函数体例，grep 确认风格）：
```dart
  static const String itemUseButton = '使用';
  static const String itemUseConfirmTitle = '使用道具';
  static String itemUseConfirmBody(String name) => '确定使用「$name」？';
  static String itemUseExpResult(String name, int layersGained) =>
      layersGained > 0 ? '服下「$name」，境界精进 $layersGained 层。' : '服下「$name」，内息渐长。';
  static String itemUseScrollResult(String name) => '研读「$name」，已了然于胸，得此绝学。';
  static String itemUseAlreadyKnown(String name) => '「$name」所载之招，早已了然于胸。';
```

- [ ] **Step 2: 写 widget 失败测 `test/features/inventory/inventory_use_button_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/core/domain/inventory_item.dart';
import 'package:wuxia_idle/core/application/inventory_providers.dart';
// ... 其余 import 以实装为准

void main() {
  testWidgets('经验丹/秘籍行显"使用"按钮，磨剑石不显', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000)); // viewport 扩容
    addTearDown(() => tester.binding.setSurfaceSize(null));

    InventoryItem mk(String id, ItemType t) => InventoryItem()
      ..defId = id
      ..itemType = t
      ..quantity = 3
      ..firstObtainedAt = DateTime(2026, 1, 1)
      ..lastObtainedAt = DateTime(2026, 1, 1);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        allInventoryItemsProvider.overrideWith((ref) async => [
              mk('item_mojianshi', ItemType.moJianShi),
              mk('item_jingyandan_small', ItemType.jingYanDan),
              mk('item_scroll_kai_bei_shou', ItemType.techniqueScroll),
            ]),
        // silverBalanceProvider override → 0（避免真 Isar）
      ],
      child: const MaterialApp(home: /* InventoryScreen 物料 tab */ Placeholder()),
    ));
    await tester.pumpAndSettle();

    // 断言：使用按钮出现 2 次（经验丹 + 秘籍），磨剑石行无按钮。
    expect(find.text('使用'), findsNWidgets(2));
  });
}
```

> 注：override `silverBalanceProvider` + `allInventoryItemsProvider` 避免真 Isar（参考 `test/features/shop/shop_screen_test.dart` override 体例）。若 InventoryScreen 默认 tab=装备需传 `initialTab` 开物料 tab（P1 已加 initialTab 参数）。具体断言数依实装行结构微调。

- [ ] **Step 3: 跑测验证失败**

Run: `flutter test test/features/inventory/inventory_use_button_test.dart`
Expected: FAIL（无"使用"按钮）。

- [ ] **Step 4: 改 `_MaterialRow`（inventory_screen.dart）**

要点（在 `_MaterialRow` 现有 quantity Row 末尾加按钮；ConsumerWidget 化以读 itemDefs + ref.invalidate）：
1. `_MaterialRow` 改 `ConsumerWidget`（当前 StatelessWidget）。
2. 名解析：`final itemDef = GameRepository.instance.itemDefs[item.defId];` `final displayName = itemDef?.name ?? name;` 用 `displayName` 替换 `UiStrings.materialQuantity(name, ...)` 的 name。
3. 按钮（仅 jingYanDan/techniqueScroll）：
```dart
if (item.itemType == ItemType.jingYanDan ||
    item.itemType == ItemType.techniqueScroll)
  TextButton(
    onPressed: () => _onUse(context, ref, item, itemDef!),
    child: const Text(UiStrings.itemUseButton,
        style: TextStyle(color: WuxiaColors.textPrimary)),
  ),
```
4. `_onUse` 方法：
```dart
  Future<void> _onUse(
      BuildContext context, WidgetRef ref, InventoryItem item, ItemDef def) async {
    final confirmed = await PaperDialog.show<bool>(
      context,
      title: UiStrings.itemUseConfirmTitle,
      // body: UiStrings.itemUseConfirmBody(def.name) — 沿 shop_screen PaperDialog 参数体例
      ...
    );
    if (confirmed != true) return;

    final isar = IsarSetup.instance;
    // isLayerLocked 组装：仿 stage_entry_flow（读 MainlineProgress.clearedStageIds
    // + numbers.innerDemon → InnerDemonService.isLayerLocked）。
    final result = await ItemUseService.use(
      isar,
      def: def,
      realmLookup: GameRepository.instance.getRealm,
      isLayerLocked: /* 组装，见下注 */,
    );

    ref.invalidate(allInventoryItemsProvider);
    ref.invalidate(silverBalanceProvider); // 货币位（保险，经验丹不动银两但统一刷新）
    // 角色经验变 → invalidate 相关 character provider（grep characterByIdProvider/activeCharacterIds）

    if (!context.mounted) return;
    final msg = switch (result.kind) {
      ItemUseKind.experienceApplied =>
        UiStrings.itemUseExpResult(def.name, result.layersGained),
      ItemUseKind.skillUnlocked => UiStrings.itemUseScrollResult(def.name),
      ItemUseKind.alreadyKnown => UiStrings.itemUseAlreadyKnown(def.name),
      _ => UiStrings.itemUseAlreadyKnown(def.name), // noStock/noTarget 兜底提示
    };
    await PaperDialog.show<void>(context, title: UiStrings.itemUseConfirmTitle, /* body: msg */);
  }
```

> `PaperDialog.show` 精确参数签名以 `lib/shared/widgets/wuxia_ui/paper_dialog.dart` + `shop_screen.dart:96` 调用为准（实装前 grep 对齐 title/body/确认按钮命名）。`isLayerLocked` 组装照搬 `stage_entry_flow.dart:781-789`（clearedStageIds + innerDemonDef）；若嫌重，可抽 helper，但本批最小化：直接内联组装。

- [ ] **Step 5: 跑测 + analyze**

Run: `flutter test test/features/inventory/inventory_use_button_test.dart`
Expected: PASS。
Run: `flutter analyze 2>&1 | tail -5`
Expected: `No issues found!`

- [ ] **Step 6: commit**

```bash
git add lib/features/inventory/presentation/inventory_screen.dart lib/shared/strings.dart test/features/inventory/inventory_use_button_test.dart
git commit -m "材料经济P2 T4:背包使用按钮+确认弹窗+结果浮层"
```

---

## Task 5: 货架 + dropTable 接线

**Files:**
- Modify: `data/shop.yaml`（经验丹小/中 2 条）
- Modify: `data/stages.yaml` / `data/towers.yaml`（经验丹大档 + 9 秘籍掉落，dropChance 占位）
- Test: `test/data/shop_def_test.dart`（追加）

> dropChance / price / 经验值全占位待 balance pass（同 P1 银两策略，yaml 注释标注）。秘籍仅掉落不上货架（§5.7）。

- [ ] **Step 1: shop.yaml 加经验丹小/中**

```yaml
  - id: shop_jingyandan_small
    itemDefId: item_jingyandan_small
    itemType: jingYanDan
    price: 50          # 占位待 balance
    category: pill
  - id: shop_jingyandan_mid
    itemDefId: item_jingyandan_mid
    itemType: jingYanDan
    price: 150         # 占位待 balance
    category: pill
```

- [ ] **Step 2: stages.yaml / towers.yaml 加掉落（占位）**

选若干关卡/塔层 dropTable 加（沿 item_silver 体例）：
- 经验丹大档：几个章末 Boss 关（`item_jingyandan_large`，dropChance 占位如 0.2，quantity [1,1]）。
- 9 秘籍：分散挂到对应流派/进度的 Boss 关或塔 Boss 层（`item_scroll_<skillId>`，dropChance 低如 0.1，quantity [1,1]），每招挂 1-2 处。具体分布占位，balance pass 校准。注释标 `# 秘籍掉落(P2 占位,待 balance)`。

> 实装时 grep 既有 `dropTable:` 段落，选关卡正向定位（memory `feedback_stages_yaml_edit_direction` 从 `- id:` 正读）。秘籍 9 招的 unlockSkillId 与 items.yaml 一致。

- [ ] **Step 3: 追加 shop_def_test 断言新货品加载 + dropTable 合法**

`test/data/shop_def_test.dart` 加：
```dart
  test('shop.yaml 含经验丹小/中', () async {
    final repo = await GameRepository.loadAllDefs();
    expect(repo.shopItemDefs['shop_jingyandan_small']?.itemType,
        ItemType.jingYanDan);
    expect(repo.shopItemDefs['shop_jingyandan_mid']?.price, 150);
  });
```
（dropTable 合法性由 `DropEntry.fromYaml` 加载时强校验兜底——loadAllDefs 不抛即合法；可加一条断言某关 dropTable 含 item_scroll_*。）

- [ ] **Step 4: 跑测 + commit**

Run: `flutter test test/data/shop_def_test.dart`
Expected: PASS。
```bash
git add data/shop.yaml data/stages.yaml data/towers.yaml test/data/shop_def_test.dart
git commit -m "材料经济P2 T5:经验丹上货架+经验丹大档/9秘籍 dropTable 接线(占位)"
```

---

## Task 6: GDD/PROGRESS sync + 全量验证

**Files:**
- Modify: `GDD.md`（§6.1 或材料/商店段，补经验丹/秘籍用途激活）
- Modify: `CLAUDE.md` §12.2 #12（P2 激活标注）
- Modify: `PROGRESS.md`（顶段续记）
- Modify: `docs/spec/2026-06-21-p4-material-economy-design.md`（P2 行标 ✅ 实装）

- [ ] **Step 1: GDD/CLAUDE/父 spec 文档 sync**

- GDD：材料/商店相关段补「经验丹=加经验推境界；秘籍=解锁秘传招（仅掉落）」，守 §5.7 措辞。
- CLAUDE.md §12.2 #12：行尾补 `**P2 新材料用途已激活 ✅**(2026-06-21):经验丹3档(applyExperience)+秘籍9本(grantManual 路径,仅掉落)+ItemUseService+背包使用入口。`
- 父 spec §6 拆分表 P2 行标 ✅。

- [ ] **Step 2: 全量 analyze**

Run: `flutter analyze 2>&1 | tail -5`
Expected: `No issues found!`

- [ ] **Step 3: 全量 test（净增长锚点，对照 Task 0 baseline）**

Run: `flutter test 2>&1 | tail -5`
Expected: `All tests passed!`，总数 = baseline + 本批新增（约 +14~16：item_def 5 + fromDefId 4 + item_use 5 + use_button 1 + shop_def 1）。**必读 log 确认「All tests passed!」**（不信 `$?`，memory `feedback_nightshift_max_output_token` 邻近坑）。

- [ ] **Step 4: commit 文档**

```bash
git add GDD.md CLAUDE.md PROGRESS.md docs/spec/2026-06-21-p4-material-economy-design.md
git commit -m "材料经济P2:GDD/CLAUDE/spec sync + 全量验证绿"
```

---

## 真机目检（实装后，非本 plan 步骤，留收尾）

沿 P1 体例：补 debug 路由（`inventory_use` seed 经验丹/秘籍入库直开物料 tab）→ `flutter run -d macos` 双分辨率自截 → 验「使用」按钮 + 确认弹窗 + 结果浮层（升层/解锁/已解锁三态）+ per-item 道具名（凝神丹/开碑手·秘籍）+ 缺图 glyph 降级。

---

## 自检（写 plan 后对照 spec）

- **Spec 覆盖**：§3.1 items.yaml/ItemDef→T1 · §3.2 经验丹→T3/T5 · §3.3 秘籍→T3/T5 · §3.4 ItemUseService→T3 · §3.5 背包入口→T4 · §3.6 fromDefId→T2 · §5 数据变更→T1/T2/T5 · §6 测试→各 task。无遗漏。
- **类型一致**：`ItemUseKind`/`ItemUseResult` 字段 T3 定义，T4 switch 消费一致；`ItemDef` 字段 T1 定义，T3/T4 用一致；`repo.getRealm`/`itemDefs` 全程一致。
- **占位标注**：经验值/price/dropChance 均注释占位 + §7 Deferred 记 balance pass。
- **已核实**（写 plan 时 grep 确认，code 已对齐）：`Character.create` 7 required 命名参签名 · `Attributes()` 默认构造 · `getByDefId` Isar 索引方法 · `skillUnlockProgress` extension 源 `skill_unlock_entry.dart` · `realm_def.dart` 路径 · `getRealm(RealmTier,RealmLayer)` 签名 · `fromDefId` 调用点全集。
- **实装前仍需 grep 确认**（plan 未钉死）：`PaperDialog.show` 精确参数签名（title/body/按钮命名，对齐 `shop_screen.dart:96`）· UiStrings 既有静态风格（const vs 函数）· `silverBalanceProvider` 定义位置（invalidate 用）· T4 widget 测 InventoryScreen 物料 tab 渲染入口（initialTab）。
