# Ch8「（暂名·北追线）」· 二流第 2 章设计 spec（2026-07-18）

> 二流内容周期第 2 章 · 真传位新弧续篇。承 Ch7「北望」（`2026-07-17-erliu-content-ch7-design.md`）「灰衣人未擒 + 北派铜符指更北」双 hook。
> 本 spec 定**设计与验收**，不落逐关数值/敌队/掉落/biome（留实现计划 Phase-0 盘点）。范围=**仅 Ch8**（Ch9、塔二流段=后续独立 spec）。

## 0 · 现状锚（Phase 0 实测 · 2026-07-18 worktree · HEAD d8de476f）

- **主线 Ch1-7**，Ch7=二流首章（真传位新弧开篇），主角=继位新掌门（无固定名+「你」），李寒=太祖第三人称。当前主线 **35 关**（7 章 × 5·实现计划须 grep 复核 count 全站点）。
- **发布上限 `max_absolute_realm_level: 17`（二流·熟练）**（`data/numbers.yaml:206` 实测）。Ch8 **不抬 cap**——敌队 `realmTier: erLiu`，装备掉落 ≤ **好家伙**，招式 = 名家功 / tier3 二流。玩家全内容通关约三流层（远低于 cap，二流内容属 aspirational 上打，纵向余量足）。
- **灰衣人 canon**：Ch3 章末 `enemy_erLiu_huiyi`（`stage_03_05`）；Ch7 章中 `enemy_erLiu_huiyi_beijing`（`stage_07_04`·阴柔本命·`chargeSkillId: skill_zhu_ying_yao_hong` 烛影摇红残页已挂）。Ch7 epilogue：灰衣人关外现身即散、往更北去（**未擒**）；北派重手宗匠留旧铜符（北派门纹）指「更北·师父没去过的关外」。
- **孤儿招已清空**：唯一 `mount_deferred = skill_suo_mai_zhen`（锁脉针·tier2 三流·断魂庄 gauntlet 首通奖励·已 spoken for，非 Ch8 可用）。→ **Ch8 须新写 ≥1 门二流真解**（末Boss 本命），无孤儿可复用。
- **narrative 结构**：`data/narratives/chapters/chapter_NN.yaml`（章首尾）+ `data/narratives/stages/stage_NN_MM_{opening,victory,defeat}.yaml`。Ch7 = 13 文件（chapter + 10 stage + 2 defeat）。

## 1 · 定位 & 主角

- Ch8 = 二流第 2 章，**追灰衣人·铜符引路北上**；一弧收 Ch7 双 hook（灰衣人 + 铜符-更北）。
- 主角 = **新掌门**（承 Ch7·角色化「新掌门」+「你」·无固定名）；李寒=太祖第三人称回望。
- **tier 锁**（三系锁死自动成立）：敌 `erLiu`；掉落 ≤ 好家伙；招式 tier3 二流。

## 2 · 叙事弧（承 Ch7·灰衣人/北派线）

- **章首心境**：接 Ch7 尾「怀里铜符指着更北」——新掌门带符出关**主动北追**。承 Ch7「头一回自己赢」再进：不再被动应战，是独自深入师父从未涉足之地的孤绝与笃定。
- **主线钩**：铜符门纹与灰衣人所窃北派刚猛**同源**——符既引路，亦是灰衣人身世线索。循符北追，一路揭出灰衣人为何窃刚猛、为何往北逃。
- **章末拐点**：师父遗言 motif 递进——Ch7「剑到一处就听那处的风·听懂半句」→ Ch8「听懂另半句」（追索尽头对「自己的路」更深体认；具体顿悟随末Boss结局定）。
- **地理弧（更北·师父没去过）**：Ch7 止阴山北派山门 → Ch8 再北：漠南草原 → 大漠/瀚海 → 关外孤城 → 更北的北派根脉所在。**逐关 biome 由实现计划核现有枚举填**（不臆造新 biome）。
- **遗物/线索 hook**：末关灰衣人败中吐露 + 铜符终指——他惧/为某个更北的北派本源（祖庭/宗主），留 Ch9 hook（沿 Ch4-7「末 Boss 留文化承载线索续章」体例）。
- **视角**：章首尾第三人称（称「新掌门」）+ stage 第二人称「你」；李寒作太祖第三人称。
- **Tier 风格词**：二流延续 Ch7「青涩/锐进/担当/初立」，Ch8 略进（笃定/独行/追索/自立）。**黑名单词锁**（legendary/epic/神器/传说级/无敌/血溅…）。

## 3 · 关卡结构（5 关）

- `stage_08_01..05`：`chapterIndex: 8`，`stageType: mainline`，`requiredRealm: erLiu`。逐关 name/biome/enemyTeam（二流敌队 inline）/narrative id/dropTable（好家伙 tier）**由实现计划盘点填充**——本 spec 定框架与验收，不逐关落数值。
- **灰衣人章中重现**（追踪途中交手·未擒·阴柔）+ **末关决战**。敌队机制沿现有（bossPhases/chargeSkillId/vuln 按需），**不新增机制类型**。

## 4 · 末Boss & 招挂载（核心·末Boss = 灰衣人本人·用户拍板 A）

- **stage_08_05 章末 Boss = 灰衣人本人（阴柔·二流）**——追索终局擒住/决战；他被逼出**真正本命**（比 Ch7 烛影摇红更进的阴柔绝艺）。
- **新写 1 门二流阴柔真解**（灰衣人本命·`source: mainline_drop`·`style: yinRou`·`tier: 3`·powerMult 留实现计划核·守全局 ≤8000）：`stage_08_05` 加 `dropSkillManualId: <新招>`（破招首通 `markUnlocked`·沿「破他的招、学他的招」canon）；真解 mult 须 > 该 Boss 其余 powerSkill（AI 蓄力自动选·实装逐 Boss 核）。
- **成对配 bossPhase**：`chargeSkillId: <新招>` + `onEnterMechanic: chargeCounter`（成对·否则 `readable_tempo` missingBossMechanic 因 chargeRows=0 挂）。
- **章中灰衣人默认不掉招**（烛影摇红 Ch7 已挂·避重复）；如需再加残页由 narrative/实现计划另定。
- **配平影响**：新招是**独立末Boss真解**（非 wave_b 真解 2/2/2 或残页 3/3/3 配平池成员）——实现计划须核 `wave_b_content_redline` / `skill_source_redline` 语义（新招 source=mainline_drop·恰 1 挂载点·红线⑦；池不变、零 rebalancing）。

## 5 · 红线（loader fail-fast + 红线测·写约束语义）

- 挂载红线④（`dropSkillManualId`→mainlineDrop）⑥（drop 招须 style+tier）⑦（挂载完备·恰 1 挂载点）全过。
- 二流 tier lock：敌队/掉落 tier ≤ 二流（`_enforceEncounterSkillRedLines` / equipment tier）。
- **pubspec**：narrative 复用现有 `chapters/` + `stages/` 目录（Ch7 已声明），预期**无新目录**→ 无需补 pubspec；实现计划核 `pubspec_asset_declaration_test`。
- 红线测写**约束语义**（白名单/集合自洽/cap-agnostic），不硬编瞬时数字（沿 `feedback_red_line_test_semantics`）。

## 6 · 内容产物 & 验收

- **narrative（13 文件·~4-6k 字）**：`chapter_08.yaml`（prologue/epilogue·第三人称）+ 10 段 stage opening/victory（第二人称）+ 1-2 段 defeat（`08_04`/`08_05`）。**师父/太祖遗言或顿悟回响 3 处贯穿**（章首承上·章末启下·defeat 回响）。承上体例、黑名单词 0 命中。
- **lore/equipment**：好家伙 tier 掉落（复用现有或新增·实现计划盘点）；北派本源线索遗物（叙事物件·非数值）。
- **新招**：`data/skills.yaml` 加 1 门二流阴柔真解 + proficiency 表（沿现有阴柔真解锚，如斜雨穿帘/烛影摇红）。
- **测试**：stage 加载 / 末Boss 招挂载 wiring / wave_b·skill_source 红线复核 / narrative 完整性（asset audit）/ 加章 reconcile 全站点（见 §7）/ 批末全量 `flutter test --no-pub`（并发）。
- **视觉验收**：复用现有 BattleScreen / mainline flow，**无新 UI route**；新 biome 背景/敌立绘若缺走 `Image.asset errorBuilder` 兜底 + 入 `test/fixtures/known_missing_assets.txt`（美术另拍板·补图后从 allowlist 删·guard 查残留）。

## 7 · 加章 reconcile 面（实现计划逐项 Phase-0 grep·memory `feedback_wuxia_add_mainline_chapter_reconcile`）

> Ch7 实证 ~11 测站点 + 6 生产站点·**开工先全 grep 找齐硬编码假设·别打地鼠**。以下为清单，实现计划落逐个断言。

- **count 35→40**：`progression_playtest_diagnostic`（多处 + CSV evidence **byte-lock**·改敌队数值须 `UPDATE_PROGRESSION_PLAYTEST_EVIDENCE=1` 重生）/ `game_repository_test`（≥3 处：mainlineCount / 主线 N 关红线含 4-5 Boss / R3 prevStageId 单链）/ `mainline_narrative_completeness`（count + 章循环 1→8）/ `balance_simulator`（`>=` 不破·硬编码破）/ `readable_tempo`（名 + 章 ratchet）。
- **boss 计数**：`stages_boss_enemy`（isBoss 敌总数·+2）/ `boss_memory_providers`（图鉴 = isBossStage 数 + 塔）。
- **progression 级联快照**（`progression_release_budget`）：加章 exp 推高全局 Lv → 首通/全内容 Lv + cumExp 全位移·**逐值实测迭代·禁猜**（守 `reference_anti_hallucination`）。
- **tier 红线**（`mainline_stage_curve`）：章→境界映射 + 掉落 cap **cap-agnostic**（按 `requiredRealm.index` / 发布上限阶·守 `feedback_red_line_test_semantics`）。
- **生产可见性**（否则章不可达=死内容）：`chapter_list_screen._chapters` → `[1..8]` + widget 章卡计数（viewport 扩容）/ `main_menu`+`status_summary` 章循环 `<=8` / **`boss_memory_key` group index Ch8→11 偏移**（沿 Ch7→10 例·避心魔/轻功/群战 7/8/9·持久化字段不重排旧值）/ `UiStrings.chapterTitle/Hint` switch / `strings.dart` 主菜单 hint「8 章 40 关」。
- **新招**：`data/skills.yaml` + `wave_b_content_redline`/`skill_source_redline` 语义复核（新招不进配平池·恰 1 挂载点）。

## 8 · 非目标 / 依赖 / 风险

- **非目标**：Ch9、塔二流段、断魂庄、抬 cap、`SkillSource.gauntlet` 简化。
- **依赖**：北派本源/更北 lore 建成（Ch8 内产）；好家伙装备够用（待盘点·不够则新增）；biome 枚举现有值够用（不够则实现计划拍板）。
- **风险**：① 新招 powerMult/proficiency 需实测校（守 ≤8000 + AI 蓄力优先选中）；② progression 级联快照逐值实测慢（fail-fast 逐个改）；③ 去固定名后章第三人称文学锚较弱（Ch7 已知取舍沿用）；④ 二流 biome/敌立绘美术缺（errorBuilder 兜底·另拍板）。

## 9 · 已拍板 / 默认项

- **用户已拍（2026-07-18）**：做 Ch8（非塔）/ 追灰衣人·铜符北上弧 / 末Boss = 灰衣人本人（阴柔·选项 A）/ 二流段第 2 章不抬 cap / 整体设计 approve。
- **bg 默认（可推翻·记 backlog 候补）**：章名暂缺（narrative 批定·Ch7 定为「北望」）；逐关 biome/敌队/掉落数值 + 新招数值留实现计划；北派本源遗物具体物件留 narrative 批。
