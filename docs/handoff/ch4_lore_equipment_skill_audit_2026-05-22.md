# Ch4 lore / equipment / skill 联结审计(2026-05-22)

> 派单方:Mac Opus 4.7(8h autonomous 工作流 B2 批次)
> 审计目标:验 Ch4 stages.yaml 5 关 dropTable / enemyTeam.skillIds 引用全部命中,无 broken reference

---

## TL;DR

**Ch4 数据层零 broken reference ✅**。7/7 equipment + 7/7 lore + 12/12 skill 引用全命中,1 inventoryItem inline 处理符合体例。

---

## 一 · Ch4 stages.yaml dropTable equipment 引用(7 件)

| equipmentDefId | equipment.yaml | lore/ 文件 | 引用 stage |
|---|---|---|---|
| weapon_liqi_long_quan | ✅ | ✅ 47 行 | stage_04_01 dropChance 0.8 |
| weapon_liqi_pan_long_dao | ✅ | ✅ 46 行 | stage_04_02 dropChance 0.7 |
| weapon_liqi_lian_zi_bian | ✅ | ✅ 45 行 | stage_04_03 dropChance 0.7 / stage_04_04 dropChance 1.0 |
| accessory_haojiahuo_yu_pei_lao | ✅ | ✅ 45 行 | stage_04_03 dropChance 0.5 / stage_04_04 dropChance 0.6 |
| **weapon_zhongqi_qing_xu_jian**(末 Boss 主奖) | ✅ | ✅ 50 行 | stage_04_05 dropChance 1.0(给 Ch5 jueDing 起步) |
| **accessory_zhongqi_qing_yu_huan**(末 Boss 副奖) | ✅ | ✅ 49 行 | stage_04_05 dropChance 0.5 |
| **armor_baowu_jin_si_jia**(末 Boss 传承奖) | ✅ | ✅ 49 行 | stage_04_05 dropChance 0.4(GDD §6.6 典故联结 Ch3 stage_03_04 雁门 lore 跨章串联)|

**结论**:7/7 全在 equipment.yaml 定义 + lore/ 文件全在(累计 lore ~330 行),无缺失。

---

## 二 · Ch4 stages.yaml enemyTeam skillIds 引用(12 个)

| skillId | skills.yaml | 引用 stage |
|---|---|---|
| skill_gangmeng_menpai_basic | ✅ | stage_04_01/02/04/05 多处 |
| skill_gangmeng_menpai_skill | ✅ | stage_04_01/02/04/05 多处 |
| skill_gangmeng_menpai_ult | ✅ | stage_04_03/04/05 |
| skill_lingqiao_menpai_basic | ✅ | stage_04_01/02/03 多处 |
| skill_lingqiao_menpai_skill | ✅ | stage_04_03/04/05 |
| skill_lingqiao_menpai_ult | ✅ | stage_04_03/04/05 |
| skill_yinrou_menpai_basic | ✅ | stage_04_01/02/03/04 多处 |
| skill_yinrou_menpai_skill | ✅ | stage_04_02/03/04 |
| skill_yinrou_menpai_ult | ✅ | stage_04_03/04 |
| **skill_yinrou_jianghu_basic**(jueDing 跨阶 skill) | ✅ | stage_04_05 西凉霸主主 boss |
| **skill_yinrou_jianghu_skill** | ✅ | stage_04_05 西凉霸主主 boss |
| **skill_yinrou_jianghu_ult** | ✅ | stage_04_05 西凉霸主主 boss |

**结论**:12/12 全在 skills.yaml 定义。**末 Boss 西凉霸主 jueDing·qiMeng 跨阶用 `skill_yinrou_jianghu_*`**(江湖秘传阶 / jueDing cap)— 符合 spec §四「skillIds 跨阶用 jianghu」设计。

---

## 三 · Ch4 inventoryItem 引用(1 项)

| inventoryItemDefId | 定义位置 | 引用 stage |
|---|---|---|
| **item_xinxuejiejing**(心血结晶) | `lib/core/domain/enums.dart:294` switch case + `lib/features/mainline/presentation/stage_entry_flow.dart:549` ItemType.xinXueJieJing | stage_04_01..05 全 5 关 dropChance 1.0(qty 6→14 阶梯) |

**结论**:item_xinxuejiejing **不在 data/*.yaml 定义**(全项目无 inventory.yaml),走 lib/ inline 硬编码 ItemType enum + GameRepository.applyInventoryDrop 处理。Phase2SeedService 也有引用(L765 `..defId = 'item_xinxuejiejing'`)。**这是项目既有体例**,不属 Ch4 引入的 broken reference。

> 若 1.0 P2 后扩 inventory 系统,建议 `data/inventory.yaml` schema 化(memory `feedback_avoid_over_engineer_abstraction`:能复用就不抽新 yaml,但 ≥5 个 item 时建议抽 yaml)。Demo + Ch4 仅 1 item,不抽。

---

## 四 · Ch4 narrative 联结 stages.yaml(13 文件)

| stage | narrativeOpeningId | narrativeVictoryId | narrativeDefeatId |
|---|---|---|---|
| stage_04_01 | ✅ stage_04_01_opening.yaml | ✅ stage_04_01_victory.yaml | — |
| stage_04_02 | ✅ stage_04_02_opening.yaml | ✅ stage_04_02_victory.yaml | — |
| stage_04_03 | ✅ stage_04_03_opening.yaml | ✅ stage_04_03_victory.yaml | — |
| stage_04_04 | ✅ stage_04_04_opening.yaml | ✅ stage_04_04_victory.yaml | ✅ stage_04_04_defeat.yaml |
| stage_04_05 | ✅ stage_04_05_opening.yaml | ✅ stage_04_05_victory.yaml | ✅ stage_04_05_defeat.yaml |

**结论**:5 关 narrative 字段锚定全 12 个 id 对应文件存在(opening 5 + victory 5 + defeat 2 = 12)。chapter_04.yaml 独立 1 文件。**13/13 narrative 联结全通**。

---

## 五 · Ch4 跨章 lore 联结

| 跨章 lore | 联结点 | 状态 |
|---|---|---|
| `armor_baowu_jin_si_jia`(stage_04_05 末 Boss 传承奖) | Ch3 stage_03_04 雁门 lore 跨章串联(GDD §6.6 典故联结) | ✅ lore 文件存在(`data/lore/armor_baowu_jin_si_jia.yaml` 49 行)— 实际跨章 lore 内容是否提雁门需读 lore 文件细节,但 yaml 联结已通 |

**建议**:1.0 P2 Ch5/Ch6 spec 起草时,**armor_baowu_jin_si_jia lore 内容**是否补「李寒西出阳关获此甲」一笔承接,留 spec 阶段考虑。

---

## 六 · audit 总览

- **lib/ 引用**:Ch4 引入的 EncounterBiome desert/frontier 2 enum + game_repository 红线放开 4 章 20 关 + chapter_list_screen 4 章 + strings.dart Ch4 title/hint — 全在 lib/ 内消费,无 dangling reference
- **data/ 引用**:Ch4 stages.yaml 5 关 + narrative 13 文件 + dropTable 引用 7 equipment + skillIds 引用 12 skill + 1 inventoryItem — **零 broken reference** ✅
- **test/ 引用**:Ch4 ch4_r5_crosstier_redline_test 引用 stages.yaml stage_04_05 + buildExtremum 模板复用 — pass ✅
- **lore/ 联结**:7/7 equipment lore 文件全在(~330 行典故内容已落)— Ch4 dropTable 装备**典故文化承载完整** ✅

**Ch4 1.0 P2 第二条主线第 1 章数据层完整度 100% ✅**

---

## 七 · 1.0 P2 后续待办(本 audit 暴露)

| 待办 | 触发时机 | 优先级 |
|---|---|---|
| Ch5 spec 起草前**审 zhongQi 后续 weapon 投放路径**(Ch5/Ch6 yiLiu→jueDing→zongShi 装备阶梯连续性)| Ch5 Phase 0 reality check | 高(避免 Ch4 落的 zhongQi 后续断挡) |
| `armor_baowu_jin_si_jia` lore 文件**补 Ch4 西出阳关获此甲**一笔承接(若 1.0 P2 决定串联) | Ch5 spec 起草时讨论 | 中 |
| `data/inventory.yaml` schema 化决议(扩 inventory 系统时) | 1.0 P3+ 出现第 2 个 item 时 | 低 |

---

**Ch4 联结审计完成 ✅** → 8h-C 批次 wuxia_idle 项目 stage_audit 续起。
