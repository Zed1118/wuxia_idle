# Ch12「中州·名下之实」一流第三章设计（一流三章收官）

## 定位
- 一流三章(Ch10-12)**收官**·承 Ch11「名门之虚·见虚」·文化弧「名门虚实之辨」由「虚」收束于「实」。
- 母题「名≠本事」终章落点：**实至名归·本事在骨**。承守拙翁「托印看江湖」延续到「看全虚实两半」。
- `requiredRealm: yiLiu`（承 Ch11）·章内敌人层 **yuanShu→dengFeng** 递进（Ch11 收 yuanShu·Ch12 收 dengFeng=**一流封顶**）。
- **cap 26→28**（dengFeng·within-tier·`numbers.yaml:206` 注释已预留·用户 2026-07-21 确认）。

## 承接 hook
- 主角带**止水旧印 + 凉铜符**·Ch11 卷尾「去寻配得起名头的、实的一半」。
- Ch12 = 寻「实」：走过满江湖虚名门，终于遇到一个**不图名头、把本事练到骨子里的无名真高手**（扫地僧式·「实」之化身·守拙翁正面镜像）·破其真招得真传·收一流三章。

## 5 关（寻实·每关一种「实」·对照 Ch11 每关一种「虚」）
| 关 | id | 场景/biome | 「实」侧面 | 流派/层 | Boss | HP/Atk/Spd |
|---|---|---|---|---|---|---|
| 1 | stage_12_01 | 渡口(dock) | 藏于平凡的真本事（摆渡人身怀实功·不显山露水） | lingQiao·yuanShu | — | 26000/900/305 |
| 2 | stage_12_02 | 市井巷陌(alley) | 不图名的真功夫（默默练到骨子·无人识得） | gangMeng·yuanShu | — | 27000/920/268 |
| 3 | stage_12_03 | 山道(mountainpath) | 名实相副的低调行家（章中考验·非 boss·阴柔） | yinRou·huaJing | 非 boss | 29000/955/296 |
| 4 | stage_12_04 | 铁匠铺(smithy) | 真有本事的守成匠人（章中 Boss·stat 门槛无相位·配 defeat） | lingQiao·huaJing | 章中 Boss | 33000/1080/300 |
| 5 | stage_12_05 | 隐世居所(inn) | 无名真高手·名下之实的化身（末 Boss·真解·配 defeat） | yinRou·dengFeng | 末 Boss | 40000/1150/298 |

- Boss 位 **{4,5}**（章中 + 末·同 Ch10/11）。12_03 非 boss 关保 5 关有敌队。
- 章首 stage_12_01 **不跨章 prevStageId**（承 Ch11 收尾自然衔接·链首必缺 prevStageId·跨章引用加载期 StateError）；12_02..05 内链单链。
- 数值续 Ch11 曲线（Ch11 22000-37000/820-1060 → Ch12 26000-40000/900-1150）·守 **Boss hp 40000<60000 硬红线不进 1M**·`difficultyMultiplier` 12.8→13.8（续 Ch11 12.6）。biome/scene 全复用现有图（dock/alley/mountainpath/smithy/inn 均存在）。

## 末 Boss(12_05) + 真解
- **无名真高手**：全无名头、最平凡处身怀绝技·与满章虚名门相反。`school: yinRou`·`realmLayer: dengFeng`（绵里藏针·实藏于内·把招练进骨子）。
- 机制反讽收束：Ch11 主角「练成名宿没练透的招」；Ch12 终于遇到**把招练到骨子里**的人，破其真招 = 真正较量、得真传（正打「名≠本事·实至名归」）。
- 结构复用守拙翁/鎏金公模板：`chargeSkillId = 真解`·`bossPhases` 两相位（1.0 / 0.5 aggressive `onEnterMechanic: chargeCounter`·`titleKey: bossPhase_desperate`）·首通拦截掉真解（`source: mainline_drop`）。
- **真解新写（+1 招·唯一新增）**：绵里藏针意象·`style: yinRou`·`tier: 4`·`type: powerSkill`·`powerMultiplier ~3600`（沿 `skill_liu_jin_jue`/`skill_zhi_shui_jue`/`skill_chen_sha_yi_jue` 锚·守 ≤8000）·`qiDelta ~-30`·`cooldownTurns 4`·`requiresManualTrigger: false`·`chargeSkill=dropSkillManual` 双用·`proficiency` 真解手工高半档（阴柔向·照 `skill_liu_jin_jue` 三层 `damage_pct` 体例）。推荐 id `skill_mian_li_cang_zhen`（绵里藏针·实装可调名）。
- 登记 `standaloneBossManualIds` 白名单（`wave_b_content_redline_test:136` 配平排除·否则破 2/2/2 流派）。

## feng_juan 及既有 mount_deferred 处置
- `skill_feng_juan_liu_sha`（大漠灵巧）沿 Ch11 继续 `mount_deferred` 搁置（大漠意象不搭中州「名下之实」）。cap 28 within-tier 不暴露新阶招、不触发新 `mount_deferred`（见 memory `feedback_wuxia_release_cap_raise_reconcile` #5）。
- **一流封顶后遗留 mount_deferred 招（feng_juan 真解 + jin_gang/guan_shan fragment）最终处置 = 待用户拍板项**（收编绝顶段 / 专门 review / 否决）·不阻塞 Ch12。

## 止水印 / 铜符 motif（收束守拙翁托付·跨段续带）
- Ch12 一流收官**回应守拙翁托付**「替我看看这潭水外头的江湖走到哪一步」——虚实两半看全·这条托付线在章尾收束。
- 铜符（师父）+ 止水印（守拙翁）作为**跨段 motif 继续带向绝顶段**·不在一流末消耗·保持象征·零 schema。

## 复用策略（同 Ch10/11·敌招/装备零新增）
- 敌招复用一流 `menpai` 系列（三流派 basic/skill·池已足）。
- 装备掉落复用 `liQi`（利器 tier4·Ch10/11 已用）。
- **唯一新增 = 末 Boss 真解 1 招**。

## 叙事纲（13 篇·同 Ch10/11 体例·~6300 字）
- `chapter_12`：章首（寻「实」·带两枚印入中州更深处）+ 章尾（见「实」·一流三章收官·收束守拙翁托付·承绝顶段 hook）。
- 10 段 stage（5 关 × opening/victory）+ 2 defeat（12_04 章中 Boss / 12_05 末 Boss）。
- 母题「名≠本事」收于「实」·无名真高手 vs 满江湖虚名·主角见「实」得真传；黑名单词 + 现代词 + 网文腔 grep 0 命中。

## reconcile 面（~26 站点·承 `feedback_wuxia_add_mainline_chapter_reconcile`·站点已 Phase 0 grep 实定，行号 2026-07-21 grep·实装前重核防 drift）
- **count 55→60**：`progression_playtest_diagnostic_test:15`（注释「改此一处」·CSV byte-lock 须 `UPDATE_PROGRESSION_PLAYTEST_EVIDENCE=1` 重生）/ `game_repository_test:84,673,679`（mainlineCount 60 / 主线 60 关红线含双 Boss / prevStageId 单链）/ `mainline_narrative_completeness_test:58,62`（60 + 章循环 1→12）/ `balance_simulator`（`>=` 不破）/ `readable_first_clear_tempo_diagnostic_test:110`（**终章门槛钉 stage_12_05·实装先核实 Ch10/11 是否漏更新留 stage_09_05 drift**）。
- **boss 敌 24→26**（`stages_boss_enemy_test`）·**catalog 37→39**（`boss_memory_providers_test` 图鉴 = isBossStage 数）。
- **skill 计数 3 处（+1 真解 251→252）**：`game_repository_test`(skillDefs 池) / `skill_count_contract_test:38`(mergedIds 252 + `:28` genericIds 212 + 交叉核 GDD 字串「N 招」) / `skill_qi_redline_test:57`(skillDefs 252)。
- **真解白名单**：`wave_b_content_redline_test:136` standaloneBossManualIds +1。
- **progression 级联（Lv 位移·逐值实测·fail-fast·禁猜·守 <Lv100）**：`progression_release_budget_test:30,47`（hasLength 60 + cumExp 从 1541 位移）/ `progression_idle_horizon_simulation`（同口径重校）。
- **生产可见性**：`chapter_list_screen.dart:30` `_chapters=[1..12]` + widget 章卡计数（viewport 扩容）/ main_menu + status_summary 循环 `<=12` / `boss_memory_key` group index（新章 chNum=12·防撞心魔/轻功/群战·持久化字段不重排旧值）/ `strings.dart:1468,1486` chapterTitle·Hint switch +12 分支 + chapter12Title/Hint 常量 / `strings.dart:1367` mainMenuHint「12 章 60 关」。
- **material 级联**：`enhancement_material_supply_test`（结晶 +Ch12 5 关·软线沿 Ch11「不足 5 件」）。
- **tier 红线**：`mainline_stage_curve` 加 Ch12→境界映射（cap-agnostic·按 `requiredRealm.index`）。
- **cap 抬 26→28**：`numbers.yaml:206` `max_absolute_realm_level: 28` + `numbers_config_progression_release_cap_test`（cap-value 断言·within-tier 只此一处破·releaseTier 仍 yiLiu 不触发 mount_deferred/skill-source 全套）。
- GDD §8.1 章表 + 招式池计数同步。

## 红线守卫（实装期逐条守）
- Boss hp 40000 < 60000 硬红线·不进 1M；真解 mult ~3600 ≤ 8000；敌 baseAttack ~1150（敌属性·装备掉落攻击另守 ≤2000）。
- 章首 12_01 缺 prevStageId；末 Boss chargeSkillId 必配 bossPhase `onEnterMechanic: chargeCounter`（成对·否则 `readable_tempo` missingBossMechanic 挂）；章中 Boss 12_04 **stat 门槛无 bossPhases**（照玉京阁·有 bossPhases ⟹ 必有 charge）。

## 已知拍板（用户 2026-07-21 全按推荐）
章名「名下之实」/ 末 Boss 无名真高手（扫地僧式）/ 真解 school=yinRou·绵里藏针 / cap 26→28 确认 / motif 收束托付 + 续带绝顶。feng_juan 沿 Ch11 搁置。material 软线沿 Ch11。

## 实装建议
- coupled xhigh 批整章一次做完（同 Ch10/11）·先全 Phase-0 grep 复定站点行号（本 spec 行号 2026-07-21 grep·实装前重核防 drift）。
- 合并前主 checkout `build_runner`（.g.dart gitignored）→ `flutter analyze` 0 → 批末全量 `flutter test --no-pub`。
- 破坏证红：真解 mult 9000>8000 RED→还原绿（commit 后做·守 `feedback_break_red_after_commit`）。
