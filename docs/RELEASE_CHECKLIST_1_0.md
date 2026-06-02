# 挂机武侠 1.0 Release Checklist

> **v1.0** 起草 2026-05-25 · Mac+Opus xhigh · **长寿文档**(跨阶段更新)
> 状态来源:`docs/handoff/1_0_release_audit_v2_2026-05-25.md` 6 系统快照 + 本会话 P5.0
> 与 `docs/ROADMAP_1_0.md` 互补:ROADMAP 是 16 月宏观规划,本文档是 Steam 上线前**二元勾选清单**
> ⚠ 本 checklist 是 Steam 1.0 上线前的最终勾选,**所有 A-E 段必收勾完方可上线**

## TL;DR

**当前 release readiness:~99%**(A+B+C 全 PASS · 0 P0/P1 阻塞 · **出版美术 pass 整体全闭环**〔战斗屏 A+B1+B2 + 剧情屏 + 战斗场景 16 biome + §12 上线门 11/12,唯音频缺〕· **1667 测 / 1 skip / 0 analyze** · stage_05_05 跨阶墙 sim 复核销账 2026-05-31)

**2026-05-29 方向调整 + D/H 首批落地**:用户拍板「先把游戏打磨完成,再启 Steam 上架」→ **F + G 段搁置**(留 ship 前 1-2 月)+ **聚焦 D + H 新增 + E 部分**(E1 SoundManager + E5 BGM 1 套)。1.0 路径 ≠ 全 D/E/F/G 串行,而是「游戏打磨完成度」优先。**当日 H/D 首批已落**:H 中期/后期/卡点三审计全完 + H 接线 polish 5 项 + 外部 review 5 项硬化(P1-a 三系锁死 auto_swap / P2-c 公式单源 / P2-a/b 健壮性 / P3 文档 drift)+ 根因A 挂机循环重平衡(B1+B2+B3)+ idle_economy 经济曲线验证 + 红线值统一 numbers.yaml(单一真相源)。

| 段 | 完成度 | 阻塞? | 当前优先级 |
|---|---|---|---|
| A 代码质量 | ✅ 100% | — | 维持(1667 测) |
| B 系统完整性(6 系统) | ✅ 100% | — | 维持 |
| C 视觉验收 | ✅ 100% C.1 8/8 + C.2 4/4 + C.3 10/10 + C.4 12/12 + **C.5 H1 批3 5/5 + 白屏证伪 ✅** | — | 全收口(神物金 drop + 凝练 50 点态 + §9 新色 ✅ 2026-05-30 Pen+Codex+Mac 3/3 PASS) |
| **D 性能 + 数值再平衡(P5.2)** | 🔄 ~20%(数值再平衡首批 ✅:根因A + 红线统一 + idle_economy 验证 · 性能/closed beta 留 M15-16) | M15-16 | **🎯 主聚焦** |
| E 音频 部分(P5.3)| ✗ 0% | M15-16 | E1 SoundManager + E5 BGM 1 套纳入 / E3-E7 ship 前 1-2 月 |
| **H 内容打磨 + UX**(新增) | 🔄 ~65%(中期/后期/卡点 3 审计 + 接线 polish 5 项 + **H1 上手 audit 全闭环 ✅** · UX 微调 / 文案终 polish 续) | M15-16 | **🎯 主聚焦** |
| ~~F Steam 集成(P5.4)~~ | ⏸️ 搁置 | ship 前 1-2 月 | F1 guide 已起草 `docs/handoff/m15_f1_*` 待启 |
| ~~G 法律商业~~ | ⏸️ 搁置 | ship 前 1-2 月 | 与 F 同步启动 |
| **H′ 出版美术(Presentation Pass)** | ✅ ~95%(战斗屏 A+B1+B2 + 剧情屏 + 战斗场景 16 biome 全闭环 · §12 上线门 11/12) | — | 唯音频(§12 #10)留 E 段 |

## A. 代码质量(本机可验 · ✅ 全过)

- [x] `flutter analyze` 0 issues
- [x] 全测族过(**1581 测** / 1 skip / 144 测文件)
- [x] 数值红线 §5.4 测族 13+ 守护(普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000)
- [x] 三系锁 §5.3 测族 5+ 守护(境界 ↔ 装备阶 ↔ 心法阶)
- [x] §5.5 在线=离线(挂机 = 实际时间)
- [x] §5.1 反留存(无每日任务 / 登录奖励 / 战令 / 抽卡 / VIP / 体力)
- [x] §6 公式集中在 `lib/core/combat/formulas.dart` + `damage_calculator.dart`
- [x] 0 硬编码(中文文案走 `data/narratives/lore/events/` · 数值走 `data/*.yaml`)
- [x] Isar schema 0.14.0 稳定(Q6B saveVersion 升档)
- [x] Riverpod 3.x 锁定(无 BLoC)
- [x] 无第三方游戏引擎(无 Flame)

## B. 系统完整性(audit v2 6 系统 · ✅ 全健康)

- [x] **战斗核心**:19 file(engine/state/log/ai/damage_calc/strategy×3)· 红线 13+ / 三系锁 5+ / 流派克制 wire 完整 · **P3.2.B 群战 wave 间 IF 恢复调优 ✅**(aliveIfRecoveryPct=0.50 修全 draw) · **P3.x 群战 UI wiring ✅**(MassBattleStrategy 接入 stage_entry_flow + 阵型选择 dialog)
- [x] **encounter**:94 测 / festival 8 全 wire · 软概率公式 `p = base × (1 + fortune/20)` 与 GDD §12.2 #6 v1.9 对齐
- [x] **闭关**:62 测 · 时辰加成 `solarTermMultiplier` wire · 12 节气 hardcode · 离线累积 idle tick
- [x] **师徒/共鸣/飞升**:49 测 · founderBuff 三维度(maxHp/crit/internal)· P5+ 多代飞升 + 真传位完整(v1.15)
- [x] **社交(sect+jianghu+pvp)**:22 文件 / 123 测 · enmity clamp / sectRank 三阶 ≠ 七阶 / ELO 数值范围 · **P4.1 1.1 sect 全闭环 ✅**(Q6A encounter recruit + Q6B stage_boss recruit + founder_buff cross_sect + polish)
- [x] **cross-system**:T20 跨系统数值红线 audit 通过 · `balance/ch4/5/6` + synergy hot loop + maxhp extremum + p3_1 light foot · **P1.2 Boss 击杀声望 wire ✅**(StageDef.factionId + factions.yaml 加载 + boss 派 -5 / rival 派各 +3)

### B 段附加(production seed 阻塞清)

- [x] **P5.0 onboarding production seed ✅**(2026-05-25 修):`OnboardingService.ensureFoundingMasters()` 幂等(信源 `isFounder=true count`)· 全新启动 Character × 3 + Equipment × 9 + Technique × 4 + 物料 50/0
- [x] **debug 入口 kDebugMode 切除**:Phase1/2 BattleTestMenu/Phase2TestMenu release build 不显
- [x] **home_feed 空 feed 引导**:「按下「直入江湖」启程」文案 wire
- [x] **Boss 招降叙事 6 篇 ✅**(2026-05-27):Ch1-3 折剑/卸刃/空手 + Ch4-6 预写 留镜/解佩/收剑 · `stage_boss_recruit_hook` 接 `NarrativeReaderScreen`
- [x] **debug 强制招募入口 ✅**(2026-05-27):`SectRecruitDebugScreen` 主菜单加「强制招募 NPC」· 跳过战斗/奇遇直走 `runSectRecruitFlow`
- [x] **Boss 招降+收降叙事全齐 12/12 ✅**(2026-05-28):战胜 6 篇(Ch1-3 折剑/卸刃/空手 + Ch4-6 留镜/解佩/收剑)+ 战败 6 篇(Ch1-3 + Ch4-6 败后叙事)
- [x] **P3.2.B 群战数值调优 ✅**(2026-05-28):`aliveIfRecoveryPct=0.50` 修 stage 03/04/05 全 draw → 37W/45W/30W
- [x] **P1.2 Boss 击杀声望 wire ✅**(2026-05-28):`StageDef.factionId` 6 主线 Boss + `_applyBossKillReputation` victory wire + R5.8 6 测
- [x] **P3.x 群战 UI wiring ✅**(2026-05-28):`MassBattleStrategy` 接入 `stage_entry_flow` + `buildEnemyTeamsPerWave` + 阵型选择 dialog + UiStrings 7 段
- [x] **P2.1 内容扩充 4 批全收 ✅**(2026-05-28):装备 35→80(+45 跨 T1-T7 全 slot)/ 心法 21→49(+28 三流派 7 阶覆盖)/ 技能 82→166(+84 招式描述全补齐)/ lore 0→80(装备典故)/ 相生 8→12(+4 传说彩蛋)
- [x] **装备 drop 全覆盖 ✅**(2026-05-28):56 条 dropTable 条目注入 26 个主线关卡 · 77 件主线装备全部有至少 1 个 dropTable 来源 · +1 覆盖率红线测试(sealed class pattern match)
- [x] **装备 icon 美术 45 张入库 ✅**(2026-05-28):MJ v7 水墨厚涂 + AutoSail Chrome 扩展批量 · 7 阶全齐(T1 6/T2 6/T3 6/T4 7/T5 7/T6 7/T7 6=45)· 全 80 件主线装备 iconPath 引用 0 缺图 · **detail 状态修正**:yaml 80/80 已填 detailPath + UI `equipment_detail_screen.dart:108` 已 wire(errorBuilder 兜底)+ 文件 35/80 ✅(原 35 件)+ 45/80 待美术 M15-16

### B 段附加(2026-05-29 外部 review 硬化 + 根因A 重平衡)

- [x] **P1-a 飞升 auto_swap 三系锁死修复 ✅**(`559455f` TDD):`performAscend` 副作用 4 auto_swap 直写 `equipped{Slot}Id` 无 canEquip → 武圣神物可装到低境界徒弟破 §5.3 · 加 `Equipment.isEquippableAtRealm` 域规则 + 上身前守卫 + R5.11 红线测 2
- [x] **P2-c 战斗公式双路径收敛 ✅**(`f719172`):`DamageCalculator.calculateResolved` 抽为唯一真相源,`DefaultGroundStrategy._calculateInBattle` 删 ~100 行重复数学 · production 与测试参考实现归一,改一处不再 drift(§6 公式集中强化)
- [x] **P2-a/P2-b 健壮性 ✅**(`62b0b7e` + `2686815`):P2-a 奇遇招式池空静默失效修(去 `isNotEmpty` 闸门 + 空池有引用 fail-fast + 红线测)/ P2-b 敌人属性 hardcode 抽 `numbers.yaml combat.enemy_defaults` + `EnemyDefaults` config
- [x] **P3 文档 drift 同步 ✅**(`1afc888`):GDD §5.6 / CLAUDE §6 / AGENTS §6 血量公式系数同步到代码真值(装备攻击 1.0 / 内力 0.5 / 根骨 400)
- [x] **A2 多代飞升循环断裂修 ✅**(`20d7273` H3 audit 唯一 🔴):`performAscend` 真传位漏写 `save.founderCharacterId=promotedDiscipleId` → gen2「祖师不在出战阵容」永久 blocked · 1 行 production 修 + 删测试 setup 暴露真闸门 + R5.6 防回退断言
- [x] **根因A 挂机循环重平衡 B1+B2+B3 ✅**(`a359dc2` spec + `d7ee3f9`):B1 闭关挂机折算 battleCount 喂共鸣度(`seclusion_battle_count_per_hour=5`)+ 默契阈值 500→300 / B2 闭关 EXP ×2.5 / B3 抽 `InsightExchangeService` 凝练领悟点→修炼度 + technique_panel「凝练领悟」入口(insightPoints 死钱包变 sink)· §5.4 红线不涉战斗数值不破
- [x] **idle_economy 经济曲线验证 ✅**(`745e5a3` test+doc only):`test/tools/idle_economy_test.dart` 量化 72h 挂机 vs 主动战斗三维成长速度 drift 雷达 · 输出 `test/tools/output/idle_economy_2026-05-29.md`
- [x] **B2 低 tier 挂机 EXP 偏慷慨修 ✅**(2026-05-29 晚 · 用户拍 B 方向):finding 纠正(主线按 clearedStageIds 解锁非境界 → 非跳内容,而是挂机优先早期战斗碾压)· 山林/古剑冢/藏经阁(学徒/三流图)experience_per_hour 回 ×1.0(原值 100/80/90)· 满挂 72h 山林 16→**12 层**(落点三流,对 Ch1 学徒差 1 阶不碾压)· erLiu+ 保 ×2.5(根因A 中期喂成长保留)· idle_economy 加 B2-c 语义回归守(学徒图满挂落点 < 二流)+ seclusion_service_test 6 测同步新值
- [x] **红线值统一 numbers.yaml ✅**(`7a1d1e7` [schema]):15000/20000 散落字面量收口到 `combat.red_lines` + `RedLinesConfig` 强类型 · wire derived_stats / stage_battle_setup.applySynergy / game_repository._enforceRedLines 4 处 · 纯抽取零行为变化 + 4 测

## C. UI 视觉验收

### C.1 基础 8 项(Pen Codex ✅ 全 PASS 2026-05-26)

- [x] 全新启动 `江湖见闻`+`直入江湖`引导(`01_fresh_launch_clean_isar.png` · 无 crash)
- [x] 主菜单全 menu 项 release build seeded(`02_main_menu_top_seeded.png` + `03_main_menu_lower_sect_visible.png` · 14+ 项 · 含「门派事务」)
- [x] 门派事务 → sect_screen 4 Tab(`04_sect_four_tabs_current_events.png` · **当前事件 / 历史记录 / 成员 / 领地** · 无名宗 等阶 1 · 声望 50/100)
- [x] sect_screen 成员 Tab(`05_sect_members_tab_clean_seed.png` · clean seed 空状态显示「尚无门派成员」无 layout 破)
- [x] sect_screen 领地 Tab(`06_sect_territories_tab_clean_seed.png` · territory cards + 占领 actions)
- [x] 主线章节屏 clean seed(`07_mainline_chapters_clean_seed.png` · 章节 lock 渲染正常)
- [x] 战斗 e2e(`08_battle_e2e_clean_seed.png` · 3v3 战斗 + 「左队胜 · 总伤害 10022 · 暴击 0 次 · 用时 7 tick」§5.4 红线守)
- [x] 战斗结束结算屏(同 08 · 「返回菜单」按钮)

### C.2 P4.1 1.1 sect recruit 验收(R2 ✅ 全 PASS 2026-05-28)

- [x] 「强制招募 NPC」按钮可见 + 候选列表 **6** NPC(05-28 池扩 valley_hermit 生效)
- [x] 二次确认对话框弹出(标题「是否招入门派?」· 按钮「招入门派」/「婉拒」· 含属性+lore)
- [x] 招募成功 SnackBar 显示(「竹影客 折服于你的剑下,入门派任 [初入] 阶」)
- [x] character_panel「门派同道: 竹影客 / 漠行客」非空成员列表 ✅

> R1(2026-05-26)3 FAIL:debug picker 不走 recruit wire / 打不赢 Boss / 非空列表未验 · 已修 commit `6e771fd` 加 `SectRecruitDebugScreen` · R2 派单 `docs/handoff/codex_dispatch_r2_sect_recruit_2026-05-27.md`

> 派单单据 + 续跑成功段 `docs/handoff/codex_visual_check_p5_p4_1_2026-05-25.md` · 8 截图归档 `docs/screenshots/p5_p4_1_visual_check_2026-05-25/` · **WARN**:1280×720 截图右边框是 Pen 桌面捕获 framing 不是 in-app bug / clean seed 成员 Tab 空状态预期非 bug · **Isar 路径修正**:派单 prompt 写 `%LOCALAPPDATA%\com.example.wuxia_idle\` 实际是 `getApplicationDocumentsDirectory() → C:\Users\Administrator\Documents\wuxia_save_slot1.isar`(下次派单沿 `isar_setup.dart` grep)

### C.3 R3 合并验收(✅ 必收 10/10 PASS 2026-05-28)

- [x] **R1 P5+ 飞升全流程**(5/5):按钮 enable / 装备选择 / 弟子下拉 / 确认 dialog / snackbar
- [x] **R2 心魔+轻功+群战+阵型**(5/5):3 Screen 入口 + 阵型选择 dialog(雁行/八卦/锋矢)+ 群战结算
- [x] **R3 Ch4-6 章节列表**(1/1):Ch4/5/6 可见 · narrative opening 因章节锁定标 LOCKED_EXPECTED
- [x] **R4 声望面板**(1/1)
- 4.2 门派持久:NOT_APPLICABLE(clean seed 无招募数据 · R2 已验证持久化)

> R3 派单 `docs/handoff/codex_dispatch_r3_consolidated_visual_check_2026-05-28.md` · 16 截图归档 `docs/handoff/r3_visual_check_screenshots/` · closeout `docs/handoff/pen_visual_verify_r3_consolidated_2026-05-28.md`

### C.4 R4 P2.1 内容扩充 + 装备 drop 验收(✅ 12/12 PASS 2026-05-28)

- [x] **R4.1 基础启动 4 项**(4/4):启动无 crash / 装备 80 件加载 / 心法面板 / 相生 chip
- [x] **R4.2 战斗+掉落 3 项**(3/3):战斗启动 stage_01_01 / 胜利掉落显示 / 装备入仓库
- [x] **R4.3 内容验收 5 项**(5/5):百科典籍 Tab / 装备典故详情 / 招式描述 / 仓库滚动 / 相生切角色不 crash
- [x] **顺手修 UI bug**:R4.3 招式描述验收暴露 `encounter_skill_section.dart` 漏渲染 `SkillDef.description` → commit `3150be8` 补 `if skill.description.trim().isNotEmpty` 守 + Text 渲染(Pen 端 flutter analyze 0 / widget+seed 测过 / build windows debug · Mac 端 character_panel 28/28 全过)

> R4 派单 `docs/handoff/codex_dispatch_r4_p2_1_content_drop_2026-05-28.md`(12/12 全收)· 12 截图 `docs/handoff/r4_visual_check_screenshots/r4_01..r4_12.png` · closeout `docs/handoff/pen_visual_verify_r4_p2_1_content_drop_2026-05-28.md`

### C.5 H1 上手修复批 视觉验收 + 主线白屏证伪(✅ 5/5 PASS 2026-05-30)

- [x] **过场绛红**(`chapter_transition` FilledButton WuxiaColors.gangMeng · 非 M3 蓝紫)
- [x] **掉落品阶仪式感**(勋章图标 + 品阶标签 + 寻常货灰 · 道具朴素列 · **神物金色掉落弹窗 2026-05-30 Pen+Codex 验证 PASS** — seedVisualCheckShenwuDrop 满配队稳胜 06_04 必掉昆仑佩,金标签 + 与宝物紫色阶清晰)
- [x] **回合术语**(battle_log/battleSummary 玩家可见「tick」→「回合」)
- [x] **凝练 0 点灰显常驻态**(technique_panel 主修凝练按钮「·暂无领悟点」灰显 · P3 seed)
- [x] **picker 关闭按钮 + 他人装备中标注**(character_panel 装备 picker)
- [x] **主线白屏 🔴 证伪消除**:clean 存档 + dirty seed 3 轮均不复现 · flutter run 日志 0 exception/RenderFlex/assertion/Navigator → 判**非真 runtime bug**,已被 overnight B6 provider invalidate 加固消除

> **§9 视觉验收全收口 ✅**(2026-05-30 Pen+Codex+Mac 多模态亲验 3/3 PASS):凝练「· 50 点」有点态(seedRefineInsight · 绛红流派色可点) + 凝练确认 dialog「全部凝练」金按钮 + 散功确认 dialog「确认散功」绛红按钮(与正向收益金区分明确)。神物金色掉落同日 PASS。截图 docs/handoff/v3_checklist_s9_2026-05-30/(8 文件)。
> 派单 closeout `docs/handoff/codex_batch3_visual_2026-05-30.md`(18 截图)+ `docs/handoff/codex_whitescreen_repro_2026-05-30.md`(12 截图/日志)· 我多模态亲验 5 关键截图 + chapterlist 正常 paint

## D. 性能稳定 + 数值再平衡(P5.2)

> 2026-05-29 数值再平衡首批落地(根因A + 红线统一 + idle_economy 验证)· 性能项 + closed beta 外部数据源留 M15-16。

- [x] **数值再平衡首批 ✅**(根因A 挂机循环重平衡 B1+B2+B3 · 红线值统一 numbers.yaml 单源 · idle_economy 72h 经济曲线验证带 drift 雷达 · **B2 低 tier 挂机 EXP 回 ×1.0**(用户拍 B · 山林满挂 16→12 层不碾压 Ch1))
- [x] **D 段主线难度曲线收尾 ✅**(2026-05-29 · balance_simulator 真 build + floor/ceiling bracket + on-level 基线诊断):**过难关清零** —— `stage_01_05` Ch1 Boss +2 阶硬墙修(erLiu→xueTu at-tier 体例 · ceiling 0%→100% · `781c85b`)+ `stage_05_05` Ch5 Boss 跨阶过苛缓(HP×0.88/atk×0.93 · ceiling 30%→76% · 守住 R5 跨阶威慑红线 · `24cea80`)· 过易 11 关诊断为章首杂兵教学关 by design 不动 · 全 6 章末 Boss ceiling 76-100% / floor 0-10% 健康
- [ ] 30-35 关全玩家路径数值再平衡终调(主线难度曲线已收尾 ✅ · 全路径终调待 closed beta 数据)
- [ ] 长时间运行 8h+ 无 crash(挂机典型场景)
- [ ] 内存增长稳定(无 leak 锚点)
- [ ] FPS 主菜单 / 战斗 / 闭关 平均 ≥ 60(Steam 用户机器最低配)
- [ ] Isar IO 无 ANR(大背包 / 多 character 场景)
- [ ] P5.4b closed beta ~10 人外部反馈(Google 表单结构化:难度评分 / 数值 bug / 流程卡点 / 通关时长)

## E. 音频(P5.3 · 留 M15-16)

- [ ] BGM 主线 / 战斗 / 闭关 3 套(水墨克制基调)
- [ ] SFX 战斗(攻击 / 命中 / 暴击 / 死亡 · 7 阶递进)
- [ ] SFX UI(按钮 / 翻页 / 反馈)
- [ ] 配音(关键剧情:师父三句遗言 / Ch4-6 主敌登场 · 至少 ~10 段)

## F. Steam 集成(P5.4 · 留 M15-16 · 1 月 buffer)

- [ ] Steam developer 账号 + 商品页提交
- [ ] 成就接入(7 阶突破 / 飞升 / 跨章 / 心魔 / 群战 / 轻功 / 师徒传承)
- [ ] 云存档(可选,Demo 同步策略)
- [ ] Steam Demo 版上架(P5.4b · 替代 itch.io 中间态)
- [ ] MSIX 打包工具链
- [ ] Sentry release 监控 + sourcemap 接入
- [ ] 评测 / 锁国问题 / 商品页本地化

## G. 法律商业(留 M15-16)

- [ ] 中国机构 ICP 备案(如发行国内 region)
- [ ] 美术 AI 出图版权声明(LoRA 自训练 · 风格独立 · 非 IP 仿冒)
- [ ] 字体授权(可商用确认)
- [ ] BGM/SFX 来源(原创 / 授权 / CC0)清单
- [ ] 隐私政策 + EULA(Steam 模板适配)

## H. 内容打磨 + UX(🎯 主聚焦 · spec 起草中 2026-05-29)

> v1.9 重定义:H 从 nice-to-have 升为「完成游戏」核心段。spec `docs/spec/h_polish_ux_spec_2026-05-29.md`。

- [x] **上手 30min 体验 audit 全闭环 ✅**(2026-05-30 · H1 批1 主菜单未解锁门控 §5.7 + 批2 装备穿戴入口修核心循环断裂 + 批3 掉落仪式感 + picker 移装标注 · Pen Codex 视觉验收 5/5 PASS)
- [x] **中期循环 2-3h audit ✅**(2026-05-29 H2 audit `h2_midgame_audit` · 两大根因:A 挂机循环脱节 + B backend 未接线 → 接线 polish 5 项 + 根因A 挂机循环重平衡全落)
- [x] **后期挑战 audit ✅**(2026-05-29 H3 audit `h3_lategame_audit` · Ch4-6 主线/心魔/群战/轻功/飞升 整体远比中期健康 · 唯一 🔴 A2 多代飞升断裂已修)
- [x] **卡点 / 秒杀点诊断 ✅**(idle_economy 量化验证 · balance_simulator 伤害公式已真路径 P2-c 后 · B2 低 tier EXP finding 已拍 B 方向修 ✅ 低 tier 回 ×1.0)
- [ ] UX 微调(空状态文案 / 错误处理 / loading 反馈 / 翻页流畅度)— H2 接线 polish 已含部分(章节翻篇过场 / 升阶大境界仪式 / effective 实战值可见 / 死字段清理)· **§9 dialog 按钮水墨分层调色 ✅**(8 金 + dispel 绛红 · 2026-05-30)· 续
- [ ] 内容文案最终 polish(typo / 古风一致性 / 主线叙事流畅度)

### H 历史 nice-to-have 残留

- [ ] 英文翻译(主线 / UI / 系统提示 · P4.2 可选 · M12 评估)
- [x] ~~1.1 挂账起步~~ → **P4.1 1.1 四项全闭环 ✅**(Q6A encounter recruit v1.12 + founder_buff cross_sect v1.13 + Q6B stage_boss recruit v1.14 + polish v1.15 · 1505 测)
- [x] ~~1.1 战败收降 + 池扩~~ → **stageBossFailRecoverProb 战败收降 wire ✅ + stage_04_05+ 池扩 ✅**(2026-05-28 过夜清理 · 败后叙事 6 篇 + Ch4-6 bossRecruit config + valley_hermit NPC)
- [ ] 1.1 剩余挂账:candidateRefs rng pick(降级 1.2)
- [ ] Pen 视觉验收发现的产品 bug 修(若 C 段验出)

## H′. 出版美术 gate(Presentation Pass · 2026-05-31 开段)

> 详细规划见 `docs/PUBLISHING_ART_PASS_1_0.md`(从系统测试版画面 → 出版级游戏画面)。本段是上线门指针,12 条发布级验收标准以该文档 §12 为准,不在此重复。

- [x] **Phase A 视觉垂直切片 ✅**(主菜单水墨山门 + 战斗屏 + 章节/角色档案化/心法面板 5 屏 Codex 多门 PASS · 同一游戏观感)
- [x] **Phase B 战斗专项 ✅**(战斗背景按 biome 接线 + scrim + Boss 头像金边 + 大招题字 overlay + 胜负仪式全屏 overlay · B1 `d8ef483` + B2)
- [x] **Phase C 系统页统一 ✅**(出版美术各屏宣纸/墨框/题字体例统一 · Border 异构经审计否决过度抽象)
- [~] **Phase D 素材补齐**(战斗背景 16 biome ✅ + 章节封面 6 章 ✅ + 剧情背景 30 图 ✅ + sect/recruit 立绘 ✅ · Boss 立绘/装备 detail 45/80 长尾留 M15-16)
- [ ] **Phase E 音频 + 最终截图包**(= 本 checklist E 段 · 合并口径不重复记 · 音频留 M15-16)
- [x] **发布级验收 12 项 → 11/12 达成 ✅**(§12:1-9+11-12 Codex 多轮 PASS · release 无 debug 走 kDebugMode 编译切除 · 唯 #10 音频最小闭环留 E 段)

## I. 1.0 已 OUT 项(留 2.0)

- 婚姻后代(GDD §12.2 · 2026-05-17 砍)
- MOD 支持(GDD §12.4 · 2026-05-17 砍)
- 角色寿命传承(GDD §12.5)
- 江湖编年史(GDD §12.5)
- 跨周目元数据(GDD §12.5)
- 多平台扩展(Mac / Linux / Switch)
- DLC / 资料片 / 持续更新

---

## 修订记录

- **v1.13**(2026-06-02)出版美术 pass 全闭环状态对齐(B1 audit 驱动 · 0 代码改动纯 doc):**头号修 doc drift** —— 出版美术整个 Phase(2026-05-31→06-02 · 战斗屏 A+B1+B2 + 剧情屏 narrative_scene + 战斗场景 16 biome 全闭环 · Codex 多门 PASS)此前 H′ 段全 [ ] 标 0% → 按真实勾(Phase A/B/C ✅ + D 部分 + 发布级验收 11/12)。**对齐**:TL;DR readiness ~98%→**~99%** + 测数 1602→**1667**(出版美术批 +65);段表 A 行 1581→1667 + 加 H′ 出版美术行(~95%);§12 上线门 12 项核对 **11/12 达成**(唯 #10 音频留 E 段 · release 无 debug 实测 `main_menu.dart:320` kDebugMode 编译切除)。**真缺口盘点**:Mac 端 ship 前硬工程窗口 `SetMinimumSize` 已实装(`3db46b2` WM_GETMINMAXINFO 锁 1280×720 · 待 Windows 实机验证),其余 ~1% 全卡外部/M15-16(D 性能 8h/FPS/Isar ANR + closed beta ~10 人 + E 音频 + F Steam + G 法律)。**verify**:HEAD `982f603` flutter analyze 0 / 1667 测实测绿(本 audit 实跑),0 代码改动。
- **v1.12**(2026-05-30)白屏证伪 + H1 上手 audit 全闭环 + §9 水墨 polish 重估:本会话 2026-05-30 三项进展纳入(均原未入 CHECKLIST)——① 主线白屏 🔴 证伪消除(clean+dirty seed 不复现 + 日志零 exception + B6 加固 → 非真 runtime bug,0 P0/P1 阻塞从乐观判断变证伪确认,**不增完成度 % 但摘风险悬顶**);② **H 段头号 [ ] 上手 30min 体验 audit 全闭环 ✅**(H1 批1 门控 §5.7 + 批2 装备穿戴入口修核心循环断裂 + 批3 掉落仪式感 + picker 移装标注 · Pen Codex 5/5 PASS)→ H 段 ~50%→**~65%**;③ §9 dialog 按钮水墨分层调色(8 金 + dispel 绛红)。**对齐**:TL;DR readiness ~97%→**~98%** + 测数 1552→**1581**(+29 · overnight 安全清理 5 批 + H1 修复批);段表 A 测数 / C 加 C.5(H1 批3 5/5 + 白屏证伪)/ H ~50%→~65%;A 段测数;C 段加 C.5 段(5/5 PASS + 3 分支待 Pen 续验);H 段上手 audit 勾 + UX 微调行加 §9 水墨。**重估关键判断**:Mac 端「ship 前必做」近见底,剩 ~2% 全卡外部/M15-16(D 性能验证 8h/FPS/Isar ANR + closed beta ~10 人 + E 音频);Mac 当下可立即推进仅剩 H 段尾巴(文案终 polish / UX 微调)+ 决策第三层 #4 清理。**verify**:HEAD `8115a13` 0 代码改动(纯 doc 状态对齐),1581 测同 HEAD 上会话 worktree subagent 实跑核验。
- **v1.11**(2026-05-29 晚)B2 低 tier 挂机 EXP finding 修(用户拍 B 方向):finding 纠正——主线按 `clearedStageIds`(打通前关)解锁,境界不 gate,挂机练级 ≠ 跳过 Ch1-2 内容,真实影响是挂机优先的玩家早期战斗碾压(学徒挂二流回头打 Ch1 差 2 阶)。修:山林/古剑冢/藏经阁(学徒/三流图)`experience_per_hour` 回 ×1.0(原值 100/80/90,撤销根因A ×2.5),山林满挂 72h 16→**12 层**(落点三流,对 Ch1 差 1 阶不碾压);erLiu+(悬崖瀑布/断崖绝壁)保 ×2.5(根因A 中期喂成长初衷保留)。`idle_economy_test` 加 B2-c 语义回归守(学徒图满挂落点境界 < 二流)+ `seclusion_service_test` 6 测同步新值(山林 4h EXP 1000→400 · 升层 6→3 层至 jingTong)。**verify**:`flutter analyze` 0 + `flutter test` 1552 pass / 1 skip。readiness ~97% 维持(D 段内 polish)。
- **v1.10**(2026-05-29 晚)D/H 首批落地状态对齐:CHECKLIST v1.9 起草后当日又落 10 批(H1-Q1 小套餐 + H2 中期 audit + H2 接线 polish 5 项 + H3 后期 audit + A2 🔴 修 + 外部 review P1-a/P2-a/b/c/P3 5 项 + 根因A 挂机循环重平衡 B1+B2+B3 + idle_economy 验证 + 红线值统一 numbers.yaml)。**对齐**:TL;DR 测数 1519→**1552**(1 skip)/ 测文件 139→**144** / readiness ~96%→**~97%** + 当日批次摘要;段表 D **0%→🔄~20%**(数值再平衡首批)/ H **0%→🔄~50%**(3 审计 + 接线 polish 5 项);A 段测数同步;B 段加附加段(外部 review 硬化 8 条);D 段重命名「性能稳定 + 数值再平衡」+ 数值再平衡首批勾;H 段中期/后期/卡点 3 审计勾 + 上手/UX/文案 续。**复核 verify**:`flutter analyze` 0 + `flutter test` 1552 pass / 1 skip(同 HEAD `fdaa2b2` 实跑核验,非照抄)。无代码改动,仅 doc 状态对齐。
- **v1.9**(2026-05-29)方向调整 + H 段升主聚焦:用户拍板「先把游戏打磨完成,再启 Steam」→ F + G 段标搁置(留 ship 前 1-2 月)+ H 段从 nice-to-have 升「内容打磨 + UX」主聚焦段(6 子项)+ E 段分拆(E1 SoundManager + E5 BGM 1 套纳入 / E3-E7 ship 前 1-2 月)+ TL;DR 优先级标注。无代码改动,仅 doc 状态对齐。
- **v1.8**(2026-05-28)C.4 R4 P2.1 内容验收 12/12 全收 + UI bug 顺手修:C 段加 C.4 R4 段(基础 4 + 战斗 3 + 内容 5 = 12/12 PASS)· R4.3 招式描述暴露 `encounter_skill_section.dart` 漏渲染 `SkillDef.description` → commit `3150be8` 补 `if skill.description.trim().isNotEmpty` 守 + Text 渲染 · TL;DR C 视觉验收行加 C.4 12/12 · 双端 verify(Pen flutter analyze 0/widget+seed/build · Mac character_panel 28/28)· release readiness ~96% 维持。
- **v1.7**(2026-05-28)detail 状态修正:asset 路径审计发现 detail wire 链路全闭环(EquipmentDef.detailPath schema ✅ + equipment_detail_screen.dart:108 UI 已 wire + errorBuilder 兜底 + yaml 80/80 已填 detailPath)· 真状态文件 35/80 ✅(原 35 件)+ 45/80 待美术 M15-16(非「0/80 留 M15-16」)。无代码改动,仅 doc 状态对齐。
- **v1.6**(2026-05-28)装备 icon 美术 45 张入库:B 段附加加装备 icon 美术全齐(MJ v7 + AutoSail 批量 · 7 阶全齐 · 80 件 iconPath 0 缺图)· TL;DR 内容总量更新加 80 件装备 icon · release readiness 95%→**~96%**。
- **v1.5**(2026-05-28)P2.1 全收 + drop 全覆盖:A 段测试数 1514→1519 · B 段附加加 P2.1 内容扩充 4 批全收(装备 80/心法 49/技能 166/lore 80/相生 12)+ 装备 drop 全覆盖(56 条 dropTable · 77 件主线装备 · +1 红线测试)· TL;DR 内容总量更新。**~95% 维持**。
- **v1.4**(2026-05-28)C 段 100% + P2.1 Batch 1:C.2 R2 全 PASS 勾完 + C.3 R3 合并验收必收 10/10 PASS(P5+ 飞升/心魔/轻功/群战+阵型/Ch4-6/声望)+ P2.1 Batch 1 装备 35→80 落地。release readiness 93% → **~95%**。
- **v1.3**(2026-05-28)P3.2.B+P1.2+P3.x 三项实装 + 1.1 挂账清理状态对齐:A 段测试数 1505→1514 · B 段战斗核心行加 P3.2.B 群战调优 + P3.x UI wiring · cross-system 行加 P1.2 Boss 声望 wire · B 段附加加 4 项(招降收降叙事 12/12 + P3.2.B + P1.2 + P3.x)· H 段 1.1 战败收降+池扩标闭环 + 剩余挂账缩至 candidateRefs(1.2)· **~93% 维持**。
- **v1.2**(2026-05-27)P4.1 1.1 全闭环状态对齐:A 段测试数 1484→1505 / 139 测文件 / Isar 0.13→0.14 · B 段 sect 社交行加 P4.1 1.1 四项闭环注 · B 段附加加 Boss 招降叙事 6 篇 + debug 强制招募入口 · C 段拆 C.1 基础(8/8 PASS 维持) + C.2 P4.1 1.1 sect recruit(R2 验收中 4 项) · H 段 1.1 挂账标闭环 + 剩余挂账明细 · Pen 仓库从 T18 拉齐到 HEAD `4bdc08d` + git remote 切 SSH · **~93% 维持**(C.2 R2 回来勾完后 C 段 100%)。
- **v1.1**(2026-05-26)Pen Codex 视觉验收 ✅ 闭环:Mac SSH 反向 tar pipe 救场 5min → Codex 续跑 PASS · 8 截图全 PASS(`docs/screenshots/p5_p4_1_visual_check_2026-05-25/01-08.png`)· C 段 8 项全勾 · release readiness 91% → **93%**(本机可验 + 视觉验收 全清零)· 剩 D-G M15-16。**Isar 路径修正记录**:实际路径 `C:\Users\Administrator\Documents\wuxia_save_slot1.isar`(`getApplicationDocumentsDirectory()` Windows fallback)非 `%LOCALAPPDATA%` · 下次派单 prompt 沿 `lib/data/isar_setup.dart` grep。
- **v1.0**(2026-05-25)起草:Mac+Opus xhigh ~25min · 上游 audit v2 doc + P5.0 onboarding 闭环 + Pen 派单准备 · 当前 ~91% release ready · 0 P0/P1 阻塞 · 剩 C 段视觉验收 + D/E/F/G 留 M15-16
