# P0.1 #38 base maxHp 数值重平衡 · 完整 spec

> **任务级别**:P0 阶段第一波(1.0 路线图 ROADMAP_1_0.md P0.1)
> **预估**:opus xhigh **8-15h**(R3 风险:实测可能更长,memory `feedback_layered_bugs` 数值平衡级联)
> **开工模型**:必须 **opus xhigh**(跨 yaml + 代码层 + test + 文档,跨模块大改)
> **commit 前缀**:`[balance]`(可多 commit 拆分推进)
> **作者**:Mac + Opus 4.7 · 2026-05-17 起草

---

## 1. 背景

W18-A1.2 hot-loop 升级版(2026-05-17,commit `b2f4a03`)在 7 阶 × 5 synergy 矩阵 + 4 极端 case 压测中暴露:

**wushen 境界 + 满 constitution(10) + internalForce 15000(§5.4 红线上限) + 神物级装备(3 件) 派生 base maxHp 理论极值 = 21800,已破 §5.4 玩家血量红线 20000。**

当前临时兜底:`StageBattleSetup.applySynergy` 加 maxHp ≤ 20000 cap(W18-A1.2 hotfix),保证战斗注入数值不破红线。但 **base 派生公式仍不自洽**:玩家在角色面板看到的「最大血量」可能显示 21800 然后实际战斗值被 cap 到 20000,UI 与战斗层割裂。

**根治目标**:**重平衡 numbers.yaml + equipment.yaml,保证派生公式 base maxHp ≤ 16667**(让 W18-A1 实装的心法相生 hpPct 0.20 加成后 16667 × 1.20 = 20000 仍 ≤ 红线,自然兜底不依赖 cap)。

## 2. 公式与极值锚点

### GDD §5.6 最大血量公式

```
最大血量 = base + 内力 × internal_force_factor + 根骨 × constitution_factor + 装备血量
```

### 当前 numbers.yaml 实测(2026-05-17 grep)

| 字段 | 路径 | 当前值 |
|---|---|---|
| base | `combat.max_hp_formula.base` | 1000 |
| internal_force_factor | `combat.max_hp_formula.internal_force_factor` | 0.7(GDD 原写 5,Phase 1 平衡调) |
| constitution_factor | `combat.max_hp_formula.constitution_factor` | 500 |

### 装备 hp 上限(神物级 5 件,equipment.yaml line 462-538)

| 装备 | slot | baseHealthMax |
|---|---|---|
| weapon_shenwu_po_jun_dao(刚猛) | weapon | 500 |
| weapon_shenwu_tian_wen_jian(灵巧) | weapon | 500 |
| weapon_shenwu_huan_meng_bian(阴柔) | weapon | 500 |
| armor_shenwu_xuan_huang_pao | armor | **3000** |
| accessory_shenwu_kun_lun_pei | accessory | **1800** |

**单角色 3 槽极值装备 hp = 500 + 3000 + 1800 = 5300**

### 当前极值计算

```
wushen 极值 base maxHp = 1000 + 15000 × 0.7 + 10 × 500 + 5300
                       = 1000 + 10500 + 5000 + 5300
                       = 21800  ❌ 破红线 20000
```

### 目标极值

```
wushen 极值 base maxHp ≤ 16667
经心法相生 hpPct 0.20 加成后 ≤ 16667 × 1.20 = 20000  ✅ 守红线
需降 21800 → 16667,即减 5133
```

## 3. 范围

### 必动文件

| 文件 | 段 | 说明 |
|---|---|---|
| `data/numbers.yaml` | `combat.max_hp_formula.*` | 3 个 lever 候选可调 |
| `data/numbers.yaml` | `equipment.tiers.*.hp_range` | 7 阶 hp 上限曲线(可能需要全阶降) |
| `data/equipment.yaml` | 35 件 baseHealthMin/Max | 与 numbers.yaml tier hp_range 对齐 |
| `test/balance/synergy_hot_loop_upgrade_test.dart` | 39 + 4 case | 极端 case 数值断言更新 |
| `test/features/battle/application/stage_battle_setup_test.dart` | 6 字段红线 case | A:B/A:C maxHp 锚点(7992/6660 yiLiu)可能微调 |

### 可能联动文件

| 文件 | 涉及理由 |
|---|---|
| `numbers.yaml combat.damage_formula.*` | **独立 internal_force_factor 0.4,不动伤害公式**(确认两个 IF factor 路径独立后无须改) |
| `numbers.yaml inheritance.heritage_items.*` | 师承遗物 +5% buff,wushen 飞升才有(Demo 不实装),但加入压测矩阵 |
| `numbers.yaml combat.resonance.stages` | 共鸣度心剑通灵 +30% bonus_multiplier 作用 base 还是 final 需澄清 |
| `numbers.yaml equipment.enhancement.success_curve` | +49 强化 ×(1+0.05×level) 加成在 base 之上 |

### 不动文件

- ❌ `data/skills.yaml`(招式倍率不动)
- ❌ `lib/features/battle/`(代码层 cap 兜底保留,作为 second-line defense)
- ❌ `data/equipment.yaml` 数量(仍 35 件,只动数值)
- ❌ GDD.md / CLAUDE.md(本批数值层重平衡,不动设计文档)

## 4. lever 候选(opus xhigh design review 阶段决定方案)

不预先选,**opus xhigh design review 阶段(预计 1-2h)拍方案**。候选:

### 方案 A:单 lever 重击 IF factor
- `internal_force_factor 0.7 → 0.4`(-4500)
- 优:lever 单一,影响可控
- 劣:wushen 境界感知:IF 15000 只给 6000 maxHp,「内力即血量」直觉退化

### 方案 B:单 lever 重击 const factor
- `constitution_factor 500 → 300`(-2000)
- 优:GDD §4.1「根骨主要影响血量」,const 收益感知保留
- 劣:单 lever 不够,需配合其他

### 方案 C:单 lever 重击神物装备 hp
- `armor_shenwu_xuan_huang_pao baseHealthMax 3000 → 1800`(-1200)
- `accessory_shenwu_kun_lun_pei baseHealthMax 1800 → 1000`(-800)
- 优:wushen 装备体感曲线收敛
- 劣:神物装备「神物」感知下降,叙事张力少

### 方案 D:多 lever 组合(推荐起手考虑)
- `IF factor 0.7 → 0.55`(-2250)
- `const factor 500 → 400`(-1000)
- 神物装备 hp 降 ~30%(-1500 到 -2000)
- 合计 -4750 到 -5250,命中目标
- 优:每个 lever 微调,无单点剧烈变化
- 劣:测试 case 断言批量微调,工作量大

### 方案 E:全 7 阶 hp_range 等比降
- 全阶 hp_range 降 ~25%
- 优:体感曲线完整,wushen 体验保留比例
- 劣:低阶玩家 maxHp 也下调,可能影响新手 Demo 关卡数值平衡(需联动验证 stage_01_01 至 stage_03_05 战斗结果)

**开工建议**:design review 阶段先用方案 D 推一遍 7 阶 × wushen 极值矩阵,**任何方案落地前必须 grep 实测所有 7 阶极值不破红线**(memory `feedback_closeout_numbers_grep` 实战:closeout 罗列加和不可信,grep 为准)。

## 5. 7 阶 × 维度极值矩阵(必须全审)

每阶都要算 4 维极值,确保**全 7 阶都 ≤ 16667**(不仅 wushen):

| 境界 | IF 上限 | const | 主修 tier 装备 hp 上限 | base 极值 = 1000 + IF×factor + const×factor + equip_hp |
|---|---|---|---|---|
| 学徒 xueTu | ? | 10 | 寻常货 5 件 hp_max | 计算填 |
| 三流 sanLiu | ? | 10 | 像样货 5 件 hp_max | 计算填 |
| 二流 erLiu | ? | 10 | 好家伙 5 件 hp_max | 计算填(W18-A1 实测 yiLiu A:B 7992/6660 fixture 锚点) |
| 一流 yiLiu | ? | 10 | 利器 5 件 hp_max | 计算填 |
| 绝顶 jueDing | ? | 10 | 重器 5 件 hp_max | 计算填 |
| 宗师 zongShi | ? | 10 | 宝物 5 件 hp_max | 计算填 |
| **武圣 wuSheng** | **15000** | **10** | **神物 3 件 5300** | **21800** → 目标 ≤ 16667 |

**注**:`realms.tiers[*].max_internal_force` 需 grep 实测填入。如果低阶 IF 上限远低于 wushen,可能低阶不破红线,但仍要全审避免漏。

### synergy 加成压测矩阵

W18-A1 5 synergy 组合 × 7 阶 × wushen const 10 × IF 上限,共 35 case:

- 阴阳调和(hpPct 0.20)→ base × 1.20 ≤ 20000
- 刚柔并济(speed +25%,不影响 hp)→ base ≤ 20000
- 阴影迅捷(attack +15% + speed +15%,不影响 hp)→ base ≤ 20000
- 同流派精进(attack +20%,不影响 hp)→ base ≤ 20000
- 同辈互补(internalForceMax +25%,影响 IF 不影响 hp)→ base ≤ 20000

**关键**:只有阴阳调和影响 maxHp,所以 base 派生 ≤ 16667 即可让全 35 case 红线全过。

## 6. 验收

### 必交付红线

- ✅ **极值场景**:wushen + const 10 + IF 15000 + 神物 3 件 + 阴阳调和 hpPct 0.20 → maxHp ≤ 20000
- ✅ **派生公式自洽**:base maxHp ≤ 16667(不依赖 applySynergy cap 兜底)
- ✅ **applySynergy cap 仍保留**(second-line defense,但日常路径不再 trigger)
- ✅ **全 7 阶极值矩阵**:每阶 const 10 + IF 上限 + 该阶装备 hp 上限 ≤ 16667
- ✅ **普伤红线 ≤ 8000 不退化**(damage_formula 不动,但要回归现有伤害 case 确认无副作用)
- ✅ **Boss HP ≤ 50000 不退化**(towers.yaml Boss 数值不动,但与 maxHp 公式无关)
- ✅ **闭关 4 维度产出红线不退化**(seclusion_service 不动)
- ✅ **境界曲线感知**:每升 1 阶 maxHp 提升明显(2-3x)但不爆炸

### 必交付测试

- ✅ 864/864(W18 基线)→ 新基线全过(数字可能微调,但不退化数量)
- ✅ `synergy_hot_loop_upgrade_test.dart` 39 + 4 case 数值断言更新(case A wushen 极值从 21800 → ≤ 16667 或新值)
- ✅ `stage_battle_setup_test.dart` 6 字段红线 case + W18-A1 A:B/A:C maxHp 锚点适配
- ✅ 新增红线压测:7 阶 × 极值 const 10 + IF 上限矩阵 case ≥ 7 个(每阶 1)
- ✅ analyze 0 issues 不退化

### closeout 必产

- `docs/handoff/p0_38_maxhp_rebalance_closeout_2026-MM-DD.md` — 含:
  - 选定方案(A/B/C/D/E 哪一种 + 具体 lever 数值)
  - 7 阶极值矩阵 grep 实测表
  - 现有 test 断言更新清单
  - PROGRESS #38 销账段
  - W18-A1.2 cap 兜底保留决议(继续保留 / 删除)

## 7. 风险

1. **R1 IF factor 联动 SeclusionService**:闭关产出 `internalForcePoints` 公式(`numbers.yaml retreat.base_outputs[*].internal_force_per_hour`)与 max_hp_formula.IF factor 在 numbers.yaml 路径独立,**理论无联动**,但需开工前 grep 确认 SeclusionService 没意外 cross-reference。
2. **R2 const factor 与 §4.1 设计哲学**:GDD §4.1「根骨主要影响血量上限」,const factor 降太多会让 const 失去存在感。建议 const factor 不低于 350(降 30% 上限)。
3. **R3 W18-A1 fixture A:B/A:C 实测锚点 7992/6660 微调**:VC18-A1 视觉验收 chip 实测数字会变,如果还在 PROGRESS 引用要同步更新。
4. **R4 装备 hp 降幅 vs 神物叙事**:神物级装备「神兵」叙事需保持张力,装备 hp 降幅建议 ≤ 35%,避免「神物不如重器」感知。
5. **R5 估时**:8-15h 是基于 design review 1-2h + 调参 2-4h + test 适配 2-4h + 验证 1-2h + closeout 0.5-1h。若选方案 D/E,test 适配会拉到 4-6h(批量微调断言)。R3 风险:估时未压测可能更长。

## 8. memory 实战参考

开工前必读 3 条 memory:

1. **`feedback_layered_bugs`** — 修上层 cap 后下层 base 派生 bug 浮现的实战教训,本任务正是该 memory 的延伸:applySynergy cap 兜底 → 暴露 base 派生不自洽 → 根治 base
2. **`feedback_red_line_test_semantics`** — 红线 test 写约束语义不写具体数字,新增 7 阶极值 case 必须用「base ≤ 16667」「post-synergy ≤ 20000」等约束写法,不写「wushen maxHp == 5300」具体值
3. **`feedback_closeout_numbers_grep`** — 7 阶极值矩阵 closeout 罗列加和不可信,**每阶必 grep 实测填表**
4. **`feedback_batch_sed_analyze_radar`** — 批量改 yaml 后 analyze 是漏改雷达,first analyze 必跑

## 9. 开工流程建议

### Phase 0:reality check(0.5h)
- `grep realms.tiers data/numbers.yaml` 拉全 7 阶 IF 上限 / level cap
- `grep equipment.tiers data/numbers.yaml` 拉全 7 阶 hp_range 配置
- 算出 7 阶极值矩阵当前数字
- 确认 SeclusionService / damage_formula 无 cross-reference

### Phase 1:design review(1-2h)
- 选 lever 组合(A/B/C/D/E 或自定义)
- 算目标极值矩阵(每阶填新数字)
- 验证全阶 ≤ 16667
- 用户拍板方案

### Phase 2:numbers.yaml + equipment.yaml 调参(2-4h)
- 改 max_hp_formula coefficients
- 改神物装备 baseHealthMin/Max(及其他阶必要时联动)
- 改 equipment.tiers hp_range(若选方案 E)

### Phase 3:test 适配(2-4h)
- `synergy_hot_loop_upgrade_test.dart` 极端 case 断言更新
- `stage_battle_setup_test.dart` W18-A1 锚点适配
- 新增 7 阶极值红线 case
- `flutter test` 全过

### Phase 4:验证 + closeout(1-2h)
- `flutter analyze` 0 issues
- 重跑 hot-loop 升级版 39 + 4 case
- grep 实测全 7 阶极值填 closeout 矩阵
- PROGRESS.md 销账 #38
- closeout 产文

## 10. 关键约束沿用(项目级)

- 不硬编码数值/中文文案
- 不动 GDD.md / CLAUDE.md / IDS_REGISTRY.md / data_schema.md(本批数值平衡 P0 例外:**必动 numbers.yaml + equipment.yaml**,commit 前缀 `[balance]`)
- 红线 test 写约束语义不写具体数字
- Mac 写 lib/、data/*.yaml(顶层)、test/;DeepSeek 不参与本批
- §5.4 数值红线:普伤 ≤ 8000 / Boss HP ≤ 50000 / 玩家血 ≤ 20000 / 内力 ≤ 15000 / 装备攻击 ≤ 2000

---

**spec 起草完毕。开工前升 opus xhigh + 新会话(避免 audit 上下文干扰数值决策)。**
