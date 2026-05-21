# 阶段性项目审查报告(2026-05-21)

> **触发**:P1.1 系统纵深 5 候选全收口(候选 1-5,本会话 P1.1 内 10 commit / 单日 20 commit,~24h 推进)。对照 [2026-05-20 版](./stage_audit_2026-05-20.md) 看推进幅度,审 1.0 路线图剩余比例,grill 下波重点。
> **范围**:6 段(沿 2026-05-20 体例)+ 新增 §1.5 P1.1 24h 推进矩阵 + 新增 §3.5 closeout doc 体量盘点
> **节奏**:主对话 opus ~30min,不动代码,只产报告
> **HEAD**:`e291cfe` · origin/main 同步 ✅ · flutter test 1172 pass / analyze 0 issues

---

## §1 审查 A · 1.0 路线图进度盘点(docs/ROADMAP_1_0.md v1.2 · 24h 对比)

### 阶段完成度对比

| 阶段 | 月份预算 | 核心交付 | 2026-05-20 | **2026-05-21** | Δ |
|---|---|---|---|---|---|
| **Demo M0** | 已 done | Demo §8.4 14 维度 | ~95% | **~95%** | 持平(§8.4 14/14 持续达标)|
| **P0 数值前置 + strategy** | M1-M2 | #38 maxHp + strategy | 100% | **100%** | 持平 |
| **P1.1 A 类系统纵深** | M2-M4 | A1 师徒 E.1/E.5 / A3 共鸣 / A4 开锋 | ~60% | **~100%** | **+40% ⭐⭐** |
| **P1.2 §12 独立模块** | M2-M4 | 节日 / 江湖恩怨 / 声望 | ~25% | **~25%** | 持平 |
| **P1.3 美术 PoC + LoRA** | M2-M4 | 水墨 LoRA / 装备 35 张 | ~70% | **~75%** | +5%(round 2 视觉验收 9/9 PASS)|
| **P1.4 DeepSeek 产能** | M2-M4 | 流程定稿 | N/A 退役 | N/A 退役 | — |
| **P2 第二条主线** | M5-M10 | 35→80 装 / 21→50 法 / 心魔 / 飞升 | 0% | **0%** | 持平(本次有 P2 audit reality check 出 6 决策,详 `15d4be7`)|
| **P3 战斗形态扩展** | M10-M12 | 轻功 / 群战 / PVP | 0%(基建 100%) | **0%** | 持平 |
| **P4 社交收尾** | M12-M14 | 帮派 / 翻译 | 0% | **0%** | 持平 |
| **P5 上线收尾** | M15-M16 | 教程 / 难度 / 音频 / Steam | 0% | **0%** | 持平 |

### 关键判定

- **24h 推进密度最高 = P1.1 A 类系统纵深 +40%**(60% → ~100%),候选 1-5 全收口
- **Demo 阶段加权完成度仍 ~95%**(§8.4 14/14 持续达标,本次「主线扩 / §12.2 江湖恩怨」未动 → 余 5% 在 Demo 范围外的 1.0 P2 扩展)
- **真硬阻塞 1.0 启动 = 0 项**(P0/P1.1/P1.3/P1.4 已 ✅ 或决议 / P1.2 进 1.0 P2 阶段自然补完)
- **P2 audit 已 reality check 出 6 决策**(commit `15d4be7`,保守路径方向已锁,M5 起手不阻塞)

---

## §1.5 P1.1 候选 24h 推进矩阵(新增 · 单日推进密度基线)

P1.1 系统纵深 5 候选本会话 ~24h 全收口,scope + 时长 + commit 实测如下:

| 候选 | 子任务 | commit(s) | files / +/− | 时长(opus xhigh) | test Δ |
|---|---|---|---|---|---|
| **1 A1 E.1 收徒弹窗** | inactive 池采样 + 弹窗 UI + 入门境界初始化 | `86618f1` | 23 / +1949 / -26 | ~3.5h | (含在合计) |
| **2 A1 E.5 祖师爷 buff** | sect_wide buff 激活(`enabled_when_alive: true`)+ UI 显 | `a0eae82` | 15 / +674 / -42 | ~1.5h | (含在合计) |
| **3 A3 共鸣度满级体验**(4 子任务) | a 晋阶 banner / b joint_skill battle / c sword_song / d equipment_detail | `e7176c9` audit + `3cb9918` `15ff8aa` `9e54cf9` `225ee8e` `8b64390` 5 连击 | 28 / +1196 / -60 | ~3h | +23 |
| **4 A4 开锋 specialSkillCandidates 扩** | 21 weapon × 2 skills 机械映射 + 14 armor/acc 走 UI 兜底 | `d98d972` | 6 / +362 / -11 | ~50min | +2 |
| **5 CLAUDE.md §12 表述对齐** | 6 处 Edit · 0 代码 / 0 yaml / 0 test 改动 | `e291cfe` | 3 / +78 / -11 | ~20min | 0 |
| **合计 5 候选** | — | **10 commit** | **75 files / +4259 / -150** | **~9h xhigh + ~20min** | **+49 test** |

> 单日 commit 总数 = **20 个**(P1.1 5 候选 10 commit + M4 #46 美术 round 2 视觉验收 / 候选 2 §4.5 触上限 8 重设计 / P2 audit reality check / PROGRESS 整理共 10 commit)。
> 推进密度对比 2026-05-20 当日:同等节奏(单日 close 一个大里程碑)。**1.0 路线图按 16 月分摊,P1.1 单日 100% 收口已显著超 baseline 推进率**。

---

## §2 审查 B · Demo §8.4 14 维度全达标实测矩阵

(grep + wc 实测,HEAD `e291cfe`)

| # | 维度 | GDD §8.4 目标 | 2026-05-20 | **2026-05-21** | 状态 |
|---|---|---|---|---|---|
| 1 | 主线关卡 | 15-20 | 15 | **15** | ✅ 下限 |
| 2 | 章节 | 3 | 3 | **3** | ✅ |
| 3 | 主线字数 | 3000-7000 | 6858 | **6858**(stages 5504 + chapters 1354) | ✅ 近上限(同 2026-05-20)|
| 4 | 爬塔 | 30 层(3 小+3 大 Boss) | 54 段 | **30 floor**(grep `floorIndex:`) | ✅(对齐 GDD §8.2 原口径)|
| 5 | 闭关地图 | 5 | 5 | **5**(numbers.yaml `retreat.maps`)| ✅ |
| 6 | 武学领悟触发 | 20-30 | 25 | **25** | ✅ |
| 7 | 基础奇遇 | 15-25 | 29 ⚠️ | **29** | ⚠️ 持平超 4(1.0 翻倍消除)|
| 8 | 节日 encounter | 6-10 | 8 | **8** | ✅ |
| 9 | 装备 | 30-50 | 35 | **35** | ✅ |
| 10 | 心法 | 20-30 | 21 | **21** | ✅ 下限 |
| 11 | 典故 | 50-80 段 | 360 段 | **360 段**(80 default + 140 obtained + 140 boss) | ✅ 大超(按段算)|
| 12 | 武学领悟招式 | 30-50 | 40 | **40** | ✅ |
| 13 | 心法相生 | ≥5 | 7 | **8 ⬆** | ✅ +1(候选 2 §4.5 触上限 8 重设计 commit `d8b98ff`)|
| 14 | 师徒 | 3 | 3 | **3**(founder + first_disciple + second_disciple)| ✅ |

**判定**:**14/14 实测全达标 ✅** · 与 2026-05-20 唯一差异 = 心法相生 7→8(候选 2 早于 P1.1 5 候选,本日早些 commit 落)。**Demo §8.4 持续稳定**。

---

## §3 审查 C · 代码健康审计

### 关键指标对比

| 项 | 2026-05-20 | **2026-05-21** | Δ |
|---|---|---|---|
| flutter test | 1123 pass / 1 skip / 0 fail | **1172 / 1 skip / 0 fail** | **+49 ✅** |
| flutter analyze | 0 issues | **0 issues** | 持平 ✅ |
| lib 非 codegen 行数 | 25,214 | **27,212** | **+1,998**(P1.1 实装含 recruitment 723 + inheritance 73 + character_panel +233 + inventory +172 等)|
| test 行数 | 26,735 | **27,838** | +1,103 |
| test:code 比 | 106% | **102%** | -4 pp(lib 增量略大,test 仍 > code 健康)|
| HEAD == origin | ✅ | **✅** `e291cfe` | 持平 |

### lib 子系统行数分布对比

| feature | 2026-05-20 | **2026-05-21** | Δ | 备注 |
|---|---|---|---|---|
| battle | 3900 | 4037 | +137 | (候选 3-b joint_skill battle_ai 优先级)|
| character_panel | 2036 | **2269** | **+233 ⭐** | (候选 3-d equipment_detail 共鸣晋升 section + 候选 1 UI)|
| debug | 1999 | 1999 | 0 | — |
| seclusion | 1752 | 1764 | +12 | (小幅 polish)|
| tower | 1574 | 1612 | +38 | — |
| mainline | 1408 | 1521 | +113 | (mainline 节奏 / chapters 渲染)|
| equipment | 1465 | 1465 | 0 | (候选 4 改 yaml 不动 lib)|
| encounter | 1445 | 1445 | 0 | — |
| inventory | 882 | **1054** | **+172 ⭐** | (装备列表 / 共鸣度浮字接入)|
| **recruitment**(新) | — | **723 ⭐** | +723 | (候选 1 全新 feature)|
| codex | 533 | 533 | 0 | — |
| cultivation | 469 | 474 | +5 | — |
| technique_panel | 372 | 384 | +12 | — |
| tutorial | 332 | 367 | +35 | — |
| main_menu | 332 | 367 | +35 | — |
| dispel | 284 | 284 | 0 | — |
| event(新算入) | — | 261 | +261 | (event hooks 重组)|
| home_feed(新算入) | — | 250 | +250 | (江湖见闻录 UI)|
| baike(新算入) | — | 231 | +231 | (百科 codex)|
| narrative(新算入) | — | 172 | +172 | (narrative 渲染)|
| splash | ~110 | 113 | +3 | — |
| festival(新算入) | — | 94 | +94 | (节日 chip)|
| **inheritance**(新) | — | **73 ⭐** | +73 | (候选 2 founder_buff_service)|

- ✅ 单 feature ≤ 4100 行,**无巨石模块**
- ⚠️ debug 1999 行偏多(Demo / 1.0 内部 dogfood 仍要用,不清)
- ✅ recruitment + inheritance 新增 2 个 sub-1000 行轻量 feature(候选 1 + 候选 2 实装)

### pub outdated

- direct:`intl 0.19.0 → 0.20.2` 可升小版本(同 2026-05-20,本批不动)
- transitive:`_fe_analyzer_shared` / `analyzer` / `meta` 等一批锁版本(isar_community 上游约束,memory `feedback_isar_pitfalls` 决议)
- `js` package discontinued(transitive,不动)

### 死代码

- 未深查(不动代码)
- 留候选 7「closeout 归档拐点」一并审

---

## §3.5 closeout doc 体量盘点(新增)

| 项 | 实测(2026-05-21) | 健康度 |
|---|---|---|
| `docs/handoff/` 文档数 | **170 docs** | ⚠️ **到归档拐点边缘** |
| `docs/handoff/` 总大小 | **1.8M** | 仍可接受 |
| `docs/handoff/` 总行数 | **28,175 行** | ⚠️ 单目录已超单 ROADMAP 体量 |

**判定**:
- 170 docs 已达「单目录可读性边界」,Phase 5 / P1 详条 closeout 应进一步归档分卷(如 `docs/handoff/_archived_phase5/`, `_archived_w15/`)
- **非阻塞,本批不动**;留候选 7 ROI 极低做拢:简单一次性归档分卷 sonnet ~20min
- 替代选项:不动 handoff,后续新 closeout 走「PROGRESS 顶段 + git log + commit message」体例,降低 closeout doc 单文件体量

---

## §4 审查 D · memory 盘点 + 本会话教训 sink

### memory 索引盘点

- **总 ~77 条**(MEMORY.md 80 行,vs 2026-05-20 78 行,+2 行)
- 活跃高频(本周命中):~15 条(协作 v1.8 / Phase 0 grep / opus xhigh 估时 / Codex 桌面 / Image.asset / Pen flutter run / underscore wildcard / living-doc drift)
- 过时风险:**0** 条
- 重复风险:**0** 条

### 本会话教训 sink

| # | 教训 | sink 路径 | 状态 |
|---|---|---|---|
| 1 | 长寿规则文档状态/行号 drift(CLAUDE.md / GDD.md 「待决/状态字段」+ 行号是 drift 高发区,实装当 commit 顺手对齐)| `feedback_living_doc_state_drift.md` + MEMORY.md 索引 | ✅ 已 sink(候选 5 closeout 同步落)|

(本会话 P1.1 4 候选实装 + 1 文档对齐主要走「现有 memory 命中」如 `feedback_phase0_grep_two_axes` / `feedback_avoid_over_engineer_abstraction` / `feedback_red_line_test_semantics` / `feedback_riverpod_lint_plugin_enable`,未触发新 memory 沉淀。)

---

## §5 综合结论 + 下波候选 ROI 表

### 核心结论

- **P1.1 24h 全收口 ⭐⭐**(60% → 100%,5 候选 10 commit / +49 test / 0 issues / +1998 lib 行)
- **Demo §8.4 14/14 持续达标**(心法相生 7→8 仍稳)
- **真硬阻塞 1.0 启动 = 0 项**(P0/P1.1/P1.3/P1.4 全 ✅ 或决议;P2 audit reality check 已 6 决策拍板)
- **代码健康满分**(1172 test pass / 0 analyze / test 仍 > code)
- **handoff doc 170 docs / 1.8M 到归档拐点边缘**(非阻塞,候选 7 备选)

### 下波候选 ROI 表(grill 不拍板,留对话讨论)

| # | 候选 | ROI | scope | 时长 | 接续度 | 说明 |
|---|---|---|---|---|---|---|
| 1 ⭐ | **M4 美术 Stage 3 量产** | **高** | ~50-100 张 | 多日(用户 MJ 产 + Mac 接入)| **直接接续** P1.3 美术线 70%→75% | Stage 2 W1-W6 共 74 + Stage 1 PoC 15 = 89 张已落,Stage 3 可推 BOSS 立绘 / 场景插画 / 心法卷轴 / NPC portrait;**与 P1.1 系统纵深完工形成「系统 + 美术」节奏** |
| 2 ⭐ | **主线扩(第 4 章 + 5 关)** | **高** | +5-10 关 + 1 章 | xhigh ~10-15h | 接续 Demo §8.4 主线 15→20 | 接近 GDD §8.4 主线 15-20 上限,扩到 20 关 + 加 1 章「江湖崭露」补 §8.1;**支撑 1.0 P2 第二条主线启动** |
| 3 | **武学领悟内容扩(招式 +10)** | 中 | 40 → 50 招 | xhigh ~5-8h | 与心法相生 8 形成内容深度 | 招式 40 接近上限 50,可扩 10 招 |
| 4 | **师徒升级 Phase 5+** | 中-低 | 飞升 / heritage_items transfer | 多日 xhigh | GDD §7.1 飞升 + numbers.yaml heritage 4 字段已锁 | 1.0 路线图 P1.1 留接口,**现在做 vs P2 阶段做** 需用户拍板时机 |
| 5 | **闭关地图扩** | 中-低 | 5 → 7 | xhigh ~3-5h | 节气日 encounter 密度 | Demo §8.4 下限 5 达,1.0 扩到 7 让节气 encounter 触发更密 |
| 6 | dependency 升级(intl) | 极低 | intl 0.19.0 → 0.20.2 | sonnet ~30min | 非阻塞 | Demo / 1.0 内不阻塞,留 1.0 P5 上线收尾时统一升 |
| 7 | closeout 归档分卷 | 极低 | 170 docs → 分 5-7 目录 | sonnet ~20min | docs 整理 | 非阻塞,Phase 5+ / W14-15 详条可分目录归档 |

### 推荐下波路径(opus 视角,grill 用)

**首选 ⭐**:**候选 1 M4 美术 Stage 3** 或 **候选 2 主线扩** **二选一**

- **候选 1 优**:与 P1.3 路线图直接接续,89 张 → ~150-180 张完成 1.0 美术 100%;用户 MJ 产能已稳;Mac 端接入工时低
- **候选 1 劣**:用户 MJ 出图占用时间(每张 ~3-5min × 50-100 张),且需逐张 grill 命中(memory `feedback_mj_wuxia_prompt_pitfalls` 锚)
- **候选 2 优**:Demo §8.4 主线 15→20 上限,叙事密度直接拉满;支撑 1.0 P2 启动节奏
- **候选 2 劣**:文案产能由 Mac+Opus 接管(v1.8 后单端),~10-15h xhigh 块单一长任务,中途 fatigue 风险

**次选**:候选 3 武学领悟 / 候选 4 师徒升级 / 候选 5 闭关地图扩(系统深度,中等 ROI)

**暂缓**:候选 6 dep / 候选 7 归档(无紧迫性,留 1.0 P5 阶段)

---

## §6 审查产出物

- 本 doc:`docs/handoff/stage_audit_2026-05-21.md`(本次新增 §1.5 P1.1 24h 推进矩阵 + §3.5 closeout doc 体量盘点)
- 0 memory sink(本会话已在候选 5 closeout 沉淀 `feedback_living_doc_state_drift`)
- 0 代码改动 / 0 yaml 改动 / 0 test 改动(纯 audit doc)

---

**审查完结**。

**下波 grill 重点**:**候选 1 美术 Stage 3** vs **候选 2 主线扩(第 4 章 + 5 关)** 二选一,你拍板路径后我起 Phase 0 grep 现状(对应候选的实装 reality check)。

候选 1 推优势在「与 P1.3 美术接续 + 系统/美术节奏」;候选 2 推优势在「Demo 主线饱和 + 支撑 P2 启动」。**两者都不阻塞 1.0 路线图,纯节奏选择**。
