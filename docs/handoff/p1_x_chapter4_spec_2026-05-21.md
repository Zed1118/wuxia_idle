# 候选 2 主线扩 · Phase 1 spec(第 4 章 · 西出阳关 · 1.0 P2 第二条主线第 1 章)

> 日期:2026-05-21 晚
> 模型:Mac + Opus 4.7 xhigh(spec 起草档)
> 上游 Phase 0:`p1_x_chapter4_phase0_reality_check_2026-05-21.md`
> 用户拍板:Ch4=1.0 P2 范畴(γ 字数方案 / 西北 yiLiu 全章 / 立即开 spec)
> 产出:本 doc(spec 设计稿,不动 lib/ / yaml / GDD)

---

## TL;DR · Ch4 设计要点

- **章定位**:1.0 P2 第二条主线第 1 章(M5-M10 范畴),Demo §8.4 不动
- **章标题**:**「西出阳关」**(沿 GDD §8.1 章名风格 — 学武出山 / 武林初识 / 名扬江湖)
- **境界跨度**:yiLiu 一流(qiMeng → dengFeng 完整 7 层)
- **5 关结构**:1-3 普通 + 4 小 Boss + 5 大 Boss(跨 jueDing 末关)
- **地理梯度**:中原 → 河西走廊 → 玉门关 → 大漠 → 嘉峪关西凉
- **数值梯度**:HP 7,000 → 16,000 / Atk 700 → 1,300 / Speed 170 → 220(全在 §5.4 红线内)
- **字数预算**:~3,100 字(章首尾 ~1,300 + 12 stages narratives ~1,800)
- **schema 改动**:**仅** `EncounterBiome` 扩 2 enum(`desert` / `frontier`)+ 5 entry stages.yaml + 12 narratives 文件 + 1 chapter_04.yaml + GDD/PROGRESS/ROADMAP_1_0 同步
- **不动**:lib/(零代码改),所有现有 yaml(equipment/techniques/numbers/skills/towers...)

---

## 一 · 5 关数值矩阵 + 敌人设计

### 1.1 数值梯度推算依据

参考 Ch1-3 末关 + memory `feedback_wuxia_boss_balance_crosstier`:章末 Boss 跨 1-2 阶才稳触发战败。

| 章 | requiredRealm | 末关 boss tier | 末关 HP | 末关 Atk | difficultyMultiplier | baseExpReward |
|---|---|---|---|---|---|---|
| Ch1 | xueTu | erLiu·yuanShu(跨 2)| 10,000 | 750 | 1.8 | 600 |
| Ch2 | sanLiu | erLiu·yuanShu(跨 1)| ~10,000 | ~800 | 2.3 | 1,800 |
| Ch3 | erLiu | erLiu·yuanShu(同阶顶层)| 11,000 | 900 | 2.8 | 6,000 |
| **Ch4** | **yiLiu** | **jueDing·qiMeng(跨 1)** | **~16,000** | **~1,300** | **~3.3** | **~18,000** |

Ch4 末 Boss 跨阶 jueDing qiMeng(29 级,internal_force_max 6000+),HP ~16,000 仍远低于 §5.4 Boss 红线 50,000+ — 与 GDD §3 三阶节奏一致(暗示玩家需升 jueDing 才能轻取)。

### 1.2 5 关 stages.yaml 设计稿

#### Ch4-1 · 阳关初渡(首关)
- **stage_04_01**(yiLiu·qiMeng,普通关,3 敌人)
- **biome**:`mountainForest` 复用(中原边缘山道,渐入河西走廊)
- **weather**:`clear`(默认)
- **敌人组合**(西北流寇前哨,三流派覆盖):
  | id | 名称 | tier/layer | school | HP | Atk | Speed | skillIds |
  |---|---|---|---|---|---|---|---|
  | enemy_yiLiu_liukou_a | 流寇头领 | yiLiu·qiMeng | gangMeng | 7,200 | 720 | 170 | menpai_basic + skill |
  | enemy_yiLiu_liukou_b | 流寇副手 | yiLiu·qiMeng | lingQiao | 6,800 | 750 | 180 | menpai_basic |
  | enemy_yiLiu_liukou_c | 流寇刀手 | yiLiu·qiMeng | yinRou | 7,000 | 730 | 165 | menpai_basic |
- **dropTable**:`weapon_liqi_long_quan` 0.8 + `item_xinxuejiejing` qty [6,9] 1.0
- **difficultyMultiplier**:3.0
- **baseExpReward**:10,000

#### Ch4-2 · 古道行商(普通关)
- **stage_04_02**(yiLiu·shuLian,3 敌人)
- **biome**:**新加 `frontier`**(玉门关古道驿站)
- **weather**:`clear`
- **prevStageId**:stage_04_01
- **敌人组合**(西北守关把总 + 副手):
  | enemy_yiLiu_guarda | 玉门关把总 | yiLiu·shuLian | gangMeng | 8,500 | 820 | 175 | menpai 系全套 |
  | enemy_yiLiu_guardb | 西凉骑士 | yiLiu·ruMen | lingQiao | 8,000 | 850 | 190 | menpai_basic + skill |
  | enemy_yiLiu_guardc | 商队护卫 | yiLiu·shuLian | yinRou | 8,200 | 800 | 170 | menpai_basic + skill |
- **dropTable**:`weapon_liqi_pan_long_dao` 0.7 + `item_xinxuejiejing` qty [7,10] 1.0
- **difficultyMultiplier**:3.1
- **baseExpReward**:12,000

#### Ch4-3 · 沙海迷踪(普通关)
- **stage_04_03**(yiLiu·jingTong,3 敌人)
- **biome**:**新加 `desert`**(大漠戈壁)
- **weather**:`mist` 复用(沙漠晨雾)— 不引新增 sandstorm enum(memory `feedback_avoid_over_engineer_abstraction`:能复用就不抽新词)
- **prevStageId**:stage_04_02
- **敌人组合**(沙匪头领 + 沙盗):
  | enemy_yiLiu_shafei_a | 沙匪头领 | yiLiu·jingTong | gangMeng | 9,500 | 950 | 180 | menpai 系全套 + ult |
  | enemy_yiLiu_shafei_b | 沙盗刀手 | yiLiu·jingTong | yinRou | 9,000 | 920 | 175 | menpai 系全套 |
  | enemy_yiLiu_shafei_c | 沙盗弓手 | yiLiu·shuLian | lingQiao | 8,800 | 980 | 200 | menpai 系全套 |
- **dropTable**:`weapon_liqi_lian_zi_bian` 0.7 + `accessory_haojiahuo_yu_pei_lao` 0.5 + `item_xinxuejiejing` qty [8,11] 1.0
- **difficultyMultiplier**:3.2
- **baseExpReward**:14,000

#### Ch4-4 · 西凉论剑(小 Boss 关)
- **stage_04_04**(yiLiu·yuanShu,3 敌人,isBossStage=true,narrativeDefeatId)
- **biome**:`drillGround` 复用(西凉武林集会比武场)
- **weather**:`clear`
- **prevStageId**:stage_04_03
- **敌人组合**(西凉武林名宿 + 二副,小 Boss 体例):
  | enemy_yiLiu_xiliangboss | 西凉武林名宿 | yiLiu·yuanShu | gangMeng | 11,500 | 1,050 | 195 | menpai_basic/skill/ult 全套 |
  | enemy_yiLiu_xiliang_a | 武林名宿之徒 | yiLiu·jingTong | lingQiao | 10,500 | 1,000 | 200 | menpai_basic/skill |
  | enemy_yiLiu_xiliang_b | 武林名宿之徒 | yiLiu·jingTong | yinRou | 10,500 | 1,020 | 185 | menpai_basic/skill |
- **dropTable**:`weapon_liqi_lian_zi_bian` 1.0 + `accessory_haojiahuo_yu_pei_lao` 0.6 + `item_xinxuejiejing` qty [9,12] 1.0
- **isBossStage**:true
- **narrativeDefeatId**:stage_04_04_defeat
- **difficultyMultiplier**:3.3
- **baseExpReward**:16,000

#### Ch4-5 · 阳关一决(章末大 Boss · 跨 jueDing)
- **stage_04_05**(yiLiu·dengFeng + jueDing·qiMeng,3 敌人,isBossStage=true,narrativeDefeatId)
- **biome**:**新加 `frontier`**(嘉峪关古关塞)
- **weather**:`night`(关塞夜战,与 Ch3 stage_03_05 night 同感呼应)
- **prevStageId**:stage_04_04
- **敌人组合**(西凉霸主 + 二副,**末 Boss 跨阶 jueDing**):
  | enemy_jueDing_xiliangbazhu | 西凉霸主 | **jueDing·qiMeng** | yinRou | **15,500** | **1,250** | 215 | **skill_yinrou_jianghu_basic/skill/ult**(跨阶 jianghu) |
  | enemy_yiLiu_bazhu_zuofu | 西凉左护法 | yiLiu·dengFeng | gangMeng | 13,000 | 1,150 | 200 | menpai_basic/skill/ult |
  | enemy_yiLiu_bazhu_youfu | 西凉右护法 | yiLiu·dengFeng | lingQiao | 12,500 | 1,100 | 210 | menpai_basic/skill/ult |
- **dropTable**(给玩家进 Ch5 jueDing 准备):
  - `weapon_zhongqi_qing_xu_jian` 1.0(主奖,清虚剑 — 西北秦腔武学之意)
  - `accessory_zhongqi_qing_yu_huan` 0.5
  - `armor_baowu_jin_si_jia` 0.4(雁门关传承,与 Ch3 stage_03_04 lore 呼应)
  - `item_xinxuejiejing` qty [10,14] 1.0
- **isBossStage**:true
- **narrativeDefeatId**:stage_04_05_defeat
- **difficultyMultiplier**:3.5
- **baseExpReward**:20,000

### 1.3 数值红线自查

| 字段 | Ch4 最高值 | §5.4 红线 | 状态 |
|---|---|---|---|
| 敌人单只 HP | 15,500(末 boss) | Boss 50,000+ | ✅ 远低 |
| 敌人单只 Atk | 1,250 | 不直接限,公式约束 | ✅ 普伤上限 8000 内 |
| 装备攻击 | 引用 weapon_zhongqi(unknown 数值待 grep zhongQi 范围) | 2,000 | ✅(spec Phase 2 落 yaml 时再校验)|
| 内力 | yiLiu dengFeng max 5,700;jueDing qiMeng max 6,000+ | 15,000 | ✅ |

---

## 二 · 章首尾 chapter_04.yaml 构想

体例沿 Ch2/Ch3:`id + title + prologue + epilogue` 双段,目标 ~1,300 字。

```yaml
id: chapter_04
title: 西出阳关
prologue: |
  许昌一战后第十七日,李寒到了潼关。
  关楼上「天下第一关」的匾额被风雨打得发白,
  潼关守军没认出他,只当是个过路的剑客,挥手放行。
  
  ...(~600 字:从许昌到潼关再到玉门的心境过渡 + 西北风物 + 留 hook 西凉武人传说)
  
epilogue: |
  嘉峪关的旗子在夜里垂着,被风一阵阵吹得猎猎。
  李寒坐在关楼石阶上,身上几处刀伤还在渗血。
  
  ...(~500 字:与西凉霸主一战的余韵 + 一流→绝顶 境界拐点的暗示 + 留 hook Ch5)
```

**Tier 风格梯度词锚定**(memory `feedback_collab_mode_single_lore_workflow` 7 阶):
- 一流 yiLiu 文风词:**「沉着」「肃杀」「老练」「冷静」**(对照 Ch1 学徒新嫩 / Ch2 三流方知江湖 / Ch3 二流锋芒 → Ch4 一流稳重已成名)
- 不写「网游词」(`feedback_collab_mode_single_lore_workflow`):无 `legendary/epic/master class`
- 西北风物:风沙、烽燧、马蹄、戈壁、关楼、旗影、夜战 — 不写「沙漠地图」「关塞副本」

**字数预算**:prologue ~600 字 + epilogue ~500 字 + 内文标点 ~200 字 ≈ 1,300 字。

---

## 三 · 12 narratives stages 文件

体例沿 Ch3 stage_03_*:`id` + `paragraphs[]`(每段 ~80-150 字)。

| 文件 | 类型 | 字数预算 | 风格锚点 |
|---|---|---|---|
| stage_04_01_opening.yaml | 开场 | ~400 字 | 潼关出/河西走廊初见流寇,沉着推进 |
| stage_04_01_victory.yaml | 战胜 | ~300 字 | 流寇散去,西望沙海 hook 古道 |
| stage_04_02_opening.yaml | 开场 | ~450 字 | 玉门古道遇守关把总,礼节中带肃杀 |
| stage_04_02_victory.yaml | 战胜 | ~320 字 | 守军认输,商队感谢,hook 沙海 |
| stage_04_03_opening.yaml | 开场 | ~480 字 | 大漠迷踪,沙匪伏击,黄沙蔽日 |
| stage_04_03_victory.yaml | 战胜 | ~330 字 | 沙匪溃散,远见嘉峪关影 hook 论剑 |
| stage_04_04_opening.yaml | 小 Boss 开场 | ~540 字 | 西凉武林集会比武场,名宿挑衅 |
| stage_04_04_victory.yaml | 小 Boss 战胜 | ~360 字 | 名宿败北归山,获西凉武人敬意 |
| stage_04_04_defeat.yaml | 小 Boss 战败 | ~300 字 | 比武落败,名宿留全尸退场,胸中怒火 |
| stage_04_05_opening.yaml | 末 Boss 开场 | ~600 字 | 嘉峪关夜战,西凉霸主三人组阵前出现 |
| stage_04_05_victory.yaml | 末 Boss 战胜 | ~440 字 | 霸主败,关楼上夜望长安,境界拐点 |
| stage_04_05_defeat.yaml | 末 Boss 战败 | ~320 字 | 霸主三招破之,夜寒中养伤,师父遗言 |

**字数合计**:~4,840 字(单关均 ~400 字,合 Ch3 单关 ~400 字水准)。

> ⚠ Phase 0 推算单关 ~150 字属 narrative 体例**早期** Ch1 简洁版,Ch3 已达 ~400 字/文件,Ch4 沿 Ch3 体例;但 1.0 P2 总字数 +6-10k 预算下仍合理(本章占 ~4.8k 字,留 Ch5/Ch6 各 ~3k)。

---

## 四 · Boss 设计详 · 西凉霸主三人组

### 4.1 Boss 文化背景

- **西凉霸主**(主 Boss,jueDing qiMeng,school=yinRou):西北武学领袖,身世神秘,流派阴柔(暗合 GDD §4.4 三流派)— 沉默克敌,出手即决,与中原武林正统形成对照
- **左护法**(yiLiu dengFeng,school=gangMeng):刚猛大力斧 — 沉重打击
- **右护法**(yiLiu dengFeng,school=lingQiao):灵巧短戟 — 高速突刺

### 4.2 Boss 战术设计

memory `feedback_wuxia_boss_balance_crosstier`:跨阶才稳触发战败,这里主 Boss 跨阶 jueDing,二副 yiLiu 顶层。玩家方此时:
- 通常 yiLiu·yuanShu / huaJing 起步(完成 Ch4-4 升 ~24-26 级)
- vs 主 Boss(jueDing·qiMeng 29 级,跨 1 阶):
  - 攻方 ×0.7 / 守方 ×1.4(GDD §5.3 境界差距修正)
  - 玩家方需:满级 yiLiu 心法 + 利器装备 +10+ 强化 + 共鸣度晋阶 + 心法相生组合

### 4.3 skillIds 跨阶用 jianghu(已确认有命名)

主 Boss 用 `skill_yinrou_jianghu_*`(江湖秘传 / jueDing 阶 cap),二副 yiLiu 顶层用 `skill_{school}_menpai_*`(门派绝学 / yiLiu cap)。

### 4.4 dropTable 设计哲学

- **主奖**:`weapon_zhongqi_qing_xu_jian` 1.0 dropChance(确给,玩家进 Ch5 jueDing 起步装备)
- **副奖**:`accessory_zhongqi_qing_yu_huan` 0.5(jueDing accessory)
- **传承奖**:`armor_baowu_jin_si_jia` 0.4(GDD §6.6 典故联结,与 Ch3 stage_03_04 雁门 lore 呼应)— **跨章 lore 系统串联**
- **xinxuejiejing**:[10,14] qty 1.0(强化材料)

---

## 五 · EncounterBiome enum 扩 2 个

### 5.1 现有 15 个 biome(`lib/core/domain/enums.dart:212`)

mountainPath / inn / dock / cityWall / escortRoad / teaHouse / smithy / drillGround / alley / temple / mountainForest / swordTomb / cliffWaterfall / cliff / bambooForest

### 5.2 Ch4 新加 2 个

```dart
enum EncounterBiome {
  ...
  desert,          // 大漠戈壁(stage_04_03 沙海迷踪 / 后续 Ch5 西域奇遇 / 1.0 P2 飞升前心魔关)
  frontier,        // 边塞关隘(stage_04_02 玉门古道 / stage_04_05 嘉峪关 / Ch6 北漠草原)
}
```

**单一 commit 在 Phase 2 实装 batch 起手时改**(小范围扩 enum 不破现有调用 + 1 处 enum 解析点)。

### 5.3 是否扩 EncounterWeather?

**不扩**。`sandstorm` 通过 sceneBackgroundPath 视觉表达,enum 复用 `mist`/`night`/`clear` 三个已有值 + biome desert 组合表示风沙意境。memory `feedback_avoid_over_engineer_abstraction`:能复用就不抽新 enum。

### 5.4 encounter 触发 / events 是否补?

Phase 1 起步**不补 encounters.yaml/events**;Ch4 5 关纯 mainline 推进,后续若需边塞 encounter,Phase 2 起草 batch 2.3 再补(参 Phase 0 doc 边塞类 events 现成可复用 15+ 个,本章 mainline 不强依赖)。

---

## 六 · GDD / PROGRESS / ROADMAP_1_0 同步动作清单

memory `feedback_living_doc_state_drift`:行号/状态字段实装当 commit 顺手对齐,别拖下波。

### 6.1 GDD.md 改动(Phase 2 batch 2.4 内做)

| 位置 | 改动 | 行号(待 verify)|
|---|---|---|
| §8.1 表 | **不动**(GDD §8.1 仅列 Demo 3 章,Ch4-6 在 1.0 P2 范畴) | n/a |
| §8.4 表 | **不动**(Demo 主线字数 7000 上限保留 — 字数方案 γ)| n/a |
| §12 | **新加 §12.5 1.0 P2 第二条主线扩 — Ch4 西出阳关(2026-05-21 P1 启动)** 备注 | spec 起草时定位 §12.x 行号 |

### 6.2 PROGRESS.md 顶段校正

**当前(L8)误读表述**:
> 下波:Stage 3 剩 28 张待出图 ... 候选 2 主线扩(第 4 章+5 关) ... Demo §8.4 主线 15→20 上限 + 支撑 1.0 P2 启动

**校正后**:
> 候选 2 主线扩(第 4 章 西出阳关 · **1.0 P2 第二条主线第 1 章**) ... yiLiu 全章 + 末关跨阶 jueDing + 西北边塞(玉门关/河西/大漠/嘉峪关)+ ~3,100 字 narratives

并加 1 行候选 1 待启动状态(Stage 3 剩 28 张场景/心法,等用户 MJ 解封后启动)。

### 6.3 ROADMAP_1_0.md 同步

**当前 P2(L37)**:`§12.4 第二条主线 3 章 15-20 关`

**Phase 2 batch 2.4 加备注**(P2 行下加 1 子项):
> ※ Ch4「西出阳关」(2026-05-21 P1 启动,~3,100 字 / yiLiu 全章 / 跨 jueDing 末 boss):本会话从 1.0 P2 启动桥头堡,详 `docs/handoff/p1_x_chapter4_spec_2026-05-21.md`

---

## 七 · 工作流估时

**预计 Phase 2 全 ~6-10h opus xhigh(分 batch)**:

| Batch | 内容 | 估时 | 触发 |
|---|---|---|---|
| 2.1 | EncounterBiome enum 扩 2 个(desert/frontier)+ enum_localizations + ~12 单测改 1-2 处 | 30-45 min | 必先做(后续 stages.yaml 用 biome 字段)|
| 2.2 | stages.yaml 5 关 entry 写入(5 关 × ~80 行 = ~400 行新增)+ 数值红线测试加 Ch4 case | 1-1.5h | 依赖 2.1 |
| 2.3 | chapter_04.yaml(~1,300 字)+ 12 narratives 文件(~3,500 字)| 3-5h | 用户可介入精修关键段(章首尾 + 末 boss defeat)|
| 2.4 | GDD §12 / PROGRESS / ROADMAP_1_0 同步 + 复读自查 + flutter test/analyze 跑 | 30-60 min | 收尾 |
| 2.5 | closeout doc + commit + push | 15-30 min | 必收 |

**用户可介入点**:
- 章首尾 prologue/epilogue 精修(若文风走偏可指点 Tier 风格梯度词)
- 末 Boss defeat 段落(剧情情感强度,容易写空洞)
- 西凉霸主背景设定(后续 Ch5/Ch6 是否复出 hook)

---

## 八 · 不变量沿用

- GDD §5.4 数值红线 / §5.3 三系锁死 / §5.6 不硬编码 / §6 核心公式
- CLAUDE.md v1.9 单端 Mac+Opus 全权
- Riverpod 3.x / Isar / 不引第三方游戏引擎
- 工作流速度 3 lever(memory `feedback_workflow_speed_levers`)
- memory `feedback_wuxia_boss_balance_crosstier`:章末跨 1-2 阶
- memory `feedback_collab_mode_single_lore_workflow`:Tier 风格梯度
- memory `feedback_living_doc_state_drift`:实装当 commit 顺手对齐 doc 状态

---

## 九 · 风险与挂账

| # | 风险 | 应对 |
|---|---|---|
| R1 | EncounterBiome enum 扩可能影响 enum_localizations 或某些 case 全枚举 switch | Phase 2.1 起手 grep `EncounterBiome\.` 用法,全 switch case 加 default 兜底或显式加新 case |
| R2 | weapon_zhongqi_qing_xu_jian / armor_zhongqi_yin_lin_jia 已存在但 lore 文件可能未配套 | Phase 2.4 收尾 grep `data/lore/weapon_zhongqi_*.yaml`,若缺则补占位「[lore 待补]」 |
| R3 | stages.yaml prevStageId 链条要保持单链(stage_04_01 → stage_04_02 → ...)| Phase 2.2 起草时直接写入,GameRepository._enforceRedLines 会校验,test 兜底 |
| R4 | narratives 字数 ~3,500 字单端写较重,user 介入精修关键段 | 章首尾 + defeat 段用户精修,opening/victory 走 Tier 风格梯度词体例 |
| R5 | 末 Boss 跨阶 jueDing,玩家此时 yiLiu 顶端可能也吃力 | Phase 2 完成后跑红线压测 case(yiLiu·dengFeng + 利器满 + menpai 满 vs jueDing·qiMeng boss),验证胜率 60-80% 合理(模板 memory `feedback_red_line_test_semantics`)|
| R6 | dropTable `weapon_zhongqi_qing_xu_jian` 1.0 dropChance 给玩家进 Ch5 起步,但若 Ch5/Ch6 还没设计装备投放路径会断挡 | spec 注明:**Ch5/Ch6 spec 起草前先核验本批 zhongQi 投放与后续装备体系是否平滑** |

---

## 十 · spec 收尾

- 本 spec 不动代码 / 不动 yaml / 不动 GDD,**仅 docs/handoff/ 1 个 spec doc**
- Phase 2 起草开工前用户**最后审阅**:
  - 5 关数值矩阵(§一)
  - 西凉霸主三人组设计(§四)
  - EncounterBiome enum 扩 2 个(§五)
  - 12 narratives 字数 ~3,500 字预算合理 vs 3,100 字 Phase 0 推算(§三 ⚠ note)
  - 6 风险挂账(§九)
- 用户审阅通过 → 切到 Phase 2 batch 2.1 开始(EncounterBiome enum 扩)

**Phase 1 spec 起草本会话产出:reality check + spec doc 各 1 个,总 ~470 行,无代码改动,可一次 commit 收**。
