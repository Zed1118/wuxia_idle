# H1 上手 30min 体验 audit

> 起草:2026-05-29 · H 段 Batch 1 · spec `docs/spec/h_polish_ux_spec_2026-05-29.md`
> Phase 0 grep 6 维(splash/home_feed/main_menu/tutorial/stage_01_01/victory)+ 数据驱动诊断
> **不实装** · 卡点候选清单 H1.3 待用户拍后再 apply

## 1. 启动链路(已 wire 的)

```
splash_screen.dart
  ↓ GameRepository.loadAllDefs + IsarSetup.init + OnboardingService.ensureFoundingMasters
home_feed_screen.dart(首次启动空 feed → _EmptyHint 占位)
  ↓ QuickClaim 按钮 markAllFeedRead → pushReplacement
main_menu.dart
  ↓ _MenuButton[主线] → ChapterListScreen
  ↓ stage_01_01 entry → narrativeOpeningId → BattleScreen → VictoryDialog
```

## 2. 已实装的上手仪式感

- ✅ Splash 水墨 landscape_loading.png + 应用标题 + Spinner
- ✅ HomeFeed 空 feed 时显占位文案(`UiStrings.homeFeedEmptyHint`)
- ✅ MainMenu 顶部 _TodayFestivalChip(节气 / 节日感)
- ✅ stage_01_01 narrativeOpeningId(2 段古风文案:山门已看不见 / 师父的话很重 / 山风推你)
- ✅ stage_01_01 dropTable(100% 寻常护甲 + 30% 通灵配饰 + 100% 磨剑石 · "首战必出 1 件装备"配置)
- ✅ VictoryDialog 显 drops + advancements + resonanceUpgrades

## 3. 发现的卡点 / Gap

### 🔴 P0 严重(ship blocker · 必修)

| ID | 位置 | 问题 |
|---|---|---|
| **G1** | `lib/shared/strings.dart:39` | `mainMenuTitle = '挂机武侠 · 调试主菜单'` · production 玩家看到"调试主菜单"会非专业感 / 困惑 |

### 🟡 P1 中等(影响体验)

| ID | 位置 | 问题 |
|---|---|---|
| **G2** | `tutorial_service.dart:36-42 + tutorial_hint_def.dart:34-56` | step 1-5(Ch1 5 关通关推进)**0 banner 提示** · 玩家上手 30min 全程无引导,直到 step 6 才出现"收徒资格已达成"banner。Demo 玩家可能 30min 内卡 step 5,根本看不到任何引导提示 |
| **G3** | `home_feed_screen.dart:88-103` | 首次启动空 feed → 占位文案 + QuickClaim 按钮,但 **无明显 CTA 引导玩家点 QuickClaim**(玩家可能停留在 feed 不知道往下走) |
| **G4** | `stage_01_01_opening.yaml` | 2 段古风叙事后无"轻按屏幕开始战斗"等显式 prompt;依赖 NarrativeReader 默认 onPop 进战斗,但**玩家可能不直觉**(需 Pen 实机测) |
| **G5** | `main_menu.dart:113-117` | 主标题字号 24 · 加粗 · 沿 P0 G1 修一并 polish 字号 / 字距 |

### 🟢 P2 优化(polish · 可选)

| ID | 位置 | 问题 |
|---|---|---|
| **G6** | VictoryDialog 全链路 | 首次装备掉落是否有"哇我第一件装备"的额外特效 / 动画?(沿 GDD §10.2 仪式感设计)|
| **G7** | step 6/7/8 真实触发时机 | 上手 30min 玩家估计能到 step 4-5(Ch1 末)· step 6 收徒(一流境界)+ step 7 奇遇 + step 8 开锋全在 1-3h 后才触发 → 30min audit 几乎覆盖不到 |
| **G8** | tutorial banner step 1-5 缺位 | 与 G2 同源 · 是否补 step 1-5 也加 banner?(GDD §10.2 第 2 方式上下文气泡)|

## 4. 期望体验 vs 实际 gap

| 时间点 | 期望 | 实际 | gap |
|---|---|---|---|
| 0-1min | 启动 splash + 进 home feed | ✅ | — |
| 1-3min | feed 引导 / 点 QuickClaim | ⚠️ 空 feed 占位 + 无 CTA | G3 |
| 3-5min | MainMenu 看到入口 | ✅ 主线按钮显著 · ❌ 标题写"调试主菜单" | **G1** |
| 5-10min | stage_01_01 进 opening + 战斗 | ✅ 但 narrativeReader 后是否直觉进战斗?| G4 |
| 10-15min | 首胜 + VictoryDialog drops | ✅ 100% 掉护甲 + 磨剑石 | — |
| 15-25min | stage_01_02 / 01_03 推进 + step 3 心法面板解锁 | ✅ tutorialStep wire 全 | — |
| 25-30min | stage_01_04 章末 Boss 前哨 | ✅ | — |

**结论**:30min audit 找到 **1 P0 + 4 P1 + 3 P2** 共 8 个 gap,其中 G1 是 ship blocker 必修,G2-G4 影响首次玩家感受 polish 建议修,G5-G8 锦上添花。

## 5. 不动的事

- ❌ 不动 numbers.yaml(D4 数值再平衡 + 候选 3 已闭环)
- ❌ 不动 stages.yaml / enemies.yaml(首关 3v3 已平衡)
- ❌ 不动 stage_01_01 dropTable(已配置首战仪式感)
- ❌ 不动 tutorial_service.dart hook(step 推进已 wire 全)

---

**下一步**:H1.3 卡点候选清单(`docs/handoff/h1_polish_candidates_2026-05-29.md`)展开 P0+P1+P2 修复方案 → 用户拍后再 apply。
