# 挂机武侠 · 开发进度

> Mac 端 Claude Code + Opus 4.7 维护。会话开始主动读取，任务完成主动更新。
> 总行数控制在 100 行内，超出归档到末尾。

## 当前阶段

> 📊 **2026-05-29 1.0 路径方向调整 · F+G 搁置 · H 主聚焦 · H2 小套餐实装 · D 数值再平衡推进 · 1534 测 / 0 analyze**

**2026-05-29 H2 小套餐(接线 polish)实装**(TDD · 0 数值改 0 schema 改 · 1520→1534 测):**C1 章节翻篇过场**(loadChapter + ChapterTransitionScreen + chapter_list「卷」入口 · prologue/epilogue 此前 dead content 变可达)+ **C2 升阶大境界仪式**(AdvancementResult.crossedTier → AdvancementSummary/retreat banner 大境界走 military_tech+badge,区别小层升级)+ **E2 effective 实战值可见**(detail _StatRow 显强化×共鸣×开锋乘法值 + 「基 N」副标)+ **S3 死字段清理**(cultivation_progress_pct 移除误导 UI 行 + numbers.yaml 注释加重)+ **R2 verified 已实装**(victory dialog ResonanceUpgradeBanner 早在 P1.1 候选 3-a,不加冗余 toast)。defer:C1 Boss 自动仪式 / E2 换装 delta / 根因A 挂机循环重平衡(中套餐)。详 closeout `m15_h2_small_polish_closeout_2026-05-29.md`。

**2026-05-29 H2 中期玩法深度 audit 完成**(doc only · 0 代码改):4 并行子 agent Phase 0 grep(装备/心法/师徒+共鸣/闭关+章节+升阶)→ `docs/handoff/h2_midgame_audit_2026-05-29.md`(~135 行)· 6 条 load-bearing 断言 grep 实测核验。**两大根因**:A 挂机循环与中期成长脱节(idle 0 喂共鸣度/修炼度 · 闭关鸡肋 · insightPoints/learnPoints 死钱包)+ B backend 做完前端没接线(章节翻篇 dead content · 学心法 UI 0 caller · 升阶大境界 UI 不区分 · 换装 effective 不展示 · cultivation_progress_pct 死字段)。3 套餐候选(小=接线 polish 0 数值改 / 中=挂机循环重平衡 / 大=深度加深 1.1 级)+ H2-Q1~Q4 决策点等用户拍。**推荐 小套餐**(已产 backend 接线 ROI 最高)。

**2026-05-29 H1-Q1 小套餐实装**(1 commit `a497044`):G1 `mainMenuTitle '挂机武侠 · 调试主菜单' → '挂机武侠'`(P0 ship blocker 清 · production-facing 产品名)+ G5 标题 style 24→28/w600/letterSpacing 4(沿 splash 体例次一档)· main_menu 测 30 全过含标题渲染 · 0 analyze · 顺手清 8 个往期遗留工作树(全已并入 main + clean)。**P0 ship blocker 清零**。

**2026-05-29 5h 挂机推进 · 方向调整**:用户拍板「先打磨游戏再启 Steam」→ F/G 搁置(留 ship 前 1-2 月)+ H 段从 nice-to-have 升「内容打磨 + UX」主聚焦 + Q1-Q4 默认决议 + 方案 A 单线推 D4。本批 Batch A0-A5 推进:CHECKLIST v1.9 + ROADMAP 对齐 + H 段 spec 起草 + `tools/balance_simulator.dart` PoC + 30 关全路径 1500 跑 + 难度曲线 csv + numbers tune 候选 diff(不上线,起床用户拍)+ R5 测族保护。

**2026-05-28 P2.1 装备美术 icon 45 张入库**(1 commit `d1cfd5a`):MJ v7 水墨厚涂 + AutoSail Chrome 扩展批量 + 4 张候选挑 1 张 · 7 阶全齐(T1 6+T2 6+T3 6+T4 7+T5 7+T6 7+T7 6=45)· 全 80 件主线装备 iconPath 引用 0 缺图 ✅ · 测族 1519 维持 / 0 analyze · **detail 图状态修正**:yaml 80/80 已填 detailPath + UI `equipment_detail_screen.dart:108` 已 wire(errorBuilder 兜底)+ 文件 35/80 ✅(原 35 件)+ 45/80 待美术 M15-16。

**2026-05-28 RELEASE_CHECKLIST v1.5 + ROADMAP v1.8 + R4 派单**(2 commit `e5bb9ba` + `51aaafb`):A 段测试数 1514→1519 · B 段附加 P2.1 全收+drop 全覆盖 · ROADMAP 93%→95% · Pen 同步 `e5bb9ba` + build OK · R4 派单 12 验收点(数据加载/掉落显示/典故+招式)· 典故盘点:80 文件 170 段 default_lore > GDD §8.4 目标 80 段 ✅ 已达标。

**2026-05-28 装备 drop 全覆盖 + P2.1 4 批全收**(2 commit · 1514→1519 测 / 0 analyze):56 条 dropTable 注入 26 关 · 77 件主线装备全覆盖 · +1 红线测试。P2.1 4 批全收(装备 80 / 心法 49 / 技能 166 / lore 80 / 相生 12)。

**2026-05-28 P3.2.B+P1.2+P3.x 三项 + 过夜 1.1 清理**(6 commit · 1508→1514 测):群战调优+Boss 声望 wire+群战 UI wiring+战败收降 wire+池扩。详各 closeout。

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
