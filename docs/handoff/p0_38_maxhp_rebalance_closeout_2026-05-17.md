# P0.1 #38 base maxHp 数值重平衡 · closeout

> **完工**:2026-05-17(Mac + Opus 4.7 xhigh,~2h 全 4 phase)
> **基线**:864/864 → **873/873**(+9 case)+ analyze 0 issues
> **commit 前缀**:`[balance]`
> **spec 起点**:`docs/handoff/p0_38_maxhp_rebalance_spec.md`(245 行)

---

## 1. 决议

**方案 D**(spec §4 5 lever 候选 + Phase 0 reality check 后增 zongShi 修正路径)。

### 1.1 具体 lever 改动(numbers.yaml + equipment.yaml)

| 改动点 | 旧值 | 新值 | 降幅 |
|---|---|---|---|
| `combat.max_hp_formula.internal_force_factor` | 0.7 | **0.5** | -28% |
| `combat.max_hp_formula.constitution_factor` | 500 | **400** | -20% |
| `equipment.tiers.baoWu.armor.hp_max` | 2300 | **2000** | -13% |
| `equipment.tiers.baoWu.accessory.hp_max` | 1300 | **1100** | -15% |
| `equipment.tiers.shenWu.weapon.hp_max` | 500 | **350** | -30% |
| `equipment.tiers.shenWu.armor.hp_max` | 3000 | **2300** | -23% |
| `equipment.tiers.shenWu.accessory.hp_max` | 1800 | **1400** | -22% |

equipment.yaml 联动改 7 件(同 numbers tier 区间端点):
- 5 件神物级 baseHealthMin/Max(weapon×3、armor、accessory)
- 2 件宝物级 baseHealthMin/Max(armor、accessory)
- min 端按比例收窄保区间宽度自洽

### 1.2 W18-A1.2 cap 兜底保留决议

**保留 maxHp ≤ 20000 cap**(`StageBattleSetup.applySynergy`),作 **second-line defense**:
- 日常路径不再 trigger(实测 wushen 极值 base 16550 + hpPct 0.20 = 19860 < 20000)
- 兜底覆盖**装备强化 + 共鸣双乘极值场景**(满 +49 强化 ×3.45 + 共鸣心剑通灵 ×1.30 合计 ×4.485 倍乘,神物级 armor 单件可达 ~13455)
- hot-loop 升级版 test 新增独立 case 区分「历史回归(人造 21800 触发 cap)」vs「新基线回归(真实 16550 不触发 cap)」

## 2. 7 阶极值矩阵(grep 实测填表,memory `feedback_closeout_numbers_grep` 实践)

**公式**:base + IF×0.5 + const×400 + Σ(weapon+armor+accessory).hp_max(裸值,无强化无共鸣)

| 境界 | IF 上限(dengFeng) | const 10 | 装备 hp_max 求和 | **新 base 极值** | vs 16667 |
|---|---|---|---|---|---|
| xueTu·dengFeng | 1100 | 4000 | 0+200+100 = 300 | 1000+550+4000+300 = **5850** | ✅ 余 10817 |
| sanLiu·dengFeng | 2000 | 4000 | 50+450+200 = 700 | 1000+1000+4000+700 = **6700** | ✅ 余 9967 |
| erLiu·dengFeng | 3500 | 4000 | 100+750+350 = 1200 | 1000+1750+4000+1200 = **7950** | ✅ 余 8717 |
| yiLiu·dengFeng | 5700 | 4000 | 150+1100+550 = 1800 | 1000+2850+4000+1800 = **9650** | ✅ 余 7017 |
| jueDing·dengFeng | 9000 | 4000 | 250+1600+850 = 2700 | 1000+4500+4000+2700 = **12200** | ✅ 余 4467 |
| zongShi·dengFeng | 12500 | 4000 | 400+2000+1100 = 3500 | 1000+6250+4000+3500 = **14750** | ✅ 余 1917 |
| **wuSheng·dengFeng** | **15000** | **4000** | 350+2300+1400 = **4050** | 1000+7500+4000+4050 = **16550** | ✅ 余 117 |

**心法相生 hpPct 0.20 加成后**(spec §5 验收):
- wuSheng 极值 16550 × 1.20 = **19860** ≤ 20000 §5.4 红线 ✓
- zongShi 极值 14750 × 1.20 = 17700 ≤ 20000 ✓
- 全 7 阶 hpPct 加成后均 ≤ 20000,不依赖 applySynergy cap 兜底

## 3. Phase 0 reality check 关键发现(spec 漏算的 zongShi 阶)

spec §2 / §4 只算了 wuSheng 极值 21800 → 16667 缺口 -5133,**漏算 zongShi 阶 18750 → 16667 缺口 -2083**。

Phase 0 grep 实测 7 阶 × 维度极值矩阵后发现:
- 单 lever 方案 A(只动 IF factor 0.7→0.4):wuSheng 17300 仍破红线
- 单 lever 方案 B(只动 const factor 500→300):wuSheng 19800 仍破
- 单 lever 方案 C(只动神物 hp):zongShi 不解决
- 单 lever 方案 E(全阶 hp_range 等比降 25%):wuSheng 20475 仍破(IF/const 不动 lever 不够)

**结论:只有方案 D(多 lever 组合)能同时让 zongShi + wuSheng 双阶通过 ≤ 16667**。

## 4. 代码层 cross-ref 实测

- ✅ **SeclusionService**(`lib/features/seclusion/application/seclusion_service.dart`)走独立路径,只用 `baseInternalForcePerHour × growth × ...`,**不引 `max_hp_formula` 任何系数**,改 IF factor / const factor 不影响闭关产出
- ✅ **damage_formula.internal_force_factor=0.4** 独立 numbers 路径(`lib/features/battle/domain/damage_calculator.dart`),与 maxHp 公式两条线,本次不动
- ✅ **师承遗物 +5%/件 buff**(`CharacterDerivedStats.internalForceMaxWithLineage`)只乘 `Character.internalForceMax`,不直接进 maxHp 公式。`internalForce`(当前值)间接进 maxHp 公式时,§5.4 红线锁住 IF ≤ 15000 + `applySynergy` cap 15000 双护栏,不构成额外 lever

## 5. 修改清单(7 + 6 = 13 处)

### 5.1 numbers.yaml(7 处)

1. `combat.max_hp_formula.internal_force_factor` 0.7 → 0.5 + 历史变更注释
2. `combat.max_hp_formula.constitution_factor` 500 → 400 + 历史变更注释
3. `equipment.tiers.baoWu.armor.hp_min/max` 1600/2300 → 1400/2000
4. `equipment.tiers.baoWu.accessory.hp_min/max` 850/1300 → 750/1100
5. `equipment.tiers.shenWu.weapon.hp_min/max` 200/500 → 150/350
6. `equipment.tiers.shenWu.armor.hp_min/max` 2300/3000 → 1750/2300
7. `equipment.tiers.shenWu.accessory.hp_min/max` 1300/1800 → 1000/1400
- 附:数值校验注释「神物·护甲 2000-3000 ✓」→ 「1750-2300 ✓」
- 附:`validation_examples` 5 战例 max_hp 注释同步(A/B/C/D/E)

### 5.2 equipment.yaml(7 件 baseHealthMin/Max)

- `armor_baowu_jin_si_jia` 1600/2300 → 1400/2000
- `accessory_baowu_yu_long_pei` 850/1300 → 750/1100
- `weapon_shenwu_po_jun_dao` 200/500 → 150/350
- `weapon_shenwu_tian_wen_jian` 200/500 → 150/350
- `weapon_shenwu_huan_meng_bian` 200/500 → 150/350
- `armor_shenwu_xuan_huang_pao` 2300/3000 → 1750/2300
- `accessory_shenwu_kun_lun_pei` 1300/1800 → 1000/1400

### 5.3 test 改动清单(4 文件)

1. `test/data/game_repository_test.dart` line 59-60 maxHpFormula 期望值 0.7/500 → 0.5/400
2. `test/combat/derived_stats_test.dart` 5 战例 maxHp 期望 3850/6600/6180/7760/19500 → 3250/5400/5100/6400/15500
3. `test/balance/synergy_hot_loop_upgrade_test.dart`:
   - 7 阶 tierBaseStats baseMaxHp 重算(xueTu 2200→5850 / sanLiu 3500→6700 / erLiu 5500→7950 / yiLiu 8000→9650 / jueDing 11500→12200 / zongShi 15500→14750 / wuSheng 21800→16550)
   - 极端 1 case 拆为「历史回归(人造 21800 触发 cap)」+「新基线回归(真实 16550 不触发 cap)」2 case
4. `test/features/battle/application/stage_battle_setup_test.dart` Codex 视觉验收 A:B:C maxHp 锚点 7992/6660/6660 → 6360/5300/5300(A:B ratio 1.20 不变)

### 5.4 新增 test 文件(spec §6 验收)

`test/balance/maxhp_extremum_redline_test.dart`(+8 case):
- 7 case:每阶 dengFeng + const 10 + 装备 hp_max 满 → maxHp ≤ 16667 约束语义(memory `feedback_red_line_test_semantics` 实践)
- 1 case:销账锚点 wushen 极值 == 16550 锁固定数字防漂移(memory 配套:锚点单独写)

## 6. 验收结果

- ✅ **极值场景**:wushen + const 10 + IF 15000 + 装备 hp_max 满 + 阴阳调和 hpPct 0.20 → 19860 ≤ 20000 §5.4
- ✅ **派生公式自洽**:base maxHp ≤ 16667 全 7 阶过(spec §2 目标)
- ✅ **applySynergy cap 保留**(W18-A1.2 hotfix 仍在,作 second-line defense)
- ✅ **全 7 阶极值矩阵**:实测填表全 ≤ 16667(详 §2)
- ✅ **普伤红线 ≤ 8000 不退化**(damage_formula 未动)
- ✅ **Boss HP ≤ 50000 不退化**(towers.yaml 未动)
- ✅ **闭关 4 维度产出红线不退化**(seclusion_service 未动)
- ✅ **境界曲线感知**:7 阶 maxHp 5850 → 6700 → 7950 → 9650 → 12200 → 14750 → 16550,每升 1 大境界 +~1500-2800,**线性增长无爆炸**,叙事张力保留
- ✅ **测试**:864 → 873(+9 case,新增 8 极值红线 + 1 hot-loop 新基线 case)
- ✅ **analyze**:0 issues

## 7. 风险关闭

| spec §7 风险 | 实测结果 |
|---|---|
| R1 SeclusionService IF factor cross-ref | ✅ 独立路径无 cross-ref(grep 实测) |
| R2 const factor vs §4.1「根骨主要影响血量」 | ✅ const factor 400 ≥ 350 建议下限,叙事保留 80% |
| R3 W18-A1 fixture A:B/A:C 锚点微调 | ✅ A:B = 6360/5300 ratio 1.20 不变,只数值微调 |
| R4 神物级装备「神兵」叙事张力 | ✅ shenWu armor 降幅 23% < 35% 上限,神物级仍是体感最强 |
| R5 估时 8-15h 偏长 | ✅ **实际 ~2h** 全 4 phase(Phase 0 0.5h + Phase 1 0.5h 直接拍 D + Phase 2 0.5h + Phase 3 0.5h),低于估时下限 |

## 8. memory 实战追加

- **`feedback_layered_bugs`** 命中:W18-A1.2 cap 兜底加上后真暴露 base 派生不自洽,P0.1 #38 根治
- **`feedback_red_line_test_semantics`** 实践:新增 7 阶极值 case 用「≤ 16667」约束语义 + 销账锚点 wushen == 16550 单独写
- **`feedback_closeout_numbers_grep`** 实践:Phase 0 grep 实测 7 阶 IF 上限 + 装备 hp_max 填表,**发现 spec §2/§4 漏算 zongShi 阶 18750 → 16667 缺口 -2083**,避免单 lever 方案落坑
- **`feedback_batch_sed_analyze_radar`** 沿用:Phase 2 改 yaml 后第一动作跑 analyze,0 issues 再继续

## 9. PROGRESS #38 销账段(待更新到 PROGRESS.md)

```
38. ✅ **base maxHp 数值平衡 P0.1 销账**(2026-05-17,opus xhigh ~2h):方案 D 多 lever
    组合 + numbers.yaml IF×0.5 + const×400 + 神物/宝物装备 hp_max 联动降 22-30%。
    全 7 阶极值 ≤ 16667 spec §2 目标(实测 wushen 16550 / zongShi 14750),hpPct
    0.20 加成后 ≤ 20000 §5.4 红线自然过,不靠 cap 兜底。W18-A1.2 cap 保留作
    second-line defense。test 864 → 873(+9 case)+ analyze 0 issues。详
    closeout `p0_38_maxhp_rebalance_closeout_2026-05-17.md`。**P0.2 切 Supabase
    排行榜 0→1**(opus xhigh 6-10h 新会话)。
```

---

**closeout 完毕**。下波 P0.2 Supabase 排行榜 0→1 单独会话开工(spec 待起草)。
