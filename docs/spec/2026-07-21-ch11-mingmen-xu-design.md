# Ch11「中州·名门之虚」一流第二章设计

## 定位

- 一流三章(Ch10-12)第二章·承 Ch10「入中原·守拙翁托印看江湖」。
- **文化弧:名门虚实之辨**（Ch11 见「虚」·Ch12 见「实」）·母题「名≠本事」·承 Ch10「守→进」延伸到「名→实」。
- `requiredRealm: yiLiu`（承 Ch10）·章内敌人层 **shuLian→yuanShu** 递进（Ch10 收 shuLian·Ch11 续 jingTong/yuanShu·Ch12 再收 dengFeng）。

## 承接 hook

- 主角带**止水旧印 + 凉铜符**入中州深处·守拙翁托「替我看看这潭水外头的江湖走到哪一步」。
- 踏中州名门场合·见识名门之虚·章尾看透「名不副实」这一步·但照见求「实」的路（承 Ch12）。

## 5 关（踏名门·揭虚名·每关一种「虚」）

| 关 | id | 场景 | 「虚」 | 敌流派/层 | Boss |
|---|---|---|---|---|---|
| 1 | stage_11_01 | 中州名镇·剑会外场 | 徒有架势的名家（排场唬人） | lingQiao·shuLian | — |
| 2 | stage_11_02 | 中州名派山门 | 吃祖上老本的门户（后辈靠门第） | gangMeng·shuLian | — |
| 3 | stage_11_03 | 洛阳镖行/榷场 | 买来的名声（钱/关系堆名头） | yinRou·jingTong | — |
| 4 | stage_11_04 | 名门内里 | 华而不实的名门「绝学」（好看没杀伤） | 混·jingTong/yuanShu | 章中 Boss（stat 门槛·嵩阳关主式） |
| 5 | stage_11_05 | 名宿 | 名震中州却虚有其表 | gangMeng·yuanShu | 末 Boss（真解） |

- Boss 位 **{4,5}**（章中 + 末·同 Ch10）。11_03 非 boss 关保全 5 关有敌队。
- 章首不跨章 `prevStageId`（承 Ch10 收尾自然衔接，链首指向 Ch10 末关）。

## 末 Boss（11_05）+ 真解

- **名宿**：名震中州、实为虚。`school: gangMeng`·`realmLayer: yuanShu`（中州名门堂皇刚猛剑法·威势唬人却没练到真髓）。
- 机制：成名真解是好招，但他没练透；主角首通拦 `chargeSkill`·掉同招真解——**主角练成他没练透的招**（反讽「真解在懂的人手里才是真解」，正打「名≠本事」）。
- 结构复用守拙翁模板：`chargeSkillId = 真解`·`bossPhases` 两相位（1.0 / 0.5 aggressive `onEnterMechanic: chargeCounter`·`titleKey: bossPhase_desperate`）·首通掉真解（`source: mainline_drop`）。
- **真解新写（+1 招·唯一新增）**：中州名门刚猛华丽绝学意象·`style: gangMeng`·`tier: 4`·`type: powerSkill`·`powerMultiplier ~3600`（沿 `skill_zhi_shui_jue`/`skill_chen_sha_yi_jue` 锚·守 ≤8000）·`chargeSkill=dropSkillManual` 双用·proficiency 真解手工高半档。
- 登记 `standaloneBossManualIds` 白名单（`wave_b_content_redline` 配平排除·否则破 2/2/2 流派）。

## feng_juan 处置

- `skill_feng_juan_liu_sha` 继续 `mount_deferred: true` 搁置（大漠灵巧意象不搭中州名门·不强用不强删·留待未来边塞/大漠相关章或最终否决）。

## 止水旧印

- 象征用法：凉铜符（走完的边塞旧路）+ 止水印（守拙翁的守成）对照名门的「虚」；章尾呼应守拙翁「江湖走到哪一步」。**不做强剧情道具/数值物品**（保持象征，零 schema）。

## 复用策略（同 Ch10·敌招/装备零新增）

- 敌招复用一流 `menpai` 系列（三流派 basic/skill/ult 及 fang/nei 变体·池已足）。
- 装备掉落复用 `liQi`（利器 tier4·Ch10 已用）。
- **唯一新增 = 末 Boss 真解 1 招**。

## 叙事纲（13 篇·同 Ch10 体例）

- `chapter_11`：章首（入中州名门世界·带两枚印）+ 章尾（看透名门之虚·承 Ch12 求「实」hook）。
- 10 段 stage（5 关 × opening/victory）+ 2 defeat（11_04 章中 Boss / 11_05 末 Boss）。
- 母题「名≠本事」·守拙翁「守」vs 名门「虚」·主角求「进」求「实」；黑名单词 + 现代词 + 网文腔 grep 0 命中。

## reconcile 面（~26 站点·承 `feedback_wuxia_add_mainline_chapter_reconcile`）

- **count 50→55**：progression_playtest_diagnostic（CSV byte-lock 重生）/ game_repository（mainlineCount 55 / 主线红线含 Boss / prevStageId 单链）/ mainline_narrative_completeness（count + 章循环 1→11）/ balance_simulator / readable_tempo（终章钉 `stage_11_05`）。
- **boss 敌 22→24**·catalog 35→37。
- **skill 计数 3 处**（+1 真解）：game_repository / skill_count_contract（+ GDD 字串「N 招」）/ skill_qi_redline。
- **真解白名单**：standaloneBossManualIds +1。
- **progression 级联**：Lv 位移**逐值实测**（progression_release_budget + progression_idle_horizon 同口径重校·守 < Lv100·fail-fast 迭代禁猜）。
- **生产可见性**：chapter_list `[1..11]` + widget 章卡计数（viewport 扩容）/ main_menu + status_summary 循环 `<=11` / boss_memory_key group index / UiStrings.chapterTitle·Hint switch / strings.dart「十一章」。
- **material 级联**：enhancement_material_supply（结晶掉落 +Ch11 关·守「不足 3 件」软线）。
- **tier 红线**：mainline_stage_curve 加 Ch11→境界映射（cap-agnostic·按 requiredRealm.index）。
- GDD §8.1 章表 + 招式池同步。

## 已知拍板（用户 2026-07-21 全按推荐）

文化弧名门虚实 / 骨架踏名门揭虚名 / 末 Boss school=gangMeng / feng_juan 搁置 / 止水印象征——全定。material 结晶软线放宽（一流章 balance 拍板项，同 Ch10）。
