# Ch13「绝顶段首章」设计 spec（草稿 · 绝顶段开篇 · 待拍板稿）

**日期**：2026-07-22 · **分支**：kimi/jueding-spec-20260722（worktree 纯文档）
**境界阶**：绝顶（jueDing·第 5 境界，绝对层 29-35）· 主线第 13 章
**状态**：草稿·全部拍板点开放（逐项【待拍板】，用户拍板后转正式）

---

## 定位
- **绝顶段首章**（承一流三章 Ch10-12 收官·cap 28=一流·登峰 dengFeng 封顶，`numbers.yaml:206`）。
- `requiredRealm: jueDing`（**新境界 tier**，非 within-tier 抬层）·章内敌人层 **qiMeng→shuLian** 递进（照 Ch10 一流首章模板：01-02 启蒙 / 03-04 入门 / 05 熟练）。
- 三系锁死（GDD §3.4:175-187）：绝顶 ↔ 重器 zhongQi（`numbers.yaml:394`）↔ 江湖秘传 jiangHuMiChuan（`numbers.yaml:395`）。
- 章名【待拍板】（见 §10 #1，推荐「山外青山」）。

## 承接 hook
- Ch12 卷尾（`chapter_12.yaml` epilogue）：虚实两半看全，守拙翁托付已能回一句「走到了名下终究要有实这一步」；「野店外是中州再往深、再往高的去处……往上的那一程，才刚要起脚」。Ch13 = **起脚往上**。
- 止水旧印 + 凉铜符 **跨段 motif 续带**（Ch12 spec §止水印象征定调：保持象征·零 schema·不做数值道具）；守拙翁托付线已收束，不复活，只作「主角替人看江湖→自己走到被看的位置」的镜像底色。
- 绵里藏针真解（`skill_mian_li_cang_zhen`）已入手，与止水诀/鎏金诀并列为「看全虚实」的三卷凭据。

## 5 关（登绝顶路·每关一种「绝顶」侧面）
| 关 | id | 场景/biome（全复用现有图） | 「绝顶」侧面 | 流派/层 | Boss | HP/Atk/Spd |
|---|---|---|---|---|---|---|
| 1 | stage_13_01 | 山脚茶棚(teaHouse) | 见过绝顶的人（退隐老把式·只讲不出手的老话） | gangMeng·qiMeng | — | 42000/1200/300 |
| 2 | stage_13_02 | 半山寺(temple) | 半山即停的人（「半山也很好」的知足·考校主角的「再上」） | lingQiao·qiMeng | — | 44000/1240/295 |
| 3 | stage_13_03 | 竹林(bambooForest) | 登到高处反收锋的人（章中考验·非 boss） | yinRou·ruMen | 非 boss | 47000/1300/300 |
| 4 | stage_13_04 | 断崖瀑布(cliffWaterfall) | 登顶路最后的拦路考校者（章中 Boss·stat 门槛无相位·配 defeat） | gangMeng·ruMen | 章中 Boss | 52000/1420/305 |
| 5 | stage_13_05 | 绝顶平台(mountainForest/innerRealm 候选) | 绝顶之上等人的人（末 Boss·真解·配 defeat） | lingQiao·shuLian | 末 Boss | 56000/1550/300 |

- Boss 位 **{4,5}**（章中 + 末·同 Ch10/11/12）。13_03 非 boss 关保 5 关有敌队。
- 章首 stage_13_01 **不跨章 prevStageId**（链首必缺·跨章引用加载期 StateError）；13_02..05 内链单链。
- 数值续 Ch12 曲线（Ch12 26000-40000/900-1150，`stages.yaml` stage_12_01..05 实测）→ Ch13 42000-56000/1200-1550·**末 Boss 56000 < 60000 硬红线**（GDD §5.2:300 硬约束 Boss 血 ≤60000）·`difficultyMultiplier` 14.2→15.0（续 Ch12 12.8→13.8）·绝顶敌 defense_rate 0.25（`numbers.yaml:393`·yiLiu 0.20 升档）。
- 境界差修正（GDD §5.5）：玩家入章时绝顶·启蒙 vs 敌同层·无跨阶碾压问题；跨阶末 Boss 战败风险照 `boss_balance_crosstier` 口径 balance 校准。

## 末 Boss(13_05) + 真解
- **绝顶之上等人的人**：几十年前登到绝顶、此后坐在山顶等后来者上来一战的老人——守拙翁的绝顶版镜像（守拙翁守死一地困于旧路；这位登顶后不走，等一个「走得上来」的人）。破其真招 = 主角正式踏上绝顶，老人把「看江湖走到了哪一步」的下一程交到主角手里（托付意象倒置：不是别人托主角，是主角成了别人要等的人）。
- 结构复用守拙翁/鎏金公/无名客模板：`chargeSkillId = 真解`·`bossPhases` 两相位（1.0 / 0.5 aggressive `onEnterMechanic: chargeCounter`·`titleKey: bossPhase_desperate`）·首通拦截掉真解（`source: mainline_drop`）。
- **真解新写（+1 招·唯一新增）**：登高一览意象·推荐 `style: lingQiao`（Ch10 止水 yinRou / Ch11 鎏金 gangMeng / Ch12 绵里藏针 yinRou·三流派轮换灵巧缺位）·**tier: 5**（绝顶真解必对 jiangHuMiChuan 阶·守三系锁死·tier4 招不可充数）·`type: powerSkill`·`powerMultiplier ~4800`（tier4 真解锚 3600 上一档·守 ≤8000·`skills.yaml:18` jiangHuMiChuan 阶敌招 cap=4000，真解手工高于敌招档沿既有体例）·`qiDelta ~-30`·`cooldownTurns 4`·`requiresManualTrigger: false`·`chargeSkill=dropSkillManual` 双用·proficiency 真解手工高半档（灵巧向 CD 倾斜·照 `skill_feng_juan_liu_sha` 三层模板）。推荐命名「一览众山」（古诗化用·合 content_guide 命名法·4 字）·id `skill_yi_lan_zhong_shan`（实装可调名）。
- 登记 `standaloneBossManualIds` 白名单（`wave_b_content_redline_test:136` 配平排除·否则破 2/2/2 流派）。
- 末 Boss 人设/真解 school【待拍板】（见 §10 #6）。

## 复用策略（池盘点 2026-07-22 实测·复用优先）
- **敌招·池足零新写**：江湖秘传（tier5）系列已写 **21 招全部未挂主线敌**——3 流派 × basic/skill/ult 9 招（`skills.yaml:567-691`·basic 500/skill 3200/ult 4000）+ fang 变体 9 招（`:2103-2212`）+ lingQiao nei 变体 3 招；心法定义 `tech_*_jianghu` tier: jiangHuMiChuan 已就位（`techniques.yaml:193-233`）。现仅 stage_04_05 cycle 相位解锁用 yinrou_jianghu_fang（`stages.yaml:1006-1020`）。Ch13 敌队直接装配 jianghu 系列（对 Ch10-12 用 menpai 系列的升档）。
- **装备·池足零新写**：重器 zhongQi **11 件常规**（weapon 5：破阵锤/青虚剑/毒龙索/日月轮/追魂钉·armor 3·accessory 3·`equipment.yaml:353-1087`）+ 1 special（xin_mo_zhu·不入掉落池）。五关 dropTable 复用搭配（每关 weapon 1.0 + armor/accessory 0.3-0.5·沿 Ch10-12 体例）。
- **唯一新增 = 末 Boss 真解 1 招**。复用 vs 新招【待拍板】（见 §10 #3·推荐全复用+1 真解）。

## cap 28→? 与 releaseTier 抬升影响面（cross-tier·与 Ch10-12 within-tier 本质不同）
- 【待拍板】cap（见 §10 #2·推荐 28→31=绝顶·熟练·对称 Ch10 首章爬到 shuLian 体例）。
- **releaseTier yiLiu→jueDing 自动随 `max_absolute_realm_level` 重算**（`wave_b_content_redline_test:179-181` 读 cap 推 tier），触发 mount_deferred/skill-source 全套：
  - **红线⑦挂载完备**（`skill_source_redline_test:123-176`）：发布阶扩到 tier5 后，已写的 tier5 standalone 招中 `skill_shi_dang_shi_jue`（mainline_drop·gangMeng·`skills.yaml:2954`）、`skill_jing_hong_zhao_ying`/`skill_ma_ta_fei_yan`（fragment·lingQiao·`:3100`/`:3160`）从未挂载→**不挂载则测试红**。处置【待拍板】（见 §10 #4·推荐：jing_hong 挂 Ch13 章末重打残页位·ma_ta 挂塔层空位·shi_dang 标 mount_deferred——西凉马战意象属边塞）。edge_zhongqi ×3 为 source: special 不在完备性口径内。
  - 内容挂载完备（`wave_b_content_redline_test:38-91`）：canEquipAtRealm 重算 + `!mountDeferred` 豁免口径复核（tier4 既有 3 招 mount_deferred 仍豁免·tier 仍 ≤ 发布阶）。
  - 心法/装备侧是否有对称完备性测试（tech_*_jianghu 领悟池挂载·zhongQi 掉落挂载）→ **Phase-0 grep 复定**。
  - 升层门禁 e2e cap-agnostic（`inner_demon_r5_redline` R5.3）·stale 文案 de-drift（「Lv100/停在层」label）·照 Ch10 cap 抬升 4 站点体例逐站 grep。

## mount_deferred 3 招处置衔接（tier4 遗留·承 Ch12 拍板悬项）
- `skill_feng_juan_liu_sha`（tier4·lingQiao·mainline_drop·`:2933-2952`）：大漠风卷意象·Ch11/Ch12 已连续以「不搭中州」搁置；绝顶段若留中州登高线**仍不搭**（除非章叙事写「绝顶望见来路大漠」·勉强）。`skill_jin_gang_fu_mo`/`skill_guan_shan_ba_ji`（tier4·gangMeng·fragment·`:3080-3098`/`:3140-3158`）：禅门伏魔/阳关戍戟意象·与绝顶段主题弱相关。
- 【待拍板】（见 §10 #5·推荐：Ch13 不动·留 Ch14/15 fragment 位收编 jin_gang/guan_shan·feng_juan 留待边塞相关章或最终否决）。

## 叙事纲（13 篇·同 Ch10-12 体例·~6300 字）
- `chapter_13`：章首（起脚往上·带两枚印三卷真解出中州向高处）+ 章尾（踏上绝顶·见「被等的人」·承 Ch14 hook）。
- 10 段 stage（5 关 × opening/victory）+ 2 defeat（13_04 章中 Boss / 13_05 末 Boss）。
- 母题承「名≠本事→实至名归」之后转向（方向【待拍板】§10 #6）·黑名单词 + 现代词 + 网文腔 grep 0 命中·水墨克制·不写教程弹窗。

## reconcile 面（承 Ch12 ~26 站点 + cap cross-tier 追加·行号 2026-07-21/22 grep·**实装前 Phase-0 grep 复定防 drift**）
- **count 60→65**：`progression_playtest_diagnostic_test:15`（CSV byte-lock 须 `UPDATE_PROGRESSION_PLAYTEST_EVIDENCE=1` 重生）/ `game_repository_test:84,673,679`（mainlineCount 65 / 主线 65 关红线含双 Boss / prevStageId 单链）/ `mainline_narrative_completeness_test:58,62`（65 + 章循环 1→13）/ `balance_simulator`（`>=` 不破）/ `readable_first_clear_tempo_diagnostic_test:110`（**终章门槛钉 stage_13_05·Phase-0 先核实 Ch12 实装后现值**）。
- **boss 敌 26→28**（`stages_boss_enemy_test`）·**catalog 39→41**（`boss_memory_providers_test`）。
- **skill 计数 3 处（+1 真解 252→253）**：`game_repository_test` / `skill_count_contract_test:38`(mergedIds 253 + `:28` genericIds 213 + 交叉核 GDD 字串「N 招」) / `skill_qi_redline_test:57`。（收编既有 tier5 招只改挂载不改计数。）
- **真解白名单**：`wave_b_content_redline_test:136` standaloneBossManualIds +1。
- **progression 级联（Lv 位移·逐值实测·fail-fast·禁猜）**：`progression_release_budget_test:30,47`（hasLength 65 + cumExp 位移）/ `progression_idle_horizon_simulation`（同口径重校·终态 guard 现 ≤103·随加章重核）。
- **生产可见性**：`chapter_list_screen.dart:30` `_chapters=[1..13]` + widget 章卡计数 / main_menu + status_summary 循环 `<=13` / `boss_memory_key` group index（chNum=13·防撞心魔/轻功/群战·持久化不重排旧值）/ `strings.dart:1468,1486` chapterTitle·Hint switch +13 分支 + chapter13Title/Hint 常量 / `strings.dart:1367` mainMenuHint「13 章 65 关」。
- **material 级联**：`enhancement_material_supply_test`（结晶 +Ch13 5 关·软线沿 Ch12）。
- **tier 红线**：`mainline_stage_curve` 加 Ch13→jueDing 映射（cap-agnostic·按 `requiredRealm.index`）。
- **cap 抬升**：`numbers.yaml:206` `max_absolute_realm_level` + `numbers_config_progression_release_cap_test`（cap-value 断言）+ §5 cross-tier 全套（红线⑦/挂载完备/门禁 e2e/de-drift）。
- GDD §8.1 章表 + 招式池计数同步。

## 红线守卫（实装期逐条守）
- Boss hp 56000 < 60000 硬红线（GDD §5.2:300）·真解 mult ~4800 ≤ 8000·敌 baseAttack ≤ ~1550（敌属性·装备掉落攻击另守 ≤2000）。
- 三系锁死：绝顶 ↔ zhongQi ↔ jiangHuMiChuan·真解必 tier 5·敌招用 jianghu 系列（不用 menpai 降档充数）。
- 章首 13_01 缺 prevStageId；末 Boss chargeSkillId 必配 bossPhase `onEnterMechanic: chargeCounter`（成对·否则 `readable_tempo` missingBossMechanic 挂）；章中 Boss 13_04 **stat 门槛无 bossPhases**。
- 在线=离线·不做体力/每日任务/抽卡等反主流项·爽感走表现层不膨胀数值。

## 10. 待拍板汇总（逐项选项 + 推荐）
1. **章名**：A「山外青山」（承卷尾「再往高」+ 人外有人双关·兼容两主题方向）/ B「绝顶之上」（直承段名）/ C「高处相逢」（落在「等的人」）。**推荐 A**——雅且留悬念·合 Ch11/12 四字短语体例。
2. **cap**：A 28→31（绝顶·熟练·对称 Ch10 首章 qiMeng→shuLian 体例·暗含绝顶段三章 Ch13-15 规划）/ B 28→29（只启蒙·小步）/ C 28→35（一次封顶·数值风险大）。**推荐 A**——体例对称·后续章节奏可预期。
3. **复用 vs 新招**：A 敌招/装备全复用（jianghu 21 招未挂载 + zhongQi 11 件·池实测足）唯一新写真解 1 招 / B 借机新写绝顶敌招若干。**推荐 A**——池足·守 Ch10-12「零新增+1 真解」体例。
4. **tier5 既有 3 招处置**（releaseTier 抬升必答）：A jing_hong 挂 Ch13 章末重打残页 + ma_ta 挂塔层空位 + shi_dang 标 mount_deferred / B 三招全标 deferred（最省事·浪费已写内容）/ C 三招全挂载（Ch13 挂载位不够·需加挂点）。**推荐 A**——残页/塔位体例已有·shi_dang 边塞意象不搭。
5. **mount_deferred tier4 3 招**：A Ch13 不动·留 Ch14/15 收编 jin_gang/guan_shan·feng_juan 待边塞章或否决 / B Ch13 即收编为 fragment 挂载 / C 否决删除。**推荐 A**——本批 scope 已含 cap cross-tier 全套·不再加挂载面。
6. **绝顶段主题/文化弧**：A「从看江湖到成为江湖」（传承弧：守拙翁托他看江湖·走到绝顶他自己成了别人要等/要看的人·末 Boss=绝顶等人数十年的老者·真解 lingQiao「一览众山」）/ B「山外有山·人外有人」（谦逊弧：实至名归根后上山方知上有更高·末 Boss=更高处的隐者）。**推荐 A**——motif 承接最紧（铜符/止水印皆「前人留路标」·主角从接符人变留符人）·且呼应其北派新掌门身份（绝顶=开宗立派资格）。

## 实装建议
- coupled xhigh 批整章一次做完（同 Ch10-12）·**先全 Phase-0 grep 复定站点行号**（本 spec 行号 2026-07-21/22 grep·实装前重核防 drift·尤其 cross-tier 影响面站点）。
- 合并前主 checkout `build_runner`（.g.dart gitignored）→ `flutter analyze` 0 → 批末全量 `flutter test --no-pub`。
- 破坏证红：真解 mult 9000>8000 RED→还原绿（commit 后做·守 `feedback_break_red_after_commit`）。
