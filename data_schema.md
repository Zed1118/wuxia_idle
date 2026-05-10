# data_schema.md · 数据模型定义

> **文档地位**：本项目所有 Dart model 类的字段定义规范。所有持久化逻辑、yaml 配置加载、UI 数据绑定都以本文档为准。
>
> **遵循 GDD.md v1.1**
>
> **本文档版本**：v1.1（Demo 阶段定稿 · 修订版）
>
> **v1.1 变更**：
> 1. 新增 §3.6 Map 字段方案对照表（与实际字段一一对应）
> 2. SaveData 增加多存档支持（`slotId` / `slotName`），用多 Isar db 文件隔离
> 3. DailyChallenge 钉死 dateKey 时区规则（强制本地时区）
> 4. AdventureDef 增加 `enemyTeamKey` 扩展字段（Demo 全填 null，未来支持战斗向奇遇）
> 5. §7 IsarSetup 改造为多存档架构（含切换槽位、列出槽位元信息工具方法）
>
> **维护规则**：本文档由 Mac 端 Claude Code + Opus 4.7 维护。新增 model 或修改字段需在 commit message 注明 `[SCHEMA]` 前缀。

---

## 目录

0. [文档定位](#0-文档定位)
1. [设计原则](#1-设计原则)
2. [枚举类型](#2-枚举类型)
3. [嵌入对象（@Embedded）](#3-嵌入对象embedded)
4. [持久化实体（@Collection）](#4-持久化实体collection)
5. [配置类（YAML 加载）](#5-配置类yaml-加载)
6. [实体关系图](#6-实体关系图)
7. [Isar 初始化样板代码](#7-isar-初始化样板代码)

---

## 0. 文档定位

本文档定义两类数据：

| 类型 | 加载方式 | 后缀约定 | 示例 |
|------|---------|---------|------|
| **持久化实体** | Isar 数据库读写 | 无后缀（本名） | `Character`、`Equipment` |
| **配置类** | 启动时从 yaml 加载到内存 | `Def` 后缀 | `EquipmentDef`、`StageDef` |

> **关键约定**：所有数值（基础攻击、修炼度加成、关卡难度系数等）只在配置类中定义，玩家实例只存"指向哪个 Def + 玩家个人状态（强化等级、共鸣次数等）"。

---

## 1. 设计原则

### 1.1 配置 vs 存档分离

```
┌──────────────────────────────────────────────┐
│  data/*.yaml （只读，发版打包）                 │
│  → EquipmentDef / TechniqueDef / StageDef ... │
│  → 启动时一次性加载到内存（GameRepository）     │
└──────────────────────────────────────────────┘
                    │ 引用 defId
                    ▼
┌──────────────────────────────────────────────┐
│  Isar 数据库（玩家本地存档）                    │
│  → Character / Equipment / Technique ...      │
│  → 实时读写，自动持久化                         │
└──────────────────────────────────────────────┘
```

**好处**：
- 改数值只改 yaml，不动代码、不动存档结构
- 存档体积小（不重复存配置数据）
- 后期可解锁 MOD：玩家替换 yaml 即可改游戏（GDD §12.4 已留接口）

### 1.2 Isar 关键约定

- **主键**：所有 Collection 用 `Id id = Isar.autoIncrement;`，类型 `Id` 是 Isar 内部 `int` typedef。
- **外键**：Isar 不支持真正的外键约束。关系用 `int? xxxId` 显式存储，应用层负责一致性。
- **索引**：常用查询字段加 `@Index()`；唯一字段加 `@Index(unique: true)`。
- **枚举**：所有枚举字段加 `@Enumerated(EnumType.name)`，用枚举名（字符串）持久化，便于增删枚举值不破坏存档。
- **嵌入对象**：用 `@Embedded()`，**只能嵌入一层**；不能在 `@Embedded` 里再嵌套 `@Embedded`。
- **List 字段**：基础类型 List 直接存（`List<int>`），对象 List 必须是 `@Embedded` 类型。
- **Map 字段**：Isar 不直接支持 `Map`，需要用 `List<XxxEntry>` 嵌入对象模拟。

### 1.3 命名约定

| 维度 | 约定 | 示例 |
|------|------|------|
| Collection 名 | 单数 + PascalCase | `Character` |
| 字段名 | camelCase（英文） | `internalForce`、`enhanceLevel` |
| 枚举名 | PascalCase | `RealmTier`、`TechniqueSchool` |
| 枚举值 | camelCase（中文拼音） | `xueTu`、`gangMeng` |
| 配置类后缀 | `Def` | `EquipmentDef` |
| FK 字段 | `xxxId` 或 `xxxIds` | `mainTechniqueId`、`discipleIds` |
| Def 引用 | `defId`（String 类型） | `Equipment.defId = "weapon_iron_sword"` |

### 1.4 时间字段约定

| 字段 | 用途 | 类型 |
|------|------|------|
| `createdAt` | 实体创建时间（真实） | `DateTime` |
| `lastSavedAt` | 最后保存时间 | `DateTime` |
| `startedAt` / `expectedEndAt` | 闭关等长时事件 | `DateTime`（真实时间） |
| `birthInGameYear` | 角色出生时游戏内年序号 | `int` |

> **重要**：闭关时间锚点机制必须用真实时间（`DateTime.now()`），关闭游戏继续计时（GDD §7.3）。

---

## 2. 枚举类型

### 2.1 境界相关

```dart
/// 境界大阶（7 阶，GDD §3.1）
enum RealmTier {
  xueTu,     // 1 学徒
  sanLiu,    // 2 三流
  erLiu,     // 3 二流
  yiLiu,     // 4 一流
  jueDing,   // 5 绝顶
  zongShi,   // 6 宗师
  wuSheng,   // 7 武圣
}

/// 境界 7 层（每个大阶内部，GDD §3.1）
enum RealmLayer {
  qiMeng,     // 1 启蒙
  ruMen,      // 2 入门
  shuLian,    // 3 熟练
  jingTong,   // 4 精通
  yuanShu,    // 5 圆熟
  huaJing,    // 6 化境
  dengFeng,   // 7 登峰
}

/// 修炼度 9 层（每本心法独立累积，GDD §4.3）
/// 严格不与境界 7 层重名
enum CultivationLayer {
  chuKui,     // 1 初窥  100%
  xiaoCheng,  // 2 小成  115%
  zhongCheng, // 3 中成  130%
  daCheng,    // 4 大成  150%
  yuanMan,    // 5 圆满  175%
  dianFeng,   // 6 巅峰  200%
  tongShen,   // 7 通神  230%
  wuXia,      // 8 无瑕  260%
  jiJing,     // 9 极境  300%
}
```

### 2.2 装备 / 心法品阶

```dart
/// 装备品阶（7 阶，GDD §3.2），与境界一一对应
enum EquipmentTier {
  xunChang,    // 1 寻常货
  xiangYang,   // 2 像样货
  haoJiaHuo,   // 3 好家伙
  liQi,        // 4 利器
  zhongQi,     // 5 重器
  baoWu,       // 6 宝物
  shenWu,      // 7 神物
}

/// 心法品阶（7 阶，GDD §3.3）
enum TechniqueTier {
  ruMenGong,        // 1 入门功
  changLianGong,    // 2 常练功
  mingJiaGong,      // 3 名家功
  menPaiJueXue,     // 4 门派绝学
  jiangHuMiChuan,   // 5 江湖秘传
  shiChuanShenGong, // 6 失传神功
  chuanShuoShenGong,// 7 传说神功
}

/// 装备槽位
enum EquipmentSlot {
  weapon,       // 武器
  armor,        // 护甲
  accessory,    // 饰品
}

/// 开锋槽位类型（+10 / +15 / +19 解锁，GDD §6.5）
enum ForgingSlotType {
  attack,        // 攻击强化
  speed,         // 速度强化
  lifesteal,     // 吸血
  pierce,        // 破甲
  specialSkill,  // 专属技能（仅第三槽 +19）
}
```

### 2.3 心法 / 流派 / 招式

```dart
/// 三流派（GDD §4.4）
/// 克制关系：刚猛 → 阴柔 → 灵巧 → 刚猛
enum TechniqueSchool {
  gangMeng,  // 刚猛 → 克阴柔（震伤）
  lingQiao,  // 灵巧 → 克刚猛（暴击+20%）
  yinRou,    // 阴柔 → 克灵巧（内伤 debuff）
}

/// 心法在角色身上的定位（GDD §4.2）
enum TechniqueRole {
  main,      // 主修（每个角色 1 本）
  assist,    // 辅修（每个角色最多 3 本）
}

/// 招式类型（GDD §5.3）
enum SkillType {
  normalAttack,    // 普通攻击  倍率 500
  powerSkill,      // 强力技能  倍率 1000-3000
  ultimate,        // 大招      倍率 5000+
  jointSkill,      // 人剑合一招式（共鸣度默契阶段解锁）
}

/// 共鸣度阶段（GDD §6.4，派生值，不入库）
enum ResonanceStage {
  shengShu,         // 生疏  0~100      无加成
  chenShou,         // 趁手  100~500    +10%
  moQi,             // 默契  500~2000   +20%，解锁人剑合一
  xinJianTongLing,  // 心剑通灵 2000+  +30%，剑鸣特效
}
```

### 2.4 角色相关

```dart
/// 角色稀有度（GDD §4.1，出生时根据四属性总和决定，不可重 roll）
enum RarityTier {
  yongCai,    // 庸才   16-17  15%
  xunChang,   // 寻常   18-19  35%
  biaoZhun,   // 标准   20     25%
  ziYou,      // 资优   21-22  18%
  tianCai,    // 天才   23     5%
  jueShi,     // 绝世   24     2%
}

/// 师徒角色定位（GDD §7.1）
enum LineageRole {
  founder,        // 开派祖师（玩家本体）
  disciple,       // 弟子
  grandDisciple,  // 徒孙（绝顶境界后解锁）
}
```

### 2.5 内容 / 系统

```dart
/// 关卡类型
enum StageType {
  mainline,     // 主线（GDD §8.1）
  tower,        // 爬塔（问鼎江湖，GDD §8.2）
}

/// 闭关地图（GDD §8.3）
enum RetreatMapType {
  shanLin,         // 山林（平均产出）
  guJianZhong,     // 古剑冢（兵器掉率 +50%）
  cangJingGe,      // 藏经阁（心法领悟 +50%）
  xuanYaPuBu,      // 悬崖瀑布（内力增长 +50%）
  duanYaJueBi,     // 断崖绝壁（仅宗师以上可去）
}

/// 时辰（闭关加成用，GDD §7.3）
enum TimeOfDayPeriod {
  ziShi,           // 子时 23:00-1:00
  zhengWu,         // 正午 11:00-13:00
  other,           // 其他时段（无加成）
}

/// 背包物品类型
enum ItemType {
  moJianShi,        // 磨剑石（强化材料）
  xinXueJieJing,    // 心血结晶（强化保底，GDD §6.3）
  jingYanDan,       // 经验丹
  techniqueScroll,  // 心法秘籍
  miscMaterial,     // 杂项材料
}

/// 游戏事件类型（"昨晚发生的事"，GDD §9.2）
enum GameEventType {
  retreatCompleted,    // 闭关完成
  adventureTriggered,  // 奇遇触发
  equipmentObtained,   // 获得装备
  techniqueLearned,    // 习得心法
  skillEnlightened,    // 武学领悟
  realmBreakthrough,   // 境界突破
  resonanceUpgraded,   // 共鸣度晋升
  bossDefeated,        // 击败 Boss
  disciplePromoted,    // 弟子突破
}
```

---

## 3. 嵌入对象（@Embedded）

### 3.1 Attributes · 四项基础属性

> 嵌入在 `Character` 内。出生时按 GDD §4.1 规则生成，单项 1-10，总和 16-24，**不可重 roll**。可通过奇遇微弱后天弥补（生涯总加成上限 +5）。

| 字段 | 类型 | 可空 | 约束 | 说明 |
|------|------|------|------|------|
| constitution | int | ❌ | 1-10 | 根骨：影响血量上限 |
| enlightenment | int | ❌ | 1-10 | 悟性：影响修炼速度、武学领悟概率 |
| agility | int | ❌ | 1-10 | 身法：影响出手速度、闪避 |
| fortune | int | ❌ | 1-10 | 机缘：影响奇遇触发率、商店折扣 |

```dart
@embedded
class Attributes {
  int constitution = 5;   // 根骨
  int enlightenment = 5;  // 悟性
  int agility = 5;        // 身法
  int fortune = 5;        // 机缘

  int get total => constitution + enlightenment + agility + fortune;
}
```

**JSON 示例**：
```json
{
  "constitution": 7,
  "enlightenment": 9,
  "agility": 4,
  "fortune": 3
}
```

---

### 3.2 ForgingSlot · 开锋槽位

> 嵌入在 `Equipment.forgingSlots` 中。每件装备恒为 3 个槽，分别在强化 +10 / +15 / +19 解锁（GDD §6.5）。

| 字段 | 类型 | 可空 | 约束 | 说明 |
|------|------|------|------|------|
| slotIndex | int | ❌ | 1 / 2 / 3 | 槽位序号 |
| type | ForgingSlotType? | ✅ | — | 玩家选择的强化方向；未选为 null |
| unlocked | bool | ❌ | — | 是否已解锁 |
| bonusValue | int | ❌ | ≥0 | 数值加成（百分比或固定值，由 yaml 决定） |
| specialSkillId | String? | ✅ | — | 第 3 槽 type=specialSkill 时的招式 defId |

```dart
@embedded
class ForgingSlot {
  int slotIndex = 1;

  @Enumerated(EnumType.name)
  ForgingSlotType? type;

  bool unlocked = false;
  int bonusValue = 0;
  String? specialSkillId;
}
```

**JSON 示例**（已开第一槽，选了破甲）：
```json
{
  "slotIndex": 1,
  "type": "pierce",
  "unlocked": true,
  "bonusValue": 15,
  "specialSkillId": null
}
```

---

### 3.3 Lore · 装备典故

> 嵌入在 `Equipment.lores` 中。预设典故由 yaml 加载时初始化，延续典故由战斗事件动态追加（GDD §6.6）。

| 字段 | 类型 | 可空 | 约束 | 说明 |
|------|------|------|------|------|
| text | String | ❌ | 20-200 字 | 典故正文 |
| isPreset | bool | ❌ | — | 预设 / 动态延续 |
| addedAt | DateTime | ❌ | — | 添加时间 |
| triggerEventDesc | String? | ✅ | — | 触发事件描述（仅延续典故有） |

```dart
@embedded
class Lore {
  String text = '';
  bool isPreset = true;
  DateTime addedAt = DateTime.now();
  String? triggerEventDesc;
}
```

**JSON 示例**（延续典故）：
```json
{
  "text": "曾饮黑衣门主之血，剑身红光不褪三日。",
  "isPreset": false,
  "addedAt": "2026-05-12T22:15:00.000Z",
  "triggerEventDesc": "用此剑斩杀章 2 Boss 黑衣门主"
}
```

---

### 3.4 SkillUsageEntry · 招式使用次数

> 嵌入在 `Technique.skillUsageCount` 中，模拟 `Map<String, int>`。用于累积心法修炼度（GDD §4.3）。

| 字段 | 类型 | 可空 | 约束 | 说明 |
|------|------|------|------|------|
| skillId | String | ❌ | FK → SkillDef.id | 招式 def id |
| count | int | ❌ | ≥0 | 该招式累计使用次数 |

```dart
@embedded
class SkillUsageEntry {
  String skillId = '';
  int count = 0;
}
```

**JSON 示例**：
```json
{
  "skillId": "skill_yi_jin_jing_3",
  "count": 92
}
```

---

### 3.5 RewardEntry · 奖励条目

> 嵌入在 `RetreatSession.estimatedRewards` / `actualRewards` 中。统一表达"获得了什么"。

| 字段 | 类型 | 可空 | 约束 | 说明 |
|------|------|------|------|------|
| rewardKey | String | ❌ | — | 奖励标识：`exp` / `internal_force` / item defId / equipment defId |
| quantity | int | ❌ | ≥0 | 数量 |

```dart
@embedded
class RewardEntry {
  String rewardKey = '';
  int quantity = 0;
}
```

**JSON 示例**：
```json
{ "rewardKey": "item_mojianshi", "quantity": 6 }
```

---

### 3.6 Map 字段实现方案对照表 · [v1.1 新增]

> Isar 不原生支持 `Map<K, V>`，凡是逻辑上需要键值对的字段都需要选方案。
>
> **决策准则**：
> - 需要按 key/value 查询、排序、过滤 → 用 `List<嵌入对象>` 模拟
> - 仅整体读写、不单独查询 → 存 JSON 字符串
> - 配置类（`Def` 后缀，不入 Isar）→ 内存里直接用原生 Dart `Map`

#### 字段对照表

| 字段位置 | 实际类型 | 方案 | 理由 |
|---------|---------|------|------|
| `Technique.skillUsageCount` | `List<SkillUsageEntry>` | List 模拟 | 修炼度结算时按 `skillId` 累加；相生 buff 判定时需查"该心法最常用的招式"，必须能按 key 查询 |
| `Equipment.forgingSlots` | `List<ForgingSlot>` | List 模拟（定长 3） | 每次升级/战斗结算需按 `slotIndex` 取单槽（不是真 Map，但语义类似） |
| `Equipment.lores` | `List<Lore>` | 原生 List（非 Map） | 典故是有序列表，无键值对语义，按时间倒序展示即可 |
| `RetreatSession.estimatedRewards` | `List<RewardEntry>` | List 模拟 | 领取时需按 `rewardKey` 比对预期与实际是否一致（Demo 阶段两者一致，预留差异空间） |
| `RetreatSession.actualRewards` | `List<RewardEntry>` | List 模拟 | 同上 |
| `Character.assistTechniqueIds` | `List<int>` | 原生 `List<int>` | 纯 ID 集合，无键值对语义 |
| `Character.discipleIds` | `List<int>` | 原生 `List<int>` | 同上 |
| `Character.learnedSkillIds` | `List<String>` | 原生 `List<String>` | 同上 |
| `AdventureDef.triggerConditions` | `List<TriggerCondition>` | 不变（key/op/value 三元组） | 不是 Map 而是条件列表，AND 关系 |
| `AdventureChoice.rewardData` | `Map<String, dynamic>` | **JSON String**（仅在 Isar 持久化时；内存中保留 Map） | 配置类（不入 Isar），yaml 加载后内存里直接用 Map。如果未来需要在 `AdventureRecord` 里保留玩家选择的 rewardData 快照，则在 record 上加 `rewardDataJson: String?` 字段 |

#### 实现规约

1. **List 模拟 Map 时，嵌入对象的第一个字段固定为 key**（如 `skillId` / `slotIndex` / `rewardKey`），让代码搜索时能一眼识别意图。
2. **应用层提供工具扩展**减少调用点的样板代码：

```dart
extension MapLikeOnSkillUsage on List<SkillUsageEntry> {
  int countOf(String skillId) =>
      firstWhere((e) => e.skillId == skillId, orElse: () => SkillUsageEntry()).count;

  void increment(String skillId, [int delta = 1]) {
    final idx = indexWhere((e) => e.skillId == skillId);
    if (idx >= 0) {
      this[idx].count += delta;
    } else {
      add(SkillUsageEntry()..skillId = skillId..count = delta);
    }
  }
}

extension MapLikeOnRewards on List<RewardEntry> {
  int quantityOf(String rewardKey) =>
      firstWhere((e) => e.rewardKey == rewardKey, orElse: () => RewardEntry()).quantity;
}
```

3. **配置类的 Map 字段**（如 `AdventureChoice.rewardData`）在 yaml 加载时直接 `as Map<String, dynamic>`，不涉及 Isar 序列化。如果某个 record 需要持久化这种灵活数据，单独加 `xxxJson: String?` 字段，用 `jsonEncode/Decode` 转换。

#### 反模式（不要这样做）

```dart
// ❌ 不要在 Isar Collection 里直接写 Map（运行时报错）
@collection
class BadExample {
  Map<String, int> usageCount = {};  // Isar 不支持
}

// ❌ 不要用 JSON String 存需要查询的数据（失去查询能力）
@collection
class AlsoBad {
  String skillUsageJson = '{}';  // 想查"用得最多的招式"必须 decode 全部
}
```

---

## 4. 持久化实体（@Collection）

### 4.1 SaveData · 全局存档元数据

> **每槽单例**：每个存档槽位（slot）对应**独立的 Isar db 文件**，每个 db 内的 SaveData 只有一行（`id` 固定为 0）。多存档完全隔离，避免跨槽位数据泄露。
>
> **多存档实现机制**：见 §7 IsarSetup。简言之 —— 槽位 1 对应 `wuxia_save_slot1.isar`，槽位 2 对应 `wuxia_save_slot2.isar`，以此类推。所有 Collection 都不需要带 `slotId` 字段。

| 字段 | 类型 | 可空 | 约束 | 说明 |
|------|------|------|------|------|
| id | Id | ❌ | 固定为 0 | Isar 主键（每个槽位 db 文件内单例） |
| slotId | int | ❌ | 1 / 2 / 3 | **[v1.1 新增]** 存档槽位号，与 db 文件名 `wuxia_save_slot{slotId}` 对应；冗余存储以便存档选择界面快速识别 |
| slotName | String? | ✅ | ≤16 字 | **[v1.1 新增]** 玩家自定义存档名（如"主流派"/"灵巧 build 试验"），存档选择界面展示用 |
| saveVersion | String | ❌ | semver（如 `"0.1.0"`） | 存档版本号；major.minor.patch 用于未来 schema migration 判断（如 0.1.x → 0.2.0 触发迁移逻辑，0.1.0 → 0.1.1 直接读取） |
| createdAt | DateTime | ❌ | — | 开档时间 |
| lastSavedAt | DateTime | ❌ | — | 最后保存时间 |
| lastOnlineAt | DateTime | ❌ | — | 最后在线时间（离线挂机用，玩家关游戏时写入） |
| sectName | String? | ✅ | ≤20 字 | 门派名 |
| founderCharacterId | int? | ✅ | FK → Character.id | 开派祖师 id |
| activeCharacterIds | List\<int\> | ❌ | 长度 ≤3 | 当前出战阵容（FK） |
| totalPlaySeconds | int | ❌ | ≥0 | 累积游戏时间（秒） |
| isOnboardingCompleted | bool | ❌ | — | 是否完成新手引导 |
| highestTowerLayer | int | ❌ | 0-30 | 历史最高爬塔层 |
| towerLeaderboardSyncedAt | DateTime? | ✅ | — | 上次同步排行榜的时间 |

```dart
@collection
class SaveData {
  Id id = 0; // 每个槽位 db 文件内单例（id 固定为 0）

  // [v1.1 新增] 多存档支持：用多个 Isar db 文件实现完全隔离
  // 实际隔离机制在 IsarSetup 层（不同 db.name），这里只是冗余存储 + 玩家可读名
  int slotId = 1;
  String? slotName;

  late String saveVersion;
  late DateTime createdAt;
  late DateTime lastSavedAt;
  late DateTime lastOnlineAt;

  String? sectName;
  int? founderCharacterId;

  List<int> activeCharacterIds = [];

  int totalPlaySeconds = 0;
  bool isOnboardingCompleted = false;
  int highestTowerLayer = 0;
  DateTime? towerLeaderboardSyncedAt;
}
```

**JSON 示例**：
```json
{
  "id": 0,
  "slotId": 1,
  "slotName": "青锋门主线",
  "saveVersion": "0.1.0",
  "createdAt": "2026-05-01T10:00:00.000Z",
  "lastSavedAt": "2026-05-10T22:35:12.000Z",
  "lastOnlineAt": "2026-05-10T22:30:00.000Z",
  "sectName": "青锋门",
  "founderCharacterId": 1,
  "activeCharacterIds": [1, 2, 3],
  "totalPlaySeconds": 36540,
  "isOnboardingCompleted": true,
  "highestTowerLayer": 12,
  "towerLeaderboardSyncedAt": "2026-05-10T22:00:00.000Z"
}
```

---

### 4.2 Character · 角色

> 玩家可控角色（祖师 / 弟子 / 徒孙）。Demo 阶段最多 3 个（GDD §7.1）。

| 字段 | 类型 | 可空 | 约束 | 说明 |
|------|------|------|------|------|
| id | Id | ❌ | autoIncrement | 主键 |
| name | String | ❌ | ≤10 字 | 角色名 |
| realmTier | RealmTier | ❌ | — | 境界大阶 |
| realmLayer | RealmLayer | ❌ | — | 境界 7 层 |
| internalForce | int | ❌ | ≥0 | 当前内力 |
| internalForceMax | int | ❌ | 500-15000 | 内力上限（境界推算，GDD §5.2） |
| experience | int | ❌ | ≥0 | 当前层进度经验 |
| experienceToNextLayer | int | ❌ | >0 | 突破到下一层所需经验 |
| attributes | Attributes | ❌ | embedded | 四项基础属性 |
| rarity | RarityTier | ❌ | — | 稀有度（出生时定，不可变） |
| school | TechniqueSchool? | ✅ | — | 主修流派（跟随主修心法） |
| mainTechniqueId | int? | ✅ | FK → Technique.id | 主修心法 |
| assistTechniqueIds | List\<int\> | ❌ | ≤3 | 辅修心法 FK 列表 |
| equippedWeaponId | int? | ✅ | FK → Equipment.id | 武器 |
| equippedArmorId | int? | ✅ | FK → Equipment.id | 护甲 |
| equippedAccessoryId | int? | ✅ | FK → Equipment.id | 饰品 |
| learnedSkillIds | List\<String\> | ❌ | — | 通过武学领悟单独学到的招式 defId |
| isActive | bool | ❌ | indexed | 是否在出战阵容 |
| isInRetreat | bool | ❌ | — | 是否在闭关 |
| currentRetreatSessionId | int? | ✅ | FK → RetreatSession.id | 当前闭关会话 |
| masterId | int? | ✅ | FK → Character.id | 师父 id |
| discipleIds | List\<int\> | ❌ | — | 徒弟 id 列表 |
| lineageRole | LineageRole | ❌ | — | 师徒角色定位 |
| isFounder | bool | ❌ | — | 是否开派祖师 |
| isAlive | bool | ❌ | — | 生死（扩展用，Demo 阶段恒为 true） |
| birthInGameYear | int | ❌ | ≥0 | 出生时游戏内年序号 |
| attributeBonusFromAdventure | int | ❌ | 0-5 | 奇遇累积总加成（生涯硬上限 +5） |
| createdAt | DateTime | ❌ | — | 角色创建时间 |

```dart
@collection
class Character {
  Id id = Isar.autoIncrement;

  late String name;

  @Enumerated(EnumType.name)
  late RealmTier realmTier;

  @Enumerated(EnumType.name)
  late RealmLayer realmLayer;

  int internalForce = 0;
  int internalForceMax = 500;
  int experience = 0;
  int experienceToNextLayer = 100;

  late Attributes attributes;

  @Enumerated(EnumType.name)
  late RarityTier rarity;

  @Enumerated(EnumType.name)
  TechniqueSchool? school;

  int? mainTechniqueId;
  List<int> assistTechniqueIds = [];

  int? equippedWeaponId;
  int? equippedArmorId;
  int? equippedAccessoryId;

  List<String> learnedSkillIds = [];

  @Index()
  bool isActive = false;

  bool isInRetreat = false;
  int? currentRetreatSessionId;

  int? masterId;
  List<int> discipleIds = [];

  @Enumerated(EnumType.name)
  late LineageRole lineageRole;

  bool isFounder = false;
  bool isAlive = true;
  int birthInGameYear = 0;

  int attributeBonusFromAdventure = 0;

  late DateTime createdAt;
}
```

**JSON 示例**（祖师，二流·圆熟，主修易筋经）：
```json
{
  "id": 1,
  "name": "苏惊鸿",
  "realmTier": "erLiu",
  "realmLayer": "yuanShu",
  "internalForce": 2400,
  "internalForceMax": 3500,
  "experience": 1200,
  "experienceToNextLayer": 2000,
  "attributes": {
    "constitution": 6,
    "enlightenment": 8,
    "agility": 5,
    "fortune": 4
  },
  "rarity": "ziYou",
  "school": "gangMeng",
  "mainTechniqueId": 1,
  "assistTechniqueIds": [2, 3],
  "equippedWeaponId": 1,
  "equippedArmorId": 2,
  "equippedAccessoryId": null,
  "learnedSkillIds": ["skill_yi_jin_jing_3", "skill_listen_rain_sword"],
  "isActive": true,
  "isInRetreat": false,
  "currentRetreatSessionId": null,
  "masterId": null,
  "discipleIds": [2, 3],
  "lineageRole": "founder",
  "isFounder": true,
  "isAlive": true,
  "birthInGameYear": 0,
  "attributeBonusFromAdventure": 2,
  "createdAt": "2026-05-01T10:00:00.000Z"
}
```

---

### 4.3 Equipment · 装备实例

> 玩家持有的具体一件装备。`defId` 指向 `EquipmentDef`（yaml）。共鸣度阶段是派生值（从 `battleCount` 算），不直接存储。

| 字段 | 类型 | 可空 | 约束 | 说明 |
|------|------|------|------|------|
| id | Id | ❌ | autoIncrement | 主键 |
| defId | String | ❌ | indexed, FK → EquipmentDef.id | 装备模板 id |
| customName | String? | ✅ | ≤16 字 | 玩家改名（默认显示模板名） |
| tier | EquipmentTier | ❌ | — | 品阶（冗余，便于查询） |
| slot | EquipmentSlot | ❌ | — | 槽位 |
| school | TechniqueSchool? | ✅ | — | 流派偏向 |
| baseAttack | int | ❌ | 100-2000 | 基础攻击（生成时按 yaml 范围 roll） |
| baseHealth | int | ❌ | ≥0 | 基础血量 |
| baseSpeed | int | ❌ | ≥0 | 基础速度 |
| enhanceLevel | int | ❌ | 0-49 | 强化等级（上限 = 持有者境界总层数） |
| ownerCharacterId | int? | ✅ | indexed, FK → Character.id | 持有者；null 表示在仓库 |
| isLineageHeritage | bool | ❌ | — | 是否师承遗物（自带内力上限 +5%） |
| previousOwnerCharacterIds | List\<int\> | ❌ | — | 历任持有者（叙事用） |
| battleCount | int | ❌ | ≥0 | 使用次数（共鸣度由此派生） |
| forgingSlots | List\<ForgingSlot\> | ❌ | 长度 = 3 | 开锋槽位 |
| lores | List\<Lore\> | ❌ | — | 典故列表 |
| obtainedAt | DateTime | ❌ | — | 获得时间 |
| obtainedFrom | String | ❌ | — | 来源描述："掉落"/"商店"/"奇遇"/"师承" |

```dart
@collection
class Equipment {
  Id id = Isar.autoIncrement;

  @Index()
  late String defId;

  String? customName;

  @Enumerated(EnumType.name)
  late EquipmentTier tier;

  @Enumerated(EnumType.name)
  late EquipmentSlot slot;

  @Enumerated(EnumType.name)
  TechniqueSchool? school;

  int baseAttack = 0;
  int baseHealth = 0;
  int baseSpeed = 0;

  int enhanceLevel = 0;

  @Index()
  int? ownerCharacterId;

  bool isLineageHeritage = false;
  List<int> previousOwnerCharacterIds = [];

  int battleCount = 0;

  List<ForgingSlot> forgingSlots = [];
  List<Lore> lores = [];

  late DateTime obtainedAt;
  late String obtainedFrom;
}

/// 派生属性扩展（不入库）
extension EquipmentResonance on Equipment {
  ResonanceStage get resonanceStage {
    if (battleCount < 100) return ResonanceStage.shengShu;
    if (battleCount < 500) return ResonanceStage.chenShou;
    if (battleCount < 2000) return ResonanceStage.moQi;
    return ResonanceStage.xinJianTongLing;
  }

  /// 共鸣度数值加成（GDD §6.4）
  double get resonanceBonus {
    switch (resonanceStage) {
      case ResonanceStage.shengShu: return 1.0;
      case ResonanceStage.chenShou: return 1.10;
      case ResonanceStage.moQi: return 1.20;
      case ResonanceStage.xinJianTongLing: return 1.30;
    }
  }

  /// 师承传承时调用：保留 70% 共鸣度
  void inheritFrom(int previousOwnerId) {
    previousOwnerCharacterIds.add(previousOwnerId);
    battleCount = (battleCount * 0.7).toInt();
    isLineageHeritage = true;
  }
}
```

**JSON 示例**（一把"利器"级长剑，+12 强化，已开第一槽）：
```json
{
  "id": 1,
  "defId": "weapon_qing_feng_jian",
  "customName": null,
  "tier": "liQi",
  "slot": "weapon",
  "school": "lingQiao",
  "baseAttack": 680,
  "baseHealth": 0,
  "baseSpeed": 45,
  "enhanceLevel": 12,
  "ownerCharacterId": 1,
  "isLineageHeritage": false,
  "previousOwnerCharacterIds": [],
  "battleCount": 432,
  "forgingSlots": [
    {"slotIndex": 1, "type": "pierce", "unlocked": true, "bonusValue": 15, "specialSkillId": null},
    {"slotIndex": 2, "type": null, "unlocked": false, "bonusValue": 0, "specialSkillId": null},
    {"slotIndex": 3, "type": null, "unlocked": false, "bonusValue": 0, "specialSkillId": null}
  ],
  "lores": [
    {
      "text": "此剑出自陇西铸剑名匠欧冶之手，剑身刻有北斗七星纹。",
      "isPreset": true,
      "addedAt": "2026-05-03T14:20:00.000Z",
      "triggerEventDesc": null
    }
  ],
  "obtainedAt": "2026-05-03T14:20:00.000Z",
  "obtainedFrom": "奇遇·古剑冢"
}
```

---

### 4.4 Technique · 心法实例

> 玩家修炼的某本心法。`defId` 指向 `TechniqueDef`（yaml）。修炼度由招式使用次数累积（GDD §4.3）。

| 字段 | 类型 | 可空 | 约束 | 说明 |
|------|------|------|------|------|
| id | Id | ❌ | autoIncrement | 主键 |
| defId | String | ❌ | indexed, FK → TechniqueDef.id | 心法模板 id |
| ownerCharacterId | int | ❌ | indexed, FK → Character.id | 持有者 |
| tier | TechniqueTier | ❌ | — | 品阶（冗余） |
| school | TechniqueSchool | ❌ | — | 流派（冗余） |
| cultivationLayer | CultivationLayer | ❌ | — | 修炼度 9 层 |
| cultivationProgress | int | ❌ | ≥0 | 当前层累积（招式使用总次数） |
| cultivationProgressToNext | int | ❌ | >0 | 升下一层所需 |
| skillUsageCount | List\<SkillUsageEntry\> | ❌ | embedded | 每个招式的使用次数 |
| role | TechniqueRole | ❌ | — | 主修 / 辅修 |
| wasMainBeforeReset | bool | ❌ | — | 散功前是否为主修（散功代价判定用） |
| learnedAt | DateTime | ❌ | — | 习得时间 |

```dart
@collection
class Technique {
  Id id = Isar.autoIncrement;

  @Index()
  late String defId;

  @Index()
  late int ownerCharacterId;

  @Enumerated(EnumType.name)
  late TechniqueTier tier;

  @Enumerated(EnumType.name)
  late TechniqueSchool school;

  @Enumerated(EnumType.name)
  CultivationLayer cultivationLayer = CultivationLayer.chuKui;

  int cultivationProgress = 0;
  int cultivationProgressToNext = 100;

  List<SkillUsageEntry> skillUsageCount = [];

  @Enumerated(EnumType.name)
  late TechniqueRole role;

  bool wasMainBeforeReset = false;
  late DateTime learnedAt;
}

/// 散功调用：修为 -50%，调用方还要扣角色当前内力 -50%
extension TechniqueDispersion on Technique {
  void disperse() {
    wasMainBeforeReset = true;
    cultivationProgress = (cultivationProgress * 0.5).toInt();
    role = TechniqueRole.assist;
    // cultivationLayer 的回退由应用层根据 cultivationProgress 重新计算
  }
}
```

**JSON 示例**（少林易筋经，圆满修为）：
```json
{
  "id": 1,
  "defId": "tech_yi_jin_jing",
  "ownerCharacterId": 1,
  "tier": "menPaiJueXue",
  "school": "gangMeng",
  "cultivationLayer": "yuanMan",
  "cultivationProgress": 480,
  "cultivationProgressToNext": 800,
  "skillUsageCount": [
    {"skillId": "skill_yi_jin_jing_1", "count": 1240},
    {"skillId": "skill_yi_jin_jing_2", "count": 580},
    {"skillId": "skill_yi_jin_jing_3", "count": 92}
  ],
  "role": "main",
  "wasMainBeforeReset": false,
  "learnedAt": "2026-05-02T09:15:00.000Z"
}
```

---

### 4.5 StageProgress · 关卡进度

> 玩家关卡通关记录。每个 stageDefId 一行，更新 `clearCount` / `bestClearTimeSeconds`。

| 字段 | 类型 | 可空 | 约束 | 说明 |
|------|------|------|------|------|
| id | Id | ❌ | autoIncrement | 主键 |
| stageDefId | String | ❌ | unique indexed, FK | 关卡定义 id |
| stageType | StageType | ❌ | — | 主线 / 爬塔 |
| chapterIndex | int? | ✅ | 1-3 | 章节序号（主线用） |
| towerLayer | int? | ✅ | 1-30 | 爬塔层数（爬塔用） |
| isCleared | bool | ❌ | — | 是否通关 |
| clearCount | int | ❌ | ≥0 | 通关次数 |
| bestClearTimeSeconds | int? | ✅ | >0 | 最快通关时间 |
| firstClearedAt | DateTime? | ✅ | — | 首次通关时间 |
| lastClearedAt | DateTime? | ✅ | — | 最近通关时间 |

```dart
@collection
class StageProgress {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String stageDefId;

  @Enumerated(EnumType.name)
  late StageType stageType;

  int? chapterIndex;
  int? towerLayer;

  bool isCleared = false;
  int clearCount = 0;
  int? bestClearTimeSeconds;
  DateTime? firstClearedAt;
  DateTime? lastClearedAt;
}
```

**JSON 示例**（爬塔第 12 层，通关 3 次）：
```json
{
  "id": 12,
  "stageDefId": "tower_layer_12",
  "stageType": "tower",
  "chapterIndex": null,
  "towerLayer": 12,
  "isCleared": true,
  "clearCount": 3,
  "bestClearTimeSeconds": 87,
  "firstClearedAt": "2026-05-08T19:30:00.000Z",
  "lastClearedAt": "2026-05-10T20:15:00.000Z"
}
```

---

### 4.6 AdventureRecord · 奇遇触发记录

> 玩家触发过的奇遇历史。同一奇遇可重复触发（取决于 yaml 配置中的 `repeatable` 字段）。

| 字段 | 类型 | 可空 | 约束 | 说明 |
|------|------|------|------|------|
| id | Id | ❌ | autoIncrement | 主键 |
| adventureDefId | String | ❌ | indexed, FK | 奇遇定义 id |
| characterId | int | ❌ | indexed, FK → Character.id | 触发的角色 |
| triggeredAt | DateTime | ❌ | — | 触发时间 |
| outcomeChoice | String? | ✅ | — | 玩家选择（多选项奇遇） |
| outcomeSummary | String | ❌ | ≤200 字 | 结果摘要（事件流展示用） |
| attributeBonus | int | ❌ | 0-5 | 本次加属性点数 |
| gainedItemDefIds | List\<String\> | ❌ | — | 获得物品 |
| gainedTechniqueDefId | String? | ✅ | — | 获得心法 |
| gainedEquipmentDefId | String? | ✅ | — | 获得装备 |

```dart
@collection
class AdventureRecord {
  Id id = Isar.autoIncrement;

  @Index()
  late String adventureDefId;

  @Index()
  late int characterId;

  late DateTime triggeredAt;

  String? outcomeChoice;
  late String outcomeSummary;

  int attributeBonus = 0;
  List<String> gainedItemDefIds = [];
  String? gainedTechniqueDefId;
  String? gainedEquipmentDefId;
}
```

**JSON 示例**（竹林听雨悟剑）：
```json
{
  "id": 5,
  "adventureDefId": "adv_listen_rain_in_bamboo",
  "characterId": 1,
  "triggeredAt": "2026-05-09T03:45:00.000Z",
  "outcomeChoice": "stay_and_meditate",
  "outcomeSummary": "雨打竹叶，剑意自生。习得'听雨剑'招式。",
  "attributeBonus": 0,
  "gainedItemDefIds": [],
  "gainedTechniqueDefId": null,
  "gainedEquipmentDefId": null
}
```

---

### 4.7 RetreatSession · 闭关会话

> 时间锚点闭关（GDD §7.3）。**使用真实时间**计算（`DateTime.now()`），关闭游戏继续计时。

| 字段 | 类型 | 可空 | 约束 | 说明 |
|------|------|------|------|------|
| id | Id | ❌ | autoIncrement | 主键 |
| characterId | int | ❌ | indexed, FK → Character.id | 闭关角色 |
| mapType | RetreatMapType | ❌ | — | 闭关地图 |
| durationHours | int | ❌ | 1 / 4 / 12 | 闭关时长档位 |
| startedAt | DateTime | ❌ | — | 开始时间（真实） |
| expectedEndAt | DateTime | ❌ | — | 预计结束（startedAt + durationHours） |
| timeOfDayBonusAtStart | double | ❌ | 1.0 / 1.2 | 开始时辰加成（开始时确定） |
| solarTermBonus | double | ❌ | 1.0 / 1.3 | 节气加成 |
| isClaimed | bool | ❌ | indexed | 是否已领取 |
| claimedAt | DateTime? | ✅ | — | 领取时间 |
| estimatedRewards | List\<RewardEntry\> | ❌ | embedded | 预计奖励（开始时算） |
| actualRewards | List\<RewardEntry\> | ❌ | embedded | 实际奖励（领取后填） |

```dart
@collection
class RetreatSession {
  Id id = Isar.autoIncrement;

  @Index()
  late int characterId;

  @Enumerated(EnumType.name)
  late RetreatMapType mapType;

  int durationHours = 1;

  late DateTime startedAt;
  late DateTime expectedEndAt;

  double timeOfDayBonusAtStart = 1.0;
  double solarTermBonus = 1.0;

  @Index()
  bool isClaimed = false;
  DateTime? claimedAt;

  List<RewardEntry> estimatedRewards = [];
  List<RewardEntry> actualRewards = [];
}
```

**JSON 示例**（古剑冢闭关 4 小时，子时开始）：
```json
{
  "id": 7,
  "characterId": 2,
  "mapType": "guJianZhong",
  "durationHours": 4,
  "startedAt": "2026-05-09T23:30:00.000Z",
  "expectedEndAt": "2026-05-10T03:30:00.000Z",
  "timeOfDayBonusAtStart": 1.2,
  "solarTermBonus": 1.0,
  "isClaimed": true,
  "claimedAt": "2026-05-10T08:15:00.000Z",
  "estimatedRewards": [
    {"rewardKey": "exp", "quantity": 480},
    {"rewardKey": "item_mojianshi", "quantity": 6}
  ],
  "actualRewards": [
    {"rewardKey": "exp", "quantity": 480},
    {"rewardKey": "item_mojianshi", "quantity": 6},
    {"rewardKey": "weapon_jian_xin", "quantity": 1}
  ]
}
```

---

### 4.8 InventoryItem · 背包物品

> 堆叠式背包：每种物品类型一行，更新 `quantity`。装备和心法不入背包（各自有自己的 Collection）。

| 字段 | 类型 | 可空 | 约束 | 说明 |
|------|------|------|------|------|
| id | Id | ❌ | autoIncrement | 主键 |
| defId | String | ❌ | unique indexed | 物品定义 id（如 `item_mojianshi`） |
| itemType | ItemType | ❌ | — | 物品类别 |
| quantity | int | ❌ | ≥0 | 持有数量 |
| firstObtainedAt | DateTime | ❌ | — | 首次获得时间 |
| lastObtainedAt | DateTime | ❌ | — | 最近获得时间 |

```dart
@collection
class InventoryItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String defId;

  @Enumerated(EnumType.name)
  late ItemType itemType;

  int quantity = 0;

  late DateTime firstObtainedAt;
  late DateTime lastObtainedAt;
}
```

**JSON 示例**：
```json
{
  "id": 1,
  "defId": "item_mojianshi",
  "itemType": "moJianShi",
  "quantity": 152,
  "firstObtainedAt": "2026-05-01T10:30:00.000Z",
  "lastObtainedAt": "2026-05-10T20:15:00.000Z"
}
```

---

### 4.9 GameEvent · 游戏事件流

> 用于"昨晚发生的事"摘要展示（GDD §9.2）。所有值得告知玩家的事件按时间倒序展示。

| 字段 | 类型 | 可空 | 约束 | 说明 |
|------|------|------|------|------|
| id | Id | ❌ | autoIncrement | 主键 |
| eventType | GameEventType | ❌ | — | 事件类型 |
| title | String | ❌ | ≤20 字 | 标题 |
| summary | String | ❌ | ≤120 字 | 金色文字摘要 |
| relatedCharacterId | int? | ✅ | FK | 关联角色 |
| relatedEntityIds | List\<String\> | ❌ | — | 关联实体 def id |
| occurredAt | DateTime | ❌ | indexed | 发生时间 |
| isRead | bool | ❌ | indexed | 是否已读 |

```dart
@collection
class GameEvent {
  Id id = Isar.autoIncrement;

  @Enumerated(EnumType.name)
  late GameEventType eventType;

  late String title;
  late String summary;

  int? relatedCharacterId;
  List<String> relatedEntityIds = [];

  @Index()
  late DateTime occurredAt;

  @Index()
  bool isRead = false;
}
```

**JSON 示例**（弟子触发奇遇）：
```json
{
  "id": 23,
  "eventType": "adventureTriggered",
  "title": "竹林听雨",
  "summary": "二弟子在闭关时偶遇雨夜，剑意有所长进，习得'听雨剑'。",
  "relatedCharacterId": 3,
  "relatedEntityIds": ["adv_listen_rain_in_bamboo", "skill_listen_rain_sword"],
  "occurredAt": "2026-05-09T03:45:00.000Z",
  "isRead": false
}
```

---

### 4.10 DailyChallenge · 每日挑战次数

> 爬塔每日 5 次（GDD §8.2）。每天首次进入主界面时检查是否需要新建一行。

#### dateKey 时区规则 · [v1.1 钉死]

```dart
// ✅ 唯一正确的写法：本地时区
import 'package:intl/intl.dart';
final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

// ❌ 错误：用 UTC 会导致中国玩家上午 8:00 经历每日重置（北京 8:00 = UTC 0:00）
final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now().toUtc());
```

**规则**：

| 维度 | 规定 |
|------|------|
| **本地存储 dateKey** | 一律用 `DateTime.now()`（含本地时区偏移），玩家在自己的"自然日"内体验每日重置 |
| **排行榜上传** | 上传 Supabase 时附带 UTC 时间戳，仅供服务端做全球性活动判断；本地存储的 dateKey **永远不写 UTC** |
| **DST 处理** | 夏令时切换日同一"天"可能 23 或 25 小时，但 `yyyy-MM-dd` 字符串不受影响 |
| **跨时区出行** | 玩家从北京飞到纽约，第二天打开游戏看到的 dateKey 是纽约本地日期；这是正确行为，不需要补偿 |
| **校验时机** | 进入主界面 / 开始爬塔 / 闭关结算前各做一次 dateKey 校验，不依赖单一入口 |

**判断"是否需要新建当日记录"的标准代码**：

```dart
Future<DailyChallenge> ensureTodayChallenge(Isar isar) async {
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final existing = await isar.dailyChallenges
      .filter()
      .dateKeyEqualTo(today)
      .findFirst();
  if (existing != null) return existing;

  final fresh = DailyChallenge()
    ..dateKey = today
    ..towerAttemptsRemaining = 5
    ..towerAttemptsUsed = 0
    ..createdAt = DateTime.now();
  await isar.writeTxn(() => isar.dailyChallenges.put(fresh));
  return fresh;
}
```

| 字段 | 类型 | 可空 | 约束 | 说明 |
|------|------|------|------|------|
| id | Id | ❌ | autoIncrement | 主键 |
| dateKey | String | ❌ | unique indexed, `yyyy-MM-dd` | 日期标识（**本地时区**自然日，**禁止用 UTC**，详见上方钉死规则） |
| towerAttemptsRemaining | int | ❌ | 0-5 | 爬塔剩余次数 |
| towerAttemptsUsed | int | ❌ | ≥0 | 当日已用次数 |
| createdAt | DateTime | ❌ | — | 该日记录创建时间 |

```dart
@collection
class DailyChallenge {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String dateKey;  // [v1.1] 必须用本地时区生成，见上方规则

  int towerAttemptsRemaining = 5;
  int towerAttemptsUsed = 0;

  late DateTime createdAt;
}
```

**JSON 示例**：
```json
{
  "id": 10,
  "dateKey": "2026-05-10",
  "towerAttemptsRemaining": 2,
  "towerAttemptsUsed": 3,
  "createdAt": "2026-05-10T00:00:00.000Z"
}
```

---

## 5. 配置类（YAML 加载）

> 所有 `Def` 类**不入 Isar**，启动时由 `GameRepository` 从 `data/*.yaml` 一次性加载到内存。
>
> 这里只列字段定义；具体数值见 `numbers.yaml`（待生成）。

### 5.1 EquipmentDef · 装备定义

| 字段 | 类型 | 可空 | 说明 |
|------|------|------|------|
| id | String | ❌ | 唯一 id（如 `weapon_qing_feng_jian`） |
| name | String | ❌ | 显示名 |
| tier | EquipmentTier | ❌ | 品阶 |
| slot | EquipmentSlot | ❌ | 槽位 |
| schoolBias | TechniqueSchool? | ✅ | 流派偏向 |
| baseAttackMin | int | ❌ | 基础攻击下限（生成时 roll） |
| baseAttackMax | int | ❌ | 基础攻击上限 |
| baseHealthMin | int | ❌ | 基础血量下限 |
| baseHealthMax | int | ❌ | 基础血量上限 |
| baseSpeedMin | int | ❌ | 基础速度下限 |
| baseSpeedMax | int | ❌ | 基础速度上限 |
| presetLoreIds | List\<String\> | ❌ | 预设典故 id |
| dropSourceTags | List\<String\> | ❌ | 掉落来源标签 |
| iconPath | String | ❌ | 图标资源路径 |

```dart
class EquipmentDef {
  final String id;
  final String name;
  final EquipmentTier tier;
  final EquipmentSlot slot;
  final TechniqueSchool? schoolBias;
  final int baseAttackMin, baseAttackMax;
  final int baseHealthMin, baseHealthMax;
  final int baseSpeedMin, baseSpeedMax;
  final List<String> presetLoreIds;
  final List<String> dropSourceTags;
  final String iconPath;

  const EquipmentDef({
    required this.id,
    required this.name,
    required this.tier,
    required this.slot,
    this.schoolBias,
    required this.baseAttackMin,
    required this.baseAttackMax,
    required this.baseHealthMin,
    required this.baseHealthMax,
    required this.baseSpeedMin,
    required this.baseSpeedMax,
    required this.presetLoreIds,
    required this.dropSourceTags,
    required this.iconPath,
  });
}
```

**JSON 示例**（"利器"级长剑）：
```json
{
  "id": "weapon_qing_feng_jian",
  "name": "青锋剑",
  "tier": "liQi",
  "slot": "weapon",
  "schoolBias": "lingQiao",
  "baseAttackMin": 600,
  "baseAttackMax": 750,
  "baseHealthMin": 0,
  "baseHealthMax": 0,
  "baseSpeedMin": 40,
  "baseSpeedMax": 55,
  "presetLoreIds": ["lore_qing_feng_origin"],
  "dropSourceTags": ["chapter_3", "tower_15+"],
  "iconPath": "assets/equipment/weapon_qing_feng_jian.png"
}
```

---

### 5.2 TechniqueDef · 心法定义

| 字段 | 类型 | 可空 | 说明 |
|------|------|------|------|
| id | String | ❌ | 唯一 id |
| name | String | ❌ | 心法名 |
| tier | TechniqueTier | ❌ | 品阶 |
| school | TechniqueSchool | ❌ | 流派 |
| description | String | ❌ | 描述（来自 narratives yaml） |
| skillIds | List\<String\> | ❌ | 该心法包含的招式 def id |
| internalForceGrowthBonus | double | ❌ | 内力增长加成（每秒/挂机） |
| speedBonus | int | ❌ | 出手速度加成 |
| acquireSourceTags | List\<String\> | ❌ | 获取来源标签 |

```dart
class TechniqueDef {
  final String id;
  final String name;
  final TechniqueTier tier;
  final TechniqueSchool school;
  final String description;
  final List<String> skillIds;
  final double internalForceGrowthBonus;
  final int speedBonus;
  final List<String> acquireSourceTags;
  const TechniqueDef({...});
}
```

**JSON 示例**：
```json
{
  "id": "tech_yi_jin_jing",
  "name": "易筋经",
  "tier": "menPaiJueXue",
  "school": "gangMeng",
  "description": "少林七十二绝技之首，洗髓伐毛，固本培元。",
  "skillIds": ["skill_yi_jin_jing_1", "skill_yi_jin_jing_2", "skill_yi_jin_jing_3"],
  "internalForceGrowthBonus": 1.30,
  "speedBonus": 0,
  "acquireSourceTags": ["chapter_3_boss", "shaolin_quest"]
}
```

---

### 5.3 SkillDef · 招式定义

| 字段 | 类型 | 可空 | 说明 |
|------|------|------|------|
| id | String | ❌ | 唯一 id |
| name | String | ❌ | 招式名 |
| description | String | ❌ | 招式描述 |
| type | SkillType | ❌ | 普通攻击 / 强力技能 / 大招 / 人剑合一 |
| powerMultiplier | int | ❌ | 招式倍率（500 / 1000-3000 / 5000+） |
| internalForceCost | int | ❌ | 内力消耗 |
| cooldownTurns | int | ❌ | 冷却回合 |
| requiresManualTrigger | bool | ❌ | 是否需要手动放（大招） |
| parentTechniqueDefId | String? | ✅ | 所属心法（武学领悟独立招式可为 null） |
| visualEffect | String | ❌ | 特效标识符 |

```dart
class SkillDef {
  final String id;
  final String name;
  final String description;
  final SkillType type;
  final int powerMultiplier;
  final int internalForceCost;
  final int cooldownTurns;
  final bool requiresManualTrigger;
  final String? parentTechniqueDefId;
  final String visualEffect;
  const SkillDef({...});
}
```

**JSON 示例**：
```json
{
  "id": "skill_kang_long_you_hui",
  "name": "亢龙有悔",
  "description": "降龙十八掌第一式，掌力刚猛无俦。",
  "type": "ultimate",
  "powerMultiplier": 5500,
  "internalForceCost": 800,
  "cooldownTurns": 5,
  "requiresManualTrigger": true,
  "parentTechniqueDefId": "tech_xiang_long_shi_ba_zhang",
  "visualEffect": "dragon_palm_gold"
}
```

---

### 5.4 StageDef · 关卡定义

| 字段 | 类型 | 可空 | 说明 |
|------|------|------|------|
| id | String | ❌ | 唯一 id（如 `mainline_ch1_stage_3`、`tower_layer_15`） |
| name | String | ❌ | 显示名 |
| stageType | StageType | ❌ | 主线 / 爬塔 |
| chapterIndex | int? | ✅ | 章节序号（主线用） |
| towerLayer | int? | ✅ | 爬塔层数（爬塔用） |
| requiredRealm | RealmTier | ❌ | 进入门槛境界 |
| enemyTeam | List\<EnemyDef\> | ❌ | 敌方阵容（最多 3 个） |
| isBossStage | bool | ❌ | 是否 Boss 关 |
| narrativeId | String? | ✅ | 关联剧情文案 id（DeepSeek 维护） |
| dropEquipmentDefIds | List\<String\> | ❌ | 可掉落装备 |
| dropItemDefIds | List\<String\> | ❌ | 可掉落物品 |
| baseExpReward | int | ❌ | 基础经验 |
| difficultyMultiplier | double | ❌ | 难度系数（爬塔层层递增） |

```dart
class StageDef {
  final String id;
  final String name;
  final StageType stageType;
  final int? chapterIndex;
  final int? towerLayer;
  final RealmTier requiredRealm;
  final List<EnemyDef> enemyTeam;
  final bool isBossStage;
  final String? narrativeId;
  final List<String> dropEquipmentDefIds;
  final List<String> dropItemDefIds;
  final int baseExpReward;
  final double difficultyMultiplier;
  const StageDef({...});
}

class EnemyDef {
  final String id;
  final String name;
  final RealmTier realmTier;
  final RealmLayer realmLayer;
  final TechniqueSchool school;
  final int baseHp;
  final int baseAttack;
  final int baseSpeed;
  final List<String> skillIds;
  final String iconPath;
  const EnemyDef({...});
}
```

**JSON 示例**（爬塔第 15 层，小 Boss）：
```json
{
  "id": "tower_layer_15",
  "name": "问鼎江湖·第十五层",
  "stageType": "tower",
  "chapterIndex": null,
  "towerLayer": 15,
  "requiredRealm": "erLiu",
  "enemyTeam": [
    {
      "id": "enemy_ghost_blade",
      "name": "鬼影刀客",
      "realmTier": "erLiu",
      "realmLayer": "huaJing",
      "school": "lingQiao",
      "baseHp": 18000,
      "baseAttack": 1200,
      "baseSpeed": 180,
      "skillIds": ["skill_ghost_step", "skill_ghost_blade_ult"],
      "iconPath": "assets/enemies/ghost_blade.png"
    }
  ],
  "isBossStage": true,
  "narrativeId": "narr_tower_15_boss",
  "dropEquipmentDefIds": ["weapon_ghost_blade", "armor_dark_robe"],
  "dropItemDefIds": ["item_mojianshi", "item_xinxuejiejing"],
  "baseExpReward": 1500,
  "difficultyMultiplier": 1.85
}
```

---

### 5.5 AdventureDef · 奇遇定义

| 字段 | 类型 | 可空 | 说明 |
|------|------|------|------|
| id | String | ❌ | 唯一 id |
| name | String | ❌ | 奇遇名 |
| narrativeId | String | ❌ | 关联文案 id（DeepSeek 维护） |
| triggerConditions | List\<TriggerCondition\> | ❌ | 触发条件（AND 关系） |
| baseTriggerProbability | double | ❌ | 基础触发概率 0.0-1.0 |
| repeatable | bool | ❌ | 是否可重复触发 |
| choices | List\<AdventureChoice\> | ❌ | 玩家选项（≥1） |
| enemyTeamKey | String? | ✅ | **[v1.1 新增]** 战斗向奇遇关联敌方阵容配置 id；Demo 阶段所有奇遇填 `null`（纯叙事 / 选项类奇遇）。未来支持"奇遇里有 Boss 战"时只填此字段 + 加战斗启动逻辑，**不动 schema** |

```dart
class AdventureDef {
  final String id;
  final String name;
  final String narrativeId;
  final List<TriggerCondition> triggerConditions;
  final double baseTriggerProbability;
  final bool repeatable;
  final List<AdventureChoice> choices;
  final String? enemyTeamKey;  // [v1.1] 战斗向奇遇扩展位，Demo 全填 null
  const AdventureDef({...});
}

class TriggerCondition {
  final String key;     // "school" / "retreat_map" / "kill_count" / "weather" ...
  final String op;      // "==" / ">=" / "in" ...
  final dynamic value;  // 比较值
  const TriggerCondition({...});
}

class AdventureChoice {
  final String id;             // "stay_and_meditate"
  final String label;          // "留下静修"
  final AdventureRewardType rewardType;
  final Map<String, dynamic> rewardData;  // 灵活的奖励配置（内存中保留 Map，见 §3.6）
  const AdventureChoice({...});
}
```

**JSON 示例**（竹林听雨悟剑，纯叙事奇遇）：
```json
{
  "id": "adv_listen_rain_in_bamboo",
  "name": "竹林听雨",
  "narrativeId": "narr_adv_listen_rain",
  "triggerConditions": [
    {"key": "school", "op": "==", "value": "lingQiao"},
    {"key": "retreat_map", "op": "==", "value": "shanLin"},
    {"key": "weather", "op": "==", "value": "rain"},
    {"key": "killed_swordsman_count", "op": ">=", "value": 100}
  ],
  "baseTriggerProbability": 0.15,
  "repeatable": false,
  "choices": [
    {
      "id": "stay_and_meditate",
      "label": "留下静修",
      "rewardType": "skill",
      "rewardData": {"skillId": "skill_listen_rain_sword"}
    },
    {
      "id": "leave_immediately",
      "label": "起身离去",
      "rewardType": "story",
      "rewardData": {}
    }
  ],
  "enemyTeamKey": null
}
```

**未来扩展示例**（战斗向奇遇，Demo 不实现，仅展示 schema 兼容性）：
```json
{
  "id": "adv_ambushed_by_thieves",
  "name": "山道遇贼",
  "narrativeId": "narr_adv_thieves_ambush",
  "triggerConditions": [
    {"key": "retreat_map", "op": "==", "value": "shanLin"},
    {"key": "fortune", "op": "<", "value": 5}
  ],
  "baseTriggerProbability": 0.08,
  "repeatable": true,
  "choices": [
    {"id": "fight", "label": "出手退敌", "rewardType": "item", "rewardData": {}}
  ],
  "enemyTeamKey": "enemy_team_mountain_thieves"
}
```

---

### 5.6 SynergyDef · 心法相生组合

> 主修 + 辅修达到特定组合时触发的隐藏 buff（GDD §4.5）。Demo 阶段至少 5 个。

| 字段 | 类型 | 可空 | 说明 |
|------|------|------|------|
| id | String | ❌ | 唯一 id |
| name | String | ❌ | 组合名（如"阴阳调和"） |
| requiredMainTechniqueDefId | String | ❌ | 必需的主修心法 |
| requiredAssistTechniqueDefIds | List\<String\> | ❌ | 必需的辅修心法（任意一项满足即可） |
| effectType | String | ❌ | 效果类型：`all_attr_pct` / `crit_dmg_pct` / `reflect_pct` / `unlock_skill_crit` |
| effectValue | double | ❌ | 效果数值 |
| narrativeId | String? | ✅ | 触发时叙事文案 |

```dart
class SynergyDef {
  final String id;
  final String name;
  final String requiredMainTechniqueDefId;
  final List<String> requiredAssistTechniqueDefIds;
  final String effectType;
  final double effectValue;
  final String? narrativeId;
  const SynergyDef({...});
}
```

**JSON 示例**（阴阳调和）：
```json
{
  "id": "syn_yin_yang_he",
  "name": "阴阳调和",
  "requiredMainTechniqueDefId": "tech_jiu_yang_shen_gong",
  "requiredAssistTechniqueDefIds": ["tech_jiu_yin_zhen_jing"],
  "effectType": "all_attr_pct",
  "effectValue": 0.20,
  "narrativeId": "narr_syn_yin_yang_he"
}
```

---

### 5.7 RetreatMapDef · 闭关地图定义

| 字段 | 类型 | 可空 | 说明 |
|------|------|------|------|
| id | String | ❌ | 唯一 id |
| mapType | RetreatMapType | ❌ | 地图类型 |
| name | String | ❌ | 显示名 |
| description | String | ❌ | 描述 |
| requiredRealm | RealmTier | ❌ | 进入门槛境界（断崖绝壁 = zongShi） |
| expRatePerHour | double | ❌ | 经验产出率（每小时） |
| moJianShiRatePerHour | double | ❌ | 磨剑石产出率 |
| equipmentDropRateBonus | double | ❌ | 装备掉率加成（古剑冢 +50%） |
| techniqueLearnRateBonus | double | ❌ | 心法领悟率加成（藏经阁 +50%） |
| internalForceGrowthBonus | double | ❌ | 内力增长加成（悬崖瀑布 +50%） |
| iconPath | String | ❌ | 图标 |

```dart
class RetreatMapDef {
  final String id;
  final RetreatMapType mapType;
  final String name;
  final String description;
  final RealmTier requiredRealm;
  final double expRatePerHour;
  final double moJianShiRatePerHour;
  final double equipmentDropRateBonus;
  final double techniqueLearnRateBonus;
  final double internalForceGrowthBonus;
  final String iconPath;
  const RetreatMapDef({...});
}
```

**JSON 示例**（古剑冢）：
```json
{
  "id": "retreat_gu_jian_zhong",
  "mapType": "guJianZhong",
  "name": "古剑冢",
  "description": "千年剑冢，剑意纵横。利兵随处可拾。",
  "requiredRealm": "sanLiu",
  "expRatePerHour": 100.0,
  "moJianShiRatePerHour": 1.0,
  "equipmentDropRateBonus": 0.50,
  "techniqueLearnRateBonus": 0.0,
  "internalForceGrowthBonus": 0.0,
  "iconPath": "assets/maps/gu_jian_zhong.png"
}
```

---

### 5.8 RealmDef · 境界配置

> 49 级境界对应的内力上限、突破经验等数值表。具体数值见 `numbers.yaml`。

| 字段 | 类型 | 可空 | 说明 |
|------|------|------|------|
| tier | RealmTier | ❌ | 大阶 |
| layer | RealmLayer | ❌ | 7 层 |
| absoluteLevel | int | ❌ | 总层数 1-49（用于强化上限计算） |
| internalForceMax | int | ❌ | 该层内力上限 |
| experienceToNext | int | ❌ | 突破到下一层所需经验 |
| equipmentTierCap | EquipmentTier | ❌ | 可装备品阶上限 |
| techniqueTierCap | TechniqueTier | ❌ | 可修心法品阶上限 |

```dart
class RealmDef {
  final RealmTier tier;
  final RealmLayer layer;
  final int absoluteLevel;
  final int internalForceMax;
  final int experienceToNext;
  final EquipmentTier equipmentTierCap;
  final TechniqueTier techniqueTierCap;
  const RealmDef({...});
}
```

---

## 6. 实体关系图

```
┌──────────────────────────────────────────────────────────────────┐
│                       Isar 持久化层                                │
└──────────────────────────────────────────────────────────────────┘

                     ┌──────────────┐
                     │   SaveData   │ (单例 id=0)
                     └──────┬───────┘
                            │ founderCharacterId
                            │ activeCharacterIds[]
                            ▼
                     ┌──────────────┐
            ┌────────│  Character   │────────┐
            │        └──────┬───────┘        │
            │ master/        │ equipped       │ main/assist
            │ disciple       │                │
            ▼                ▼                ▼
       (self ref)    ┌─────────────┐   ┌─────────────┐
                     │  Equipment  │   │  Technique  │
                     └─────────────┘   └─────────────┘
                          │                  │
                          │ defId            │ defId
                          ▼                  ▼

┌──────────────────────────────────────────────────────────────────┐
│                    YAML 配置层（内存）                              │
└──────────────────────────────────────────────────────────────────┘

  EquipmentDef    TechniqueDef ──skillIds──► SkillDef
                       │                          │
                       │                          │ parentTechniqueDefId
                       ▼                          │
                  SynergyDef                  (back ref)

  StageDef ──enemyTeam──► EnemyDef
       │
       ▼
  StageProgress (Isar)

  AdventureDef ──triggers──► (生成) ──► AdventureRecord (Isar)

  RetreatMapDef ──► (闭关时引用) ──► RetreatSession (Isar)

  RealmDef (49 行) ──► (升级查表) ──► Character.realmTier/realmLayer
```

**FK 一致性维护责任**：

| 关系 | 维护方 |
|------|--------|
| `Character.equippedXxxId ↔ Equipment.ownerCharacterId` | 应用层（穿/脱装备时双向更新） |
| `Character.mainTechniqueId ↔ Technique.role == main` | 应用层（散功 / 切换主修时同步） |
| `Character.discipleIds ↔ Character.masterId` | 应用层（收徒时双向写入） |
| `RetreatSession.characterId == Character.currentRetreatSessionId.characterId` | 应用层（开始 / 结束闭关时同步 isInRetreat） |
| `SaveData.activeCharacterIds == Character.isActive == true` | 应用层（切换阵容时同步） |

---

## 7. Isar 初始化样板代码

> **[v1.1 重构]** 多存档架构：每个存档槽位对应**独立的 Isar db 文件**，所有 Collection 不需要带 `slotId` 字段。槽位 1 对应 `wuxia_save_slot1.isar`，槽位 2 对应 `wuxia_save_slot2.isar`，以此类推（最多 3 个槽位）。
>
> **设计选择理由**：相比"所有 Collection 加 slotId 外键 + where 过滤"的方案，多 db 文件方案：
> - 完全杜绝跨存档数据泄露（漏写一个 where 就能读到别人的存档，是经典 bug）
> - 备份 / 导出 / 删除一个存档 = 操作一个文件
> - 所有 Collection schema 不需要变化
> - 代价：切换存档需要 close + open（用户感知约 100ms，存档选择界面进入时操作，无所谓）

### 7.1 标准实现

```dart
// lib/data/isar_setup.dart

import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'models/save_data.dart';
import 'models/character.dart';
import 'models/equipment.dart';
import 'models/technique.dart';
import 'models/stage_progress.dart';
import 'models/adventure_record.dart';
import 'models/retreat_session.dart';
import 'models/inventory_item.dart';
import 'models/game_event.dart';
import 'models/daily_challenge.dart';

/// 所有持久化 schema 的统一清单（多处使用，集中维护）
const _allSchemas = [
  SaveDataSchema,
  CharacterSchema,
  EquipmentSchema,
  TechniqueSchema,
  StageProgressSchema,
  AdventureRecordSchema,
  RetreatSessionSchema,
  InventoryItemSchema,
  GameEventSchema,
  DailyChallengeSchema,
];

class IsarSetup {
  static late Isar instance;
  static int currentSlotId = 1;  // [v1.1] 当前打开的存档槽位

  /// 多存档隔离：每个槽位对应独立 db 文件
  /// - 槽位 1 → ~/Documents/wuxia_save_slot1.isar
  /// - 槽位 2 → ~/Documents/wuxia_save_slot2.isar
  /// - 槽位 3 → ~/Documents/wuxia_save_slot3.isar
  static Future<void> init({int slotId = 1}) async {
    assert(slotId >= 1 && slotId <= 3, 'slotId 必须是 1/2/3');

    final dir = await getApplicationDocumentsDirectory();
    instance = await Isar.open(
      _allSchemas,
      directory: dir.path,
      name: 'wuxia_save_slot$slotId',  // [v1.1] 槽位隔离的关键
      inspector: true, // Debug 模式可在浏览器查看数据
    );
    currentSlotId = slotId;
  }

  /// [v1.1] 切换存档槽位：先关闭当前 db，再用新 slotId 打开
  /// 用于"主菜单 → 存档选择 → 进入游戏"流程
  static Future<void> switchSlot(int newSlotId) async {
    if (newSlotId == currentSlotId) return;
    await close();
    await init(slotId: newSlotId);
  }

  /// [v1.1] 列出所有存档槽位的元信息（用于存档选择界面）
  /// 实现策略：依次临时打开每个槽位 db，读 SaveData.id=0，立即关闭
  static Future<List<SlotMetadata>> listAllSlots() async {
    final dir = await getApplicationDocumentsDirectory();
    final result = <SlotMetadata>[];

    for (int i = 1; i <= 3; i++) {
      final file = File('${dir.path}/wuxia_save_slot$i.isar');
      if (!await file.exists()) {
        result.add(SlotMetadata.empty(i));
        continue;
      }

      // 临时打开读取后立即关闭，避免长时间占用
      final isar = await Isar.open(
        _allSchemas,
        directory: dir.path,
        name: 'wuxia_save_slot$i',
      );
      final saveData = await isar.saveDatas.get(0);
      await isar.close();

      if (saveData != null) {
        result.add(SlotMetadata(
          slotId: i,
          slotName: saveData.slotName,
          sectName: saveData.sectName,
          founderName: null,  // 需要的话再查 Character 表
          lastSavedAt: saveData.lastSavedAt,
          totalPlaySeconds: saveData.totalPlaySeconds,
          highestTowerLayer: saveData.highestTowerLayer,
        ));
      } else {
        result.add(SlotMetadata.empty(i));
      }
    }
    return result;
  }

  /// [v1.1] 删除指定槽位的存档（删除整个 db 文件）
  /// 危险操作，UI 层必须二次确认
  static Future<void> deleteSlot(int slotId) async {
    assert(slotId >= 1 && slotId <= 3);
    if (slotId == currentSlotId) {
      throw StateError('不能删除当前正在使用的存档槽位 $slotId');
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/wuxia_save_slot$slotId.isar');
    if (await file.exists()) await file.delete();
    // Isar 还会创建 .lock 文件，一并删除
    final lockFile = File('${dir.path}/wuxia_save_slot$slotId.isar.lock');
    if (await lockFile.exists()) await lockFile.delete();
  }

  static Future<void> close() async {
    await instance.close();
  }
}

/// [v1.1] 存档槽位元信息（用于存档选择界面展示）
class SlotMetadata {
  final int slotId;
  final bool isEmpty;
  final String? slotName;
  final String? sectName;
  final String? founderName;
  final DateTime? lastSavedAt;
  final int totalPlaySeconds;
  final int highestTowerLayer;

  const SlotMetadata({
    required this.slotId,
    this.slotName,
    this.sectName,
    this.founderName,
    this.lastSavedAt,
    this.totalPlaySeconds = 0,
    this.highestTowerLayer = 0,
  }) : isEmpty = false;

  const SlotMetadata.empty(this.slotId)
      : isEmpty = true,
        slotName = null,
        sectName = null,
        founderName = null,
        lastSavedAt = null,
        totalPlaySeconds = 0,
        highestTowerLayer = 0;
}
```

### 7.2 启动流程

```dart
// main.dart 启动顺序
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 加载所有 yaml 配置到内存（不依赖 Isar）
  await GameRepository.loadAllDefs();

  // 2. 列出存档槽位 → 让玩家选择 → 打开对应槽位
  //    （主菜单 UI 调用 IsarSetup.listAllSlots() 然后 init(slotId)）
  //    新开档时 init(slotId: 1) 即可

  runApp(const WuxiaApp());
}
```

### 7.3 目录结构建议

```
lib/
├── data/
│   ├── isar_setup.dart
│   ├── models/                # 所有 @Collection / @Embedded
│   │   ├── enums.dart         # 所有枚举
│   │   ├── attributes.dart
│   │   ├── forging_slot.dart
│   │   ├── lore.dart
│   │   ├── reward_entry.dart
│   │   ├── skill_usage_entry.dart
│   │   ├── save_data.dart
│   │   ├── character.dart
│   │   ├── equipment.dart
│   │   ├── technique.dart
│   │   ├── stage_progress.dart
│   │   ├── adventure_record.dart
│   │   ├── retreat_session.dart
│   │   ├── inventory_item.dart
│   │   ├── game_event.dart
│   │   └── daily_challenge.dart
│   ├── defs/                  # 所有配置类（不带 @Collection）
│   │   ├── equipment_def.dart
│   │   ├── technique_def.dart
│   │   ├── skill_def.dart
│   │   ├── stage_def.dart
│   │   ├── adventure_def.dart
│   │   ├── synergy_def.dart
│   │   ├── retreat_map_def.dart
│   │   └── realm_def.dart
│   └── repositories/          # GameRepository（加载 yaml + 桥接 Isar）
└── ...
```

---

## 附录：与 GDD 数值红线的对应

下表帮助实现时校验 model 字段是否覆盖了 GDD §5.2 的数值红线：

| GDD 数值 | 对应字段 | 上限校验位置 |
|---------|---------|--------------|
| 普通伤害 2,000-8,000 | 战斗结算（不入库） | 战斗 Service |
| 玩家血量 5,000-20,000 | 派生：`Character.attributes.constitution × 500 + ...` | 战斗 Service |
| Boss 血量 50,000+ | `EnemyDef.baseHp` | yaml 加载校验 |
| 内力 500-15,000 | `Character.internalForceMax` | yaml 加载校验 + Realm 推算 |
| 装备攻击 100-2,000 | `Equipment.baseAttack` & `EquipmentDef.baseAttackMax` | yaml 加载校验 |
| 强化等级 0-49 | `Equipment.enhanceLevel` | 应用层校验（≤ 持有者境界总层数） |
| 修炼度加成 1.0-3.0 | 派生：`CultivationLayer` 查表 | numbers.yaml 配置 |
| 流派克制 0.75/1.0/1.25 | 战斗结算（不入库） | numbers.yaml 配置 |
| 共鸣度 +10/+20/+30% | 派生：`Equipment.resonanceBonus` | 见 §4.3 扩展方法 |

---

**文档结束。**

下一份文档：`numbers.yaml`（待生成 · 数值配置）
