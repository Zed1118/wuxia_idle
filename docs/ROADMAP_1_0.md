# 挂机武侠 · 1.0 版本路线图

> **v1.13** · 修订日 2026-06-02 · 状态:**1.0 整体 ~99%**(出版美术 pass 全闭环〔战斗屏 A+B1+B2 + 剧情屏 narrative_scene + 战斗场景 16 biome 全覆盖〕+ §12 上线门 11/12 达成 + B1 audit 修 doc drift · **1667 测 / 1 skip / 0 analyze**)
> **v1.12** · 修订日 2026-05-31 · 状态:**1.0 整体 ~98%**(B1 敌人内力对称化已实装回填 + stage_05_05 跨阶墙 sim 复核销账 + G2 上手 banner + G4 剧情轻点 Pen 5/5 · **1602 测 / 1 skip / 0 analyze**)
> **v1.11** · 修订日 2026-05-30 · 状态:**1.0 整体 ~98%**(白屏 🔴 证伪消除 + H1 上手 audit 全闭环 + §9 水墨 polish · **1581 测 / 1 skip / 0 analyze**)
> **v1.10** · 修订日 2026-05-29 晚 · 状态:**1.0 整体 ~97%**(D/H 首批落地 · H 中期/后期/卡点 3 审计 + 接线 polish 5 项 + 外部 review 5 项硬化 + 根因A 挂机循环重平衡 + idle_economy 验证 + 红线值统一 numbers.yaml · **1552 测 / 1 skip / 0 analyze**)
> **v1.9** · 修订日 2026-05-29 · 状态:**1.0 整体 ~96%**(路径调整 · F/G 搁置 + H 升主聚焦 + D 数值再平衡推进 + 1519 测 / 0 analyze)
> **v1.8** · 修订日 2026-05-28 · 状态:**1.0 整体 ~95%**(P2.1 4 批全收 + 装备 drop 全覆盖 77 件 + 1519 测 / 0 analyze)
> **v1.7** · 修订日 2026-05-28 · 状态:**1.0 整体 ~93%**(P3.2.B 群战调优 ✅ + P1.2 Boss 声望 wire ✅ + P3.x 群战 UI wiring ✅ + 1514 测 / 0 analyze)
> **v1.6** · 修订日 2026-05-28 · 状态:**1.0 整体 ~93%**(1.1 挂账 stageBossFailRecoverProb wire ✅ + stage_04_05+ 池扩 ✅ + Codex R2 验收等明日)
> **v1.5** · 修订日 2026-05-26 · 状态:**1.0 整体 ~93%**(Pen 视觉验收 ✅ 8 截图全 PASS + P4.1 1.1 sect 子系统全 polish 4 PR 收尾 + audit v3 0 P0/P1 阻塞)
> **v1.4** · 修订日 2026-05-25 晚续 · 状态:**1.0 整体 ~91%**(P4.1 全闭环 + P5.0 onboarding production seed + audit v2 6 系统全过 + Pen 视觉验收派单 ⏳)
> **v1.3** · 修订日 2026-05-25 · 状态:**1.0 整体 ~78%**(本批 nightshift T17-T22 跑完后 · 完工率 4/6)
> **v1.2** · 修订日 2026-05-17 晚续 · 状态:**P0 阶段 4 项 100% 收口**(P0.1 #38 / P0.2 strategy 重构 / P0.3 #41 决议 + 新销账段 spec 起步段闭环)
> **v1.0** · 起草日 2026-05-17 · 状态:**已 launched(开发未启动,P0 待开工)**
> 决策来源会话:Mac + Opus 4.7,W18 起步段全收口当晚
> 路线图本身是规划文档,实际推进可能因实测调整 — 修订记录见末尾
> **配套长寿 doc**:`docs/RELEASE_CHECKLIST_1_0.md`(Steam 上线前二元勾选清单 · 与本路线图互补)
> **出版美术阶段(1.0 Presentation Pass)**:`docs/PUBLISHING_ART_PASS_1_0.md` — 把系统/内容完成版包装成可对外展示的完整游戏(主菜单+战斗屏视觉切片起步),当下主聚焦下一阶段

---

> **v1.11 变更**(2026-05-30 · 白屏证伪 + H1 上手 audit 全闭环 + §9 水墨 polish):
> - **主线白屏 🔴 证伪消除**:Codex Pen clean 存档 + dirty seed 3 轮均不复现 · flutter run 日志 0 exception/RenderFlex/assertion/Navigator · ChapterListScreen 三批未碰 → 判**非真 runtime bug**(根因脏 seed 状态已被 overnight B6 provider invalidate 加固消除)· 0 P0/P1 阻塞从乐观判断变证伪确认
> - **H 段头号 [ ] 上手 30min 体验 audit 全闭环 ✅**:H1 批1 主菜单未解锁系统门控(§5.7)+ 批2 装备穿戴入口(**修真核心循环断裂**——掉落装备此前无穿戴 UI)+ 批3 掉落仪式感 + picker 移装标注 · Pen Codex 视觉验收 **5/5 PASS**(过场绛红/掉落品阶/回合术语/凝练灰显/picker)→ H 段 ~50%→**~65%**
> - **§9 dialog 按钮水墨分层调色**:8 个收益确认→金(resultHighlight)+ dispel 散功破坏性确认→绛红(gangMeng)· Phase 0 拦下 2 误判(「设为主修」蓝紫=阴柔流派色 by design / recruitment decline 语义)
> - **测族** 1552→**1581**(+29 · overnight 安全清理 5 批 17 处硬编码→UiStrings + Batch6 14 provider invalidate + H1 修复批)· 0 analyze
> - 1.0 整体 ~97%→**~98%**(白屏摘风险悬顶不增 % · H 上手 audit 闭环 +1%)· **CHECKLIST v1.12** 同步 · **重估关键判断**:Mac 端 ship 前必做近见底,剩 ~2% 全卡外部/M15-16(D 性能 8h/FPS/Isar ANR + closed beta ~10 人 + E 音频),Mac 当下仅剩 H 文案终 polish / UX 微调 + 决策第三层 #4 清理
>
> ---
>
> **v1.10 变更**(2026-05-29 晚 · D/H 首批落地 · v1.9 起草后当日续 10 批):
> - **H 中期玩法深度 audit ✅**(`h2_midgame_audit`):两大根因 A 挂机循环与中期成长脱节 + B backend 做完前端没接线 → **H2 接线 polish 5 项**(C1 章节翻篇过场 / C2 升阶大境界仪式 / E2 effective 实战值可见 / S3 死字段清理 / R2 verified)+ **根因A 挂机循环重平衡 B1+B2+B3**(B1 闭关挂机折算 battleCount 喂共鸣度 + 默契阈值 500→300 / B2 闭关 EXP ×2.5 / B3 `InsightExchangeService` 凝练领悟点→修炼度 sink)
> - **H 后期挑战 audit ✅**(`h3_lategame_audit`):Ch4-6 主线/心魔/群战/轻功/飞升 整体远比中期健康(35 narrative 0 dangling)· 唯一 🔴 **A2 多代飞升循环断裂**(`performAscend` 真传位漏写 `founderCharacterId` → gen2 祖师不在阵容永久 blocked)已红绿修复
> - **H 卡点诊断 ✅**:`idle_economy` 量化验证 72h 挂机 vs 主动战斗三维成长 drift 雷达 · Phase 0 事实修正(伤害公式 P2-c 后已真路径,balance_simulator 残留缺口仅 `_synthPlayer` 硬编码 build)· **finding** B2 低 tier EXP 偏慷慨 → 用户拍 B 方向已修(低 tier 山林/古剑冢/藏经阁回 ×1.0,满挂 16→12 层不碾压 Ch1;erLiu+ 保 ×2.5)
> - **外部 review 5 项硬化**:P1-a 飞升 auto_swap 三系锁死修(§5.3)/ P2-c 战斗公式双路径收敛(`DamageCalculator.calculateResolved` 单一真相源,删 ~100 行重复数学)/ P2-a 奇遇招式池空静默失效修 / P2-b 敌人属性 hardcode 抽 `enemy_defaults` / P3 三文档血量公式系数 drift 同步
> - **红线值统一 numbers.yaml**:15000/20000 散落字面量收口到 `combat.red_lines` + `RedLinesConfig` 强类型 · wire 4 处 · 纯抽取零行为变化
> - **测族** 1519→**1552**(+33 · 1 skip)· 0 analyze · 同 HEAD `fdaa2b2` 实跑核验
> - 1.0 整体 ~96% → **~97%**(D 段 0%→~20% 数值再平衡首批 · H 段 0%→~50% 3 审计 + 接线 polish · 外部 review 修闭 2 个真 bug:P1-a 三系锁死违规 + A2 多代飞升断裂)· **CHECKLIST v1.10** 同步
>
> ---
>
> **v1.9 变更**(2026-05-29 · 1.0 路径方向调整 + 5h 挂机 D4 推进):
> - **用户拍板「先打磨游戏再启 Steam」** → F Steam 段 + G 法律段 **搁置 ship 前 1-2 月**(F1 注册 guide `docs/handoff/m15_f1_*` 已 ready 待启)→ 聚焦 **D 性能 + 数值再平衡** + **H 内容打磨 / UX**(从 nice-to-have 升主聚焦)+ E 部分(E1 SoundManager + E5 BGM 1 套纳入 / E3-E7 ship 前)
> - **5h 挂机方案 A 单线推 D4**:Batch A0-A5 · `tools/balance_simulator.dart` PoC + 30 关全路径 1500 跑 + 难度曲线 csv + numbers tune 候选 diff(不上线 · 起床用户拍)+ R5 测族保护 + handoff
> - **CHECKLIST v1.9** + **H spec 起草** + Q1-Q4 默认决议入档
> - 1.0 整体 ~96% 维持(本批不改完成度,只改路径优先级 · D 段 0% → ~10-15% 视 D4 PoC 实际产出)

---

> **v1.7 变更**(2026-05-28 · P3.2.B+P1.2+P3.x 三项实装):
> - **P3.2.B 群战数值调优 ✅**:`aliveIfRecoveryPct=0.50` 修 stage 03/04/05 全 draw → 37W/45W/30W(wave 间 IF 恢复)
> - **P1.2 Boss 击杀声望 wire ✅**:`StageDef.factionId` 6 主线 Boss + `_applyBossKillReputation`(boss 派 -5 / rival 派各 +3)+ R5.8 6 测
> - **P3.x 群战 UI wiring ✅**:`MassBattleStrategy` 接入 `stage_entry_flow`(massBattle 分支 + `_pickFormation` dialog + `buildEnemyTeamsPerWave`)+ UiStrings 7 段
> - **Phase 0 副产**:P3 技术债 3 项 + P1.2 B3+B4 已完成确认(ROADMAP T19 FAIL 记录过时清理)
> - **测族** 1508→1514(+6)· 0 analyze
> - 1.0 整体 **~93% 维持** · 下波:内容扩充(装备 35→80 / 心法 21→50)
>
> **v1.8 变更**(2026-05-28 · P2.1 全收 + 装备 drop 全覆盖):
> - **P2.1 内容扩充 4 批全收 ✅**:装备 35→80(+45)/ 心法 21→49(+28)/ 技能 82→166(+84 招式描述全补齐)/ lore 0→80(装备典故)/ 相生 8→12(+4 传说彩蛋)
> - **装备 drop 全覆盖 ✅**:56 条 dropTable 条目注入 26 个主线关卡 · 77 件主线装备全部有至少 1 个 dropTable 来源 · +1 覆盖率红线测试
> - **测族** 1514→1519(+5)· 0 analyze
> - 1.0 整体 **93% → ~95%** · 剩 D-G 段(性能/音频/Steam/法律)留 M15-16
>
> **v1.6 变更**(2026-05-28 · 1.1 挂账清理 Batch B+C 自主工作流):
> - **stageBossFailRecoverProb 战败收降 wire ✅**(0.30 从 0 caller → 完整 hook+wire · defeat 路径末段触发 · 共用 triggeredBossRecruitStageIds 防刷 · Ch1-3 败后叙事 3 篇)
> - **stage_04_05+ 池扩 ✅**(Ch4-6 三 Boss bossRecruit config · river_drifter/blacksmith_son/valley_hermit(新增 yinRou) · Ch4-6 败后叙事 3 篇 · sect_candidates 5→6 NPC)
> - **Boss 招降+收降叙事全齐**(战胜 6 篇 + 战败 6 篇 = 12/12)
> - **降级决策**:candidateRefs rng pick 代码注释标「1.2 升」→ 本批 spec-only 留 1.2
> - **测族** 1505→1508(+3 failRecover R5)· 0 analyze · CLAUDE.md v1.16 对齐
> - 1.0 整体 **~93% 维持** · 1.1 挂账剩 candidateRefs(1.2)
>
> **v1.5 变更**(2026-05-26 · Pen 视觉验收 ✅ + P4.1 1.1 sect 子系统全 polish 4 PR + audit v3):
> - **Pen Codex 视觉验收 ✅**(2026-05-26 续跑 8 截图全 PASS · `docs/handoff/codex_visual_check_p5_p4_1_2026-05-25.md` 续跑成功段 + 截图归档 `docs/screenshots/p5_p4_1_visual_check_2026-05-25/` · WARN:1280×720 framing / clean seed 空状态预期非 bug · Isar 路径修正 `getApplicationDocumentsDirectory()`)→ release checklist C 段 ⏳ → **C 段 100% ✅**
> - **P4.1 1.1 sect 子系统全 polish 4 PR ✅**(Mac+Opus xhigh 同会话续 cache warm 0.13-0.30× 精度):
>   - PR #13 `7d9b903` **Q6A encounter recruit**(AffectsSectMembership + SectCandidateDef 5 NPC + 3 fortuneEvent + _handleSectRecruit helper + 8 R5 测 · ~1.5-2h xhigh 精度 0.25-0.30×)
>   - PR #14 `884a989` **founder_buff cross_sect**(per-character `isBuffActiveFor` API + stage_battle_setup wire + 5 R5 测 · ~30-40min 精度 0.13-0.20× 同会话续 cache warm 新最低)
>   - PR #15 `215df8c` **Q6B stage_boss recruit**(BossRecruitConfig + saveVersion 0.14.0 + 抽 `runSectRecruitFlow` 共用 helper + 3 章末大 Boss + 8 R5 测 · ~1-1.5h 精度 0.20-0.30×)
>   - PR #16 `bcd7c93` **polish 候选 1+3**(character_panel `_SectMembershipRow` + 8 段文案扩 events+lore · ~30-45min 精度 0.20-0.25×)
> - **CLAUDE.md v1.11 → v1.15 升档 4 次**(状态对齐 · 0 规则层变化 · sect 子系统全 polish 收尾)
> - **audit v3 6 维 sweep ✅**(7 子系统 + 11 红线 + 6 三系锁 + 1.1 sect 链路 + 文档 drift + dead code · 0 P0/P1 阻塞 · stageBossFailRecoverProb 0 caller 是设计预留确认)
> - **测族**:1484 → 1505(本会话 +21 · Q6A 8 + founder_buff 5 + Q6B 8)· 0 analyze · Isar saveVersion 0.13.0 → 0.14.0
> - 1.0 整体 ~91% → **~93%**(C 段 +2% · sect polish 0 增量 polish 内已计入)· **0 P0/P1 阻塞** · 剩 D 性能 / E 音频 / F Steam / G 法律商业(全 M15-16 + 多外部依赖)
> - **1.1 挂账续**:stageBossFailRecoverProb 战败收降(P5+/1.1)/ candidateRefs rng pick / stage_04_05+ 池扩 / Boss 招降 narrative

---

> **v1.4 变更**(2026-05-25 晚续 · P4.1 全闭环 + P5.0 + audit v2 + Q6A spec):
> - **P4.1 §12.2 帮派门派 全闭环 ✅**(B1 schema + B2 service + B3 UI + B4 R5+收尾 · 4 batch squash merge 推 main · 1458 → 1476 测 / 0 analyze · ~2.75h vs spec 估 15-20h 精度 0.16×)→ P4.1 状态「spec 8%」→ 「**100% ✅**」
> - **P5.0 onboarding production seed ✅**(`OnboardingService.ensureFoundingMasters` 幂等 · 全新启动 P0-1 release 阻塞清 · 1476 → 1484 测 / 0 analyze · ~1h vs spec 估 1.7-2.0h 精度 0.5-0.67× · PR #12 squash 推 main)→ P5.0 新增段(原 P5 阶段空白)
> - **1.0 整体 audit v2 ✅**(6 跨系统复审:战斗核心 / encounter / 闭关 / 师徒共鸣飞升 / 社交 / cross-system 全健康 · 0 P0/P1 阻塞 · 137 测文件 / 1484 测 / 0 analyze)→ 揭 audit v1 误读修正(`testWidgets` 嵌套 group 实际全 wire)+ release ready 验证清零
> - **Pen Codex 视觉验收派单**(派单 prompt ready · 异步 ~60-90min · 8 必收硬证据 splash/main_menu/sect_screen 4 Tab/战斗 e2e + 能给则给)→ release checklist C 段 ⏳
> - **Q6A encounter recruit spec 起草**(P4.1 1.1 挂账起点 · `docs/spec/p4_1_q6a_encounter_recruit_spec_2026-05-25.md` 159 行 · 默认决议草案 Q1-Q8 · ~5-7h xhigh 估时)→ 1.1 启动准备
> - **`RELEASE_CHECKLIST_1_0.md` 起草**(顶层长寿 doc · 9 段 ~60 项二元勾选 · A 代码 / B 系统 / C 视觉 / D 性能 / E 音频 / F Steam / G 法律商业 / H nice-to-have / I OUT)→ Steam 上线前最终勾选锚点
> - 1.0 整体 ~78% → **~91%**(P4.1 +8% + P5.0/audit v2 +5%)· **0 P0/P1 阻塞**(本机可验全清零 · 剩 C 段视觉验收 + D-G 段 M15-16)

---

> **v1.3 变更**(2026-05-25 本批 nightshift T17-T22 跑完):
> - **完工率 4/6**:T18 narrative ✅ / T20 audit ✅ / T21 P4.1 spec ✅ / T22 总收尾 ✅ · **T17 partial**(P1.2 B1+B2 only · B3 UI/B4 R5/closeout 全缺) · **T19 FAIL**(0 commit · 技术债 3 项全未做)
> - P1.2 §12.1+§12.2 江湖恩怨+声望 schema+service 落(`4e79722` Reputation/NpcRelation Isar + numbers.yaml jianghu + factions.yaml + stages/encounters extend / `bdfee91` ReputationService + NpcRelationService + EncounterIntegration) → P1.2 状态 「spec only 15%」 → 「**B1+B2 ~50% · B3 UI/B4 R5/closeout 留下波**」
> - P3.3 PVP narrative 补 10 条(连胜/晋级/降段/月榜)+ R4 loader 测 ✅(`10711b1`)→ P3.3 narrative 状态「stub 1」→ 「完整 11」
> - P3.4 sect_event narrative 补 8 条(tournament 3 + mission 3 + crisis 2)+ R4 loader 测 ✅(同上 commit)→ P3.4 narrative 状态「2 tournament」→ 「10 全 type 覆盖」
> - **P3 技术债 3 项仍挂账**(T19 fail · 0 commit):numbers_config 强类型 PvpDef/SectEventDef / Sect/SectEvent/PvpRecord/PvpSnapshot Isar 真持久化 / systemClockProvider 全未做
> - 跨系统数值红线 audit(`ab514e1`)P2.2/P3.1/P3.2/P1.2 attackPowerMultiplier 链 + R5 6-10 测 + worst-case 验)→ R2 风险清(详 audit doc §5)
> - P4.1 §12.2 帮派门派 Phase 0 + spec 起草(`be6c224` Q1-Q8 默认决议 · ~15-20h xhigh 实装挂账)→ P4.1 状态「0% 无 spec」→ 「**spec ~8% · 待用户拍板 Q1-Q8 后实装**」
> - 1.0 整体 ~75% → **~78%**(P0/P1.1/P1.3/P2 全 + P3.1/P3.2 全 + P3.3/P3.4 narrative 全 + P1.2 ~50% + P4.1 spec 8%)
> - 详 `docs/handoff/stage_audit_1_0_overall_2026-05-25.md`(本批 milestone audit)+ `docs/handoff/6h_unattended_handoff_2026-05-25.md`(6h 挂机回报)

---

## 总览

- **目标**:Demo(2026-05-17 W18 全收口)→ 1.0 Steam 买断版一次性上线
- **总时长估算**:**16 个月**(2026-06 → 2027-09)
- **上线节奏**:一次性 1.0 Steam 上线(不发 EA)
- **美术策略**:AI 出图为主(水墨风 LoRA),UI 仍 Flutter Widget
- **范围定位**:激进派(Demo + §12 大部分 + 上线打磨全套),留 §12.5 长期愿景给 2.0

### 时间线

| 阶段 | 月份 | 核心交付 | 关键里程碑 |
|---|---|---|---|
| **P0 数值前置 + 战斗 strategy 重构** | M1-M2 | #38 base maxHp 重平衡 + battle_engine 抽 strategy 层 | 数值红线全过 + strategy e2e 全过 |
| **P1 系统纵深 + 美术 PoC + DeepSeek 产能压测** | M2-M4 | A1 师徒 E.1/E.5 / A3 共鸣度 / A4 开锋 / 节日内容 / 江湖恩怨 / 声望 + 水墨 LoRA 训练 + 装备 35 张 | M4 美术 PoC 公开(LoRA 风格定稿) + DeepSeek 流程定稿 |
| **P2 第二条主线主战场** | M5-M10(**6 月**) | §12.4 第二条主线 3 章 15-20 关 / §12.1 心魔 / A1 飞升 E.2/E.3 + 遗物 transfer / 文案 +6-10k 字 / 装备 35→80 / 心法 21→50 / 典故 80→160 | M10 主线全跑通(一流→武圣) |
| **P3 战斗形态扩展** | M10-M12 | §12.3 轻功对决 / 群战守城 / Supabase PVP / 门派事件 | M12 战斗形态 3 种全交付 |
| **P4 社交收尾** | M12-M14 | §12.2 帮派门派 / 翻译(可选英文) | M14 全系统收口 |
| **P5 上线收尾** | M15-M16 | C1 教程 / C2 难度曲线 / C4 音乐音效配音 / C5 Steam 集成 / C6 时长校准 / Steam 上线 | M16 Steam 1.0 上线 |

### 关键决策记录(2026-05-17 用户拍板)

| 决策 | 选项 | 备注 |
|---|---|---|
| 1.0 范围定位 | 激进派(雄心版) | A + C + §12 大部分,留 §12.5 给 2.0 |
| 优先级偏好 | 三者并行,按依赖排 | 不设 上线/纵深/广度 单一优先 |
| 美术策略 | AI 出图(水墨风 LoRA) | M4 PoC 硬门槛 |
| 上线节奏 | 一次性 1.0 上线 | 不发 EA |
| 第二条主线工期 | 放宽到 5-6 月 | 从原 4 月 |
| §12 砍项 | 婚姻后代 + MOD 支持 | 全放 2.0 |
| Phase 5 第 7 批战斗 strategy | 插 P0 | 先付重构债再建战斗形态 |
| itch.io 中间发布砍 | 不走 itch.io | 2026-05-17 v1.1 决议:聚焦游戏本身,R6 对策改 P5.4b closed beta + Google 表单 + Steam Demo 版 |

---

## P0 数值前置 + 战斗 strategy 重构(M1-M2)

### P0.1 #38 base maxHp 重平衡
- **估时**:opus xhigh ~8-15h(完整 numbers.yaml + equipment.yaml 7 阶 × 装备 + 属性 + 内力维度全审)
- **产物**:
  - base maxHp ≤ 16667(让 hpPct 0.20 仍 ≤ §5.4 红线 20000)
  - 全维度数值压测(wushen + 满 attr + 神物装备 + 心法相生 cap 兜底)
  - 红线测试加 P0 压测 case(7 阶 × 3 流派 × 心法相生 5 组合矩阵)
- **前置依赖**:无(P0 起手)
- **阻塞影响**:P2 第二条主线扩到武圣体验路径全依赖此

### P0.2 battle_engine 抽 strategy 层 — **✅ 2026-05-17 销账**(v1.2)
- **实测**:Mac + Opus 4.7 xhigh ~2h(vs 预估 6-12h 快 3-5×,Batch 1+2 同会话续跑)
- **产物**(详 `docs/handoff/p0_battle_strategy_closeout_2026-05-17.md`):
  - `BattleStrategy` 抽象基类(3 method 粗粒度)+ `DefaultGroundStrategy`(地面 3v3 实装,11 method 搬迁公式零变化)
  - `BattleEngine` 改 facade(467 → 50 行)委派 const DefaultGroundStrategy()
  - `BattleNotifier` 接 strategy injection(_strategy instance field + startBattle 可选参数)
  - e2e 红线压测 `test/balance/battle_strategy_e2e_test.dart` 333 行 55 case(主线 15 + 爬塔 30 + 心法相生 5 + backwards compat 5,单文件 ~3s 全过)
- **commit 链(4 commit 全 push)**:`6748582` [arch] Phase 1 → `456349b` [refactor] Phase 2 → `14d62b1` [refactor] Phase 3 → `68a6365` [test] Phase 4
- **校正记录**:闭关地图实测 0 战斗(spec §2.4 reality check 修正原 R4 prompt "5 闭关地图战斗"误解)
- **阻塞解除**:P3 §12.3 三战斗形态(轻功 / 群战 / PVP)扩展时 implements BattleStrategy + startBattle 传自定义实装即可 plug-in,生产 4 callsite 不必改

> **P0.3 itch.io Demo 公开免费版** — **2026-05-17 v1.1 砍**(方案 C 决议):聚焦游戏本身,MSIX + itch.io + Sentry + Google 表单 5 项全推 P5.4b closed beta + Steam Demo 版。

---

## P1 系统纵深 + 美术 PoC + DeepSeek 产能压测(M2-M4)

### P1.1 A 类系统纵深
- A1 师徒系统真实化(E.1 收徒弹窗 / E.5 founder_ancestor_buff sect buff,sonnet 各 1-3h)
- A3 共鸣度满级体验完整化(joint_skill 表现层 / banner 时机 / 拆分提示,sonnet 2-4h)
- A4 开锋 3 槽 build 内容扩(审计每件装备开锋方案,sonnet 2h)

### P1.2 §12 独立模块组(与主线解耦)
- §12.4 节日活动:W16/W17 框架已建,补内容(DeepSeek 12 节日文案,~2 周)
- §12.1 江湖恩怨:NPC 关系网独立模块,数据 schema 设计 + Isar 持久化 + 触发条件(opus xhigh ~6-8h)
- §12.2 声望:独立累积值模块(行侠 / 行恶累积,影响 NPC 反应 / 剧情分支,opus high ~4-6h)

### P1.3 美术 PoC + LoRA 训练
- 水墨风 LoRA 训练(Stable Diffusion / Midjourney,~1 月,可与系统开发并行)
- 装备 35 张图首批出图(对照 Demo 现有 35 件)
- **M4 硬门槛**:风格统一度 / 上手识别度 / 数量节奏(35/80 装备)
- **失败分支**:M4 PoC fail → 触发外包 / 极简几何 决策

### P1.4 DeepSeek 产能压测
- Demo 期 DeepSeek 文案产能基线测算(3-5k 字 / ~3 周)
- 1.0 文案量 ~2x,需流程优化(批量派单模板 / 文案审计自动化)
- M4 末出 DeepSeek 产能优化文档 + 流程定稿

---

## P2 第二条主线主战场(M5-M10,6 月)

### P2.1 §12.4 第二条主线 3 章
- 主线 15-20 关(一流→绝顶→宗师→武圣,玩家境界路径) — **拟升档 25-30 关上限**(Ch4 已落 + Ch5/Ch6 spec 起草前正式拍板,GDD §8.4 Demo 表保持不动)
- DeepSeek 文案 +6-10k 字 — **Mac+Opus 单端文案产线(v1.8 CLAUDE.md 起 DeepSeek 退役)**
- 装备扩 35→80(每阶 5-7 件 → 全 7 阶 80 件)
- 心法扩 21→50(全 7 阶 × 3 流派,每阶 ~7 心法)
- 典故扩 80→160(每装备 2 段 anecdote → 7 阶 80 件 × 2 段)

**※ Ch4「西出阳关」P1 启动**(2026-05-21 桥头堡 ✅):yiLiu 全章 + 跨 jueDing·qiMeng 末 Boss(西凉霸主三人组 · 沉默克敌出手即决型 + 留 hook Ch5/Ch6 西凉小铜镜遗物)+ 西北边塞地理(玉门关 / 河西走廊 / 大漠 / 嘉峪关)+ ~5,880 字 narrative(10 段 stage v1 + 1 段 stage_04_04_defeat v1 + 1 段 stage_04_05_defeat v1)+ ~1,420 字 chapter_04 章首尾 v1。本批 ~50% P2.1 字数预算(预算 +6-10k 字 / Ch4 落 ~5,880,留 Ch5/Ch6 各 ~3,000)。详 spec `docs/handoff/p1_x_chapter4_spec_2026-05-21.md` + closeout `docs/handoff/p1_x_chapter4_phase2_batch1_closeout_2026-05-21.md`。

**※ Ch5「征东」P2 启动**(2026-05-22 第二条主线第 2 章 ✅):jueDing 全章(qiMeng→dengFeng)+ 跨 zongShi·qiMeng 末 Boss(C 复合三人组 西凉霸主三弟子 + 中州论剑顶 + 嵩山道宗 · 师承玉佩 hook Ch6)+ 中原东归地理(嘉峪关→灞桥→潼关→渭水→嵩山→黄河→嵩山论剑场)+ Tier jueDing「沉静 / 从容 / 通达 / 入微」+ 师父遗言 3 处贯穿 + 物理遗物 hook 5 处闭环(小铜镜回取兑现 + 玉佩出场兑现)+ ~6,638 字 narrative(13 文件:chapter + 10 stage opening/victory + 2 defeat,对照 Ch4 ~5,880 ✅)。本批累计 P2.1 字数 Ch4 5,880 + Ch5 6,638 ≈ 12,518(预算 +6-10k → 已达上限,Ch6 预期 ~5,000 字续作时按比例校准)。详 spec `docs/handoff/p2_x_chapter5_spec_2026-05-22.md` + closeout `p2_x_chapter5_phase2_full_closeout_2026-05-22.md`。

**※ Ch6「飞升」P2 全收口**(2026-05-22 第二条主线第 3 章 ✅ · **1.0 P2 第二条主线全闭环**):zongShi 全章(qiMeng→dengFeng)+ 跨 wuSheng·qiMeng 末 Boss(**B 复合 = 西凉霸主本人首次开口 + 2 副 zongShi·dengFeng 西凉三弟子** · Ch4 小铜镜 + Ch5 玉佩三章 hook 全闭环 + **无物之境收束**承 Ch5 玉佩兑现不留任何物理遗物)+ 中原西渐地理(中州论剑场散场 → 嵩山再访 → 黄河之源 → 昆仑山外 → 昆仑山顶飞升前夜)+ Tier zongShi「澄澈 / 无为 / 玄妙 / 化境」+ **师父第三句遗言完整联通**(prologue 半解 + stage_06_05_victory 全联通 + epilogue 三句话第一次完整连成一句)+ ~5,800 字 narrative(13 文件:chapter + 10 stage opening/victory + 2 defeat)。本批累计 P2.1 字数 Ch4 5,880 + Ch5 6,638 + Ch6 5,800 ≈ 18,318(预算 +6-10k 字 → 实测超 ~83%,质感优先 acceptable)。详 spec `docs/handoff/p2_x_chapter6_spec_2026-05-22.md` + closeout `p2_x_chapter6_phase2_full_closeout_2026-05-22.md`。

### P2.2 §12.1 心魔系统
- 高境界突破前心魔关卡(剧情化的内心战斗)
- 前置依赖:第二条主线推进到关键境界(绝顶 / 宗师)
- 数值平衡:心魔不应破 P0 数值红线

**※ P2.2 §12.1 心魔系统 Batch 2.1-2.5 全收尾 ✅**(2026-05-23 · 1.0 P2.2 子阶段最终收尾):

**Batch 2.5 增量**(`308bf52` + `b15d34d`):① **Batch 2.5.A R5 跨阶红线压测**(3 测 e2e:R5.1 7 关 × 50 种子双边断言 leftWins+draws ≥ rightWins 克己语义 / R5.2 e2e mirror cap §5.4 红线 verify / R5.3 渐进通关 unlock 链 e2e qiMeng→dengFeng 6 步)+ R5.1 实测分布全 **3/0/47**(玩家 leftWin 6% / rightWin 0% / draws 94%);② **Batch 2.5.B UI reactive 三态**(InnerDemonScreen `mainlineProgressProvider` + `clearedStageIds` + `unlockTriggers` reverse 链查 → cleared/available/locked 三态 + main_menu _MenuButton 入口 Tower 后 Leaderboard 前 + UiStrings 加 mainMenuInnerDemon/Hint + main_menu_test 12 按钮适配);③ **Batch 2.5.C inner_demon_07 双镜像决议**(R5.1 数据印证 `_07 +20%` 同 `_06 +20%` 完全同分布,改 `_07 +20% → +40%` 单副本 YAGNI 不动 BattleState 6v3 架构);④ **Batch 2.5.C cap 维度纠正**(`mirror_caps.attack_power_max 2000 → 6000` = 3 × §5.4 单件 2000;原 2000 锚错 §5.4 维度让镜像 attack 永远低于玩家 ~2850);⑤ **挂账 1.0 P3+**(BreakthroughBlocker 集成 character_panel 1257 行 + inner_demon 战斗机制层调优 + 7 主题 enemy 立绘异步);⑥ **1217 → 1220 pass / 0 analyze ✅**(+R5.1/R5.2/R5.3 3 测)。详 final closeout `docs/handoff/p2_x_inner_demon_final_closeout_2026-05-23.md`。

---

**Batch 2.1-2.4 原段**(2026-05-22 夜 ✅):7 关 `stage_inner_demon_01..07` 拦截 wuSheng 7 层突破(qiMeng → ruMen → shuLian → jingTong → yuanShu → huaJing → dengFeng → 飞升前置)+ **镜像战斗**(`InnerDemonService.buildMirrorEnemyTeam` 深拷贝 playerTeam BattleCharacter list ×(1+mirror_buff 0.10→0.20)clamp §5.4 cap 20k/15k/2k · StageBattleSetup.buildTeams innerDemon 分支)+ **unlock 拦截 hook**(`isLayerLocked` 接 advancement_service.applyExperience · EXP 留账 §5.1 · 3 callers seclusion/tower/mainline wire production hook 真生效)+ **失败惩罚**(散功 ×0.5 阉割版:内力 ×0.85 / 主修修炼度 ×0.9 + 「心魔余毒」debuff 闭关 8h 清 · 数值落 numbers.yaml `inner_demon` 段 46 行)+ **narrative ~3,900 字**(chapter ~720 + 7 opening ~280×7 + 7 victory ~150×7 + 7 defeat ~210×7 · Tier wuSheng 风格梯度词「湛然/寂照/圆融/化机」+ 7 主题 贪/嗔/痴/慢/疑/空/真 · 第二人称「你」(stage)+ 第三人称「李寒」(chapter)· 不破师父三句已完整 + 不再现物理遗物)+ **UI 占位**(InnerDemonScreen ConsumerWidget · InnerDemonBreakthroughBlocker StatelessWidget · 集成 character_panel/main_menu 路由留 Batch 2.5+)+ **测试 25 个**(R1 14 hook unit/integration + R2-R3 7 buildMirrorEnemyTeam 数值/slot/§5.4 cap + R4 4 narrative loader)+ **1217 pass / 0 analyze ✅**。**7 commit `e666e4c → a0cbb29` 全 push origin/main**(Phase 0 reality check + Phase 1 spec 148 行 + Batch 2.1 schema + Batch 2.2.A vertical slice + Batch 2.2.B 镜像战斗 + Batch 2.3 narrative + UI + 2 PROGRESS sync)。**spec 估 ~7-8h opus xhigh · 实际 ~4h · 精度 0.5×**(技术 + narrative 混合 batch 整体快于估)。**调整记录**:InnerDemonStrategy implements BattleStrategy 不建(YAGNI)+ inner_demon_07 双镜像单副本 +20% 占位(真双镜像 6v3/连战 留 Batch 2.5 R5)+ chapter_inner_demon 运行时不 load(纯叙事 doc)+ UI widget reactive 集成路由留 Batch 2.5+。**数值红线 §5.4/§5.3/§6 公式完全不动** + **Ch1-Ch6 主线 + Demo 49 层 EXP 自动升层路径完全不变**(`isLayerLocked` 严格 wuSheng 短路 + qiMeng 跨 tier 起步层放行)。详 spec `docs/handoff/p2_x_inner_demon_spec_2026-05-22.md` + Phase 1 closeout `p2_x_inner_demon_phase1_closeout_2026-05-22.md`。Batch 2.5 R5 跨阶红线压测 + UI reactive 集成 + inner_demon_07 双镜像决议另起。

### P2.3 §7.1 飞升 + 遗物 transfer

**2026-05-24 P2.3 Batch 3.1-3.3 全闭环 ✅**(主 cwd · 4 commit `eaa3e00 → 本` 推 main · 1283 pass / 1 skip / 0 analyze · 实测 ~2h30min opus xhigh · spec 估 ~4h · 精度 0.63×):
- **方向 B + Q1a/Q2c/Q3b/Q4d 拍板**:Q1a `isFounder=true + isActive=false` 出阵复用现字段不加 isAscended / Q2c lineageRole 不真切传位 P5+ 再切语义 / Q3b 玩家手动选 1-2 件 player_pick 真消费 / Q4d 3 条件并存(`stage_inner_demon_07 cleared + wuSheng·dengFeng + stage_06_05 cleared`)
- **Batch 3.1 schema + Service**(~50min):`data/numbers.yaml` 末加 `ascension.unlock_triggers` 段 + `NumbersConfig` 扩 `HeritageItems`(6 字段消费 v1.5 决议 4 规则字段 transfer_trigger/multi_disciple_allocation/stack_across_generations/conflict_slot_resolution + 2 数量字段)+ `AscensionConfig` 解析 unlock_triggers · `AscendService` 4 method(`computeEligibility` 5 子条件 + missingReasons / `listHeritageCandidates(founderId)` / `listDiscipleTargets` / `performAscend(selections)` caller 持锁 writeTxn)+ 4 Riverpod providers
- **Batch 3.2 UI**(~55min):`AscensionScreen` 三段式 ConsumerStatefulWidget 401 行(仪式横幅 + 装备多选 1-2 件 + DropdownButton 改 disciple + 确认 dialog → performAscend → snackbar)+ `LineagePanelScreen` 末加 `_AscensionSection`(eligibility 5 子条件聚合 → 「步入飞升」按钮 enable/disable + tooltip 显 missingReasons)+ UiStrings 15 段
- **Batch 3.3 R5 + closeout**(~30min):R5.1-5.5 5 族 14 测(e2e 1 + eligibility 5 + player_pick 3 + 边界 4 + §5.4 红线 1)+ closeout 65 行 + GDD v1.14 + CLAUDE.md §12.2 #10 「P2.3 已实装 ✅」+ 本段 + PROGRESS 顶段
- **生产 bug 顺手修**:`Equipment.inheritFrom` 从 Isar 读取实例的 `previousOwnerCharacterIds: List<int>` 是 fixed-length,`.add()` 抛 `Cannot add to a fixed-length list`,改 reassign `[...old, new]`(memory `feedback_isar_pitfalls`)
- **founder_buff_service 0 代码改**:飞升后 founder isActive=false 自然让 `computeBuffActive` 返 false · 无需扩 trigger
- **挂账留下批**:~~narrative ~600 字~~ ✅ 已 ship(P2.3 narrative 4 yaml commit `8a4b7bd` · `ascension_intro/pick_hint/disciple_thank/complete`)+ ~~P5+ 多代飞升~~ ✅ 已 ship + ~~P5+ 真传位~~ ✅ 已 ship(P5+ ④+⑤ 合并 batch 见下段)
- **数值红线 §5.4/§5.3/§5.5/§6 公式完全不动** · Character/Equipment Isar schema 0 改 · BattleStrategy 接口不动 · 1.0 P2 主线 3 子阶段(P2.1+P2.2 心魔+P2.3 飞升)全闭环 → **1.0 P2 ~87%**
- 详 `docs/handoff/p2_3_ascension_closeout_2026-05-24.md` + `docs/spec/p2_3_ascension_spec_2026-05-24.md`

**2026-05-24 P5+ ④+⑤ 多代飞升 + 真传位完整实装 ✅**(主 cwd · 4 commit `1e875d6 → 1b1bb86` 推 main · 1291 pass / 0 analyze · 实测 ~2h30min opus xhigh · spec 估 ~5-7h · 精度 0.42×):
- **合并方案**:Phase 0 发现 ④ 单独做没真多代场景可测(需 ⑤ 真传位 founder promotion 当前置)→ ④⑤ 合批
- **Service**(`a1d17ea`):`performAscend` 加 `promotedDiscipleId: int?` + 副作用 4 auto_swap 真消费(disciple equipped{Slot}Id 接新遗物 · 旧装 owner 不变入背包语义)+ 副作用 7 promoted 接管(promotedDisciple.isFounder=true · founder.isFounder 保 true 太祖语义 · founder_buff_service 0 改自然接管)
- **UI**(`15fc187`):AscensionScreen 加 `_PromotedDiscipleRow` 下拉(player_pick 体例)+ UiStrings 4 段
- **R5 测族 14→18**(`1b1bb86`):R5.6 多代 e2e 2 + R5.7 auto_swap 2 + R5.8 stack enforce 1 · R5.1-5.5 原 14 测全过(向后兼容验证 ✅)
- **0 schema 改 · 0 公式改 · founder_buff_service 0 代码改**(P2.3 留好的 isFounder+isActive 两轴语义自然承载传位)· GDD §12.2 #10 v1.15 + CLAUDE.md v1.10
- 详 `docs/handoff/p5_lineage_full_closeout_2026-05-24.md` + `docs/spec/p5_lineage_full_spec_2026-05-24.md`

**2026-05-24 凌晨 P5+ UI polish 续作 + 8h overnight v2 全流 ABCDEFGHI 完结 ✅**(主 cwd · 9 commit `154211b → e2dae9a` 推 main · 1299 pass / 0 analyze · Mac+Opus high 累计 ~2h):
- **A 批 P5+ UI polish 4 项实装**(`154211b → 4229a12` · 3 commit):listDiscipleTargets isFounder 过滤防循环传位 + R5.9 / 双 UI 多代 chip(character_panel + LineagePanel)/ AscensionScreen dialog/snackbar 含接任弟子名
- **B 批派单 spec**(`ad145ee`):Codex 14 验收点(P5+ + P3.1 + P3.2 + Ch4-6 + inner_demon)+ MJ 10 张 prompt ready-to-paste(Ch4-6 主敌 3 + inner_demon 7 主题 1 each · v6 模板)
- **C 批 stage_audit**(`7be8798`):全加权 ~67-70% / 主轴战斗+主线 ~90%(P2/P3 全闭环 + P5+ 飞升前置 ~30%)
- **D 批 P1.2 江湖恩怨 + 声望 Phase 0**(`a5843d2`):6 维全 greenfield ✅ · Q1-Q5 候选清单留用户起床拍板
- **E 批起床 handoff**(`f7ced04`):3 类自主决策 + 6 项 first-read + memory sink 2 项追加
- **F+G 批 narrative + widget test 双 UI 覆盖 + ROADMAP 对齐**(`504dff3` + `63c7e07`):`ascension_lineage_chant.yaml` ~200 字 Tier wuSheng 4 风格梯度 + 多代 chip widget test 4 个 + ROADMAP P2.3 段对齐 P5+ 全实装
- **H 批 narrative UI 接入 + VC-P5+ fixture seed**(`f70f990`):`AscendService.isLineageContinuation()` + R5.10 2 测(测族 20→22)+ Phase2TestMenu VC-P5+ 按钮 + `seedVisualCheckP5Plus`(B.1 派单 fixture self-check 唯一未就绪 → ✅)
- **I 批终验**(`e2dae9a`):全仓 1299 pass 终跑 + PROGRESS 100 行卡上限 + handoff TL;DR + 派单 spec fixture self-check 全 ✅ + phase2_test_menu_test 13→14 修
- **8h overnight v2 实测**:9 批 ~2h opus high · 6 doc 全 ≤上限(audit 72→60 / phase0 98→41 两次主动砍)· code +200 行 / +6 测 / narrative 1 / memory 2
- 详 `docs/handoff/p5_ui_polish_closeout_2026-05-24.md` + `docs/handoff/8h_autonomous_handoff_2026-05-24.md`

---

## P3 战斗形态扩展(M10-M12)

### P3.1 §12.3 轻功对决
- 水面 / 屋脊 / 竹林特殊战斗形态
- BattleStrategy 抽象层挂 `LightFootStrategy`
- 数据:特殊地图 yaml + 轻功招式 yaml

**2026-05-23 P3.1 Batch 2.1-2.4 全收尾 ✅**(8h overnight worktree `feat/p3_1_lightfoot`,8 commit `be7248a → 本`,1238 pass / 0 analyze):
- **战斗形态全闭环**:`LightFootStrategy` 组合委派 `DefaultGroundStrategy`(零代码重复 + immutable · runToEnd 入口 `applyTerrainTo` bake terrain modifier 烘焙到 BattleCharacter critRate/evasionRate/defenseRate · clamp [0.0, 0.95] 防 §5.4/§5.5 红线破)+ `TerrainBiome` 独立 enum 3 项(water/rooftop/bamboo,与 EncounterBiome 解耦)
- **5 关 + 数据 schema**:`stage_light_foot_01..05` yiLiu(qiMeng/jingTong/dengFeng) + jueDing(qiMeng/jingTong)2 Tier × 3 terrain + diff 5.0-6.5 + enemyTeam[3] menpai/jianghu skill 体例 + `numbers.yaml light_foot` 段 45 行(3 terrain × 4 modifier + stage_terrain + unlock_triggers)+ `StageDef.terrainBiome` 字段
- **narrative ~2.1k 字**:`chapter_light_foot` 章首尾(无名轻身术 5 处试炼)+ 10 stage opening/victory(Tier yiLiu「沉着/肃杀/老练」 + jueDing「沉静/从容」风格梯度词 · 五处试炼:踏波 / 追风 / 听风 / 飞渡 / 长风)
- **UI 入口 + reactive 三态**:`LightFootScreen`(cleared/available/locked)+ `LightFootService.statusOf` + main_menu 入口 Tower → InnerDemon → **LightFoot** → Leaderboard
- **平行支线**:不接管 wuSheng 突破链(`isLayerLocked` 无 lightFoot 路径)· unlock 链 `stage_06_05 → light_foot_01..05`
- **R5 跨地形红线 3 测**:R5.1 5 关 × 50 种子分布 50/50/46/50/50 leftWins(平行支线主导 · 与心魔克己 3/0/47 对称)+ R5.2 clamp + §5.4 红线 + R5.3 unlock 链
- 详 `docs/handoff/p3_1_lightfoot_closeout_2026-05-23.md` + `docs/spec/p3_1_lightfoot_spec_2026-05-23.md` + `docs/phase0/p3_1_lightfoot_phase0_2026-05-23.md`

**2026-05-24 P3.1.B 子批全收尾 ✅**(branch `feat/p3_1_b` 主 cwd · 3 commit `31bb7bf` + `ff2a0be` + 本 · 1242 pass / 0 analyze · 实测 ~1h opus high · spec 估 ~1.5h · 精度 0.67×):
- **Batch A · damage_multiplier 接入 attackPowerMultiplier**:`BattleCharacter` +`attackPowerMultiplier:double` default=1.0 + copyWith + `default_ground_strategy._calculateInBattle` raw 末乘 atkPowerMult + breakdown(沿 cult/school/crit/def/realm 体例,独立维度乘项不进 base 求和)+ `LightFootStrategy._bake` 烘焙 `terrain.damageMultiplier` 到 attackPowerMultiplier(双方对等)+ R6 4 测(water 1.0 / rooftop 1.15 / bamboo 0.90 / 双方对等)
- **Batch B · 轻功专属 skill 池 18 招 + stages 切换**:`skills.yaml +18` 招 lightfoot pool(`skill_lightfoot_<tier>_<school>_<type>` · yiLiu 9 招 cap=3000 menpai 倍率 + jueDing 9 招 cap=4000 jianghu 倍率 · parentTechniqueDefId: null 沿 joint_skill 体例)+ `stage_light_foot_01..05` enemyTeam.skillIds 全切到新池(sed 35 次替换)+ baseline 104→122
- **架构发现**:`DamageCalculator` 用 `Character`(Isar 实体)是 phase1 公式参考,不参与战斗;实际战斗走 `DefaultGroundStrategy._calculateInBattle` 用 `BattleCharacter` · attackPowerMultiplier 加在 BattleCharacter 上接入正确路径
- **R5.1 实测分布**:50/50/49/50/50 leftWins(bamboo stage_03 draws 4→1 · ×0.90 双方等比 → 玩家击杀更稳定,主导格局未变)
- **挂账留 1.0 P3.2+**:Pen Windows 视觉验收(Codex 异步 ~1h · 非阻塞)

### P3.2 §12.3 群战守城
- 5v5 或更大规模特殊关卡
- BattleStrategy 抽象层挂 `MassBattleStrategy`
- AI 行为:多角色协作(P0 strategy 层可能需要扩展协作接口)

**2026-05-24 P3.2 Batch 2.1-2.5 全收尾 ✅**(worktree `feat/p3_2_mass_battle` · 5 commit `ae97f83 → 本` · 1268 pass / 0 analyze · Mac+Opus xhigh 累计 ~2h · spec 估 ~6-7h · 精度 0.30×):
- **战斗形态全闭环**:`MassBattleStrategy` 组合委派 `DefaultGroundStrategy`(沿 LightFoot 体例零代码重复 + immutable · runToEnd 入口 `applyFormationTo` 烘焙仅 leftTeam · wave 循环 + `_intermission` actionPoint+cd reset / HP+IF preserve)+ `Formation` enum 3 项(yanXing/baGua/fengShi 雁行/八卦/锋矢)
- **5 关 + 数据 schema**:`stage_mass_battle_01..05` yiLiu(qiMeng/jingTong/dengFeng) + jueDing(qiMeng/jingTong)2 Tier · wave 2-4 / enemy 5-7「以少胜多」· diff 6.5-8.5 + enemyTeam[3] 模板沿 LightFoot skill 池 18 招(零新增 skill)+ `numbers.yaml mass_battle` 段 50 行(3 formations × 4 字段 + wave_intermission 4 + stage_formations 5 + unlock_triggers 5)+ `StageDef.massBattleWaveCount/EnemyCounts` 字段
- **narrative ~2.2k 字**:`chapter_mass_battle` 章首尾(无名守城术 5 处试炼 · 不躁/不乱/不溃/不让/不忧)+ 10 stage opening/victory(Tier yiLiu「沉着/肃杀/老练」 + jueDing「沉静/从容」风格梯度词 · 五处试炼:守村/守镇/守县/守关/守城)
- **UI 入口 + reactive 三态**:`MassBattleScreen`(cleared/available/locked + 显「N 波 · M 敌 · 阵型 · 难度」紧凑信息)+ `MassBattleService.statusOf/orderedStageIds/formationFor` + main_menu 入口 LightFoot → **MassBattle** → Leaderboard(13→14 按钮)
- **平行支线**:不接管 wuSheng 突破链(`isLayerLocked` 无 massBattle 路径)· unlock 链 `stage_06_05 → mass_battle_01..05`
- **R5/R6 跨关红线 4 测**:R5.1 5 关 × 50 种子 leftWins+draws ≥ rightWins(rightWins=0 全过 · stage_03/04/05 全 draws 数值平衡挂账 P3.2.B)+ R5.2 formation cap clamp + §5.4 红线 + **仅 leftTeam 关键差异**(vs LightFoot 双方对等)+ R5.3 unlock 链 e2e + R5.4 wave 间 preserve/reset e2e · R6 烘焙 7 + wave 4 共 11 单测(沿 LightFoot 体例)
- **架构决议**(spec §3 漏的设计风险点 · Batch 2.5 拍板方案 (C)):`MassBattleStrategy.runToEnd` 一次性跑完 wave 循环(strategy 保持 immutable)· R5 红线测**直接调 runToEnd 不走 UI**(UI tick by tick 战斗 wiring 留 Batch 3.x 独立设计 BattleScreen 兼容批量结果 + wave 切换动画 + N 槽 UI · 当前 stage_entry_flow 无 massBattle 分支 → 点击进战斗走 fallback DefaultGround 单场 3v3 头 3 敌 · 不 crash 但非真守城体验)
- **挂账 P3.2.B 数值调优**:stage_03/04/05 R5.1 全 draws(玩家强 build 也守不下 26 敌 · 累计内力耗尽 · 解法候选:wave 间 HP 部分回血 / 敌方后波数值递减 / maxTicks 放宽)
- **挂账 P3.x UI 战斗 wiring**:阵型选择 dialog + buildWavesFor 公开 + stage_entry_flow massBattle 分支 + BattleScreen 多槽 UI / wave 切换动画
- 详 `docs/handoff/p3_2_mass_battle_closeout_2026-05-24.md` + `docs/spec/p3_2_mass_battle_spec_2026-05-24.md` + `docs/phase0/p3_2_mass_battle_phase0_2026-05-24.md`

### P3.3 §12.3 PVP(Supabase 异步)
- 排行榜模块已落(Demo 期),扩 PVP
- 异步:玩家阵容快照上传 → 其他玩家挑战
- BattleStrategy 抽象层挂 `PvpStrategy`(可能与 Default 共享 75%)

### P3.4 §12.1 门派事件
- 地图上动态出现的门派冲突 / 武林大会 / 寻宝事件
- 与 §12.2 声望联动(P1 已建立)

---

## P4 社交收尾(M12-M14)

### P4.1 §12.2 帮派门派
- 玩家创建门派可招收弟子 / 占领山头
- 与师徒系统 A1 升级链联动(P2 已实装飞升)
- 跨多个 service:`SectMemberService` / `TerritoryService` / `AscendService` rewire hook
- **2026-05-25 全闭环 ✅**:4 batch 全 squash merge 推 origin/main(B1 `ac6b523` schema + B2 `dd3e207` service+trigger + B3 `a3850ac` UI + B4 R5+收尾 本批)· 1476 pass / 0 analyze · Mac+Opus xhigh 累计 ~2.75h vs spec 估 15-20h(0.16× · spec phase0 + Q1-Q8 直采 + 路径 A UI 不开新 panel 是加速主因)· R5 18 测(R5.1-5.5+5.7)· 详 GDD §12.2 v1.16 段 + handoff `docs/handoff/p4_1_b{1,2,3,4}_*_2026-05-25.md`
- **挂账 1.1**:Q6 A encounter recruit / Q6 B stage_boss 招降 / founder_buff_service 作用域真扩 / 多代 sect 传递 / member 招收 narrative ~30 条 / P1.2 跨派系 wire

### P4.2 §12.4 翻译(可选英文)
- 英文翻译(主线 / UI / 系统提示)
- 决策点:M12 评估是否投入,可放 2.0

---

## P5 上线收尾(M15-M16)

### P5.0 onboarding production seed(2026-05-25 ✅ P0-1 release 阻塞修)
- audit `1_0_release_audit_2026-05-25.md` 揭示首次启动无 production seed 路径 — `StageBattleSetup._buildPlayerTeam` 抛 `StateError('先跑 P1 种子')`,玩家全新启动 → 任何战斗 crash
- 修:`OnboardingService.ensureFoundingMasters()` 在 `SplashScreen._bootstrap` IsarSetup.init 之后调用,幂等(count(isFounder=true) > 0 跳过)
- 沿 `Phase2SeedService.seedMasterDisciple` 主流:Character × 3 + Equipment × 9 + Technique × 4 + SaveData wire + 物料 50/0(§5.1 反留存不爆量)
- 5 helpers(buildMasterCharacter / defaultMasterName / equipMasterStarting / learnMasterStarting / seedBasicMaterials)抽 `lib/features/onboarding/application/master_builder.dart` top-level functions,debug + production 共用
- 顺带 P1-1 debug 入口 `kDebugMode` 切除 + P1-3 home_feed 空 feed 引导文案
- R5 测族 8 测(R5.1 全新 db / R5.2 幂等 / R5.3 信源 Character / R5.4 装备心法 / R5.5 真战斗 e2e / R5.6 founder.id=1 / R5.7 sectName 不覆盖 / R5.8 物料 50/0)
- 详 `docs/spec/p5_onboarding_seed_spec_2026-05-25.md` + closeout

### P5.1 C1 教程完整度审计
- GDD §10 三种引导方式(剧情 / 气泡提示 / 百科)全审计
- 新手 30 min 路径全跑通

### P5.2 C2 难度曲线打磨

> **B1 敌人内力体系对称化(2026-05-30 实装 ✅ `055696b`)**:敌人内力从扁平封顶 1000 改**按自身境界派生**(`numbers.yaml combat.enemy_defaults.internal_force` 删,新增 `internal_force_scale`;`getRealm(tier,layer).internalForceMax × scale`,与玩家对称,clamp≤15000 §5.4),解高阶 Boss 招牌 ult 永久放不出。**scale=0.20 用户拍板**:Boss 内力 2600 放 1 次招牌传说大招,满配玩家 70% 胜。副作用 stage_05_05 on-level ceiling 76→20%,**2026-05-31 balance_simulator 复核 data-confirmed 销账**(全 30 关唯一 ceiling<50%,但败局 62% 在 30% 残血内惜败、仅 10% 真碾压 → 刀锋高方差跨阶墙非 bug)。per-stage Boss 全路径终调仍待 closed-beta 数据。

- 30-35 关全玩家路径数值再平衡
- itch.io Demo 反馈(P0.3 收集)纳入数据源
- **2026-05-29 数值再平衡首批 ✅**:根因A 挂机循环重平衡(B1+B2+B3)+ 红线值统一 numbers.yaml(单源)+ idle_economy 72h 经济曲线验证(drift 雷达 · `test/tools/idle_economy_test.dart`)· **B2 低 tier finding 已修**(用户拍 B:山林/古剑冢/藏经阁回 ×1.0,满挂 16→12 层落点三流不碾压 Ch1;erLiu+ 保 ×2.5)· 30-35 关终调 + closed beta 外部数据源留 M15-16

### P5.3 C4 音乐音效配音
- BGM(主线 / 战斗 / 闭关)
- SFX(战斗 / UI)
- 配音(关键剧情)

### P5.4 C5 Steam 集成
- 成就 / 云存档 / 玩家统计
- 商品页 / 评测 / 锁国问题 / Demo 版策略
- **预留 1 月 buffer**(首次 Steam 上线 ops 类工作未压测)

### P5.4b R6 对策:closed beta + Google 表单 + Steam Demo 版(2026-05-17 v1.1 加)
- 招募 ~10 人 closed beta(测试玩家 / 论坛 / Discord)
- Google 表单结构化反馈(难度评分 / 数值 bug / 流程卡点 / 通关时长)
- Steam Demo 版上架(C5 子项):公开渠道补充,替代原 P0.3 itch.io 中间态
- MSIX 打包工具链 + Sentry release 监控接入(原 P0.3 砍项的内容全在此期落地)
- 数据源喂 P5.5 C6 内容时长校准 + P5.2 C2 难度曲线打磨
- **前置依赖**:Steam developer 账号 + Demo 版打包链路(P5.4 C5 完成)

### P5.5 C6 内容时长校准
- Demo ~5-10h → 1.0 目标 40-60h
- 校准方式:外部玩家测试(~10 人)平均通关时间

### P5.6 Steam 1.0 上线
- 商品上架 / Demo 版上架 / 首发活动

---

## §12 范围决议表

| GDD §12 子项 | 1.0 范围 | 阶段 | 备注 |
|---|---|---|---|
| §12.1 江湖恩怨 | ✅ 1.0 | P1 | 独立 NPC 关系网模块 |
| §12.1 心魔系统 | ✅ 1.0 | P2 | 依赖第二条主线 |
| §12.1 门派事件 | ✅ 1.0 | P3 | 与声望联动 |
| §12.2 帮派门派 | ✅ 1.0 | P4 | |
| §12.2 婚姻后代 | ❌ 2.0 | -- | **本批砍** |
| §12.2 声望 | ✅ 1.0 | P1 | 独立累积值模块 |
| §12.3 轻功对决 | ✅ 1.0 | P3 | strategy 层 P0 准备 |
| §12.3 群战守城 | ✅ 1.0 | P3 | strategy 层 P0 准备 |
| §12.3 PVP(异步) | ✅ 1.0 | P3 | strategy 层 P0 准备 |
| §12.4 第二条主线 | ✅ 1.0 | P2 | 6 月,放宽 |
| §12.4 节日活动 | ✅ 1.0 | P1 | W16/W17 框架已建 |
| §12.4 MOD 支持 | ❌ 2.0 | -- | **本批砍** |
| §12.4 翻译英文 | ✅ 1.0 | P4 | 可选,M12 评估 |
| §12.5 角色寿命传承 | ❌ 2.0 | -- | 长期愿景 |
| §12.5 江湖编年史 | ❌ 2.0 | -- | 长期愿景 |
| §12.5 跨周目元数据 | ❌ 2.0 | -- | 长期愿景 |

---

## Demo → 1.0 内容 delta 表

| 维度 | Demo | 1.0 目标 | 倍数 |
|---|---|---|---|
| 主线关卡 | 15 | 30-35 | 2x |
| 章节 | 3 | 6 | 2x |
| 主线文字 | 3-5k | 6-10k | 2x |
| 装备 | 35 | 80 | 2.3x |
| 心法 | 21 | 50 | 2.4x |
| 典故 | 80 段 | 160 段 | 2x |
| 武学领悟 | 35 招 + 20 触发 | 70 招 + 40 触发 | 2x |
| 心法相生 | 5 组合 | 10-15 组合 | 2-3x |
| 师徒角色 | 3 硬种 | 飞升传承动态扩展 | 系统级 |
| 战斗形态 | 1(地面 3v3) | 4(地面 + 轻功 + 群战 + PVP) | 4x |
| 社交系统 | 0 | 4(帮派 / 声望 / 江湖恩怨 / 门派事件) | 0→4 |
| 内容时长 | ~5-10h | ~40-60h | 4-6x |
| 美术 | 0(几何 UI) | AI 出图水墨风全套 | 0→1 |
| 音频 | 0 | 配音(关键剧情)+ BGM + SFX | 0→1 |

---

## 关键依赖图

```
P0.1 #38 ──────→ P2 第二条主线(扩到 wushen 必须 base ≤ 16667)
P0.2 strategy 层 ──→ P3 §12.3 战斗形态扩展(3 种新形态全挂 strategy)
P5.4b closed beta + Steam Demo ──→ P5.2 C2 难度曲线打磨(外部反馈数据源,2026-05-17 v1.1 改)
P1.3 美术 PoC ───→ P1-P5 全程美术出图(节奏伴生)
P1.4 DeepSeek 产能 ──→ P2 文案大扩
P2.1 主线推进 ───→ P2.2 心魔(突破前置) ──→ P2.3 飞升 + 遗物 transfer
P1.2 江湖恩怨 + 声望 ──→ P3.4 门派事件 ──→ P4.1 帮派门派
P2 文案大扩 ────→ P4.2 翻译(可选)
全程 P1-P4 ─────→ P5 上线收尾
```

---

## 风险列表(按风险度排序)

1. **R1 AI 美术风格一致性 + 节奏脱节**(最高):水墨 LoRA M4 PoC 不达标 → P1 后半要重新决策(外包 / 极简几何)。**M4 设硬门槛**。
2. **R2 第二条主线文案量爆炸**:已放宽到 6 月分配 + DeepSeek 产能 P1 期压测,降低风险但仍是单线工期最长项。
3. **R3 #38 数值平衡级联**:base maxHp 改完带动全维度,P0 估时建议 opus xhigh **8-15h**(不是 2-3h)。
4. **R4 P0 Phase 5 第 7 批 strategy 重构成本未压测**:battle_engine.dart 当前是单形态专写,抽 strategy 层涉及 damage_calculator / battle_state / battle_runner 全链路。**预估 opus xhigh 6-12h**,P0 早期 design review 决定是否分 2-3 batch 渐进迁移。
5. **R5 Steam 集成 + 商品上线**:首次在 Steam 发游戏,**P5 留 1 月 buffer**。
6. **R6 数值打磨需外部玩家测试**:对策 = **P5.4b closed beta(~10 人 + Google 表单结构化反馈) + Steam Demo 版公开渠道补充**(2026-05-17 v1.1 砍 P0.3 itch.io 中间态后改)。P0/P1/P2 内部 dogfood + 数值红线测试 + Phase 0 reality check 兜底,不依赖中间态公开发布。

---

## 2.0+ 留项

- §12.2 婚姻后代(本批砍)
- §12.4 MOD 支持(本批砍)
- §12.5 全部:角色寿命传承 / 江湖编年史 / 跨周目元数据
- 多平台扩展:Mac / Linux / Switch
- 长期运营:DLC / 资料片 / 持续更新

---

## 修订记录

- **v1.10**(2026-05-29 晚,D/H 首批落地):见顶部 v1.10 段。~96% → **~97%**(D 0%→~20% 数值再平衡首批 + H 0%→~50% 3 审计 + 接线 polish · 外部 review 修闭 P1-a 三系锁死 + A2 多代飞升 2 真 bug)。1519→1552 测。
- **v1.9**(2026-05-29,路径方向调整 + 5h 挂机 D4):见顶部 v1.9 段。
- **v1.8**(2026-05-28,P2.1 全收 + 装备 drop 全覆盖):见顶部 v1.8 段。
- **v1.7**(2026-05-28,P3.2.B+P1.2+P3.x 三项实装):① P3.2.B 群战 aliveIfRecoveryPct 调优;② P1.2 Boss 击杀声望 wire(factionId + rival delta);③ P3.x 群战 UI wiring(MassBattleStrategy 接入 stage_entry_flow + 阵型 dialog);④ Phase 0 副产 P3 技术债+P1.2 B3+B4 已完成确认。1508→1514 测。~93% 维持。详 `docs/handoff/session_closeout_2026-05-28_p3_p1_triple.md`。
- **v1.6**(2026-05-28,1.1 挂账清理):见顶部 v1.6 段。
- **v1.5**(2026-05-26,Pen 视觉验收+P4.1 1.1+audit v3):见顶部 v1.5 段。
- **v1.4**(2026-05-25 晚续,P4.1 全闭环 + P5.0 + audit v2 + Q6A spec):Mac + Opus xhigh 累计 ~3.5h(P4.1 ~2.75h + P5.0 ~1h + audit v2 ~40min + Q6A spec ~30min + checklist ~25min)。① P4.1 §12.2 帮派门派 100% 闭环(4 batch squash merge);② P5.0 onboarding production seed(P0-1 release 阻塞清);③ 1.0 整体 audit v2 6 系统全健康;④ Pen Codex 视觉验收派单准备(8 必收硬证据);⑤ Q6A encounter recruit spec 起草(P4.1 1.1 挂账起点);⑥ `RELEASE_CHECKLIST_1_0.md` 起草(顶层长寿勾选清单)。1.0 整体 78% → **91%**。详 `docs/handoff/session_closeout_2026-05-25_p5_audit_v2_full.md` + `docs/handoff/1_0_release_audit_v2_2026-05-25.md` + `docs/RELEASE_CHECKLIST_1_0.md`。
- **v1.3**(2026-05-25 本批 nightshift T17-T22 跑完):见顶部 v1.3 段。
- **v1.2**(2026-05-17 晚续,P0 strategy 重构销账):Mac + Opus 4.7 xhigh ~2h(vs 6-12h 预估快 3-5×),Batch 1+2 同会话续跑。① P0.2 段从「待开工」改为销账(实测 + 产物清单 + 4 commit 链 + 校正记录:闭关地图实测 0 战斗);② P0 阶段 4 项 100% 收口(P0.1 / P0.2 / P0.3 决议 + 新销账)。详 closeout `docs/handoff/p0_battle_strategy_closeout_2026-05-17.md`。
- **v1.1**(2026-05-17 晚续,#41 决议方案 C):Mac + Opus 4.7,「聚焦游戏本身」原则下决议方案 C 砍 P0.3 itch.io Demo 公开整段。① 删 P0.3 段(MSIX + itch.io + Sentry + Google 表单 5 项推 P5.4b);② R6 对策改 P5.4b closed beta + Google 表单 + Steam Demo 版;③ 关键决策记录加「itch.io 中间发布砍」条 + 时间线表 P0 交付物移除 itch.io Demo;④ 加 P5.4b 新段;⑤ 依赖图更新;⑥ PROGRESS #41 从挂账段删除归档。**P0 真正剩余 1 项:battle_engine 抽 strategy 层重构**(原 P0.2 升回 P0,opus xhigh 6-12h)。
- **v1.0**(2026-05-17,起草):Mac + Opus 4.7 起草,W18 起步段全收口当晚。用户拍板:激进派 + 三者并行按依赖排 + AI 美术 + 一次性 1.0 上线 + 第二条主线放宽 5-6 月 + 砍婚姻后代 + 砍 MOD + Phase 5 第 7 批插 P0 + itch.io Demo 纳入 P0。
