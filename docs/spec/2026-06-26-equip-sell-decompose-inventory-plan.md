# 装备出售/分解 + 仓库改进 + 升级放慢 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在装备仓库实装装备出售换银两 + 分解成强化材料（含一键按品级批量）、已装备视觉标记、商店入口、物料界面格子化，并放慢角色升级速度——推翻「装备永久收藏品 / 商店只买不卖」红线（用户 2026-06-26 拍板）。

**Architecture:** 纯函数算价/算料（domain）→ 原子事务 service（删装备 + 入银两/材料，复用 ShopService upsert 体例）→ UI（详情页单件入口 + 批量整理对话框 + 仓库标记/格子化/商店入口）。数值全进 numbers.yaml `equipment.disposal` 段；升级放慢只改 `level` 段。

**Tech Stack:** Flutter + Riverpod 3 + Isar(isar_community) + YAML 配置。测试：纯函数/service 用 `test()`，UI 用 `testWidgets()`。

**环境就绪**（已预热）：worktree 已 `pub get` + `build_runner`（110 outputs / 55 .g.dart）+ 拷 `libisar.dylib` + 冒烟通过。

**关键既有落点（已核验）：**
- `lib/features/equipment/application/equipment_service.dart`：`EquipmentService({required Isar isar})`，`equip/unequip` 用 `isar.writeTxn`。
- `lib/features/shop/application/shop_service.dart:55-92`：购买 writeTxn——读 `getByDefId('item_silver')`、扣银两、upsert 货品（76-89 即 upsert 体例）。
- `lib/core/domain/equipment.dart`：`tier`(EquipmentTier)/`enhanceLevel`/`ownerCharacterId`(null=背包)/`isLineageHeritage`/`slot`。Isar 集合 `isar.equipments`。
- `lib/core/domain/enums.dart:61` EquipmentTier 7 阶 `xunChang..shenWu`；`:348` ItemType `moJianShi/xinXueJieJing/silver`；`fromDefId` defId=`item_mojianshi`/`item_xinxuejiejing`/`item_silver`。
- `lib/core/domain/inventory_item.dart`：`defId`(unique)/`itemType`/`quantity`/`firstObtainedAt`/`lastObtainedAt`。
- `lib/data/numbers_config.dart`：`NumbersConfig.fromYaml` 解析；`final LevelConfig level`（:162）；equipment 段在 `y['equipment']`（:326）。
- `lib/features/level/domain/level_config.dart`：`expToNext(L)=base+(L-1)*perLevel`，`fromYaml` 默认 120/40（注释自称=生产初值）。
- `lib/features/inventory/presentation/inventory_screen.dart`：装备 tab `_EquipmentGrid`→`_SlotGroupSection`（按 slot 分组 Wrap）→`_EquipmentGridTile`(:423，Stack + ItemSlot + isLineageHeritage 角标 :459)；物料 tab `_MaterialTab`(:243，顶部银两位 + `_MaterialList`/`_MaterialGroup` ExpansionTile)。providers：`allEquipmentsProvider`/`allInventoryItemsProvider`/`silverBalanceProvider`/`activeCharacterIdsProvider`/`characterByIdProvider`。
- `lib/features/equipment/presentation/equipment_detail_screen.dart`：单件详情页（单件出售/分解入口落点，实装时读取结构）。
- `lib/shared/strings.dart`：`UiStrings`（新增中文串全进此处，参照 `inventoryTabEquipment`:535 / `silverBalanceLabel`:235 / `itemUseButton`:552 体例）。
- `lib/features/battle/domain/enum_localizations.dart:143`：`EnumL10n.equipmentTier(t)`。
- ShopScreen 导航体例：`main_menu.dart:391 _push(context, const ShopScreen())`。
- `lib/shared/widgets/wuxia_ui/`：`ItemSlot` / `PaperDialog.show` / `PlaqueButton` / `PaperPanel` / `SectionHeader`。

**红线纪律：** 数值全 numbers.yaml；中文全 UiStrings/EnumL10n；出售/分解恒走 service 原子事务；§5.3 境界锁 / §5.4 数值红线 / §5.1 其余项不动。唯一推翻 = 装备出售/分解。

---

## Task 1: 出售/分解 纯函数 + 配置

**Files:**
- Create: `lib/features/equipment/domain/equipment_disposal.dart`
- Modify: `lib/data/numbers_config.dart`（加 `EquipmentDisposalConfig disposal` 字段 + 解析）
- Modify: `data/numbers.yaml`（`equipment:` 下加 `disposal:` 段）
- Test: `test/features/equipment/domain/equipment_disposal_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
// test/features/equipment/domain/equipment_disposal_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:wuxia_idle/core/domain/enums.dart';
import 'package:wuxia_idle/features/equipment/domain/equipment_disposal.dart';

void main() {
  // 起始配置（= numbers.yaml disposal 段初值，待真机校）。
  const cfg = EquipmentDisposalConfig(
    sellPrice: [20, 50, 120, 280, 600, 1200, 2500],
    sellEnhanceFactor: 0.1,
    disassembleMojianshi: [1, 2, 4, 7, 12, 18, 25],
    disassembleXinxuejiejing: [0, 0, 0, 1, 2, 4, 8],
    disassembleEnhanceMojianshiPerLevel: 1,
  );

  test('出售价 = 基价 × (1 + 0.1×强化等级) 向下取整', () {
    expect(equipmentSellPrice(EquipmentTier.xunChang, 0, cfg), 20);
    expect(equipmentSellPrice(EquipmentTier.shenWu, 0, cfg), 2500);
    // 神物 +10：2500 × 2.0 = 5000
    expect(equipmentSellPrice(EquipmentTier.shenWu, 10, cfg), 5000);
    // 利器(280) +3：280 × 1.3 = 364
    expect(equipmentSellPrice(EquipmentTier.liQi, 3, cfg), 364);
  });

  test('分解产出 = 品阶基础 + 强化额外磨剑石', () {
    final r0 = equipmentDisassembleRewards(EquipmentTier.xunChang, 0, cfg);
    expect(r0.mojianshi, 1);
    expect(r0.xinxuejiejing, 0);
    final r1 = equipmentDisassembleRewards(EquipmentTier.shenWu, 0, cfg);
    expect(r1.mojianshi, 25);
    expect(r1.xinxuejiejing, 8);
    // 神物 +12：磨剑石 25 + 12×1 = 37，心血结晶 8
    final r2 = equipmentDisassembleRewards(EquipmentTier.shenWu, 12, cfg);
    expect(r2.mojianshi, 37);
    expect(r2.xinxuejiejing, 8);
  });
}
```

- [ ] **Step 2: 运行验证失败**

Run: `flutter test test/features/equipment/domain/equipment_disposal_test.dart`
Expected: FAIL（`equipment_disposal.dart` 不存在 / 未定义符号）

- [ ] **Step 3: 实现 domain**

```dart
// lib/features/equipment/domain/equipment_disposal.dart
import '../../../core/domain/enums.dart';

/// 装备出售/分解配置（numbers.yaml `equipment.disposal`，2026-06-26 红线推翻）。
/// 7 元数组按 [EquipmentTier] index（寻常货=0 … 神物=6）。**初值待真机校**。
class EquipmentDisposalConfig {
  final List<int> sellPrice;
  final double sellEnhanceFactor;
  final List<int> disassembleMojianshi;
  final List<int> disassembleXinxuejiejing;
  final int disassembleEnhanceMojianshiPerLevel;

  const EquipmentDisposalConfig({
    required this.sellPrice,
    required this.sellEnhanceFactor,
    required this.disassembleMojianshi,
    required this.disassembleXinxuejiejing,
    required this.disassembleEnhanceMojianshiPerLevel,
  });

  factory EquipmentDisposalConfig.fromYaml(Map<String, dynamic> y) =>
      EquipmentDisposalConfig(
        sellPrice: (y['sell_price'] as List).map((e) => (e as num).toInt()).toList(),
        sellEnhanceFactor: (y['sell_enhance_factor'] as num).toDouble(),
        disassembleMojianshi: (y['disassemble_mojianshi'] as List)
            .map((e) => (e as num).toInt())
            .toList(),
        disassembleXinxuejiejing: (y['disassemble_xinxuejiejing'] as List)
            .map((e) => (e as num).toInt())
            .toList(),
        disassembleEnhanceMojianshiPerLevel:
            (y['disassemble_enhance_mojianshi_per_level'] as num).toInt(),
      );
}

/// 分解产出（强化材料）。
class DisassembleRewards {
  final int mojianshi;
  final int xinxuejiejing;
  const DisassembleRewards({required this.mojianshi, required this.xinxuejiejing});
}

/// 出售价：基价[tier] × (1 + factor × enhanceLevel) 向下取整。
int equipmentSellPrice(EquipmentTier tier, int enhanceLevel, EquipmentDisposalConfig c) {
  final base = c.sellPrice[tier.index];
  return (base * (1 + c.sellEnhanceFactor * enhanceLevel)).floor();
}

/// 分解产出：品阶基础磨剑石/心血结晶 + 强化额外磨剑石（enhanceLevel × perLevel）。
DisassembleRewards equipmentDisassembleRewards(
    EquipmentTier tier, int enhanceLevel, EquipmentDisposalConfig c) {
  return DisassembleRewards(
    mojianshi: c.disassembleMojianshi[tier.index] +
        enhanceLevel * c.disassembleEnhanceMojianshiPerLevel,
    xinxuejiejing: c.disassembleXinxuejiejing[tier.index],
  );
}
```

- [ ] **Step 4: 接入 numbers.yaml + NumbersConfig**

在 `data/numbers.yaml` 的 `equipment:` 段下加（缩进对齐 `enhancement:`）：

```yaml
  # 装备出售/分解(2026-06-26 用户拍板推翻「永久收藏品/只买不卖」红线)。
  # 7 阶数组 index 0-6 = 寻常货..神物。**初值保守,待真机校**。
  disposal:
    sell_price: [20, 50, 120, 280, 600, 1200, 2500]
    sell_enhance_factor: 0.1
    disassemble_mojianshi: [1, 2, 4, 7, 12, 18, 25]
    disassemble_xinxuejiejing: [0, 0, 0, 1, 2, 4, 8]
    disassemble_enhance_mojianshi_per_level: 1
```

在 `lib/data/numbers_config.dart`：import `equipment_disposal.dart`；加字段 `final EquipmentDisposalConfig disposal;`；构造函数 `required this.disposal,`；`fromYaml` 内加 `disposal: EquipmentDisposalConfig.fromYaml(equipment['disposal'] as Map<String, dynamic>),`。

- [ ] **Step 5: 运行测试验证通过 + 全量契约**

Run: `flutter test test/features/equipment/domain/equipment_disposal_test.dart`
Expected: PASS

- [ ] **Step 6: 提交**

```bash
git add lib/features/equipment/domain/equipment_disposal.dart lib/data/numbers_config.dart data/numbers.yaml test/features/equipment/domain/equipment_disposal_test.dart
git commit -m "装备出售/分解纯函数 + numbers.yaml disposal 配置"
```

---

## Task 2: 出售/分解 service（单件）+ 删装备

**Files:**
- Create: `lib/features/equipment/application/equipment_disposal_service.dart`
- Test: `test/features/equipment/application/equipment_disposal_service_test.dart`

**接口约定：**
```dart
enum DisposalOutcome { sold, disassembled, rejectedEquipped, rejectedHeritage, notFound }
```

- [ ] **Step 1: 写失败测试**（用真 Isar 临时实例，沿 `shop_service_test` 体例：`test()` 不用 testWidgets）

```dart
// 关键断言（写全部）：
// 1. sell 背包装备 → 返回 DisposalOutcome.sold；该 equipment 从 isar 删除；
//    item_silver quantity 增加 = equipmentSellPrice(...)。
// 2. disassemble 背包装备 → disassembled；equipment 删除；
//    item_mojianshi / item_xinxuejiejing quantity 增加 = rewards（已有行则累加，无则新建）。
// 3. sell/disassemble 已装备(ownerCharacterId != null) → rejectedEquipped；
//    equipment 仍在；银两/材料不变。
// 4. sell/disassemble 师承遗物(isLineageHeritage) → rejectedHeritage；不变。
// 5. 不存在的 id → notFound。
```

测试 setUp 用内存 Isar：参照 `test/features/shop/shop_service_test.dart` 的 Isar 打开方式（同目录约定 + libisar.dylib 已就位）。构造装备用 `Equipment.create(...)`，材料/银两用 `InventoryItem()..defId=..`。

- [ ] **Step 2: 运行验证失败**

Run: `flutter test test/features/equipment/application/equipment_disposal_service_test.dart`
Expected: FAIL（service 不存在）

- [ ] **Step 3: 实现 service**

```dart
// lib/features/equipment/application/equipment_disposal_service.dart
import 'package:isar_community/isar.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/equipment.dart';
import '../../../core/domain/inventory_item.dart';
import '../domain/equipment_disposal.dart';

enum DisposalOutcome { sold, disassembled, rejectedEquipped, rejectedHeritage, notFound }

/// 装备出售/分解 service（2026-06-26 红线推翻）。原子事务：校验 → 删装备 → 入银两/材料。
/// **守卫**：已装备(ownerCharacterId!=null)/师承遗物(isLineageHeritage) 不可处置。
class EquipmentDisposalService {
  EquipmentDisposalService({required this.isar, required this.config});
  final Isar isar;
  final EquipmentDisposalConfig config;

  Future<DisposalOutcome> sell(int equipmentId) => isar.writeTxn(() async {
        final eq = await isar.equipments.get(equipmentId);
        final guard = _guard(eq);
        if (guard != null) return guard;
        final price = equipmentSellPrice(eq!.tier, eq.enhanceLevel, config);
        await isar.equipments.delete(equipmentId);
        await _addItem('item_silver', ItemType.silver, price);
        return DisposalOutcome.sold;
      });

  Future<DisposalOutcome> disassemble(int equipmentId) => isar.writeTxn(() async {
        final eq = await isar.equipments.get(equipmentId);
        final guard = _guard(eq);
        if (guard != null) return guard;
        final r = equipmentDisassembleRewards(eq!.tier, eq.enhanceLevel, config);
        await isar.equipments.delete(equipmentId);
        if (r.mojianshi > 0) await _addItem('item_mojianshi', ItemType.moJianShi, r.mojianshi);
        if (r.xinxuejiejing > 0) {
          await _addItem('item_xinxuejiejing', ItemType.xinXueJieJing, r.xinxuejiejing);
        }
        return DisposalOutcome.disassembled;
      });

  /// null = 可处置；否则返回拒绝/未找到结果。
  DisposalOutcome? _guard(Equipment? eq) {
    if (eq == null) return DisposalOutcome.notFound;
    if (eq.ownerCharacterId != null) return DisposalOutcome.rejectedEquipped;
    if (eq.isLineageHeritage) return DisposalOutcome.rejectedHeritage;
    return null;
  }

  /// upsert（仿 ShopService 76-89）：已有行累加，无则新建。须在 writeTxn 内调。
  Future<void> _addItem(String defId, ItemType type, int amount) async {
    final now = DateTime.now();
    final existing = await isar.inventoryItems.getByDefId(defId);
    if (existing != null) {
      existing.quantity += amount;
      existing.lastObtainedAt = now;
      await isar.inventoryItems.put(existing);
    } else {
      await isar.inventoryItems.put(InventoryItem()
        ..defId = defId
        ..itemType = type
        ..quantity = amount
        ..firstObtainedAt = now
        ..lastObtainedAt = now);
    }
  }
}
```

- [ ] **Step 4: 运行测试验证通过**

Run: `flutter test test/features/equipment/application/equipment_disposal_service_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/equipment/application/equipment_disposal_service.dart test/features/equipment/application/equipment_disposal_service_test.dart
git commit -m "装备出售/分解 service 单件 + 已装备/师承守卫"
```

---

## Task 3: 批量按品级处置

**Files:**
- Modify: `lib/features/equipment/application/equipment_disposal_service.dart`
- Test: `test/features/equipment/application/equipment_disposal_service_test.dart`（追加）

- [ ] **Step 1: 写失败测试**

```dart
// 追加断言：
// 1. 准备同 tier 多件：2 件背包 + 1 件已装备 + 1 件师承遗物（同 tier）。
//    sellAllOfTier(tier) → BulkDisposalResult(count==2, totalSilver==两件价之和)；
//    已装备 + 师承遗物仍在 isar（未被处置）。
// 2. disassembleAllOfTier(tier) → count==2，totalMojianshi/totalXinxuejiejing 为两件之和。
// 3. 空 tier → count==0，无写入。
```

- [ ] **Step 2: 运行验证失败**

Run: `flutter test test/features/equipment/application/equipment_disposal_service_test.dart`
Expected: FAIL（`sellAllOfTier` 未定义）

- [ ] **Step 3: 实现批量**

```dart
// 加 BulkDisposalResult 数据类 + 两方法。整批在一个 writeTxn 内（失败回滚）。
class BulkDisposalResult {
  final int count;
  final int totalSilver;
  final int totalMojianshi;
  final int totalXinxuejiejing;
  const BulkDisposalResult({
    this.count = 0, this.totalSilver = 0,
    this.totalMojianshi = 0, this.totalXinxuejiejing = 0,
  });
}

// 类内新增（_disposable 复用 _guard 逻辑筛选）：
Future<List<Equipment>> _disposableOfTier(EquipmentTier tier) async {
  final all = await isar.equipments.filter().tierEqualTo(tier).findAll();
  return all.where((e) => e.ownerCharacterId == null && !e.isLineageHeritage).toList();
}

Future<BulkDisposalResult> sellAllOfTier(EquipmentTier tier) => isar.writeTxn(() async {
  final items = await _disposableOfTier(tier);
  var total = 0;
  for (final eq in items) {
    total += equipmentSellPrice(eq.tier, eq.enhanceLevel, config);
    await isar.equipments.delete(eq.id);
  }
  if (total > 0) await _addItem('item_silver', ItemType.silver, total);
  return BulkDisposalResult(count: items.length, totalSilver: total);
});

Future<BulkDisposalResult> disassembleAllOfTier(EquipmentTier tier) => isar.writeTxn(() async {
  final items = await _disposableOfTier(tier);
  var mj = 0, xx = 0;
  for (final eq in items) {
    final r = equipmentDisassembleRewards(eq.tier, eq.enhanceLevel, config);
    mj += r.mojianshi; xx += r.xinxuejiejing;
    await isar.equipments.delete(eq.id);
  }
  if (mj > 0) await _addItem('item_mojianshi', ItemType.moJianShi, mj);
  if (xx > 0) await _addItem('item_xinxuejiejing', ItemType.xinXueJieJing, xx);
  return BulkDisposalResult(count: items.length, totalMojianshi: mj, totalXinxuejiejing: xx);
});
```

> 注：`tierEqualTo` 由 Isar 对 `@Enumerated tier` 自动生成（已索引则更快；未索引也可 filter）。实装时若签名不符，查 `equipment.g.dart` 生成的 filter 方法名。

- [ ] **Step 4: 运行测试验证通过**

Run: `flutter test test/features/equipment/application/equipment_disposal_service_test.dart`
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add lib/features/equipment/application/equipment_disposal_service.dart test/features/equipment/application/equipment_disposal_service_test.dart
git commit -m "装备批量按品级出售/分解 + 排除已装备/师承护栏"
```

---

## Task 4: UiStrings 新增串

**Files:**
- Modify: `lib/shared/strings.dart`

- [ ] **Step 1: 加串**（无独立测试，后续 UI task 引用即验）

在 `UiStrings` 加（中文文案，参照既有体例）：

```dart
// 装备出售/分解(2026-06-26)
static const String equipmentSell = '出售';
static const String equipmentDisassemble = '分解';
static const String equipmentBulkEntry = '批量整理';
static const String equippedBadge = '装备中';
static const String inventoryShopEntry = '进商店';
static String sellConfirmBody(int count, int silver) => '将出售 $count 件装备，获得银两 $silver。';
static String disassembleConfirmBody(int count, int mojianshi, int xinxue) =>
    '将分解 $count 件装备，获得磨剑石 $mojianshi' + (xinxue > 0 ? ' / 心血结晶 $xinxue' : '') + '。';
static String sellSingleConfirmBody(String name, int silver) => '出售「$name」，获得银两 $silver。';
static String disassembleSingleConfirmBody(String name, int mojianshi, int xinxue) =>
    '分解「$name」，获得磨剑石 $mojianshi' + (xinxue > 0 ? ' / 心血结晶 $xinxue' : '') + '。';
static const String disposalRejectedEquipped = '装备穿戴中，不可处置。';
static const String disposalRejectedHeritage = '师承遗物不可处置。';
static String bulkTierLabel(String tierName, int count) => '$tierName（$count 件）';
```

- [ ] **Step 2: 编译校验**

Run: `flutter analyze lib/shared/strings.dart`
Expected: No issues

- [ ] **Step 3: 提交**

```bash
git add lib/shared/strings.dart
git commit -m "装备处置/批量/已装备标记 UiStrings"
```

---

## Task 5: 单件出售/分解入口（详情页）

**Files:**
- Modify: `lib/features/equipment/presentation/equipment_detail_screen.dart`
- Test: `test/features/equipment/presentation/equipment_detail_screen_test.dart`（新建或追加）

- [ ] **Step 1: 读详情页结构**

实装前 Read `equipment_detail_screen.dart` 全文，定位底部操作区（强化/开锋按钮处），在背包态（`equipment.ownerCharacterId == null && !isLineageHeritage`）追加「出售」「分解」按钮。已装备/师承遗物时不显示这两个按钮。

- [ ] **Step 2: 写失败 widget 测**

```dart
// 断言：
// 1. 背包装备详情页 → 「出售」「分解」按钮可见（find.text(UiStrings.equipmentSell) findsOneWidget）。
// 2. 已装备(ownerCharacterId != null)装备 → 两按钮 findsNothing。
// 3. 师承遗物 → 两按钮 findsNothing。
// 用 ProviderScope + 真 IsarSetup（参照既有 inventory/equipment widget 测体例）。
```

- [ ] **Step 3: 运行验证失败**

Run: `flutter test test/features/equipment/presentation/equipment_detail_screen_test.dart`
Expected: FAIL

- [ ] **Step 4: 实现**

- 点「出售」→ `PaperDialog.show<bool>` 确认（`UiStrings.sellSingleConfirmBody(def.name, equipmentSellPrice(...))`）→ `EquipmentDisposalService(isar: IsarSetup.instance, config: GameRepository.instance.numbers.disposal).sell(eq.id)` → 结果浮层 + `Navigator.pop`（装备已删，回仓库）+ `ref.invalidate(allEquipmentsProvider)` / `allInventoryItemsProvider` / `silverBalanceProvider`。
- 「分解」同理走 `disassemble` + `disassembleSingleConfirmBody`。
- 价/料预览在确认框内用纯函数 `equipmentSellPrice` / `equipmentDisassembleRewards` 计算（domain 已有）。

- [ ] **Step 5: 运行测试 + 提交**

Run: `flutter test test/features/equipment/presentation/equipment_detail_screen_test.dart`
Expected: PASS
```bash
git add lib/features/equipment/presentation/equipment_detail_screen.dart test/features/equipment/presentation/equipment_detail_screen_test.dart
git commit -m "装备详情页单件出售/分解入口(背包态)"
```

---

## Task 6: 批量整理对话框（一键按品级）

**Files:**
- Create: `lib/features/inventory/presentation/bulk_disposal_dialog.dart`
- Modify: `lib/features/inventory/presentation/inventory_screen.dart`（装备 tab 顶部加「批量整理」按钮，弹此对话框）
- Test: `test/features/inventory/presentation/bulk_disposal_dialog_test.dart`

- [ ] **Step 1: 写失败 widget 测**

```dart
// 断言：
// 1. 对话框列出有可处置装备的品阶行（EnumL10n.equipmentTier + 可处置件数，
//    件数已排除已装备/师承）。
// 2. 某 tier 行有「一键出售」「一键分解」按钮。
// 3. 点「一键出售」→ 二次确认框显 sellConfirmBody(count, silver)；确认后
//    该 tier 可处置装备从 isar 消失、银两增加、已装备/师承装备仍在。
```

- [ ] **Step 2: 运行验证失败 → Step 3 实现**

对话框：`ProviderScope` 内 watch `allEquipmentsProvider`，按 tier 分桶并过滤 `ownerCharacterId==null && !isLineageHeritage`，每个非空 tier 一行（`UiStrings.bulkTierLabel(EnumL10n.equipmentTier(tier), count)` + 出售/分解按钮）。点击 → `PaperDialog` 二次确认（预览 total）→ `EquipmentDisposalService.sellAllOfTier(tier)` / `disassembleAllOfTier(tier)` → invalidate 三 provider + 关闭/刷新。全品阶可批量（含宝物/神物），都走二次确认（用户拍板）。

入口：`inventory_screen.dart` 装备 tab（`_EquipmentTab` build 内 `_FilterBar` 旁或上方）加 `PlaqueButton(label: UiStrings.equipmentBulkEntry, onTap: 弹 BulkDisposalDialog)`。

- [ ] **Step 4: 运行测试 + 提交**

Run: `flutter test test/features/inventory/presentation/bulk_disposal_dialog_test.dart`
Expected: PASS
```bash
git add lib/features/inventory/presentation/bulk_disposal_dialog.dart lib/features/inventory/presentation/inventory_screen.dart test/features/inventory/presentation/bulk_disposal_dialog_test.dart
git commit -m "批量整理对话框:一键按品级出售/分解(排除已装备/师承)"
```

---

## Task 7: 已装备视觉标记

**Files:**
- Modify: `lib/features/inventory/presentation/inventory_screen.dart`（`_EquipmentGridTile`）
- Test: `test/features/inventory/presentation/inventory_screen_test.dart`（追加）

- [ ] **Step 1: 写失败 widget 测**

```dart
// 断言：
// 1. ownerCharacterId != null 的装备格子 → 显「装备中」角标
//    (find.text(UiStrings.equippedBadge) findsWidgets)。
// 2. 背包装备(ownerCharacterId == null) → 不显该角标。
```

- [ ] **Step 2: 运行验证失败 → Step 3 实现**

在 `_EquipmentGridTile` 的 `Stack`（:442-470）追加：`ownerCharacterId != null` 时一个 `Positioned`（右下或底部条），显 `UiStrings.equippedBadge`（小号文字 + 半透明底，颜色 `WuxiaColors.textPrimary`）。与师承 ★（左上 :459）、境界锁灰化（ItemSlot.locked）层级不冲突——放不同角。

- [ ] **Step 4: 运行测试 + 提交**

Run: `flutter test test/features/inventory/presentation/inventory_screen_test.dart`
Expected: PASS
```bash
git add lib/features/inventory/presentation/inventory_screen.dart test/features/inventory/presentation/inventory_screen_test.dart
git commit -m "仓库装备格子加「装备中」标记"
```

---

## Task 8: 商店入口

**Files:**
- Modify: `lib/features/inventory/presentation/inventory_screen.dart`
- Test: `test/features/inventory/presentation/inventory_screen_test.dart`（追加）

- [ ] **Step 1: 写失败 widget 测**

```dart
// 断言：物料 tab(或仓库顶部)有「进商店」按钮(find.text(UiStrings.inventoryShopEntry))；
// 点击后 ShopScreen 入栈(find.byType(ShopScreen) findsOneWidget)。
```

- [ ] **Step 2: 运行验证失败 → Step 3 实现**

`_MaterialTab` 银两货币行（:264-281 Row）末尾加 `PlaqueButton(label: UiStrings.inventoryShopEntry, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopScreen())))`。import `shop_screen.dart`。

- [ ] **Step 4: 运行测试 + 提交**

Run: `flutter test test/features/inventory/presentation/inventory_screen_test.dart`
Expected: PASS
```bash
git add lib/features/inventory/presentation/inventory_screen.dart test/features/inventory/presentation/inventory_screen_test.dart
git commit -m "仓库物料 tab 加进商店入口"
```

---

## Task 9: 物料界面格子化

**Files:**
- Modify: `lib/features/inventory/presentation/inventory_screen.dart`（`_MaterialList` / `_MaterialGroup` / `_MaterialRow` → 格子布局）
- Test: `test/features/inventory/presentation/inventory_screen_test.dart`（追加 / 调整）

- [ ] **Step 1: 写/调 widget 测**

```dart
// 断言：物料 tab 渲染后，每种材料以格子(ItemSlot 或类格子容器)呈现，
// 显数量(find.textContaining('×') 或 quantity)；可用类(经验丹/秘籍)仍有「使用」入口。
// 注意 ListView viewport：testWidgets 用 tester.view.physicalSize 扩大或 setSurfaceSize(800,2000)
// (memory feedback_listview_widget_test_viewport)。
```

- [ ] **Step 2: 运行验证失败 → Step 3 实现**

把 `_MaterialGroup` 的 ExpansionTile 列表行改为：组标题（`EnumL10n.itemType` + 计数）下方一个 `Wrap`，每项用 `ItemSlot` 风格格子（图标 + 数量角标）。可用类（经验丹/秘籍 `_usable`）格子保留「使用」交互（点击格子或格子上小按钮 → 现有 `_onUse` 流程）。货币行（银两）保留在 `_MaterialTab` 顶部不变。

> 复用既有 `ItemSlot`（`shared/widgets/wuxia_ui/item_slot.dart`）；材料无 tier，用中性边框色。`_onUse` 逻辑整体保留，仅触发入口从行末按钮改格子交互。

- [ ] **Step 4: 运行测试 + 提交**

Run: `flutter test test/features/inventory/presentation/inventory_screen_test.dart`
Expected: PASS
```bash
git add lib/features/inventory/presentation/inventory_screen.dart test/features/inventory/presentation/inventory_screen_test.dart
git commit -m "物料界面格子化(像装备网格)"
```

---

## Task 10: 放慢升级速度

**Files:**
- Modify: `data/numbers.yaml`（`level` 段 exp 曲线）
- Modify: `lib/features/level/domain/level_config.dart`（`fromYaml` 默认值同步，保持「默认=生产初值」honest）
- Test: 全仓 grep 同步 + 契约

- [ ] **Step 1: grep 现有 exp 断言**

Run: `grep -rn "exp_to_next\|expToNextBase\|expToNextPerLevel\|expToNext(" test/ lib/`
确认哪些断言钉死 120/40。已知 `test/features/level/level_service_test.dart` 用自定义 cfg(100/50) 不受影响。若有契约测读真 numbers.yaml 的 120/40，同步改。

- [ ] **Step 2: 改 numbers.yaml**

`data/numbers.yaml` `level:` 段：`exp_to_next_base: 120` → `200`，`exp_to_next_per_level: 40` → `80`。更新该行注释为「2026-06-26 放慢升级·待真机校」。

- [ ] **Step 3: 同步 LevelConfig.fromYaml 默认值**

`level_config.dart:39-40`：`?? 120` → `?? 200`，`?? 40` → `?? 80`（保持注释「缺省=生产初值」honest，防 drift）。

- [ ] **Step 4: 跑相关 + 全量**

Run: `flutter test test/features/level/ test/features/cultivation/`
Expected: PASS（若有读真 yaml 的断言失败，按新值 200/80 同步）

- [ ] **Step 5: 提交**

```bash
git add data/numbers.yaml lib/features/level/domain/level_config.dart
git commit -m "[balance] 放慢角色升级速度 exp 曲线 120/40→200/80"
```

---

## Task 11: 红线文档推翻（GDD / CLAUDE / shop 头注）

**Files:**
- Modify: `GDD.md`（§2.1 反主流清单）
- Modify: `CLAUDE.md`（§5.1 + §9 操作清单）
- Modify: `lib/features/shop/application/shop_service.dart:12`（头注）

- [ ] **Step 1: GDD §2.1**

把「装备分解 | 装备永久保留，作为收藏品」行改为记录推翻：装备**可出售换银两 / 可分解成强化材料**（2026-06-26 用户拍板推翻，理由：玩家处理冗余装备的真实需求；出售/分解为良性 sink，非氪金/留存机制）。保留其余反主流项（体力/每日/登录/战令/抽卡/VIP/留存焦虑）不动。

- [ ] **Step 2: CLAUDE §5.1 + §9**

§5.1 反主流清单移除「装备分解」（及任何「卖出」表述）；§9 操作清单若有「装备永久保留」相关项同步。加一行 vN.x 变更摘要注明 2026-06-26 推翻 + spec 链接。

- [ ] **Step 3: shop_service.dart 头注**

`:12` 「只买不卖（§5.1 不做卖出/退款）」→ 订正为「购买在此 service；出售/分解见 `EquipmentDisposalService`（2026-06-26 红线推翻）」。

- [ ] **Step 4: 提交**

```bash
git add GDD.md CLAUDE.md lib/features/shop/application/shop_service.dart
git commit -m "[GDD] 推翻装备永久收藏品/只买不卖红线:开放出售+分解(2026-06-26 拍板)"
```

---

## Task 12: 收尾验证 + PROGRESS

- [ ] **Step 1: 全量 analyze**

Run: `flutter analyze`
Expected: 0 issues（基线 0）

- [ ] **Step 2: 全量测试**

Run: `flutter test`
Expected: 全绿（基线 3141+1skip + 本批新增测，0 回归）。记录实测数字。

- [ ] **Step 3: 更新 PROGRESS.md 顶段**（追加「续6」一条，含 commit 区间 + 红线推翻决策 + 测试增量 + 未真机目检标注）

- [ ] **Step 4: 提交 PROGRESS**

```bash
git add PROGRESS.md
git commit -m "PROGRESS:装备出售/分解+仓库改进+升级放慢 续6"
```

---

## Self-Review（plan 对 spec 覆盖核对）

- spec A 出售 → Task 1（纯函数+配置）+ Task 2（service）✓
- spec B 分解 → Task 1 + Task 2 ✓
- spec C service+仓储（deleteEquipment）→ Task 2（`isar.equipments.delete` 直接用，无需单独 repo 方法）✓
- spec D 一键批量 → Task 3（service）+ Task 6（UI 对话框）✓ ；**落点修正**：按品级批量做成独立「批量整理」对话框（装备 tab 实为按 slot 分组，非 tier 分组头），忠于「一键按品级」意图。
- spec E 已装备标记 → Task 7 ✓
- spec F 商店入口 → Task 8 ✓
- spec G 物料格子化 → Task 9 ✓
- spec H 放慢升级 → Task 10 ✓
- spec 红线决策史 → Task 11 ✓
- 单件出售/分解入口 → Task 5（spec C 提 EquipmentDetailScreen 落点）✓
- UiStrings → Task 4 ✓
- 测试策略（纯函数/service test() + UI testWidgets）→ 各 task 内 ✓

**类型一致性核对**：`DisposalOutcome` / `BulkDisposalResult` / `DisassembleRewards` / `EquipmentDisposalConfig` / `equipmentSellPrice` / `equipmentDisassembleRewards` 跨 Task 1-3-5-6 命名一致 ✓。

**无占位**：各 code step 含真实代码；UI task 因需读现有屏结构，给出明确落点行号 + 复用组件 + 断言，实装时 Read 对应文件。
