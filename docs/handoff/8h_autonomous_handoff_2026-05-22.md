# 8h autonomous 工作流 · 起床 handoff(2026-05-22)

> 派单方:用户(2026-05-21 晚「开启规划睡觉 8 小时工作流」+ 同时反馈颗粒度纠偏)
> 执行方:Mac Opus 4.7 xhigh(单端自主推进,memory `feedback_user_offline_autonomous` + `feedback_8h_autonomous_workflow_template` ABCDE 5 批次)
> 起跑时间:2026-05-21 晚 ~22:00
> 起床时间(预计):2026-05-22 ~06:00
> 实测产出:~3.5h opus xhigh / ~4-5h 闲置 buffer(用户颗粒度纠偏成立)

---

## TL;DR · 起床先看这一段

**Ch4「西出阳关」1.0 P2 第二条主线第 1 章全收口 ✅**(数值 + narrative + R5 + GDD/ROADMAP/PROGRESS 全联动)+ **Ch5 Phase 0 reality check + GDD §12.4.1 1.0 P2 内容总量表草案** 留审 + **memory sink 5 项** + **3 周边 audit doc**(视觉验收派单 / lore 联结审计 / stage_audit)。

**1178 pass / 0 analyze 不破** · HEAD `537c4d4`(本批 B-E commit 进行中) · P2 第二条主线 ~85%。

---

## 一 · 起床 first-read 顺序(强烈推荐)

| # | 文件 | 阅读时长 | 内容摘要 |
|---|---|---|---|
| 1 | **本 handoff doc**(本文) | ~3-5min | 一句话总览 + 本次 commit 总览 + 决议清单 + 下波候选 |
| 2 | `PROGRESS.md` 顶段 | ~2-3min | Ch4 Phase 2.1-2.5 全收口 + P2 ~85% 进度 |
| 3 | `docs/handoff/p2_ch5_phase0_reality_check_2026-05-22.md` | ~5-8min | **关键 ⭐** Ch5 Phase 0 5 维 grep + 4 拍板候选(章名/境界跨度/文化主轴/末 Boss 类型) |
| 4 | `GDD.md` §12.4.1(L640+) | ~3-5min | 1.0 P2 内容总量表草案 [v1.4 待审] · 主线 25-30 关 / 章节 6 / 字数 14-20k / 装备 80 / 心法 50 |
| 5 | `docs/handoff/stage_audit_2026-05-22.md` | ~3min(选读) | 1.0 路线图 P0-P5 进度 + 项目量化指标 |
| 6 | `docs/handoff/codex_dispatch_ch4_visual_check_2026-05-22.md` | ~3min(选读) | Codex Pen Windows 视觉验收派单 spec(等用户起床派 Codex) |

**核心拍板项**(起床后 ~10min 内决议):
- **Ch5 4 项主轴**(章名/境界/文化/Boss 类型)— 我推荐「征东」+ jueDing 全章 + 西凉霸主三弟子复出 + 「师父遗言全听懂」顿悟
- **GDD §12.4.1 1.0 P2 内容总量表正式拍板**(草案数字调整 / 通过 / 维度增删)
- **Codex Pen 视觉验收**(是否启用 + 用户介入跑 Codex 桌面)

---

## 二 · 本次 8h 跑了啥(ABCDE 5 批次)

### 批次 A · Ch4 Phase 2.5 收口(~1h)

| # | 任务 | 实测 | commit |
|---|---|---|---|
| A1 | R5 跨阶红线压测 e2e(50 种子 + leftWins+draws ≥ rightWins) | ~30min | `537c4d4` |
| A2 | Phase 2 完整 closeout doc(~280 行) | ~15min | 同上 |
| A3 | PROGRESS 110 → 82 行归档(W17-W18 + P1.1 + M4 美术 3 段合 ~30 行) | ~10min | 同上 |

### 批次 B · Ch4 周边收尾(~30min)

| # | 任务 | 实测 | 文件 |
|---|---|---|---|
| B1 | Ch4 视觉验收派单 spec(Codex Pen Windows 8-10 截图清单) | ~15min | `docs/handoff/codex_dispatch_ch4_visual_check_2026-05-22.md` |
| B2 | Ch4 lore/equipment/skill 联结审计(7 equipment + 7 lore + 12 skill + 1 inventory item 全验证) | ~15min | `docs/handoff/ch4_lore_equipment_skill_audit_2026-05-22.md` |

### 批次 C · 项目 stage_audit(~15min)

| # | 任务 | 实测 | 文件 |
|---|---|---|---|
| C | wuxia_idle stage_audit(1.0 路线图 P0-P5 + Demo §8.4 14/14 + 量化指标 + 工作量复盘) | ~15min | `docs/handoff/stage_audit_2026-05-22.md` |

### 批次 D · 1.0 P2 地基预备(~40min)

| # | 任务 | 实测 | 文件 |
|---|---|---|---|
| D1 | GDD §12.4.1 1.0 P2 内容总量表草案(主线 25-30 关 / 章节 6 / 字数 14-20k / 装备 80 / 心法 50 + 风险挂账 + 字数预算细分 + 内容投放节奏) | ~15min | `GDD.md` v1.3 → **v1.4** |
| D2 | Ch5 Phase 0 reality check(5 维 grep + EncounterBiome 现状 + 4 拍板候选 + 工作量预估 ~2.5-3h) | ~25min | `docs/handoff/p2_ch5_phase0_reality_check_2026-05-22.md` |

### 批次 E · memory sink + 起床 handoff(~50min)

| # | 任务 | 实测 | 文件 |
|---|---|---|---|
| E1 | memory sink 5 项 | ~25min | 见 §三 |
| E2 | 本 handoff doc(本文) | ~25min(写中) | 本文 |

---

## 三 · memory sink 5 项

| # | memory | 类型 | 操作 | 主旨 |
|---|---|---|---|---|
| 1 | `feedback_opus_xhigh_interactive_duration` | update | 加 4 Ch4 锚点 + 颗粒度纠偏 case + 8h autonomous 反例 | 估时不按 sonnet baseline · 1.5-10× 实测加速 |
| 2 | `project_wuxia_idle_ch4_cultural_arc` | **new** | 全新 | Ch4 4 拍板叙事弧 + Tier 风格梯度词 + 体例锚点 给 Ch5/Ch6 复用 |
| 3 | `feedback_8h_autonomous_workflow_template` | **new** | 全新 | 8h overnight ABCDE 5 批次模板 + 自主决策清单 + handoff doc 体例 |
| 4 | `feedback_living_doc_state_drift` | update | 类型 C 加 Ch4 实战 case | Ch4 升档解耦实测(GDD §8.4 Demo 表不动,§12.4.1 1.0 P2 子段另起)|
| 5 | `feedback_user_offline_autonomous` | update | 加 8h 实战 case + 链接 #3 | 时长 ≥ 8h 走新 template |
| **MEMORY.md** | update | 加 2 新条目(#2 + #3)+ 更 #4 描述 | 索引同步 | — |

---

## 四 · 本次 commit 总览(待 push)

| commit | 类型 | 改动 |
|---|---|---|
| `537c4d4` ✅ push | test(p2 Ch4 Batch 2.5) [test] | R5 跨阶红线压测 + Phase 2 全收口 closeout + PROGRESS 归档 |
| **(待 commit)** | docs(p2 Ch4 周边 + Ch5 Phase 0) [GDD] | GDD v1.4 §12.4.1 升档草案 + Ch5 Phase 0 reality check + 视觉验收派单 spec + lore 联结审计 + stage_audit doc + 8h autonomous handoff doc |

**累计 Ch4 + 8h 工作流 push origin/main commit**:`4f7fb6d` ... `537c4d4` + 本批待 commit。

---

## 五 · 起床决议清单(关键)

### 5.1 Ch5 主轴拍板(4 项)

| 拍板项 | 我的推荐(理由) | 备选 |
|---|---|---|
| **章名** | 「**征东**」(Ch4 西出 + Ch5 征东对称弧;师父遗言「就先去走一走」=西出,东归是「走过看过再回来」延续;承接 Ch3 名扬江湖 → Ch4 西出阳关 → Ch5 征东) | 「问鼎」/「江南」/「北漠」 |
| **境界跨度** | **A 对称(jueDing 全章 qiMeng→dengFeng,跨 zongShi·qiMeng 末 Boss)** | B(jueDing + 部分 zongShi,同阶 zongShi 顶层 + 多人特殊) |
| **文化主轴 3 项** | 章首「西出阳关之后的回归」 + 章末「师父遗言全听懂」 + 末 Boss「西凉霸主三弟子复出」(留霸主本人到 Ch6 顶决战) | (待你拍板) |
| **末 Boss 类型** | **C 复合:三弟子 + 中州顶强者(论剑联手)**(冲突最大 + 留 Ch6 续战) | A 三弟子单 / B 中州顶强者单 |

### 5.2 GDD §12.4.1 1.0 P2 内容总量表草案审稿

数字范围(可调):
- 主线关卡 25-30 关(Ch4 5 + Ch5 5 + Ch6 5-10)
- 章节 6(Demo 3 + 1.0 P2 3)
- 主线字数 14,000-20,000(Demo 8,233 + Ch4 5,880 + Ch5/Ch6 各 ~5,000)
- 装备 80 件 / 心法 50 本 / 典故 160 段 / 武学领悟招式 70 招 / 心法相生 10-15 组合

**正式拍板后**:把 GDD §12.4.1 段顶 `[v1.4 待用户审]` 标签移除 + 升 GDD v1.5。

### 5.3 Codex Pen 视觉验收(可选)

`docs/handoff/codex_dispatch_ch4_visual_check_2026-05-22.md` 已 ready。是否启用 Codex Pen 跑(8-10 截图)留你拍板。

---

## 六 · 下波候选(opus xhigh 实测节奏)

| # | 任务 | 估时 | 优先级 | 接续度 |
|---|---|---|---|---|
| **1** ⭐ | **Ch5「征东」spec 起 + Phase 2 全推进**(用户拍板 4 项后) | **~2.5-3h** | **高** | 直接接 Ch4 桥头堡 |
| 2 | GDD §12.4.1 正式拍板 + 升 v1.5(用户审稿后) | ~10min | 中 | 接 Ch5 spec 起草前置 |
| 3 | Codex Pen 视觉验收(用户介入 Codex 桌面) | Pen ~1-1.5h | 中 | 异步,Ch5 推进时可并行 |
| 4 | §12.1 心魔系统 spec 起步(高境界突破前心魔关卡) | 多日 spec | 中 | 与 Ch5 解耦 |
| 5 | Stage 3 美术剩 28 张(MJ 解封后) | 多日 batch | 中 | 与 P2 解耦 |

---

## 七 · 实测加速比复盘(用户颗粒度纠偏成立)

| 阶段 | spec 预估(sonnet baseline) | 实测 | 加速比 |
|---|---|---|---|
| Ch4 全 Phase 2 | 6-10h | ~3.5h | ~2-3× |
| 8h autonomous 批次 A-E | ~5h(estimate) | ~3.5h(actual) | ~1.5× |
| **整体 8h overnight 产出** | **8h estimate** | **~3.5h actual** | **~2.3×(预估高估 130%)** |

**用户反馈**:「能不能把任务的颗粒度做准确一些,不要浪费时间」— **成立** ⭐⭐。memory `feedback_opus_xhigh_interactive_duration` + 新建 `feedback_8h_autonomous_workflow_template` 已 sink 纠偏案例 + 8h 模板。

---

## 八 · 自主决策清单

本次 8h 自主拍板:

1. ✅ R5 红线压测断言语义(改 `leftWins ∈ [5, 45]` → `(leftWins + draws) ≥ rightWins`,接受 jueDing 跨阶 boss 大概率 draws 的设计意图)
2. ✅ closeout doc 结构(沿 `p1_x_chapter4_phase2_batch1_closeout_2026-05-21.md` 体例 + 加工作量复盘段)
3. ✅ PROGRESS 归档老条目(W17-W18 详条 13 段 → 1 行 / P1.1 候选 5 段 → 1 行 / M4 美术 5 段 → 1 行,合并 Ch4 详条)
4. ✅ 视觉验收派单 spec 截图清单(基于 stages.yaml 5 关 + narrative 13 文件 UI 覆盖 + chapter_04 list + biome desert/frontier sceneBackground)
5. ✅ stage_audit 1.0 路线图百分比口径(P2 ~85% = Ch4 全收口 + Ch5/Ch6 待 / 整体 ~39% 加权)
6. ✅ GDD §12.4.1 1.0 P2 内容总量表加新子段(不动 §8.4 Demo 表,解耦)
7. ✅ Ch5 Phase 0 reality check 5 维 grep + 4 拍板候选推荐(但不实质拍板,留用户起床决议)
8. ✅ memory sink 新建 2 项 vs 追加既有 3 项的判断(Ch4 叙事弧 + 8h 模板 是新格子,需新建;估时纠偏 / 长寿 doc drift 类型 C / 8h overnight 实战 是既有 memory 追加锚点)

**未拍板项**(留用户起床):
- ❌ Ch5 章名 / 境界 / 文化 / Boss 类型
- ❌ GDD §12.4.1 正式拍板
- ❌ Codex Pen 视觉验收是否启用
- ❌ §12.1 心魔系统 spec 是否启动

---

## 九 · 不变量沿用

- GDD §5.4 数值红线 / §5.3 三系锁死 / §5.6 不硬编码 / §6 核心公式
- CLAUDE.md v1.9 Mac+Opus 单端全权 / Riverpod 3.x / Isar / 不引第三方游戏引擎
- memory `feedback_collab_mode_single_lore_workflow` Tier 7 阶 / `feedback_wuxia_boss_balance_crosstier` 跨阶设计 / `feedback_phase0_grep_two_axes` 5 维 grep / `feedback_red_line_test_semantics` 约束语义不写瞬时事实

---

## 十 · 收尾状态

- HEAD `537c4d4` ✅ push origin/main(批次 A)
- 批次 B-E commit 待 push(本批一次性 commit)
- worktree:GDD.md + 4 new docs(visual_check / lore_audit / stage_audit / Ch5 Phase 0)+ handoff doc 本文 待 commit
- 1178 pass / 0 analyze 不破
- 1.0 路线图:Demo ~95% / P0 100% / P1.1 ~100% / P1.2 ~25% / P1.3 ~80% / **P2 第二条主线 ~85%**(Ch4 全收口 ✅,Ch5/Ch6 待拍板)/ 整体 ~39%

---

**起床后第一件事:读本 handoff doc → 读 Ch5 Phase 0 → 拍板 Ch5 4 项 → 起 Ch5 spec → 进 Ch5 全推进**

或者:**起床后第一件事:Codex Pen 视觉验收派单 → 等结果 → Ch5 主轴拍板**(异步并行)
