# 材料经济 balance 校准 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development（推荐）或 executing-plans 逐任务实现。步骤用 `- [ ]` 跟踪。
> 设计源:`docs/spec/2026-06-21-p4-material-economy-balance-design.md`。

**Goal:** 把材料经济占位数值校准到「适度规划·2–3 天养成一条线」节奏,经验丹随境界缩放,经验丹动态标价防套利,大还丹掉落扩展到后期。

**Architecture:** 机制改动(layerFraction schema / 缩放增益 / 动态标价 / 掉落挂点)走 TDD;数值(silver/标价/dropChance)进 yaml + 经济算式单测验证锚;balance_simulator 仅跑战斗红线确认经济改动不破伤害。

**Tech Stack:** Flutter / Isar / YAML / flutter_test。`character.experienceToNextLayer` = 当前层所需经验(缩放基准)。

---

## 文件结构

- `lib/data/defs/item_def.dart` — 加 layerFraction 废 experience
- `lib/features/inventory/application/item_use_service.dart` — 经验丹增益按境界缩放
- `lib/data/defs/shop_item_def.dart` + `lib/features/shop/application/shop_service.dart` — 经验丹动态标价
- `data/items.yaml` / `data/shop.yaml` / `data/numbers.yaml` / `data/stages.yaml` / `data/towers.yaml` — 数值
- `test/features/economy/economy_balance_test.dart`(新) — 经济节奏算式验证
- 既有测试文件:item_def / item_use_service / shop_service / 掉落接线

---

## Task 1: ItemDef layerFraction schema(废 experience)

**Files:**
- Modify: `lib/data/defs/item_def.dart`
- Modify: `data/items.yaml:12-14`
- Test: `test/data/defs/item_def_test.dart`(若无则新建)

- [ ] **Step 1: 改 items.yaml 经验丹 experience→layer_fraction**

```yaml
  - { defId: item_jingyandan_small, type: jingYanDan, name: 凝神丹, layer_fraction: 0.2 }
  - { defId: item_jingyandan_mid,   type: jingYanDan, name: 培元丹, layer_fraction: 0.5 }
  - { defId: item_jingyandan_large, type: jingYanDan, name: 大还丹, layer_fraction: 1.0 }
```

- [ ] **Step 2: 写失败测**(item_def_test.dart)

```dart
test('jingYanDan 解析 layer_fraction', () {
  final d = ItemDef.fromYaml({'defId': 'x', 'type': 'jingYanDan', 'name': '丹', 'layer_fraction': 0.5});
  expect(d.layerFraction, 0.5);
});
test('jingYanDan 缺 layer_fraction 抛', () {
  expect(() => ItemDef.fromYaml({'defId': 'x', 'type': 'jingYanDan', 'name': '丹'}), throwsStateError);
});
```

- [ ] **Step 3: 跑测验证失败**

Run: `flutter test test/data/defs/item_def_test.dart`
Expected: FAIL(layerFraction getter 不存在)

- [ ] **Step 4: 改 ItemDef**

`experience` 字段 → `final double? layerFraction;`。构造去 experience 加 layerFraction。fromYaml:
```dart
final layerFraction = (y['layer_fraction'] as num?)?.toDouble();
if (type == ItemType.jingYanDan && layerFraction == null) {
  throw StateError('ItemDef $defId: jingYanDan 必须配 layer_fraction');
}
// techniqueScroll 校验不变
return ItemDef(defId: defId, type: type, name: name, layerFraction: layerFraction, unlockSkillId: unlockSkillId);
```

- [ ] **Step 5: 跑测验证通过**

Run: `flutter test test/data/defs/item_def_test.dart`
Expected: PASS

- [ ] **Step 6: 全项目 analyze(抓 experience 残引用)**

Run: `flutter analyze`
Expected: 暴露 item_use_service.dart 用 `def.experience` 报错(Task 2 修)。若只此一处,继续;其余先修编译。

- [ ] **Step 7: Commit**

```bash
git add lib/data/defs/item_def.dart data/items.yaml test/data/defs/item_def_test.dart
git commit -m "材料经济balance T1:ItemDef layer_fraction 废 experience"
```

---

## Task 2: 经验丹增益按境界缩放

**Files:**
- Modify: `lib/features/inventory/application/item_use_service.dart:44`
- Test: `test/features/inventory/item_use_service_test.dart`

- [ ] **Step 1: 写失败测**(同档丹学徒 vs 二流增益不同)

```dart
test('经验丹增益随境界缩放:同档丹高境界给更多经验', () async {
  // 学徒 founder experienceToNextLayer 小,二流大;同 layer_fraction=0.5 培元丹
  // 增益 = founder.experienceToNextLayer * 0.5
  // 在 setUp 造学徒 founder(experienceToNextLayer=80) → 用培元丹 → experience += 40
  // 断言 applied delta == (experienceToNextLayer * layerFraction).round()
});
```
(按现有 item_use_service_test setUp 体例造 founder + seed 培元丹,断言 result.layersGained / founder.experience 变化匹配 `(etl*0.5).round()`)

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/features/inventory/item_use_service_test.dart`
Expected: FAIL(仍按旧 def.experience,或编译错)

- [ ] **Step 3: 改 item_use_service.dart jingYanDan 分支**

```dart
final gain = (founder.experienceToNextLayer * def.layerFraction!).round();
final result = CharacterAdvancementService.applyExperience(
  founder, gain,
  realmLookup: realmLookup,
  isLayerLocked: isLayerLocked,
);
```

- [ ] **Step 4: 跑测验证通过 + 全项目 analyze**

Run: `flutter test test/features/inventory/item_use_service_test.dart && flutter analyze`
Expected: PASS / analyze 0(experience 残引用清完)

- [ ] **Step 5: Commit**

```bash
git add lib/features/inventory/application/item_use_service.dart test/features/inventory/item_use_service_test.dart
git commit -m "材料经济balance T2:经验丹增益=单层经验×layer_fraction 随境界缩放"
```

---

## Task 3: 经验丹动态标价(防套利)

**Files:**
- Modify: `lib/data/defs/shop_item_def.dart` / `data/shop.yaml` / `lib/features/shop/application/shop_service.dart`
- Test: `test/features/shop/shop_service_test.dart`

- [ ] **Step 1: shop.yaml 经验丹改 price_layer_fraction**

```yaml
  - { id: shop_jingyandan_small, itemDefId: item_jingyandan_small, itemType: jingYanDan, price_layer_fraction: 1.0, category: pill }
  - { id: shop_jingyandan_mid,   itemDefId: item_jingyandan_mid,   itemType: jingYanDan, price_layer_fraction: 2.5, category: pill }
```
(磨剑石/心血结晶保留 `price: 30/120` 固定。price_layer_fraction 初值占位:标价=当前单层经验×pf;学徒单层~50 → 凝神≈50/培元≈125,贴现状量级,balance pass 由 T6 算式测校准)

- [ ] **Step 2: 写失败测**(经验丹标价随境界变,材料固定)

```dart
test('经验丹标价随境界动态:高境界标价更高', () {
  // effectivePriceFor(def, founderEtl) == (founderEtl * priceLayerFraction).round()
  // 材料 def 走固定 price
});
```

- [ ] **Step 3: 跑测验证失败**

Run: `flutter test test/features/shop/shop_service_test.dart`
Expected: FAIL

- [ ] **Step 4: 改 ShopItemDef + ShopService**

ShopItemDef:`price` 改 `final int? price;` + 加 `final double? priceLayerFraction;`,fromYaml 二选一解析 + 校验(jingYanDan 须 price_layer_fraction,材料须 price)。
ShopService 加纯函数 `int effectivePrice(ShopItemDef def, int founderEtl)`:
```dart
if (def.priceLayerFraction != null) return (founderEtl * def.priceLayerFraction!).round();
return def.price!;
```
purchase 取 founder.experienceToNextLayer 算 effectivePrice 替所有 `def.price` 用点(balance 检查 + 扣银两)。

- [ ] **Step 5: 跑测 + analyze**

Run: `flutter test test/features/shop/shop_service_test.dart && flutter analyze`
Expected: PASS / 0

- [ ] **Step 6: Commit**

```bash
git add lib/data/defs/shop_item_def.dart data/shop.yaml lib/features/shop/application/shop_service.dart test/features/shop/shop_service_test.dart
git commit -m "材料经济balance T3:经验丹动态标价(单层经验×price_layer_fraction)防套利"
```

---

## Task 4: 大还丹掉落扩展到后期

**Files:**
- Modify: `data/stages.yaml`(Ch4-6 章末 Boss) / `data/towers.yaml`(10/20/30 层)
- Test: `test/data/drop_table_test.dart`(或既有掉落接线测)

- [ ] **Step 1: 查实际 Ch4-6 章末 Boss 关 id + 爬塔 10/20/30 层 id**

Run: `grep -nE "id: stage_0[456]_|floorIndex: (10|20|30)" data/stages.yaml data/towers.yaml`
记录实际 id(勿凭记忆)。

- [ ] **Step 2: 写失败测**(后期关含大还丹掉落)

```dart
test('Ch4-6 章末 Boss + 爬塔大Boss 含大还丹掉落', () {
  // 加载 stages/towers,断言对应关/层 dropTable 含 item_jingyandan_large
});
```

- [ ] **Step 3: 跑测验证失败**

Run: `flutter test test/data/drop_table_test.dart`
Expected: FAIL

- [ ] **Step 4: yaml 加掉落条目**

各 Ch4-6 章末 Boss dropTable 加 `{ inventoryItemDefId: item_jingyandan_large, dropChance: 0.25, quantity: [1,1] }`;爬塔 10/20/30 层加 `dropChance: 0.20`。同步 Ch1-3 既有 0.2→0.25(校准)。

- [ ] **Step 5: 跑测 + analyze**

Run: `flutter test test/data/drop_table_test.dart && flutter analyze`
Expected: PASS / 0

- [ ] **Step 6: Commit**

```bash
git add data/stages.yaml data/towers.yaml test/data/drop_table_test.dart
git commit -m "材料经济balance T4:大还丹掉落扩展 Ch4-6+爬塔大Boss + dropChance 校准"
```

---

## Task 5: 秘籍 dropChance 校准 + 首通门控核实

**Files:**
- Modify: `data/stages.yaml` / `data/towers.yaml`(秘籍 dropChance)
- 核实: 主线秘籍掉落 hook 是否首通门控

- [ ] **Step 1: 核实主线秘籍掉落机制**

Run: `grep -rn "inventoryItemDefId: item_scroll_\|firstClear\|isFirstClear" data/stages.yaml lib/features/equipment/application/drop_service.dart`
判断主线 item_scroll 掉落现是概率(0.1)还是首通门控。

- [ ] **Step 2: 写失败测**(秘籍 dropChance 校准值)

```dart
test('主线秘籍倾向首通必得/爬塔残本概率 0.15', () {
  // 断言主线 3 本 dropChance(首通必得=1.0 或既有门控) + 爬塔 6 本 dropChance==0.15
});
```

- [ ] **Step 3: 跑测验证失败**

Run: `flutter test test/data/drop_table_test.dart`
Expected: FAIL

- [ ] **Step 4: 校准 dropChance**

主线 3 本:若已首通门控则保留,否则 0.1→1.0(首通必得);爬塔 6 本 0.1→0.15。

- [ ] **Step 5: 跑测 + analyze**

Run: `flutter test test/data/drop_table_test.dart && flutter analyze`
Expected: PASS / 0

- [ ] **Step 6: Commit**

```bash
git add data/stages.yaml data/towers.yaml test/data/drop_table_test.dart
git commit -m "材料经济balance T5:秘籍 dropChance 校准(主线首通/爬塔残本)"
```

---

## Task 6: 银两收入校准 + 经济节奏算式测

**Files:**
- Modify: `data/numbers.yaml`(silver_per_hour base) / `data/stages.yaml` `data/towers.yaml`(item_silver 微调)
- Test: `test/features/economy/economy_balance_test.dart`(新)

- [ ] **Step 1: 写经济节奏算式测(确定性,非战斗模拟)**

> helper(`silverPerHour`/`realmScale`/`estStageDropSilver`)= 测内薄函数,从 `GameRepository.instance.numbers`(retreat.silver_per_hour / realm_scale_per_tier)+ stages dropTable 读,非新生产代码。

```dart
// 纯算式:某境界日收入 = 闭关 base×scale×8h + 关卡掉落估值;消费锚 = 强化到+15(1050银两)
test('二流日收入支撑 2-3 天养成一条线', () {
  final perHour = silverPerHour('xuanYaPuBu') * realmScale(erLiu); // base24×1.69
  final daily = perHour * 8 + estStageDropSilver(erLiu);
  final daysToEnhance = 1050 / daily;
  expect(daysToEnhance, inInclusiveRange(2.0, 3.0));
});
test('无套利:经验丹动态标价下,买1层经验银两 >= 挂机赚够该银两的隐含成本', () {
  // effectivePrice(培元) / 增益层数 vs 挂机时薪/挂机升层速度,断言买丹不优于挂机
});
```

- [ ] **Step 2: 跑测验证失败**

Run: `flutter test test/features/economy/economy_balance_test.dart`
Expected: FAIL(现状 base 不贴锚)

- [ ] **Step 3: 调 numbers.yaml silver_per_hour base**

按 design §3 表:山林8/古剑冢14/藏经阁14/悬崖24/断崖60。关卡/塔 item_silver 保留递增曲线,微调系数让算式贴锚。

- [ ] **Step 4: 迭代到算式测通过**

Run: `flutter test test/features/economy/economy_balance_test.dart`
反复微调 base/掉落系数/price_layer_fraction 直到 PASS(2-3 天锚 + 无套利)。

- [ ] **Step 5: Commit**

```bash
git add data/numbers.yaml data/stages.yaml data/towers.yaml test/features/economy/economy_balance_test.dart
git commit -m "材料经济balance T6:银两收入校准到2-3天锚+无套利算式测"
```

---

## Task 7: 战斗红线确认 + 全量回归

**Files:**
- 跑: balance_simulator(确认经济改动不破伤害红线) + 全量

- [ ] **Step 1: 跑 balance_simulator 战斗红线**

Run: `flutter test test/tools/balance_simulator_test.dart`
Expected: PASS(经济改动不碰战斗公式,伤害红线 <100万 应天然保持)

- [ ] **Step 2: 全项目 analyze**

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 3: 全量测试**

Run: `flutter test`
Expected: All tests passed(基线 2753 + 本批新增,零回归)

- [ ] **Step 4: 红线人工核对**

确认:§5.4 银两/经验无膨胀(算式测) · §5.5 无套利(T6 测) · §5.6 全走 yaml · §5.7 秘籍仍仅掉落(未上货架)。

- [ ] **Step 5: Commit(若有)**

```bash
git commit --allow-empty -m "材料经济balance T7:战斗红线+全量回归确认"
```

---

## 验证法说明(spec §8 修正)

balance_simulator **只模拟战斗 winRate/伤害,不建模挂机银两收入** → 经济节奏(收入vs消费/无套利)改用 `economy_balance_test` 确定性算式验证(T6);simulator 仅跑战斗红线确认经济改动不影响伤害(T7)。
