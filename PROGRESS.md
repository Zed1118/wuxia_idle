# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

> 📊 **2026-05-26 1.0 release ready ~93% · sect 子系统全 polish + audit v3 0 阻塞 + P5.2 audit 子项 1+2+5 本机收齐**

**2026-05-26 audit v3 + P5.2 audit 子项 1+2+5 一波 ✅**(Mac+Opus xhigh 主对话 ~40min · 2 commit 直推 main · 1505 测全过 / 0 analyze):承接 polish 后续 → **audit v3 6 维 sweep**(7 子系统 + 11 红线 + 6 三系锁 + 1.1 sect 链路 e2e + 文档 drift + dead code 全 ✅ · 0 P0/P1 阻塞 · stageBossFailRecoverProb 0 caller 确认设计预留)→ **F1+F2 drift 修**(`580b80a` · ROADMAP v1.4→v1.5 升档 + sect_providers/ascend_service 2 处注释 stale 修)→ **P5.2 audit 子项 1+2+5 实装**(audit 2026-05-24 已存复用 · 6 数值微调 stages.yaml:Ch4 3.0/3.2/3.4/3.6/4.0 末关 +0.4 跨阶感 / 轻功 5.0/5.4/5.8/6.2/6.5 +0.4 均匀 + 子项 5 dead-end 由 audit「跨段衔接」表已覆盖)+ audit doc 末段加实装记录(子项 3+4 留 P5.4b closed beta M15-16)。**本机可推 1.0 polish 全收齐 ✅**(剩 D-G 段全 M15-16 外部依赖)。

---

**2026-05-26 P4.1 1.1 polish 候选 1+3 一波 ✅**(Mac+Opus xhigh 主对话 ~30-45min · 1 commit feat branch · 1505 测全过 / 0 analyze · 精度 0.20-0.25×):承接 Q6B 三项收齐后续 → **候选 3 `_SectMembershipRow` widget**(`character_panel_screen.dart:_LineageSection` 内 50 行 · 沿 `_LineageDisciplesRow` 体例 · `playerSectIdProvider` + `sectMembersProvider` filter `!m.isFounder && m.id != character.id` 排玩家自己/前代祖师/当前 character)+ UiStrings 2 段 `panelSectMembersLabel/Empty` + **候选 1 文案 8 段扩**(Q6A 3 events outcome body 4→7-8 行 · bamboo/desert/mountain 加 NPC 背景动机段 + 5 sect_candidates lore 3→6-7 行 · 母亲早逝 7 岁练剑/玉门关血流一夜/师弟出事自请放逐/杂学半生求归处/父亲炸塌成年礼 · 古风克制不滥情)。**Q1-Q5 default no-brainer 跳 spec doc · trust the build 跳 widget test**(filter 1 行 + 沿 _LineageRow 体例 · memory `feedback_isar_widget_test_deadlock`)。**P4.1 1.1 sect 子系统全 polish 收尾 ✅**(Q6A v1.12 + founder_buff v1.13 + Q6B v1.14 + polish v1.15)· 1.0 release ~93% 维持。详 closeout `p4_1_1_polish_closeout_2026-05-26.md`。

---

**2026-05-26 P4.1 1.1 Q6B stage_boss recruit B1-B3 全闭环 ✅**(Mac+Opus xhigh 主对话 ~1-1.5h · 3 commit feat branch · 1497→1505 测全过 / 0 analyze · 精度 0.20-0.30×):承接 P4.1 1.1 双项 ship 后 → 用户拍 Q6B spec Q1-Q8 默认 OK → 主仓 `a1a6996` spec(129 行)push main → sibling worktree `~/Desktop/挂机武侠.q6b` feat branch → **Phase 0 六维 grep verify**(spec deviation 方案 Z:Phase 0 漏看既存 `stageBossFailRecoverProb` 0.30 P4.1 v1.10 战败收降 0 caller 留 P5+/1.1 + 加新 `stageBossRecruitProb` 0.40 走本批战胜招降双语义共存)→ **B1 schema+yaml**(`eeac8cd` · `BossRecruitConfig` class + `StageDef.bossRecruit` + `SaveData.triggeredBossRecruitStageIds` + saveVersion 0.13→0.14 + 3 章末大 Boss stage_01_05/02_05/03_05 加 bossRecruit 跨三系 bamboo/desert/mountain + numbers.yaml stage_boss_recruit_prob + `_enforceBossRecruitRedLines` 三重校)→ **B2 抽 helper+wire**(`44352f4` · 抽 `_handleSectRecruit` from encounter_hook:174 → `sect_recruit_handler.dart` 共用 `runSectRecruitFlow` API(onMarkTriggered + onFallback 可空 callback 解耦语义)+ encounter_hook 改 wrapper 不破 Q6A 语义 + 新 `stage_boss_recruit_hook.dart` 6 步算法 + stage_entry_flow:182 wire + UiStrings 3 段 + closure promotion 修)→ **B3 R5 测族 + closeout**(8 测 · stages production yaml + numbers + persistence + serviceTie + 3 schema 红线 brokenLoader transform + 1 compat)+ closeout 42 行 ≤80。**P4.1 1.1 三项收齐 ✅**(主线 Q6A v1.12 + 副线 founder_buff v1.13 + 第三项 Q6B v1.14)· 1.0 release ~93% 维持。详 closeout `p4_1_q6b_b123_closeout_2026-05-26.md` + spec `p4_1_q6b_stage_boss_recruit_spec_2026-05-26.md`。

---

**2026-05-26 P4.1 1.1 Q6A + founder_buff 双项 ship 归档**:Q6A encounter recruit ~1.5-2h 0.25-0.30× + founder_buff cross_sect ~30-40min 0.13-0.20× 同会话续 cache warm 新最低 · PR #13 `7d9b903`(Q6A · AffectsSectMembership + SectCandidateDef + 5 NPC + 3 encounters + 8 R5 测)+ PR #14 `884a989`(founder_buff · isBuffActiveFor per-character API + per-player wire + 5 R5 测)· 详 closeout `p4_1_q6a_b123_closeout_2026-05-26.md` + `p4_1_founder_buff_b123_closeout_2026-05-26.md`。

---

**2026-05-26 凌晨自主挂机 5h batch ✅**(Mac+Opus xhigh 累计 ~3.5h · 0 改主代码):本会话起于 P5.0+audit v2 全闭环 → 派单 Pen Codex 视觉验收 → Codex 卡 partial-clone promisor 阻塞 → **Mac SSH 反向 tar pipe 救场 5min 完成** → 自主挂机 5h batch。**核心产物 6 doc**:① Q6A encounter recruit spec(Q1-Q10 默认决议)② P4.1 founder_buff 跨派系扩 spec(Q1-Q6 默认决议)③ Q6A self-review devil's advocate(11 风险点 · 2 🔴 必改)④ `RELEASE_CHECKLIST_1_0.md` 顶层长寿 ⑤ `ROADMAP_1_0.md` v1.4 升档(78%→91%)⑥ Pen 救场 closeout。**1.0 release ready ~91%**(0 P0/P1 阻塞 · Pen 视觉验收 8 截图 PASS · 93% 升档)。

---

**2026-05-25 1.0 整体 audit v2 ✅**(Mac+Opus xhigh ~40min · commit `e5fbb56` 直推 main · 0 改代码):audit v1 P0-1 修(PR #12 `3bf5e0c`)后复审 6 跨系统全健康 — ① 战斗核心 19 file ② encounter 94 测 ③ 闭关 62 测 ④ 师徒/共鸣/飞升 49 测 ⑤ 社交 22 文件 123 测 ⑥ cross-system T20 通过。**1484 测全过 / 0 analyze · 0 P0/P1 阻塞**。详 `docs/handoff/1_0_release_audit_v2_2026-05-25.md` + `session_closeout_2026-05-25_p5_audit_v2_full.md`。

---

**2026-05-25 P5.0 onboarding production seed ✅**(Mac+Opus xhigh ~1h · 1476→1484 测 / 0 analyze · PR #12 `3bf5e0c`):audit 揭 P0-1 阻塞 — 首次启动 `StageBattleSetup._buildPlayerTeam` 抛 crash。修:① 5 helpers `lib/features/onboarding/application/master_builder.dart` top-level + `OnboardingService.ensureFoundingMasters` 幂等(信源 isFounder=true count)+ SplashScreen wire + R5 测族 8 测 ② 顺带 P1-1 kDebugMode 切除 + P1-3 home_feed「按下「直入江湖」启程」引导 ③ Character × 3 + Equipment × 9 + Technique × 4 + SaveData wire + 物料 50/0 §5.1 反留存。**挂账 1.1+**:P1-2 fallback id=1 / 创角向导 UI / 多槽存档 / sectName 自定义。详 spec `docs/spec/p5_onboarding_seed_spec_2026-05-25.md` + closeout `p5_onboarding_closeout_2026-05-25.md`。

---

**2026-05-25 P4.1 §12.2 帮派门派 全闭环 ✅**(Mac+Opus xhigh 累计 ~2.75h · 4 batch squash merge origin/main · 1458→1476 测 / 0 analyze · spec 估 15-20h 精度 0.16×):**B1 schema**(`ac6b523`):`SectRank` enum + `Character.{isInSect,sectId,sectRank}` + `Sect.{territoryIds,memberCount}` + `data/territories.yaml` 6 territory + `numbers.yaml sect_management`。**B2 service**(PR #9 `dd3e207`):`SectMemberService` + `TerritoryService` caller 持锁 + 7 provider + Q7 B mission hook + AscendService rewire。**B3 UI**(PR #10 `a3850ac`):sect_screen TabBar 2→4 + 5 widget + UiStrings 28 段。**B4 R5**:18 测 + GDD §12.2 v1.16 + ROADMAP P4.1 0%→100%。**挂账 1.1**:Q6 A encounter recruit(spec ✅)/ Q6 B stage_boss 招降 / founder_buff 作用域扩(spec ✅)/ 多代 sect 传递 / member narrative ~30 条 / P1.2 跨派系 wire。详 `docs/handoff/p4_1_b{1,2,3,4}_*_2026-05-25.md` + spec `p4_1_sect_management_spec_2026-05-25.md`。

---

**2026-05-22/23/24 历史段归档**:见末尾「### 2026-05-22/23/24 详条归档」段(Ch6 飞升 P2 全闭环 / 心魔 Batch 2.1-2.5 / P3.1 轻功对决 / P3.1.B 子批 / P3.2 群战守城 / P5+ 多代飞升 + 真传位 / 8h overnight v2/v3 / nightshift v2 + T17-T22 + v2.1 工具完善 + T23/T24)。

## 已完成(近 W6 起,早期归档见末尾)

> W15 + W17-W18 + P5+ + P3.1+P3.2+心魔+Ch4-6 详条均已归档,详末尾归档段。

## 已知偏差 / 挂账事项

- ~~37 / 38 / 40 / 41 / 42 / 43 / 44 / 45 全销账~~(2026-05-17/18/19/20):详各 closeout

> 已销账条目(#1-#45)详见末尾归档。**P1 阶段全销账 ✅** + **Demo §8.4 14/14 全达标 ✅** + **1.0 ~91% release ready ✅**(本机可验全清零)。

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
