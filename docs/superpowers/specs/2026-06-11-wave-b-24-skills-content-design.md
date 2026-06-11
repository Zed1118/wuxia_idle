# 波B · 24 招全内容 + 30 关高熟练度 sweep · 设计 spec（2026-06-11）

> 上游：master spec §12/§16#1 + `playability_phase2_backlog.md` §一(24 招)/§六(sweep)。
> 模式 xhigh。原则：长线打磨（CLAUDE v1.19 §7）——一次做全面。
> 拍板背景：波次顺序 B 已拍顺位第一；构成细节按 master spec §12 自主决策（bg autonomous）。

## 0 · 现状锚（Phase 0 实测）

- 玩家侧 Boss 来源招仅 8：真解 3（崩山击/青锋绝/落英缤纷,前后两个系**复用心法 ult 改 source**）
  + 塔残页 2（御风斩/流星剑,同为复用,且全灵巧）+ 破招 3。流派分布 刚2/灵4/阴2。
- 真解挂载仅 Ch1/2/3 章末;塔残页仅 floor 10/20;Boss 蓄力技全游戏仅 1（青锋绝 @stage_02_05）。
- **wiring 大缺口**：解锁的 standalone 真解（青锋绝,parentTechniqueDefId=null）**进不了任何装配池**
  ——resolver 主修/大招池只读心法 skillIds,`isUnlocked` 对装配零消费。掉了等于白掉。
- 青锋绝无 tier → canEquipAtRealm 恒 true,一旦入池即破 §5.3（必须补 tier）。
- `isEncounterSkill` getter = parent==null && tier!=null → drop 招补 tier 后会被误判为奇遇招。
- stage hook 已支持 dropSkillFragmentId（每胜 rng,非首通限定）;红线④⑤只锚 stage manual / tower frag。
- balance_simulator：主表 30 关 × floor/ceiling × 50 seed;熟练度只有 3 真解关焦点测（uses 0 vs 800）。
- ultimate_power_threshold=5000 → 真解档（mult<5000,powerSkill）全进主修槽池。
- 敌内力 = 同境界 IF max × 0.20（离散阀门,>0.245 wuSheng 放 2 次击穿红线）——蓄力技 cost 决定 Boss 放招次数。

## 1 · B1 内容批：24 招构成（master spec §12 对齐）

**真解 6**（mainline_drop · 章末 Boss 首通必给 · **同招 = 该 Boss chargeSkillId 蓄力技**,
沿青锋绝 canon「破他的招、学他的招」）。流派 2/2/2,tier = 章 requiredRealm（1-6）：

| 章 | Boss | 流派 | 名（拟） | mult |
|---|---|---|---|---|
| Ch1 | 撑伞高人(雨渡) | 阴 | 斜雨穿帘 | 1800 |
| Ch2 | 青衫剑客 | 灵 | 青锋绝（已有,补 style/tier） | 2500 |
| Ch3 | 灰衣人 | 刚 | 千钧坠岳 | 2800 |
| Ch4 | 西凉霸主(阳关) | 灵 | 风卷流沙 | 3200 |
| Ch5 | 三弟子 | 刚 | 十荡十决 | 3600 |
| Ch6 | 西凉霸主(终战) | 阴 | 阳关无故人 | 4000 |

**塔残页 6**（fragment · 塔 Boss 层 5/10/15/20/25/30 每胜概率掉,floor10/20 re-point）：
f5 刚·开碑手 1600 / f10 灵·燕子三抄 2300 / f15 阴·烛影摇红 2600 /
f20 刚·金刚伏魔 3000 / f25 灵·惊鸿照影 3400 / f30 阴·月落无声 3800。tier 1-6。

**章末重打残页 3**（Ch4/5/6 章末 dropSkillFragmentId,高阶 farm 目标,stage hook 已支持）：
Ch4 刚·关山拔戟 3100 / Ch5 灵·马踏飞燕 3500 / Ch6 阴·夜雨十年灯 3900。tier 4/5/6。

**破招 3** 已有。→ 玩家侧每流派 = 真解2+塔残页2+重打残页1+破招1 = **6/6/6**;
Boss 技 6 = 真解双用。批合计 18 distinct（24 构成含双用,master spec「24 个左右」）。

新增 skill def 14（5 真解 + 6 塔残页 + 3 重打残页）,全 powerSkill / requiresManualTrigger
false / style 必填 / tier 必填 / cost 按该章 Boss 内力预算校准（Boss 蓄力 1-2 次,实装实测）/
cd 3-5。**4 个复用心法 ult（崩山击/落英缤纷/御风斩/流星剑）restore source: technique**
（波A proficiency 效果保留）,挂载点 re-point 新招。
proficiency.effects：模板招沿波A 流派模板;真解 6 手工高半档（沿青锋绝锚;化境伤害%死配置→CD）。
文案：4 字主体（content_guide §5.2）,描述金庸机理+古龙意象各半,Boss 身份 tie-in（Ch4-6 沿
「西出阳关」文化弧:流沙/关山/夜雨十年灯）。

## 2 · B2 装配池 wiring（内容批前置,不修白铺）

1. `SkillSource.towerFragment` → **`fragment`**（yaml `tower_fragment` → `fragment`,2 处）：
   残页语义与挂载位置解耦（塔层 + 章末重打共用）。source 不入 save,零迁移。
2. `isEncounterSkill` getter 改 `source == SkillSource.encounter`（单一真相源;fixture 缺 source 的补）。
3. Resolver 加 `unlockedDropSkills`：source ∈ {mainlineDrop, fragment} && save.isUnlocked
   && style == character.school（流派 build 一致性,沿破招槽先例）。
4. Picker 池注入：main1/main2/ultimate 槽候选 += dropSkills（按 ultimate_power_threshold 分流;
   当前批全 <5000 → 主修槽）。**autoFill 不动**（掉落招玩家主动换装,不自动顶,§5.7 先感受问题）。
5. `equipSkill` gate：drop 招仅 main1/main2/ultimate 槽 + isUnlocked（新 sealed
   `SlotEquipNotUnlocked`）+ style==school（复用 SlotEquipStyleLocked）+ 既有 tier gate。
6. 藏经阁武学库加「秘传」分组（已解锁 drop 招,复用 SkillProficiencyRow）。

## 3 · B3 Boss 蓄力技挂载（机制 Boss ×6）

5 章末 Boss（01/03/04/05/06_05）：chargeSkillId = 其真解 + 真解入 skillIds。
- 真解 mult 必须 > 该 Boss 其余 powerSkill（AI 蓄力自动选,沿青锋绝注释锚）,实装逐 Boss 核。
- cost × 敌内力预算（IF max × 0.20）→ 放招次数 1-2 次/场,逐 Boss 实测校准。
- Ch5/Ch6 跨阶红线压测必须重跑（满配玩家不被击穿）;Ch1 蓄力 = 破招机制 onboarding（破招槽 autoFill 已保底）。

## 4 · 红线（loader fail-fast + 红线测,写约束语义）

- ⑥ drop 招（mainlineDrop|fragment）必须 style ≠ null && tier ≠ null。
- ⑦ 挂载完备性：每个 mainlineDrop 招恰被 1 个 stage manual 挂载;每个 fragment 招恰被
  1 个挂载点（tower floor 或 stage frag）挂载（无孤儿/无重复）。
- ⑤ 改写：stage/tower dropSkillFragmentId → source == fragment。
- 内容红线测：6 章末 Boss 关 manual+charge 全配 / 塔 6 Boss 层 frag 全配 / 流派 6/6/6。
- §5.4 绝对线 + 130% cap 既有测族守住;新招 interrupt 无关(canInterrupt=false)不触波A cap 红线。

## 5 · B5 30 关高熟练度 sweep（backlog §六销账）

balance_simulator_test 加全表 sweep：30 mainline × {floor,ceiling} × uses {0,800} × 30 seed,
输出 `proficiency_sweep_2026-06-11.md`（每关 4 列 + delta + 过易/过难诊断,沿 _summarize 体例）。
断言写约束语义：per stage maxed ≥ fresh − 10pt（CD 改变战斗流容噪）+ 全表 mean delta ≥ 0。
B3 蓄力 Boss 落地后跑（新机制难度变化一并入读数）;主表 sweep 同跑对照波前 baseline。
tune 候选只动 skills.yaml（我层）;numbers.yaml 候选记 doc 待拍板（CLAUDE 红线）。

## 6 · 实装序（TDD,每步全测）

T1 source enum fragment 泛化 + isEncounterSkill 改 source + 红线⑤⑥⑦ → T2 14 新招 yaml
+青锋绝补 style/tier + 4 ult restore + 挂载（stages/towers）+ 内容红线测 → T3 蓄力技挂载
×5 + 逐 Boss cost/mult 校准 + 跨阶压测 → T4 resolver/picker/equipSkill gate/武学库秘传组
→ T5 e2e（首通真解→装配→战斗可用;重打残页累计）→ T6 sweep 全表 + balance 全量 + 全仓闸门。

## 7 · 默认拍板（bg 自主,可推翻,记 backlog 候补）

- 真解=Boss 蓄力技双用（青锋绝 canon);Boss school 与真解流派允许错位（灰衣人掉刚猛 canon,文案圆）。
- drop 招装配走 style==school gate（流派 build 一致性）;autoFill 不自动装 drop 招。
- 塔小 Boss 层（5/15/25）一并挂残页（master spec 只说大 Boss;6/6/6 配平需要,且小 Boss 层掉残页
  与「每次 Boss 胜利 rng」语义一致）。
