# Ch10「中州」一流拐点主线章 — 设计 spec

**日期**：2026-07-20
**分支**：`worktree-ch10-yiliu`
**境界阶**：一流（yiLiu）· 主线第 10 章 · 一流三章（Ch10-12）规划之首章
**状态**：设计框架已拍板（用户 2026-07-20 批准）→ 待 review → writing-plans
**章名**：「中州」为暂定（地名，承边塞三章地名命名法；可调）

---

## 0. 拍板决策（用户 2026-07-20）

| # | 决策 | 结论 | 依据 |
|---|------|------|------|
| 1 | 规划范围 | 按**一流三章 Ch10-12** 整体规划，本次先实装 **Ch10** | 对称 Ch7-9 二流三章成功先例 |
| 2 | 发布上限 | `max_absolute_realm_level` **17→24**（一流熟练） | realmLayer 递增模式验证（见 §5） |
| 3 | 末 Boss | **加**一流真解（沿沉沙一诀模板） | 承 Ch7/8/9 章末真解体例 |
| 4 | 文化弧 | **关外收束 → 入江湖深处（中原武林）** | Ch9 epilogue 实文「边塞三程到此为止，江湖才刚往深处去」 |

## 1. 目标与范围

- **做**：Ch10 五关（stage_10_01..05）+ 一流敌招（门派绝学）+ 末 Boss 一流真解 + 叙事 ~13 篇 + cap 17→24 + 全 reconcile。
- **不做**（本 batch）：Ch11-12（仅在数值/叙事上预留 hook，不实装）。
- **红线**：守 §5.2 七阶 / §5.3 三系锁死 / §5.4 数值红线 / §5.5 在线=离线 / §5.6 不硬编。

## 2. 文化叙事弧

- **承接**：Ch9 epilogue —— 北派新掌门循铜符走完边塞（阴山→大碛→碛北），在「符尽之处」胜守井老人「那一位」，铜符凉透。结句「**边塞三程，到此地为止。江湖，才刚往深处去。身前，是他还没走过的路。**」
- **主角**：北派新掌门（第三人称「他」/ 章内第二人称「你」）。
- **一流拐点顿悟**：**从「循路」到「开路」**——师父北行、灰衣人、铜符，都是别人踩过或指引的路；一流之境 = 无符自行、走进没有指引的中原江湖。呼应师父遗言后半截「知道下一步该往哪儿迈」的**第 3 处回响**（章末兑现「不再需要符/别人的路」）。
- **地理弧**：碛北南下 → 出塞过河 → 中原北门户 → 中原武林腹地（对边塞肃杀的反面：人事繁复的江湖）。
- **末 Boss 命题**：一位「一辈子替人守路 / 循前人规矩」的中原名宿，与主角「自己开路」互为镜像（延续 Ch9「那一位」的沉默高手体例，但内核对照）。留 **1 件文化承载遗物** hook Ch11。
- **Tier 风格梯度词**（一流）：**通达 / 洞明 / 练达 / 举重若轻**（对二流「沉着 / 肃杀 / 老练 / 冷静」的内省升格）。
- **体例约束**：黑名单 14 词（legendary/epic/史诗/神器/无敌/最强/血溅/刀光剑影…）0 命中；现代词/网文腔 grep 0；字数 ~5-6k 纯正文；师父遗言/顿悟 3 处贯穿（章首 / 章末 / defeat）。

## 3. 五关结构（机制骨架 · 地名人物文案留实装 batch）

| 关 | realmLayer | school | isBoss | biome | 叙事主题（草案） |
|----|-----------|--------|--------|-------|------------------|
| 10_01 | qiMeng（一流启蒙·层22） | gangMeng | 否 | frontier→过渡 | 出碛北南下、过河，边塞与中原的界 |
| 10_02 | qiMeng | lingQiao | 否 | mountainForest | 中原北门户，江湖气息初现 |
| 10_03 | ruMen（入门·层23） | yinRou | 否（章中考验） | mountainForest | 阴柔幻/试炼，镜像「循路 vs 开路」母题 |
| 10_04 | ruMen | gangMeng | 是（章中 Boss·纯 stat 门槛） | mountainForest | 守道名宿，HP/攻墙，**无 bossPhases** |
| 10_05 | shuLian（熟练·层24=cap） | yinRou（暂定·守道内敛，对 Ch9 gangMeng 差异化） | 是（末 Boss·真解） | mountainForest | 映照命题的中原一流对手，真解双用+两相位 |

- **realmLayer 分布**严格沿 Ch7 模板（01-02 启蒙 / 03-04 入门 / 05 熟练）。
- **三派分布**沿 Ch9（刚猛/灵巧/阴柔/章中Boss刚猛/末Boss），末 Boss 流派随叙事定（Ch9=gangMeng，Ch10 可换以差异化）。
- **章中 Boss（10_04）**：`isBoss:true` + `isBossStage:true` 但**不配 bossPhases**（纯 stat 门槛；memory 红线：boss 关有 bossPhases ⟹ 必有 charge 机制）。配 `narrativeDefeatId`。
- **末 Boss（10_05）**：`dropSkillManualId` + 敌 `chargeSkillId` **双用同一真解**（破招首通 markUnlocked）；`bossPhases` 两相位（1.0 / 0.5 `aiMode:aggressive` `onEnterMechanic:chargeCounter` `titleKey`）。配 `narrativeDefeatId`。

## 4. 新增内容清单

### 4.1 一流敌招「门派绝学」（新增 6 招）
- 3 派 × (basic + skill) = 6 招，供 Ch10（及 Ch11-12 复用）一流敌人使用。
- **命名**：沿现有阶前缀规约（二流 = `skill_<school>_mingjia_<type>`）；一流前缀**实装时 grep `TechniqueTier` 枚举确认**（推测 `juexue`/`menpai`）。
- **数值锚**（守全局 ≤8000 硬红线）：以二流名家功续进——二流 skill=1800（裂石掌）→ 一流 skill 目标 ~2400、basic ~550；`qiDelta`/`cooldownTurns` 沿名家功档。精确值实装 balance 校准。

### 4.2 末 Boss 一流真解（新增 1）
- 沿沉沙一诀模板：`type:powerSkill / targetType:single / source:mainline_drop / requiresManualTrigger:false / proficiency 高半档`。
- **tier: 4**（一流门派绝学阶，对沉沙一诀 tier:3）。
- `powerMultiplier` 目标 ~3600（二流真解 3000 → 上一档，守 ≤8000）；`style` = `yinRou`（末 Boss 流派·见 §3）。
- **登记 `standaloneBossManualIds` 白名单**（`wave_b_content_redline_test`），排除出 2/2/2 流派配平池（memory 易漏点）。

### 4.3 装备（零新增·复用）
- 一流利器 `liQi` 已有 **12 件**（weapon: long_quan/pan_long_dao/lian_zi_bian/hu_tou_gou/li_hua_zhen；armor: xuan_tie_jia/qing_luo_shan/tie_ye_jia；accessory: fei_yu_pei/hu_xin_jing/jin_chuang_gao）。
- 五关 dropTable 从中搭配（每关 weapon 1.0 + armor/accessory 0.3-0.5）；心血结晶 `item_xinxuejiejing`（数量沿 Ch9 续进）+ 银两 `item_silver` + 末 Boss `item_jingyandan_large` 0.30。掉落 cap 按发布上限阶（§5.3 管上身不管掉落）。

### 4.4 叙事（新增 ~13 篇）
`chapter_10`（prologue+epilogue）+ stage_10_01..05 opening/victory（10 篇）+ 10_04/10_05 defeat（2 篇）。~5-6k 字。

## 5. 境界数值框架

- `chapterIndex:10` / `requiredRealm: yiLiu` / 敌 `realmTier: yiLiu` + `realmLayer` 沿 §3 分布。
- **cap 17→24 验证**：realmLayer 模式 = 章首递增、章内爬到熟练封顶。二流 Ch7`qiMeng`→Ch8`ruMen`→Ch9`shuLian`(封顶=cap17)。一流对称：Ch10 章内 `qiMeng→shuLian`（层22→24），cap=一流熟练=24。
- **敌人数值曲线**（设计目标·实装 balance 校准）：HP 沿 Ch9（9000→16000）续进至 ~18000→32000 量级（末 Boss 32000 **远内 60000 硬红线**）；攻 ~700→950（**内 2000 硬红线**）；`difficultyMultiplier` ~10.2→11.0；`baseExpReward` ~72→…（**progression 快照逐值实测**，见 §6）。

## 6. Reconcile 清单（~26 站点 + cap 抬升 4 站点 · 实装逐个 grep 现值）

> memory `feedback_wuxia_add_mainline_chapter_reconcile` + `feedback_wuxia_release_cap_raise_reconcile`。**开工先全 Phase-0 grep 找齐硬编码假设，禁猜（逐值实测·守 anti_hallucination）。**

**加章（count/N→N+5）**：`progression_playtest_diagnostic`（多处 + CSV evidence **byte-lock** 重生）/ `game_repository_test`（≥3 处：mainlineCount、主线关红线含 Boss、R3 prevStageId 单链）/ `mainline_narrative_completeness`（count + 章循环 1→10）/ `balance_simulator`（`>=` 不破·硬编码破）/ `readable_tempo`（名 + 章 ratchet + **终章门槛钉 `stage_10_05`**）。
**boss 计数**：`stages_boss_enemy`（isBoss 敌 +2）/ `boss_memory_providers`（图鉴 = isBossStage 数）。
**catalog / 主线可见性**：`chapter_list_screen._chapters` `[1..10]` + widget 章卡计数（viewport 扩容）/ `main_menu`+`status_summary` 章循环 `<=10` / `UiStrings.chapterTitle/Hint` switch + `strings.dart`「十章…关」/ `boss_memory_key` group index（新章 chNum 与心魔/轻功/群战撞→偏移·持久化不重排旧值）。
**progression 级联**：`progression_release_budget` + `progression_idle_horizon_simulation`（加章推高 Lv → 首通/全内容 Lv + cumExp/缺口/里程碑全位移·**逐值实测迭代**）。
**tier 红线**：`mainline_stage_curve`（章→境界映射 + 掉落 cap，改**语义化/cap-agnostic** 按 `requiredRealm.index`，不硬编快照）。
**下游级联（Ch9 补·易漏）**：加真解 → skill 计数 **3 处**（`game_repository_test` skillDefs 总池 / `skill_count_contract_test` genericIds hasLength + **交叉核对 GDD「N 招」** / `skill_qi_redline_test`）；真解白名单（`wave_b_content_redline_test` `standaloneBossManualIds`）；材料（`enhancement_material_supply_test` 结晶总量）。
**chargeSkill 成对**：末 Boss `chargeSkillId` ⟺ bossPhase `onEnterMechanic:chargeCounter`（`readable_tempo` missingBossMechanic）。
**cap 17→24 抬升 4 站点**：① 内容挂载完备测（`wave_b_content_redline`+`skill_source_redline`：`canEquipAtRealm(releaseTier)` 重算 + 补 `&& !s.mountDeferred`）② 升层门禁 e2e（`inner_demon_r5_redline` R5.3：改 cap-agnostic 读 `maxAbsoluteRealmLevel`）③ stale 文案 de-drift（`overflow_layer_jump_probe`/seclusion/game_repository「Lv100/停在层10」等 label）④ 确认不破（dynamic 读 cap 的、`progression_gate_service` 自建 fixture）。
**GDD 同步**：§8.1 章表 + 招式池「N 招」+ 发布边界层。

## 7. 验收标准

- `flutter analyze` **0 issue**；`dart format` 归一（CI format gate）。
- 批末全量 `flutter test --no-pub`（并发）**全绿**；红线测（`full_build_damage_redline`/`balance_simulator` 不进百万、`skill_qi_redline`、`wave_b` 配平）绿。
- Ch10 五关 balance 模拟：三档胜率合理（无硬墙，末 Boss 血线收尾 ~0.94-0.96 同 Ch7-9 带）；跨阶末 Boss 触发战败风险（memory `boss_balance_crosstier`）。
- 破坏性证红（改真解 mult/count 断言 → RED → 还原绿）在 commit 后做（memory `break_red_after_commit`）。
- 立绘 11 图缺 → `errorBuilder` allowlist 兜底，待 codex `image_gen` 出图（后续 batch）。

## 8. 实装切片（留 writing-plans 细化）

1. **P0 Phase-0 grep**：逐个 grep §6 所有 reconcile 站点**现值**（count/Lv 快照/skill 计数/cap 站点/TechniqueTier 前缀）。
2. **数值层**：stages.yaml +5 关 / skills.yaml +6 敌招 +1 真解 / cap 17→24 / dropTable 复用。
3. **红线层**：真解白名单 + 章中/末 Boss 机制成对 + 加载期校验。
4. **叙事层**：chapter_10 + 13 篇 narrative（体例约束）。
5. **reconcile 层**：§6 全站点逐值同步（progression 逐值实测迭代）。
6. **生产可见性**：chapter_list/main_menu/strings/UiStrings/boss_memory_key。
7. **GDD 同步** + 验收（analyze/format/全量/红线/balance）。

> Ch10-12 一流三章：本 spec 仅 Ch10；Ch11-12 复用本 spec 框架 + 敌招/真解命名体系，另起 spec。
