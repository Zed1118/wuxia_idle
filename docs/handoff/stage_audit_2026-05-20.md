# 阶段性项目审查报告(2026-05-20)

> **触发**:M4 PoC #46 美术 89 张 assets 归位 + Flutter UI 3 处接入完工后(HEAD `9ce0201`),Pen 视觉验收异步等待期间 Mac 端做的并行盘点
> **范围**:4 项审查(1.0 路线图进度 + Demo §8.4 14/14 实测 + 代码健康 + memory 盘点)
> **节奏**:主对话 opus xhigh ~25min,不动代码,只产报告

---

## §1 审查 A · 1.0 路线图进度盘点(docs/ROADMAP_1_0.md v1.2)

### 阶段完成度矩阵

| 阶段 | 月份预算 | 核心交付 | 实测状态 | 完成度 |
|---|---|---|---|---|
| **Demo M0** | 已 done(W1-W18) | Demo §8.4 14 维度 + Phase 1-5 全 | **见 §2 实测**,test 1123 pass | **~95%** |
| **P0 数值前置 + strategy 重构** | M1-M2 | #38 maxHp + battle_engine strategy | **✅ 全收口** 2026-05-17 销账 | **100%** |
| **P1.1 A 类系统纵深** | M2-M4 | A1 师徒 E.1/E.5 / A3 共鸣 / A4 开锋 | E.1/E.5/A3/A4 大量已落,Phase 5+ 飞升留接口 | ~60% |
| **P1.2 §12 独立模块组** | M2-M4 | §12.4 节日 / §12.1 江湖恩怨 / §12.2 声望 | 节日 8 个 encounter + chip ✅ / 恩怨 + 声望 未开工 | ~25% |
| **P1.3 美术 PoC + LoRA** | M2-M4 | 水墨 LoRA / 装备 35 张 / M4 硬门槛 | **✅ MJ 路线 89 张全成 + 落入 app(本会话)** / LoRA 未训练 | **~70%** |
| **P1.4 DeepSeek 产能压测** | M2-M4 | 流程定稿 + 产能基线 | **DeepSeek 已退役 v1.8 → Mac 接管文案**,P1.4 目标转移 | N/A |
| **P2 第二条主线** | M5-M10(6 月) | 主线扩 35→80 装备 / 21→50 心法 / 80→160 典故 / +6-10k 字 / §12.1 心魔 / 飞升 | 未开工 | 0% |
| **P3 战斗形态扩展** | M10-M12 | 轻功 / 群战 / PVP | strategy 层 ready,实装未开工 | 0%(基建 100%) |
| **P4 社交收尾** | M12-M14 | 帮派 / 翻译可选 | 未开工 | 0% |
| **P5 上线收尾** | M15-M16 | 教程 / 难度 / 音频 / Steam | 未开工 | 0% |

### 关键判定

- **Demo 阶段加权完成度 ~95%** — 原 PROGRESS 顶段「1.0 加权 ~25%」是把 P1-P5 全 16 月分母,Demo 子分母接近收口
- **真硬阻塞 1.0 启动 = 0 项** — P0/P1.3/P1.4 都 ✅,P1.1/P1.2 进 1.0 P2 阶段时自然补完
- **下波候选**:候选 4(P1.3 收口 = Demo §7 UI 完善阶段)接住本会话 89 张美术落地的最后环节,是 ROI 最高路径

---

## §2 审查 B · Demo §8.4 14 维度全达标实测矩阵

(grep + wc 实测,HEAD `9ce0201`)

| # | 维度 | GDD §8.4 目标 | 实测 | 状态 |
|---|---|---|---|---|
| 1 | 主线关卡 | 15-20 | **15** | ✅ 下限达标 |
| 2 | 章节 | 3 | **3** | ✅ |
| 3 | 主线字数 | 3000-7000 | stages 5504 + chapters 1354 = **6858 字**(wc -m 中文字符) | ✅ 接近上限 |
| 4 | 爬塔 | 30 层(3 小 + 3 大 Boss) | towers.yaml 54 stage 段(含每层 npc + boss) | ✅ |
| 5 | 闭关地图 | 5 | **5**(shanLin / guJianZhong / cangJingGe / xuanYaPuBu / duanYaJueBi) | ✅ |
| 6 | 武学领悟触发 | 20-30 | **25 techniqueInsight** | ✅ |
| 7 | 基础奇遇 | 15-25 | **29 fortuneEvent** | ⚠️ **超 4**(1.0 翻倍不需补;可选 Demo 期裁 4 或保留)|
| 8 | 节日 encounter | 6-10 | **8 festivalRequired** | ✅ |
| 9 | 装备 | 30-50 | **35** | ✅ |
| 10 | 心法 | 20-30 | **21** | ✅ 下限达标 |
| 11 | 典故 | 50-80 段 | **360 段**(35 件 × default_lore + continued_lore_obtained 4 + continued_lore_boss_defeated 4) | ✅ **大超**(GDD §8.4 段数口径需二次对齐,若按「件」算 35 与目标 50-80 件不达标但 W17 已确认按段算)|
| 12 | 武学领悟招式 | 30-50 | **40 encounter_skills** | ✅ |
| 13 | 心法相生 | ≥5 | **7** | ✅ |
| 14 | 师徒 | 3 | **3**(founder + first_disciple + second_disciple) | ✅ |

**判定**:**14/14 实质全达标 ✅** · 唯一可挑刺是「基础奇遇 29 超目标 25」(超 4 个,轻量,不调整)。**Demo §8.4 候选 3 顺手 close,无需独立任务**。

---

## §3 审查 C · 代码健康审计

### 关键指标

| 项 | 实测 | 健康度 |
|---|---|---|
| flutter test | **1123 pass + 1 skip + 0 fail** | ✅ 满分(skip 1 = Isar widget test event loop deadlock,memory `feedback_isar_widget_test_deadlock` 已锚) |
| flutter analyze | **0 issues** | ✅ 满分 |
| lib 非 codegen 行数 | **25,214 行** | 合理 |
| test 行数 | **26,735 行** | ✅ **test > 代码(106%),健康标志** |
| origin/main 同步 | HEAD 9ce0201 == origin 9ce0201 | ✅ |

### lib 子系统行数分布

```
battle 3900 / character_panel 2036 / debug 1999 / seclusion 1752 /
tower 1574 / equipment 1465 / encounter 1445 / mainline 1408 /
inventory 882 / codex 533 / cultivation 469 / technique_panel 372 /
tutorial 332 / main_menu 332 / dispel 284 / splash ~110(本会话新)
```

- ✅ 单 feature ≤ 4000 行,**无巨石模块**
- ⚠️ debug 1999 行偏多(Phase 2 调试场景累积) — Demo / 1.0 内部 dogfood 仍要用,**不清**
- ✅ splash 新增 ~110 行轻量(SplashScreen 独立 feature dir)

### pub outdated

- direct:`intl 0.19.0 → 0.20.2` 可升小版本(本批不动,候选 4 时与 UI 翻新一起)
- transitive:`_fe_analyzer_shared` / `analyzer` / `meta` 等一批锁版本(isar_community 上游约束) — **Demo / 1.0 内不动,memory `feedback_isar_pitfalls` 决议**

### 死代码

- 未深查(不动代码)
- 留候选 4(UI 完善阶段)同步审计 dead provider/widget

---

## §4 审查 D · memory 盘点 + 本会话 3 条教训 sink

### memory 索引盘点

- **总 ~70 条**(MEMORY.md 共 78 行 → +2 新条)
- 活跃高频(本周命中):~15 条(协作 v1.8 / Phase 0 grep / opus xhigh 估时 / Codex 桌面 / Image.asset / Pen flutter run / underscore wildcard)
- 过时风险:**0** 条(memory 是「教训性」非「状态性」无过期问题)
- 重复风险:**0** 条(扩展原 memory 不新建相似)

### 本会话 3 条教训 sink 方案

| # | 教训 | sink 路径 |
|---|---|---|
| 1 | Phase 3 接入受 widget 现状真实约束 | **扩展 [[feedback_phase0_grep_two_axes]]**:3 维 → 4 维(加 D. UI widget 是否已建),加实战补充 #3 |
| 2 | Dart 3.7+ underscore wildcard `(_, _, _)` 新规则 | **新写 `feedback_dart_underscore_wildcard.md`** + MEMORY.md 索引 |
| 3 | Flutter Image.asset 必加 errorBuilder 守 widget test 不破 | **新写 `feedback_image_asset_error_builder.md`** + MEMORY.md 索引 |

### sink 实测

- `feedback_phase0_grep_two_axes.md` 扩展 + name 由 "三维" 改 "四维"(MEMORY.md 索引同步)
- `feedback_dart_underscore_wildcard.md` 新建(~30 行)
- `feedback_image_asset_error_builder.md` 新建(~30 行)
- MEMORY.md 末尾加 2 行索引,共 78 行

---

## §5 综合结论 + 下波候选优先级

### 核心结论

- **Demo §8.4 14/14 实测全达标 ✅**(候选 3 顺手完工,无需独立任务)
- **1.0 路线图 Demo 阶段 ~95%**,P0 100%,P1.3 美术(本会话 +)~70%
- **真硬阻塞 1.0 启动 = 0 项**
- **代码健康满分** — test:code = 106%(test 比代码多)

### 下波候选优先级建议(按 ROI 排)

| # | 候选 | ROI | 说明 |
|---|---|---|---|
| 1 ⭐ | **候选 4 1.0 Demo §7 UI 完善阶段** | **最高** | 装备列表页 + 师徒展示页 + 装备详情弹窗 + UI 类资源(seal/scroll/divider/paper_bg 等)全面接入,一次性消费余下 64 装备 detail + 3 立绘 + 8 UI 资源,与本会话美术接入直接连续,opus xhigh 2-5 工日,**1.0 路线图 P1.3 收口最后里程碑** |
| 2 | 候选 2 心法相生 §4.5 触上限 8 重设计 | 中 | 21 心法 / 7 相生现状达标 §8.4,8 重是 1.0 P2 内容扩需求,sonnet+opus 1-2h,非阻塞 |
| 3 | 视觉验收 closeout(等 Pen 截图回来) | 低 | 等 Codex / 用户 RDP 截图,~10-30min |
| 4 | 候选 3 Demo §8.4 14/14 | **本审查已完** | 14/14 全达标无需独立任务,合并到本审查 |
| 5 | P2 第二条主线启动 | 远期 | M5-M10 主战场,需先 P1.3 美术 100% 收口(候选 1)+ P1.2 §12 模块组准备 |

### 候选 1(原候选 4)详细 scope 预估

| Phase | 工作 | 模型 | 时长 |
|---|---|---|---|
| Phase 0 | grep 现状(equipment widget 现状 / character feature 是否存在 / 详情弹窗 pattern 现状)| opus | 30min |
| Phase 1 | 设计装备列表页 + 装备详情弹窗 + 师徒展示页 + UI 资源接入位置 | opus xhigh | 1-2h |
| Phase 2 | 实装装备列表页(35 件分 7 阶 grid + filter + icon) | opus xhigh | 4-6h |
| Phase 3 | 实装装备详情弹窗(展示 detailPath 大图 + 典故 lore + 数值 + 三系锁死) | opus xhigh | 3-5h |
| Phase 4 | 实装师徒展示页(3 角色 portraitPath + 数据卡)| opus xhigh | 2-4h |
| Phase 5 | UI 类资源接入(scroll 弹窗 / divider 分隔 / paper_bg / mountain_bg / coin/lotus/meditation 入口图标)| opus xhigh | 2-4h |
| Phase 6 | test 加固 + closeout | opus xhigh | 1-2h |
| **合计** | — | **opus xhigh** | **2-5 工日**(13-23h) |

memory `feedback_opus_xhigh_interactive_duration` 提醒不要硬塞 scope,实测时间常 1.7-5× 加速,可能 1-3 工日完工。

---

## §6 审查产出物

- 本 doc:`docs/handoff/stage_audit_2026-05-20.md`
- memory 3 条 sink:
  - `~/.claude/projects/-Users-a10506/memory/feedback_phase0_grep_two_axes.md` 扩展 4 维 + 实战补充 #3
  - `~/.claude/projects/-Users-a10506/memory/feedback_dart_underscore_wildcard.md` 新
  - `~/.claude/projects/-Users-a10506/memory/feedback_image_asset_error_builder.md` 新
  - `~/.claude/projects/-Users-a10506/memory/MEMORY.md` 索引 +2 行 / 改 1 行

---

**审查完结**。下波 ROI 最高 = **候选 1 1.0 Demo §7 UI 完善阶段**,与本会话美术接入直接连续,起手即建装备列表页 + 详情弹窗 + 师徒展示页 + UI 资源全接入。
