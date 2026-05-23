# 挂机武侠游戏 · 主设计文档（GDD）

> **文档地位**：本文档是整个项目的**最高设计纲领**。所有具体子文档（战斗、装备、剧情、UI 等）必须遵循本文档的设计原则与数值框架。任何与本文档冲突的设计决策必须先回到这里讨论。
>
> **维护规则**：本文档由 Mac 端 Claude Code + Opus 4.7 维护。修改需附带变更说明。
>
> **版本**:v1.16(§7.1 飞升 P5+ UI polish 续作 + 8h overnight v2 流 ABCDEFGHIJKL 全完结 ✅ · 防循环传位 + 多代 chip + dialog/snackbar 含接任名 + narrative UI 接入 + VC-P5+ fixture + GDD/ROADMAP doc state 对齐 + chant 风格词均匀测 · 1300 pass / 0 analyze)
>
> **v1.16 变更**(2026-05-24 凌晨 §7.1 飞升 P5+ UI polish 续作 + 8h overnight v2 流批 ABCDEFGHI · Mac+Opus high 累计 ~2h · 9 commit `154211b → e2dae9a` 推 main):① **A 批 P5+ UI polish 4 项实装**(`154211b → 4229a12`):A.1 `AscendService.listDiscipleTargets` 加 `!c.isFounder` 过滤防 P5+ 真传位后循环传位 + R5.9 防回退 2 测(gen0 baseline + gen1 promote=2 后 d2 排除 d3 仍在)/ A.2 `character_panel _LineageHeritageRow` 多代 chip 副行 prev.length > 1 → 「{N} 代传承」(N = prevLen + 1)/ A.3 `LineagePanel _HeritageRow` 末尾 Container chip 同语义 / A.4 `AscensionScreen _showConfirmDialog` 加 promotedDiscipleName 参数 + dialog Column 显「门派衣钵:{N}」strong 行(resultHighlight 色 w600) + snackbar 追加「 · {N} 接掌门派」 + UiStrings 加 2 段;② **B 批 Codex/MJ 派单 spec**(`ad145ee`):Codex 14 验收点 spec(P5+ 多代飞升 + P3.1 + P3.2 + Ch4-6 + inner_demon)+ MJ 10 张 prompt ready-to-paste(Ch4-6 主敌 3 张 + inner_demon 7 主题各 1 张 · v6 模板);③ **C 批 stage_audit**(`7be8798`):1.0 整体全加权 ~67-70% / 主轴战斗+主线口径 ~90%;④ **D 批 P1.2 江湖恩怨 + 声望 Phase 0**(`a5843d2`):6 维全 greenfield ✅ + Q1-Q5 候选清单留用户拍板;⑤ **E 批起床 handoff**(`f7ced04`):TL;DR + 3 类自主决策 + 6 项 first-read + memory sink 2 项追加;⑥ **F+G 批 narrative + widget test + ROADMAP**(`504dff3` + `63c7e07`):`ascension_lineage_chant.yaml` ~200 字 Tier wuSheng 4 风格梯度词均匀(湛然/寂照/圆融/化机)+ 多代 chip widget test 4 个(character_panel 2 + LineagePanel 2)+ ROADMAP P2.3 段对齐 P5+ 全实装;⑦ **H 批 narrative UI 接入 + VC-P5+ fixture**(`f70f990`):`AscendService.isLineageContinuation()` 判 founder 装备 `previousOwnerCharacterIds.isNotEmpty`(真前任 vs def 自带 heritage 区分)+ AscensionScreen narrative 条件 load(gen2+ → ascension_lineage_chant · gen1 → ascension_complete)+ R5.10 防回归 2 测(测族 20→22)+ Phase2TestMenu 加 VC-P5+ 按钮 + `seedVisualCheckP5Plus()`(B.1 fixture self-check 唯一未就绪 → ✅);⑧ **I 批终验**(`e2dae9a`):PROGRESS 顶段 9 批汇总 100 行卡上限 + handoff TL;DR 9 批 + Codex 派单 spec fixture self-check 全 ✅ + phase2_test_menu_test 13→14 修;⑨ **1293 → 1297 pass / 0 analyze ✅**(+R5.9 2 + R5.10 2 + widget test 4 = +8 测 - 2 既有重叠)。**数值红线 §5.4/§5.3/§5.5/§6 公式完全不动** · Character/Equipment Isar schema 0 改 · LineageRole enum 0 改 · founder_buff_service 0 代码改 · BattleStrategy 接口不动。**8h overnight v2 改进版实测产出**:9 批 ~2h opus high · 6 doc 全 ≤上限(audit 72→60 / phase0 98→41 两次主动砍 · pattern bug 自查及时拉回) · code +200 行 + test +6 测 + narrative 1 + memory sink 2 项。详 `docs/handoff/p5_ui_polish_closeout_2026-05-24.md` + `docs/handoff/8h_autonomous_handoff_2026-05-24.md`。
>
> **v1.15 变更**(2026-05-24 §7.1 飞升 P5+ 多代飞升 + 真传位 ④+⑤ 合并 batch · 4 commit `1e875d6 → 1b1bb86` 推 main):① CLAUDE.md §12.2 #10 师承遗物规则层 4 字段从 v1.14「P2.3 一代飞升不验证 stack/swap · P5+ 多代场景实装」升「**P5+ 多代飞升 + 真传位完整实装 ✅**」 — `stackAcrossGenerations=false` derived_stats §244 按 instance count 不按 prev len(R5.8 防回退测)+ `conflictSlotResolution=auto_swap` 真消费(AscendService.performAscend 副作用 4 · disciple 端 equipped{Slot}Id 接新遗物 · 旧装 owner 不变入背包语义);② **AscendService.performAscend 加 promotedDiscipleId 可选参数**(null = P2.3 一代飞升兼容路径 · 非 null = 真传位:promotedDisciple.isFounder=true · founder.isFounder 保 true 「太祖」语义 · founder_buff_service 自然接管 「active 中 isFounder=true → 激活」语义 0 service 改);③ **AscensionScreen 加 _PromotedDiscipleRow widget**(player_pick 体例 · DropdownButton 选 disciple 默认大弟子 · 沿 P2.3 multi_disciple_allocation 体例);④ **R5 测族 14→18**(R5.6 多代 e2e 2 + R5.7 auto_swap 2 + R5.8 stack enforce 1)· R5.1-5.5 原 14 测全过(向后兼容验证 ✅);⑤ **1291 pass / 1 skip / 0 analyze ✅**(原 1286 + 5 R5 多代)。**数值红线 §5.4/§5.3/§5.5/§6 公式完全不动** · Character/Equipment Isar schema 0 改 · LineageRole enum 0 改 · founder_buff_service 0 代码改 · BattleStrategy 接口不动 · 1.0 P2 + P5+ 真传位 → **1.0 整体 ~90%**。挂账下批:批 2 = ⑥ P1.2 江湖恩怨(~6-8h xhigh · 独立模块)+ P5+ UI polish(character_panel 多代 chip + narrative 「太祖→祖师→新祖师」叙事弧 + listDiscipleTargets 已 promoted disciple 过滤)+ Pen Codex Windows 视觉验收 ~1h 异步。详 `docs/handoff/p5_lineage_full_closeout_2026-05-24.md` + `docs/spec/p5_lineage_full_spec_2026-05-24.md`。
>
> **v1.14 变更**(2026-05-24 §7.1 飞升 + 遗物 transfer P2.3 Batch 3.1-3.3 全闭环 ✅ · 4 commit `eaa3e00 → 本` 推 main):① §7.1 师徒传承「飞升渡劫后传位给大徒弟」语义 P2.3 真实装(方向 B + Q1a/Q2c/Q3b/Q4d:Q1a `isFounder=true + isActive=false` 出阵复用现字段不加 isAscended / Q2c lineageRole 不真切传位 P5+ 再切语义 / Q3b 玩家手动选 1-2 件 player_pick 真消费 / Q4d 3 条件并存 `stage_inner_demon_07 cleared + wuSheng·dengFeng + stage_06_05 cleared`);② **schema 改动**:`data/numbers.yaml` 末加 `ascension.unlock_triggers` 段(cleared_stages 2 关 + required_realm wuSheng·dengFeng)+ `NumbersConfig` 扩 `HeritageItems` class(6 字段消费 v1.5 决议 4 规则字段 transfer_trigger/multi_disciple_allocation/stack_across_generations/conflict_slot_resolution + 2 数量字段)+ `AscensionConfig` class(unlock_triggers 解析 · empty 兜底);③ **AscendService 4 method**(`computeEligibility` 5 子条件 + missingReasons / `listHeritageCandidates(founderId)` / `listDiscipleTargets` / `performAscend(selections)` caller 持锁 writeTxn)+ 4 Riverpod providers(service / eligibility / candidates / disciples);④ **AscensionScreen 三段式 UI**(ConsumerStatefulWidget 401 行 · 仪式横幅 + 装备多选 1-2 件 + DropdownButton 改 disciple + 确认 dialog → performAscend → snackbar + invalidate 4 provider)+ `LineagePanelScreen` 末加 `_AscensionSection`(eligibility 5 子条件聚合 → 「步入飞升」按钮 enable/disable + tooltip 显 missingReasons);⑤ **founder_buff_service 0 代码改**(飞升后 founder isActive=false 自然让 `computeBuffActive` 返 false · spec §6 注 P5+ 真传位时再扩 trigger);⑥ **Equipment.inheritFrom 生产 bug 修**(memory `feedback_isar_pitfalls`):从 Isar 读取实例的 `previousOwnerCharacterIds: List<int>` 是 fixed-length,`.add()` 抛 `Unsupported operation: Cannot add to a fixed-length list`,改 reassign `[...old, new]`;⑦ **R5 红线 5 族 14 测**(R5.1 e2e + R5.2 5 子条件 + R5.3 player_pick 3 测 + R5.4 边界 4 测 + R5.5 §5.4 cap)+ test 顺手修宽 finder false positive(memory `feedback_red_line_test_semantics`);⑧ **1283 pass / 1 skip / 0 analyze ✅**(原 1269 + 14 R5)。**数值红线 §5.4/§5.3/§5.5/§6 公式完全不动** · Character/Equipment Isar schema 0 改 · founder_buff_service 0 代码改 · CLAUDE.md §12.2 #10 师承遗物规则层 4 字段从「Phase 5+ 激活」升「**P2.3 已激活实装 ✅**」(`transferTrigger=ascend_to_wusheng` / `multiDiscipleAllocation=player_pick` 真消费 · `stackAcrossGenerations=false` 与 `conflictSlotResolution=auto_swap` Demo 一代飞升不验证 P5+ 多代场景实装)。**1.0 P2 主线 3 子阶段全闭环**:Ch4+Ch5+Ch6 主线 + 心魔 7 关 + 飞升 → 1.0 P2 ~87%。挂账留下批:narrative ~600 字(spec §7 · `data/narratives/ascension/` 4 yaml)+ P5+ 多代飞升 + P5+ 真传位语义。详 `docs/handoff/p2_3_ascension_closeout_2026-05-24.md` + `docs/spec/p2_3_ascension_spec_2026-05-24.md`。
>
> **v1.13 变更**(2026-05-24 §12.3 群战守城 P3.2 Batch 2.1-2.5 全收尾 ✅ · worktree `feat/p3_2_mass_battle` · 5 commit · ROADMAP_1_0.md:153-167):① §12.3「群战 / 守城战」行从「5v5 或更大规模的特殊关卡」单行注释升「**P3.2 Batch 2.1-2.5 全收尾 ✅**」实装段;② **战斗形态全闭环**:`MassBattleStrategy implements BattleStrategy` 组合委派 `DefaultGroundStrategy`(沿 LightFoot 体例零代码重复 + immutable · runToEnd 入口 `applyFormationTo` 烘焙仅 leftTeam · wave 循环 + `_intermission` actionPoint+cd reset / HP+IF preserve / result 清空)+ `Formation` enum 3 项(yanXing 雁行/baGua 八卦/fengShi 锋矢);③ **5 关 schema**:`stage_mass_battle_01..05` yiLiu 3 + jueDing 2 · wave 2-4 / enemy 5-7「以少胜多」· diff 6.5-8.5 + enemyTeam[3] 模板沿 LightFoot skill 池 18 招(零新增 skill)+ `numbers.yaml mass_battle` 段 50 行 + `StageDef.massBattleWaveCount/EnemyCounts` nullable 字段;④ **narrative ~2.2k 字**:`chapter_mass_battle` 章首尾(无名守城术 5 处试炼 · 不躁/不乱/不溃/不让/不忧)+ 10 stage opening/victory(村/镇/县/关/城 五阶递进);⑤ **UI 入口**:`MassBattleScreen` 三态 reactive + `MassBattleService.statusOf/orderedStageIds/formationFor` + main_menu 入口 LightFoot → **MassBattle** → Leaderboard(13→14 按钮);⑥ **R5/R6 红线 4 测**:R5.1 5 关 × 50 种子 leftWins+draws ≥ rightWins(rightWins=0 全过 · stage_03/04/05 全 draws 数值平衡挂账 P3.2.B)+ R5.2 formation cap clamp + §5.4 红线 + **仅 leftTeam 关键差异**(vs LightFoot 双方对等)+ R5.3 unlock 链 e2e + R5.4 wave 间 preserve/reset e2e + R6 烘焙 7 + wave ctor 4 共 11 单测;⑦ **架构决议**:`MassBattleStrategy.runToEnd` 一次性跑完 wave 循环(strategy 保持 immutable)· R5 红线直接调 runToEnd 不走 UI · UI tick by tick 战斗 wiring 留 Batch 3.x;⑧ **1268 pass / 0 analyze ✅**(原 1242 + 26:11 strategy 单测 + 9 service + 1 stage 校验 + 1 schema 校验 + 4 R5)。**数值红线 §5.4/§5.3/§5.5/§6 公式完全不动**(Formation 修正烘焙到 BattleCharacter view layer,base 公式不变)。详 `docs/handoff/p3_2_mass_battle_closeout_2026-05-24.md`。
>
> **v1.12 变更**(2026-05-24 §12.3 轻功对决 P3.1.B 子批收尾 ✅ · branch `feat/p3_1_b` · 3 commit · ROADMAP_1_0.md:130-145):① §12.3「轻功对决」行从「P3.1 Batch 2.1-2.4 全收尾 ✅」升「**P3.1.B 子批收尾 ✅**」— damage_multiplier 真接入 + 18 招专属 skill 池;② **Batch A**:`BattleCharacter +attackPowerMultiplier:double` default=1.0 + copyWith + `default_ground_strategy._calculateInBattle` raw 末乘 atkPowerMult + breakdown(沿 cult/school/crit/def/realm 体例)+ `LightFootStrategy._bake` 烘焙 `terrain.damageMultiplier` 到 attackPowerMultiplier(双方对等)+ R6 4 测(water 1.0 / rooftop 1.15 / bamboo 0.90 / 双方对等);③ **Batch B**:`skills.yaml +18` 招 lightfoot pool(`skill_lightfoot_<tier>_<school>_<type>` · yiLiu 9 招 cap=3000 / jueDing 9 招 cap=4000 · parentTechniqueDefId: null 沿 joint_skill 体例)+ `stage_light_foot_01..05` enemyTeam.skillIds 全切到新池(sed 35 次替换);④ **架构发现**:`DamageCalculator`(用 `Character` Isar 实体)是 phase1 公式参考,不参与战斗 — 实际战斗走 `DefaultGroundStrategy._calculateInBattle`(用 `BattleCharacter`),attackPowerMultiplier 加在 BattleCharacter 上接入正确路径;⑤ **R5.1 实测分布**:50/50/49/50/50 leftWins(bamboo stage_03 draws 4→1 · ×0.90 双方等比 → 玩家击杀更稳定,主导格局未变);⑥ **1242 pass / 0 analyze ✅**(原 1238 + 4 R6 · skill 总数 64→82)。**数值红线 §5.4/§5.3/§6 公式完全不动**(attackPowerMultiplier 是 BattleCharacter view layer 字段,base 公式形态不变,仅末端乘项)。详 `docs/handoff/p3_1_b_closeout_2026-05-24.md`。
>
> **v1.11 变更**(2026-05-23 夜 → 2026-05-24 晨 §12.3 轻功对决 1.0 P3.1 全收尾 ✅ · ROADMAP_1_0.md:130-148 · 8h overnight worktree `feat/p3_1_lightfoot` 8 commit `be7248a → 本` push origin 等 review):① §12.3「轻功对决」行从纯 1.0 P3 占位升「**1.0 P3.1 Batch 2.1-2.4 全收尾 ✅**」— 用户拍板 4 主轴(范围=全闭环·战斗形态+5 关+narrative+UI 入口+R5 红线 / 胜负判定=HP 决胜负 + 地形 modifier / push=worktree feat/p3_1_lightfoot 等 review / xhigh);② **4 主轴自主拍板**(memory `feedback_user_offline_autonomous` 用户离线):**5 关 = yiLiu 3 关(water/rooftop/bamboo)+ jueDing 2 关(高阶 water/rooftop)** · diff 5.0-6.5 · 平行支线**不接管 wuSheng 突破链** + terrain modifier ≥15% 单维度有效(memory `feedback_balance_buff_singledim_no_effect`)+ **LightFootStrategy 组合委派 DefaultGroundStrategy 零代码重复**(memory `feedback_avoid_over_engineer_abstraction`)+ UI 入口 main_menu Tower→InnerDemon→**LightFoot** + 轻功 skill 不新增 YAGNI;③ schema 改动:`StageType` enum +1 `lightFoot` / 新建 `TerrainBiome` enum 3 项(water/rooftop/bamboo,与 EncounterBiome 解耦)/ `numbers.yaml light_foot` 段 ~45 行(3 terrain × 4 modifier + 5 stage_terrain + 5 unlock_triggers)/ `stage_light_foot_01..05` 5 entries;④ codebase 0 引用 greenfield(Phase 0 完全 grep ✅)+ BattleStrategy 注入位已 ready(`battle_providers.dart:73 startBattle(strategy: ...)`);⑤ Phase 2+ 实装估时 ~7-7.5h opus xhigh(spec 估 ~9.5h × 0.74×)Batch 2.1 schema → 2.2 strategy → 2.3 narrative + UI → 2.4 R5 + doc。**数值红线 §5.4/§5.3/§6 公式完全不动**(terrain modifier 烘焙到 BattleCharacter stat + clamp ≤0.95 + R5.2 校验)。**Ch1-Ch6 主线 + Demo 49 层 EXP 自动升层 + 心魔 7 关 wuSheng 突破链路径完全不变**(轻功对决独立支线 / isLayerLocked 无 lightFoot 路径)。详 `docs/phase0/p3_1_lightfoot_phase0_2026-05-23.md` + `docs/spec/p3_1_lightfoot_spec_2026-05-23.md`。
>
> **v1.10 变更**(2026-05-23 §12.1 心魔系统 Batch 2.5 全收尾 + P2.2 final · ROADMAP_1_0.md:110-113):① §12.1「心魔系统」行从「v1.9 Phase 2 实装完成 ✅」升「**v1.10 Batch 2.1-2.5 全收尾 ✅**」— Batch 2.5.A R5 跨阶红线压测 3 测 e2e(50 种子 × 7 关 / cap §5.4 e2e / unlock 链 e2e)`308bf52` + Batch 2.5.B UI reactive 三态(InnerDemonScreen MainlineProgress.clearedStageIds + unlockTriggers reverse 链查 + cleared/available/locked 三态)+ main_menu 入口 _MenuButton(Tower 后 Leaderboard 前)+ Batch 2.5.C 决议 `b15d34d`;② **Batch 2.5.C inner_demon_07 双镜像决议**:R5.1 实测 7 关分布全 **3/0/47**(玩家 leftWin 6% / rightWin 0% / draws 94%)— `_07 +20%` 与 `_06 +20%` 完全同分布,spec §一末关「双镜像 2 副本」未真正落地;改 `_07 +20% → +40%` 单副本(YAGNI 不动 BattleState 6v3 架构);③ **Batch 2.5.C cap 维度纠正**:`mirror_caps.attack_power_max 2000 → 6000`(spec 锚错 §5.4 维度 — §5.4「装备攻击 2000」是 equipment.yaml 单件 cap,镜像 `totalEquipmentAttack` 是 3 件求和;原 2000 让镜像 attack 永远低于玩家 ~2850,buff 完全无效);④ **挂账留 1.0 P3+**(3 项):BreakthroughBlocker 集成 character_panel(1257 行 ~30-45min)+ inner_demon 战斗机制层调优(R5.1 实测数值层 buff 单维度调整不影响战斗结果,真改需 mirror crit +0.20 / 心魔余毒 debuff 实装 / max_ticks 兜底机制改)+ inner_demon 7 主题 enemy 立绘异步 MJ 派单;⑤ **1220 pass / 0 analyze ✅**(原 1217 + 新 3 R5)。**数值红线 §5.4/§5.3/§6 公式完全不动**。详 `docs/handoff/p2_x_inner_demon_final_closeout_2026-05-23.md`。
>
> **v1.9 变更**（2026-05-22 夜 §12.1 心魔系统 1.0 P2.2 Phase 2 实装完成 ✅ · ROADMAP_1_0.md:110-113):① §12.1「心魔系统」行从「**v1.8 Phase 1 spec 拍板**」升「**v1.9 Phase 2 实装完成 ✅**」— 7 commit `e666e4c → a0cbb29` 全 push origin/main(Phase 0 reality check + Phase 1 spec doc + Batch 2.1 schema + Batch 2.2.A vertical slice + Batch 2.2.B 镜像战斗 + Batch 2.3 narrative + UI 占位);② **机制全通**:`InnerDemonService.isLayerLocked` 拦截 hook 接 `character_advancement_service.applyExperience`(EXP 留账不消费 §5.1)+ `buildMirrorEnemyTeam` 深拷贝 playerTeam ×(1+buff) clamp §5.4 cap(20k/15k/2k) + 3 callers(seclusion/tower/mainline)wire production hook 真生效;③ **narrative ~3,900 中文字**(chapter ~720 + 7 opening ~280×7 + 7 victory ~150×7 + 7 defeat ~210×7 · Tier wuSheng 风格梯度词「湛然/寂照/圆融/化机」+ 7 主题贪/嗔/痴/慢/疑/空/真);④ **数值实测**:`numbers.yaml inner_demon` 段 46 行(mirror_buff_per_stage 0.10→0.20 7 关 · §5.4 cap · failure_penalty 散功 ×0.5 阉割版 0.85/0.90/1.00 · residue_debuff 0.95/0.80 8h 清 · unlock_triggers 7 链 · required_realm_layer 7 配);⑤ **测试**:R1 14 测(isLayerLocked unit + applyExperience hook integration)+ R2-R3 7 测(buildMirrorEnemyTeam 数值/slot/§5.4 cap)+ R4 4 测(22 narrative load + chapter content)= **1217 pass / 0 analyze ✅**(原 1192 + 新 25);⑥ **spec doc 调整记录**:InnerDemonStrategy implements BattleStrategy 不建(YAGNI · BattleStrategy 是 tick 层,enemy 构造在 setup 层职责)+ inner_demon_07 双镜像 spec §一 +20%×2 副本 → 当前实装单副本 +20%(BattleState slot 3v3 限制,真双镜像 6v3/连战 留 Batch 2.5 R5 讨论)+ chapter_inner_demon 运行时不 load(与 chapter_06 同体例,纯叙事 doc)+ UI widget reactive 集成 character_panel/main_menu 路由留 Batch 2.5+。**数值红线 §5.4/§5.3/§6 公式完全不动**。**Ch1-Ch6 主线 + Demo 49 层 EXP 自动升层路径完全不变**(`isLayerLocked` 严格 wuSheng 短路 + qiMeng 跨 tier 起步层放行)。详 `docs/handoff/p2_x_inner_demon_phase1_closeout_2026-05-22.md` 及上下游。
>
> **v1.8 变更**（2026-05-22 晚 §12.1 心魔系统 Phase 1 spec 起草拍板 · 1.0 P2.2 子阶段启动 · ROADMAP_1_0.md:110/200/247):① §12.1「心魔系统」行从纯 1.0 扩展占位升「**1.0 P2.2 Phase 1 spec 拍板**」— 用户拍板 4 主轴(**触发=wuSheng 6 内部 + 1 飞升前置 7 关** / 形态=stages.yaml `stageType: innerDemon`(StageType enum 加第 3 项)/ 数值=**镜像玩家自己 +10-20% + §5.4 红线 cap**(HP ≤20k/内力 ≤15k/装备 ≤2k)/ 失败惩罚=**散功 ×0.5 公式阉割版**(内力 ×0.85 / 主修修炼度 ×0.9 + 「心魔余毒」debuff 闭关 8h 清));② schema 改动最小(StageType enum +`innerDemon` / EncounterBiome enum +`innerRealm` / numbers.yaml `inner_demon` 段 ~25 行 / 7 stage entries);③ codebase 0 心魔引用(Phase 0 完全 grep ✅ B 独立路线);④ unlock 拦截 hook 加 `character_advancement_service.dart:54-67` while-loop 2-3 行(严格 wuSheng tier,不影响 Demo 全境界 + Ch4-6 P2.1 主线);⑤ Phase 2+ 实装估时 ~7-8h opus xhigh(Batch 2.1 schema → 2.2 strategy + service → 2.3 narrative ~3,500 字 → 2.4 GDD/ROADMAP/PROGRESS → 2.5 R1-R5)。**数值红线 §5.4/§5.3/§6 公式完全不动**。**Ch1-Ch6 主线 + Demo 49 层 EXP 自动升层路径完全不变**(`isLayerLocked` 严格 wuSheng 短路)。详 `docs/handoff/p2_x_inner_demon_phase0_reality_check_2026-05-22.md` + `p2_x_inner_demon_spec_2026-05-22.md`。
>
> **v1.7 变更**（2026-05-22 午后 Ch6「飞升」Phase 2 全收口 · 1.0 P2 第二条主线全闭环）:① §12.4 Ch6「飞升」行升「Phase 1 spec 起草拍板 · Phase 2 启动」→「**Phase 2 全收口 ✅ · 1.0 P2 第二条主线全闭环**」— 6 commit `15216a0`→`486d39b` 全 push(P0+P1+P2.1+2.2+P2.3.①+P2.3.②);② §12.4.1 字数表 Ch6 ~6,600 预算 → 实测 **~5,800 字**(narrative 13 文件,略低 spec ~10%)+ Ch6 合计 ~18,318 字超 14-20k 上限 ~83%(质感优先 acceptable);③ 师父第三句遗言三章弧完整 — Ch4 epilogue 半懂前一句 / Ch5 epilogue 第三句半解 / Ch6 epilogue **三句话第一次完整连成一句**;④ 物理遗物三章 hook 全闭环 — Ch4 小铜镜 + Ch5「师」字玉佩 + Ch6 epilogue **无物之境**(四件物事并放青石不带走,雪埋);⑤ Tier zongShi 风格梯度词「澄澈 / 无为 / 玄妙 / 化境」全章实测落地。**数值红线 §5.4/§5.3/§6 公式完全不动**。**§12.1 心魔系统不前置依赖**(B 路线 0 contamination,留 P2.2 独立 spec)。详 `docs/handoff/p2_x_chapter6_phase2_full_closeout_2026-05-22.md`。
>
> **v1.6 变更**（2026-05-22 午间 Ch6「飞升」Phase 1 spec 起草拍板）:① §12.4 Ch6「飞升」行升「拟 zongShi 全章备注」→「Phase 1 spec 起草拍板 · Phase 2 启动」— 用户拍板 4 主轴(章名「飞升」/ 境界跨度 A:zongShi 全章 + 末 Boss 跨 wuSheng·qiMeng / 文化主轴:师父第三句遗言完整联通 + 西凉霸主本人复出 / 末 Boss B 复合 = wuSheng·qiMeng 西凉霸主本人首次开口 + 2 副 zongShi·dengFeng 西凉三弟子 · Ch4 小铜镜 + Ch5 玉佩双 hook 兑现);② §12.4 Ch5「征东」行升「Phase 2 全收口 ✅ → + Ch6 启动」;③ §12.4.1 字数表 Ch5 (拟 ~4-5k) → 实测 ~6,638 字 + Ch6 (拟 ~4-5k) → 预算 ~6,600 字(沿 Ch5 实测)。Tier zongShi 风格梯度词「澄澈 / 无为 / 玄妙 / 化境」全章 + 物理遗物 hook 收束「无物之境」(承 Ch5 玉佩兑现,Ch6 不留任何物理遗物)。**数值红线 §5.4/§5.3/§6 公式完全不动**。详 `docs/handoff/p2_x_chapter6_spec_2026-05-22.md` + `p2_x_chapter6_phase0_reality_check_2026-05-22.md`。
>
> **v1.5 变更**（2026-05-22 早间 Ch5「征东」Phase 1 spec 起草前用户审稿拍板）:① §12.4.1「1.0 P2 内容总量表草案」正式拍板 — 标签 `[v1.3 待用户审]` → `[v1.5 正式拍板,2026-05-22 用户审稿过]`,数字接受(主线 25-30 关 / 章节 6 / 字数 14-20k / 装备 80 / 心法 50 / 典故 160 / 武学领悟招式 70 / 心法相生 10-15 / 战斗形态 4 / 社交系统 4);② §12.4 第二条主线行加 Ch5「征东」启动条目(jueDing 全章 + 跨 zongShi·qiMeng 末 Boss · C 复合三人组西凉三弟子+中州顶强者+嵩山道宗 + 师父遗言全听懂顿悟 + 小铜镜兑现 + 师承玉佩 hook Ch6,详 `docs/handoff/p2_x_chapter5_spec_2026-05-22.md`);③ §12.4 加 Ch6「飞升」拟 zongShi 全章备注。**数值红线 §5.4/§5.3/§6 公式完全不动**。
>
> **v1.4 变更**（2026-05-22 8h autonomous 工作流 D1 批次起草,留用户审稿）:加 §12.4.1「1.0 P2 内容总量表草案」**子段**(本表与 §8.4 Demo 现状表**解耦**,Demo 数字保留实测对齐,1.0 P2 升档由本表统管)。内容含:主线关卡 25-30 / 章节 6 / 主线字数 14-20k / 装备 80 / 心法 50 / 典故 160 / 武学领悟招式 70 / 心法相生 10-15 / 战斗形态 4 / 社交系统 4。**数值红线 §5.4/§5.3/§6 公式完全不动**。**v1.5 已正式拍板**。
>
> **v1.3 变更**（2026-05-21 候选 2 Ch4「西出阳关」Batch 2.4 同步）:§8.1 表下加 1 行注释明 Demo 锁 3 章 + Ch4-Ch6 在 §12.4 第二条主线范畴。§12.4「第二条主线」行加备注:Ch4 西出阳关 P1 启动(yiLiu 全章 + 跨 jueDing 末 Boss + 西北边塞地理梯度,~5,880 字 narrative + ~1,420 字 v1 章首尾,详 `docs/handoff/p1_x_chapter4_spec_2026-05-21.md`),拟扩 3 章后 §8.4 主线关卡 15-20 → 25-30 升档(留 Ch5/Ch6 spec 起草前再正式拍板)。**§8.4 Demo 现状不动**(Demo 实测对齐,1.0 P2 升档与 Demo 解耦)。
>
> **v1.2 变更**（2026-05-17 W18 全收口 + 外部审查后对齐）：§8.4 内容总量表对齐实装实测。① 奇遇口径拆分:原「奇遇事件 20-30 + 节日 6」(混算导致基础非节日 fortuneEvent 仅 16 不达 20 下限)拆成「武学领悟触发 20-30 / 基础奇遇(fortuneEvent 非节日)15-25 / 节日 encounter 6-10」三独立维度。② 节日 encounter 6→8(W17 扩 chuXi/qingMingJie)。③ 主线剧情字数上限 5000→7000 字(实测 chapter 1354 + stages 5424 = 6778 字,内容多反而好)。④ §8.4 注释段同步重写。
>
> **v1.1 变更**：修正爬塔 Boss 数量；明确散功双重代价；境界 7 层重命名以避免与心法修炼度混淆；补充单项属性范围；强化"装备永不过时"设计哲学；新增三流派视觉差异；明确"一辈子"语义；明确师承遗物数量。

---

## 目录

1. [项目定位](#1-项目定位)
2. [反主流设计原则](#2-反主流设计原则)
3. [世界观度量衡](#3-世界观度量衡)
4. [角色系统](#4-角色系统)
5. [战斗系统](#5-战斗系统)
6. [装备系统](#6-装备系统)
7. [MVP 三大特色系统](#7-mvp-三大特色系统)
8. [内容结构](#8-内容结构)
9. [核心循环](#9-核心循环)
10. [新手引导](#10-新手引导)
11. [工作流与技术栈](#11-工作流与技术栈)
12. [未来扩展](#12-未来扩展)

---

## 1. 项目定位

### 1.1 基础参数

| 项目 | 内容 |
|------|------|
| **平台** | Windows 单平台 |
| **引擎** | Flutter Desktop |
| **商业模式** | 买断制（无内购、无广告） |
| **联网形式** | 纯单机 + Supabase 云端排行榜 |
| **美术风格** | 写实武侠风（金庸 / 古龙气质），全部 AI 出图 |
| **战斗形态** | 半横版队伍战 3v3，自动战斗 + 手动放技能 |
| **首个里程碑** | 3 个月内出可玩 Demo |

### 1.2 设计基调

写实而非二次元，沉郁而非鲜艳。参考意象：水墨、宣纸、竹影、雨夜、青衫、断剑、孤灯。色彩克制，UI 不堆砌特效。

### 1.3 目标受众

- 喜欢武侠题材但厌倦氪金手游的玩家
- 希望"开着挂机几小时回来看故事"的轻度沉浸型玩家
- 单机游戏爱好者（愿意为买断制武侠付费的人群）

---

## 2. 反主流设计原则

本节是项目的**底线条款**。Claude Code 在实现任何功能时，若发现该功能涉及以下任何一项，必须停下来与人类确认。

### 2.1 不做清单

| 不做的功能 | 替代方案 / 设计意图 |
|-----------|-------------------|
| 体力系统 | 用爬塔每日 5 次等**自然限制**替代 |
| 每日任务 / 登录奖励 / 战令 | 不制造"上线义务"，玩家想玩才玩 |
| 抽卡 | 用**武学领悟系统**自然解锁招式 |
| VIP 等级 | 买断制无 VIP 概念 |
| 装备分解 | 装备永久保留，作为收藏品 |
| 强化破防降级 | 只可能扣材料，不会降级（避免挫败） |
| 战力数字膨胀 | 数值范围保持几千~几万的可读区间 |
| 留存焦虑通知 | 桌面通知**极简且默认可关** |

### 2.2 设计哲学

> **"让玩家先感受问题，再给答案。"**

不预先讲规则，让玩家先遇到现象，再揭晓机制。新系统通过剧情或战斗自然出现，而非教程弹窗。

> **"在线离线收益相同。"**

挂机就是挂机，不做"在线 buff"逼人挂着挂件。玩家关掉游戏的几小时，回来看到的世界应当与一直挂机相同。

---

## 3. 世界观度量衡

**统一 7 阶系统**：所有可量化的进阶系统都用同一套 7 阶节奏，方便玩家形成稳定的认知锚点。

### 3.1 境界系统（49 级）

7 个大境界 × 每境界 7 层 = **49 级**。

| 阶 | 境界名 | 通俗对应 |
|----|--------|----------|
| 1 | 学徒 | 学武起步 |
| 2 | 三流 | 江湖小卒 |
| 3 | 二流 | 一方好手 |
| 4 | 一流 | 名门高手 |
| 5 | 绝顶 | 当世高手 |
| 6 | 宗师 | 一代宗师 |
| 7 | 武圣 | 武林神话 |

每个境界内 **7 层**，固定命名（**已避免与心法修炼度 9 层重名**）：

| 层 | 名称 |
|----|------|
| 1 | 启蒙 |
| 2 | 入门 |
| 3 | 熟练 |
| 4 | 精通 |
| 5 | 圆熟 |
| 6 | 化境 |
| 7 | 登峰 |

**UI 显示风格**：`二流·入门`、`一流·圆熟`、`宗师·化境`。

**命名约定**：境界 7 层（启蒙→登峰）描述"角色整体武学水平"；心法修炼度 9 层（初窥→极境）描述"单本心法精熟程度"。两套词汇严格不重叠，避免玩家混淆。

### 3.2 装备品阶（7 阶）

| 阶 | 名称 | 风格示例 |
|----|------|----------|
| 1 | 寻常货 | 铁剑、麻布袍 |
| 2 | 像样货 | 精铁刀、皮甲 |
| 3 | 好家伙 | 雁翎刀、锁子甲 |
| 4 | 利器 | 名匠铸刃 |
| 5 | 重器 | 古战场遗器 |
| 6 | 宝物 | 失传名兵 |
| 7 | 神物 | 传说中的兵器 |

### 3.3 心法品阶（7 阶）

| 阶 | 名称 | 风格示例 |
|----|------|----------|
| 1 | 入门功 | 县衙捕快教的拳脚 |
| 2 | 常练功 | 镖局通用心法 |
| 3 | 名家功 | 中等门派招牌 |
| 4 | 门派绝学 | 七大派看家本领 |
| 5 | 江湖秘传 | 失传几十年的功法 |
| 6 | 失传神功 | 失传数百年的功法 |
| 7 | 传说神功 | 九阳、九阴这种级别 |

### 3.4 三系一一对应

| 境界 | 可装备上限 | 可修心法上限 |
|------|-----------|-------------|
| 学徒 | 寻常货 | 入门功 |
| 三流 | 像样货 | 常练功 |
| 二流 | 好家伙 | 名家功 |
| 一流 | 利器 | 门派绝学 |
| 绝顶 | 重器 | 江湖秘传 |
| 宗师 | 宝物 | 失传神功 |
| 武圣 | 神物 | 传说神功 |

**设计理由**：境界、装备、心法三系完全锁死同步，避免"低境界堆装备碾压高境界"的数值崩坏，也让玩家对"我现在能用什么"有最简单清晰的判断。

---

## 4. 角色系统

### 4.1 四项基础属性

| 属性 | 影响 |
|------|------|
| **根骨** | 主要影响血量上限 |
| **悟性** | 主要影响心法修炼速度、武学领悟概率 |
| **身法** | 主要影响出手速度、闪避 |
| **机缘** | 影响奇遇触发率、商店折扣感知 |

**生成规则**：四项总和 16-24 浮动，**单项数值范围 1-10**，按**正态分布**生成（中段最常见，两端罕见）。

**6 档稀有度**：

| 稀有度 | 概率 | 总点数 |
|--------|------|--------|
| 庸才 | 15% | 16-17 |
| 寻常 | 35% | 18-19 |
| 标准 | 25% | 20 |
| 资优 | 18% | 21-22 |
| 天才 | 5% | 23 |
| 绝世 | 2% | 24 |

**关键约束**：**不可重 roll**。出生即命运，但奇遇可微弱后天弥补（**每个角色整个生涯内**最多 +3~5 点）。

**设计理由**：拒绝"洗练-保底"循环，让"投胎"本身具有意义；用奇遇的微弱补偿留出努力空间，避免初始绝望感。

### 4.2 心法搭配

- **主修 1 个**：决定流派身份与战斗风格。换主修需要"散功"（详见 §4.3 散功代价）。
- **辅修 3 个**：可随时切换，但学习新心法需消耗"领悟点"。

### 4.3 修炼度（9 层进度）

每本心法独立修炼度，决定该心法所有招式的最终倍率。

| 层 | 名称 | 加成 |
|----|------|------|
| 1 | 初窥 | 100% |
| 2 | 小成 | 115% |
| 3 | 中成 | 130% |
| 4 | 大成 | 150% |
| 5 | 圆满 | 175% |
| 6 | 巅峰 | 200% |
| 7 | 通神 | 230% |
| 8 | 无瑕 | 260% |
| 9 | 极境 | 300% |

**累积方式**：通过该心法的招式使用次数累积。

**散功代价**（重要）：换主修时同时承受**两项**惩罚：

| 项目 | 惩罚 |
|------|------|
| 角色当前内力 | -50%（不归零，但需重新累积） |
| 原主修心法修为 | -50%（修炼度回退） |

**设计理由**：双重惩罚让"换主修"成为重大决策而非随意操作，但都不归零，鼓励玩家在足够代价下仍可探索多元 build。

### 4.4 三流派克制

| 流派 | 风格 | 克制对象 | 克制效果 | 视觉表现 |
|------|------|---------|---------|---------|
| **刚猛** | 力量型 | 阴柔 | 每招额外震伤 | 击中时屏幕震动 + 红色震波扩散 |
| **灵巧** | 速度型 | 刚猛 | 暴击率 +20% | 暴击时金光闪烁 + 残影拖尾 |
| **阴柔** | 阴损型 | 灵巧 | 每招施加内伤 debuff | 紫色雾气缠绕目标 + 内伤数字飘出 |

**克制系数**：±25%（最终伤害公式中的 0.75 / 1.0 / 1.25）。

**设计理由**：挂机游戏的核心体验是"看战斗"，三流派的视觉差异必须一眼可辨。玩家不需要看伤害数字就能判断当前是谁克谁。

### 4.5 心法相生（5-8 个隐藏组合）

主修 + 辅修达到特定组合时，触发**隐藏彩蛋 buff**。Demo 阶段至少 5 个：

| 组合名 | 心法搭配 | 效果 |
|--------|---------|------|
| 阴阳调和 | 九阳 + 九阴 | 全属性 +20% |
| 丐帮传承 | 降龙十八掌 + 打狗棒法 | 解锁"亢龙有悔"暴击 |
| 少林正宗 | 易筋经 + 少林外功 | 内力增长 +30% |
| 武当圆融 | 太极拳 + 太极剑 | 反伤 15% |
| 华山合璧 | 紫霞神功 + 华山剑法 | 暴击伤害 +50% |

**设计理由**：相生组合是"老玩家彩蛋"，不放进引导，靠攻略与口碑传播，制造发现的快感。

---

## 5. 战斗系统

### 5.1 形态

**半横版队伍战 3v3**，自动战斗为主，手动放大招为辅。视角左右两侧各 3 名角色对峙，攻击表现为"前冲-出招-后撤"的循环。

### 5.2 数值范围（重要约束）

| 项目 | 范围 |
|------|------|
| 普通伤害 | 2,000 ~ 8,000 |
| 大招暴击伤害 | 上万 |
| 玩家血量 | 5,000 ~ 20,000 |
| Boss 血量 | 50,000+ |
| 内力 | 500 ~ 15,000 |
| 装备攻击 | 100 ~ 2,000 |

**红线**：任何系统设计**不得突破上述上限**。战力数字必须保持在玩家一眼能读懂的范围内。

### 5.3 基础伤害公式

```
基础伤害 = (内力 × 0.4) + (装备攻击 × 1.0) + 招式倍率
```

> 注：装备攻击系数早期 v0.1 设为 8，Phase 1 平衡时为防装备轴数值膨胀调为 1.0，代码以 yaml 为准，详 `numbers.yaml combat.damage_formula.equipment_attack_factor` 注释。

招式倍率参考：

| 类型 | 倍率 |
|------|------|
| 普通攻击 | 500 |
| 强力技能 | 1,000 ~ 3,000 |
| 大招 | 5,000+ |

### 5.4 最终伤害公式

```
最终伤害 = 基础伤害
        × 心法修炼度加成 (1.0 ~ 3.0)
        × 流派克制 (0.75 / 1.0 / 1.25)
        × 暴击系数 (1.0 / 1.5 ~ 2.5)
        × (1 - 目标防御率)
        × 境界差距修正
```

### 5.5 境界差距修正

| 境界差 | 攻方修正 | 守方修正 |
|--------|---------|---------|
| 同境界 | ×1.0 | ×1.0 |
| 差 1 大境界 | ×1.4 | ×0.7 |
| 差 2 大境界 | ×2.5 | ×0.3 |
| 差 3+ 大境界 | — | **×0.05（基本免疫）** |

**设计理由**：境界差是武侠世界的"硬天花板"。三流挑战一流可能赢一次，但挑战绝顶就是送死。这强迫玩家**修炼境界**而非堆砌装备。

### 5.6 血量与速度公式

```
最大血量 = 1,000 + 内力 × 0.7 + 根骨 × 500 + 装备血量
出手速度 = 100 + 身法 × 8 + 装备速度 + 心法速度加成
```

> 注：最大血量内力系数早期 v0.1 设为 5，Phase 1 平衡时为防玩家血量超 §5.2 红线 20,000 调为 0.7（武圣·登峰满根骨条件下 ≤ 20,000），代码以 yaml 为准，详 `numbers.yaml combat.max_hp_formula.internal_force_factor` 注释。出手速度公式无平衡变动。

---

## 6. 装备系统

> **核心设计：装备永不过时，一把好兵器陪你一生。**
>
> 强化上限随境界提升而提升（最高 +49），共鸣度随使用次数累积，师承传承可保留 70%。一把"二流"获得的好兵器，到了"宗师"境界依然可以是你的本命兵器。本设计直接对标主流手游"每升一级换全身装备"的疲劳感。

### 6.1 获取方式

| 来源 | 说明 |
|------|------|
| **战斗掉落** | 所见即所得（敌人用什么掉什么） |
| **江湖商店** | 每日真实日期刷新；机缘高的角色看到的价格更便宜 |
| **奇遇所得** | 高阶装备（重器以上）几乎只能这样获得 |
| **师承遗物** | 师父留给徒弟的兵器（每代传 **1-2 件**），自带传承 buff（内力上限 +5%） |

### 6.2 强化系统

**唯一资源**：磨剑石。

**强化等级上限** = 角色当前境界总层数（最高 +49）。

**强化数值**：每级 +5%。

**成功率与失败惩罚**：

| 等级区间 | 成功率 | 失败惩罚 |
|---------|-------|---------|
| +1 ~ +10 | 100% | — |
| +11 ~ +13 | 90% | 仅扣半数材料 |
| +14 ~ +16 | 75% | 全扣材料 |
| +17 ~ +19 | 50% | 全扣材料 |

**关键设计**：**不会破防降级**。最坏结果只是"白扣材料"，不会出现 +18 掉到 +12 的崩溃感。

### 6.3 心血结晶（保底机制）

- 每次强化失败必得 1 颗心血结晶。
- 消耗保底：
  - +14 ~ +16 强化时可消耗 **3 颗**直接成功
  - +17 ~ +19 强化时可消耗 **5 颗**直接成功

### 6.4 共鸣度（人剑合一）

装备使用次数累积，解锁递进 buff：

| 战斗次数 | 阶段 | 加成 |
|---------|------|------|
| 0 ~ 100 | 生疏 | 无加成 |
| 100 ~ 500 | 趁手 | 装备数值 +10% |
| 500 ~ 2,000 | 默契 | +20%，**解锁人剑合一招式** |
| 2,000+ | 心剑通灵 | +30%，**暴击附带剑鸣特效** |

**清零规则**：换主清零；师徒传承只清 70%（鼓励"一柄剑用一辈子"，并支持师承叙事）。

### 6.5 开锋系统（3 槽 build 选择）

| 解锁条件 | 内容 |
|---------|------|
| +10 解锁开锋一 | 选攻击 / 速度 / 吸血 / 破甲 一项永久强化 |
| +15 解锁开锋二 | 再选一项（不能与第一项相同） |
| +19 解锁开锋三 | 解锁专属技能词条 |

**设计理由**：装备到了高强化等级后，玩家有**主动 build 决策**而非纯堆数值。同一把剑可以走破甲流也可以走吸血流。

### 6.6 典故系统

- 每件装备 **1-3 个预设典故**。Demo 阶段需 50-100 条典故文案。
- **关键事件触发后自动追加"延续典故"**（例：用此剑斩杀某 Boss → 追加典故"曾饮某某之血"）。
- 5-10 个延续模板，基于事件类型动态生成。

**维护职责**：典故文案由 Windows 端 DeepSeek 维护（见 §11）。

---

## 7. MVP 三大特色系统

这三个系统是 Demo 的差异化卖点，必须在内测版本中可玩、可感知。

### 7.1 师徒传承

**身份设定**：玩家是**开派祖师**。

**解锁节奏**：

| 突破到 | 解锁内容 |
|--------|---------|
| 一流（结丹） | 收徒 |
| 绝顶（化神） | 徒弟可以收徒孙 |
| 飞升渡劫后 | 传位给大徒弟，前任成为**祖师爷**提供门派 buff |

**Demo 简化**：只做 **祖师 + 大弟子 + 二弟子** 3 个角色。

### 7.2 武学领悟（替代抽卡）

挂机 / 探索时累积**机缘值**。当**触发条件**满足时，弹出"灵光一现"事件，自动领悟新招。

**示例**：

> 剑客 + 在竹林挂机 + 雨天 + 击败 100 名剑客敌人 → 触发"听雨悟剑"。

**Demo 内容量**：30-50 招武功 + 20-30 个领悟触发条件。

**设计理由**：把"开包出货"的爽点改写成"江湖悟道"的爽点。同样是稀有内容的获得，但叙事完全不同。

### 7.3 时间锚点闭关

**三档闭关时长**：1 小时 / 4 小时 / 12 小时。

**真实时间机制**：使用**系统真实时间**计算，关闭游戏继续计时。

**时辰加成**：

| 时辰 | 现实时间 | 加成 |
|------|---------|------|
| 子时 | 23:00 ~ 1:00 | 内力增长 +20% |
| 正午 | 11:00 ~ 13:00 | 阳刚类武学 +20% |

**节气日**（清明 / 冬至等）：全属性 +30%。

**约束**：闭关期间角色**不可出战**。

**设计理由**：把现实时间编织进游戏，让"早上起床看子时闭关产出"成为仪式。同时三档分时也覆盖了"短时间游玩 / 临睡前 / 工作日全天"三种场景。

---

## 8. 内容结构

### 8.1 主线江湖路（3 章节）

| 章 | 标题 | 境界跨度 | Boss | 关键事件 |
|----|------|---------|------|---------|
| 1 | 学武出山 | 学徒 → 三流 | 山贼头子 | — |
| 2 | 武林初识 | 三流 → 二流 | 黑衣门主 | 收第一个徒弟 |
| 3 | 名扬江湖 | 二流 → 一流 | 魔教长老 | — |

- 每章 4-6 个关卡 + 1 个 Boss
- 共 **15-20 个关卡**，2-3 小时通关
- 文案风格：**轻剧情 + 重氛围**，纯文字，每场 20-100 字

> **Demo 锁 3 章**;Ch4「西出阳关」起属 §12.4「第二条主线」范畴(2026-05-21 P1 启动,详 `docs/handoff/p1_x_chapter4_spec_2026-05-21.md`)。yiLiu 全章 + 跨 jueDing 末 Boss + 西北边塞地理(玉门关 / 河西走廊 / 大漠 / 嘉峪关),数值已落 `data/stages.yaml` stage_04_01..05(commit `4f7fb6d`),narrative 13 文件已落 `data/narratives/{chapters/chapter_04, stages/stage_04_*}`(commit `be9ac31` + `0c8175b`)。

### 8.2 爬塔"问鼎江湖"（30 层）

| 层数 | 难度 |
|------|------|
| 1-10 | 简单 |
| 11-20 | 中等 |
| 21-30 | 困难 |

- 每 5 层小 Boss，每 10 层大 Boss
- **每天 5 次挑战次数**（自然限制非体力）
- 通关层数决定排行榜位置（Supabase 同步）

### 8.3 闭关"问道"（5 张地图）

| 地图 | 主要产出 |
|------|---------|
| 山林 | 经验 + 磨剑石（平均产出） |
| 古剑冢 | 兵器掉率 +50% |
| 藏经阁 | 心法领悟概率 +50% |
| 悬崖瀑布 | 内力增长 +50% |
| 断崖绝壁 | **仅宗师以上可去**，回报最高 |

### 8.4 内容总量（Demo 阶段）

| 项目 | 数量 |
|------|------|
| 主线关卡 | 15-20 |
| 章节剧情 | 3 |
| 爬塔层数 | 30 |
| 爬塔 Boss | 6（3 小 3 大，分别在第 5/15/25 层和第 10/20/30 层） |
| 闭关地图 | 5 |
| 武学领悟触发（techniqueInsight encounter） | 20-30 |
| 基础奇遇（fortuneEvent，非节日） | 15-25 |
| 节日 encounter（festivalRequired 独立通道） | 6-10 |
| 装备 | 30-50 件（覆盖 7 阶，每阶 5-7 件） |
| 心法 | 20-30 本（覆盖 7 阶 + 3 流派） |
| 武学领悟招式 | 30-50 招 |
| 心法相生组合 | ≥ 5 |
| 师徒角色 | 3（祖师 + 大弟子 + 二弟子） |
| 典故文案 | 50-80 段 |
| 主线剧情字数 | 3,000 ~ 7,000 字 |

> **奇遇三通道独立计算**（v1.2 拆分）：原 v1.1「奇遇事件 20-30 + 节日 6」混算
> 已拆为 3 独立维度,因 encounter type 分 `techniqueInsight`(GDD §7.2 武学领悟
> 触发,玩家境界突破前置)/ `fortuneEvent`(GDD §6.1 + §10 江湖奇缘内容)/ 节日触发
> (festivalRequired 独立窗口)。三类玩家感知与触发条件完全不同,合并计数易
> 漂移。**当前实装(2026-05-17 W18 实测)**:武学领悟触发 20 / 基础奇遇 16
> （24 fortuneEvent - 8 节日）/ 节日 8。
>
> **节日 encounter 独立通道**（W16/W17 GDD §12.4 落地 2026-05-16/05-17）：8 节日
> encounter（春节/元宵/端午/七夕/中秋/重阳 + 除夕/清明 共 8 条）走 `festivalRequired`
> 维度，全年仅对应公历窗口概率触发，**不挤占基础奇遇 15-25 池容量**。玩家年内
> 能触发的基础池仍是 15-25 上限，节日池为应景独立通道（GDD §12.4「节日活动：
> 不影响数值」的内容层落地）。

---

## 9. 核心循环

### 9.1 5 阶段循环

| 阶段 | 时长 | 内容 |
|------|------|------|
| 1. **开场看大家** | 0-2 分钟 | 看"昨晚发生的事"金色文字摘要 |
| 2. **调度门人** | 3-8 分钟 | 闭关安排、装备、心法选择 |
| 3. **战斗推进** | 5-12 分钟 | 主线 + 爬塔 + 奇遇战斗 |
| 4. **收尾安排** | 2-5 分钟 | 全员闭关安排，期待下次 |
| 5. **离线挂机** | — | 真实时间累积，奇遇触发 |

### 9.2 关键设计

- **上线第一屏 = "昨晚发生的事"**：金色文字的摘要，不是任务列表。
- **快速领取按钮**：30 秒最低限度上线流程，照顾忙碌玩家。
- **Windows 桌面通知**：极简，可关，默认温和。
- **不做快进**：在线离线收益相同。

**设计理由**：让"打开游戏"这件事本身具有仪式感——不是看到一堆红点要清，而是看到一段故事的延续。

---

## 10. 新手引导

### 10.1 解锁节奏

| 时间段 | 解锁内容 |
|--------|---------|
| 0-15 分钟 | 战斗 + 境界 + 装备掉落 |
| 15-30 分钟 | 装备强化 + 装备共鸣（被动展示） |
| 30-45 分钟 | 心法系统（先只展示主修） |
| 45-60 分钟 | 三流派克制（实战中遇到） |
| 1-2 小时 | 闭关系统 + 时间锚点 |
| 2-3 小时 | 师徒系统（收第一个徒弟） |
| 3-5 小时 | 奇遇 + 武学领悟 + 辅修心法 |
| 5-8 小时 | 装备开锋 + 心血结晶 + 心法相生 |

### 10.2 三种引导方式混用

1. **剧情包装的强制引导**（前 30 分钟）：师父教徒弟的视角，强制流程。
2. **上下文气泡提示**（30 分钟后）：红点 + 50-100 字介绍。
3. **江湖见闻录百科**（永久可查）：每条 200-500 字，详细机制说明。

### 10.3 设计哲学

> **"让玩家先感受问题，再给答案。"**

- 不预先讲规则，让玩家先遇到现象再揭晓机制。
- **第一次的爽点要留足**：暴击 / 突破 / 拿到利器 / 心法升级。
- **第一小时所有战斗让玩家轻松取胜**。
- **未解锁系统的菜单按钮直接灰掉或隐藏**，避免认知负担。

### 10.4 快速开局

- 二周目玩家可**跳过引导直接开档**，避免老玩家折磨。

---

## 11. 工作流与技术栈

### 11.1 双 AI 分工（重要）

| 端 | 工具 | 职责 |
|----|------|------|
| **Mac 端** | Claude Code + Opus 4.7 | 所有 Dart 代码、架构决策、Code Review |
| **Windows 端** | Claude Code + DeepSeek | 所有内容文本（剧情 / 典故 / 奇遇 / 心法描述） |

**冲突避免原则**：**文件类型完全隔离**。Opus 不动文案，DeepSeek 不动代码与数值。
**汇合方式**：GitHub 主分支汇合。

### 11.2 文件结构约定

```
data/
├── ranks.yaml          # 境界配置（Opus 维护）
├── equipment.yaml      # 装备数值（Opus 维护）
├── techniques.yaml     # 心法数值（Opus 维护）
├── stages.yaml         # 关卡配置（Opus 维护）
├── narratives/         # 剧情文案（DeepSeek 维护）
├── lore/               # 装备典故（DeepSeek 维护）
└── events/             # 奇遇事件文本（DeepSeek 维护）
```

### 11.3 技术栈

| 层 | 选型 |
|----|------|
| 状态管理 | Riverpod 或 BLoC |
| 本地存储 | Isar |
| 战斗动画 | 纯 Flutter Widget + AnimationController |
| 排行榜 | Supabase + Edge Function |
| 打包 | MSIX，先 itch.io 内测 |

---

## 12. 未来扩展

以下系统在 Demo 阶段**不实现**，但在设计时已为其留好接口与命名空间。1.0 正式版可逐步加入。

### 12.1 剧情与世界

- **江湖恩怨系统**：NPC 之间的关系网，杀某人会被其门派追杀。
- **心魔系统**:高境界突破前需面对心魔关卡,剧情化的内心战斗。**v1.10 1.0 P2.2 Batch 2.1-2.5 全收尾 ✅**(2026-05-23,10 commit `e666e4c → b15d34d` 全 push origin/main):7 关 `stage_inner_demon_01..07` 拦截 wuSheng 7 层突破(qiMeng → ruMen → ... → dengFeng → 飞升前置)+ `InnerDemonService.buildMirrorEnemyTeam` 深拷贝 playerTeam ×(1+10-40%) clamp §5.4 cap(`mirror_caps` HP ≤20k/IF ≤15k/Attack ≤6k=3×§5.4 单件 2000)+ `isLayerLocked` 拦截 hook 接 advancement_service.applyExperience(EXP 留账 §5.1)+ 3 callers wire(seclusion/tower/mainline)+ 失败 = 内力 ×0.85 / 主修修炼度 ×0.9 + 「心魔余毒」debuff 闭关 8h 清 + 22 narrative ~3,900 字(Tier wuSheng「湛然/寂照/圆融/化机」+ 7 主题贪/嗔/痴/慢/疑/空/真)+ **UI reactive 三态**(InnerDemonScreen cleared/available/locked + main_menu _MenuButton 入口)+ R1-R5 28 测 + **1220 pass / 0 analyze ✅**。Batch 2.5.A R5 实测 7 关分布全 3/0/47(克己语义「难赢但不输」)→ Batch 2.5.C 决议 `_07 +20% → +40%` 单副本 YAGNI(双镜像架构不动)+ `mirror_caps.attack_power_max 2000 → 6000` 纠 §5.4 维度。挂账 1.0 P3+:BreakthroughBlocker 集成 character_panel + 战斗机制层调优 + 7 enemy 立绘。详 `docs/handoff/p2_x_inner_demon_final_closeout_2026-05-23.md`。
- **门派事件**：地图上动态出现的门派冲突、武林大会、寻宝事件。

### 12.2 角色与社交

- **帮派 / 门派系统**：玩家创建的门派可招收弟子、占领山头。
- **婚姻 / 后代系统**：可结婚生子，子女有遗传属性 + 特殊事件。
- **声望系统**：行侠 / 行恶累积不同声望，影响 NPC 反应与剧情分支。

### 12.3 战斗与玩法

- **轻功对决**:在水面、屋脊、竹林上的特殊战斗形态。**v1.12 1.0 P3.1.B 子批收尾 ✅**(2026-05-24 branch `feat/p3_1_b` 主 cwd · 3 commit · 1242 pass / 0 analyze):damage_multiplier 真接入 `BattleCharacter.attackPowerMultiplier`(double default=1.0)+ `default_ground_strategy._calculateInBattle` raw 末乘 + `LightFootStrategy._bake` 烘焙(双方对等)+ R6 4 测;`skills.yaml +18` 招 lightfoot pool(yiLiu 9 招 cap=3000 + jueDing 9 招 cap=4000 · parentTechniqueDefId: null)+ stages.yaml stage_light_foot_01..05 enemyTeam.skillIds 全切到新池。R5.1 实测 bamboo stage_03 draws 4→1(双方等比削减,玩家主导未变)。**v1.11 1.0 P3.1 Batch 2.1-2.4 全收尾 ✅**(2026-05-23 夜 → 2026-05-24 晨,8h overnight worktree `feat/p3_1_lightfoot`,8 commit · 1238 pass / 0 analyze):5 关 `stage_light_foot_01..05` 跨 yiLiu(qiMeng/jingTong/dengFeng)+ jueDing(qiMeng/jingTong)2 Tier × 3 terrain(water/rooftop/bamboo)+ `LightFootStrategy` 组合委派 `DefaultGroundStrategy`(terrain modifier 烘焙到 BattleCharacter critRate/evasionRate/defenseRate · clamp ≤0.95 防红线破)+ `TerrainBiome` 独立 enum 3 项 + `numbers.yaml light_foot` 段(3 terrain × {crit/evasion/defense/damage} delta)+ 平行支线**不接管 wuSheng 突破链**(`isLayerLocked` 无 lightFoot 路径)+ unlock_triggers 链 `stage_06_05 → light_foot_01 → 02 → 03 → 04 → 05`。Batch 2.1-2.4 实装路径详 `docs/spec/p3_1_lightfoot_spec_2026-05-23.md`。
- **群战 / 守城战**:5v5 或更大规模的特殊关卡。**v1.13 1.0 P3.2 Batch 2.1-2.5 全收尾 ✅**(2026-05-24 worktree `feat/p3_2_mass_battle` · 5 commit · 1268 pass / 0 analyze · ~2h opus xhigh / spec 估 6-7h):5 关 `stage_mass_battle_01..05` 跨 yiLiu(qiMeng/jingTong/dengFeng)+ jueDing(qiMeng/jingTong)2 Tier · wave 2-4 / enemy 5-7「以少胜多」· `MassBattleStrategy` 组合委派 `DefaultGroundStrategy`(immutable runToEnd 一次性跑完 wave 循环 · formation modifier 烘焙**仅 leftTeam** · clamp ≤0.95 防红线破 · `_intermission` HP+IF preserve / actionPoint+cd reset / result 清空)+ `Formation` enum 3 项(yanXing/baGua/fengShi)+ `numbers.yaml mass_battle` 段 50 行 + 平行支线**不接管 wuSheng 突破链**(`isLayerLocked` 无 massBattle 路径)+ unlock_triggers 链 `stage_06_05 → mass_battle_01 → 02 → 03 → 04 → 05` + narrative ~2.2k 字「不躁/不乱/不溃/不让/不忧」五处试炼。**架构决议**:R5 红线测直接调 runToEnd 不走 UI(UI tick by tick 战斗 wiring 留 Batch 3.x)。**挂账 P3.2.B 数值调优**:stage_03/04/05 R5.1 全 draws(玩家 3 vs 累计 17-26 敌 maxTicks=2000 不足)解法候选:wave 间 HP 部分回血 / 敌方后波数值递减 / maxTicks 放宽。详 `docs/handoff/p3_2_mass_battle_closeout_2026-05-24.md`。
- **生死状 PVP**：异步 PVP，挑战其他玩家阵容（基于 Supabase）。

### 12.4 内容与节奏

- **第二条主线**：从一流到武圣的后续剧情（再 3 章）。
  - **Ch4「西出阳关」**:2026-05-21/22 P1 启动桥头堡全收口 ✅。yiLiu 全章(qiMeng→dengFeng 完整 7 层)+ 跨 jueDing·qiMeng 末 Boss(西凉霸主三人组 · 沉默克敌出手即决型 + 留 hook Ch5/Ch6 西凉小铜镜遗物)+ 西北边塞地理梯度(中原→河西走廊→玉门→大漠→嘉峪关)+ ~5,880 字 narrative + ~1,420 字 v1 章首尾(opus 单写 Tier 7 阶风格梯度词锚定)+ R5 跨阶红线压测 + GDD v1.3 / ROADMAP / PROGRESS 全联动。详 `docs/handoff/p1_x_chapter4_spec_2026-05-21.md` + `p1_x_chapter4_phase2_full_closeout_2026-05-22.md`。
  - **Ch5「征东」**:2026-05-22 P2 启动 · Phase 2 全收口 ✅ + Ch6 启动。jueDing 全章(qiMeng→dengFeng 完整 7 层)+ 跨 zongShi·qiMeng 末 Boss(C 复合三人组:西凉霸主三弟子 + 中州论剑顶 + 嵩山道宗 · 师承玉佩 hook Ch6)+ 中原东归地理梯度(嘉峪关→灞桥→潼关→渭水→嵩山道观→黄河义渡→中州论剑场→嵩山论剑顶)+ Tier jueDing 风格梯度词「沉静 / 从容 / 通达 / 入微」全章 + **师父遗言 3 处贯穿**(prologue 承上 + stage_05_05_victory 全听懂 + epilogue 第三句反转 hook Ch6)+ **物理遗物 hook 5 处闭环**(回取镜 → 玉佩出场 → 玉佩兑现 → 二字并放 → defeat 反例)+ **narrative 实测 ~6,638 字**(13 文件,对照 Ch4 ~5,880 字)+ 黑名单词 0 命中 + 1185+ pass / 0 analyze。详 `docs/handoff/p2_x_chapter5_spec_2026-05-22.md` + `p2_x_chapter5_phase2_full_closeout_2026-05-22.md`。
  - **Ch6「飞升」**:2026-05-22 午后 Phase 2 全收口 ✅ · **1.0 P2 第二条主线全闭环**。zongShi 全章(qiMeng→dengFeng 完整 7 层)+ 跨 wuSheng·qiMeng 末 Boss(**B 复合 = 西凉霸主本人首次开口 + 2 副 zongShi·dengFeng 西凉三弟子** · Ch4 小铜镜 + Ch5 玉佩三章 hook 全闭环 + **无物之境收束**四件物事并放青石不带走雪埋)+ 中原西渐地理梯度(中州论剑场散场 → 嵩山再访 → 黄河之源 → 昆仑山外 → 昆仑山顶飞升前夜)+ Tier zongShi 风格梯度词「澄澈 / 无为 / 玄妙 / 化境」全章 + **师父遗言第三句完整联通**(三章弧:Ch4 半懂前一句 / Ch5 第三句半解 / Ch6 三句话第一次完整连成一句)+ **narrative 实测 ~5,800 字**(13 文件:chapter + 10 stage opening/victory + 2 defeat,略低 spec ~6,600 ~10%)+ 黑名单 14 词 0 命中 + 1191 pass / 0 analyze + R5 跨阶 wuSheng 红线压测。详 `docs/handoff/p2_x_chapter6_spec_2026-05-22.md` + `p2_x_chapter6_phase2_full_closeout_2026-05-22.md`。

### 12.4.1 1.0 P2 内容总量表[v1.5 正式拍板,2026-05-22 用户审稿过]

> **2026-05-22 8h autonomous D1 起草 → Ch5 spec 起草前用户审稿正式拍板**。本表与 §8.4 Demo 现状表**解耦**(Demo 数字保留实测对齐),1.0 P2 升档由本表统管。Ch4 已落 + Ch5 spec 拍板进 Phase 2 + Ch6 待 spec 起草。

| 维度 | Demo §8.4 现状 | 1.0 P2 升档目标 | 倍数 | 备注 |
|------|---|---|---|---|
| **主线关卡** | 15-20(实测 20/20) | **25-30**(Ch4 5 落 + Ch5 拟 5 + Ch6 拟 5-10) | 1.5-2× | Ch6 飞升章可能 7-10 关(zongShi 7 层 + wushen 飞升前置) |
| **章节** | 3(锁) | **6**(Ch1-3 Demo + Ch4-6 1.0 P2) | 2× | 与 ROADMAP delta 表对齐 |
| **主线字数** | 3,000-7,000(实测 8,233) | **14,000-20,000**(Demo 8,233 + Ch4 5,880 + Ch5/Ch6 各 ~5,000) | 2× | Ch4 实测 ~5,880 字 / 章,Ch5/Ch6 同节奏 |
| **爬塔层数** | 30(锁) | **30**(1.0 不扩塔,留 2.0) | 1× | strategy 层 P0 ready,P3 扩战斗形态而非加层 |
| **闭关地图** | 5(锁) | **5**(1.0 不扩,留 2.0) | 1× | — |
| **武学领悟触发** | 20-30(实测 20) | **30-40** | 1.5-2× | — |
| **基础奇遇** | 15-25(实测 16) | **25-35** | 1.5-2× | — |
| **节日 encounter** | 6-10(实测 8) | **10-12** | 1.2-1.5× | 节气日扩 + 西北/西域节日 |
| **装备** | 30-50(实测 35+) | **80** | 2× | 全 7 阶 × ~12 件(每阶 5-7 件 → 全阶 80) |
| **心法** | 20-30(实测 21) | **50** | 2.5× | 全 7 阶 × 3 流派 × ~2 心法(每阶每流派 2-3 本) |
| **典故** | 50-80(实测 80+) | **160** | 2× | 装备扩 80 件 × 2 段 anecdote |
| **武学领悟招式** | 30-50(实测 35) | **70** | 2× | 各阶 + 各流派 + 隐藏组合 |
| **心法相生** | ≥5(实测 5) | **10-15** | 2-3× | 现有 5 + 1.0 P2 扩 5-10(跨流派 / 跨阶 / 师徒传承相生) |
| **师徒角色** | 3 硬种 | **飞升传承动态扩展** | 系统级 | A1 飞升 E.2/E.3 + 遗物 transfer(GDD §7.1 + CLAUDE.md §12.2 #10) |
| **战斗形态** | 1(地面 3v3) | **4**(地面 + 轻功 + 群战 + 异步 PVP) | 4× | P3 启动后扩 strategy 层 plug-in |
| **社交系统** | 0 | **4**(帮派 / 声望 / 江湖恩怨 / 门派事件) | 0→4 | P1.2 + P3.4 + P4.1 联合扩 |

#### 1.0 P2 数值红线沿用

- §5.4 数值红线**完全不动**:普伤 ≤8,000 / 玩家血 ≤20,000 / 内力 ≤15,000 / 装备攻击 ≤2,000 / Boss HP ≤50,000(Ch4 实测 15,500 远低)
- §5.3 三系锁死**完全不动**:境界 ↔ 装备阶 ↔ 心法阶 一一对应(Ch4 末 Boss 跨阶 jueDing 用 jianghu 阶 skill 沿例)
- §6 核心公式**完全不动**:基础伤害 / 最大血量 / 出手速度 / 境界差距修正

#### 1.0 P2 风险挂账

| # | 风险 | 应对 |
|---|---|---|
| R1 | Ch5/Ch6 主线关数升档可能撞红线层 grep 漏检(参 Ch4 R0 经验) | Ch5 Phase 0 reality check 起手必跑「红线层 / UI 硬码 list / test 总数」5 维 grep(memory `feedback_phase0_grep_two_axes` 维度 E) |
| R2 | 主线字数 14-20k 单端 opus 产能验证 | Ch4 实测 ~50min 单批 ~4,460 字(opus xhigh) → Ch5/Ch6 各预算 1-1.5h 内可完(单端文案产能验证 ✅) |
| R3 | 装备 80 / 心法 50 数值平衡级联 | P0.1 #38 平衡已 ready(base maxHp ≤ 16,667),P2 扩装备/心法仍在此框架下不破红线;但 jueDing/zongShi/wushen 装备阶 baseAttack/baseHealth 上限需 spec 起草前预审 |
| R4 | 共鸣度 / 开锋 / 师承遗物 / 飞升传承等系统层与第二条主线交互复杂度 | P1.1 已收口(候选 2/3/4 / CLAUDE.md §12.2 实装表),P2 心魔 + 飞升各 1 spec 起草前依赖审计 |

#### 字数预算细分

| 章 | 主线字数 | narrative 文件 | 备注 |
|---|---|---|---|
| Ch1 学武出山(Demo) | ~1,500 字 | chapter_01 + stages 8 文件 | 实测对齐 |
| Ch2 武林初识(Demo) | ~2,000 字 | chapter_02 + stages 9 文件 | 实测对齐 |
| Ch3 名扬江湖(Demo) | ~4,800 字 | chapter_03 + stages 12 文件 | 实测对齐 |
| **Ch4 西出阳关(1.0 P2)** | **~5,880 字** | **chapter_04 + stages 13 文件** | **2026-05-22 实测 ✅** |
| **Ch5 征东(1.0 P2)** | **~6,638 字** | **chapter_05 + stages 13 文件** | **2026-05-22 Phase 2 全收口 ✅** |
| **Ch6 飞升(1.0 P2)** | **~5,800 字** | **chapter_06 + stages 13 文件** | **2026-05-22 Phase 2 全收口 ✅** |
| **合计** | **~26,551 字** | — | **1.0 P2 ~18.3k 字 = 5,880 + 6,638 + 5,800(质感饱满 +83% 超 14-20k 上限)** |

#### 内容投放节奏

- **Ch4 → Ch5**:dropTable `weapon_zhongqi_qing_xu_jian` 已 1.0 投放(末 Boss 主奖,给 Ch5 jueDing 起步装备)+ `accessory_zhongqi_qing_yu_huan` 0.5 投放(jueDing 配饰 起步)
- **Ch5 → Ch6**:zongQi 装备 (jueDing cap) 应在 Ch5 末 Boss 投放,Ch6 启用 baoWu / shenWu(zongShi/wuSheng cap)装备(spec 时审 weapon 路径连续性)
- **典故 / 武学领悟招式 / 心法相生**:1.0 P2 扩段与 Ch4-6 主线推进**并行**,不必严格绑定章节(玩家奇遇路径触发,可在任章遇到任 typ)

- **节日活动**:春节、中秋等真实节日的限定剧情(不影响数值)。
- **MOD 支持**:开放 yaml 数据加载,允许玩家创作自定义关卡 / 心法。

### 12.5 长期愿景

- **角色寿命与传承**：角色有真实寿命（30-100 年游戏内），死亡后由弟子继承遗志。
- **江湖编年史**：玩家所有重要事件自动写入家族编年史，可导出为 PDF。
- **跨周目元数据**：第二周目继承部分典故 / 装备认知，但人物全新开始。

---

## 附录 · 文档约定

- 所有数值类配置统一存放于 `data/*.yaml`，**不允许在 Dart 代码里硬编码数值**。
- 所有文案统一存放于 `data/narratives/`、`data/lore/`、`data/events/`，**不允许在 Dart 代码里写中文文案**。
- 修改本文档需在 commit message 注明 `[GDD]` 前缀，并简述变更影响范围。
- 所有子文档（如 `COMBAT_DETAIL.md`、`EQUIPMENT_DETAIL.md`）必须在文首标注"遵循 GDD.md v1.1"。

---

**文档结束。**
