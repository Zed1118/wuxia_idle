# Ch7「（暂名·北派线）」· 二流首章设计 spec（2026-07-17）

> 二流内容周期第 1 章 · 真传位新弧开篇。承 wave-b spec（`2026-06-11-wave-b-24-skills-content-design.md`）2 孤儿招挂账。
> 本 spec 定**设计与验收**，不落逐关数值/敌队/掉落（留实现计划）。范围=**仅 Ch7**（Ch8-9、塔二流段=后续独立 spec）。

## 0 · 现状锚（Phase 0 实测 · 2026-07-17 worktree）

- **主线 Ch1-6**，Ch6=飞升终章（李寒昆仑化境·硬收束，`data/narratives/chapters/chapter_06.yaml` title=「飞升」）。末 Boss 西凉霸主 `realmTier: sanLiu`（enemy id `enemy_wuSheng_xiliang_bazhu`，id 是武圣但被 Lv100 批 re-tier 到三流·熟练）。
- 塔封顶三流。发布上限 `max_absolute_realm_level: 17`（二流·熟练）。**全游戏唯一二流内容 = 断魂庄闻九针**。
- **2 孤儿招 `mount_deferred: true`**（`data/skills.yaml`）：千钧坠岳（刚·tier3 二流·`mainline_drop` 真解，powerMult 2800）+ 烛影摇红（阴·tier3 二流·`fragment` 残页，powerMult 2600）。二者已在**真解 2/2/2、残页 3/3/3 配平池内**（源 wave-b spec §1 line 30/36 + 现状订正 note），各只缺 1 个二流 Boss 掉落槽。
- **灰衣人** = Ch3 章末 Boss（`stage_03_05`「一剑封名」，enemy `enemy_erLiu_huiyi`，`school: yinRou`，id 二流亦被降学徒），槐树下双手空空的神秘符号；stage_04_05 以十年作对照。千钧坠岳描述=「灰衣人**夺自北派**的重手功夫」→ 用的是偷来的刚猛。**北派 lore 仅此一提（种子，Ch7 内建成）**。
- 主角机制：`founder`=玩家塑形（名可改）；`first_disciple` 大弟子=二流·启蒙 senior，全主线通关（stage_06_05）拜入；真传位 `performAscend(promotedDiscipleId)` 已实装。narratives 硬编「李寒」29 处（文学第三人称，与玩家 founder 名脱钩=既有软妥协）。

## 1 · 定位 & 主角

- Ch7 = 二流首章，**真传位新弧开篇**；李寒飞升为**太祖背景**（第三人称回望/门户交托）。
- **主角 = 继位大弟子/新任掌门**，角色化称呼 +「你」，**无固定名**（匹配弟子 role-based；不引入第二个固定名）。
- **tier 锁**（三系锁死自动成立）：敌人 `realmTier: erLiu`；装备掉落 ≤ **好家伙**（haoJiaHuo）；招式 = 名家功 / tier3 二流。

## 2 · 叙事弧（北派·灰衣人线，承 Ch3）

- **章首心境**：承李寒飞升——新任掌门接过门户，太祖余荫下的惶恐与责任。
- **主线钩**：十年前灰衣人夺北派重手（千钧坠岳）后隐去；李寒飞升、本门声望鹊起，北派重手门上门讨艺 / 灰衣人重现，新掌门**首次独当一面**。
- **章末拐点**：「独当一面」顿悟——第一次不靠太祖余荫赢下硬仗（二流内成长，启蒙→熟练层向）。
- **地理弧**：北方（承李寒昆仑/西，新弧转北境）——门山 → 北地关隘 → 北派山门（biome 雪原/关隘向，具体待实现计划）。
- **遗物 hook**：末 Boss / 灰衣人留一件北派信物，作 Ch8 hook（沿 Ch4-6「末 Boss 留文化承载遗物续章」体例）。
- **视角**：章首尾第三人称（称「新任掌门 / 大弟子」，非固定名）+ stage 第二人称「你」；李寒作太祖第三人称。
- **Tier 风格词**：二流（取自 `feedback_collab_mode_single_lore_workflow` 7 阶；方向=青涩 / 锐进 / 担当 / 初立，契合 fresh 继任者，低于 Ch4-6 的一流/绝顶/宗师）。**黑名单词锁**（legendary/epic/神器/传说级/无敌/血溅…）。

## 3 · 关卡结构（5 关）

- `stage_07_01..05`：`chapterIndex: 7`，`stageType: mainline`，`requiredRealm: erLiu`。逐关 name/biome/enemyTeam（二流敌队）/narrative id/dropTable（好家伙 tier）**由实现计划盘点填充**——本 spec 定框架与验收，不逐关落数值。
- 敌队机制沿现有（bossPhases/chargeSkillId/vuln 等按需），不新增机制类型。

## 4 · 末 Boss & 两招挂载（核心）

- **stage_07_05 章末 Boss = 北派重手宗匠**（刚猛·二流）。`chargeSkillId: skill_qian_jun_zhui_yue`（破招首通掉同招真解，沿西凉霸主/青锋绝「破他的招、学他的招」canon）；真解 mult 须 > 该 Boss 其余 powerSkill（AI 蓄力自动选，实装逐 Boss 核）。
- **千钧坠岳挂载**：删 `mount_deferred` → `stage_07_05` 加 `dropSkillManualId: skill_qian_jun_zhui_yue`（真解，首通 `markUnlocked`）。红线④ source=mainline_drop ✓。
- **烛影摇红挂载**：删 `mount_deferred` → **灰衣人作章中 Boss（阴柔）**，非末 Boss（Ch3 用偷来的刚猛重手，Ch7 显阴柔本命袖艺）；其关加 `dropSkillFragmentId: skill_zhu_ying_yao_hong`（残页，重打该关累加达阈解锁）。红线⑤ source=fragment ✓。Boss school（阴柔）与真解无涉；本关不掉真解。具体关序（07_03/04）留实现计划。
- **配平影响（零 rebalancing）**：两招原就是真解 2/2/2（刚·Ch3）与残页 3/3/3（阴·f15）的目标成员，挂载只补掉落槽、**不改配平数值**。挂载后两招进「发布阶 drop 招挂载完备」（红线⑦，每招恰 1 挂载点）。**实现计划须复核 3 测**：`test/data/wave_b_content_redline_test.dart` / `test/data/skill_source_redline_test.dart` / `test/features/cultivation/wave_b_drop_skill_wiring_test.dart`——预期配平数值不动，需更新的是任何**断言两招 `mount_deferred` 状态**的测。

## 5 · 红线（loader fail-fast + 红线测·写约束语义）

- 挂载红线④（`dropSkillManualId`→mainlineDrop）⑤（`dropSkillFragmentId`→fragment）⑥（drop 招须 style+tier）⑦（挂载完备）全过。
- 二流 tier lock：敌队/掉落 tier ≤ 二流（`_enforceEncounterSkillRedLines` / equipment tier）。
- **pubspec 声明**：若 narrative 新增目录/文件，补 `pubspec.yaml` 声明（守 `pubspec_asset_declaration_test` asset 可达红线）。
- 红线测写**约束语义**（白名单/集合自洽），不硬编瞬时数字（沿 `feedback_red_line_test_semantics`）。

## 6 · 内容产物 & 验收

- **narrative**：`chapter_07.yaml`（prologue/epilogue，第三人称）+ 10 段 stage opening/victory（第二人称）+ 1-2 段 defeat，**~4-6k 字**，承上体例（师父/太祖遗言或顿悟回响 3 处贯穿：章首承上 / 章末启下 / defeat 回响）。
- **lore/equipment**：好家伙 tier 掉落（复用现有或新增，实现计划盘点）；北派信物遗物（叙事物件，非数值）。
- **测试**：stage 加载 / 两招挂载 wiring / wave_b 3 测 / narrative 完整性（asset audit）/ 批末全量 `flutter test --no-pub`（并发）。
- **视觉验收**：Ch7 复用现有 BattleScreen / mainline flow，**无新 UI route**；新 biome 背景图若缺走 `Image.asset errorBuilder` 兜底（不破布局，美术素材另拍板）。

## 7 · 非目标 / 依赖 / 风险

- **非目标**：Ch8-9、塔二流段、断魂庄 `suo_mai_zhen`（已 C2.4 处理，不动）、`SkillSource.gauntlet` 简化（候选#2 独立）。
- **依赖**：北派/灰衣人 lore 建成（Ch7 内产）；好家伙装备够用（待盘点，不够则新增）。
- **风险**：① wave_b 配平实测——预期零数值改，但断言 deferred 的测须更新；② 二流 biome 美术若缺需拍板（errorBuilder 兜底）；③ 去固定名后章节第三人称文学锚较弱（已知取舍，用户已拍）。

## 8 · 已拍板 / 默认项

- **用户已拍**：新一代主角·真传位新弧 / 角色化「新任掌门」+你（无固定名）/ 北派·灰衣人 arc / Ch7 单章范围 / 整体设计。
- **bg 默认（可推翻，记 backlog 候补）**：章名暂缺（narrative 批定）；biome/敌队/掉落逐关数值留实现计划；遗物具体物件留 narrative 批。
