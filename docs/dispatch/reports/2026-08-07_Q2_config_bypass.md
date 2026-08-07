# REPORT_Q2 · 配置声明 vs 生产硬编码背离全仓扫描

- **性质**:只读深核 + 报告,零代码改动(派单 Q2)
- **时间**:2026-08-07(夜批)
- **基线**:branch `qoder/config-bypass-audit` @ `af82baea`(worktree 干净)
- **上游**:`2026-08-07_PI1_yaml_consumption.md`(lib grep 零命中 = 完全未消费)、`2026-08-07_Q1_field_verify.md`(25 项假阴复核)
- **本单定位**:找 PI1/Q1 都逮不到的**第三类**——字段名/概念在 lib 有 grep 命中(不算"未消费"),但真实取值路径被**字面量常量或结构性硬编码顶替**,配置形同虚设,改 yaml 不改变行为。

---

## 一、TL;DR

| 指标 | 数值(实统) |
|---|---|
| data/ 下 .yaml 总数 | 668 |
| 本单扫描范围(除 `narratives/_archive` 66 + `lore/_templates` 7) | **595 文件** |
| 其中运行时可达(进 asset bundle;再除 `lore/_archive` 45 + `events/_archive` 5) | 545 文件 |
| 顶层可调 config yaml(numbers/equipment/encounters/…) | 20 文件 |
| 顶层 config yaml 叶子字段(脚本实提) | **14,944**(其中 numbers.yaml 1,239) |
| 强类型配置字段(numbers_config.dart + 36 defs 的 `final` 属性,去重) | **627** |
| 业务侧零引用(机械筛,`grep .field` 排除 lib/data、debug、.g.dart) | **89** → 逐一深核 |
| **背离(confirmed)** | **8 字段 / 8 处** |
| **部分背离** | **7 字段 / 3 组** |
| **休眠配置(形态 4:loader 解析但零 caller)** | **21 字段**(+1 预留) |
| 非背离(深核确认:假阴还原 / 校验消费 / 合理硬编码) | 51 字段 |
| 其余强类型字段(业务引用 ≥1,抽查均配置驱动) | 538 |

**一句话结论**:全仓未发现 rarity 式"概率分布整段失效"的大面积数值撒谎,但**实锤 8 处背离 + 7 处部分背离**,集中在**飞升传承规则、断魂庄补给、Boss 招降概率、师徒阵容开关、门派克制附带效果开关**五个子系统;另有 **21 处"已解析零 caller"的休眠配置**(心魔惩罚、江湖 NPC、桃花岛地形副本等),是下一轮接线/删配置的主要候选。

### 自校验闸门:方法是否扫出活样本?
**是。** 活样本 `character.rarity_distribution`(numbers.yaml:942)被本方法独立命中:机械筛发现 `RarityTier` 六档枚举在 lib 满屏命中、但三个生产赋值点全部写死 `RarityTier.biaoZhun`,且该 yaml 段**根本没被 `NumbersConfig.fromYaml` 解析**(连 loader 都没有)。判据成立,方法无漏。

---

## 二、方法说明(实际执行)

1. **叶子字段提取**:python 脚本(临时 `/tmp/q2/leaf_extract.py`,**未入仓**)按缩进解析 20 个顶层 config yaml,产出 `行号\t路径\t值`,共 14,944 叶。narratives/lore/events 为文案内容,字段是剧情/描述而非可调数值,按内容文件处理(抽查其触发概率/奖励字段,见附录)。
2. **loader 映射**:把 numbers.yaml 38 个顶层段逐一 grep `numbers_config.dart` 是否解析;解析器 = `lib/data/numbers_config.dart` + `lib/data/defs/*.dart` 的 `fromYaml`。`tower`/`synergies`/`skills`/`validation_examples` 四段 loader 零命中(与 PI1 一致)。
3. **业务侧消费机械筛**:脚本(临时 `/tmp/q2/field_usage.py`)对 627 个 `final` 配置属性逐个 `grep -rn "\.<prop>\b" lib`,排除 `lib/data/`(loader 自身)、`lib/features/debug/`、`*.g.dart`。得 89 个零引用候选。
4. **89 候选深核**:按子系统拆 6 组并行只读深核(战斗/强化、闭关/江湖/门派、心魔/轮回/掉落、远征/桃花岛/扫荡、遗物/祖师/心法/羁绊、动画/内容链接)。重点还原三类**假阴**:计算 getter(如 `attackTotalMs`)、accessor 方法(如 `chanceFor`/`traitsFor`/`realmScaleFor`)、私有字段经公开方法暴露(如 `SkillProficiencyEffects`)。
5. **反向扫描**(补机械筛盲区):`?? <字面量>` 兜底、`dart:math Random` vs `rngProvider`、`nextDouble() < 字面量` 概率比较、lib/features 内按实体 id 写死的数值 map。
6. **概率字段随机源核查**:凡配概率者,确认是否接 `rngProvider`/`newMathRandom` 的 roll;配了概率却无 roll = 强背离信号(命中 stage_boss_recruit_prob、encounter_base_prob、rarity_distribution)。
7. 每条 finding 的**双侧 file:line 均由本会话 grep/read 实锤**;无法落双侧证据的条目不进主表。

---

## 三、背离(confirmed)主表 · 8 处

> 判据:yaml 有可调字段;生产决策点是字面量/结构性硬编码,不读该字段;**改 yaml 不改变行为**。

### B1. `character.rarity_distribution` —— 六档稀有度概率整段失效【活样本 · 最高危】
- **yaml**:`data/numbers.yaml:942-961`(庸才 15% / 寻常 35% / 标准 25% / 资优 18% / 天才 5% / 绝世 2%,GDD §4.1 强制规则)。
- **loader**:**未解析**——`NumbersConfig.fromYaml`(numbers_config.dart:315)只取 `character.adventure_attribute_bonus.lifetime_cap_per_character`(:459-465),`rarity_distribution` 无 loader。
- **lib 硬编码点(全部)**:
  - `lib/features/recruitment/application/recruitment_service.dart:99` `rarity: RarityTier.biaoZhun`
  - `lib/features/sect/presentation/sect_recruit_handler.dart:110` `rarity: RarityTier.biaoZhun`
  - `lib/features/onboarding/application/master_builder.dart:53` `rarity: RarityTier.biaoZhun`
  - 枚举本体 `lib/core/domain/enums.dart:150`(`yongCai..jueShi` 六档齐备,却从不被概率选中)。
- **改配置为何不生效**:概率段无 loader、无 roll,三个创角/收徒路径直接把稀有度钉死在「标准」。
- **玩家侧表现**:招募/拜师/开局的弟子与师父**永远是「标准」档**,见不到庸才/天才/绝世;GDD §4.1 稀有度分布从未生效,调 yaml 概率零变化。

### B2. `boss_gauntlets.supply_cap` —— 补给上限双重写死
- **yaml**:`data/boss_gauntlets.yaml:10` `supply_cap: 3`。
- **loader**:`lib/data/defs/boss_gauntlet_config.dart:56` 解析;`:75-76` **硬校验 `==3`,否则启动 throw**。
- **lib 硬编码点**:`lib/features/boss_gauntlet/presentation/gauntlet_loadout_screen.dart:42` `static const int _supplyCap = 3`;用于 `:306`(UI 提示)/`:318`(装载 gate)/`:340`(预算显示),`:65` 传入 `GauntletService.enter`。`.supplyCap` 属性生产 0 读(仅 defs + 测试)。
- **改配置为何不生效**:改成 ≠3 启动即崩(loader 硬校验);即便放开校验,业务仍读常量 3。配置字段纯摆设。
- **玩家侧表现**:断魂庄补给装载恒 3 份,UI/拦截/文案全用常量,yaml 调整完全无效。

### B3. `sect_recruit.stage_boss_recruit_prob` —— Boss 招降概率被 Dart 字面量顶替(注释误导)
- **yaml**:`data/numbers.yaml:1917` `stage_boss_recruit_prob: 0.40`。
- **loader**:`lib/data/numbers_config.dart:2687-2688` 解析为 `stageBossRecruitProb`(:2664);**该属性全 lib 无业务读取**。
- **lib 硬编码点**:`lib/data/defs/stage_def.dart:198` `this.baseProbability = 0.40` + `:204` `?? 0.40`(`BossRecruitConfig.fromYaml` 缺省回退是字面量,**不是**读 numbers.yaml);决策点 `lib/features/sect/presentation/stage_boss_recruit_hook.dart:174` 用 `stage.bossRecruit!.baseProbability`。`data/stages.yaml` 全部 6 处 `bossRecruit`(:263/:517/:768/:1029/:1286/:1552)均省略 `baseProbability` → 生产 100% 走字面量。
- **误导注释**:`stage_def.dart:191`、`stage_boss_recruit_hook.dart:146`、`numbers_config.dart:2664` 三处都声称"走 numbers.yaml stage_boss_recruit_prob",实际从不读。
- **改配置为何不生效**:决策走 `?? 0.40` 字面量;当前 yaml 与字面量恰好同为 0.40,故一直未被发现。
- **玩家侧表现**:Boss 战胜招降概率恒 40%,把 yaml 改成 0.80 不生效。同组对照:`stageBossFailRecoverProb` 是真读配置(hook.dart:57-62)。

### B4. `masters.enabledInDemo` —— 师徒阵容开关零读取,按数组下标 seed
- **yaml**:`data/masters.yaml:31/52/73`(三人全 `enabledInDemo: true`)。
- **loader**:`lib/data/defs/master_def.dart:20/56`(缺省 true)。
- **lib 硬编码点**:`lib/features/onboarding/application/onboarding_service.dart:89-117` 按**位置索引** `masters[0]/[1]/[2]` 直接建角(`soloStart` 只影响数量);`lib/data/validation/lineage_recruit_red_lines_validator.dart:35` 硬校 `masters.length != 3` 即抛。`enabledInDemo` 全 lib 0 读。
- **改配置为何不生效**:阵容按下标取人、不按开关过滤;把某弟子 `enabledInDemo` 改 false 仍会被 seed;删/减条目直接撞红线启动即抛。
- **玩家侧表现**:当前全 true 无可观察差异;一旦想用此开关下线某弟子,不生效(低危,但开关是死的)。

### B5-B8. `inheritance.heritage_items` 四条规则字段 —— 飞升传承规则全写死(yaml 注释自相矛盾)
- **yaml**:`data/numbers.yaml:1408` `transfer_trigger`、`:1409` `multi_disciple_allocation`、`:1410` `stack_across_generations`、`:1411` `conflict_slot_resolution`。
- **loader**:`lib/data/numbers_config.dart:694-700` 解析(字段声明 :662-665),缺省值与 yaml 同。
- **lib 硬编码点(逐条)**:
  - `transfer_trigger`(仅飞升触发):传承只存在于 `lib/features/ascension/application/ascend_service.dart:238` `eq.inheritFrom(founderId, numbers)`,触发时机结构性钉死=飞升,无 `if(transferTrigger==…)` 分支。
  - `multi_disciple_allocation`(player_pick):`lib/features/ascension/presentation/ascension_screen.dart:339-351` 无条件构建逐件下拉,player_pick 写死 UI 结构。
  - `stack_across_generations`(false):`lib/features/battle/domain/derived_stats.dart:274-275` 按 `equipped.where(isLineageHeritage)` **件数**计 `+5%/件`,布尔从不读。
  - `conflict_slot_resolution`(auto_swap):`ascend_service.dart:248-268` 副作用 4 无条件 auto_swap,注释自认对应本字段但不读值。
- **改配置为何不生效**:4 字段解析后无任何 `if/switch` 读值;`numbers_config.dart:645` doc 声称"lib 端真消费 6 字段",实际仅 `pieces_per_generation_min/max` 2/6 被消费(ascend_service.dart:192-196、ascension_screen.dart:309-310)。
- **玩家侧表现**:把 `stack_across_generations` 改 true、`conflict_slot_resolution` 改 keep_old,飞升传承行为零变化(仍仅飞升触发、仍逐件手选、仍自动换装、仍不累代叠加)。yaml 注释标"已实装",实为值被写死。

---

## 四、部分背离主表 · 7 字段 / 3 组

> 判据:配置对象被读取,但**某些子字段/分支**绕过它、由结构性硬编码顶替。

### P1. `retreat.zhengWu.target_attribute` —— 正午闭关目标维度写死
- **yaml**:`data/numbers.yaml:1208` `target_attribute: "internal_force_points"`。
- **loader**:`lib/data/numbers_config.dart:2130` 解析为 `zhengWuTargetAttribute`(声明 :2039);**全 lib 零消费**。
- **读配置的路径**:同一 zhengWu 块的 `multiplier`(1.20)与 `applies_to_school`(gangMeng)走配置(`seclusion_service.dart:236` 算 `zhengWuBonus`)。
- **绕开的路径**:`lib/features/seclusion/application/seclusion_service.dart:282` `zhengWuBonus` **无条件只乘进 `internalForcePoints`**,无按目标属性路由的分支。
- **玩家侧表现**:正午刚猛闭关加成永远只落在内力点数;把 yaml 改成 `experience_points` 不生效。

### P2. `combat.school_counter.gang_meng_quake` 三语义布尔 —— 震伤语义结构性写死
- **yaml**:`data/numbers.yaml:878/879/880`(`pierces_defense`/`pierces_critical`/`follows_main_hit`,全 true)。
- **loader**:`lib/data/numbers_config.dart:1154-1156`。
- **读配置的路径**:同对象 `.damage` 被 `lib/features/battle/domain/damage_calculator.dart:269` 消费。
- **绕开的路径**:震伤在 `damage_calculator.dart:263-271` 以**独立加值**在防御率/暴击乘式之外叠加、闪避早退——"穿防/不暴击/随主攻击"三条语义靠代码结构写死;触发对硬编码 `gangMeng→yinRou`(:267-269),不查 `_counterTarget`。
- **玩家侧表现**:当前 yaml 全 true 与硬编码行为恰好一致,无可见差异;但把任一布尔改 false 行为不变,配置可调性失效。

### P3. `combat.school_counter.yin_rou_internal_injury` 三标志 —— 内伤叠加/穿透写死
- **yaml**:`data/numbers.yaml:890` `pierces_defense`、`:891` `stack_rule: "refresh"`、`:892` `follows_main_hit`。
- **loader**:`lib/data/numbers_config.dart:1187`(stackRule)。
- **读配置的路径**:同对象 `turnsPersist`/`damagePerTick` 被 `lib/features/battle/domain/strategy/default_ground_strategy.dart:915-916` 消费。
- **绕开的路径**:`:908-918` 触发对硬编码 `yinRou→lingQiao`(:912-913),**直接覆盖旧 slot 不叠层**(refresh 语义结构性写死,:909/:921 注释);dot 结算 `:359-374` 固定伤害直扣(pierces_defense 写死)、`!result.isDodged`(:911, follows_main_hit 写死)。
- **玩家侧表现**:当前 yaml 值与硬编码一致,无可见差异;若策划把 `stack_rule` 改"叠层"完全无效。

---

## 五、休眠配置(形态 4:loader 解析但零 caller)· 21 字段

> 判据:yaml 有字段、loader 解析了,但结果对象/属性**无任何生产 caller**。严格说无"字面量取值点"(行为缺失或被替代),故不单列为背离,属本单方法第 4 形态;是接线/删配置的主要候选。

| # | 字段 | yaml | loader | 零 caller 说明 / 替代路径 |
|---|---|---|---|---|
| 1 | `combat.critical.max_damage_multiplier` | numbers.yaml:137 | numbers_config.dart:1748 | 自述"信息性上限,不作运行时 clamp";暴击走固定档(damage_calculator.dart:196-200),无 clamp 分支 |
| 2 | `combat.qi.chain_recovery_pct` | numbers.yaml:80 | numbers_config.dart:1308 | "连锁恢复"机制不存在;唯一真气回复是群战 waveIntermission(喂另一字段) |
| 3 | `inner_demon.failure_penalty.internal_force_multiplier` | numbers.yaml:1657 | inner_demon_def.dart:256-266 | 惩罚改版:`applyFailurePenalty`(inner_demon_service.dart:160-193)不扣内力,改挂"内息紊乱";测试锁定不扣内力 |
| 4 | `inner_demon.failure_penalty.internal_force_floor_pct` | numbers.yaml:1658 | 同上 | 同上(内力地板无意义) |
| 5 | `inner_demon.failure_penalty.sub_cultivation_multiplier` | numbers.yaml:1660 | 同上 | 代码内自标 UNUSED;只扣主修(`mainCultivationMultiplier` 被消费,:183) |
| 6 | `inner_demon.failure_penalty.debuff_id` | numbers.yaml:1661 | 同上 | 余毒走 `innerBreathDisorderHoursRemaining` 时数,不按 id 派发 |
| 7 | `inner_demon.failure_penalty.debuff_clear_via_retreat_hours` | numbers.yaml:1662 | 同上 | 清解走实际闭关时长/战斗结算/离线,无硬编码 8 |
| 8 | `sect_recruit.encounter_base_prob` | numbers.yaml:1916 | numbers_config.dart:2686 | 奇遇招收概率实际由 `encounters.yaml` per-event `baseProbability`(:1229/1248/1267)掌管并接 rng roll;numbers 侧旋钮挂空 |
| 9 | `jianghu.triggers.encounter_npc_delta_min` | numbers.yaml:1900 | numbers_config.dart:2408-2411 | NpcRelation 机制未实装:`NpcRelationService.upsert` 生产 0 caller,仅测试调 |
| 10 | `jianghu.triggers.encounter_npc_delta_max` | numbers.yaml:1901 | 同上 | 同上 |
| 11 | `jianghu.enmity.enemy_attack_power_mult` | numbers.yaml:1893 | numbers_config.dart:2372-2373 | loader 注释自认"schema 占位,0 caller";敌方加成复用 `player_attack_power_mult`(双向对等设计) |
| 12 | `sect_management.demo_initial_count` | numbers.yaml:1921 | numbers_config.dart:2716 | 领地清单整体数据驱动(territories.yaml 恰 6 条),无按 count 截断;纯描述 |
| 13 | `light_foot.stage_terrain` | numbers.yaml:1735 | light_foot_def.dart:53-61 | **双真相源**:地形实际取自 `stages.yaml` `terrainBiome`(:5438 等)→ light_foot_strategy.dart:41/49;numbers 侧副本零 lookup |
| 14 | `StageDef.towerLayer` | stages.yaml 无条目 | stage_def.dart:136 | 塔走独立 `towers.yaml`/TowerFloorDef,关卡↔塔层不经 stages.yaml |
| 15 | `FactionDef.npc_ids` | factions.yaml:17 等(六派全空) | faction_def.dart:23-25 | schema 占位;NPC↔门派关联实际由 StageDef.factionId / EncounterDef.affectsReputation 建立 |
| 16 | `TerritoryDef.initialOwnerSectId` | territories.yaml:21 等(全 null) | territory_def.dart:33 | 初始领地 seeding 未实装;ownership 唯一权威源=动态 `Sect.territoryIds` |
| 17 | `animation.readable_victory_min_ms` | numbers.yaml:1598 | numbers_config.dart:1923 | 纯诊断锚点;胜利节拍走 `victoryHandoffDelayMs`/`keyMomentHoldMs`;yaml(14000)与 Dart 默认(10000)已漂移 |
| 18 | `animation.shake_offset_px` | numbers.yaml:1602 | numbers_config.dart:1927 | 批次 2.4 起废弃,震幅改走 `combat.impact_feedback` 分档(该链是活的) |
| 19 | `inheritance.founder_ancestor_buff.cultivation_progress_pct` | numbers.yaml:1430 | numbers_config.dart:633 | yaml 自注"未生效 · Phase 5+ 接公式";修炼度机制无 buff 注入点 |
| 20 | `TechniqueDef.speedBonus`(per-心法) | techniques.yaml 每条目 | technique_def.dart:85 | **被影子替代**:速度实际按主修心法 tier 查 `numbers.techniqueSpeedBonus`(derived_stats.dart:157),per-心法值不参与公式 |
| 21 | `TechniqueDef.internalForceGrowthBonus`(per-心法) | techniques.yaml 每条目 | technique_def.dart:83 | 内力上限纯按境界 `RealmDef.internalForceMax`(character_advancement_service.dart:95),无心法成长环节 |
| (+预留) | `SectCandidateDef.targetSectId` | sect_candidates.yaml 未配置 | sect_candidate_def.dart:75 | 文档化预留(1.2 跨派系启用);当前招收落派硬编玩家门派(sect_recruit_handler.dart:81/127),yaml 无值可背离 |

---

## 六、非背离(抽样,证明扫过)

以下经深核**确认配置生效或硬编码合理**,不计入背离:

- **假阴还原(计算 getter / accessor / 私有字段)**:`attackRetreatMs`(经 `attackTotalMs`)、`SkillProficiencyEffects` 四私有字段(经公开 `*At()` 方法,战斗主线活消费)、`realmScalePerTier`/`experienceRealmScalePerTier`(经 `realmScaleFor()`/`experienceRealmScaleFor()`)、`enabledWhenAlive`(经 getter `isActive` → founder_buff_service.dart:39)、`ExpeditionDepthCurve`(经 `enemiesForNode`)、桃花岛 `capBase/capPerLevel`(经 `capFor`)、`RareBonusTier.chance/chanceNgPlus`(经 `chanceFor`,接 rng roll)、`RealmAdvance`/`CycleDropBonus`/`cycleBossPhases`/`CycleEvolution`(经 accessor)、`SynergyDef.assistSchool/requiredMain/Assist`(经 `matches()`)、`EncounterDef.outcomeMapping`(经 `resolveOutcome`)、`SchoolCounterMatrix.countered`(经 `multiplierFor`)、`ReadableFirstClear` 两血量倍率(经 `hpMultiplierFor`)、强化 `successCurve/minLevel/materialPenalty/cost`(经 `successRateFor` 等)。
- **加载期校验/debug 消费(合理)**:`RedLinesConfig` 四字段(validation/redline_audit)、`WeaknessConfig.minMult/maxMult`(加载期值域校验)、`QiConfig.deltaAbsCap`(qiDelta 绝对值校验)、`TaohuaBuildingSynergyConfig.maxRateBonusPerSourceLevel`(rule 合法性上界)、`SkillDef.mountDeferred`(红线校验豁免旗标)。
- **合理硬编码 / 测试兜底**:`EncounterService.fortuneSensitivity=20.0`(仅旧测试 fixture,生产注入 `attributeEffects`)、injury 展示层 `?? 3/0.85/0.15`(与 yaml 同值的防御回退,真行为走 injury_service)、强化 `_fallbackFormula`(+20-49 段 yaml 以 `success_formula` 显式授权)。
- **内容文件**:narratives/lore/events 为文案,整段加载呈现;events 触发概率接 `triggerProbability`/`baseProbability` 配置并经 rng roll,未见字面量旁路。

其余 538 个强类型字段业务引用 ≥1,抽查(`skillUnlock/treasureDrop/cycleEvolution/heroCamera/taohuaIsland` 等)均配置驱动。

---

## 七、相邻硬编码(非 Q2 背离,但涉 §5.6,供收口参考)

这些**没有对应 yaml 字段**(属"该配置而未配"),不构成 Q2"配置被旁路",但同为硬编码,列出供 Claude 收口时一并评估:

- `lib/features/expedition/domain/expedition_rules.dart:127-130` 瘴蚀"第 31 节点起每 5 节点 +1 层"(30/5 写死)、`:139` 断魂帖里程碑 `% 10` 写死——expeditions.yaml 无对应键(其 `zhangshi_pct_per_layer` 有配且被消费)。
- `lib/shared/effects/screen_shake.dart:6` 默认 `amplitude = 4.0` 字面量;`lib/features/equipment/presentation/enhance_dialog.dart:294` 不传 amplitude 走该默认——装备强化屏震动不读任何 yaml(战斗屏震走 impact_feedback 配置)。
- `lib/features/sect/presentation/widgets/sect_event_dialog.dart:85` 用 `Random.nextBool` 模拟 50/50——yaml 未声明门派事件战斗胜率,属文档化 Demo 占位(Phase 4 待接真战斗)。

---

## 八、[BLOCKED] / 待拍板

本单无硬性 BLOCKED。以下为**处置建议**(留一句话,最终由 Claude 收口,涉数值红线不硬做):

1. **B1 rarity**:接线概率 roll(接 rngProvider)或明确降级为设计锚——涉 GDD §4.1 强制规则,需拍板。
2. **B2 supply_cap / B3 stage_boss_recruit_prob**:二选一——让业务读 loader 值(删字面量/删硬校验),或删 yaml 字段改标注设计锚;B3 还需**纠正三处误导注释**。
3. **B4 enabledInDemo / B5-B8 heritage**:接线开关或删字段;heritage 四字段 yaml 注释"已实装"与"值未被读"矛盾,需澄清口径。
4. **P1 zhengWu / P2-P3 门派附带效果**:接线布尔/目标路由,或删字段标注"结构性固定"。
5. **休眠 21 字段**:心魔惩罚 5 字段 + `inner_demon_service.dart:152-153` 陈旧 docstring 需对齐;桃花岛 `stage_terrain` 双真相源建议删 numbers 侧副本。

---

*本报告零代码改动;脚本仅存于临时目录,未入仓。所有计数为本会话实跑所得。*
