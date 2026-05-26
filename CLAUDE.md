# CLAUDE.md

> Claude Code 启动必读。本文件用最小篇幅让你立刻能在本项目中正确工作。
> 任何细节冲突时，以 [`GDD.md`](./GDD.md) 为准；本文件提供操作层指引。
> 内容文案规范见 GDD §6.6 装备典故 / §10.2 江湖见闻录 / `data/lore/_templates/` 既有体例(原 `WINDOWS_DEEPSEEK_GUIDE.md` 已归档 `docs/_archive/`,2026-05-19 协作模式切换 Mac+Opus 单端接管文案后退役)。
>
> **版本:v1.16**
> v1.16 变更摘要(2026-05-28 1.1 挂账清理 Batch B+C 自主工作流状态对齐):本批 0 改规则层主体(§12.2 表 #1-#13 全保持 v1.10 决议)· **1.1 挂账 2/4 闭环**:① **stageBossFailRecoverProb 战败收降 wire ✅**(`stage_boss_recruit_hook.dart` 加 `runStageBossFailRecoverHookAfterDefeat` 函数 · `stage_entry_flow.dart` defeat 路径末段 wire · `stageBossFailRecoverProb` 0.30 全局概率 · 共用 `triggeredBossRecruitStageIds` 防刷 · UiStrings 3 段 · Ch1-3 战败收降叙事 3 篇(折剑/卸刃/空手 败后));② **stage_04_05+ 池扩 ✅**(stages.yaml stage_04_05→river_drifter / 05_05→blacksmith_son / 06_05→valley_hermit 三 Boss 加 bossRecruit · sect_candidates.yaml 新增 valley_hermit(yinRou 三系平衡 5→6 NPC)· Ch4-6 战败收降叙事 3 篇(阳关/中州/昆仑 败后));③ **R5 测族更新**(stage_boss_recruit_test 8→11 + sect_recruit_test 5→6 NPC 更新);④ **降级决策**:candidateRefs rng pick 代码注释标「1.2 升」+ schema 变更影响面大 → 本批 spec-only 留 1.2。**1.0 release ready ~93% 维持** · 1.1 剩余挂账:candidateRefs rng pick(留 1.2) / Boss 招降叙事已 12/12 全齐。**状态对齐,无规则层变化**。
> **版本:v1.15**
> v1.15 变更摘要(2026-05-26 P4.1 1.1 polish 候选 1+3 一波实装状态对齐):本批 0 改规则层主体(§12.2 表 #1-#13 全保持 v1.10 决议)· **P4.1 1.1 sect 子系统全 polish 收尾 ✅**:① **候选 3 character_panel sect NPC 集成**(`_SectMembershipRow` widget 加在 `character_panel_screen.dart:_LineageSection` 内 · 沿 `_LineageDisciplesRow` 50 行体例 · ref.watch `playerSectIdProvider`(int?)+ `sectMembersProvider(sectId)` filter `!m.isFounder && m.id != character.id` 排玩家自己+前代祖师+当前 character active · 空状态「门派人少」)+ UiStrings 2 段 `panelSectMembersLabel/Empty`(沿 lineageDisciplesLabel 体例)· **Q6A closeout deviation 续:NPC sect_screen listMembers 已显 + character_panel 集成 ✅**;② **候选 1 文案扩 8 段**:Q6A 3 events outcome body 深度 4→7-8 行(bamboo/desert/mountain · accept body 加 NPC 背景动机段 / decline body 加细节场景段)+ 5 sect_candidates lore 3→6-7 行(NPC 背景/动机:母亲早逝 7 岁练剑 / 玉门关血流一夜 / 师弟出事自请放逐 / 杂学半生求归处 / 父亲炸塌成年礼 · 古风克制不滥情);③ **跳 spec doc + 跳 widget test**(候选 3 Q1-Q5 default no-brainer + filter 1 行简单 · 沿 trust the build · memory `feedback_isar_widget_test_deadlock` warning);④ verify:1505 测 baseline 维持 / 0 analyze / Pen 视觉验收续步(三项链路 + 文案 polish)。**1.0 release ready ~93% 维持** · 1.1 挂账续 stageBossFailRecoverProb 战败收降(P5+/1.1) / candidateRefs rng pick / stage_04_05+ 池扩 / Boss 招降 narrative。详 closeout `p4_1_1_polish_closeout_2026-05-26.md`。**状态对齐,无规则层变化**。
> **版本:v1.14**
> v1.14 变更摘要(2026-05-26 P4.1 1.1 Q6B stage_boss recruit B1-B3 全闭环实装状态对齐):本批 0 改规则层主体(§12.2 表 #1-#13 全保持 v1.10 决议)· **P4.1 1.1 三项收齐 ✅**(主线 Q6A v1.12 + 副线 founder_buff v1.13 + 第三项 Q6B v1.14):① **Q6B spec 拍板 + B1+B2+B3 全闭环**(branch `feat/p4_1_q6b_stage_boss_recruit` 3 commit · 1497→1505 测全过 · 0 analyze · 主对话 ~1-1.5h · 精度 0.20-0.30× · 同会话续 cache warm 三项收齐节奏);② **B1 schema+yaml**:`BossRecruitConfig` class(`stage_def.dart:155+` · 沿 `AffectsSectMembership` 体例 · candidateRef + baseProbability 默认 0.40)+ `StageDef.bossRecruit` 字段(仅 isBossStage=true 可配)+ `SaveData.triggeredBossRecruitStageIds: List<String>`(防玩家刷)+ Isar saveVersion 0.13.0 → 0.14.0 + 3 章末大 Boss(stage_01_05/02_05/03_05 跨三系 bamboo/desert/mountain)配 bossRecruit + numbers.yaml `stage_boss_recruit_prob: 0.40`(沿既存 sect_management.recruit 段加)+ `SectRecruitConfig` 加 stageBossRecruitProb 字段(numbers_config.dart) + `_enforceBossRecruitRedLines` 三重校(isBossStage / candidateRef in sectCandidates / probability ∈ [0,1]);③ **spec deviation 方案 Z**(Phase 0 漏看再补 · 用户拍):numbers_config.dart 既存 `stageBossFailRecoverProb` 0.30 P4.1 v1.10 「**战败收降**」语义 0 caller 留 P5+/1.1 不动 + 加新 `stageBossRecruitProb` 0.40 走本批「**战胜招降**」独立字段(双语义共存,不破 P4.1 既定);④ **B2 抽 helper+wire**:抽 `_handleSectRecruit` from `encounter_hook.dart:174`(~170 行)→ `lib/features/sect/presentation/sect_recruit_handler.dart`(`runSectRecruitFlow` 共用 API + `SectRecruitOutcome` enum · onMarkTriggered + onFallback 可空 callback 解耦语义 · Q6A onFallback=encounter.applyOutcome+reputation+banner / Q6B onFallback=null 静默)+ `encounter_hook` 改 wrapper 不破 Q6A 语义(closure promotion 修 triggered EncounterDef? → local final triggeredDef)+ 新 `lib/features/sect/presentation/stage_boss_recruit_hook.dart`(6 步算法:isBossStage+bossRecruit 守 → IsarSetup 守 → triggeredBossRecruitStageIds 防刷 → rng pick 0.40 → candidate 解 → runSectRecruitFlow)+ `stage_entry_flow.dart:182` wire 一行(在 runEncounterHookAfterVictory 之后顺序执行)+ UiStrings 3 段(stageBossRecruitSuccess/CapFull/NoSect);⑤ **B3 R5 测族 8 测**(`test/features/sect/stage_boss_recruit_test.dart` · stages production yaml + numbers + persistence + serviceTie e2e + 3 schema 红线 brokenLoader transform 模式(读 production stages.yaml 后 String.replace 改 1 处 inject 不破 _enforceMainlineRedLines)+ 1 compat)· closeout 42 行 ≤80。**1.0 release ready ~93% 维持** · 1.1 挂账续 character_panel sect NPC / stageBossFailRecoverProb 战败收降实装(P5+/1.1) / candidateRefs rng pick / stage_04_05+ 池扩 / Boss 招降 narrative(~10-20 条)/ events 文案扩。详 closeout `p4_1_q6b_b123_closeout_2026-05-26.md` + spec `p4_1_q6b_stage_boss_recruit_spec_2026-05-26.md`。**状态对齐,无规则层变化**。
> **版本:v1.13**
> v1.13 变更摘要(2026-05-26 P4.1 1.1 founder_buff cross_sect B1-B3 全闭环实装状态对齐):本批 0 改规则层主体(§12.2 表 #1-#13 全保持 v1.10 决议)· P4.1 1.1 第二项挂账实装 ✅(主线 Q6A v1.12 + 副线 founder_buff v1.13 两项收齐):① **founder_buff spec 拍板 + B1+B2+B3 全闭环**(branch `feat/p4_1_founder_buff_cross_sect` 3 commit · 1492→1497 测全过 · 0 analyze · 主对话 ~30-40min · 精度 0.13-0.20× · Q6A 同会话续 cache warm 后再降一档);② **B1 API 升**:`FounderBuffService.isBuffActiveFor({target, numbers, playerSectId})` 新 per-character API(`founder_buff_service.dart:54+`)+ 旧 `computeBuffActive` 委派保留向后兼容(character_panel / lineage_panel UI 不动)+ `playerSectIdProvider` legacy `Provider<int?>` 派生(`sect_providers.dart:72+` · 沿 currentSectProvider 体例 · Demo 单 sect 简化 return sect?.id);③ **B2 wire**:`stage_battle_setup.dart:97-107` per-character map 替换 P1.1 整队同一 bool inline 算 · `FounderBuffService(isar)` instance + 内部 `isar.sects.get(1)?.id` 拿 playerSectId 不引 ref dep · per-player await `isBuffActiveFor` map 传 `_playerToBattle.founderBuffActive` 参数 · derived_stats 3 caller `maxHp/critRate/internalForceMaxWithLineage` 签名不变(参数语义保留);④ **B3 R5 测族**(5 测追加 `founder_buff_service_test.dart` 末段 group):R5.1 P1.1 维持(isInSect=false → true)/ R5.2 跨派系不享(sectId=2 ≠ playerSectId=1 → false)/ R5.3 同 sect 享(sectId=1 == playerSectId=1 → true)/ R5.4 playerSectId=null fallback isInSect=false → true(Sect lazy-init race 守 P1.1 路径)/ R5.5 整体 inactive → false;⑤ **跨派系真链路解锁**:Q6A NPC 招进 isInSect=true sectId=playerSectId=1 → 享 founder buff · 1.2 跨派系 NPC(sectId=2)wire 时不享 · R5.8 delta 测从 Q6A spec §7 标延后可补回(本 spec 实装已成立 verify)。**1.0 release ready ~93% 维持**(P4.1 1.1 第二项实装 ✅ · 主线 Q6A + 副线 founder_buff 两项收齐)。详 closeout `p4_1_founder_buff_b123_closeout_2026-05-26.md`。**状态对齐,无规则层变化**。
> **版本:v1.12**
> v1.12 变更摘要(2026-05-26 P4.1 1.1 Q6A encounter recruit B1-B3 全闭环实装状态对齐):本批 0 改规则层主体(§12.2 表 #1-#13 全保持 v1.10 决议)· P4.1 1.1 第一项挂账实装 ✅:① **Q6A spec 拍板 + B1+B2+B3 全闭环**(branch `feat/p4_1_q6a_encounter_recruit` 3 commit · 1484→1492 测全过 · 0 analyze · 主对话 ~1.5-2h · 精度 0.25-0.30×);② 新 schema `AffectsSectMembership` class(`encounter_def.dart:243+` · 沿 `AffectsReputation` 体例)+ `SectCandidateDef` def(`lib/data/defs/sect_candidate_def.dart` 纯 Dart)+ 5 NPC `data/sect_candidates.yaml`(3 PoC encounter + 2 池余量)+ 3 sect_recruit fortuneEvent(`data/encounters.yaml` 30-32 段 · 跨 biome `bambooForest/desert/mountainForest`)+ 3 events 文案 + 双层加载红线(`_enforceSectCandidateRedLines` count/三系锁守 + `_enforceEncounterRedLines` 三重校 affectsSectMembership);③ wire 链路(`encounter_hook.dart` sect 分支 + `_handleSectRecruit` helper 150 行 · Sect lazy-init 兜底 + confirm dialog 二次确认 + caller 持锁 writeTxn `Character.create` + `SectMemberService.recruit` + result 处理:success markTriggered+SnackBar / fullCap 回滚+fallback applyOutcome / 玩家取消 fallback 不 mark)+ `sect_recruit_confirm_dialog.dart` AlertDialog 2 按钮 + 6 UiStrings `sectEncounterRecruit*` + `encounter_debug_picker.dart` markTriggered 分支(sect 类 skip 让 VC 反复测);④ R5 测族 8 测(`sect_recruit_test.dart`:production yaml 3 + e2e 1 + cap fallback 1 + schema 红线 broken loader 3);⑤ **spec deviation** (closeout 记):NPC 不入 `SaveData.recruitedDiscipleIds`(spec §3 提沿 P1.1 体例 · 但 sect NPC 不属师徒 inactive 池语义)· sect_screen 成员 Tab 通过 listMembers 显示足够 · 1.2 wire character_panel 集成时再加。**1.0 release ready ~93% 维持**(Q6A 是 P4.1 1.1 挂账第一项实装 ✅)· 下波 founder_buff cross_sect spec working tree 等用户拍 Q1-Q6。详 closeout `p4_1_q6a_b123_closeout_2026-05-26.md`。**状态对齐,无规则层变化**。
> **版本:v1.11**
> v1.11 变更摘要(2026-05-26 1.0 release readiness 78%→91% 状态对齐):本批 0 改规则层主体(§12.2 表 #1-#13 全保持 v1.10 决议)· 仅 1.0 release readiness 锚更新:① **`docs/RELEASE_CHECKLIST_1_0.md`** 起草(顶层长寿勾选清单 · 9 段 ~60 项 A-I · 现 ~91% release ready · 0 P0/P1 阻塞 · 剩 Pen 视觉验收 + P5.x M15-16);② **`docs/ROADMAP_1_0.md`** v1.4 升档(78%→91% · P4.1 §12.2 帮派门派 100% 闭环 + P5.0 onboarding production seed + audit v2 6 系统全过 全段对齐);③ 1.1 挂账起步双 spec 起草:`p4_1_q6a_encounter_recruit_spec_2026-05-25.md`(Q1-Q8 默认决议 · ~5-7h xhigh · 含 11 风险点 self-review `q6a_spec_self_review_2026-05-26.md`)+ `p4_1_founder_buff_cross_sect_spec_2026-05-26.md`(Q1-Q5 默认决议 · per-character `isBuffActiveFor` API · ~3-5h xhigh · 不破 P1.1 R5 红线);待用户拍板 · spec only 0 实装。**状态对齐,无规则层变化**。
> **版本:v1.10**
> v1.10 变更摘要(2026-05-24 P5+ 多代飞升 + 真传位 ④+⑤ 合并 batch 实装状态对齐):§12.2 #10 师承遗物规则层 ③+④ 字段从 v1.14「Demo 一代飞升不验证 · P5+ 多代场景实装」升「**v1.15 P5+ 多代飞升 + 真传位完整实装 ✅**」 — `stackAcrossGenerations=false` derived_stats §244 按 instance count 不按 prev len 累加(R5.8 防回退测) + `conflictSlotResolution=auto_swap` 真消费(`AscendService.performAscend` 副作用 4 · disciple 端 equipped{Slot}Id 接新遗物 · 旧装 owner 不变入背包语义) + 真传位 `AscendService.performAscend` 加 `promotedDiscipleId: int?` 可选参数(promotedDisciple.isFounder=true · founder.isFounder 保 true「太祖」语义 · founder_buff_service 0 改自然接管「active 中 isFounder=true → buff 激活」) + AscensionScreen 加 _PromotedDiscipleRow widget(player_pick 体例) + R5 测族 14→18(R5.6 多代 e2e 2 + R5.7 auto_swap 2 + R5.8 stack enforce 1)。**状态对齐,无规则层变化**。
> v1.9 变更摘要（2026-05-21 P1.1 候选 2/3 实装状态对齐）：§12.2 #11 祖师爷 buff 表述由「Demo 不实装,1.0 版本再设计」→「P1.1 候选 2 已激活,`enabled_when_alive: true`,玩家=祖师享 sect_wide_buff」（commit `a0eae82`,详 `lib/features/inheritance/application/founder_buff_service.dart`）;§12.2 #9 人剑合一追加 P1.1 候选 3-b 实装注（commit `15ff8aa`,`skills.yaml skill_joint_skill` mult=4500 + battle_ai 自动放）;§12.2 #1 enum_localizations 文件路径更新（已迁 `lib/features/battle/domain/`）+ §12.2 #6 encounter 公式行号更新（公式在 `encounter_service.dart:216`）;§12.1 末尾备注删 #11 条目（已实装无需挂账）。**状态对齐,无规则层变化**。
> v1.8 变更摘要（2026-05-19 P1 #44 协作模式切换）：DeepSeek 端文案产线退役,Mac+Opus 4.7 单端接管 `data/lore/` + `data/narratives/` + `data/events/` 写权限。§3 目录结构 3 个文案目录所有权由 [DeepSeek，禁止编辑] 改为 [你]。§8 工作流表 Windows 行删除,只剩 Mac 单行;冲突解决段简化(单端无跨端冲突)。§9 不要做的事第 3 条「修改 data/narratives/ data/lore/ data/events/」红线删除。**触发动因**:P1 #44 35 件 × 2 池 ≈ 280 条文案补齐 Mac 端接手,Opus 4.7 古风克制文学能力足够,链路简化为单端。WINDOWS_DEEPSEEK_GUIDE.md 移至 `docs/_archive/WINDOWS_DEEPSEEK_GUIDE.md` 加 DEPRECATED 头注。
> v1.7 变更摘要（2026-05-17 W18 全收口外部审查后对齐）：§7 Demo 必交付内容量表与 GDD v1.2 §8.4 同步——「奇遇 20-30」混算口径拆为「武学领悟触发 20-30 / 基础奇遇 15-25 / 节日 encounter 6-10」3 独立维度;主线字数上限 5000→7000(实测 6778);节日 encounter 6→8 备注(W17 扩 chuXi/qingMingJie);「Demo 阶段不要做」清单「节日活动」加备注(W16/W17 节日 encounter 内容层已落,系统级仍按 GDD §12.4 留 1.0)。**PROGRESS 外部审查 P1 #5 #6 销账**。
> v1.6 变更摘要（2026-05-16）：§6 核心公式块 GDD §5.3/§5.6 公式系数口误对齐——基础伤害公式装备攻击系数 ×8 → ×1.0（Phase 1 平衡前后差异，防装备轴数值膨胀）；最大血量公式内力系数 ×5 → ×0.7（Phase 1 平衡前后差异，防玩家血量超 §5.2 红线 20,000）。出手速度 ×8 无变动。GDD.md §5.3/§5.6 同步对齐 + 加历史脚注。代码以 `numbers.yaml damage_formula.equipment_attack_factor / max_hp_formula.internal_force_factor` 为准（早已平衡到位）。**PROGRESS 挂账 #6 销账**。
> v1.5 变更摘要（2026-05-16）：§12.1 #10 师承遗物规则层 4 子项决议收口——① 传递时机:武圣飞升时自动传(GDD §7.1 原意,Demo 不实装飞升 → Phase 5+ 激活) ② 多徒弟归属:玩家进选件界面逐件分配(给主动权 + UI 包不复杂) ③ 累代叠加:只取当代不叠加(数值不爆炸,5 代不会撑红线;UI 可显传承链路但 buff 不叠) ④ 同部位冲突:自动卸下原装入背包 + 新遗物入槽(sane default,不做装备分解违反 §5.1)。numbers.yaml `inheritance.heritage_items` 加 4 规则字段(`transfer_trigger: ascend_to_wusheng` / `multi_disciple_allocation: player_pick` / `stack_across_generations: false` / `conflict_slot_resolution: auto_swap`)。**§12.1 真硬阻塞清零**,Phase 5 师徒系统升级路径无 schema 歧义。
> v1.4 变更摘要（2026-05-16）：§12.1 #7 三流派 extra_effect 数值拍板收口——刚猛震伤每招 +500 固定(穿透防御不暴击) / 阴柔内伤 N=3 守方 tick × 200/tick 固定(穿透防御 + 同源刷新覆盖) / 正午阳刚 +20% 乘到 `internalForcePoints` 维度且仅 `school=gangMeng` 角色触发。numbers.yaml 加 4 子段(`combat.schools.gang_meng_quake` / `combat.schools.yin_rou_internal_injury` / `retreat.time_of_day_bonus[zhengWu].target_attribute` / `applies_to_school`)。代码层 damage_calculator 震伤分支 + BattleState internalInjurySlot + battle_engine tick 衰减 + seclusion_service 正午阳刚 wire 同期落地。§12.1 #7 → §12.2 归档,剩 #10 师承遗物 1 条。
> v1.3 变更摘要（2026-05-15）：§12.1 #7 加现状备注——`SeclusionService.computeOutputs` 已接 4 维度（节气日 +30% / 子时 +20% 只乘内力 / techniqueLearnPoints / internalForcePoints），正午阳刚 +20% 因本条 #7 流派 extra_effect 未决暂未消费，加成乘到哪个维度也待 #7 决议后才能落代码。
> v1.2 变更摘要（2026-05-15）：§12 待决清单收口——13 条经 W1-W15 实装默认决议 10 条 + 本批方案 A 决议节气清单 1 条，剩 2 条进对应系统再拍板。§12 拆 §12.1（未决）/ §12.2（已消解归档）两段。
> v1.1 变更摘要：状态管理锁定 Riverpod 3.x；爬塔 Boss 数修正为 3 小 + 3 大；§6 增散功代价公式；§5.3 明确师承遗物纳入三系锁死；新增 §12 待人类决策清单；§1 末加 GDD 快速索引；§8 加 yaml 联结示例。

---

## 1. 项目一句话

Windows 单平台、买断制、写实武侠挂机游戏。Flutter Desktop，3v3 自动战斗 + 离线挂机，首个里程碑：3 个月内出可玩 Demo。

### GDD 快速索引

| 我想查 | 看 GDD 章节 |
|---|---|
| 项目定位与基调 | §1 |
| 反主流不做清单 | §2.1 |
| 7 阶节奏与三系对应 | §3 |
| 角色 4 项属性 / 稀有度 | §4.1 |
| 心法搭配 / 修炼度 9 层 | §4.2 – §4.3 |
| 三流派克制 | §4.4 |
| 心法相生组合 | §4.5 |
| 战斗数值范围（红线） | §5.2 |
| 伤害 / 血量 / 速度公式 | §5.3 – §5.6 |
| 装备获取 / 强化 / 心血结晶 | §6.1 – §6.3 |
| 共鸣度（人剑合一） | §6.4 |
| 开锋（3 槽 build） | §6.5 |
| 典故系统 | §6.6 |
| 师徒传承 | §7.1 |
| 武学领悟（替代抽卡） | §7.2 |
| 时间锚点闭关 | §7.3 |
| 主线 / 爬塔 / 闭关地图 | §8.1 – §8.3 |
| Demo 内容总量 | §8.4 |
| 核心循环（5 阶段） | §9 |
| 新手引导节奏 | §10 |
| Demo 阶段不做的扩展 | §12 |

## 2. 技术栈

| 层 | 选型 | 备注 |
|---|---|---|
| 引擎 | Flutter Desktop (Windows) | 只 Windows，不出 Mac / Linux |
| 状态管理 | **Riverpod**（Phase 1 锁 2.x，与 phase1_tasks 一致；Phase 5 收尾再迁 3.x） | 不引入 BLoC 等其他方案 |
| 本地存储 | Isar | 角色、装备、进度、共鸣度计数等 |
| 云端 | Supabase + Edge Function | **仅**排行榜，不做账号同步 |
| 战斗表现 | 纯 Flutter Widget + AnimationController | 不引入 Flame 等游戏引擎 |
| 打包 | MSIX，内测先发 itch.io | — |
| 数据格式 | YAML | 数值、配置统一 yaml |

## 3. 目录结构

```
project_root/
├── CLAUDE.md                  # 本文件
├── GDD.md                     # 主设计文档（你维护）
├── docs/_archive/             # 退役文档归档（含 WINDOWS_DEEPSEEK_GUIDE.md，v1.8 起退役）
├── lib/                       # Dart 源码 ── 你的领地
│   ├── core/                  # 公式、常量包装、领域模型（纯 Dart，无 Flutter 依赖）
│   ├── data/                  # yaml 加载、Isar 仓储、Supabase 客户端
│   ├── features/              # 按功能切分（battle / equipment / cultivation / ...）
│   │   └── <feature>/
│   │       ├── domain/        # 实体与用例
│   │       ├── application/   # Notifier
│   │       └── presentation/  # Widget
│   ├── shared/                # 跨 feature 复用（主题、组件、工具）
│   └── main.dart
├── data/                      # 全部配置与文案
│   ├── ranks.yaml             # 境界配置                    [你]
│   ├── equipment.yaml         # 装备数值                    [你]
│   ├── techniques.yaml        # 心法数值                    [你]
│   ├── stages.yaml            # 关卡配置                    [你]
│   ├── encounters.yaml        # 奇遇触发条件与数值          [你]
│   ├── narratives/            # 主线/章节剧情               [你 · v1.8 起接管]
│   ├── lore/                  # 装备典故                    [你 · v1.8 起接管]
│   └── events/                # 奇遇事件文本                [你 · v1.8 起接管]
├── assets/                    # 图片、字体（AI 出图）
└── test/                      # 单元测试 + golden 测试
```

**[你] = Mac + Opus 4.7 写**;v1.8 起单端接管全部文件类型(数值 + 文案 + 代码 + 测试 + GDD)。

## 4. 命名规范

| 对象 | 规则 | 示例 |
|---|---|---|
| Dart 文件 | snake_case.dart | `equipment_repository.dart` |
| 类 / Enum | UpperCamelCase | `EquipmentRepository`, `RealmTier` |
| 变量 / 函数 | lowerCamelCase | `currentRealm`, `calculateDamage()` |
| 私有 | 前缀 `_` | `_internalCache` |
| 常量 | lowerCamelCase（不用 SCREAMING） | `maxStrengthenLevel` |
| YAML key | snake_case | `attack_power: 1500` |
| 文案文件名 | snake_case | `chapter_01_opening.yaml` |
| 提交分支 | `feat/<feature>` `fix/<bug>` `balance/<topic>` | — |

**枚举命名锁死 GDD 词汇**：境界用 `Realm`，层用 `RealmStratum`，装备阶用 `EquipmentTier`，心法阶用 `TechniqueTier`，流派用 `Style { rigid, agile, sinister }`（刚猛/灵巧/阴柔）。**不要用 `legendary` `epic` 这类网游词汇**——本项目不存在这些概念。

## 5. 关键设计原则（红线）

> 这一节是底线。实现任何功能前若发现冲突，**停下来与人类确认**，不要自作主张地"折中"。

### 5.1 反主流不做清单
不做：体力 / 每日任务 / 登录奖励 / 战令 / 抽卡 / VIP / 装备分解 / 强化破防降级 / 留存焦虑通知。任何 PR 涉及以上功能 → 停。

### 5.2 七阶节奏（统一锚点）
所有可量化进阶系统共用同一套 7 阶：
- **境界**：学徒 / 三流 / 二流 / 一流 / 绝顶 / 宗师 / 武圣（每阶 7 层 → 49 级）
- **装备阶**：寻常货 / 像样货 / 好家伙 / 利器 / 重器 / 宝物 / 神物
- **心法阶**：入门功 / 常练功 / 名家功 / 门派绝学 / 江湖秘传 / 失传神功 / 传说神功

新增任何"阶/品/级"概念前先问：能否复用 7 阶？不能 → 找人类讨论。

### 5.3 三系锁死同步（不可破，无例外）
境界 ↔ 装备阶 ↔ 心法阶 一一对应。例：二流境界 → 最多装备「好家伙」、最多修「名家功」。**任何允许低境界使用更高阶装备/心法的设计都是错的**。在 `EquipmentRepository.canEquip()` / `TechniqueRepository.canPractice()` 这类校验点上保持硬约束。

**例外说明（v1.1 明确）**：
- **师承遗物同样受锁死约束**：虽自带传承 buff（内力上限 +5%），但徒弟境界未达对应阶时不可装备，只能存放在背包等到达阶时才可装备。规则统一，无网开一面。
- **奇遇所得 / 失传神物等"高于当前境界"的物品**同理：可获得、可携带、可观摩，但**不可装备 / 不可修炼**，等境界到了自动解锁。

### 5.4 数值红线（不得突破）

| 项目 | 上限 |
|---|---|
| 普通伤害 | 8,000 |
| 大招暴击 | 几万（不许进十万） |
| 玩家血量 | 20,000 |
| Boss 血量 | 50,000+（不许进 1M） |
| 内力 | 15,000 |
| 装备攻击 | 2,000 |

**理由**：玩家一眼能读懂。突破 = 战力膨胀 = 项目失败。yaml 配置写完做一遍 schema 校验拦下越界。

### 5.5 在线 = 离线
挂机就是挂机。**不允许任何"在线 buff""挂机加速""快进券"**。关游戏 8 小时回来 = 一直挂着 8 小时。

### 5.6 不硬编码
- **Dart 代码里不写中文文案**——全部走 `data/narratives/` `data/lore/` `data/events/`。
- **Dart 代码里不写数值常量**——全部走 `data/*.yaml`。
- 唯一例外：开发期占位字符串可临时用，但合并 main 前必须迁出。

### 5.7 让玩家先感受问题，再给答案
新系统通过剧情或战斗自然出现，**不要写教程弹窗**。未解锁系统的菜单按钮直接灰掉或隐藏。

## 6. 核心公式（实现层必须遵循）

```
基础伤害 = (内力 × 0.4) + (装备攻击 × 1.0) + 招式倍率

最终伤害 = 基础伤害
        × 心法修炼度加成 (1.0 ~ 3.0)
        × 流派克制 (0.75 / 1.0 / 1.25)
        × 暴击系数 (1.0 / 1.5 ~ 2.5)
        × (1 - 目标防御率)
        × 境界差距修正

最大血量 = 1,000 + 内力 × 0.7 + 根骨 × 500 + 装备血量
出手速度 = 100 + 身法 × 8 + 装备速度 + 心法速度加成
```

> 注（v1.6 对齐）：装备攻击系数 GDD §5.3 早期 ×8 / 最大血量内力系数 GDD §5.6 早期 ×5 均为 Phase 1 平衡前的口误值，代码以 `numbers.yaml combat.damage_formula.equipment_attack_factor` (1.0) 与 `combat.max_hp_formula.internal_force_factor` (0.7) 为准，已在 numbers.yaml 注释中标注历史变更。出手速度 ×8 与 yaml 一致无变动。

**境界差距修正**（攻方/守方）：同 1.0/1.0｜差 1 阶 1.4/0.7｜差 2 阶 2.5/0.3｜差 3+ 阶 —/**0.05（近免疫）**。

**招式倍率参考**：普攻 500｜强力技能 1,000–3,000｜大招 5,000+。

**散功代价**（玩家更换主修心法时触发，v1.1 新增）：
```
新角色内力     = 当前内力 × 0.5
新主修修炼度   = 原主修修炼度 × 0.5    （原修炼度记录保留，重学时不归零）
辅修不受影响   = 不动
```
扣除非清零，鼓励多元探索；50% 的代价让"换流派"成为重决策而非随手切。

公式实现集中放 `lib/core/combat/formulas.dart`，**任何战斗结果计算都必须走这里**，禁止在 Widget 或 Notifier 里散写。散功流程封装在 `lib/features/cultivation/domain/dispel_cultivation.dart`。

## 7. 当前开发阶段

**阶段：Demo（首个 3 个月里程碑）**

Demo 必交付内容量：

| 项目 | 数量 |
|---|---|
| 主线关卡 | 15–20 |
| 章节 | 3 章（学武出山 / 武林初识 / 名扬江湖） |
| 主线剧情字数 | 3,000–7,000 |
| **爬塔** | **30 层（3 小 Boss [5 / 15 / 25 层] + 3 大 Boss [10 / 20 / 30 层]）** |
| 闭关地图 | 5 |
| 武学领悟触发（techniqueInsight encounter） | 20–30 |
| 基础奇遇（fortuneEvent，非节日） | 15–25 |
| 节日 encounter（festivalRequired 独立通道） | 6–10 |
| 装备 | 30–50（覆盖 7 阶，每阶 5–7） |
| 心法 | 20–30（覆盖 7 阶 + 3 流派） |
| 典故 | 50–80 段 |
| 武学领悟招式 | 30–50 招 |
| 心法相生组合 | ≥ 5 |
| 师徒角色 | 祖师 + 大弟子 + 二弟子（共 3） |

**Demo 阶段不要做**（GDD §12 已留接口，碰都不碰）：
江湖恩怨 / 心魔 / 门派事件 / 婚姻后代 / 帮派 / 声望 / 轻功对决 / 群战 / PVP / 第二条主线 / **节日活动系统级**(W16/W17 节日 encounter 内容层已落 ✅,但 §12.4 系统级活动框架留 1.0) / MOD / 跨周目元数据。

## 8. 工作流

| 端 | 工具 | 写什么 |
|---|---|---|
| Mac | Claude Code + Opus 4.7 | `lib/` / `data/` 全部(`*.yaml` 数值 + `narratives/` + `lore/` + `events/` 文案) / `test/` / `GDD.md` |

**汇合**:GitHub 主分支(`Zed1118/wuxia_idle`)。**单端写入,无跨端冲突**(v1.8 起 DeepSeek 端退役)。

**Windows 端保留用途**:① 视觉验收(Codex 桌面 @ Pen Windows 跑 `flutter run -d windows` 截图验收);② Mac Opus 用量上限时 Codex 桌面备份顶 Mac 端代码任务。**不再用 Windows 端做文案产出**。

### 8.1 数值与文案的联结约定

`data/encounters.yaml`（你写）与 `data/events/<id>.yaml`（DeepSeek 写）通过 `id` 字段联结。**`id` 必须严格相等且唯一**，加载时若任一端缺失对应 id 直接抛错而非静默跳过。

**示例**：

```yaml
# data/encounters.yaml （你写：纯数值与触发条件）
- id: bamboo_listen_rain
  type: technique_insight        # 类型枚举：领悟 / 奇缘 / 试炼 / 因果
  trigger:
    biome: bamboo_forest
    weather: rain
    enemy_class: swordsman
    kill_count_threshold: 100
  fortune_required: 30           # 机缘属性门槛
  unlock_technique_id: ting_yu_jian
  cooldown_days: 30
```

```yaml
# data/events/bamboo_listen_rain.yaml （DeepSeek 写：纯文案）
id: bamboo_listen_rain           # 必须与 encounters.yaml 完全一致
title: 听雨悟剑
opening: |
  竹叶上水珠成串而下，雨声渐密。你伫立林间，
  忽觉百日来斩落的剑影，皆与雨势暗合……
choices:
  - text: 闭目静听
    outcome: insight
  - text: 拔剑试招
    outcome: practice
```

同样规则适用于：装备 (`equipment.yaml` ↔ `lore/<equipment_id>.yaml`)、关卡 (`stages.yaml` ↔ `narratives/<stage_id>.yaml`)。

## 9. 不要做的事（操作清单）

❌ Dart 代码里写硬编码数值（`damage = 1500`、`hp = 5000`）
❌ Dart 代码里写中文字符串文案（`"你战胜了山贼头子"`）
❌ 引入其他状态管理库（已锁定 Riverpod 3.x）
❌ 引入第三方游戏引擎（Flame、Forge2D 等）
❌ 在 Demo 阶段动 §12 任何扩展系统
❌ 给玩家做"每日任务""登录奖励""快进券""体力"等留存机制
❌ 让任何系统的数值突破 §5.4 的红线
❌ 让 yaml 配置在没有 schema 校验的情况下被静默接受
❌ 让 `data/encounters.yaml` 的 id 与 `data/events/` 下文件名失联（加载层必须强校验）
❌ 用 Material 默认饱和色彩——基调是水墨克制（青、墨、宣纸黄、绛红点缀）
❌ 写教程弹窗——用剧情、气泡提示、百科三种方式（见 GDD §10.2）
❌ 让"低境界 + 神物装备"或"低境界 + 高阶心法"的组合在任何代码路径上能跑通（**师承遗物也不例外**）

## 10. 拿不准时的处理顺序

1. 查 `GDD.md` 对应章节（用 §1 的快速索引定位）
2. 查 §12 待人类决策清单——是否在已登记的未决项中？
3. 查 `data/*.yaml` 既有结构是否已暗示约定
4. 查同类 feature 下已实现代码的模式
5. 仍不清楚 → **停下来问人类**，不要凭推测落代码

## 11. 提交规范

- commit message 用中文，动宾结构，简明
- 涉及 GDD 修改：标题前加 `[GDD]`，并简述变更影响范围
- 涉及数值平衡：标题前加 `[balance]`
- 涉及配置 schema 变化：标题前加 `[schema]`，并在 PR 描述中列影响的 yaml 文件
- 普通代码改动可省略前缀

## 12. 待人类决策清单（v1.5 收口 · §12.1 清零）

> v1.5（2026-05-16）：§12.1 #10 师承遗物规则层 4 子项决议收口（详 v1.5 变更摘要 + §12.2 归档），**§12.1 真硬阻塞清零**。所有 13 条原始待决条目已 100% 收口(11 条 yaml/代码层默认决议 + 2 条本批方案 A / v1.4 / v1.5 决议)。完整销账见 §12.2 归档。

### §12.1 未决项

**无**(2026-05-16 v1.5 全收口)。后续进 Phase 5 师徒系统升级 / 1.0 版本扩展系统时若出现新待决项,在此区段重开。

`#12` 江湖商店 Demo 不列(`§7` 内容总量表无)— 已知 Demo 不阻塞挂账,Phase 5+ 自然实装时再回头。(`#11` 祖师爷 buff 已于 2026-05-21 P1.1 候选 2 激活,详 §12.2 #11 v1.9 更新)

### §12.2 已消解归档（W1-W15 实装中默认决议）

| # | 条目 | 实质决议位置 |
|---|---|---|
| 1 | 境界 7 层 vs 修炼度 9 层名重叠 | 代码层严格不同名：境界用「启蒙/入门/熟练/精通/圆熟/化境/登峰」，修炼度用「初窥/小成/中成/大成/圆满/巅峰/通神/无瑕/极境」，见 `lib/features/battle/domain/enum_localizations.dart`（`RealmLayer.qiMeng:42 / dengFeng:48` + `CultivationLayer.wuXia:96 / jiJing:97`） |
| 2 | 单项属性范围 | `numbers.yaml character.attributes`：单项 [1,10] / 总和 [16,24] / 正态 μ=5.5 σ=1.5 / `rerollable: false` |
| 3 | 强化 +20-49 成功率与材料 | `numbers.yaml equipment.enhancement.success_curve`：`max(0.30, 0.50 - 0.02*(level-19))`，磨剑石 18/25 颗，心血结晶保底 8 颗 |
| 4 | 暴击系数 + 防御率 | `numbers.yaml combat.critical`：base 5% + 身法 0.5%/点 + 上限 50%，倍率 1.5-2.5（灵巧固定 2.0）；防御率走 `realms.tiers.defense_rate` 按境界固定档（学徒 5%→武圣 35%） |
| 5 | 闭关产出公式 | `numbers.yaml retreat`：5 地图 base_outputs 各产出 + `realm_scale_per_tier: 1.3` + `cap_hours: 72`（2026-05-11 决议） |
| 6 | 武学领悟机缘累积规则 | W14-1 简化为「fortune 属性 1-10 静态值 + 软概率 `p = baseProbability * (1 + fortune/20)`」，不再单独累积"机缘值"，见 `encounters.yaml:13` + `lib/features/encounter/application/encounter_service.dart:216`（公式实装）+ `lib/features/encounter/domain/encounter_def.dart:162`（schema 注释） |
| 8 | 心法速度加成 | `numbers.yaml techniques.tiers[*].speed_bonus`：7 阶 0/5/10/15/25/40/60，直接进 GDD §5.6 公式，无独立上限 |
| 9 | 人剑合一招式定义位置 | `numbers.yaml combat.resonance.unlocks_joint_skill: true`（默契阶段解锁）+ `skills.reference_multipliers.joint_skill.base: 4500`，**统一固定倍率，不绑流派/不绑装备类型**，由共鸣度系统统管。**v1.9 补**:P1.1 候选 3-b(2026-05-21,commit `15ff8aa`)已实装 battle 释放路径 — `skills.yaml:772 skill_joint_skill`(mult=4500 / cost=250 / cd=4)+ `ResonanceStageConfig.unlocksJointSkill/hasSwordSongEffect` 解析 + `battle_ai` 优先级 `pending>jointSkill>powerSkill>normalAttack`,红线 27,421 < 100,000 ✅ |
| 13 | 节气日完整清单 | v1.2 决议方案 A（2026-05-15）：12 个节气均匀覆盖四季，公历 hardcode 不引入农历库；删除原中秋（属农历节日非节气）。已落 `numbers.yaml retreat.solar_term_bonus.days_2026` |
| 7 | 三流派 extra_effect 数值 + 正午阳刚定向 | v1.4 决议（2026-05-16）：① 刚猛震伤每招 +500 固定(穿透防御不暴击,主攻击命中才触发);② 阴柔内伤 N=3 守方 tick × 200/tick 固定(穿透防御 + 同源刷新覆盖,可致死);③ 正午阳刚 +20% 乘到 `internalForcePoints` 维度且仅 `character.school==gangMeng` 触发;④ 灵巧 crit_rate +0.20 已在 §6 公式实装 (v1.0 起)。已落 `numbers.yaml combat.schools.gang_meng_quake / yin_rou_internal_injury / retreat.time_of_day_bonus[zhengWu].target_attribute & applies_to_school` + 代码层 damage_calculator 震伤分支 / BattleState internalInjurySlot / battle_engine tick 衰减 / seclusion_service 正午阳刚 wire |
| 10 | 师承遗物规则层(4 子项)| v1.5 决议(2026-05-16):① 传递时机:武圣飞升时自动传(GDD §7.1 原意);② 多徒弟归属:玩家进选件界面逐件分配;③ 累代叠加:只取当代不叠加(数值不爆炸 + UI 可显传承链路但 buff 不叠);④ 同部位冲突:自动卸下原装入背包 + 新遗物入槽。已落 `numbers.yaml inheritance.heritage_items` 加 4 规则字段。**v1.14 P2.3 已实装 ✅**(2026-05-24 Batch 3.1-3.3):①+② 真消费(LineagePanel→AscensionScreen→performAscend · player_pick DropdownButton 真分配);③+④ Demo 一代飞升不验证 YAGNI 留 P5+。**v1.15 P5+ 多代飞升 + 真传位完整实装 ✅**(2026-05-24,④+⑤ 合并 batch 4 commit `1e875d6 → 1b1bb86`):③ `stackAcrossGenerations=false` derived_stats §244 按 isLineageHeritage instance count 不按 prev len 累加(R5.8 防回退测) + ④ `conflictSlotResolution=auto_swap` 真消费 `AscendService.performAscend` 副作用 4(disciple 端 equipped{Slot}Id 接新遗物 · 旧装 owner 不变入背包语义) + **真传位**:`performAscend` 加 `promotedDiscipleId: int?` 可选参数 · `promotedDisciple.isFounder=true` · `founder.isFounder` 保 true 「太祖」语义 · `founder_buff_service` 0 代码改自然接管(active 中找 isFounder=true → buff 激活) + AscensionScreen 加 _PromotedDiscipleRow widget · R5 测族 14→18(R5.6 多代 e2e 2 + R5.7 auto_swap 2 + R5.8 stack enforce 1)。详 `docs/handoff/p5_lineage_full_closeout_2026-05-24.md`。 |
| 11 | 祖师爷门派 buff(v1.9 已激活)| **v1.9 反转**:P1.1 候选 2(2026-05-21,commit `a0eae82`)决议方案 E.5.A → `enabled_when_alive: true`,玩家=祖师自享 sect_wide_buff(internal_force_max_pct=0.05 / max_hp_pct=0.05 / crit_rate_bonus=0.02 / cultivation_progress_pct=0.03)。`apply_to_disciples_only: false` 即 active 中 founder + disciple 全员享。Phase 5+ 飞升后再切语义(founder 退 active → buff 作用于新一代继位者)。已落 `lib/features/inheritance/application/founder_buff_service.dart` + `derived_stats.dart` `maxHp / internalForceMaxWithLineage / criticalRate` 各加 `founderBuffActive` 可选参数 + `lineage_panel_screen.dart _FounderBuffSection` UI 显。**P1.1 简化**:玩家本人即 founder 自享 buff;cultivation_progress_pct 修炼度公式接入留 Phase 5+ |
| 12 | 江湖商店折扣公式(Demo 不列)| Demo 内容总量表(§7)未列江湖商店,1.0 版需要时再补 |

---

**遇到拿不准的设计决策，优先回到 `GDD.md`，查 §12 待决项，仍不清晰则停下来与人类确认。不自作主张是这个项目最重要的纪律。**
