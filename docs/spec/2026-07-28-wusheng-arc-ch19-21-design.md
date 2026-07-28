# 武圣段(Ch19-21)设计 spec — 主线终段 · 待拍板

**日期**:2026-07-28 · **载体**:main 直落(bg 会话·纯文档)
**境界阶**:武圣(wuSheng·绝对层 43-49·终极境界)· 主线 Ch19-21 三章 · 承 Ch18「阳关故人」
**状态**:**待拍板**(本 spec 只做 Phase 0 实测 + 候选与推荐,零代码改动)
**前置实测**:HEAD `cec7cd1a` · analyze EXIT=0 · 全量 4712/0 · 18 章 90 关 · cap 42

---

## 1. Phase 0 实测(2026-07-28 现测 · 禁转抄)

| 维度 | 实测值 | 出处 |
|---|---|---|
| 发布上限 | **42**(zongShi·dengFeng) | `numbers.yaml:206` |
| 主线规模 | **18 章 90 关** | `stages.yaml` mainline 计数 |
| 段构体例 | 每段恰 3 章,requiredRealm 逐段递进 | 实测 Ch1-3 xueTu / 4-6 sanLiu / 7-9 erLiu / 10-12 yiLiu / 13-15 jueDing / 16-18 zongShi |
| 武圣层表 | abs **43-49** · defense_rate **0.35** · equip cap **shenWu** · tech cap **chuanShuoShenGong** | `numbers.yaml:465-495` |
| tier7 招池 | **21 招已存在**(9 基础 + 9 fang + 3 nei)· 全 `source: technique` | `skills.yaml:833-960, 2359-2480, 2739-2775` |
| tier7 招已用组 | 仅 `yinrou_chuanshuo_fang_*`(Ch6 昆仑山顶副手)→ **6 组 18 招未用** | `stages.yaml:1532/1541/1546` |
| tier7 心法 | **7 门已写**(刚猛/灵巧/阴柔传说 + 3 fang + 混沌功) | `techniques.yaml:282-310, 572-600, 691` |
| 神物装备 | **11 件已写 · dropTable 命中全部 0**(零投放) | `equipment.yaml` `tier: shenWu` ×11 |
| **tier7 drop/fragment/gauntlet 招** | **0 门** | 全池 tier 分布实测(tier1-6 各有,tier7 空) |
| mount_deferred | **全仓 0**(Ch18 收编后归零) | `grep 'mount_deferred: true' data/` = 0 |
| 闭关图 | 5 张 · 最高 `required_realm: zongShi`(断崖绝壁) | `numbers.yaml:1153` |
| skill 计数 | genericIds **216** / merged **256** / skillDefs **256** | `skill_count_contract_test:28,38` `skill_qi_redline_test:57` |
| 数值头寸 | Boss HP 59500(硬线 60000·余 500)· 敌攻 **2000 已用尽** | Ch18 实装值 |

**两条最重要的结论**:
1. **cross-tier 红线⑦风险 = 零**。tier7 无任何 drop/fragment/gauntlet 招,releaseTier zongShi→wuSheng 不会暴露未挂载招——宗师段当时有 2 门 tier6 fragment 必须挂载,本段没有这笔债。
2. **敌招可零新增**。tier7 池 6 组 18 招闲置,足够三章用;宗师段当时 tier6 敌招 0 门须新写 9 招,本段不必。

## 2. 进度口径澄清(防误判 · 与 cap 语义相关)

- **全内容参考路线终态 = Lv121 / 绝对层 13(三流·化境)/ 层内余量 75**(`progression_idle_horizon_simulation_test:59-68`)。
- 即 **cap 是「成长上界」不是玩家到达点**;玩家靠挂机爬境界(Lv121→Lv141 缺口 4425 EXP ≈ 实测 37.3/38.5/37.9 天墙钟)。
- **推论:抬 cap 42→49 不改变玩家实际进度曲线**,它改的是 releaseTier 判据(三系锁死上界)与内容定义上界。不要把「抬 cap」误读成「玩家马上能到 49」。

## 3. 飞升耦合(本段最大设计决策)

飞升 eligibility 三条件并存(`numbers.yaml:1812-1832` · `AscendService.computeEligibility` 消费):

1. `stage_inner_demon_07` cleared — 已可达
2. `stage_06_05` cleared — 已可达
3. **`founder.realm == wuSheng·dengFeng`(abs 49)** — **当前 cap 42 → 永不可达**

**故 Ch21 把 cap 抬到 49 = 飞升/传承系统第一次对玩家真正开放**,主线收官与二周目循环在同一拍上。系统侧 P2.3+P5+ 已完整实装(多代飞升/真传位/遗物 transfer 四规则),**零新实装**,只差 cap。

**stale 注释待订正**(实装批顺修):`numbers.yaml:1392`「飞升渡劫,Demo 不实现」、`masters.yaml:3`「飞升机制 Demo 不做」、`equipment.yaml:17`「Demo 玩家境界 ≤ zongShi 不可装备」——三处均已被 P5+ 实装与本段 cap 抬升推翻。

## 4. 机制层框架(数值轴已尽 · 宗师段拍板 1 的延续)

- Boss HP 只剩 500 头寸(59500→60000 硬线)、敌攻 2000 已用尽 → **武圣段难度 100% 走机制层**,这正是宗师段段级拍板 1 预言的「武圣段同适用」。
- 可用机制(零 schema 扩展):`vulnerability.outOfWindowDamageMult` + `cycleVulnerability` + `bossPhases` chargeCounter 相位。宗师段已把 0.20(教学)→0.12(收官)档走完,武圣段须往**复合方向**取(ward×vuln 复合 ≈ 塔 floor30 的 0.03 档 / cycleVulnerability 周目加压 / 新胜负条件如心魔 07 限时生存)。
- tier7 招 cap = **8000** = §5.4 全局硬红线本身。真解倍率上限即 8000(宗师段真解 6400),**没有上浮空间了**,这也是数值轴终点的另一面。

## 5. 叙事弧候选(Ch18 hook 已定向)

Ch18 章尾原文(`chapter_18.yaml` 卷尾)已把方向钉死:

> 「西边到这里就到头了。**人间的路走到头,剩下的那一段,不在东西南北里**。」

即 **武圣段不是地理续行**(不再"往哪个方向走")。三个候选:

| # | 候选 | 说明 | 推荐 |
|---|---|---|---|
| A | **回望弧「不在东西南北里」** | 不去新地方,而是回到走过的地方重新看(嵩山/昆仑/中原);终局对手是"路本身"与前代人 | **推荐** — 直接兑现 Ch18 hook 原句,且与飞升"传承"主题同构:走到头的人开始交棒 |
| B | 昆仑纵深弧 | 承 Ch6 昆仑山顶,往更高处去 | 仍是地理续行,与 hook 字面冲突 |
| C | 心魔/内景弧 | 完全内向,对手是自己 | 与既有心魔支线(inner_demon 01-07)撞主题 |

风格词(wuSheng·文化弧):「湛然 / 寂照 / 圆融 / 化机」(`ascension_lineage_chant.yaml:4` 已登记同一组词,与飞升叙事天然接续)。

## 6. 段级待拍板项(逐项带推荐)

| # | 决策点 | 候选 | 推荐 |
|---|---|---|---|
| 1 | **段构** | A: Ch19-21 三章(沿七段×三章体例,完成 21 章 105 关全闭环)/ B: 更多章 | **A** — 六段全部恰 3 章,体例锁死;21 章 = 7 阶 ×3,结构自洽 |
| 2 | **cap 轨迹** | A: 42→**45**(Ch19·cross-tier)→**47**(Ch20)→**49**(Ch21 封顶) / B: 其他分配 | **A** — 与宗师段 38/40/42 = shuLian/yuanShu/dengFeng 同体例;49 = 绝对终点无第 50 层 |
| 3 | **飞升接线** | A: Ch21 收官即开飞升(cap 49 自然满足条件③,零新实装)/ B: 抬 cap 但另设门槛推迟 | **A** — 系统已实装且闲置,主线收官与传承循环同拍是最强收束;B 等于继续雪藏已完成的系统 |
| 4 | **敌招** | A: 零新增,复用 tier7 6 组 18 招 / B: 新写 fang/nei 之外的第 7-9 组 | **A** — 池子够用,且宗师段"新写 9 招"是 tier6 敌招为 0 的被迫之举,本段没这问题 |
| 5 | **真解** | A: 新写 tier7 mainline_drop ×3(每章 1·mult ≤8000)/ B: 收编既有招 | **A** — tier7 drop 招现为 0 门,无可收编对象;终段真解须新写 |
| 6 | **神物投放** | A: 11 件分三章 dropTable(三系锁死硬要求)/ B: 部分投放 | **A** — cross-tier 后玩家可装神物却无处获得 = 死内容;11 件恰好三章分配 |
| 7 | **机制层密度** | A: 复合机制(ward×vuln)+ 终关新胜负条件 / B: 沿用 0.12 单档 | **A** — 0.12 档宗师段已用过,终段须有新台阶;但**须探针实测校准**,不预先钉值 |
| 8 | **武圣闭关图** | A: 不加第 6 张(断崖绝壁 zongShi 已覆盖)/ B: 加武圣专属图 | **A** — GDD §8.3 闭关图 5 张是内容量表既定值;加图属独立需求,不搭车 |
| 9 | **叙事弧** | 见 §5 三候选 | **A 回望弧** |

## 7. Ch19 章细化(拍板后细化 · 本 spec 只登记框架)

- 定位:武圣段首章 · **cross-tier**(cap 42→45)· requiredRealm: wuSheng · 三系锁死:武圣↔神物↔传说神功。
- 敌层 qiMeng→shuLian 递进(照 Ch13/Ch16 体例)· Boss 位 {4,5} · `stage_19_01` 不跨章 prevStageId。
- HP/Atk:段首回落照体例,但**上界已封顶**(HP ≤59500 / 攻 ≤2000)→ 三章 HP 走 ~58000/59000/59500,攻全段钉 2000,难度全部由机制承担。
- 真解新写 tier7 ×1(mult 候选 7000-8000·避撞须 grep 0 命中)· 神物 dropTable 首批投放。
- 叙事 13 篇(章首 + 10 段 stage + 2 defeat)· 黑名单/现代词 grep 0。

## 8. Ch19 reconcile 面(cross-tier 全套 · 实装前重跑 Phase-0 复定行号)

- **count 90→95**:playtest CSV byte-lock 重生 / `game_repository_test` mainlineCount(≥3 处)/ `mainline_narrative_completeness` + 章循环 [1..19] / `balance_simulator` / `readable_tempo` 终章 `stage_18_05`→`stage_19_05`。
- **boss 敌 38→40** / **catalog 51→53** / **skill 计数 216→217·256→257 三站点 + GDD 字串** / **wave_b 白名单** +新真解。
- **cap 42→45 四站点**(memory `feedback_wuxia_release_cap_raise_reconcile`)+ **releaseTier zongShi→wuSheng cross-tier 全套**:挂载完备(§1 实测零暴露,仍须复跑证)/ R5.3 cap-agnostic / stale 文案 grep(§3 三处 + `Lv100`/`停在.*层`)/ 心法·装备侧完备性测。
- **progression 逐值实测禁猜**:`release_budget` 首通 Lv105→? / 全内容 Lv121→? · `idle_horizon` 缺口 4425 位移 · `enhancement_material_supply` 结晶上界。
- **生产可见性**:`chapter_list_screen._chapters` [1..19] / `strings.dart` chapter19Title·Hint + 两 switch / mainMenuHint「18 章 90 关」→「19 章 95 关」/ `main_menu`·`status_summary` ≤19 / `boss_memory_key` chNum=19。
- **GDD 头部当前状态块必更**(cap 45 / 19 章 95 关 / 实测锚 · `truth_source_guard_test` 自动拦)+ §8.1 章表 + 招式池。
- **美术**:`known_missing_assets` 登记 11 图(5 敌 + cover + 5 叙事背景)· `character_avatar._battleStandeeOverrides` 补 5 敌自映射(memory 已记该中间态坑)。

## 9. 红线守卫

- Boss HP ≤59500 < 60000 · 敌攻 ≤2000 · 真解 ≤8000(= 全局硬线本身,无余量)· 敌招 tier7 cap 8000。
- 三系锁死:武圣↔神物↔传说神功,敌招全 tier7 档不降档充数。
- `stage_19_01` 缺 prevStageId · 末 Boss `chargeSkillId` 与 `onEnterMechanic: chargeCounter` 成对 · stat 门槛 Boss 不配 `bossPhases`。
- 在线=离线 · §5.1 反主流不碰 · 机制层只走减伤/新胜负条件方向,不膨胀伤害数字(§5.4 例外条款)。

## 10. Ch20/21 前瞻(留各自章 spec 终拍)

- **Ch20**(cap 45→47):中段 · 机制复合化 · 真解 ×1 · 神物第二批。
- **Ch21**(cap 47→**49 封顶**):**主线终章** · 真解 ×1 · 神物第三批 · 末 Boss 复合机制 + 新胜负条件 · **飞升三条件在此全满足**,章尾 hook 指向传承/二周目而非下一段(没有下一段了)。

## 11. 实装建议

- 拍板后按 Ch16-18 体例:每章 coupled xhigh 批一次做完 · 章批 → 美术批 → webp 清账批 三段式。
- 实装前必重跑 Phase-0 grep 复定本 spec 全部行号(本 spec 行号 2026-07-28 实测,会 drift)。
- 必读 memory:`feedback_wuxia_add_mainline_chapter_reconcile` / `feedback_wuxia_release_cap_raise_reconcile` / `feedback_wuxia_boss_balance_crosstier` / `reference_anti_hallucination`。
- Ch19 是 cross-tier 首章,**破坏证红在 commit 后做**(真解 mult 越 8000 → RED → 还原复绿)。
