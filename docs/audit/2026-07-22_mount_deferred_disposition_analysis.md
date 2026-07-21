# mount_deferred 招处置分析（6 招档案 + 机制 + 处置选项）

> 日期：2026-07-22 · 夜间自主批 E（只读分析·证据链闭合）
> 触发：07-21 全量审查发现 4 招疑似无获取路径；本分析扩展至全部 6 招挂账/未挂账招，供「绝顶段是否收编」拍板
> 关联：Ch13 spec §10 待拍板 #4/#5（PR #51）· NEXT.md 下波候选「mount_deferred 招最终处置」

## 0. 关键前提：发布上限与豁免口径（后文全以此为据）

- 当前发布上限 `max_absolute_realm_level: 28`（`data/numbers.yaml:205-206`，Ch12 抬 26→28，注释明示「releaseTier 仍 yiLiu·不触发新阶 mount_deferred」）。
- `releaseSkillTierCap = yiLiu.index + 1 = 4`（RealmTier 枚举 `lib/core/domain/enums.dart:22-30`；validator 计算 `lib/data/validation/skill_red_lines_validator.dart:109`）。
- 红线⑦ 挂载完备只校验 **source ∈ {mainlineDrop, fragment, gauntlet} 且 tier ≤ 4 且 !mountDeferred** 的招（`skill_red_lines_validator.dart:182-228`）。三重豁免口：① `mountDeferred` 标记（:186-187/:195-196）；② tier > 4 高超发布阶（:188/:197）；③ source 不在三类内（special/encounter/technique 根本不进入⑦）。
- 测试侧同口径：`wave_b_content_redline_test.dart:40-53`（真解）与 `:86-99`（残页）同样按 `!mountDeferred && canEquipAtRealm(releaseTier)` 过滤。

## 1. 逐招档案（6 招）

### A 类（已标 mount_deferred）

**① skill_feng_juan_liu_sha 风卷流沙** — `data/skills.yaml:2933-2952`
- 定义：lingQiao / tier 4 / powerSkill / mult 3200 / qiDelta -30 / CD 4 / source mainline_drop / `mount_deferred: true`（:2947，注释自述：Ch10 弃用改止水诀，预留后续一流章）。
- 引入史：`5680ea2c`（2026-06-11 波B 14 招内容批）引入**并已挂载** Ch4 章末（西凉霸主 chargeSkillId + dropSkillManualId 双用）；`6fb89640`（2026-07-14 重排主线至三流境）从 stages.yaml 摘除；`c0dcf67f`（2026-07-20 Ch10+cap24）补标 mount_deferred。
- 全库引用（除 skills.yaml）：**零**——无掉落、无秘籍 item、无 encounter、无代码、无测试直接引用。仅 docs：ch11 spec:37、ch12 spec:34-35（继续搁置，处置待拍板）。
- 主题：大漠·流沙·身法，边塞意象；Ch9 已收束边塞。

**② skill_jin_gang_fu_mo 金刚伏魔** — `data/skills.yaml:3080-3098`
- 定义：gangMeng / tier 4 / mult 3000 / qiDelta -30 / CD 4 / source fragment / `mount_deferred: true`（:3094）。
- 引入史：`5680ea2c` 引入并挂载**塔 20 层**（`dropSkillFragmentId`）；`0b104a64`（2026-07-14 重校塔节奏）摘层（同 commit 还摘 15 层 zhu_ying、25 层 jing_hong、30 层 yue_luo）；`c0dcf67f` 补标 deferred。
- 全库引用：秘籍 item `item_scroll_jin_gang_fu_mo`（`data/items.yaml:21`）——**该道具无任何掉落源**；测试引用 `scroll_firstclear_gate_test.dart:168`（白名单 fixture）；文档 `docs/audit/tower_structure_review_2026-06-28.md:39`。
- 主题：禅门伏魔杵法，佛门/宗门气质——与绝顶段「名门/中州」向章节天然契合。

**③ skill_guan_shan_ba_ji 关山拔戟** — `data/skills.yaml:3140-3158`
- 定义：gangMeng / tier 4 / mult 3100 / qiDelta -30 / CD 4 / source fragment / `mount_deferred: true`（:3154）。
- 引入史：`5680ea2c` 引入并挂载 **Ch4 章末重打残页**；`6fb89640` 摘；`c0dcf67f` 补标 deferred。
- 全库引用：秘籍 item（`items.yaml:24`，同样无掉落源）。测试引用 3 处，均锁定「未投放」现状或作 fixture：`fragment_source_test.dart:30-40`、`wave_b_drop_skill_wiring_test.dart:296-315`、`scroll_firstclear_gate_test.dart` 等。
- 主题：阳关古道戍卒戟法，边塞/阳关族（与阳关无故人同族）。

### B 类（无标记、无挂载）

**④ skill_yang_guan_wu_gu_ren 阳关无故人** — `data/skills.yaml:2974-2992`
- 定义：yinRou / **tier 6（宗师）** / mult 4000 / qiDelta -30 / CD 5 / source mainline_drop / **无 deferred**。
- 引入史：`5680ea2c` 引入并挂载 Ch6 章末（西凉霸主，双用）；`6fb89640` 摘。此后再无挂载。因 tier 6 > 4，**任何 cap ≤ 一流时天然豁免⑦，从未需要标记**。
- 全库引用：仅一处**腐烂注释**——`stages.yaml:1521`，现 stage_06_05 西凉霸主蓄力技已是 `skill_xie_yu_chuan_lian`，行尾注释仍写「Boss 招牌蓄力技『阳关无故人』」（重排残留，建议顺手修）。
- 主题：描述自证「西凉霸主压箱底的绝学。一掌出，关山寂寂，故人不复」——Ch4「西出阳关」原生源，边塞/阳关族。

**⑤ skill_fu_mai 拂脉** — `data/skills.yaml:2836-2855`
- 定义：yinRou / 无 tier / mult 800 / qiDelta -30 / CD 3 / **source special / canInterrupt: true** / proficiency 均衡型（interrupt_power_pct 0.20）。
- 引入史：`e7fc6f83`（2026-06-11 波A T3+T4）——三流派破招技批（破势=刚猛/截影=灵巧/拂脉=阴柔），**不是 drop 招，是破招槽机制件**。
- **更正 07-21 审查口径**：破招技**无需解锁**——破招槽 gate 只查 `canInterrupt && style == school`，不查 unlock（`skill_loadout_service.dart:74-79`）；autoFill 自动填本流派破招技（`skill_loadout.dart:150-159`）；旧档 5 槽全空 fallback 也自动带（`battle_state.dart:474-478` + `_matchingInterruptSkill`:28-37）。**阴柔角色天然持有拂脉**，它是三流派破招 1/1/1 配平的阴柔件，非遗漏内容。
- 豁免机制：source special → 红线③ 要求 canInterrupt 必须 special（`skill_red_lines_validator.dart:122-126`），同时 special 不进⑦——双向自洽，永不需要挂载。

**⑥ skill_shi_dang_shi_jue 十荡十决** — `data/skills.yaml:2954-2972`
- 定义：gangMeng / **tier 5（绝顶）** / mult 3600 / qiDelta -30 / CD 5 / source mainline_drop / 无 deferred。
- 引入史：`5680ea2c` 引入并挂载 Ch5 章末（三弟子，双用）；`6fb89640` 摘。tier 5 > 4，当前天然豁免⑦；**一旦 cap 抬进绝顶（tier 5），它立刻暴露**——要么挂载要么补标，这是 B 类里唯一有时限的。
- 全库引用：`wave_b_drop_skill_wiring_test.dart:139-149` 作 tier gate fixture（grantManual 后 xueTu 装配 → SlotEquipTierLocked）。
- 主题：西凉军中马战杀法，gangMeng，军战/边塞气质；tier 5 = 绝顶段原生档位。

### 为何 4618 测全绿（机制总结）

1. feng_juan/jin_gang/guan_shan（tier 4，在发布阶内）：靠 `mount_deferred` 豁免⑦（`skill_red_lines_validator.dart:186-187/195-196`）+ wave_b 测同口径（`wave_b_content_redline_test.dart:44/:90`）。
2. shi_dang(t5)/yang_guan(t6)：靠 tier 超发布阶豁免⑦（:188/:197），wave_b 测同口径（:45 canEquipAtRealm/:91）。
3. fu_mai：source special 不进⑦；且红线③反向要求它必须 special。
4. **配平测不分挂载状态、全池计数**（`wave_b_content_redline_test.dart:102-155`）：真解池（除 gauntlet 敌队 + standaloneBossManualIds 白名单 :136-142）= {qingshan, xie_yu, qian_jun, feng_juan, shi_dang, yang_guan} 2/2/2；残页池 9 招 3/3/3（含金刚/关山）；破招池 {po_shi, jie_ying, fu_mai} 1/1/1。**未挂载招在配平里占名额——这是「不挂也绿」的核心，也是删除选项的最大成本点**。
5. 专项测反向锁定未投放现状：`fragment_source_test.dart:30-40`、`wave_b_drop_skill_wiring_test.dart:296-315`。
6. 计数契约：`skill_count_contract_test.dart:28/38/43-45`（skills.yaml 212 + encounter 40 = 252，GDD 表格字符串硬匹配）；`game_repository_test.dart:57-65`（252 + 逐批注释链）；`skill_qi_redline_test.dart:57`（252）。

## 2. 技能获取路径接线方式（现存例子，供收编选型）

| 机制 | 例子 | 适用 source |
|---|---|---|
| stages.yaml `dropSkillManualId`（Boss 关首通必给；双用 canon 要求同关 Boss chargeSkillId == 该招） | `stages.yaml:1768`（stage_07_05 千钧坠岳）；双用强约束在 `wave_b_content_redline_test.dart:29-37` | mainline_drop |
| stages.yaml `dropSkillFragmentId`（章末重打概率掉残页，集齐 5 片） | `stages.yaml:1717`（stage_07_04 烛影摇红） | fragment |
| towers.yaml `dropSkillFragmentId`（塔 Boss 层每胜概率掉） | `towers.yaml:131`（floor5 开碑手）、`:268`（floor10 燕子三抄）；**floor 15/20 Boss 层残页位现空置**（`towers.yaml:479-483/:663-667`） | fragment |
| items.yaml `techniqueScroll.unlockSkillId` + 关卡 loot 投放秘籍道具（首通 gate） | `items.yaml:18` + `stages.yaml:284`（开碑手秘籍首通必得）；6 款未投放 scroll 已备（`items.yaml:21-26`） | 与残页并行（kai_bei 双通道先例） |
| boss_gauntlets.yaml `first_clear_reward_skill_id`（副本首通） | `boss_gauntlets.yaml:18`（锁脉针，source gauntlet） | gauntlet |
| encounters.yaml outcome `unlockSkill` | `encounters.yaml:36-40`（skill_encounter_ting_yu_jian） | 仅 encounter 池（红线②） |
| 破招槽 autoFill 免解锁（special ∩ canInterrupt） | `skill_loadout.dart:150-159` | special（拂脉现状） |

## 3. 处置选项（用户拍板）

### A 类（feng_juan / jin_gang / guan_shan，已标 deferred，tier 4 在发布阶内）

| 选项 | 内容 | 测试契约影响 | 红线/数值风险 | 主题契合 |
|---|---|---|---|---|
| **A1 收编绝顶段挂载** | feng_juan 挂绝顶段某边塞/大漠章末 Boss（双用）；jin_gang remount 塔 20 层、guan_shan remount 塔 15 层或绝顶章末重打（恢复 5680ea2c 原设计），删 3 个 flag | **零契约改动**：⑦ 挂载后自洽；配平池不变；wave_b 测双用/残页不重复挂载天然满足；只需删 flag | 真解双用需过 cost ≤ Boss 内力预算（`wave_b_content_redline_test.dart:157-176`），mult 3200/3100/3000 远低于 8000 上限 | jin_gang 佛门杵法契合名门/绝顶；guan_shan/feng_juan 边塞族，**要求绝顶段有西域/大漠章**，否则硬塞 |
| **A2 专门 fragment farm 批**（只收 2 款残页） | jin_gang/guan_shan 塔 15/20 层 remount（两个 Boss 层残页位正空着），scroll 道具可同步投放或继续闲置；feng_juan 单独再议 | 同上，零契约改动；`fragment_source_test:30`「guan_shan 未投放→null」**需改写为断言新来源** | 无 | 残页与主题解耦（塔层 farm 无叙事），契合度要求最低 |
| **A3 删除并同步计数** | 删 3 招 + 2 个 scroll item | 重：252→249（`skill_count_contract_test:28/38/43-45`、`game_repository_test:57-65`、`skill_qi_redline_test:57`、GDD 表两行字符串）；**配平破**：真解 ling 2→1、残页 gang 3→1（`wave_b_content_redline_test.dart:144-154`），需补招或重定义配平池；`fragment_source_test:30`、`wave_b_drop_skill_wiring_test:139/147/314`、`scroll_firstclear_gate_test:168-170`、loot/item_type fixture 全要清 | 无数值风险，但配平补招 = 变相新内容批 | — |
| **A4 继续 deferred** | 不动，flag 留挂 | 零 | 零；但 ch12 spec:35 已把「最终处置」列为待拍板项，继续拖 = 挂账制度化 | — |

### B 类（yang_guan / fu_mai / shi_dang，无标记）

| 选项 | 内容 | 测试契约影响 | 红线/数值风险 | 主题契合 |
|---|---|---|---|---|
| **B1 shi_dang 收编绝顶段 + yang_guan 补标挂账 + fu_mai 不动** | shi_dang（t5=绝顶档）作绝顶段某章末真解双用挂载；yang_guan（t6=宗师档）补 `mount_deferred: true` + 注释「留宗师段阳关/西凉回访章」（现在补标零影响，cap 到宗师时已被挂账覆盖）；fu_mai 不动（机制件非内容招），可在 :2847 注释补一句「破招技走破招槽免解锁，无需挂载」 | shi_dang 挂载：配平池不变（它本在池内），⑦ 满足，双用/cost 测同 A1；yang_guan 补标：零（t6 仍豁免，标记只是挂账显性化）；fu_mai：零 | shi_dang cost 过 Boss 内力预算即可；yang_guan mult 4000 < 8000 | shi_dang 军战杀法配绝顶段「压场」章；yang_guan 是 Ch4 西出阳关原生招，宗师段西域回访天然收编位 |
| **B2 全部补标 deferred 挂账，绝顶段不收** | shi_dang/yang_guan 补标；fu_mai 不动 | 零 | shi_dang 在绝顶 cap 下靠 flag 豁免——**但等于把 Ch5 原生真解无限期挂账**，与 A4 同病 | — |
| **B3 删除** | 删 yang_guan/shi_dang | 真解配平 2/2/2 立破（yin 失 yang_guan、gang 失 shi_dang），需补 2 招或改配平语义；计数 252→250；`wave_b_drop_skill_wiring_test:139/147` fixture 要换招 | — | 删 fu_mai **不可行**：阴柔破招 1/1/1 配平破 + 阴柔角色破招槽无招可填（机制空洞） |

## 4. 推荐（一句话）

**A2+B1 组合**：jin_gang/guan_shan 走塔 15/20 层残页 remount（空位现成、零契约改动、恢复原波B 设计），shi_dang 作绝顶段章末真解收编（tier 5 本就是绝顶档），yang_guan 补标 deferred 挂账留宗师段「西出阳关回访」，fu_mai 不动只补注释；**feng_juan 单独留待绝顶段 spec 拍板**——若绝顶段有大漠/边塞章则 A1 收编，无则届时再决（继续 deferred 或删除+补 1 灵巧真解），它不阻塞任何现役契约。理由：该组合把 6 招中 4 招的挂账清零且几乎零测试 churn；唯一有契约代价的 feng_juan 删除项被推迟到信息更足时（绝顶段主题定了）再拍，符合「不强用不强删」（ch11 spec:37）既有基调。

## 5. 附：顺手可修（与本决策无关的腐烂点）

- `stages.yaml:1521` 注释仍写「阳关无故人」但实挂 xie_yu_chuan_lian（6fb89640 重排残留）。
- `items.yaml:21-26` 六款 scroll 道具无任何掉落源（含 3 款非 deferred 的 jing_hong/ma_ta/ye_yu，t5/t6 未暴露），若选 A2 可让 jin_gang/guan_shan 两款随挂载投放，其余继续闲置或一并清理。
