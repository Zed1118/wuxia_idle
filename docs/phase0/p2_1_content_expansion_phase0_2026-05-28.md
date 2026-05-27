# P2.1 内容扩充 Phase 0 Reality Check

> 2026-05-28 · Mac+Opus high · 自主挂机 Batch B
> 目标:装备 35→80 / 心法 21→50 / 技能 82→~150+ / 典故扩 / 相生扩
> **草案待用户审**:所有结构方案均为候选,留用户拍板

## 1. 当前盘点

| 维度 | 现状 | 1.0 目标 | 缺口 |
|---|---|---|---|
| 装备 | 35(7 阶 × 5:weapon 3 + armor 1 + accessory 1) | 80 | +45 |
| 心法 | 21(7 阶 × 3 流派:刚猛/灵巧/阴柔) | 50 | +29 |
| 技能 | 82(63 心法绑定 + 18 轻功池 + 1 joint) | ~150(沿比例) | +~70 |
| lore | 35 文件(1 per 装备 · 3 段:default/obtained/boss) | ~80(1 per 装备) | +45 |
| 相生 | 8 组合 | 10-15 | +2-7 |
| 典故叙事 | 66 心法叙事 + 52 事件 | ~130(沿比例) | +~60 |

### 装备结构(当前 35)

每阶 5 件,结构统一:
- 3 weapon(刚猛/灵巧/阴柔各 1,schoolBias 对应)
- 1 armor(无流派 bias)
- 1 accessory(无流派 bias)

数值由 `numbers.yaml equipment.tiers` 段定义范围,`EquipmentFactory.fromDef` roll 个体差异。

每件 weapon 有 `specialSkillCandidates`(开锋用),armor/accessory 无。

### 心法结构(当前 21)

每阶 3 本(刚猛/灵巧/阴柔各 1),每本绑 3 招(basic/skill/ult)= 63 招。

### 技能扩展约束

轻功池 18 招(yiLiu 9 + jueDing 9,`parentTechniqueDefId: null`)已独立于心法体系。
Joint_skill 1 招(共鸣度满级解锁)。
群战沿用轻功池(零新增)。

## 2. 硬约束(扩充不可触碰)

- GDD §5.4 红线:普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000
- 三系锁:装备阶 ↔ 境界阶 ↔ 心法阶 一一对应
- `numbers.yaml equipment.tiers` 7 阶数值范围**不改**(已经红线校验)
- `numbers.yaml techniques.tiers` 7 阶倍率上限**不改**
- 装备 slot 类型只有 weapon/armor/accessory(Isar schema 固定)

## 3. 扩充影响面(代码侧)

### 零改动(纯 data 扩展)

- `data/equipment.yaml`:加新 entry,沿现有字段结构
- `data/techniques.yaml`:加新 entry
- `data/skills.yaml`:加新 entry(绑新心法)
- `data/lore/*.yaml`:每件新装备加 1 文件
- `data/synergies.yaml`:加新组合

### 需改的测试(硬编码计数)

| 文件 | 当前断言 | 扩充后 |
|---|---|---|
| `test/data/game_repository_test.dart:32` | `equipmentDefs.length, 35` | 改 80 |
| `test/data/game_repository_test.dart:34` | `techniqueDefs.length, 21` | 改 50 |
| `test/data/game_repository_test.dart:43` | `skills 82 + encounter 40` | 改 ~150 + 40 |
| `test/data/game_repository_test.dart:85` | `weapons.length, 21` | 改新数量 |
| `test/data/game_repository_test.dart:411` | 覆盖度红线(某阶 < 5 件抛错) | 改阈值 |
| `test/data/game_repository_test.dart:509` | weapon 流派覆盖度 | 保持 |

### iconPath / detailPath 美术依赖

每件装备 entry 有 `iconPath` + `detailPath`,当前 35 件 × 2 = 70 美术 asset。
扩到 80 件 = 160 asset(+90)。

**美术缺口 > 代码缺口**。代码/数据扩展 ~2-3 天,美术出图 ~1-2 月(取决于 LoRA 产能)。

## 4. 候选方案(留用户拍板)

### 装备 35→80:每阶 5→11-12 件

**方案 A(推荐):6 新 slot 变体**

每阶从 5→11(+6):
- weapon: 3→5(+2:双持武器 1 + 暗器/奇门 1)
- armor: 1→3(+2:轻甲 1 + 重甲 1,引入 armorWeight 轻/重语义)
- accessory: 1→3(+2:玉佩类 1 + 药囊/法器类 1)

7 阶 × 11 = 77,加 3 件跨阶特殊装备(飞升遗物/心魔奖励/群战功勋)= 80。

**方案 B:纯数量堆叠**

每阶 weapon 3→6(每流派 2 件)+ armor 1→3 + accessory 1→3 = 12/阶 × 7 = 84。
简单但变化感弱,84 件里有 42 把武器显得同质。

### 心法 21→50:保持 3 流派 vs 加新流派

**方案 α(推荐):保持 3 流派,每阶从 1 本→2-3 本**

7 阶 × 3 流派 × 2-3 本 = 42-63,取 50。
同流派多本心法用不同 theme(攻击型/防御型/内力型)区分。
每本绑 3 招 → 新增 29 本 × 3 = 87 招。
总技能 82 + 87 = 169(可削到 ~150 if 低阶心法只绑 2 招)。

**方案 β:加第 4 流派(杂学/无极)**

7 阶 × 4 流派 × ~2 本 = 56。
需要全新流派设计(相生/克制规则),schema 变更量大。

### 相生 8→15

当前 8 组合覆盖 schoolPair + sameSchool + sameTier。
新增 7 组合:跨阶 pair / 同流派跨阶 / 特殊心法 pair(如轻功+群战跨系统 buff)。

## 5. 工作量预估

| 子项 | opus xhigh 预估 | 说明 |
|---|---|---|
| 装备 yaml 45 条 + numbers 检查 | ~2h | 纯数据,沿模板 |
| 心法 yaml 29 条 + 技能 yaml ~87 条 | ~3h | 绑定关系密集 |
| lore 45 文件(各 3 段叙事) | ~4-5h | 文案量最大 |
| 相生 7 条 + 数值校验 | ~1h | |
| 测试修 + 红线压测 | ~1h | 改计数 + 新 R5 |
| 美术 placeholder | ~30min | iconPath 占位 |
| **合计** | **~12-15h opus xhigh** | 建议分 3-4 批 |

## 6. 拍板候选(用户决策)

| # | 决策点 | 候选 | 推荐 |
|---|---|---|---|
| Q1 | 装备扩充方案 | A(slot 变体) / B(纯堆叠) | **A ✅ 用户拍板 2026-05-28** |
| Q2 | 心法扩充方案 | α(3 流派加深) / β(加第 4 流派) | **α ✅ 用户拍板 2026-05-28** |
| Q3 | 相生扩充数量 | 10 / 12 / 15 | **12 ✅ 用户拍板 2026-05-28** |
| Q4 | 批次拆分 | 3 批(装备→心法→lore) / 4 批(装备→心法→lore→相生+测试) | **4 批 ✅ 用户拍板 2026-05-28** |
| Q5 | 美术策略 | 先 placeholder 后补 / 同步出图 | **先 placeholder ✅ 用户拍板 2026-05-28** |
| Q6 | 低阶心法技能数 | 全 3 招 / 低阶 2 招高阶 3 招 | **全 3 招 ✅ 用户拍板 2026-05-28** |

## 7. 确认决议摘要(2026-05-28 用户拍板)

- **装备 35→77+3=80**:每阶 5→11(weapon +2 双持/暗器 · armor +2 轻甲/重甲 · accessory +2 玉佩/法器)+ 3 跨阶特殊
- **心法 21→~50**:3 流派 × 7 阶 × 2-3 本,同流派多本用 theme 区分(攻击/防御/内力)
- **技能沿比例**:每本 3 招(basic/skill/ult),新增 29 本 × 3 = 87 招
- **相生 8→12**:+4 新组合
- **4 批次**:Batch 1 装备 → Batch 2 心法+技能 → Batch 3 lore → Batch 4 相生+测试
- **美术先 placeholder**:iconPath/detailPath 占位,美术异步出图
