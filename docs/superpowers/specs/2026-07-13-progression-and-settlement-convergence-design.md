# 成长与结算收口设计

**日期：** 2026-07-13
**状态：** 已确认
**范围：** 门派名称接线、境界经验阈值单一真相源、主线与爬塔公共战后结算

## 1. 背景

本轮复检确认三项需要优先治理的问题：

1. `data/factions.yaml` 已配置中文门派名，但加载层只保留 `id → alignment`，声望页面向玩家显示内部 ID。
2. `Character.experienceToNextLayer` 与 `RealmDef.experienceToNext` 重复保存同一派生信息，旧存档或配置调整后可能产生漂移。
3. 主线与爬塔分别实现经验、心魔升层锁、突破事件、共鸣事件和英雄镜头等战后流程，后续修改容易只落一边。

本批采用渐进式统一，不删除 Isar 兼容字段，不扩大到群战、轻功战、资源总览或死配置清理。

## 2. 目标与非目标

### 2.1 目标

- 声望页面显示配置中的中文门派名，未知门派安全回退到原始 ID。
- 境界升级阈值的生产单一真相源为 `RealmDef.experienceToNext`。
- `Character.experienceToNextLayer` 仅保留为旧存档兼容镜像，不再驱动生产判断。
- 主线与爬塔复用同一套角色成长和公共事件结算逻辑。
- 保持现有奖励语义、事务原子性、Lv1～Lv490 展示、心魔锁和三系锁死不变。

### 2.2 非目标

- 不删除 `Character.level`、`Character.levelExp` 或 `experienceToNextLayer` 的 Isar 字段。
- 不提升存档版本，不新增破坏性迁移。
- 不调整境界经验数值、商店价格公式或战斗掉落概率。
- 不统一主线与爬塔的首通、掉落、秘籍、排行榜和进度规则。
- 不把群战、轻功战或扫荡接入新结算服务。
- 不合并“资源总览”与“装备仓库”，不清理其他死配置和废弃文案。

## 3. 方案选择

采用“渐进式统一”方案：建立完整门派定义；将经验阈值改为实时派生、存档字段保留为兼容镜像；抽取公共战后成长服务，但保留玩法策略差异。

未采用最小修补，因为它仍会留下重复状态和两套结算主体。未采用一次性重构，因为删除 Isar 字段并统一全部战斗模式会显著放大存档和回归风险。

## 4. 门派信息设计

### 4.1 数据模型

新增 `FactionDef`，字段为：

- `String id`
- `String name`
- `String alignment`
- `List<String> npcIds`

`FactionDef.fromYaml` 负责解析 `factions.yaml`。加载时校验：

- `id`、`name` 非空；
- `alignment` 仅允许 `orthodox`、`neutral`、`evil`；
- 门派 ID 不重复；
- `npc_ids` 缺失时按空列表处理。

### 4.2 Repository 接口

`GameRepository` 保存 `Map<String, FactionDef> factionDefs`，并从该映射派生现有 `Map<String, String> factionAlignments`。现有阵营计算继续使用 `factionAlignments`，避免扩大本批改动。

提供按 ID 查询显示名的窄接口。查询不到时返回原始 ID，不因坏存档或未来配置差异导致声望页面崩溃。

### 4.3 UI 行为

`ReputationPanelScreen` 不再直接渲染 `Reputation.factionId`，而是查询 `FactionDef.name`。内部 ID 只作为未知配置时的兜底。

本批不新增门派详情页，不展示 `npcIds`；该字段只是从“被加载层丢弃”改为正式模型的一部分，为后续 NPC 归属留出稳定接口。

## 5. 境界经验阈值设计

### 5.1 单一真相源

角色当前升级阈值统一按以下路径读取：

```text
Character.realmTier + Character.realmLayer
                    ↓
GameRepository.getRealm(tier, layer)
                    ↓
RealmDef.experienceToNext
```

所有界面、状态摘要、心魔判断和商店定价不得直接读取 `Character.experienceToNextLayer`。

### 5.2 兼容镜像

`experienceToNextLayer` 继续保留在 `Character` 中，原因是直接删除会改变 Isar schema。它的职责限定为：

- 读取旧存档时保持结构兼容；
- 角色创建或经验结算结束后写入当前正确阈值，便于未来迁移审计；
- 不作为任何生产判断的权威输入。

字段注释必须明确“legacy compatibility mirror”，避免后续代码重新依赖它。

### 5.3 升级服务

`CharacterAdvancementService.applyExperience` 每轮升级使用当前 `RealmDef.experienceToNext` 的局部值完成扣减和循环，不以角色镜像字段作为循环条件。成功停在最终境界后，将当前 `RealmDef.experienceToNext` 同步回镜像字段。

心魔锁拦截时：

- 不消费不足以完成合法升级的经验；
- 保留溢出经验；
- 镜像同步为当前境界阈值；
- Lv 展示不得超过 490。

### 5.4 生产消费点

本批替换以下直接读取：

- 角色面板经验进度；
- 心魔入口“经验已满”判断；
- 主菜单突破状态摘要；
- 祖师商店动态价格阈值；
- 其他经检索确认的生产调用方。

新增源码契约测试：除 `Character`、迁移/种子兼容代码和 `CharacterAdvancementService` 外，生产文件不得出现 `.experienceToNextLayer` 读取。

## 6. 公共战后结算设计

### 6.1 边界

新增公共成长结算模块，建议命名为 `CombatProgressionSettlementService`。它只处理主线与爬塔真实相同的行为：

- 根据玩法传入的经验发放条件为参战角色结算经验；
- 使用已通心魔关集合执行升层锁；
- 生成 `AdvancementEntry`；
- 记录境界突破事件；
- 记录共鸣晋阶事件和展示通知；
- 在祖师突破时推进现有教程；
- 为调用方返回公共结算结果。

### 6.2 保留在玩法外层的行为

以下差异不得塞入公共服务：

- 主线重复挑战按现规则发经验，爬塔仅首通发经验；
- 主线秘籍首通门控和固定掉落；
- 爬塔 `rollTowerRewards` 与 `_persistDrops`；
- 主线 `MainlineProgress`、爬塔 `TowerProgress`；
- 排行榜同步；
- 玩法专属剧情和胜利界面；
- Boss 名称、关卡 ID 的玩法格式。

调用方应先算出“本次是否发经验、发多少经验、是否首通”等策略结果，再交给公共服务，不让服务反查玩法状态。

### 6.3 输入与输出

公共服务输入保持窄而明确，包含：

- Isar 实例或当前事务所需依赖；
- 参战角色、心法和装备集合；
- 本次实际经验奖励；
- 已通心魔关 ID 集合；
- 祖师角色 ID；
- 共鸣晋阶装备 ID；
- 事件来源所需的最小上下文。

公共返回对象至少包含：

- `List<AdvancementEntry> advancements`
- `List<ResonanceUpgradeNotice> resonanceUpgrades`

英雄镜头若只依赖战斗最终状态和角色，应继续由纯函数派生；调用位置可以统一，但不将表现逻辑写进事务服务。

### 6.4 事务与错误处理

- 公共服务不自行开启嵌套 `writeTxn`。
- 主线和爬塔仍由各自外层持有一个写事务。
- 角色、心法、装备和公共事件必须在同一事务内写入。
- 结算错误向上抛出，禁止吞掉后形成半结算。
- 排行榜、图鉴等非关键外部同步继续在核心事务之外降级处理。
- 未知门派名属于显示降级，不得影响声望数据读写。

## 7. 测试设计

### 7.1 门派

- 完整解析六个生产门派及中文名。
- 非法立场、重复 ID、空名称加载失败。
- 声望页面显示中文名。
- 未知门派回退显示原始 ID。
- 现有 `rivalFactionIds` 结果不变。

### 7.2 经验阈值

- 人为写入错误镜像值后，角色面板、心魔判断、主菜单和商店仍使用 `RealmDef`。
- `applyExperience` 在错误镜像下仍按真实阈值升级。
- 心魔锁保留溢出经验并停在正确层级。
- 终局只到 Lv490，不进入第50层。
- 源码契约禁止新的生产读取方。

### 7.3 公共结算

- 主线胜利按当前规则发经验，重复挑战行为不变。
- 爬塔仅首通发经验，重打不发经验。
- 三名角色同时升级均产生记录。
- 心魔锁对两种玩法一致生效。
- 仅祖师突破推进教程。
- 共鸣晋阶和 Boss 首胜事件不重复。
- 事务抛错时角色与事件均不落库。
- 主线秘籍门控和爬塔掉落保持现状。

## 8. 实施切片与提交边界

1. `feat: load complete faction definitions`
2. `fix: render localized faction names in reputation panel`
3. `refactor: derive progression threshold from realm definitions`
4. `refactor: extract shared combat progression settlement`
5. `test: add cross-mode settlement contracts`

每个切片必须先增加失败测试，再做最小实现，并在提交前运行相关测试。第五个提交用于跨模块契约和最终收口，不替代前四个切片各自的单元测试。

## 9. 完成标准

- `flutter format --set-exit-if-changed .` 通过。
- `flutter analyze --no-pub` 为 0 issue。
- 门派、成长、主线、爬塔定向测试全部通过。
- `flutter test --no-pub` 全量通过。
- `flutter build macos --debug` 通过。
- 工作区无未提交文件。
- 生产奖励语义、存档版本、数值配置和 Lv1～Lv490 展示均未改变。
