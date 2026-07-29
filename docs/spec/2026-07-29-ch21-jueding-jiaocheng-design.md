# Ch21「绝顶交程」章级设计 spec — 武圣段收官 · 主线终章 · 六项自主拍板(用户授权·可推翻)

**日期**:2026-07-29(用户外出·授权自主拍板) · **载体**:worktree `ch21-shougong`
**承**:段级 spec `2026-07-28-wusheng-arc-ch19-21-design.md` §10 前瞻 + §13 末 Boss 流派硬约束 · Ch20 章尾(东归入关·「路放下来的地方…在山上」)
**前置实测**:HEAD `adb2df71` · 20 章 100 关 · cap 47 · skill 218/258 · boss 敌 42

## 1. Phase 0 实测(2026-07-29 现测 · 禁转抄)

| 维度 | 实测值 |
|---|---|
| stage_21 存在性 | **0**(净) |
| Ch20 曲线终点 | HP 59000 · 攻 2000 · 速 390 · diffMult 21.8 · exp Σ505 · cumExp 5074 |
| **tier7 敌招闲置** | **仅剩 4 门且全 lingQiao**:`lingqiao_chuanshuo_fang_{basic,skill,ult}` + `lingqiao_chuanshuo_ult` |
| 真解倍率 canon | `skills.yaml:3057`「**Ch21 只余 7800 一档**」(tier7 cap 8000 = §5.4 硬线) |
| 神物账 | 11 件已投 8 · **余 3 恰 1 武 1 甲 1 饰**:`weapon_shenwu_kong_que_ling` / `armor_shenwu_tian_can_bao_jia` / `accessory_shenwu_tian_yuan_zhi` |
| cap 49 语义 | 武圣·**登峰**(dengFeng·`numbers.yaml:277`)= 飞升条件③ `founder.realm == wuSheng·dengFeng` 要求层 → 抬到 49 使其**首次可达** |
| **surviveTicks 表现层** | **实测零玩家可见面**——详 §7,本章最大工程项 |
| 章名体例 | 20 章现测:多为四字地名/意象;Ch1「学武出山」为对仗锚 |

## 2. 章级拍板(六项 · 自主全拍 · 用户回来可逐项推翻)

| # | 决策点 | 拍定 | 理由 |
|---|---|---|---|
| 1 | **章名** | **「绝顶交程」** | 「交程」出自候峰翁 canon(`chapter_13:12`「把下一程亲手交出去」),与 Ch20 关名「接程」(20_04)成对;「绝顶」点明地点=Ch13 那座山 |
| 2 | **关序** | 潼关→黄河→嵩山→樵径→**绝顶平台** | **Ch20 章尾已写死**(「潼关，黄河，嵩山——一程一程铺回山门去」);樵径=`chapter_13:prologue`「被草埋了半截的樵径」;末关回 Ch13_05 同一处 |
| 3 | **末 Boss** | **循符而上的年轻人**(wuSheng·**dengFeng**=cap 49 同层·**lingQiao**) | 兑现 `chapter_14:20`「符面向着来路,**等下一个走得上来的人**」;lingQiao 由**招池与 §13 约束双重锁定**(闲置招全 lingQiao,且 §13 禁 yinRou);玩家此刻坐在候峰翁当年的位置上 |
| 4 | **真解** | **`skill_shan_wai_wu_shan`「山外无山」**(tier7·lingQiao·mult **7800**·mainline_drop·chargeSkill 双用) | 与 Ch13 候峰翁真解「一览众山」(4800)严格成对;兑现 `chapter_14:8`「绝顶之上没有更高的山了,可有比山更远的东西」;7800=canon 唯一预留档 |
| 5 | **神物第三批 3 件** | 孔雀翎 / 天蚕宝甲 / 天元指(1 武 1 甲 1 饰) | 11 件收口清零,段级「自平衡」预测兑现 |
| 6 | **机制层** | 21_04 vuln 0.16 + chargeCounter 两相位;21_05 vuln 0.10 + cycleVulnerability 2:0.05 + 两相位 + **`surviveTicks` 主线首用** | 承 Ch20(0.18/0.12/0.06)逐章收一档;终章换胜负轴=段级拍板 B;0.05 = §5.4 承伤乘子**下界本身**,收官到底不再有下一档 |

**cap 47→49**(within-tier·wuSheng 内第三档·releaseTier 不变·**非 cross-tier**);49 = 绝对终点,无第 50 层。

## 3. 五关设计

| 关 | 名 | 敌 | 层 | school | HP | 攻 | 速 | diffMult | exp | 敌招 |
|---|---|---|---|---|---|---|---|---|---|---|
| 21_01 | 潼关 | 关河卒(新) | jingTong | gangMeng | 59100 | 2000 | 392 | 22.0 | 92 | gangmeng basic+skill(复用) |
| 21_02 | 黄河渡 | 摆渡老手(新) | jingTong | yinRou | 59200 | 2000 | 394 | 22.2 | 94 | yinrou basic+skill(复用) |
| 21_03 | 嵩山旧坪 | 论剑后人(新) | yuanShu | lingQiao | 59300 | 2000 | 396 | 22.4 | 96 | lingqiao basic+skill(复用) |
| 21_04 | 樵径 | **拦径老仆**(新) | yuanShu | gangMeng | 59400 | 2000 | 398 | 22.6 | 112 | gangmeng basic+skill+**ult**·chargeSkill=ult·Boss |
| 21_05 | 绝顶平台 | **循符少年**(新) | **dengFeng** | **lingQiao** | **59500** | 2000 | 400 | 22.8 | 136 | **lingqiao_fang 组×3**(闲置首用)+真解双用·Boss·**surviveTicks** |

- 曲线延体例:HP +100 步(末 **59500** = 段级 §7 预算终点·<60000 硬线)· 速 +2 · diffMult +0.2 · exp Σ**530**(cumExp 5074→**5604**)。
- **敌招零新增**(段级拍板 4A):21_05 独占闲置 `lingqiao_chuanshuo_fang` 组;21_04 chargeSkill 复用 `gangmeng_chuanshuo_ult`(Ch20 20_03 已用,复用不违「零新增」)。
- **末 Boss 流派 = lingQiao,打破 18_04/18_05/19_05/20_05 连续四关 yinRou**(段级 §13 硬约束兑现)。
- requiredRealm 全 wuSheng · 21_01 无 prevStageId · Boss 位 {4,5}。

## 4. 叙事(13 篇 · 回望弧收束 · ~6000 字带内)

- chapter_21 卷首尾 + 5 opening + 5 victory + 21_04/21_05 defeat = 13 篇。
- **题眼:交程**——玩家成为新的候峰翁。候峰翁当年「登到最高处却不走,坐了几十年,只为等一个走得上来的人」(`chapter_13:12`);今日玩家坐在同一块石头旁,等到了那个人。
- **铜符 motif 收束**:`chapter_14:20`「石下的凉铜符静静压着,符面向着来路,等下一个走得上来的人」——本章那个人到了。符不再是"留下的",是"交出去的"。
- **少年不认得他**:循符而上的年轻人以为峰顶坐的还是那个等人的老人。玩家不纠正。
- 章尾 hook 指向**传承/二周目**,不指向下一段(没有下一段了)。
- **动笔前必核 canon(Phase 0.5)**:Ch13/Ch14 全文 + Ch5/Ch6 嵩山段 + Ch20 章尾;**不得顺手编设定**,尤其见 §8 地理存疑项。
- 风格词(wuSheng 文化弧):湛然/寂照/圆融/化机 · 黑名单/现代词 grep 0。

## 5. reconcile 站点(Ch20 清单 20→21 平移 · within-tier 版 · 行号实装前重定位)

- count 100→**105**:CSV byte-lock 重生 / `game_repository_test`(两处) / `mainline_narrative_completeness` 章循环 [1..21] / `chapter_list_screen_test` / `enhancement_material_supply_test` / `progression_playtest_diagnostic_test:17` / `readable_first_clear_tempo_diagnostic_test:110` 终章 20_05→21_05 / `progression_release_budget_test`。
- cap 断言 `numbers_config_progression_release_cap_test:35,42` 47→**49**。
- boss 敌 42→**44** / catalog 55→**57** / skill 计数 **218→219 / 258→259 三站点**(`skill_count_contract_test:12,28,38,43,45` + `skill_qi_redline_test:57` + `game_repository`)。
- progression 逐值**实测禁猜**(链式锚点,memory `feedback_multi_anchor_test_actual_attribution`):首通 cumExp / idle_horizon 缺口+下沿(已连续四章下调 45→40→35→30→25,本章续测)/ 结晶上界。
- 生产可见性:`chapter_list _chapters`+21 / `strings` chapter21Title·Hint+两 switch / `mainMenuMainlineHint`「21 章 105 关」/ `status_summary_provider:156` ≤21 / boss_memory chNum。
- GDD 状态块(cap 49 / 21 章 105 关)+ §8.1 章表 + 招式池 · wave_b 白名单 + 新真解 · known_missing +11 图(前缀 `jueding_*`)+ standee overrides +5。

## 6. 红线守卫

- Boss HP 59500 < 60000 · 攻钉 2000 · 真解 7800 ≤8000 · 敌招全 tier7 不降档。
- 21_01 无 prevStageId · 末 Boss chargeSkillId ∈ skillIds 双用 canon · cycleVulnerability key=周目数(≥2)且必先配 vulnerability · **cycle mult 0.05 = §5.4 下界,不得再低**。
- `surviveTicks` 须配 ticks>0(`stage_win_condition.dart:28` 强校验)。
- 机制只走减伤/新胜负条件方向(§5.4 例外条款);在线=离线;§5.1 反主流不碰。
- 破坏证红 commit 后做:真解 mult 7800→9000 RED / 摘 dropSkillManualId RED,各还原复绿。

## 7. surviveTicks 表现层缺口(本章最大工程项 · Phase 0 实测推翻段级 §12 的「零新代码」)

段级 spec §12 称 `surviveTicks` 是「零新代码」。**实测:只对战斗逻辑成立,表现层是空的。**

| 层 | 现状(实测) |
|---|---|
| schema | `stage_win_condition.dart:9,15,25-30` 已有 ✅ |
| 灌入 | `stage_entry_flow.dart:530,543,551` → `battle_state.dart:770` ✅ |
| 判定 | `default_ground_strategy.dart:106-107` 逐 tick ✅ |
| **战斗 HUD** | **零 widget 读 winCondition** ❌ |
| **胜利结算文案** | **零处区分 surviveTicks 与 defeatAll** ❌ |

现仅心魔 07 使用,靠 `InnerDemonStrategy` 独立呈现路径兜底,**不可直接复用于主线**。
主线首用若不补,玩家看到的是「打不死的 Boss 忽然赢了」——机制存在但不可读,违 §5.7「让玩家先感受问题」的前提是问题得可感知。

**本章必做**:① 战斗 HUD 增「撑住 N 拍」条件条(读 `BattleState.winCondition`);② 胜利结算文案区分「守住了」与「击败」;③ 文案进 `UiStrings` 不散写;④ 补 widget 测覆盖两种 winCondition 呈现。**这是 Ch21 与前 20 章最大的不同:前 20 章是内容批,本章带一个真表现层特性。**

## 8. 存疑项(记录不自行解决 · 留用户拍板)

**飞升地点 canon 冲突**:`ascension_intro`/`ascension_complete`(P2.3 既有)把飞升演在**昆仑山顶**青石旁(四件物事所在,= `stage_06_05` 地点);但 Ch20 章尾指的回程是**往东**(潼关→黄河→嵩山→山门),昆仑在极西,方向相反。

**本章处置(最小风险)**:Ch21 **不演飞升本身**,只走 Ch20 写死的东归路线回绝顶交程;飞升保持独立终局事件不动,cap 抬到 49 使其**首次可触发**——这正是段级 §3 说的「首次对玩家开放」而非「在 Ch21 里演出」。**零改既有 ascension 叙事,零编新地理。**

若用户希望 Ch21 直接承接飞升演出,则需先拍板飞升地点(改 ascension 叙事 or 改 Ch20 章尾),再动本章叙事——**该决策不在本 spec 自主拍板范围内**。
