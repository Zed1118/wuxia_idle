# F1 里程碑装备授予 — 设计 spec

> 2026-06-23 · 第五阶段·掉落优化 子系统 A 审计溢出修复（最高价值 content bug）
> 来源：`docs/audit/drop_consistency_2026-06-23.md` F1 + F6
> 方案：A（实装 3 个里程碑授予通道）· 升档 xhigh（跨 ascension/mass_battle/inner_demon + 动 saveVer）

## 问题

3 件 special 装备有完整定义+美术+典故 lore，`dropSourceTags` 声明走里程碑授予通道，但通道从未实装 → 玩家**永远拿不到**：

| 装备 | tier | dropSourceTags | equipment.yaml |
|------|------|----------------|----------------|
| 无名剑 weapon_special_wu_ming_jian | baoWu(宝物) | ascension_reward | :1309 |
| 心魔珠 accessory_special_xin_mo_zhu | zhongQi(重器) | inner_demon_reward | :1327 |
| 百战甲 armor_special_bai_zhan_jia | liQi(利器) | mass_battle_merit | :1343 |

亲核证实：`dropSourceTags` 全 lib 0 消费（仅 equipment_def.dart:19/58/84 解析）；3 件 defId 全仓无任何授予逻辑。

## 目标

实装 3 个里程碑授予通道，每件作**首通对应里程碑的一次性保底奖励**（必得、非 RNG、重打不重发）。
副产：`dropSourceTags` 从死字段变 live 消费源（解决 F6）。

## 设计

### 核心服务 MilestoneEquipmentGrantService

新建 `lib/features/equipment/application/milestone_equipment_grant_service.dart`，沿现有 service 体例（注入 isar，caller 持锁 or 内部 writeTxn）。

```
grantForTag(String tag) → List<grantedDefId>
  1. 扫 GameRepository 全 equipment def，筛 dropSourceTags.contains(tag)
  2. 逐件：若 SaveData.grantedMilestoneEquipmentIds 已含该 defId → skip（幂等）
  3. 否则 EquipmentFactory.fromDef 造实例（ownerCharacterId=null=入背包）
     + isar.equipments.put + 把 defId 加入 grantedMilestoneEquipmentIds
  4. 事务内重读 save 防 stale（沿 disciple_join_service:95 体例）
```

- **dropSourceTags 成为真理之源**：未来加里程碑装备只打 tag，零代码改动。
- obtainedFrom 用对应里程碑的来历串（UiStrings 新增 3 条，走集中 sink）。

### 三个授予触发点（终点关）

| tag | 触发 | 接线位置 |
|-----|------|----------|
| mass_battle_merit | 首通 stage_mass_battle_05（群战 5 关全清） | 群战胜利结算路径（recordClear 后判 isFirstClear && stageId==终点） |
| inner_demon_reward | 首通 stage_inner_demon_07（降服全部心魔） | 心魔胜利结算路径，同上 |
| ascension_reward | performAscend（武圣飞升终局） | ascend_service.performAscend 内直接 grantForTag |

- 群战/心魔走「关卡 stageId→tag」映射；飞升是终局事件非关卡，直接在 performAscend 调用。
- tier 可用性已核：群战在宗师后解锁→利器可用；心魔武圣突破段→重器可用；飞升武圣→宝物可用。均不撞 §5.3 锁死。
- **balance nit（记录不修）**：百战甲利器对宗师玩家偏弱，属数值观感非 bug，F1 不调数值。

### 配置层

`data/numbers.yaml` 新增（stageId→tag 映射，不硬编码）：
```yaml
milestone_equipment_grants:
  stage_mass_battle_05: mass_battle_merit
  stage_inner_demon_07: inner_demon_reward
```
解析进 NumbersConfig（沿现有 config 体例）。飞升 tag 'ascension_reward' 在 performAscend 内常量引用（终局单点，非映射表）。

### 持久化 / 迁移

- `SaveData.grantedMilestoneEquipmentIds: List<String> = []`（沿 triggeredDiscipleJoinStageIds 体例，Isar List 当 set）。
- saveVer `0.27.0 → 0.28.0`（isar_setup.dart:136）。迁移：`_compareVersion(from, '0.28.0') < 0` → init 空集（幂等，沿 :306 体例）。
- 全仓同步 saveVer 硬编码断言（grep 0.27.0 测试断言全改，禁 | head 截断，守 feedback_version_bump_test_assert_sync）。

## 测试（TDD）

1. **service 单测**：grantForTag 授予一次 → 背包多一件(owner=null)；二次调用幂等 no-op；正确按 dropSourceTags 筛；未知 tag → 空。
2. **迁移测**：老档(0.27.0)升 0.28.0 → grantedMilestoneEquipmentIds 初始化为空。
3. **集成测**：首通 stage_mass_battle_05 → 背包得百战甲，重打不重发；inner_demon_07 → 心魔珠；performAscend → 无名剑。
4. 全量 analyze 0 + 全量测零回归（基线本会话实测）。

## 范围边界（F1 不做）

- 不碰 F2-F8（独立项，后续批）。
- 不调 3 件数值/lore/美术。
- 不加授予专属 UI 特效（走背包静默入袋；授予提示/动画若要 → 归 D 体验批）。
- 不实装其他 dropSourceTags 通道以外的获取方式。

## 验收

- analyze 0；全量测零回归 + 新增测全绿。
- 3 件装备各有可达获取路径（集成测证实）。
- dropSourceTags 不再是死字段（F6 闭环）。
