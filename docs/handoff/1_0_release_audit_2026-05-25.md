# 1.0 Release Readiness Audit · 2026-05-25

> 体量 ≤60 行 · Mac+Opus xhigh ~30min · 范围:本机代码层 A-grep audit
> Demo §8.4 14/14 全达标 ✅ + 17 main_menu 入口齐 + 29 service 链路通 + 6 TODO 全 Phase 5 预留
> 但发现 **1 项 P0 release 阻塞** + 3 项 P1 应修。

## TL;DR

1.0 整体 ~90% 数字现实,代码层 audit 揭示真正阻塞极少。**唯一 P0**:首次启动没有 production 路径 seed 玩家三角色(founder + 大弟子 + 二弟子),`StageBattleSetup._buildPlayerTeam` 在 `players.isEmpty` 时抛 `StateError('先跑 P1 种子')` — 明确指 dev 路径。玩家全新进游戏 → 进任何战斗屏 → crash。这是 1.0 Steam release 不可接受。

## 现状:14/14 全达标(Demo §8.4)

| # | 项目 | 期 | 实测 |
|---|---|---|---|
| 1 主线关卡 | 15-20 | **15**(Demo ch01-03 各 5,ch04-06 是 1.0 P2) |
| 2 章节 | 3 | **3**(+ 1.0 P2 扩 3 章 + 3 扩展) |
| 3 主线字数 | 3,000-7,000 | **3,696**(chapter 902 + stages 2,794) |
| 4 爬塔 30 层 | 30(3 小+3 大) | **30**(3 minor [5/15/25] + 3 major [10/20/30]) |
| 5 闭关地图 | 5 | **5** |
| 6 武学领悟触发 | 20-30 | **25** |
| 7 基础奇遇 | 15-25 | **21** |
| 8 节日 encounter | 6-10 | **8** |
| 9 装备 | 30-50 | **35** |
| 10 心法 | 20-30 | **21** |
| 11 典故 | 50-80 段 | **360 段**(35 装备 × ~10 段) |
| 12 武学领悟招式 | 30-50 | **40** |
| 13 心法相生 | ≥ 5 | **8** |
| 14 师徒角色 | 3 | **3** |

## P0 阻塞清单(release 不可接受 · 必须修)

| # | 问题 | 复现 | 修复方案 | 预估 |
|---|---|---|---|---|
| **P0-1** | 首次启动没 production seed 路径 | 删 Isar db / 全新装游戏 → splash → home_feed → main_menu → 任何战斗 → `StateError('Isar 没有任何 Character(先跑 P1 种子)')` | `SplashScreen._bootstrap` 末或 `HomeFeedScreen` 首次进 MainMenu 前,加 `_ensureFoundingMasters()`:复用 `phase2_seed_service.seedMasterDisciple` 主流(剥 debug header / clear logic),从 `data/masters.yaml` 反序列化 3 master_def → 写 `Character` + starting equipment/technique + `SaveData.activeCharacterIds = [1,2,3]` + `founderCharacterId = 1`。production 路径放 `lib/data/` 或 `lib/features/onboarding/` 新建 OnboardingService。 | **xhigh ~1.5-2h** |

## P1 应修清单(1.0 release 强建议)

| # | 问题 | 建议 |
|---|---|---|
| P1-1 | `main_menu` 有 `BattleTestMenu` + `Phase2TestMenu` 两 debug 入口可见 | `if (kReleaseMode) ...` 切除,或藏到长按 logo / 7 击启动屏 dev 入口 |
| P1-2 | `_SeclusionMenuButton` fallback `defaultCharacterId=1` 是 phase 2 dev seed 习惯 | P0-1 修后,fallback 改为「ids 空 → 按钮禁用 + 引导文案」,不再硬编码 id=1 |
| P1-3 | 新玩家空 feed 没引导 | `HomeFeedScreen._EmptyHint` 加「点'开始'进入修炼」一句引导文案(production seed 触发前) |

## P2 质量审计(non-blocking · 可推迟)

- TODO 全 Phase 5 预留(`isar_setup.dart` × 3 多槽 + `numbers_config.dart` × 1 PVP 镜像 + 2 doc-only),非代码阻塞
- 17 main_menu 入口 tutorialStep 门槛只锁了 techniques(>=3)和 seclusion(>=5),其他 15 全开 — 是否合理留 P5 教程引导挂账
- Isar schema 0.13.0,多槽 / migration 全 Phase 5
- UI 视觉/手感无法本机查,需 Pen 派单 sect_screen 4 Tab + 其他 screen 视觉验收(留下波)

## 已知挂账(ROADMAP 已记录,本批不重复)

P1.1 候选 / P3 技术债 3 项 / P3.x UI 战斗 wiring / P4.1 1.1 挂账 8 项 / P5 教程 / 美术 / 音效 / Steam 集成 — 详 `ROADMAP_1_0.md` v1.3。

## 下波候选

| 选项 | 工作量 | 推荐 |
|---|---|---|
| **A. 修 P0-1**:实装 production seed 路径(OnboardingService) | xhigh ~1.5-2h | ★★★ 1.0 release 唯一硬阻塞 |
| B. P1-1+P1-2+P1-3 三项一起修 | high ~1-1.5h | ★★ 紧跟 A 提升 release 完整度 |
| C. Pen Codex Windows 视觉验收 P4.1 UI | ~1h 异步 | ★★ 派单 |
| D. 1.1 挂账起点(Q6 A encounter recruit) | xhigh ~4-6h | ★ 1.0 还没完不动 1.1 |
