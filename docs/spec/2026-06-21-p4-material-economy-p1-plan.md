# P1 经济核心 实装 Plan — 银两 + 江湖商店 + 材料背包货币位

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐 task 实装。步骤用 `- [ ]` 勾选。
> 源 spec：`docs/spec/2026-06-21-p4-material-economy-design.md`（P1 段）。P2 新材料用途另起 plan。

**Goal:** 加入银两货币（存 `InventoryItem` 的 `item_silver` 行）+ 江湖商店（固定货架卖磨剑石/心血结晶）+ 背包/商店货币位展示，形成 掉落/闭关→银两→商店买材料 的自洽经济闭环。

**Architecture:** 银两复用既有 `InventoryItem` 掉落/库存管线（新增 `ItemType.silver` 枚举值，**不改 SaveData schema、不 bump saveVer**）。商店走 `ShopItemDef` + `data/shop.yaml` + `GameRepository` 加载 + 购买 service，UI 仿 `WeaponCodexScreen` 体例。

**Tech Stack:** Flutter Desktop / Riverpod 3.x / Isar / YAML def + GameRepository 红线校验。

**红线护栏（全程）:** §5.1 商店固定标价无随机/限购/刷新、不卖出；§5.5 银两离线=在线；§5.4 数值进 yaml；§5.6 文案进 UiStrings/EnumL10n。

---

## 文件结构（P1 创建/修改）

**新建：**
- `lib/data/defs/shop_item_def.dart` — ShopItemDef 实体 + fromYaml
- `data/shop.yaml` — 货品配置（id/itemDefId/itemType/price/货架分组）
- `lib/features/shop/application/shop_service.dart` — 购买逻辑（扣 item_silver、入货品）
- `lib/features/shop/application/shop_providers.dart` — silverBalance / shopUnlocked / shopItemList provider
- `lib/features/shop/presentation/shop_screen.dart` — 商店主屏
- `test/features/shop/shop_service_test.dart`、`test/data/shop_def_test.dart`、`test/features/shop/shop_screen_test.dart`

**修改：**
- `lib/core/domain/enums.dart` — ItemType 加 `silver`
- `lib/features/battle/domain/enum_localizations.dart:186-192` — itemType switch 加 `ItemType.silver => '银两'`
- `lib/data/game_repository.dart` — 加 `shopItemDefs` 字段 + loadAllDefs 解析 + `_enforceRedLines` 标价校验
- `lib/shared/strings.dart` — UiStrings 加商店/货币文案
- `data/numbers.yaml` — retreat.maps[*].base_outputs 加 `silver_per_hour`
- `lib/features/seclusion/application/seclusion_service.dart` — computeOutputs 加 silver 产出 + completeRetreat 入库
- `lib/data/defs/`（闭关 map def 类）— 解析 silverPerHour
- `data/stages.yaml` + `data/towers.yaml` — dropTable 加 item_silver 条目
- `lib/features/inventory/presentation/inventory_screen.dart` — item_silver 排除材料网格 + 货币顶栏
- `lib/features/main_menu/presentation/main_menu.dart:341-354` 区 — 商店入口（shopUnlocked 门控）

---

## Task 1: ItemType.silver 枚举值 + 显示名

**Files:**
- Modify: `lib/core/domain/enums.dart`（ItemType enum，参 `enums.dart:19-20` 既有材料值）
- Modify: `lib/features/battle/domain/enum_localizations.dart:186-192`
- Test: `test/features/battle/enum_localizations_test.dart`（既有，加断言）

- [ ] **Step 1: 写失败测试** — 在 enum_localizations_test.dart 加：
```dart
test('ItemType.silver 显示名为 银两', () {
  expect(EnumL10n.itemType(ItemType.silver), '银两');
});
```
- [ ] **Step 2: 跑测试确认 fail** — `flutter test test/features/battle/enum_localizations_test.dart`，预期编译失败（`silver` 未定义）。
- [ ] **Step 3: 实装** —
  - `enums.dart` ItemType enum **末尾**追加 `silver`（追加避免移动既有 index；@Enumerated by name 持久化天然兼容）。
  - `enum_localizations.dart` itemType switch 加分支 `ItemType.silver => '银两',`（switch 穷尽，编译器会强制补）。
- [ ] **Step 4: 跑测试确认 pass** — 同 Step 2 命令，预期 PASS。
- [ ] **Step 5: 跑全项目 analyze** — `flutter analyze`，预期 0 issue（switch 穷尽性已补）。
- [ ] **Step 6: commit** — `git add -A && git commit -m "材料经济P1:加 ItemType.silver 银两枚举值"`

## Task 2: 闭关产出银两（silver_per_hour）

**Files:**
- Modify: `data/numbers.yaml`（retreat.maps[*].base_outputs，参既有 `mojianshi_per_hour`）
- Modify: 闭关 map def 类（grep `mojianshiPerHour` 定位 def 类文件）+ fromYaml
- Modify: `lib/features/seclusion/application/seclusion_service.dart`（computeOutputs:172-263 + completeRetreat:320-332 + _addInventoryItem:578-599）
- Test: `test/features/seclusion/seclusion_service_test.dart`（既有，加银两产出断言）

- [ ] **Step 1: 写失败测试** — 仿既有 mojianshi 产出测，断言某 map 闭关 N 小时产出 `item_silver` 数量 = `floor(silverPerHour * hours * scale * solarBonus)`，并 `_addInventoryItem` 入库后 `inventoryItems.getByDefId('item_silver').quantity` 等于该值。
- [ ] **Step 2: 跑测试确认 fail** — `flutter test test/features/seclusion/seclusion_service_test.dart`，预期 fail（silverPerHour 未定义/产出为 0）。
- [ ] **Step 3: 实装** —
  - numbers.yaml 每个 retreat map 的 base_outputs 加 `silver_per_hour:`（数值按地图梯度，低阶低、高阶高；具体值在 balance 阶段调，先给保守占位如 山林 5 / 别院 8 / 递增）。
  - map def 类加 `silverPerHour` 字段 + fromYaml 解析 `(y['silver_per_hour'] as num?)?.toDouble() ?? 0.0`。
  - computeOutputs 加 `final silver = (def.silverPerHour * actualHours * scale * solarBonus).floor().clamp(0, 999999);` 并塞进 outputs 结构（加字段）。
  - completeRetreat writeTxn 内仿 mojianshi 块：`if (outputs.silver > 0) await _addInventoryItem(isar, defId: 'item_silver', itemType: ItemType.silver, quantity: outputs.silver, now: now);`
- [ ] **Step 4: 跑测试确认 pass** — 同 Step 2，预期 PASS。
- [ ] **Step 5: analyze** — `flutter analyze`，预期 0。
- [ ] **Step 6: commit** — `git add -A && git commit -m "材料经济P1:闭关产出银两 silver_per_hour"`

## Task 3: dropTable 掉落银两

**Files:**
- Modify: `data/stages.yaml`（各关 dropTable 加 item_silver 条目）
- Modify: `data/towers.yaml`（各层 dropTable 加 item_silver 条目）
- Test: `test/features/equipment/drop_service_test.dart`（既有，加 item_silver 掉落断言）

> DropService 已支持 ItemDrop（`drop_service.dart:70-78` + `_rollTable:86-107`），本 task 纯配置 + 验证，无 service 改动。

- [ ] **Step 1: 写失败测试** — 构造含 `ItemDrop(inventoryItemDefId:'item_silver', quantity:[10,20], dropChance:1.0)` 的 StageDef，`DropService().rollDrops(stage, seededRng)`，断言 `result.items` 含 defId=='item_silver' 且 quantity ∈ [10,20]。
- [ ] **Step 2: 跑测试确认 fail/pass 边界** — `flutter test test/features/equipment/drop_service_test.dart`。若 DropService 已支持则此测直接 PASS（说明管线就绪），重点是确认 item_silver 走通。
- [ ] **Step 3: 配置** — stages.yaml 主线关、towers.yaml 各层 dropTable 加 `- inventoryItemDefId: item_silver` + `quantity: [min,max]` + `dropChance`（数值保守，balance 阶段调；通关关给定量、Boss/高层给更多）。
- [ ] **Step 4: 跑全量 drop + 配置加载测** — `flutter test test/data/ test/features/equipment/drop_service_test.dart`，确认 yaml 加载不报 schema 错、掉落产出 item_silver。
- [ ] **Step 5: analyze** — 预期 0。
- [ ] **Step 6: commit** — `git add -A && git commit -m "材料经济P1:dropTable 掉落银两"`

## Task 4: ShopItemDef + shop.yaml + GameRepository 加载

**Files:**
- Create: `lib/data/defs/shop_item_def.dart`（仿 `lib/data/defs/equipment_def.dart:66-96` fromYaml 体例）
- Create: `data/shop.yaml`
- Modify: `lib/data/game_repository.dart`（加 `shopItemDefs` 字段:31-110 区 + loadAllDefs:140-154 区解析 + `_enforceRedLines`:456-473 加标价校验）
- Test: `test/data/shop_def_test.dart`

- [ ] **Step 1: 写失败测试** —
```dart
test('shop.yaml 加载为 ShopItemDef 且标价>0', () async {
  await GameRepository.loadAllDefs(); // 或测试用加载入口
  final defs = GameRepository.instance.shopItemDefs;
  expect(defs.isNotEmpty, true);
  final mojian = defs['shop_mojianshi'];
  expect(mojian, isNotNull);
  expect(mojian!.itemDefId, 'item_mojianshi');
  expect(mojian.price > 0, true);
});
test('标价超上限抛红线错', () { /* 构造 price>上限 def，期望 _enforceRedLines throw StateError */ });
```
- [ ] **Step 2: 跑测试确认 fail** — `flutter test test/data/shop_def_test.dart`，预期 fail（shopItemDefs/ShopItemDef 未定义）。
- [ ] **Step 3: 实装** —
  - `shop_item_def.dart`：
```dart
class ShopItemDef {
  final String id;          // 'shop_mojianshi'
  final String itemDefId;   // 'item_mojianshi'（购买后入库的 InventoryItem defId）
  final ItemType itemType;  // ItemType.moJianShi
  final int price;          // 银两标价
  final String category;    // 货架分组 key（material 等）
  const ShopItemDef({required this.id, required this.itemDefId,
      required this.itemType, required this.price, required this.category});
  factory ShopItemDef.fromYaml(Map<String, dynamic> y) => ShopItemDef(
        id: y['id'] as String,
        itemDefId: y['itemDefId'] as String,
        itemType: ItemType.values.byName(y['itemType'] as String),
        price: (y['price'] as num).toInt(),
        category: y['category'] as String,
      );
}
```
  - `data/shop.yaml`（P1 只 2 材料）：
```yaml
shop:
  - id: shop_mojianshi
    itemDefId: item_mojianshi
    itemType: moJianShi
    price: 30
    category: material
  - id: shop_xinxue_jiejing
    itemDefId: item_xinxuejiejing
    itemType: xinXueJieJing
    price: 120
    category: material
```
  - GameRepository：加 `final Map<String, ShopItemDef> shopItemDefs;`，loadAllDefs 仿 equipment 解析（`_parseDefMap(shopRaw['shop'] as List, ShopItemDef.fromYaml, idOf:(d)=>d.id)`），构造塞入；`_enforceRedLines` 末尾加：`for (final d in shopItemDefs.values) { if (d.price > 100000) throw StateError('红线:商店 ${d.id} 标价 ${d.price} > 100000'); }`
- [ ] **Step 4: 跑测试确认 pass** — 同 Step 2，预期 PASS。
- [ ] **Step 5: analyze** — 预期 0。
- [ ] **Step 6: commit** — `git add -A && git commit -m "材料经济P1:ShopItemDef + shop.yaml + GameRepository 加载"`

## Task 5: ShopService 购买逻辑

**Files:**
- Create: `lib/features/shop/application/shop_service.dart`
- Test: `test/features/shop/shop_service_test.dart`

> 银两 = `item_silver` InventoryItem。购买 = 校验 item_silver.quantity >= price → 扣 silver → 加货品（仿 `_addInventoryItem` upsert）。

- [ ] **Step 1: 写失败测试** —
```dart
test('银两充足购买成功:扣银两+入货', () async {
  // 预置 item_silver quantity=100
  final r = await ShopService.purchase(isar, def: mojianDef); // price 30
  expect(r.success, true);
  expect((await isar.inventoryItems.getByDefId('item_silver'))!.quantity, 70);
  expect((await isar.inventoryItems.getByDefId('item_mojianshi'))!.quantity, 1);
});
test('银两不足拒绝:不扣不入', () async {
  // item_silver quantity=10, price 30
  final r = await ShopService.purchase(isar, def: mojianDef);
  expect(r.success, false);
  expect((await isar.inventoryItems.getByDefId('item_silver'))!.quantity, 10);
});
```
- [ ] **Step 2: 跑测试确认 fail** — `flutter test test/features/shop/shop_service_test.dart`，预期 fail（ShopService 未定义）。
- [ ] **Step 3: 实装** — ShopService.purchase：writeTxn 内读 item_silver 行，quantity<price 返回 `PurchaseResult(success:false, reason:不足)`；否则 silver.quantity-=price、put，再 upsert 货品（getByDefId 存在则 +=1 否则新建，仿 seclusion `_addInventoryItem:578-599`），返回 success。**不做卖出方法**。
- [ ] **Step 4: 跑测试确认 pass** — 同 Step 2，预期 PASS。
- [ ] **Step 5: analyze** — 预期 0。
- [ ] **Step 6: commit** — `git add -A && git commit -m "材料经济P1:ShopService 购买扣银两入货"`

## Task 6: 货币 / 解锁 / 货架 provider

**Files:**
- Create: `lib/features/shop/application/shop_providers.dart`
- Test: `test/features/shop/shop_providers_test.dart`

- [ ] **Step 1: 写失败测试** — 断言：
  - `silverBalanceProvider` 在无 item_silver 行时返回 0；有行返回 quantity。
  - `shopUnlockedProvider` 在 item_silver 行存在（曾获银两）时 true，否则 false（仿 `equipmentCatalogCountProvider>0` 体例，main_menu.dart:341-354）。
  - `shopItemListProvider` 返回 `GameRepository.instance.shopItemDefs.values` 列表。
- [ ] **Step 2: 跑测试确认 fail** — `flutter test test/features/shop/shop_providers_test.dart`，预期 fail。
- [ ] **Step 3: 实装** — 三个 riverpod provider：silverBalance（query getByDefId('item_silver')?.quantity ?? 0）、shopUnlocked（getByDefId('item_silver') != null）、shopItemList（同步读 GameRepository）。
- [ ] **Step 4: 跑测试确认 pass** — 同 Step 2，预期 PASS。
- [ ] **Step 5: analyze** — 预期 0。
- [ ] **Step 6: commit** — `git add -A && git commit -m "材料经济P1:银两/解锁/货架 provider"`

## Task 7: UiStrings 商店/货币文案

**Files:**
- Modify: `lib/shared/strings.dart`（仿 `strings.dart:1-10` 既有词条）
- Test: 无独立测（被 T8 widget 测覆盖）；analyze 守编译

- [ ] **Step 1: 加文案常量** —
```dart
static const String mainMenuShop = '江湖商店';
static const String mainMenuShopHint = '采办所需，行走江湖';
static const String shopTitle = '江湖商店';
static const String shopBuy = '购买';
static const String shopInsufficientSilver = '银两不足';
static const String shopCategoryMaterial = '炼器材料';
static String silverBalanceLabel(int n) => '银两 $n';
static String shopItemPrice(int p) => '$p 两';
```
- [ ] **Step 2: analyze** — `flutter analyze`，预期 0。
- [ ] **Step 3: commit** — `git add -A && git commit -m "材料经济P1:商店/货币 UiStrings 文案"`

## Task 8: ShopScreen UI（货架 + 购买对话框 + 货币顶栏）

**Files:**
- Create: `lib/features/shop/presentation/shop_screen.dart`（仿 `weapon_codex_screen.dart:19-133` 体例）
- Test: `test/features/shop/shop_screen_test.dart`

- [ ] **Step 1: 写失败 widget 测** — `setSurfaceSize(1280,720)` + `addTearDown` 复位；override silverBalance/shopItemList provider；pump ShopScreen；断言：货币顶栏显示「银两 N」、货品卡显示磨剑石+标价、点购买弹确认、银两不足时购买按钮禁用或弹「银两不足」。
- [ ] **Step 2: 跑测试确认 fail** — `flutter test test/features/shop/shop_screen_test.dart`，预期 fail（ShopScreen 未定义）。
- [ ] **Step 3: 实装** — ConsumerStatefulWidget，Scaffold + `WuxiaTitleBar(title: UiStrings.shopTitle)` + 顶栏货币位（读 silverBalanceProvider）+ 货架按 category 分组（PaperPanel + 卡列）+ 点货品弹 PaperDialog 确认 → 调 ShopService.purchase → `ref.invalidate(silverBalanceProvider)` + 库存 provider 刷新。Image.asset 用 `wuxiaAssetErrorBuilder`（`asset_fallback.dart`）。
- [ ] **Step 4: 跑测试确认 pass** — 同 Step 2，预期 PASS。
- [ ] **Step 5: analyze** — 预期 0。
- [ ] **Step 6: commit** — `git add -A && git commit -m "材料经济P1:ShopScreen 货架+购买+货币顶栏"`

## Task 9: 背包货币位 + 主菜单商店入口

**Files:**
- Modify: `lib/features/inventory/presentation/inventory_screen.dart`（item_silver 排除材料网格 + 加货币顶栏；参 `_MaterialGroup:478-479`）
- Modify: `lib/features/main_menu/presentation/main_menu.dart`（341-354 区加商店入口，仿兵器谱）
- Test: `test/features/inventory/inventory_screen_test.dart`（既有，加货币断言）+ `test/features/main_menu/main_menu_test.dart`（既有，加入口断言）

- [ ] **Step 1: 写失败测试** —
  - inventory：item_silver 行不出现在材料分组列表，改以「银两 N」顶栏展示。
  - main_menu：shopUnlocked=true（有 item_silver）时渲染「江湖商店」入口按钮；false 时不渲染（隐藏式，§5.7）。
- [ ] **Step 2: 跑测试确认 fail** — `flutter test test/features/inventory/inventory_screen_test.dart test/features/main_menu/main_menu_test.dart`，预期 fail。
- [ ] **Step 3: 实装** —
  - inventory_screen：`allInventoryItemsProvider` 结果过滤掉 `itemType==ItemType.silver`，单独取其 quantity 渲染货币顶栏（`UiStrings.silverBalanceLabel`）。
  - main_menu：仿兵器谱 `if (shopUnlocked) WuxiaInkButton(label: UiStrings.mainMenuShop, hint: UiStrings.mainMenuShopHint, icon: Icons.storefront_outlined, onTap: ()=>_push(context, const ShopScreen()))`，shopUnlocked 读 shopUnlockedProvider。
- [ ] **Step 4: 跑测试确认 pass** — 同 Step 2，预期 PASS。
- [ ] **Step 5: analyze** — 预期 0。
- [ ] **Step 6: commit** — `git add -A && git commit -m "材料经济P1:背包货币位+主菜单商店入口"`

## Task 10: 全量回归 + 红线套件 + GDD 更新

**Files:**
- Modify: `GDD.md`（§12.2 #12 江湖商店：去「Demo 不列」→ 标记 P1 激活 + 固定标价规则，标题 `[GDD]`）
- Test: 全量

- [ ] **Step 1: 全量测** — `flutter test`，预期全绿零回归（记录基线 2688 → 新增数）。
- [ ] **Step 2: 红线套件** — 跑 §5.4 红线测族 + 确认商店无随机/限购代码路径（结构性：grep shop_service / shop_screen 无 random/refresh/dailyLimit）。
- [ ] **Step 3: analyze 全量** — `flutter analyze`，预期 0。
- [ ] **Step 4: GDD 更新** — §12.2 #12 改为「v1.21 P1 激活:江湖商店固定货架·固定标价·无刷新无限购·只卖材料·不卖出（§5.1 守）」。
- [ ] **Step 5: commit** — `git add -A && git commit -m "[GDD] 材料经济P1:江湖商店激活 + 全量回归绿"`

---

## 自检（plan 对 spec 覆盖）

- spec §4.1 银两(InventoryItem) → T1/T2/T3 ✅；§4.2 江湖商店 → T4/T5/T6/T8 ✅；§4.5 材料背包货币位 → T9 ✅；§3 锚9 解锁谓词 → T6/T9 ✅；锚10 存储 → T1 ✅。
- §4.3/4.4 经验丹/秘籍 = **P2 范围**，本 plan 不含（已在 spec 拆分表标 P2）。
- 红线护栏 → T10 Step2 结构性断言 + GDD 同步。
- 数值（标价/掉率/silver_per_hour）P1 给保守占位，balance 调优可后续单独 balance commit（§5.4 软线，不进百万与本批无关）。
