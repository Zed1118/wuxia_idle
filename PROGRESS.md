# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

> 📊 **2026-05-25 nightshift v2.1 工具完善 + T17-T22 + retry T17b/T19b 全闭环 · 1.0 ~75% → ~85%**

**2026-05-25 v2.1 工具完善 + 6h 挂机批 cherry-pick 收尾 ✅**(main `74ba519 + bc00b50 + e9dda85` · 1452 测全过 / 0 analyze):**v2.1 工具 5 项**(commit `74ba519` 5 文件 104 行 + sync 模板源):a) dispatcher BUDGET sanity(TIMEOUT/10 起跳)b) launch 饱满度预报(sum/window %)c) cost 追踪(`--output-format json` + jq → status → morning §1)d) `verify_grep_safe` 拦 `\|` ERE blind spot e) init 预检(tracked 警告)· memory feedback-nightshift-v2-first-run-lessons A7/A8/B1/B4/C2 5 项销账。**6h 挂机批 cherry-pick** T17 B1+B2 ✅ + T18 narrative ✅ + T20 audit ✅ + T21 P4.1 spec ✅ + T22 总收尾 ✅ + **T17b retry**(B3 UI + B4 R5 + closeout · 7+2 files 392+367 行)+ **T19b retry**(技术债 3 合一 · 21 files 1066+ 行)cherry-pick 入 main。**P1.2 江湖恩怨+声望 100% ✅**(schema+service+UI+R5+closeout 全闭环)· **技术债 3 合一** numbers_config 强类型 + sect Isar 持久化 + systemClock 全闭环 ✅。**1.0 整体 ~75% → ~85%**(P1.2 100% + P3.3/P3.4 narrative + P4.1 spec 8% + 跨系统 audit + 技术债)。**已知挂账**:T19b verify path_guard 越界 `test/data/isar_setup_test.dart`(产出合理 · spec allowlist 设计太严 · 后续 task spec 含 Isar 改动默认加 `test/data/**`)· 6 关键问题清单(closeout §5 · T23 合批 + T24 wire 起草中)。详 `docs/handoff/p1_2_jianghu_full_closeout_2026-05-25.md` + `docs/handoff/p3_tech_debt_closeout_2026-05-25.md` + `docs/handoff/session_closeout_2026-05-25_nightshift_6h_review.md`。

---

**2026-05-24 晚 nightshift v2 真生产跑 T11+T12 双 COMPLETED ✅ · 1.0 P3.3/P3.4 Phase 2/2.1 schema 全闭环**(main `efc7604` · 3 commit 推 origin/main · 1302→1311 pass / 0 analyze):T11 PVP Phase 2(`PvpRecord/PvpSnapshot` + `StageType.pvp` + numbers.yaml §13 pvp 段)+ T12 sect_event Batch 2.1(`Sect/SectEvent` + composite index + 2 enum + numbers.yaml §14 sect_event 段)+ R5 schema 红线 9 测 + cherry-pick numbers.yaml 末位 1 处 resolve。速度锚点:T11 ×0.08 / T12 ×0.12(schema-only 比通用实装 ×0.13-0.18 更快)。

---

**2026-05-24 下午 nightshift v2 P1 工具收尾 + .nightshift/ 落库 ✅**(main `004cc37` · 2 commit push):.nightshift/ A 三步法落库(27 文件 + .gitignore SUMMARY/bak)+ T01.md A1 红线 + B3 per-task BRANCH/WORKTREE override + C1 morning §6「失败但有产出」候选段 + ~/scripts/nightshift-tpl/ 模板源同步。v2 工具层 P1 全销账。

---

**2026-05-24 中午 nightshift v2 首跑 ✅**(main `676be95` · 5 task spec/实装/MJ 32min · 0/5→4/4 verify P0 修补 5 项 idempotent 重跑通过 · T01 → PR #6 + T02-T05 推 main):详 `docs/handoff/nightshift_v2_first_run_closeout_2026-05-24.md` + memory `feedback_nightshift_v2_first_run_lessons` + `feedback_opus_nightshift_speed_v2`(opus --print ×0.10-0.18,3h 窗 doc/spec 塞 15-20 task)。

---

**2026-05-24 8h overnight v3 派单 4/5 PR squash merged ✅**(main `a6812c2` · 5 worktree 真并行 wall clock ~8min · 5 reviewer agent 均分 8.9/10):#4 C P3.3 PVP 10/10 / #5 D P3.4 sect_event 9.5/10 / #8 B memory_sink_gdd10 9/10 / #7 A ch4_5 1 字 fix 8→10/10;**#6 E `feat/p1_2_spec` 8/10 4 项 fix** 由 nightshift v2 首跑 T01 闭环。详 `docs/spec/overnight_v3_2026-05-24/_README.md`。

---

**2026-05-24 凌晨 8h overnight v2 + P5+ UI polish 全收尾 ✅**(15 批 ABCDEFGHIJKLMNO + VulnFix P0 · ~2h15min · 24 commit `154211b → 874ce49` 推 main · 1302 pass / 0 analyze):P5+ UI polish 全闭环(防循环传位 R5.9 + 多代 chip + dialog 含弟子名)+ Codex 14 验收点 spec + MJ 10 张 prompt + stage_audit ~70% + P1.2 Phase 0 6 维 greenfield + ascension_lineage_chant + isLineageContinuation R5.10 + VC-P5+ fixture + GDD v1.16 ROADMAP P5+ 对齐 + VulnFix P0 修补。详 git log 2026-05-24 + 各 closeout(`p5_lineage_full_closeout` / `p5_ui_polish_closeout` / `stage_audit` / `p5_x_narrative_tier_audit` / `8h_autonomous_handoff_2026-05-24`)。**v2 教训** ⚠:单会话塞 15 批违反 `feedback_clear_session_timing` · memory sink 越权 Edit 触发 P0 修补 → v3 拆 worktree 修正。

---

**2026-05-24 §12.3 群战守城 P3.2 全闭环 + P3.2.B 残血容差 + P3.2.C ①+②a 数值/sentinel 双修**(PR #3 squash merge · 9 commit + 直推 ~16 commit · Mac+Opus xhigh 累计 ~7h):Batch 2.1-2.5 + P3.2.B 残血容差 + P3.2.C ②a sentinel(`character.id = -700-slotIndex`) + P3.2.C 修法 ① 3 真因(sentinel/buildEq/_intermission)+ R5 全过 · 1269 pass。详 git log + handoff/`p3_2_c_fix_1_numerical_overhaul_2026-05-24.md` + `p3_2_c_2a_closeout_2026-05-24.md` + `p3_2b_residual_hp_closeout_2026-05-24.md` + memory `feedback_isar_autoincrement_test_id_collision` / `feedback_local_doc_unpushed_remote_squash_diverge`。

---

**2026-05-24 §12.3 轻功对决 P3.1.B 子批收尾 ✅ · 1.0 P3.1 完整闭环**(Mac+Opus high ~1h · 4 commit PR #2 squash merge → main HEAD `b1f9e4d` · 1242 pass / 0 analyze):damage_multiplier 接入 `BattleCharacter.attackPowerMultiplier`(default=1.0 · default_ground_strategy 末乘 · LightFootStrategy._bake 烘焙双方对等)+ skills.yaml +18 招 lightfoot pool(yiLiu cap=3000 + jueDing cap=4000)+ stages.yaml lightfoot 5 关 skillIds 全切。R5.1 实测 50/50/49/50/50 主导格局未变。详 `docs/handoff/p3_1_b_closeout_2026-05-24.md` + memory `feedback_local_doc_unpushed_remote_squash_diverge`

**2026-05-23 夜 → 2026-05-24 晨 §12.3 轻功对决 P3.1 全收尾 ✅**(8h overnight worktree · 5 commit PR #1 squash → main `eb56480` · 1238 pass / 0 analyze):5 关 stage_light_foot_01..05 跨 yiLiu/jueDing 2 Tier × 3 terrain(water/rooftop/bamboo)· `LightFootStrategy` 组合委派 `DefaultGroundStrategy` 双方对等 bake · narrative ~2.1k 字 + UI 入口 main_menu 12→13 + R5 跨地形红线 3 测 50/50/46/50/50 leftWins。详 `docs/handoff/p3_1_lightfoot_closeout_2026-05-23.md`

---

**2026-05-23 §12.1 心魔系统 Batch 2.1-2.5 全收尾 ✅ · 1.0 P2.2 子阶段闭环**(Mac+Opus xhigh ~5.25h · 10 commit `e666e4c → b15d34d` push main):UI reactive 三态 + inner_demon_07 决议(+20% 同分布不动 6v3)+ cap 维度纠正(mirror_caps.attack_power_max 2000→6000 单件 vs 3 件求和)+ GDD v1.10 + 1220 pass。详 `docs/handoff/p2_x_inner_demon_final_closeout_2026-05-23.md`。**1.0 整体 ~70%**。

---

**2026-05-22 Ch6「飞升」Phase 2 全收口 ✅ + 复盘修补 ✅ · 1.0 P2 第二条主线全闭环**(~4h5min · 11 commit `15216a0 → d00e039` 全 push origin/main · 三章弧 Ch4+Ch5+Ch6 叙事完整):13 文件 ~5,800 字 + chapter_06 飞升 + 师父三句遗言第一次完整连成 + 无物之境收束 + R5 跨阶 wuSheng 红线一次过 + 复盘 6 项修补(epilogue 对称 / 普伤 ~9 万 spot check / closeout 100→72)。详 `docs/handoff/p2_x_chapter6_ascension_phase2_closeout_2026-05-22.md` + memory sink `feedback_user_offline_autonomous` / `feedback_doc_inflation_overnight`。**1.0 进度 ~42% → ~50%**。

**2026-05-21/22 历史段归档**(M4 美术 Stage 3 BOSS 22 张闭环 + Ch4 Phase 2.1-2.5 全收口 + 8h overnight + 审查修补 + 3h 托管):详 commit `319e15d` → `f6b0894` 范围 + handoff `art_stage3_boss_closeout` / `p1_x_chapter4_phase2_full_closeout_2026-05-22.md` / `8h_autonomous_handoff_2026-05-22.md` / `3h_managed_handoff_2026-05-22.md`。

**P1.1 全收口 ✅**(候选 1+2+3+4 实装 + 候选 5 文档对齐 + 候选 6 audit 复跑)。详条已迁末尾「### P1.1 候选 1-5 详条迁出 2026-05-21」段。

> 归档段「### M4 #46 美术详条迁出 2026-05-20/21」+「### W17-W18 详条迁出 2026-05-19/20」+ `docs/handoff/` 各 closeout。

## 已完成(近 W6 起,早期归档见末尾)

> W15 主战场详条 20 段 + W17-W18 详条 11 段均已归档,详末尾「### W14-W15 详条迁出」+「### W17-W18 详条迁出 2026-05-19」段。

## 已知偏差 / 挂账事项

- ~~37 / 38 / 40 / 41 / 42 / 43 / 44 / 45 全销账~~(2026-05-17/18/19/20):#37 详 `p1_37_orphan_decree_2026-05-19.md`;#38/40/41/42 详末尾 W17-W18 详条段;#43 详 `p1_43_higher_tier_closeout_2026-05-19.md`;#44 详 `p1_44_mac_takeover_closeout_2026-05-19.md`;#45 详顶段 + `p1_45_demo_polish_closeout_2026-05-20.md`

> 已销账条目(#1-#45)详见末尾归档。**P1 阶段全销账 ✅** + **Demo §8.4 14/14 全达标 ✅**(2026-05-20 #45 收尾)。

## 关键约束(每次开局必读)

- 数值红线:普伤 ≤8000 / 玩家血 ≤20000 / 内力 ≤15000 / 装备攻击 ≤2000(GDD §5.2)
- 不硬编码数值/文案(走 numbers.yaml / data/narratives, lore, events)
- Riverpod 状态管理;Isar 本地存储;data/ asset 根
- 不动 GDD.md / CLAUDE.md / numbers.yaml / data_schema.md / IDS_REGISTRY.md(DeepSeek 领地)
- Mac 端写 lib/、data/*.yaml(顶层)、test/;DeepSeek 写 data/narratives/、data/lore/、data/events/

## 远程仓库

- GitHub:https://github.com/Zed1118/wuxia_idle · 主分支 main
- 双端协作:Mac+Opus 写代码与数值;Windows+DeepSeek 写文案;Codex 桌面 @ Pen 跑视觉验收

## 归档

### 已解决挂账(逆时序)

- **Phase 1-2 + W1-W13 全销账**(2026-05-10..14):#1/5/12-16/19-29/32(逐周详 git log)+ #18 验证为伪挂账(项目无 web target)

### Phase 1-4 早期详条已迁出

- Phase 1-3 + W4-W11:`phase{1,2,3}_summary.md` + git log + tags `v0.1.0-phase1` / `v0.3.0-w11`
- W14-W15 详条迁出(2026-05-15/17)+ Phase 5 #2/#3 销账详条:git log + handoff/各 closeout

### W17-W18 详条迁出 2026-05-19/20

13 段销账(P1 #42 Phase 1+P1.x+P1.y+P1.z+P2 扩段 / P1 #43 高阶占位 / P1 #44 协作 v1.8 切单端 / Nightshift 9 task / P0 4 段 / P0.1 #38 maxHp 重平衡 / 外部审查 + 6 项 / 1.0 路线图 launched / W18-A1.2 hot-loop / W18-A1 Codex 视觉)。详 git log + handoff/`p1_42_*` / `p1_43_higher_tier_closeout_2026-05-19.md` / `p1_44_mac_takeover_closeout_2026-05-19.md` / `nightshift_20260519_handoff.md` / `p0_38_maxhp_rebalance_closeout_2026-05-17.md` 等 11 closeout。

### P1.1 候选 1-5 详条迁出 2026-05-21

5 候选全收口(4 实装 + 1 文档对齐):候选 1 收徒池 E.1 / 候选 2 祖师爷 sect_wide_buff / 候选 3 共鸣度 4 子任务 + joint_skill / 候选 4 开锋 build / 候选 5 CLAUDE.md §12 表述对齐 — git log + handoff/`p1_1_*_closeout_2026-05-21.md` 5 closeout。

### M4 #46 美术 + Ch4 Phase 2 详条迁出 2026-05-20/22

- **M4 #46 美术** 5 段(2026-05-20/21):Stage 2 W1-W6 74/74 + assets 89 张归位 + stage_audit + 候选 1 round 1 + #45 Demo §8.4 polish · 详 art_poc_* / art_assets_integration_* / p1_45_demo_polish_*
- **Ch4 1.0 P2 第二条主线第 1 章**(2026-05-21/22):Phase 2.1-2.5 全收口 9 commit + 13 narrative ~5,880 字 + R5 红线 + GDD v1.3 · 详 p1_x_chapter4_phase2_*
