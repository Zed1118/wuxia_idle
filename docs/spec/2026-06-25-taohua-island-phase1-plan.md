# 桃花岛一期 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增「桃花岛」养成经营基地:4 建筑(铁匠厂/草药园/打造台/丹房)按真实时间产料并加工成战斗材料,回岛多条目收获,全程零看护、offline=online。

**Architecture:** 单一 `settle(elapsed)` 纯函数推进全部建筑(在线/离线共用此函数 → offline=online 构造性成立)。原料建筑滴落产 精铁/药草 到自身 storage(capped);加工建筑按连续速率从对应原料 storage 取料、产 磨剑石/经验丹 到自身 storage(capped)。回岛弹「桃花岛纪事」recap,一键收取入背包。状态嵌入 SaveData(per-slot 单例),数值全 numbers.yaml。

**Tech Stack:** Flutter Desktop · Riverpod 3 · Isar · YAML config。

> ⚠️ **待用户拍板的实现取舍**:spec §3「配方队列+自动续单」本计划落地为**连续速率自动加工**(源料够即按速率持续转化,无离散队列)。功能等价自动续单,自动化更彻底、offline=online 好证。若用户要离散排队队列 UI,Task 4 的算法与 Phase 2 recipe UI 需改。

---

## File Structure

| 文件 | 职责 | 新建/改 |
|---|---|---|
| `data/numbers.yaml` | `taohua_island:` 段(产速/cap/配方/升级成本/境界门槛) | 改(尾部追加) |
| `data/items.yaml` | 新材料 精铁/药草 条目 | 改 |
| `lib/features/taohua_island/domain/island_building_type.dart` | `BuildingType` enum + `RecipeDef` | 新建 |
| `lib/features/taohua_island/domain/taohua_island_config.dart` | `TaohuaIslandConfig` + `BuildingConfig` + `fromYaml` | 新建 |
| `lib/features/taohua_island/domain/island_building_state.dart` | `@embedded IslandBuildingState` | 新建 |
| `lib/features/taohua_island/application/island_production_service.dart` | 纯 `settle`/`compute` 累积逻辑 | 新建 |
| `lib/features/taohua_island/application/island_settle_service.dart` | Isar 读写 + 收取入背包(仿 offline_passive_service) | 新建 |
| `lib/features/taohua_island/application/island_providers.dart` | provider(无 codegen FutureProvider) | 新建 |
| `lib/features/taohua_island/presentation/taohua_island_screen.dart` | 主屏(4 建筑卡/升级/选配方) | 新建 |
| `lib/features/taohua_island/presentation/island_recap_card.dart` | 收获 recap 多条目卡 | 新建 |
| `lib/data/numbers_config.dart` | `NumbersConfig` 加 `taohuaIsland` 字段 | 改 |
| `lib/data/game_repository.dart` | load 不变 + `_enforceTaohuaIslandRedLines()` | 改 |
| `lib/core/domain/save_data.dart` | 加 `islandBuildings` / `islandLastSettledAt` | 改 |
| `lib/data/isar_setup.dart:139` | saveVer `0.29.0`→`0.30.0` | 改 |
| `lib/shared/strings.dart` | `UiStrings` 桃花岛文案 | 改 |
| `lib/features/main_menu/presentation/main_menu.dart` | 入口 WuxiaInkButton | 改 |
| `test/features/taohua_island/*` | 测试族 | 新建 |

---

# Phase 1 — 无 UI 机制层(全单测覆盖,headless 可验)

## Task 1: numbers.yaml `taohua_island:` 段 + items.yaml 材料

**Files:** Modify `data/numbers.yaml`(尾部), `data/items.yaml`

- [ ] **Step 1:** `data/items.yaml` 的 `items:` 列表追加两条新材料(type 用既有 `miscMaterial`,`ItemType.fromDefId` 默认即归 miscMaterial,无需改 enum):

```yaml
  - { defId: item_jingtie, type: miscMaterial, name: 精铁 }
  - { defId: item_yaocao,  type: miscMaterial, name: 药草 }
```

- [ ] **Step 2:** `data/numbers.yaml` 尾部追加(保守占位值,待 balance):

```yaml
taohua_island:
  cap_hours: 72                 # 沿用闭关 72h 防无限堆积(满则停产·非 FOMO)
  unlock_chapter_index: 1       # 主线第二章(index 1)cleared 解锁
  buildings:
    tie_jiang_chang:            # 铁匠厂(原料)
      kind: source
      output_item: item_jingtie
      base_rate_per_hour: 6.0
      cap_base: 200
      cap_per_level: 100
      max_level: 5
      upgrade_silver_base: 500
      upgrade_silver_per_level: 400
      upgrade_material_item: item_jingtie
      upgrade_material_base: 40
      realm_unlock_index: 0
    cao_yao_yuan:               # 草药园(原料)
      kind: source
      output_item: item_yaocao
      base_rate_per_hour: 6.0
      cap_base: 200
      cap_per_level: 100
      max_level: 5
      upgrade_silver_base: 500
      upgrade_silver_per_level: 400
      upgrade_material_item: item_yaocao
      upgrade_material_base: 40
      realm_unlock_index: 0
    da_zao_tai:                 # 打造台(加工)
      kind: processor
      input_item: item_jingtie
      cap_base: 80
      cap_per_level: 40
      max_level: 5
      upgrade_silver_base: 800
      upgrade_silver_per_level: 600
      upgrade_material_item: item_jingtie
      upgrade_material_base: 80
      recipes:
        - { recipe_id: forge_mojianshi, output_item: item_mojianshi,     input_per_output: 4.0,  rate_per_hour: 1.5, realm_unlock_index: 0 }
        - { recipe_id: forge_xinxue,    output_item: item_xinxuejiejing, input_per_output: 20.0, rate_per_hour: 0.4, realm_unlock_index: 3 }
    dan_fang:                   # 丹房(加工)
      kind: processor
      input_item: item_yaocao
      cap_base: 60
      cap_per_level: 30
      max_level: 5
      upgrade_silver_base: 800
      upgrade_silver_per_level: 600
      upgrade_material_item: item_yaocao
      upgrade_material_base: 80
      recipes:
        - { recipe_id: brew_ningshen, output_item: item_jingyandan_small, input_per_output: 6.0,  rate_per_hour: 1.0, realm_unlock_index: 0 }
        - { recipe_id: brew_peiyuan,  output_item: item_jingyandan_mid,   input_per_output: 18.0, rate_per_hour: 0.3, realm_unlock_index: 3 }
```

注:大还丹/秘籍不入配方(守 P4 仅掉落);高阶配方 `realm_unlock_index: 3`(一流)防低境界爆产。

- [ ] **Step 3:** 不引入 schema 即跑会失败(下一 task 解析)。先 `git add data/items.yaml data/numbers.yaml`,本 task 不单独 commit,合到 Task 2。

## Task 2: BuildingType / RecipeDef / TaohuaIslandConfig 解析

**Files:** Create `lib/features/taohua_island/domain/island_building_type.dart`, `lib/features/taohua_island/domain/taohua_island_config.dart`; Test `test/features/taohua_island/taohua_island_config_test.dart`

- [ ] **Step 1 (RED):** 写失败测,断言解析与 helper:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';
import 'package:wuxia_idle/features/taohua_island/domain/taohua_island_config.dart';
import 'package:wuxia_idle/features/taohua_island/domain/island_building_type.dart';

void main() {
  // 用 game_repository 实际加载的 numbers.yaml 子树,或内联等价 map:
  final y = (loadYaml(_yaml) as YamlMap).cast<String, dynamic>();
  final cfg = TaohuaIslandConfig.fromYaml(y);

  test('解析 cap/解锁 + 4 建筑', () {
    expect(cfg.capHours, 72);
    expect(cfg.unlockChapterIndex, 1);
    expect(cfg.buildings.length, 4);
    final tie = cfg.buildingOf(BuildingType.tieJiangChang);
    expect(tie.kind, BuildingKind.source);
    expect(tie.outputItem, 'item_jingtie');
    expect(tie.capFor(1), 200);          // cap_base + 0*per_level
    expect(tie.capFor(3), 400);          // 200 + 2*100
  });

  test('processor 配方 + 境界门槛', () {
    final dz = cfg.buildingOf(BuildingType.daZaoTai);
    expect(dz.kind, BuildingKind.processor);
    expect(dz.inputItem, 'item_jingtie');
    expect(dz.recipes.length, 2);
    final r = dz.recipeById('forge_mojianshi')!;
    expect(r.outputItem, 'item_mojianshi');
    expect(r.realmUnlockIndex, 0);
    expect(dz.recipeById('forge_xinxue')!.realmUnlockIndex, 3);
  });

  test('升级成本随等级', () {
    final tie = cfg.buildingOf(BuildingType.tieJiangChang);
    expect(tie.upgradeSilverFor(1), 500);   // base + 0
    expect(tie.upgradeSilverFor(2), 900);   // base + 1*per_level
  });
}

const _yaml = '''<把 Task1 的 taohua_island 子树粘进来作 fixture>''';
```

- [ ] **Step 2:** Run `flutter test test/features/taohua_island/taohua_island_config_test.dart` → FAIL(类不存在)。

- [ ] **Step 3 (GREEN):** `island_building_type.dart`:

```dart
enum BuildingType { tieJiangChang, caoYaoYuan, daZaoTai, danFang }
enum BuildingKind { source, processor }

class RecipeDef {
  final String recipeId;
  final String outputItem;
  final double inputPerOutput;
  final double ratePerHour;
  final int realmUnlockIndex;
  const RecipeDef({required this.recipeId, required this.outputItem,
    required this.inputPerOutput, required this.ratePerHour, required this.realmUnlockIndex});
  factory RecipeDef.fromYaml(Map<String, dynamic> y) => RecipeDef(
    recipeId: y['recipe_id'] as String,
    outputItem: y['output_item'] as String,
    inputPerOutput: (y['input_per_output'] as num).toDouble(),
    ratePerHour: (y['rate_per_hour'] as num).toDouble(),
    realmUnlockIndex: (y['realm_unlock_index'] as num).toInt(),
  );
}

const _yamlKeyByType = {
  'tie_jiang_chang': BuildingType.tieJiangChang,
  'cao_yao_yuan': BuildingType.caoYaoYuan,
  'da_zao_tai': BuildingType.daZaoTai,
  'dan_fang': BuildingType.danFang,
};
BuildingType buildingTypeFromYamlKey(String k) =>
    _yamlKeyByType[k] ?? (throw ArgumentError('未知建筑 key: $k'));
```

- [ ] **Step 4:** `taohua_island_config.dart`(`BuildingConfig` + `TaohuaIslandConfig.fromYaml`,镜像 `PassiveIdleConfig` 写法,见 `lib/data/numbers_config.dart:2751`):

```dart
class BuildingConfig {
  final BuildingType type;
  final BuildingKind kind;
  final String? outputItem;   // source
  final String? inputItem;    // processor
  final double baseRatePerHour;  // source only
  final int capBase, capPerLevel, maxLevel;
  final int upgradeSilverBase, upgradeSilverPerLevel;
  final String upgradeMaterialItem;
  final int upgradeMaterialBase;
  final int realmUnlockIndex;
  final List<RecipeDef> recipes;
  const BuildingConfig({...});  // 全 required

  int capFor(int level) => capBase + (level - 1) * capPerLevel;
  int upgradeSilverFor(int level) => upgradeSilverBase + (level - 1) * upgradeSilverPerLevel;
  int upgradeMaterialFor(int level) => upgradeMaterialBase + (level - 1) * upgradeMaterialBase;
  RecipeDef? recipeById(String id) => recipes.where((r) => r.recipeId == id).firstOrNull;

  factory BuildingConfig.fromYaml(BuildingType type, Map<String, dynamic> y) { ... }
}

class TaohuaIslandConfig {
  final int capHours;
  final int unlockChapterIndex;
  final Map<BuildingType, BuildingConfig> buildings;
  const TaohuaIslandConfig({required this.capHours, required this.unlockChapterIndex, required this.buildings});
  BuildingConfig buildingOf(BuildingType t) => buildings[t]!;
  factory TaohuaIslandConfig.fromYaml(Map<String, dynamic> y) {
    final raw = (y['buildings'] as Map).cast<String, dynamic>();
    final map = <BuildingType, BuildingConfig>{};
    raw.forEach((k, v) {
      final t = buildingTypeFromYamlKey(k);
      map[t] = BuildingConfig.fromYaml(t, (v as Map).cast<String, dynamic>());
    });
    return TaohuaIslandConfig(
      capHours: (y['cap_hours'] as num).toInt(),
      unlockChapterIndex: (y['unlock_chapter_index'] as num).toInt(),
      buildings: map,
    );
  }
}
```

- [ ] **Step 5:** Run test → PASS.
- [ ] **Step 6:** Commit: `git add data/ lib/features/taohua_island/domain/ test/features/taohua_island/taohua_island_config_test.dart && git commit -m "feat(桃花岛): numbers/items 配置 + TaohuaIslandConfig 解析"`

## Task 3: 接入 NumbersConfig + 启动期红线校验

**Files:** Modify `lib/data/numbers_config.dart`, `lib/data/game_repository.dart`; Test `test/features/taohua_island/taohua_island_redline_test.dart`

- [ ] **Step 1:** `numbers_config.dart`:加字段 `final TaohuaIslandConfig taohuaIsland;`(仿 `passiveIdle` 三处:字段 ~218 / 构造参数 ~278 / `fromYaml` 实例化 ~428):

```dart
taohuaIsland: TaohuaIslandConfig.fromYaml(
  (y['taohua_island'] as Map).cast<String, dynamic>()),
```

- [ ] **Step 2 (RED):** 红线测:产速/cap 不得为负、processor 必有 ≥1 配方、配方 output_item 必须是已知物品 defId(精铁/药草/磨剑石/心血结晶/经验丹)、input_per_output>0、realm_unlock_index ∈ [0,6]。断言合法 numbers.yaml 不抛、构造非法 map 抛 StateError。
- [ ] **Step 3:** `game_repository.dart` 校验块(~654,仿 `_enforceItemRedLines`)加 `_enforceTaohuaIslandRedLines()`:逐建筑/配方校验上述约束 + processor `input_item`/source `output_item` 配对自洽(打造台 input=精铁 必有 source 产 item_jingtie)。缺失/越界 `throw StateError`。
- [ ] **Step 4:** Run 全量相关测 → PASS;Run `flutter analyze` → 0。
- [ ] **Step 5:** Commit。

## Task 4: 核心累积逻辑 IslandProductionService(纯函数,TDD 重点)

**Files:** Create `lib/features/taohua_island/application/island_production_service.dart`; Test `test/features/taohua_island/island_production_service_test.dart`

模型:`settle(states, config, elapsedHours, founderRealmIndex)` 返回新 states(纯,不碰 Isar)。算法(连续量,double):
1. `t = elapsedHours.clamp(0, capHours)`。
2. **原料建筑**:`stored = min(cap(level), stored + baseRate*level*t)`。(level 作产速乘子)
3. **加工建筑**:取 activeRecipe(无则跳过);源建筑 = 产 `inputItem` 的 source。
   - `want = recipe.ratePerHour * level * t`(本窗口想产成品量)
   - `byMaterial = sourceStored / recipe.inputPerOutput`
   - `made = min(want, byMaterial)`,再 `made = min(made, cap(level) - stored)`(成品仓 cap)
   - `sourceStored -= made * recipe.inputPerOutput`;`stored += made`。
4. 全部 stored 内部保持 double,收取时才 floor。

- [ ] **Step 1 (RED):** 测:
  - 原料滴落 + cap 封顶(挂超 cap 时间 stored=cap)。
  - 加工受源料限(源料不足时 made 由 byMaterial 决定,源料归 0)。
  - 加工受成品 cap 限。
  - **offline=online 性质**:`settle(s, cfg, 4.0)` 与 `settle(settle(s,cfg,2.0),cfg,2.0)` 的成品总量差 < 1e-6(连续模型可加性)。
  - capHours 封顶:`settle(s,cfg,100.0)` == `settle(s,cfg,72.0)`。
  - 无 activeRecipe 的加工建筑不产、不耗源料。
- [ ] **Step 2:** Run → FAIL。
- [ ] **Step 3 (GREEN):** 实现上述算法(纯 Dart,输入输出都是不可变快照 / 或复制 state 列表)。
- [ ] **Step 4:** Run → PASS;analyze 0。
- [ ] **Step 5:** Commit。

## Task 5: 持久化 — IslandBuildingState 嵌入 SaveData + saveVer bump

**Files:** Create `lib/features/taohua_island/domain/island_building_state.dart`; Modify `lib/core/domain/save_data.dart`, `lib/data/isar_setup.dart`; Test `test/features/taohua_island/island_persistence_test.dart`

- [ ] **Step 1:** `island_building_state.dart`:

```dart
import 'package:isar/isar.dart';
import '../domain/island_building_type.dart';
part 'island_building_state.g.dart';   // 注:embedded 也走 isar codegen,集中 part 见项目惯例

@embedded
class IslandBuildingState {
  @Enumerated(EnumType.name)
  late BuildingType type;
  int level = 1;
  double stored = 0;        // 原料=原料量;加工=成品量(double 内部·floor 在收取)
  String? activeRecipeId;   // processor 选中的配方;null=未生产
}
```
(若项目 embedded 不单独 .g.dart 而随 SaveData 集中生成,按 `lib/core/domain/` 既有 embedded 如 `SkillUnlockEntry` 的 part 归属放置。)

- [ ] **Step 2:** `save_data.dart` 加字段(仿 `skillUnlockProgress` 嵌入列表 + `lastOnlineAt` 时间戳):

```dart
List<IslandBuildingState> islandBuildings = [];   // 空=未初始化(首开时建 4 个 level1)
DateTime? islandLastSettledAt;                      // 独立于 lastOnlineAt,避免与被动挂机争用
```

- [ ] **Step 3:** `isar_setup.dart:139` saveVer `'0.29.0'` → `'0.30.0'`,改注释(新字段默认空/null,无迁移分支纯 bump,仿 0.29 段)。
- [ ] **Step 4:** **全仓同步 saveVer 断言**(踩坑铁律):`grep -rn '0\.29\.0' test/`(禁 `| head` 截断),逐处改 `0.30.0`(上轮实测在 5 文件 ~9 处:isar_setup_test / save_migration_021_test / sect_isar_persistence_test / isar_setup_migration_lineage_test / passive_idle_migration_test)。执行时重新 grep 实测、勿信此清单。
- [ ] **Step 5:** `dart run build_runner build --delete-conflicting-outputs`(SaveData/embedded 改了 Isar schema,.g.dart gitignored 必重生)。
- [ ] **Step 6:** 写持久化测:存档写入 islandBuildings(含 activeRecipeId) → 读回逐字段相等;旧档(无字段)读出空列表 + null 时间戳不崩。
- [ ] **Step 7:** Run 全量 test(saveVer 断言全绿)→ PASS;analyze 0。
- [ ] **Step 8:** Commit。

## Task 6: IslandSettleService — Isar 读写 + 首开初始化 + 收取入背包

**Files:** Create `lib/features/taohua_island/application/island_settle_service.dart`; Test `test/features/taohua_island/island_settle_service_test.dart`

职责(仿 `lib/features/seclusion/application/offline_passive_service.dart:46`):
- `ensureInitialized(save)`:islandBuildings 空 → 建 4 个 level1(activeRecipeId 给 processor 默认首配方),islandLastSettledAt=now。
- `settle(save, now)`:`elapsed=(now - islandLastSettledAt)/3600`,调 `IslandProductionService.settle`,写回 islandBuildings,`islandLastSettledAt=now`。**纯累积进 storage,不入背包**(收取才入背包)。
- `harvest(save, now)`:先 `settle`,再把各建筑 `stored.floor()` 的成品/原料按 outputItem(source)或 recipe.outputItem(processor)写入 `InventoryItem`(getByDefId → 累加 quantity 或新建,仿 offline_passive_service:61-76),`stored -= floored`(保留小数尾)。返回 `IslandHarvest`(`Map<String defId, int qty>`)供 recap 多条目展示。

- [ ] **Step 1 (RED):** 测(`test()` 非 `testWidgets`,避 Isar widget 死锁):首开初始化 4 建筑;settle 后 storage 增长;harvest 后对应 InventoryItem quantity 增加且 storage 清到小数尾;offline 长时段 harvest 多条目齐全。
- [ ] **Step 2-4:** 实现 → Run → PASS;analyze 0。
- [ ] **Step 5:** Commit。

## Task 7: 建筑升级 + 选配方(纯逻辑,境界/银两/材料校验)

**Files:** Create `lib/features/taohua_island/application/island_action_service.dart`(或并入 settle service); Test 同族

- [ ] **Step 1 (RED):** 测:
  - `canUpgrade`:level<maxLevel、founderRealmIndex≥下一级 realm 门槛、银两够、自产材料够。
  - `upgrade`:扣银两(InventoryItem item_silver)+ 扣自产材料,level+1。境界不足/钱不足 → 拒(返回失败原因枚举)。
  - `selectRecipe`:仅 processor、且 `recipe.realmUnlockIndex<=founderRealmIndex` 可选;写 activeRecipeId。
- [ ] **Step 2-4:** 实现(扣银两走 InventoryItem `item_silver`,见 ItemType.silver);Run → PASS;analyze 0。
- [ ] **Step 5:** Commit。

## Task 8: Phase 1 收口验证(headless 全绿 + 红线自查)

- [ ] **Step 1:** Run `flutter analyze` → 期望 `No issues found!`。
- [ ] **Step 2:** Run `flutter test`(全量)→ 全绿,记录新增测数。
- [ ] **Step 3:** 红线自查逐条(对照 spec §2):offline=online(Task4 性质测)/无体力·每日·登录/cap 非 FOMO/复用 P4 经济(精铁药草=miscMaterial、银两=item_silver)/数值全 numbers.yaml。
- [ ] **Step 4:** Commit(若有收尾改动)。

---

# Phase 2 — UI 与接线(在 Phase 1 机制之上)

> Phase 2 各屏照既有 `lib/features/seclusion/presentation/` 与 `WuxiaInkButton`/`WuxiaPaperPanel` 既有组件搭建;中文全进 `UiStrings`。

## Task 9: UiStrings 桃花岛文案

**Files:** Modify `lib/shared/strings.dart`(仿 `mainMenuSeclusion*` ~889)

- [ ] 加 `mainMenuTaohuaIsland`/`...Hint`/`...LockedHint`/建筑名/动作标签/recap 标题等(全 `static const`,动态用 `static String 名(参数)`)。Commit。

## Task 10: island_providers + 收取/settle gate

**Files:** Create `lib/features/taohua_island/application/island_providers.dart`

- [ ] `taohuaIslandStateProvider`(FutureProvider.autoDispose,仿 `seclusion_gate.dart:19`,无 codegen):读当前 slot SaveData,`ensureInitialized` + `settle(now)`,返回快照供 UI watch。Commit。

## Task 11: 主屏 taohua_island_screen

**Files:** Create `lib/features/taohua_island/presentation/taohua_island_screen.dart`

- [ ] 4 建筑卡(名/等级/storage 进度条 vs cap/产速/processor 显当前配方);按钮:升级(显成本+境界锁灰化,守 §5.3)、选配方(processor,高阶配方未达境界灰化)、收取(汇总)。Scaffold 必带 AppBar(踩坑:无 AppBar 卡死)。ListView 包 IntrinsicHeight(WuxiaPaperPanel 滚动列踩坑)。Commit。

## Task 12: 收获 recap 多条目卡 island_recap_card

**Files:** Create `lib/features/taohua_island/presentation/island_recap_card.dart`

- [ ] 收取后弹卡:逐条目滚动列(精铁×N/药草×N/磨剑石×N/凝神丹×N…)+ 数字跳动,强化「一把收」爽感(仿 `offline_recap_card.dart`)。空收获时友好提示不弹空卡。Image.asset 必带 errorBuilder(踩坑)。Commit。

## Task 13: main_menu 入口 + 解锁门控

**Files:** Modify `lib/features/main_menu/presentation/main_menu.dart`(~234 coreItems / WuxiaInkButton 仿 pvp ~296)

- [ ] 加桃花岛 `WuxiaInkButton`:`unlock_chapter_index` 未达 → locked 灰化 + lockedHint(§5.7 不弹教程);`_push(context, const TaohuaIslandScreen())`。解锁判定复用既有章节 cleared 查询(同 pvp/seclusion lock 模式)。Commit。

## Task 14: app-resume 结算接线 + Phase 2 收口

**Files:** Modify app lifecycle/resume hook(查 `offline_recap_gate` 如何在 resume 触发,同址挂桃花岛 settle 或仅进屏时 settle)

- [ ] **Step 1:** 决策:桃花岛只在「进屏时 settle」(最简,推荐)还是 app-resume 全局 settle。MVP 取进屏 settle(provider 已含),app-resume 不额外挂(避免与被动挂机 recap 抢弹窗)。
- [ ] **Step 2:** 真机/widget 冒烟:进桃花岛屏不崩、升级/选配方/收取链路通。
- [ ] **Step 3:** Run `flutter analyze`(0)+ `flutter test`(全绿)。
- [ ] **Step 4:** 视觉验收派 Codex(本地)目检水墨基调/布局,PASS 后 Commit。
- [ ] **Step 5:** 更新 PROGRESS.md 顶段(桃花岛一期落地)+ 写 closeout。

---

## Self-Review(plan vs spec §逐条)

- spec §3 生产模型 → Task 4(连续速率·已标红待用户拍)。✅
- spec §4 四建筑两链 → Task 1 配置 + Task 4 逻辑 + Task 11 UI。✅
- spec §5 升级反哺+境界锁 → Task 7。✅
- spec §2 红线 → Task 3 校验 + Task 4 offline=online 性质测 + Task 8 自查。✅
- spec §6 数据整合(复用经济/saveVer/模块) → Task 1/5/6。✅
- spec §7 解锁 → Task 13(章节门控,落定 unlock_chapter_index=1)。✅
- spec §8 边界(不做木工/矿洞/迁移/疗伤药) → 未排任务,符合。✅
- 踩坑(saveVer 全仓同步 / build_runner / widget 测死锁 / AppBar / ListView viewport / Image errorBuilder) → 各 task 内联提醒。✅

**类型一致性**:`BuildingType`/`BuildingKind`/`RecipeDef`/`BuildingConfig`/`TaohuaIslandConfig`/`IslandBuildingState`/`IslandHarvest` 跨 task 命名统一。`stored` 字段贯穿 Task4/5/6。

**未决(执行前确认)**:Task 4 连续速率 vs 离散队列(已标红)。
