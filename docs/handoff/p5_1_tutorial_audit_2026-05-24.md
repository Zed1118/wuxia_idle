# P5.1 C1 教程完整度审计 audit(2026-05-24 凌晨 · M 批)

> 派单方:Mac Opus 4.7 · 8h overnight v2 流批 13/12(M)· ~25min · 0 code 改
> 范围:GDD §10 三种引导方式 + §10.1 解锁节奏 vs Demo 现状实装清单
> 目的:1.0 P5.1 教程审计起步 audit · 不实装 · 留 P5.x 阶段拍板

## TL;DR

GDD §10 定义 3 引导方式(剧情强制 / 气泡 + 红点 / 江湖见闻录百科)+ §10.1 解锁节奏 0-15min → 5-8h 8 阶。**Demo 现状 ~80% 覆盖**:① 剧情强制引导(Ch1-3 + Ch4-6 narrative 完整 ✅)② 江湖见闻录(`data/narratives/codex/` 18 条 + UI panel ✅)。**缺口** ⚠:气泡 + 红点引导(无系统级 widget · §10.2 #2)+ 二周目跳过引导(§10.4 0 实装)。

## §10.2 三引导方式实装现状

| 引导方式 | GDD §10.2 | Demo 现状 | 1.0 P5.1 增量 |
|---|---|---|---|
| #1 剧情包装强制(前 30min) | 师父教徒弟视角 | ✅ Ch1 narrative 5 关 + Ch4-6 narrative 接管 wuSheng 突破 + 心魔 7 关 narrative | 加新手 30min 路径 e2e 自审(无主动 grep) |
| #2 上下文气泡提示(30min 后) | 红点 + 50-100 字 | ⚠ 无系统级气泡 widget · TutorialBannerCard 部分(P1.y 实装)主菜单 banner 类 | **缺**:context-bubble widget · 红点 badge(character_panel / lineage_panel / ascension_panel 入口红点)· 50-100 字 hint pool |
| #3 江湖见闻录百科 | 200-500 字 | ✅ `data/narratives/codex/` 18 条 + CodexScreen UI(P1.z 实装) | 字数审计 + 7 阶机制百科全覆盖率 |

## §10.1 解锁节奏 vs Demo 实装

| 时间段 | GDD 解锁内容 | Demo 现状 | P5.1 增量 |
|---|---|---|---|
| 0-15min | 战斗 + 境界 + 装备掉落 | ✅ Ch1 stage_01_01..05 教学路径 | 30min path e2e 校准 |
| 15-30min | 装备强化 + 共鸣度(被动展示) | ✅ EnhanceDialog + ResonanceStage(P1.1 候选 3) | 红点引导 |
| 30-45min | 心法(先只主修) | ✅ TechniquePanel + 心法学习入口 | 气泡 hint |
| 45-60min | 三流派克制(实战遇到) | ✅ stages.yaml 流派分布(Ch1-Ch3 主敌覆盖 3 流派) | victory narrative 提示 |
| 1-2h | 闭关 + 时间锚点 | ✅ SeclusionMapList + 5 闭关地图 + 节气日 | 气泡引导首次闭关 |
| 2-3h | 师徒(收第 1 徒) | ✅ RecruitmentService + 收徒池 E.1(P1.1) | recruit narrative 首次提示 |
| 3-5h | 奇遇 + 武学领悟 + 辅修 | ✅ EncounterService(P1.x) + 武学领悟 35 招 + 辅修心法 | 红点引导首次领悟 |
| 5-8h | 开锋 + 心血结晶 + 相生 | ✅ ForgingService(P1.1 候选 4)+ Xinxue Jiejing + 心法相生 5 组合 | 气泡引导首次开锋 |

## §10.3 设计哲学验证(memory `feedback_clear_session_timing` 类型 B 文化锚点)

- ✅ **未解锁菜单隐藏**:main_menu \_MenuButton 按 unlock 条件 enable/disable / hidden 完全实装(P1.x · P3.1/P3.2/InnerDemon entry 按 unlock 链 reactive 三态)
- ✅ **第一小时轻松胜**:Ch1 stage difficulty 5.0-6.0 + 玩家 starting realmTier yiLiu·qiMeng 跨阶占优
- ⚠ **第一次爽点(暴击/突破/利器)**:暴击 narrative 自然(战斗演出含暴击 ⬆)· 但**首次突破 / 首次利器抽出**无独立 narrative cue(留 1.0 P5.1)
- ⚠ **不预先讲规则**:JianghuJianwen codex 是「永久可查」非「按需弹出」· 红点引导首次闯入新系统时弹百科入口未实装(P5.1 增量)

## §10.4 二周目跳过引导(0 实装)

GDD 注「二周目玩家可跳过引导直接开档」· Demo 现状:0 实装 · SaveData 无 `tutorialSkipped` flag · main_menu 无「跳过引导」入口。留 1.0 P5.1 子项实装(SaveData.tutorialSkipped + UI 入口 + skip narrative 路径 e2e)。

## P5.1 子项优先级(留用户起床拍板)

| # | 子项 | 估时 | 优先级 |
|---|---|---|---|
| 1 | **气泡 + 红点 widget 系统**(GDD §10.2 #2 主缺口) | ~4-6h xhigh | P0 |
| 2 | **首次爽点 narrative cue**(突破 / 利器 / 暴击专属 popup) | ~2h sonnet | P1 |
| 3 | **二周目跳过引导**(§10.4) | ~3h sonnet | P2 |
| 4 | **新手 30min path e2e 自审 doc**(无 code 改 · 仅 doc) | ~1h sonnet | P2 |
| 5 | **JianghuJianwen 百科 7 阶覆盖率审计**(已有 18 条 vs 需求) | ~30min sonnet | P3 |

## 不变量沿用

详 [`CLAUDE.md`](../../CLAUDE.md) · GDD §10 三引导方式 · §5.4 红线 0 改

## 挂账留

- 本 audit 是 P5.1 起步分析 · 不实装 · 留 P5.x 阶段 ROADMAP 推动时拍板各子项
- 优先级 1(气泡 + 红点)scope 较大需用户拍板 widget 风格(memory `feedback_user_offline_autonomous` 内容拍板留用户)
