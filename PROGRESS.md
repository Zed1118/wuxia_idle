# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

> 📊 **2026-05-29 1.0 路径方向调整 · F+G 搁置 · H 主聚焦 · 外部 review 修复批收口 + 根因A 挂机循环重平衡实装 + idle_economy 验证 + 红线值统一 numbers.yaml + B2 低 tier 挂机 EXP finding 修(回 ×1.0)+ CHECKLIST/ROADMAP v1.11 复核 + balance_simulator 升真 build + floor/ceiling bracket + on-level 修正(暴露真问题:stage_01_05 Ch1 Boss +2 阶硬墙)+ B3 结算屏去凝练引导 · 1555 测 / 0 analyze**

**2026-05-29 红线值 15000/20000 统一到 numbers.yaml**(commit `7a1d1e7` [schema] · 1548→1552 测 / 0 analyze):消除 derived_stats / stage_battle_setup / game_repository 散落的 §5.4 红线字面量,单一真相源走 `combat.red_lines`(player_hp_max 20000 / internal_force_max 15000)+ 新 `RedLinesConfig` 强类型(fixture 缺段回落 §5.4 默认,沿 InnerDemonMirrorCaps 体例)。wire 4 处:derived_stats.maxHp/internalForceMaxWithLineage、stage_battle_setup.applySynergy(加可选 `{NumbersConfig? numbers}` 默认回落 `GameRepository.instance.numbers`·synergy_hot_loop 纯测 setUpAll 加 loadAllDefs Isar-free,12 调用点不动)、game_repository._enforceRedLines。inner_demon.mirror_caps 已独立 config-driven 不并入。+4 测(parse/fallback/production drift guard/49 realm 校验)· 纯抽取零行为变化。**`_synthPlayer` 升真 build ✅**(2026-05-29 晚 · xhigh · 用户拍「活跃玩家」B 模型):换旧线性硬编码 BattleCharacter → `_buildRealPlayer` 走生产 `BattleCharacter.fromCharacter` derived_stats 路径(tier-cap 真装备 midpoint base+中等强化½+共鸣默契×1.20+主修 daCheng+founder buff · 在内存造 Character/Equipment/Technique 无 Isar)。**finding**:满配活跃玩家碾压整条主线 — 30 关 29 关 100% winRate(唯 stage_01_05 Ch1 Boss 66%)。**C 方案 floor+ceiling bracket ✅**(2026-05-29 晚续 · 用户拍 A):`_buildRealPlayer` 加 `_BuildProfile` 两档(floor 欠配置:0 强化/生疏共鸣/无 founder buff/zhongCheng/属性 20 — ceiling 活跃玩家:½ 强化/默契/founder buff/daCheng/属性 22),每关跑两档给 winRate 区间(3000 runs)+ 难度诊断重定义(过难=连 ceiling<50% / 过易=连 floor>90%)。**sim on-level 修正 ✅**(2026-05-29 晚续 · #2 诊断中纠 confound):Phase 0 发现旧「全程过低」是 sim `playerTier=requiredRealm+1`(死掉的假 _synthPlayer 时代 hack)所致 — 真 build 下玩家凭空 +1 阶 vs 同阶敌人把后段全冲 trivial。去 +1 → on-level 诚实基线后**真相完全不同**:floor 欠配置玩家有真难度曲线(多数 Boss 0-10% 难、要配装才过),**之前「连 floor 都碾压」是 confound 假象**。**真实结论(on-level)**:① ~17 关健康(配装有意义)· ② 过易 11 关(多是章首杂兵 _01/_02)· ③ **过难 2 关**:`stage_01_05`(Ch1 Boss 0%/0% 连满配 on-level 都打不过 · 敌人 +2 阶 erLiu 是全 Boss 唯一 · 新玩家硬墙)+ `stage_05_05`(0%/30% 偏硬)· ④ ceiling 满配仍碾压多数(配装 power fantasy 是否管=设计取舍)。**诊断挡下错误重平衡**(#2「抬全程数值」基于 confounded sim)。D 段真该做的窄:修 stage_01_05 +2 阶墙 +(可选)stage_05_05 放缓 · 改 stages.yaml 需 ask。

**2026-05-29 D 段 stage_01_05 Ch1 Boss +2 阶硬墙修复**(commit `781c85b` [balance] · 1555 测 / 0 analyze · 用户拍「判为 bug 对齐体例」):敌人 realmTier=erLiu(+2 阶 vs 章节 xueTu)是全 6 章末 Boss 唯一双 +2(其余 Ch2/Ch3 at-tier、Ch4-6 lead≤+1),sim on-level **ceiling 0%**(满配玩家也打不过)= 数据不一致硬墙(非有意新手墙 · 违 §5.7)。对齐 Ch2/Ch3 at-tier 体例:3 敌全 xueTu/dengFeng/jichu 技能组(boss 留 ult),数值按 Ch2 boss premium(同阶 mob ×1.1 HP/×1.07 atk)缩放(HP 9-10k→3.5-3.8k · atk 700-750→150-165)。**sim 验证**:ceiling 0%→**100%** / floor 0%→**6%**,与 02_05(100%/10%)03_05(100%/0%)同剖面。无测试断言敌人数值(e2e 仅断不抛+result 有解)。**D 段过难 2 关 → 剩 1**:stage_05_05(0%/30% 偏硬)留低优先。ceiling 满配碾压多数 = 买断单机 power fantasy 设计取舍,1.0 可暂接受。

**2026-05-29 D 段 stage_05_05 Ch5 Boss 跨阶过苛缓和**(commit `24cea80` [balance] · 1555 测 / 0 analyze · 用户拍「偏调拉回曲线」):敌人 HP 跨阶增幅 ×2.13 超调(曲线 ~×1.5/阶),sim on-level ceiling 仅 30%。**诊断中发现 layered 守护**:`ch5_r5_crosstier_redline_test` 守「跨阶 zongShi Boss 保留威慑 · 满 build 玩家不该 100% 横扫」的有意设计(memory `feedback_wuxia_boss_balance_crosstier`)—— 全幅拉回曲线(×0.76)破守护线(满 build 50/50 横扫)。改取更轻 **×0.88 HP/×0.93 atk**:ceiling 30%→**76%**(落进 Boss 健康带 55-85%),R5 威慑守护线**仍过**,floor 0% 维持。**D 段过难关清零**(全 6 章末 Boss ceiling 76-100% / floor 0-10% · summary 过难段空)。教训:05_05 非 01_05 式数据 bug,是 test-guarded 跨阶威慑设计,软化幅度受 R5 下边界硬约束。

**2026-05-29 根因A 挂机经济曲线验证 idle_economy**(test + doc only · 0 production 改 · 1547→1548 测):新建 `test/tools/idle_economy_test.dart` 量化 72h 挂机 vs 主动战斗在根因A 三维成长速度,断言「可观但不冲淡主动战斗」平衡带(drift 雷达)。**Phase 0 事实修正**:上次「balance_simulator 未接真公式」已过时 — win-rate sim 走 `BattleEngine.runToEnd→DefaultGroundStrategy._calculateInBattle`,P2-c 后即调 `DamageCalculator.calculateResolved` 单一真相源,**伤害公式数学早已是真路径**;残留缺口仅 `_synthPlayer` 硬编码 build(用户拍板本批不动)。**验证结果**:B1 ✅ 72h=360≥默契300、到阈值60h(离线可达人剑合一不秒解锁);B2 设计锚 ✅ 二流 xuanYaPuBu 折 3.5 个 Ch3 Boss(命中目标 3-4);B3 ✅ 五图凝练 0.36-2.0 早期层(有意义 sink);**finding**:B2 低 tier 偏慷慨 — 学徒山林挂满 72h 跳 16 层(早期阈值 50-400 极小 ×2.5)。输出 `test/tools/output/idle_economy_2026-05-29.md`。**→ B2 fix 已修(2026-05-29 晚 · 用户拍 B 方向)**:finding 纠正(主线按 clearedStageIds 解锁非境界 → 非跳内容,真实影响是挂机优先早期战斗碾压)· 山林/古剑冢/藏经阁(学徒/三流图)`experience_per_hour` 回 ×1.0(原值 100/80/90,撤 ×2.5),山林满挂 16→12 层落点三流(对 Ch1 差 1 阶不碾压);erLiu+ 保 ×2.5 · idle_economy 加 B2-c 语义回归守(学徒图满挂落点 < 二流)+ seclusion_service_test 6 测同步(山林 4h 1000→400 · 升层 6→3 至 jingTong)· 1552 测 / 0 analyze。

**2026-05-29 根因A 挂机循环重平衡实装 B1+B2+B3**(2 commit `a359dc2` spec + `d7ee3f9` 实装 · 1540→1547 测 / 0 analyze · xhigh · 用户拍 3 数值方向):挂机离线收益对中期成长贡献微乎其微(品类硬伤,H2 audit 根因A)。**B1 共鸣度双管**:闭关挂机折算 battleCount 喂出战装备(`resonance.seclusion_battle_count_per_hour=5` · 72h+360)+ 默契阈值 500→300 → 人剑合一离线/中期可及(`seclusion_service.completeRetreat` wire + `entities/character_panel` 阈值测同步 + GDD §6.4 同步)。**B2 闭关 EXP ×2.5**:5 地图 experience_per_hour ×2.5,72h ≈ 3-4 个 Ch3 Boss(原 1.4)(seclusion EXP 级联升层断言 1000 EXP→6 层重算)。**B3 insightPoints 死钱包变 sink**:抽 `CultivationService.applyProgressDelta`(不计 skillUsage)+ 新 `InsightExchangeService` 凝练领悟点→主修修炼度(ratio 1.0)+ `technique_panel`「凝练领悟」入口 + provider。闭关挂机→insightPoints→玩家凝练→修炼度链路(不开学心法 UI,维持 §7.2 scoped)。+7 测(B1 2/B3 5)。红线不破(§5.4 不涉战斗数值)。**B3 sink 引导 polish ✅**(2026-05-29 晚):闭关结算屏 insightPoints>0 加「领悟点可在心法面板凝练」气泡(§5.7 提示非弹窗 · `seclusionInsightHint` + `_InsightHint` widget + 3 widget 测)。

**2026-05-29 外部 review P2-a/P2-b + P3 文档 drift 三项收口**(3 commit `62b0b7e` P2-a + `2686815` P2-b + `1afc888` P3 · 1539→1540 测 / 0 analyze):**P2-a** 奇遇招式池空静默失效 — `encounter_skills.yaml` 生产损坏/缺失被 catch 吞掉时招式池空,`_enforceEncounterSkillRedLines` unlock 一致性校验被 `encounterSkillIds.isNotEmpty` 闸门跳过 → 奇遇 unlockSkill 招式静默失效(注释还谎称"生产仍校验")。去闸门 + 空池有引用即 fail-fast + 红线测。**P2-b** 敌人属性 hardcode(`stage_battle_setup:282` maxIF:1000/crit·evade:0.05)抽到 `numbers.yaml combat.enemy_defaults` + 新 `EnemyDefaults` config,纯抽取零行为变化(按境界缩放留根因A 批)。**P3** 三文档(GDD §5.6 / CLAUDE §6 / AGENTS §6)血量公式 ×0.7/×500、AGENTS 更旧 ×8/×5 同步到代码真值(装备攻击 1.0 / 内力 0.5 / 根骨 400 · P0.1 #38 方案 D)。**踩坑**:fresh worktree `libisar.dylib` 截断(1010466 vs 完整 2187120 bytes · `download:true` 下到一半)致 37 setUpAll dlopen 失败,从主仓拷完整副本修复。外部 review 修复批剩:**根因A 挂机循环重平衡**(前置全清,需先讨论数值方向 + 升 xhigh) + balance_simulator 改打真公式 + 红线值统一到 numbers.yaml。

**2026-05-29 外部 review P2-c 战斗公式双路径收敛**(commit `f719172` · 重构保形 · 1537→1539 测 / 0 analyze):`DamageCalculator.calculate` 与 `DefaultGroundStrategy._calculateInBattle` 各复制一份相同公式数学,改一处另一处 drift,违 §6。诊断:**production 只跑 _calculateInBattle,DamageCalculator 实为测试专用参考实现** → balance 验证打错公式。抽 `DamageCalculator.calculateResolved(primitives)` 为唯一真相源,双路径变薄 adapter;3 处口径差异(IF 满/当前 · defenseRate 境界base/缓存含相生 · attackPowerMult 1.0/烘焙)收为显式参数。_calculateInBattle 删 ~100 行重复数学。行为零变化(100+ 公式钉死测全绿)+ P2-c 聚焦测 2。外部 review 修复批剩:P2-a/b 健壮性 / P3 文档 drift / 根因A 挂机循环重平衡(前置 P1-b✅+P2-c✅ 已清,可动)。

**2026-05-29 外部 review P1-a 飞升 auto_swap 三系锁死修复**(commit `559455f` · TDD · 1535→1537 测 / 0 analyze):`performAscend` 副作用 4 auto_swap 直写 `disciple.equipped{Slot}Id` 无 canEquip → 武圣神物可自动装到低境界徒弟,破 §5.3(师承遗物不例外)。加 `Equipment.isEquippableAtRealm(RealmTier)` 域规则(`tier.index ≤ realm.index`)+ auto_swap 上身前守卫(不够阶只转 owner 入背包不上身)+ R5.11 红线测 2 测 + R5.6/R5.7/R5.10 收装徒弟 boost 够阶(原断言建立在违规行为上)。外部 review 修复批剩:P2-c 公式统一(根因A 前置)/ P2-a/b 健壮性 / P3 文档 drift / 根因A 挂机循环重平衡。

**2026-05-29 H3 后期挑战 audit + A2 🔴 修复**(2 commit `0cd5c81` audit + `20d7273` fix · 1534 测维持 / 0 analyze):4 并行子 agent Phase 0 grep(Ch4-6 主线/心魔/群战+轻功/飞升)→ `docs/handoff/h3_lategame_audit_2026-05-29.md`(~105 行)。**后期整体远比中期健康**(大量 🟢:难度曲线+红线+叙事接线全成熟,Ch4-6 35 narrative 0 dangling)。**唯一 🔴 = A2 多代飞升循环断裂**:`performAscend` 真传位漏写 `save.founderCharacterId=promotedDiscipleId` → gen2「祖师不在出战阵容」永久 blocked、被 R5.6/8/10 测试手动 setup 掩盖 · 主控 grep 复核铁证 + 红绿修复(1 行 production + 删测试 setup 暴露真实闸门 + R5.6 防回退断言)。其余 🟡 polish(后期入口境界门控 §5.7 / 轻功+群战解锁撞同关 stage_06_05 / Ch6→飞升路标)并入后续 polish 批。**下一步:根因A 挂机循环重平衡(需先讨论数值方向)**。

**2026-05-29 H2 小套餐(接线 polish)实装**(TDD · 0 数值改 0 schema 改 · 1520→1534 测):**C1 章节翻篇过场**(loadChapter + ChapterTransitionScreen + chapter_list「卷」入口 · prologue/epilogue 此前 dead content 变可达)+ **C2 升阶大境界仪式**(AdvancementResult.crossedTier → AdvancementSummary/retreat banner 大境界走 military_tech+badge,区别小层升级)+ **E2 effective 实战值可见**(detail _StatRow 显强化×共鸣×开锋乘法值 + 「基 N」副标)+ **S3 死字段清理**(cultivation_progress_pct 移除误导 UI 行 + numbers.yaml 注释加重)+ **R2 verified 已实装**(victory dialog ResonanceUpgradeBanner 早在 P1.1 候选 3-a,不加冗余 toast)。defer:C1 Boss 自动仪式 / E2 换装 delta / 根因A 挂机循环重平衡(中套餐)。详 closeout `m15_h2_small_polish_closeout_2026-05-29.md`。

**2026-05-29 H2 中期玩法深度 audit 完成**(doc only · 0 代码改):4 并行子 agent Phase 0 grep(装备/心法/师徒+共鸣/闭关+章节+升阶)→ `docs/handoff/h2_midgame_audit_2026-05-29.md`(~135 行)· 6 条 load-bearing 断言 grep 实测核验。**两大根因**:A 挂机循环与中期成长脱节(idle 0 喂共鸣度/修炼度 · 闭关鸡肋 · insightPoints/learnPoints 死钱包)+ B backend 做完前端没接线(章节翻篇 dead content · 学心法 UI 0 caller · 升阶大境界 UI 不区分 · 换装 effective 不展示 · cultivation_progress_pct 死字段)。3 套餐候选(小=接线 polish 0 数值改 / 中=挂机循环重平衡 / 大=深度加深 1.1 级)+ H2-Q1~Q4 决策点等用户拍。**推荐 小套餐**(已产 backend 接线 ROI 最高)。

**2026-05-29 H1-Q1 小套餐实装**(1 commit `a497044`):G1 `mainMenuTitle '挂机武侠 · 调试主菜单' → '挂机武侠'`(P0 ship blocker 清 · production-facing 产品名)+ G5 标题 style 24→28/w600/letterSpacing 4(沿 splash 体例次一档)· main_menu 测 30 全过含标题渲染 · 0 analyze · 顺手清 8 个往期遗留工作树(全已并入 main + clean)。**P0 ship blocker 清零**。

**2026-05-29 5h 挂机推进 · 方向调整**:用户拍板「先打磨游戏再启 Steam」→ F/G 搁置(留 ship 前 1-2 月)+ H 段从 nice-to-have 升「内容打磨 + UX」主聚焦 + Q1-Q4 默认决议 + 方案 A 单线推 D4。本批 Batch A0-A5 推进:CHECKLIST v1.9 + ROADMAP 对齐 + H 段 spec 起草 + `tools/balance_simulator.dart` PoC + 30 关全路径 1500 跑 + 难度曲线 csv + numbers tune 候选 diff(不上线,起床用户拍)+ R5 测族保护。

> 2026-05-28 三条(CHECKLIST v1.5+ROADMAP v1.8+R4 派单 / 装备 drop 全覆盖+P2.1 4 批 / P3.2.B+P1.2+P3.x+过夜清理 · 1508→1519 测)已归档,详末尾「2026-05-25/26/27/28 详条归档」段。

---

**2026-05-27 Boss 招降叙事+debug 招募+R2 派单**(7 commit · 1505 测):详 `session_closeout_2026-05-27_boss_narrative_debug_recruit.md`。

---

**2026-05-25/26/28 归档**:见末尾归档段。

## 已完成(近 W6 起,早期归档见末尾)

> W15 + W17-W18 + P5+ + P3.1+P3.2+心魔+Ch4-6 详条均已归档,详末尾归档段。

## 已知偏差 / 挂账事项

- ~~37 / 38 / 40 / 41 / 42 / 43 / 44 / 45 全销账~~(2026-05-17/18/19/20):详各 closeout

> 已销账条目(#1-#45)详见末尾归档。**P1 阶段全销账 ✅** + **Demo §8.4 14/14 全达标 ✅** + **1.0 ~95% release ready ✅**(A+B+C 全 PASS · 剩 D-G 留 M15-16)。

## 关键约束(每次开局必读)

- 数值红线:普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000(GDD §5.2)
- 不硬编码数值/文案(走 numbers.yaml / data/narratives, lore, events)
- Riverpod 状态管理;Isar 本地存储;data/ asset 根
- 不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md(数值/规则层 · 改前 ask)
- Mac 端写 lib/、data/(顶层)、test/、文案(v1.8 起 DeepSeek 退役)

## 远程仓库

- GitHub:https://github.com/Zed1118/wuxia_idle · 主分支 main
- 协作:Mac+Opus 单端代码+数值+文案;Codex 桌面 @ Pen 跑视觉验收

## 归档

### 已解决挂账(逆时序)

- **Phase 1-2 + W1-W13 全销账**(2026-05-10..14):#1/5/12-16/19-29/32 + #18 伪挂账

### Phase 1-4 早期详条已迁出

- Phase 1-3 + W4-W11:`phase{1,2,3}_summary.md` + tags `v0.1.0-phase1` / `v0.3.0-w11`
- W14-W15 + Phase 5 #2/#3 销账详条:git log + handoff/各 closeout

### W17-W18 详条迁出 2026-05-19/20

13 段销账(P1 #42-45 / Nightshift 9 task / P0 4 段 / 外部审查 6 项 / 路线图 launched / Codex 视觉)。详 `p1_4{2,3,4}_*` / `nightshift_20260519_handoff.md` / `p0_38_maxhp_rebalance_closeout_2026-05-17.md` 11 closeout。

### P1.1 候选 1-5 详条迁出 2026-05-21

5 候选全收口(4 实装 + 1 doc):候选 1 收徒池 E.1 / 候选 2 祖师爷 sect_wide_buff / 候选 3 共鸣度 4 子任务 + joint_skill / 候选 4 开锋 build / 候选 5 CLAUDE.md §12 对齐 — `p1_1_*_closeout_2026-05-21.md` 5 closeout。

### M4 #46 美术 + Ch4 Phase 2 详条迁出 2026-05-20/22

- **M4 #46 美术** 5 段(2026-05-20/21):Stage 2 W1-W6 74/74 + assets 89 张 + stage_audit + #45 Demo §8.4 · 详 art_poc_* / art_assets_integration_* / p1_45_demo_polish_*
- **Ch4 1.0 P2 第二条主线第 1 章**(2026-05-21/22):Phase 2.1-2.5 全收口 + 13 narrative ~5,880 字 · 详 p1_x_chapter4_phase2_*

### 2026-05-22/23/24 详条归档

- **2026-05-22 Ch5 + Ch6 飞升 P2 主线全闭环**(2 章 ~12,438 字 · 师父三句遗言完整连通 · 小铜镜+玉佩 hook 闭环 · 详 `p2_x_chapter{5,6}_phase2_full_closeout_2026-05-22.md`)
- **2026-05-23 心魔 Batch 2.1-2.5 + P3.1 轻功对决**(8h overnight worktree · 7+5 关 · 详 `p2_x_inner_demon_final_closeout_2026-05-23.md` + `p3_1_lightfoot_closeout_2026-05-23.md`)
- **2026-05-24 P3.2 群战守城 + P3.1.B 子批 + P5+ 多代飞升 + 真传位 + 8h overnight v2/v3 + nightshift v2 首跑 + UI polish**(git log `efc7604 → b6d8191` 区间 · 详 handoff `p3_2_*` / `p3_1_b_*` / `p5_lineage_full_closeout_2026-05-24.md` / `nightshift_v2_first_run_closeout_2026-05-24.md` / `8h_autonomous_handoff_2026-05-24.md`)
- **2026-05-25 v2.1 工具完善 + T17-T22 cherry-pick + T23/T24 6 关键问题闭环批**(main `74ba519 → b6d8191` · 1458 测 / 0 analyze · 批次质量 A 9.05/10 · P1.2 江湖恩怨+声望 100% + 技术债 3 合一 · 详 `session_closeout_2026-05-25_nightshift_6h_review.md` + `p1_2_jianghu_full.md` + `p3_tech_debt.md`)

### 2026-05-25/26/27/28 详条归档

- **2026-05-25 P4.1+P5.0+audit v2**(1458→1484 测 · 详各 closeout)
- **2026-05-26 P4.1 1.1 四项+audit v3+P5.2+Boss 招降叙事**(1484→1505 测 · 详各 closeout)
- **2026-05-27 Boss 招降叙事+debug 招募+R2 派单**(1505 测 · 详 `session_closeout_2026-05-27_boss_narrative_debug_recruit.md`)
- **2026-05-28 过夜清理+P3 三项+P2.1 4 批+drop 全覆盖+CHECKLIST v1.5+R4 派单**(1505→1519 测 · 详 `overnight_1_1_cleanup_handoff_2026-05-28.md` / `session_closeout_2026-05-28_p3_p1_triple.md` / `codex_dispatch_r4_p2_1_content_drop_2026-05-28.md`)
