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

**2026-05-26 Boss 招降叙事 3 篇 + hook 接入**(`d439065`):stage_01_05/02_05/03_05 各 7-8 段场景叙事 + `stage_boss_recruit_hook` 接 `NarrativeReaderScreen` 展示(rng 命中 → 叙事 → confirm dialog)。1505 测 / 0 analyze。

---

**2026-05-25/26 归档**:见末尾「### 2026-05-25/26 详条归档」段。

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

### 2026-05-25/26 详条归档

- **2026-05-25 P4.1 §12.2 帮派门派全闭环**(~2.75h · 1458→1476 测 · B1 schema + B2 service + B3 UI + B4 R5 · 详 `p4_1_b{1,2,3,4}_*_2026-05-25.md`)
- **2026-05-25 P5.0 onboarding production seed**(~1h · 1476→1484 测 · PR #12 · 详 `p5_onboarding_closeout_2026-05-25.md`)
- **2026-05-25 1.0 整体 audit v2**(~40min · 6 跨系统全健康 · 0 P0/P1 · 详 `1_0_release_audit_v2_2026-05-25.md`)
- **2026-05-26 凌晨自主挂机 5h batch**(6 doc · Q6A/founder_buff spec + self-review + RELEASE_CHECKLIST + ROADMAP v1.4 + Pen 救场)
- **2026-05-26 P4.1 1.1 Q6A encounter recruit**(~1.5-2h · 1484→1492 测 · PR #13 · 详 `p4_1_q6a_b123_closeout_2026-05-26.md`)
- **2026-05-26 P4.1 1.1 founder_buff cross_sect**(~30-40min · 1492→1497 测 · PR #14 · 详 `p4_1_founder_buff_b123_closeout_2026-05-26.md`)
- **2026-05-26 P4.1 1.1 Q6B stage_boss recruit**(~1-1.5h · 1497→1505 测 · 详 `p4_1_q6b_b123_closeout_2026-05-26.md`)
- **2026-05-26 P4.1 1.1 polish 候选 1+3**(~30-45min · character_panel sect NPC + 文案 8 段扩 · 详 `p4_1_1_polish_closeout_2026-05-26.md`)
- **2026-05-26 audit v3 + P5.2 子项 1+2+5**(~40min · 6 维 sweep 0 阻塞 + Ch4/轻功 6 数值微调 · 详 `session_closeout_2026-05-26_sect_polish_audit_v3_p5_2.md`)
