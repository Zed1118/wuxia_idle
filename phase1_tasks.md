# phase1_tasks.md · 第一阶段（第 1-3 周）战斗系统任务清单

> **文档地位**：本文档是给 Mac 端 Claude Code + Opus 4.7 的执行清单，每个任务自带验收标准，逐个交付即可。
>
> **遵循文档**：GDD.md v1.1、data_schema.md v1.1、numbers.yaml v0.1.0
>
> **阶段目标**：3v3 自动战斗能跑通,能体验到流派克制、暴击、装备影响伤害、境界差距修正
>
> **总工作量预估**：约 15-16 个工作日（3 周）

---

## 0. 总体说明（必读）

### 0.1 关键约束（不要踩雷）

1. **数值公式系数以 numbers.yaml 为准，GDD 是口误**
   - GDD §5.3 写「装备攻击 × 8」、§5.6 写「内力 × 5」是**口误**，按字面值实现会突破 §5.2 红线（伤害破万、武圣血量超 80000）
   - numbers.yaml 已平衡为 `equipment_attack_factor: 1.0` / `internal_force_factor: 0.7`
   - 代码必须从 GameRepository 读 yaml，**不得硬编码任何数值系数**
   - 每次改公式后跑 numbers.yaml §11 的 5 个 validation_examples 校验

2. **多存档架构 Phase 1 暂不实现**
   - data_schema.md §7 要求多 db 文件多存档
   - Phase 1 简化为单 slot（写死 `slotId = 1`），但 `IsarSetup.init({int slotId = 1})` API 形态保留，Phase 5 再补 switchSlot/listAllSlots/deleteSlot
   - 不要在 Collection 上加 `slotId` 字段（污染 schema）

3. **代码中不得硬编码任何中文文案与数值**
   - 文案归 `data/narratives/`、`data/lore/`、`data/events/`（DeepSeek 维护，Phase 1 还没写，留空目录即可）
   - 数值归 `data/*.yaml`（Opus 维护）
   - Phase 1 测试用敌人/装备/心法的"占位名"可在 yaml 内填中文 name 字段，但不进 dart 代码
   - description 字段填 `"TODO_NARRATIVE"`，等 Windows 端 DeepSeek 接手

4. **状态管理选定 Riverpod，不要再 BLoC**
   - 用 `flutter_riverpod` + `riverpod_annotation`（生成式 provider）
   - 战斗内频繁更新的状态用细粒度 provider，不要整个 BattleState 重建

### 0.2 任务依赖图

```
                    T01 项目初始化
                          │
                          ▼
                    T02 枚举定义
                          │
                ┌─────────┴──────────┐
                ▼                    ▼
          T03 嵌入对象           T06 Def 配置类
                │                    │
                ▼                    ▼
        T04 Isar 实体           T07 YAML 加载器
        Char/Eq/Tech              + fixture 数据
                │                    │
                ▼                    │
          T05 SaveData ◄─────────────┘
          + IsarSetup
                │
          ─── Week 1 完成线 ───
                │
                ▼
          T08 境界派生工具
                │
                ▼
          T09 角色派生属性 (HP/速度/暴击/闪避)
                │
                ▼
          T10 伤害计算器（核心）
                │
                ▼
          T11 战斗状态机数据结构
                │
                ▼
          T12 战斗引擎 + AI 行动选择
                │
          ─── Week 2 完成线 ───
                │
                ▼
          T13 战斗事件日志
                │
                ▼
          T14 战斗 UI 布局（3v3 半横版）
                │
                ▼
          T15 攻击动画 + 伤害飘字
                │
                ▼
          T16 手动大招触发 + Riverpod 串接
                │
                ▼
          T17 测试场景（4 套预设战斗）
                │
                ▼
          T18 Phase 1 验收 + 缓冲日
```

### 0.3 目录结构（按 data_schema.md §7.3 + Phase 1 战斗模块）

```
lib/
├── main.dart
├── app.dart
├── data/
│   ├── isar_setup.dart
│   ├── models/                  # T03/T04/T05 产出
│   │   ├── enums.dart
│   │   ├── attributes.dart
│   │   ├── forging_slot.dart
│   │   ├── lore.dart
│   │   ├── skill_usage_entry.dart
│   │   ├── reward_entry.dart
│   │   ├── save_data.dart
│   │   ├── character.dart
│   │   ├── equipment.dart
│   │   ├── technique.dart
│   │   ├── inventory_item.dart
│   │   └── game_event.dart
│   ├── defs/                    # T06 产出
│   │   ├── equipment_def.dart
│   │   ├── technique_def.dart
│   │   ├── skill_def.dart
│   │   ├── stage_def.dart
│   │   ├── enemy_def.dart
│   │   └── realm_def.dart
│   └── repositories/
│       └── game_repository.dart  # T07 产出
├── combat/                       # T08-T13 产出
│   ├── derived_stats.dart
│   ├── damage_calculator.dart
│   ├── battle_state.dart
│   ├── battle_engine.dart
│   ├── battle_ai.dart
│   └── battle_log.dart
├── ui/
│   ├── battle/                   # T14-T16 产出
│   │   ├── battle_screen.dart
│   │   ├── character_avatar.dart
│   │   ├── hp_bar.dart
│   │   └── damage_popup.dart
│   └── debug/                    # T17 产出
│       └── battle_test_menu.dart
└── providers/                    # T16 产出
    └── battle_providers.dart

assets/data/                      # T07 产出
├── numbers.yaml                  # 已有（用户提供）
├── equipment.yaml                # T07 fixture
├── techniques.yaml               # T07 fixture
├── skills.yaml                   # T07 fixture
└── stages.yaml                   # T07 fixture（含测试关卡）
```

---

## Week 1：基础架构（T01–T07）

### T01 · 项目初始化与依赖配置

- **预估时长**：0.5 天
- **依赖任务**：无
- **涉及文件**：`pubspec.yaml`、`analysis_options.yaml`、`.gitignore`、`lib/main.dart`、整个 Flutter 项目骨架

**任务内容**：
1. `flutter create --platforms=windows,macos . --org com.pen.wuxia`（Mac 开发把 macos 加上方便本地测试）
2. 配置 `pubspec.yaml` 依赖：
   ```yaml
   dependencies:
     flutter_riverpod: ^2.5.0
     riverpod_annotation: ^2.3.0
     isar: ^3.1.0
     isar_flutter_libs: ^3.1.0
     path_provider: ^2.1.0
     yaml: ^3.1.2
     intl: ^0.19.0
   dev_dependencies:
     build_runner: ^2.4.0
     isar_generator: ^3.1.0
     riverpod_generator: ^2.3.0
     custom_lint: ^0.6.0
     riverpod_lint: ^2.3.0
   flutter:
     assets:
       - assets/data/
   ```
3. 把用户提供的 `numbers.yaml` 复制到 `assets/data/numbers.yaml`
4. `analysis_options.yaml`：开启 `prefer_const_constructors`、`prefer_final_locals` 等 lint
5. `.gitignore` 加入 `*.g.dart`（生成代码不入库，依赖 build_runner 重新生成）
6. `flutter config --enable-windows-desktop --enable-macos-desktop`
7. `main.dart` 写最简启动：`runApp(MaterialApp(home: Scaffold(body: Text('启动成功'))))`

**验收标准**：
- [ ] `flutter run -d macos` 启动并显示「启动成功」
- [ ] `flutter analyze` 0 warning 0 error
- [ ] `dart run build_runner build` 命令能执行（即使没文件可生成）
- [ ] git 已 init 并完成 first commit

**可能的坑**：
- isar 3.x 与 Flutter 3.x SDK 兼容；**不要混用 isar 4.x**（API 不同）
- `*.g.dart` 是否入库各团队约定不同，本项目选择**不入库**，CI 必须先跑 build_runner
- macOS 上 Flutter Desktop 需要 Xcode 命令行工具齐全（Pen 之前配过应无障碍）
- `dart run build_runner build` 偶尔卡在 `[INFO] Generating build script...`，加 `--delete-conflicting-outputs` 强制覆盖
- pubspec.yaml 中 `assets: - assets/data/` 末尾的 `/` 是必须的（声明目录而非单个文件）

---

### T02 · 全部枚举定义

- **预估时长**：0.5 天
- **依赖任务**：T01
- **涉及文件**：`lib/data/models/enums.dart`

**任务内容**：
按 data_schema.md §2 把所有枚举原样搬到一个文件里（**不要拆分到各 model 文件**，多处引用集中维护更清晰）。共 18 个枚举：

`RealmTier`、`RealmLayer`、`CultivationLayer`、`EquipmentTier`、`TechniqueTier`、`EquipmentSlot`、`ForgingSlotType`、`TechniqueSchool`、`TechniqueRole`、`SkillType`、`ResonanceStage`、`RarityTier`、`LineageRole`、`StageType`、`RetreatMapType`、`TimeOfDayPeriod`、`ItemType`、`GameEventType`

**验收标准**：
- [ ] 所有枚举值的命名与 data_schema.md §2 表格**逐字一致**（用 grep 自查）
- [ ] 文件顶部注释指明每个枚举对应 GDD 哪一节
- [ ] `flutter analyze` 通过

**可能的坑**：
- **拼音命名最容易写错**：`xueTu`（学徒）不是 `xueDi`，`jueShi`（绝世）不是 `juShi`，`huaJing`（化境）不是 `huJing`，`jueDing`（绝顶）不是 `jueDuan`。逐字对照 data_schema.md §2
- `RealmLayer.qiMeng`（启蒙，境界第一层）≠ `CultivationLayer.chuKui`（初窥，心法第一层）。schema v1.1 已专门避免重名
- 后续 `@Enumerated(EnumType.name)` 把枚举名字符串化存盘。**现在写错的拼写，下一阶段再改成本极高（旧存档全失效）**
- 枚举值开头小写（camelCase）是项目约定，**不要写成 `XueTu` 或 `XUE_TU`**

---

### T03 · 嵌入对象（@Embedded）

- **预估时长**：0.5 天
- **依赖任务**：T02
- **涉及文件**：`attributes.dart`、`forging_slot.dart`、`lore.dart`、`skill_usage_entry.dart`、`reward_entry.dart`

**任务内容**：
按 data_schema.md §3 实现 5 个嵌入对象：
1. `Attributes`（根骨/悟性/身法/机缘 + total getter）
2. `ForgingSlot`（slotIndex/type/unlocked/bonusValue/specialSkillId）
3. `Lore`（text/isPreset/addedAt/triggerEventDesc）
4. `SkillUsageEntry`（skillId/count）
5. `RewardEntry`（rewardKey/quantity）

每个类：
- 顶部 `@embedded` 注解
- 所有字段给默认值（**不要 `late`**，嵌入对象不允许 late 字段）
- 枚举字段加 `@Enumerated(EnumType.name)`
- 按 data_schema.md §3.6 给 `List<SkillUsageEntry>` 和 `List<RewardEntry>` 写 extension（独立 extension 块）：
  - `MapLikeOnSkillUsage.countOf(skillId)` / `.increment(skillId, [delta])`
  - `MapLikeOnRewards.quantityOf(rewardKey)`

**验收标准**：
- [ ] 5 个嵌入类都有 `@embedded` 注解
- [ ] 没有任何 `late` 字段（嵌入对象禁用 late）
- [ ] extension 方法的单元测试 ≥ 4 个用例（增量、查询、不存在的 key、覆盖现有 key）

**可能的坑**：
- 嵌入对象内**不能再嵌入嵌入对象**（Isar 限制：只能嵌一层）
- `DateTime` 字段在嵌入对象里**必须有默认值**，写 `DateTime addedAt = DateTime(2000);` 然后由调用方覆盖。`DateTime.now()` 作默认值在 isar_generator 偶尔报错
- extension 的 `firstWhere` + `orElse` 创建新对象**不会回写到原 List**。`increment` 必须用 `indexWhere` + 直接修改或 `add`，照搬 schema §3.6 标准实现

---

### T04 · 三个核心 Isar 实体（Character / Equipment / Technique）

- **预估时长**：1 天
- **依赖任务**：T03
- **涉及文件**：`character.dart`、`equipment.dart`、`technique.dart`、自动生成的 `*.g.dart`

**任务内容**：
按 data_schema.md §4.2/§4.3/§4.4 实现三个 Collection：

1. **Character**（§4.2）：主键 `Id id = Isar.autoIncrement;`、`@Index() bool isActive`、所有枚举字段加 `@Enumerated(EnumType.name)`、`Attributes attributes` 嵌入
2. **Equipment**（§4.3）：`@Index() defId` / `@Index() ownerCharacterId`、`List<ForgingSlot> forgingSlots`（实例化时**填满 3 个**，索引 1/2/3）、`List<Lore> lores`、独立 extension `EquipmentResonance` 提供 `resonanceStage` / `resonanceBonus` / `inheritFrom(prevOwnerId)`
3. **Technique**（§4.4）：`@Index() defId` / `@Index() ownerCharacterId`、`List<SkillUsageEntry> skillUsageCount`、独立 extension `TechniqueDispersion.disperse()`

跑 `dart run build_runner build --delete-conflicting-outputs` 生成 `*.g.dart`。

**验收标准**：
- [ ] 3 个 Collection 全部成功生成 schema（`CharacterSchema`、`EquipmentSchema`、`TechniqueSchema`）
- [ ] `flutter analyze` 0 error
- [ ] 临时 main 测试：`Isar.open([CharacterSchema, EquipmentSchema, TechniqueSchema], ...)` 不报错
- [ ] 手动构造 Character + 1 件 Equipment + 1 本 Technique，写入 + 读出，字段完整一致

**可能的坑**：
- `@Index()` **不能加在 List 字段上**（包括 `List<int>` 和 `List<嵌入对象>`），加了 build_runner 直接报错
- `late` 字段未初始化就读会 `LateInitializationError`，**实例化时务必填齐**。建议给 Character 写工厂构造器 `Character.newCharacter({required name, ...})` 统一初始化
- `@Enumerated` **每个枚举字段独立加**，写一次不会自动应用到其他字段
- extension 不要写到 collection 类内部（isar_generator 不认），必须写在文件底部独立 extension 块（参考 schema §4.3）
- `forgingSlots` 实例化时必须填满 3 个（schema 约定 `长度 = 3`），否则后面查 `slotIndex == 2` NoSuchElement
- `*.g.dart` 文件不要手动改，每次 schema 变了重跑 build_runner

---

### T05 · SaveData + IsarSetup（单 slot 简化版）

- **预估时长**：0.5 天
- **依赖任务**：T04
- **涉及文件**：`save_data.dart`、`inventory_item.dart`、`game_event.dart`、`isar_setup.dart`、`main.dart`

**任务内容**：
1. 实现 `SaveData`（schema §4.1），单例 id=0，包含 v1.1 新增的 `slotId` / `slotName`，但 Phase 1 写死 `slotId = 1`
2. 实现 `InventoryItem`（schema §4.8）和 `GameEvent`（schema §4.9）—— Phase 1 不会用到，但放进 schema 清单避免后期迁移
3. 实现 `IsarSetup`（schema §7.1）**简化版**：
   - 只提供 `init({int slotId = 1})` 和 `close()`
   - **暂不实现** `switchSlot` / `listAllSlots` / `deleteSlot`，用 `// TODO Phase 5` 标注
   - 文件命名仍按 `wuxia_save_slot$slotId.isar`，便于后期扩展
4. 在 `main.dart` 启动序：
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await GameRepository.loadAllDefs();  // T07 产出，先占位
     await IsarSetup.init();
     runApp(const ProviderScope(child: WuxiaApp()));
   }
   ```

**验收标准**：
- [ ] 启动时若 SaveData 不存在，自动创建一行（id=0），字段填默认值
- [ ] 启动时若已存在，读出 lastSavedAt 等字段
- [ ] `inspector: true` 打开 Isar Inspector，浏览器能看到所有表（Character/Equipment/Technique/SaveData/InventoryItem/GameEvent）

**可能的坑**：
- `Isar.open` 必须在 `runApp` 之前 await，否则 Provider 读不到
- `getApplicationDocumentsDirectory()` Mac 是 `~/Library/Containers/<bundle>/Data/Documents`，Windows 是 `C:\Users\<user>\Documents`，path_provider 自动处理
- 改 schema（加字段）后要么写 migration，要么删 `wuxia_save_slot1.isar` 重来。Phase 1 没存档负担，删了重跑无压力
- Phase 1 末尾给 SaveData 加上「自动保存」（每 30s 或玩家进入主菜单时），**不要每次战斗都写盘**（性能差）

---

### T06 · 配置类（Defs）

- **预估时长**：1 天
- **依赖任务**：T02
- **涉及文件**：`equipment_def.dart`、`technique_def.dart`、`skill_def.dart`、`stage_def.dart`（含 `EnemyDef`）、`realm_def.dart`

**任务内容**：
按 data_schema.md §5 实现 5 个 Def 类。注意：
- **不加 `@collection` 注解**（Def 不入 Isar）
- 全部字段 `final`，构造函数 `const`（性能更好）
- 字段名照 schema §5 字段表逐项实现
- `EnemyDef` 是 `StageDef.enemyTeam` 内嵌，但作为独立 plain class 而非 `@embedded`（Def 层无 Isar 概念）
- `RealmDef` 包含 tier/layer/absoluteLevel/internalForceMax/experienceToNext/equipmentTierCap/techniqueTierCap

（AdventureDef / SynergyDef / RetreatMapDef 推迟到 Phase 4，本阶段不实现）

**验收标准**：
- [ ] 5 个 Def 类编译通过
- [ ] 每个类写 `factory MyDef.fromYaml(Map<String, dynamic> y)`，能从 yaml 节点构造（具体加载逻辑在 T07）
- [ ] 每个类写 `@override toString()`，便于调试日志

**可能的坑**：
- 不要把 Def 写成 `@collection`，否则 Isar 会尝试持久化，schema 报错
- yaml 解析出来的整数有时是 `int` 有时是 `num`（与 yaml 写法有关）。`fromYaml` 里用 `(y['baseAttackMin'] as num).toInt()` 防御性转换
- 枚举字段从 yaml 里是字符串（如 `"erLiu"`），需要 `RealmTier.values.byName(y['tier'] as String)` 反序列化。**yaml 里的拼写必须与 dart 枚举值名字完全一致**
- `StageDef.enemyTeam` 长度 0-3，要支持空数组解析（剧情关卡可能无敌人）

---

### T07 · YAML 加载器 + GameRepository + 占位数据 fixture

- **预估时长**：1.5 天
- **依赖任务**：T05、T06
- **涉及文件**：`game_repository.dart`、`assets/data/numbers.yaml`（已有）、`equipment.yaml`、`techniques.yaml`、`skills.yaml`、`stages.yaml`

**任务内容**：

#### 7.1 GameRepository 接口
```dart
class GameRepository {
  static late final GameRepository instance;

  // 数值表
  late final NumbersConfig numbers;       // 包装 numbers.yaml 全部内容
  late final List<RealmDef> realms;       // 49 行

  // 内容表（按 id 索引）
  late final Map<String, EquipmentDef> equipmentDefs;
  late final Map<String, TechniqueDef> techniqueDefs;
  late final Map<String, SkillDef> skillDefs;
  late final Map<String, StageDef> stageDefs;

  static Future<void> loadAllDefs() async { /* 从 rootBundle 读 yaml + 解析 */ }

  // 便捷查询方法
  RealmDef getRealm(RealmTier tier, RealmLayer layer);
  RealmDef getRealmByAbsoluteLevel(int level);
  EquipmentDef getEquipment(String defId);
  // ...
}
```

#### 7.2 NumbersConfig 结构
将 numbers.yaml 11 个段落映射为强类型类。**Phase 1 重点用 `combat` 和 `realms` 段**，其他先用 `Map<String, dynamic>` 存原始数据，不强类型化（避免 Phase 1 写一堆用不上的强类型代码）。

#### 7.3 占位数据 fixture（最小可用集）
- **6 本心法**：3 流派（gangMeng/lingQiao/yinRou）× 2 阶（入门功 + 名家功）
- **每本心法 3 招**：1 普攻 + 1 强力 + 1 大招，共 18 招
- **10 件装备**：寻常货武器/护甲/饰品 各 1，像样货/好家伙武器各 1（用于演示装备差距），利器武器 1（用于一流境界对决）；护甲、饰品按需补
- **6 个测试关卡**（不挂主线，纯测试用，stageType 仍设为 `mainline` 即可），每个关卡 3 个敌人
- 武侠风格命名（青锋剑、铁甲、玉佩之类），由 Opus 自己 roll
- description 字段填 `"TODO_NARRATIVE"`，文案是 DeepSeek 的活

#### 7.4 加载顺序
```dart
// main.dart 顺序
await GameRepository.loadAllDefs();   // 1. 先加载 yaml
await IsarSetup.init();               // 2. 再开 Isar
runApp(...);                          // 3. 启动 UI
```

**验收标准**：
- [ ] 启动后日志输出：「已加载 49 行境界 / 10 件装备 / 6 本心法 / 18 招招式 / 6 个关卡」
- [ ] 改 numbers.yaml 一个数值（如 `damage_formula.equipment_attack_factor: 2.0`），重启后 GameRepository.numbers 反映该改动
- [ ] yaml 加载失败时（故意写错语法），fail fast 抛出异常，不要 silent fallback
- [ ] 加载后立即做**红线校验**：循环每件 EquipmentDef 断言 `baseAttackMax <= 2000`、循环每个 RealmDef 断言 `internalForceMax in [500, 15000]`，违反则启动失败

**可能的坑**：
- yaml package 解析出来的 root 类型是 `YamlMap` 而非 `Map<String, dynamic>`，**用前 `.cast<String, dynamic>()` 一次或写工具函数 `Map<String, dynamic> _toMap(dynamic v)`**
- yaml 中 `null` 在 dart 里就是 null，`~` 也表示 null（yaml spec），**统一写显式 `null`**
- 加载顺序：**GameRepository 在 IsarSetup 之前**。Isar 不依赖 Defs，反过来后期某些迁移可能依赖
- 占位 yaml 不要写超出数值红线（武器攻击 > 2000）的值，否则一上来就破红线
- 路径：`rootBundle.loadString('assets/data/numbers.yaml')`，**注意 pubspec.yaml 已声明 assets**，否则 path 找不到
- numbers.yaml 中 `level_diff_modifier.diff_3_or_more.attacker: null`，代码读出来要处理 null 情况（默认取 1.0）

---

## Week 2：战斗核心（T08–T12）

### T08 · 境界派生工具

- **预估时长**：0.5 天
- **依赖任务**：T07
- **涉及文件**：`lib/combat/derived_stats.dart`（新建，本任务先写境界相关）

**任务内容**：
基于 GameRepository.realms 实现：
```dart
class RealmUtils {
  /// 计算 absoluteLevel（1-49）—— 从 RealmDef 表查
  static int absoluteLevelOf(RealmTier tier, RealmLayer layer);

  /// 给定大境界差，返回攻方/守方修正
  static (double attacker, double defender) realmDiffModifier(
      RealmTier attackerTier, RealmTier defenderTier);

  /// 该境界的内力上限
  static int internalForceMaxOf(RealmTier tier, RealmLayer layer);

  /// 该大境界的基础防御率
  static double defenseRateOf(RealmTier tier);

  /// 给定 Character 当前可装备品阶上限
  static EquipmentTier equipmentTierCapOf(RealmTier tier);

  /// 强化等级上限 = absoluteLevel
  static int maxEnhanceLevelOf(Character c);
}
```

**验收标准**：
- [ ] 单元测试覆盖所有方法：
  - `absoluteLevelOf(zongShi, huaJing) == 41`
  - `realmDiffModifier(yiLiu, sanLiu)` → (2.5, 0.3)（差 2 大境界）
  - `realmDiffModifier(sanLiu, jueDing)` → (1.0, 0.05)（差 3+ 守方基本免疫）
  - `defenseRateOf(yiLiu) == 0.20`
- [ ] 所有方法都查 GameRepository.realms 表，**不硬编码任何数字**

**可能的坑**：
- `RealmTier.values.indexOf(tier)` 注意枚举顺序：`xueTu`(0) → `wuSheng`(6)，差值 `attackerTier.index - defenderTier.index`
- 差 ≤ -3 时按 GDD §5.5：守方修正 0.05（低境界打高境界 5%），攻方修正 yaml 是 `null`，**取 attacker = 1.0 即可**（已经被碾压无须放大）
- 同境界 (1.0, 1.0)，差 -1（低打高）返回 (?, 0.7)，**这里两个数字是从攻方视角看的，文档表述容易绕，写测试钉死**

---

### T09 · 角色派生属性（HP / 速度 / 暴击 / 闪避）

- **预估时长**：0.5 天
- **依赖任务**：T08
- **涉及文件**：`lib/combat/derived_stats.dart`（继续）

**任务内容**：
实现 numbers.yaml `combat` 段的全部派生公式：

```dart
class CharacterDerivedStats {
  /// HP = 1000 + 内力*0.7 + 根骨*500 + 装备血量
  static int maxHp(Character c, List<Equipment> equipped, NumbersConfig n);

  /// 速度 = 100 + 身法*8 + 装备速度 + 心法速度加成
  static int speed(Character c, List<Equipment> equipped, Technique mainTech, NumbersConfig n);

  /// 暴击率：base 0.05 + 身法*0.005，灵巧流派 +0.20，clamp(0, 0.50)
  static double criticalRate(Character c, NumbersConfig n);

  /// 闪避率：身法*0.003，clamp(0, 0.30)
  static double evasionRate(Character c, NumbersConfig n);

  /// 派生：装备攻击 = baseAttack * (1 + enhanceLevel*0.05) * 共鸣度倍率 * 开锋槽位加成
  static int effectiveEquipmentAttack(Equipment eq, NumbersConfig n);
  static int effectiveEquipmentHp(Equipment eq, NumbersConfig n);
  static int effectiveEquipmentSpeed(Equipment eq, NumbersConfig n);
}
```

**验收标准**：
- [ ] 单元测试对照 numbers.yaml §11 五个 validation_examples 的 HP 数字，**误差 ≤ 5%**（浮点精度）
- [ ] 暴击率上限严格 0.50（哪怕身法 100 + 灵巧流派也不能超过）
- [ ] 装备 +0 强化共鸣生疏无开锋时 effectiveEquipmentAttack == baseAttack（没有意外加成）

**可能的坑**：
- numbers.yaml 中 `equipment_attack_factor: 1.0`（**不是 8.0**），这是经过平衡的，不要按 GDD 字面值改回 8
- 心法速度加成 = `mainTech.tier` 对应 `speed_bonus`（numbers.yaml techniques.tiers），**辅修不加**
- 装备血量 effectiveEquipmentHp 也要应用强化倍率（每级 +5%）
- 灵巧流派 +20% 暴击率是**额外加成**：先算 `base + agility * 0.005`，再 +0.20，**最后才 clamp** 到 0.50
- 装备攻击的多重加成顺序：`baseAttack × (1 + enhanceLevel * 0.05) × resonanceBonus × (1 + 开锋攻击%)`，**乘法连乘**而非加法。校验：寻常货 +0 共鸣生疏无开锋的攻击 = `baseAttack × 1.0 × 1.0 × 1.0 = baseAttack` ✓

---

### T10 · 伤害计算器（核心）

- **预估时长**：1.5 天
- **依赖任务**：T09
- **涉及文件**：`lib/combat/damage_calculator.dart`

**任务内容**：
实现 GDD §5.3/§5.4 全部公式。这是 Phase 1 最核心的代码，必须严格按 numbers.yaml combat 段。

```dart
/// 一次攻击的输入
class AttackContext {
  final Character attacker;
  final List<Equipment> attackerEquipped;
  final Technique attackerMainTech;
  final SkillDef skill;             // 普攻 / 强力 / 大招

  final Character defender;
  final List<Equipment> defenderEquipped;
  final Technique defenderMainTech;

  final bool forceCritical;          // 测试用，强制暴击
  final Random? rng;                 // 测试时传入固定 seed
}

/// 一次攻击的输出
class AttackResult {
  final int finalDamage;
  final bool isCritical;
  final bool isDodged;
  final double schoolCounterMultiplier;  // 0.75 / 1.0 / 1.25
  final double realmDiffAttackerMod;
  final double realmDiffDefenderMod;
  final List<String> appliedEffects;     // ["extra_quake_dmg", "internal_injury"...]
  final String formulaBreakdown;         // 调试用文本
}

class DamageCalculator {
  static AttackResult calculate(AttackContext ctx, NumbersConfig n);
}
```

**实现步骤**：
1. 闪避判定：roll 0-1，若 < `defender.evasionRate`，返回 `isDodged: true`
2. 基础伤害 = `attacker.内力 * 0.4 + attacker.装备攻击 * 1.0 + skill.powerMultiplier`
3. 心法修炼度倍率 = `attacker.mainTech.cultivationLayer` 查 yaml 表（1.0 ~ 3.0）
4. 流派克制倍率：
   - attacker.school 克 defender.school → 1.25 + extra_effect
   - attacker.school 被 defender.school 克 → 0.75
   - 否则（同流派或非克制关系） → 1.00
5. 暴击：roll 0-1，若 < `attacker.criticalRate` 或 `forceCritical=true`，乘 base_damage_multiplier (1.5)；灵巧流派暴击使用更高倍率（Phase 1 简化为 2.0）
6. 防御率应用：`× (1 - defender.defenseRate)`
7. 境界差修正：`× attackerMod`（schema §5.5：高境界打你时 attackerMod = 1.4，你打高境界用 defenderMod = 0.7）
8. 取整 → finalDamage

**验收标准**：
- [ ] 单元测试覆盖 numbers.yaml §11 五个战例（A/B/C/D/E），每个的 `calculated_damage` 应当与代码计算结果**误差 ≤ 5%**（浮点 + roll 随机性，固定 seed 后一致）
- [ ] 武圣 vs 武圣战例 E，最终伤害 ≤ 100000（公式真实值 ~52000，留 2× buffer 防数值崩盘；实际是否一击致死取决于守方血量，与本伤害上限无关）
- [ ] `formulaBreakdown` 字符串能被人读懂：`"(800*0.4 + 130 + 500) * 1.0 * 1.25 * 1.5 * 0.85 * 1.0 = 1467"`
- [ ] 流派克制矩阵测试：刚猛打阴柔 → 1.25；阴柔打刚猛 → 0.75；刚猛打灵巧 → 0.75（被克）；刚猛打刚猛 → 1.0

**可能的坑**：
- **公式系数务必从 NumbersConfig 读，不要硬编码 0.4 / 1.0 / 0.7 等魔数**（即使现在写对了，调平衡时一改就忘）
- 闪避 roll 用 `Random()` 默认就行，但**测试时要传 `Random(seed)` 固定 seed**，`AttackContext.rng` 字段为此设
- 流派克制是单向：刚猛 → 阴柔单向克制。反向（阴柔打刚猛）走"被克 ×0.75"分支，因为被刚猛克的是阴柔。**写一个 3×3 矩阵的查表函数最稳，不要用嵌套 if-else**
- 暴击系数有两档：基础 1.5、最高 2.5。Phase 1 简化为：普通暴击 ×1.5，灵巧流派暴击 ×2.0。**写 yaml 字段配置**而不要在代码里加 if-else
- 暴击 + 流派克制的额外效果（如灵巧克刚猛额外 +20% 暴击率）：暴击率在 T09 计算暴击率时已经加上，**这里不要重复加**

---

### T11 · 战斗状态机数据结构

- **预估时长**：1 天
- **依赖任务**：T10
- **涉及文件**：`lib/combat/battle_state.dart`

**任务内容**：
设计战斗状态机的 immutable 数据结构（Riverpod 友好）：

```dart
/// 战斗中的角色快照（缓存派生属性，避免每 tick 重算）
class BattleCharacter {
  final int characterId;                  // ↔ Character.id
  final String name;
  final RealmTier realmTier;
  final RealmLayer realmLayer;
  final TechniqueSchool school;
  final int maxHp;
  final int currentHp;                    // ← 战斗中变化
  final int maxInternalForce;
  final int currentInternalForce;         // ← 战斗中变化
  final int speed;
  final double criticalRate;
  final double evasionRate;
  final List<SkillDef> availableSkills;   // 主修心法的招式
  final Map<String, int> skillCooldowns;  // skillId → 剩余 CD
  final List<String> activeBuffs;         // ["internal_injury", ...]
  final int actionPoint;                  // ← time-based 行动制：累积到 1000 触发行动
  final bool isAlive;
  final int teamSide;                     // 0=左队 1=右队
  final int slotIndex;                    // 队内位置 0/1/2

  BattleCharacter copyWith({...});
}

/// 战斗整体状态
class BattleState {
  final List<BattleCharacter> leftTeam;   // 玩家方
  final List<BattleCharacter> rightTeam;  // 敌方
  final int tick;                         // 已经过的 tick 数（每 tick = 100ms 概念，但实际是逻辑 tick）
  final BattleResult? result;             // null 表示战斗中
  final List<BattleAction> actionLog;     // 已发生的所有动作（T13 用）

  BattleState copyWith({...});
}

enum BattleResult { leftWin, rightWin, draw }

/// 一次战斗动作（用于动画播放和日志）
class BattleAction {
  final int tick;
  final int actorId;
  final int? targetId;
  final SkillDef? skill;
  final AttackResult? attackResult;
  final String description;               // "祖师对鬼影刀客使用青龙拳，造成 1234 伤害"
}
```

**验收标准**：
- [ ] `BattleCharacter.copyWith` 单元测试：HP 变化只影响 currentHp，其他字段不变
- [ ] `BattleState.copyWith` 单元测试：能正确构造下一个 tick 的状态
- [ ] 工厂方法 `BattleCharacter.fromCharacter(Character c, ...)`：从 Isar 实体生成战斗快照（计算所有派生属性）

**可能的坑**：
- BattleCharacter 用 immutable 设计，每次状态变化产生新对象。Riverpod 监听只在引用变化时触发，避免无限重建
- `actionPoint` 的实现：每 tick 全员 actionPoint += speed；累积到 1000 则该角色行动并归零（time-based 行动制比"每回合所有人轮流出手"更符合速度差直观）
- `skillCooldowns` 战斗开始时为空 map，使用招式后写入 `cooldownTurns`，每 tick 全员减 1（最低 0）
- 不要在 BattleCharacter 里直接持 Equipment 或 Technique 引用（持久化对象在 Isar 里），快照只缓存派生属性，**避免战斗中误改 Isar 数据**

---

### T12 · 战斗引擎 + AI 行动选择

- **预估时长**：1.5 天
- **依赖任务**：T11
- **涉及文件**：`lib/combat/battle_engine.dart`、`lib/combat/battle_ai.dart`

**任务内容**：

#### 12.1 BattleEngine
```dart
class BattleEngine {
  /// 推进一个 tick：所有角色 actionPoint += speed；找出 ≥ 1000 的角色按 actionPoint 大到小依次行动
  static BattleState tick(BattleState state, NumbersConfig n);

  /// 跑完整场战斗（用于纯逻辑模拟，不带动画）
  static BattleState runToEnd(BattleState initial, NumbersConfig n, {int maxTicks = 1000});

  /// 玩家手动触发大招（中途插入，下次该角色 actionPoint 满时优先放大招）
  static BattleState requestUltimate(BattleState state, int characterId, SkillDef ultimate);
}
```

#### 12.2 BattleAI（行动决策）
```dart
class BattleAI {
  /// 选择本次行动（招式 + 目标）
  static (SkillDef skill, int targetId) decide(
    BattleCharacter actor,
    BattleState state,
    NumbersConfig n,
  );
}
```

**Phase 1 简化策略**：
- 招式选择：优先级是 大招（如果手动请求且内力 + CD 满足）> 强力技能（内力够且 CD 0）> 普攻
- 目标选择：选对方队伍中**当前 HP 最低的存活角色**（简单粗暴但效果直观）
- 大招手动请求队列：state 里带一个 `Map<int, SkillDef> pendingUltimates`，下次该角色行动时弹出

#### 12.3 死亡 / 胜负判定
- 一方全员 isAlive == false → 战斗结束
- maxTicks 触发 → draw（防死循环兜底）
- 行动后立即更新 BattleAction 写入 actionLog

**验收标准**：
- [ ] 单元测试：3v3 同境界同流派同装备的战斗，平均 50-200 tick 内分出胜负，不死循环
- [ ] 速度差测试：A 队全员 speed=200，B 队全员 speed=100，A 队应当行动次数约为 B 队的 2 倍
- [ ] 大招请求测试：玩家请求祖师放大招后，祖师下次行动一定使用该大招（前提内力够、CD 0）
- [ ] 单元测试：境界差测试，三流满员去打绝顶满员，几乎必败（守方 0.05 修正）

**可能的坑**：
- **同 tick 多人 actionPoint ≥ 1000 时**：按 actionPoint 大到小排序行动；同分按 speed 高优先；都同则按 (teamSide, slotIndex) 排序破平局。**写测试钉死顺序**否则结果不稳定
- 死亡角色仍占阵容位置，但 isAlive=false 不行动；AI 选目标时跳过
- 招式 CD 在该角色行动后立即写入 `cooldownTurns`，下个 tick 才开始减 1（**当前 tick 不减**），否则 CD 1 的招式效果同 0
- 内力消耗：行动时立即扣，不够则降级到普攻
- maxTicks 兜底很重要：3v3 互相打不动（境界差太大双方都基本免疫）会死循环，必须有上限
- 玩家手动大招的实现细节：**不打断当前 tick 的行动顺序**，只是把"下次行动用什么招"标记下来。否则按下大招按钮立即生效会让节奏混乱

---

## Week 3：UI、串接与验收（T13–T18）

### T13 · 战斗事件日志

- **预估时长**：0.5 天
- **依赖任务**：T12
- **涉及文件**：`lib/combat/battle_log.dart`

**任务内容**：
把 BattleState.actionLog 转换为人类可读的中文战斗日志（先存内存，调试用，UI 可在战斗界面侧边栏展示）：

```dart
class BattleLog {
  /// 把一个 BattleAction 转为中文日志条目
  static String formatAction(BattleAction action, BattleState state);
  // 例 "[第 23 tick] 祖师对鬼影刀客使用「青龙拳」，命中暴击，造成 2340 伤害（流派克制 ×1.25）"

  /// 战斗结束总结
  static String formatSummary(BattleState finalState);
  // 例 "战斗结束（左队胜）。共 87 tick，祖师造成最高伤害 8420，鬼影刀客被击杀"
}
```

**Phase 1 还不接入 GameEvent 持久化**（那是"昨晚发生的事"系统，Phase 4 实现）。本任务只是产出可读日志字符串，便于 T14 的 UI 在侧边栏展示。

**验收标准**：
- [ ] 跑一场完整战斗，输出的日志字符串覆盖：行动顺序、伤害数字、暴击/闪避/克制标识、胜负结果
- [ ] 日志中文文案不出现 enum 拼音（如 `gangMeng` 应该转为 `刚猛`），写一个 enum → 中文字符串的工具函数

**可能的坑**：
- enum → 中文字符串的转换函数要单独抽出来（`lib/combat/enum_localizations.dart`），**Phase 4 才会被 DeepSeek 文案接管**，本阶段先用硬编码中文（这是唯一允许的"代码内中文"，且仅限调试日志）
- 日志格式化和实际伤害计算分离，**不要在 DamageCalculator 里写日志字符串**

---

### T14 · 战斗 UI 布局（3v3 半横版）

- **预估时长**：1 天
- **依赖任务**：T13
- **涉及文件**：`lib/ui/battle/battle_screen.dart`、`character_avatar.dart`、`hp_bar.dart`

**任务内容**：
实现半横版 3v3 战斗的静态布局（动画下个任务）：

```
┌────────────────────────────────────────────────────────┐
│ [日志侧边栏]                              战斗 X v Y    │
│                                                         │
│   [我方0]                                  [敌方0]      │
│   HP: ████░░  3000/5000                  HP: ███░░ ...  │
│                                                         │
│   [我方1]                                  [敌方1]      │
│   HP: █████░  4000/5000                  HP: ██░░░ ...  │
│                                                         │
│   [我方2]                                  [敌方2]      │
│   HP: ██████  5000/5000                  HP: █████ ...  │
│                                                         │
│ [大招按钮 1] [大招按钮 2] [大招按钮 3]    [快进按钮]     │
└────────────────────────────────────────────────────────┘
```

**Widget 拆分**：
- `BattleScreen`：StatelessWidget，从 `battleStateProvider` 监听 BattleState
- `CharacterAvatar`：显示角色头像（占位用 CircleAvatar + 首字 + 流派颜色边框：刚猛红、灵巧金、阴柔紫）+ 名字 + 境界
- `HpBar`：自绘 Container，背景灰，前景按 currentHp/maxHp 比例填充
- 内力条同样位置但更细
- 大招按钮：仅当对应角色内力够 + CD 0 时点亮

**验收标准**：
- [ ] 16:9 窗口下 6 个角色 + HP 条不重叠，左 3 右 3 对称
- [ ] HP 比例正确显示（如 currentHp=3000 / maxHp=5000 显示 60% 填充）
- [ ] 流派颜色边框区分明显（不需要看名字也能一眼看出三种流派）
- [ ] 死亡角色变灰（透明度 0.3）

**可能的坑**：
- Flutter Desktop 默认窗口太小，**main.dart 启动时要 setSize**（用 `window_manager` 或 native 方式，Phase 1 简单点直接 `await DesktopWindow.setWindowSize(Size(1280, 720))` 或类似）
- HP 条颜色：HP > 50% 绿，25-50% 黄，< 25% 红（用 LinearGradient 平滑过渡也行）
- **不要用 Stack + Positioned 写整个布局**，用 Row/Column + Expanded/Spacer，否则窗口缩放会乱
- 流派颜色三色定义放在 `lib/ui/theme/colors.dart`：`schoolColor(TechniqueSchool s)` 返回 Color

---

### T15 · 攻击动画 + 伤害飘字

- **预估时长**：1.5 天
- **依赖任务**：T14
- **涉及文件**：`battle_screen.dart`（继续）、`damage_popup.dart`、新建 `lib/ui/battle/attack_animation.dart`

**任务内容**：

#### 15.1 攻击动画：前冲 - 出招 - 后撤
- 用 `AnimationController` + `Transform.translate` 实现位移
- 时间序列：
  - 0-150ms：从原位置向对方方向冲过去（Curves.easeIn）
  - 150-250ms：停顿（出招瞬间，伤害此时弹出）
  - 250-400ms：返回原位（Curves.easeOut）
- 队左角色向右冲，队右角色向左冲

#### 15.2 伤害飘字
- 在被攻击者头顶弹出数字，向上漂浮 + 淡出（800ms）
- 颜色规则：
  - 普通伤害：白色
  - 暴击：金色 + 字体加大 1.5x + 短暂屏震（震屏用 Transform.translate 整个 BattleScreen 5px 以内）
  - 闪避：显示「闪」字，灰色
  - 流派克制：在数字旁边加 ⬆ 或 ⬇ 小标记
- 文字描边用 `Text.rich` + `Stroke` 或 `Shadow`

#### 15.3 动画与逻辑解耦
- 战斗逻辑跑完得到 `List<BattleAction>`（T11/T12 已产出）
- UI 层用一个 timer/scheduler 顺序播放每个 action 的动画
- 一次 action 全播完（约 400ms 主动画 + 400ms 飘字延迟）才进入下一个
- 快进按钮：把 timer 间隔从 800ms 缩到 100ms，或直接跳到结果

**验收标准**：
- [ ] 一次普攻动画流畅，60 FPS 不卡顿（macOS dev 模式下）
- [ ] 暴击时金色 + 屏震效果明显（一眼认出是暴击）
- [ ] 闪避时不弹伤害数字，弹「闪」字
- [ ] 同时多个伤害飘字不重叠（用 Stack 内随机微偏移）
- [ ] 快进按钮按下后，整场战斗在 5 秒内播完

**可能的坑**：
- 多个 AnimationController 同时跑必须 **`dispose()` 干净**，否则内存泄漏。用 `TickerProviderStateMixin`，dispose 时一并清理
- 动画和战斗逻辑必须**解耦**：不要一边跑战斗逻辑一边跑动画，否则战斗很慢且容易出 bug。先纯逻辑跑出 actionLog，再 UI 顺序播放
- 屏震不要太狠：`Transform.translate(Offset(±3, ±3))` 持续 100ms 即可，过了就晕
- 飘字 widget 数量太多会卡顿（30+ 同时存在），及时移除淡出完成的飘字
- 角色 widget 在 Stack 里移动时，HP 条要跟着移动（**HP 条作为 CharacterAvatar 的 child 一起 Transform**，不要分离）

---

### T16 · 手动大招触发 + Riverpod 串接

- **预估时长**：0.5 天
- **依赖任务**：T15
- **涉及文件**：`lib/providers/battle_providers.dart`、`battle_screen.dart`（继续）

**任务内容**：

#### 16.1 Riverpod 状态供给
```dart
@riverpod
class BattleNotifier extends _$BattleNotifier {
  @override
  BattleState build() => /* 初始化空战斗 */;

  void startBattle(List<Character> playerTeam, StageDef stage) {...}
  void requestUltimate(int characterId, SkillDef ultimate) {...}
  void advanceTick() {...}  // 由 UI 层 timer 驱动
  void fastForward() {...}
}

/// 派生 provider：避免整个 BattleState 重建导致 UI 全量刷新
final leftTeamProvider = Provider<List<BattleCharacter>>((ref) =>
  ref.watch(battleNotifierProvider).leftTeam);

final battleResultProvider = Provider<BattleResult?>((ref) =>
  ref.watch(battleNotifierProvider).result);
```

#### 16.2 大招按钮逻辑
- 大招按钮显示条件：该角色主修心法的 `ultimate` 招式存在，内力 ≥ skill.internalForceCost，CD 0
- 按下后调用 `ref.read(battleNotifierProvider.notifier).requestUltimate(characterId, ultimate)`
- 按下后按钮立刻置灰（避免连按），下次该角色行动后才解除置灰

#### 16.3 战斗结算 UI
- 战斗结束（result != null）→ 弹出 overlay 显示「胜利 / 失败」+ 关键数据（总伤害、暴击次数、用时 tick 数）
- Phase 1 不实现奖励发放（装备掉落、经验等），只是返回主菜单

**验收标准**：
- [ ] 战斗中按下大招按钮，下次该角色行动一定使用该大招（前提满足）
- [ ] HP 变化时只有对应角色 widget 重建，不是整个屏幕重建（用 `flutter inspector` 查 rebuild 频率验证）
- [ ] 战斗结束 overlay 正常显示，点击关闭返回上一界面

**可能的坑**：
- Riverpod 在战斗 tick 频繁变化时容易触发整屏 rebuild。**派生 provider 必须细粒度**（每个角色一个 currentHp 单独 provider 也不过分）
- 千万不要在战斗循环里调用 Isar 写入（性能差），**战斗结束才统一结算**写盘
- 大招按钮的"按下后置灰"用本地 state，不要污染全局 BattleState（按钮 UI 状态属于 UI 层）

---

### T17 · 测试场景（4 套预设战斗）

- **预估时长**：1 天
- **依赖任务**：T16
- **涉及文件**：`lib/ui/debug/battle_test_menu.dart`、`assets/data/test_scenarios.yaml`（新建）、`stages.yaml`（补充）

**任务内容**：
新建一个调试入口（暂时挂在 main.dart 的入口屏，正式 UI 留到 Phase 3），列出 4 个预设战斗，对应 Phase 1 验收要展示的 4 个核心体验：

| 场景 | 演示重点 | 设计 |
|------|---------|------|
| **A · 同境界基础对决** | 基础伤害公式、节奏感 | 二流·圆熟 3v3，三人都是同流派同装备，纯比谁先出招 |
| **B · 流派克制循环** | 三流派克制的视觉差异 | 一流·启蒙 3v3，左队三人分别为刚猛/灵巧/阴柔，右队对应阴柔/刚猛/灵巧（一一克制） |
| **C · 装备影响伤害** | 装备 + 共鸣 + 强化的累加效果 | 二流·圆熟 1v1（其他位置空），左方武器 +12 强化共鸣"默契"，右方裸装。预期左方两击杀对方 |
| **D · 境界差距碾压 / 蚂蚁咬大象** | 境界差修正 ×0.05 | 三流·登峰 3v3 vs 绝顶·启蒙 3v3。左队差 2 大境界。预期左队基本打不动右队，右队两三招清场 |

**实现细节**：
- 在调试菜单里 4 个按钮，点击后用 hard-coded 的角色 + 装备 + 心法配置启动战斗（**不写入 Isar**，用临时构造的内存对象）
- 每个场景跑完后回到调试菜单
- 每个场景顶部显示一行 hint，提醒玩家观察什么（如「场景 B：注意三种流派的颜色与暴击表现」）

**验收标准**：
- [ ] 4 个场景都能正常启动并跑完
- [ ] 场景 A：双方互殴，每一击伤害落在 2000-8000 区间
- [ ] 场景 B：刚猛打阴柔时伤害明显高于打灵巧时（前者 ×1.25，后者 ×0.75，差距 1.67 倍）
- [ ] 场景 C：左方 +12 强化的角色伤害比右方裸装高 ≥ 60%（强化 +12 = ×1.6 倍数值）
- [ ] 场景 D：左队（低境界）打右队（高境界）伤害基本是 100-300 / 击，几乎打不动；右队反之一两招秒杀

**可能的坑**：
- 临时构造的 Character 等对象，**不要 Isar.put**（污染存档）。直接用 dart 构造器 new 出来传给战斗引擎
- yaml fixture 不够用时（如缺一阶利器武器），可以在测试代码里直接 `EquipmentDef(...)` 构造测试专用的 Def，**不要写到正式 yaml**
- 场景 C 的强化共鸣组合：要在测试代码里直接设 `equipment.enhanceLevel = 12; equipment.battleCount = 600;`（共鸣 500-2000 = 默契阶段），跳过强化系统
- 场景 D 的境界差很容易触发"双方都打不动"死循环（守方 ×0.05），所以高境界一方必须用强力技能或暴击破局；T12 的 maxTicks 兜底也要保证不死循环

---

### T18 · Phase 1 验收 + 缓冲日

- **预估时长**：0.5 天
- **依赖任务**：T17
- **涉及文件**：跑一遍验收清单 + 修零碎 bug

**任务内容**：
1. 按下面的「第一阶段验收清单」逐项过一遍，截图存档
2. 修零碎 bug（动画、布局、文字、性能）
3. git tag `v0.1.0-phase1`，commit message 包含本阶段交付物清单
4. 写一份 1 页的 phase1_summary.md，记录：
   - 交付了什么（功能清单）
   - 数值校验（5 个 validation_examples 实测 vs 预期对照表）
   - 已知问题 / Phase 2 待办
   - 性能基准（动画 FPS、战斗 tick 速度）

**验收标准**：见下方独立章节《第一阶段验收清单》

**可能的坑**：
- 别在最后一天加新 feature，专门用来打磨已有功能的细节
- 验收清单里任何一项不通过，回头修不能跳过
- git tag 之前确认 main 分支干净、构建过 release 包能跑

---

## 第一阶段验收清单（Demo 第 1 版能展示什么）

跑完所有 18 个任务后，本阶段产物应当能向（你自己 / 朋友 / 投资人）演示以下内容。**每一条都要能现场跑给人看**，不是"理论上能做到"。

### A. 启动与基础架构

- [ ] **A1** `flutter run -d windows`（或 macos）能启动游戏，不到 5 秒进入主菜单
- [ ] **A2** 关闭游戏再开，存档元数据（SaveData.lastSavedAt 等）正确恢复
- [ ] **A3** 改 `numbers.yaml` 里 `equipment_attack_factor: 2.0`，重启后战斗伤害约翻倍（证明数值与代码彻底解耦）

### B. 战斗 UI 与节奏

- [ ] **B1** 调试菜单 → 场景 A，能看到 3v3 半横版战斗画面，左 3 右 3 角色对称
- [ ] **B2** 角色按速度自动出手，攻击动画"前冲-出招-后撤"流畅
- [ ] **B3** HP 条实时下降，颜色随血量变化（绿→黄→红）
- [ ] **B4** 伤害数字飘字向上漂浮 + 淡出
- [ ] **B5** 普通伤害数字落在 **2000-8000 区间**（验证 GDD §5.2 红线）
- [ ] **B6** 角色死亡变灰，不再行动

### C. 流派克制（场景 B）

- [ ] **C1** 三个流派（刚猛红 / 灵巧金 / 阴柔紫）头像边框颜色一眼可分
- [ ] **C2** 刚猛打阴柔时伤害数字明显高（旁边有 ⬆ 标记），约 ×1.25
- [ ] **C3** 阴柔打刚猛时伤害明显低（旁边有 ⬇ 标记），约 ×0.75
- [ ] **C4** 同流派或非克制关系打击伤害无修正

### D. 暴击（场景 A 或 B 中观察）

- [ ] **D1** 暴击时数字变金色 + 字号变大 1.5x
- [ ] **D2** 暴击时屏幕短暂震动
- [ ] **D3** 灵巧流派的暴击率明显高于其他两派（统计 30 次出手，灵巧暴击次数 ≥ 其他流派 1.5 倍）
- [ ] **D4** 闪避时弹"闪"字而非伤害数字

### E. 装备影响伤害（场景 C）

- [ ] **E1** 同境界 1v1，左方 +12 强化共鸣"默契"角色 vs 右方裸装角色
- [ ] **E2** 左方两击杀对方，右方需要 3-5 击才能造成同样伤害
- [ ] **E3** 大招按钮可手动触发（内力够 + CD 0 时点亮），按下后下次行动放出
- [ ] **E4** 大招暴击伤害**上万**（验证 GDD §5.2 大招红线）

### F. 境界差距修正（场景 D）

- [ ] **F1** 三流·登峰 3v3 vs 绝顶·启蒙 3v3
- [ ] **F2** 三流方打绝顶方，每击伤害仅 100-300（守方修正 ×0.05 几乎免疫）
- [ ] **F3** 绝顶方打三流方，每击伤害 ≥ 普通伤害的 2.5 倍（攻方修正 ×2.5），一两招秒杀
- [ ] **F4** 战斗在合理 tick 数内结束（绝顶方碾压，不死循环）

### G. 数据持久化与红线

- [ ] **G1** 启动日志输出：「已加载 49 行境界 / N 件装备 / N 本心法 / N 招招式 / N 个关卡」
- [ ] **G2** 加载阶段红线校验通过：所有 EquipmentDef.baseAttackMax ≤ 2000、所有 RealmDef.internalForceMax ∈ [500, 15000]
- [ ] **G3** 跑 numbers.yaml §11 的 5 个 validation_examples，实测伤害与预期 calculated_damage 误差 ≤ 5%
- [ ] **G4** Isar Inspector 浏览器视图能看到 SaveData / Character / Equipment / Technique / InventoryItem / GameEvent 表

### H. 性能与稳定

- [ ] **H1** 战斗中动画 60 FPS（debug 模式 30+ FPS 也算过）
- [ ] **H2** 跑场景 D（境界差大）不死循环（maxTicks 兜底生效）
- [ ] **H3** 整场战斗（约 100 tick）内存占用稳定（不持续涨）

---

## 已知不在 Phase 1 范围内的内容（避免误解）

下面这些 Phase 1 **故意不做**，留到后续阶段。验收时如果发现没有，**不算 bug**：

- 主菜单（仅有调试入口，正式主菜单留到 Phase 3）
- 「昨晚发生的事」上线第一屏（Phase 4）
- 真正的角色生成（属性 roll、出生稀有度），Phase 1 用 hard-coded 测试角色
- 装备掉落 / 强化 / 开锋 / 共鸣度递增（Phase 2 装备系统专题）
- 心法学习 / 修炼度递增 / 散功（Phase 2 心法系统专题）
- 闭关、奇遇、师徒、爬塔、主线（Phase 3+）
- 美术资源（角色都是占位 CircleAvatar，敌人头像同），Phase 5 接 AI 出图
- 文案（除了硬编码的调试日志中文，其余 description 都是 `TODO_NARRATIVE`），Phase 4 接 DeepSeek

如果 Phase 1 把这些都做了，那就过度交付了，意味着上面 18 个任务没做扎实。

---

**文档结束。**

> 交给 Claude Code 时建议：复制本文档贴进 Claude Code，告诉它「按 T01 → T18 顺序执行，每完成一个任务停下来等我 review，跑通 acceptance 后再开下一个」。每个任务的「可能的坑」是从 GDD/schema/numbers 三份文档里推断出的高风险点，可以让 Claude Code 实现前先看一眼。
