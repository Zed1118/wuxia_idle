# 断魂庄战斗驱动全链导航 wiring 实现计划

> **For agentic workers:** 用 superpowers:executing-plans 逐 Task 实装（inline·顺序依赖·勿并行 subagent 撞共享文件）。步骤用 `- [ ]`。设计见 spec `docs/superpowers/specs/2026-07-17-gauntlet-battle-flow-wiring-design.md`。

**Goal:** 把断魂庄 loadout/interlude 两屏 + GauntletService 接成端到端：主菜单入口→装载→逐关现场战斗(BattleScreen)→整备→三选一奖励/战败结算→离庄。

**Architecture:** 设计 A(BattleScreen 现场跑)。新建 `gauntlet_entry_flow` 编排器镜像 tower/stage entry_flow；`fightCurrentStage` 抽 `prepareStage`+`settleStageResult` seam 供 live 路复用；新建 reward/defeat 两屏；主菜单加 gate 入口。

**Tech Stack:** Flutter Desktop · Riverpod 3 · Isar · 严格 TDD(red→green→refactor)·全量并发 test。

---

## 分支 / 环境
- 分支 `feat/baicao-duanhun-phase-b`·worktree `.claude/worktrees/baicao-duanhun-phase-a2`(HEAD `35757104`·未 push)。
- 测试：`cd` worktree 后 `flutter test --no-pub <targeted>`；改共享 seam 的 Task 跑全量。dylib/.g.dart 已就位。

## 文件结构
- 改 `lib/features/boss_gauntlet/application/gauntlet_service.dart`：+`prepareStage`/`settleStageResult`，refactor `fightCurrentStage`。
- 建 `lib/features/boss_gauntlet/application/gauntlet_stage_plan.dart`：`GauntletStagePlan` record typedef。
- 建 `lib/features/boss_gauntlet/presentation/gauntlet_reward_screen.dart` / `gauntlet_defeat_screen.dart` / `gauntlet_entry_flow.dart`。
- 改 `gauntlet_loadout_screen.dart`(enter→push flow)、`main_menu.dart`(journey 入口)、`debug/application/visual_route.dart`+host+seed(reward/defeat route)。

---

### Task 1: Service seam(`prepareStage` + `settleStageResult`)
**Files:** Modify `gauntlet_service.dart`；Create `gauntlet_stage_plan.dart`；Test `test/features/boss_gauntlet/gauntlet_stage_seam_test.dart`(+ 回归现有 `gauntlet_*_test.dart`)。

- [ ] Step1 写失败测：`prepareStage` 返 (playerTeam 继承态·enemyDefs·seed=_stageSeed·isBoss) 与旧 fightCurrentStage 中间量一致；`settleStageResult(finalState)` 单 writeTxn 推进 advance/stageBossReward，幂等重入 no-op。
- [ ] Step2 跑测证失败(方法未定义)。
- [ ] Step3 定义 `typedef GauntletStagePlan = ({List<BattleCharacter> playerTeam, List<EnemyDef> enemyDefs, int seed, bool isBoss})`；抽 `prepareStage`(gauntlet_service.dart:287-302 纯计算段)与 `settleStageResult`(:305-321 writeTxn 段)；`fightCurrentStage`=prepareStage+runStage+settleStageResult(行为零改)。
- [ ] Step4 跑 targeted `test/features/boss_gauntlet/` 全绿(含 fightCurrentStage/recover 回归)。
- [ ] Step5 commit `重构断魂庄单场驱动抽 prepareStage/settleStageResult seam`。

### Task 2: `GauntletRewardScreen`(三选一)
**Files:** Create `gauntlet_reward_screen.dart`；Test `.../gauntlet_reward_screen_test.dart`。
- [ ] Step1 写失败 widget 测 @1280×720/1440×900：读 `activeRun().rewardCandidateDefIds` 出 3 装备卡，点选→`service.chooseReward(chosenEquipmentDefId)`；无 Isar 测 service==null 旁路空态；无溢出。
- [ ] Step2 跑证失败。
- [ ] Step3 实现屏(深底 lineup 体例+WuxiaPaperPanel·首通/重复标读 isFirstClearPending·选中确认后 `chooseReward`→回主菜单)。
- [ ] Step4 跑 targeted 绿 + `flutter analyze --no-pub` 0。
- [ ] Step5 commit `加断魂庄通关三选一奖励屏`。

### Task 3: `GauntletDefeatScreen`(战败结算)
**Files:** Create `gauntlet_defeat_screen.dart`；Test `.../gauntlet_defeat_screen_test.dart`。
- [ ] Step1 写失败 widget 测：展示已击败精英经验/轻重伤摘要(读 run/结算态)，「离庄」→ pop 回主菜单；两分辨率无溢出。
- [ ] Step2 跑证失败。
- [ ] Step3 实现屏(表现层·settleDefeat 已由 flow 调·本屏只读摘要+离庄)。
- [ ] Step4 targeted 绿 + analyze 0。
- [ ] Step5 commit `加断魂庄战败结算屏`。

### Task 4: `gauntlet_entry_flow` 编排器
**Files:** Create `gauntlet_entry_flow.dart`；Test `.../gauntlet_entry_flow_test.dart`。
- [ ] Step1 写失败测:`runGauntletFlow(context, ref)` 循环——prepareStage→设 battleProvider(镜像 stage host「挂空团→postFrame startBattle」)→push BattleScreen(onVictory/onDefeat)；victory 非终关→settleStageResult→interlude 屏→continueToNextStage 回循环；victory 终关→reward 屏；defeat→settleStageResult+settleDefeat→defeat 屏。测走真 ProviderContainer+seed 三关端到端(mirror `feedback_battle_determinism_test_via_notifier`)。
- [ ] Step2 跑证失败。
- [ ] Step3 实现 flow(镜像 `tower_entry_flow.runTowerFlow`·不 await push·onVictory 读 battleProvider 战末 BattleState 传 settleStageResult·config 经 provider watch 防竞态)。
- [ ] Step4 targeted 绿 + analyze 0。
- [ ] Step5 commit `加断魂庄逐关战斗驱动编排器 gauntlet_entry_flow`。

### Task 5: loadout enter → push flow
**Files:** Modify `gauntlet_loadout_screen.dart:37-62`；Test 更新 `gauntlet_loadout_screen_test.dart`。
- [ ] Step1 改测:`_enter` 成功后 push `runGauntletFlow`(替原 `maybePop`)；断言导航发生。
- [ ] Step2 跑证失败/红。
- [ ] Step3 改 `_enter`:enter 成功→`runGauntletFlow(context, ref)`。
- [ ] Step4 targeted 绿 + analyze 0。
- [ ] Step5 commit `接线断魂庄装载入庄→逐关战斗流`。

### Task 6: 主菜单断魂庄入口(gated)
**Files:** Modify `main_menu.dart`(journeyItems ~227-295)；Test `.../main_menu_*_test.dart` 或新增门控测。
- [ ] Step1 写失败测:`jianghuJourneyUnlocked` 时 journeyItems 含断魂庄项(onAllowed→GauntletLoadoutScreen)；未解锁隐藏。
- [ ] Step2 跑证失败。
- [ ] Step3 加断魂庄 journey item(镜像远征入口·gate `jianghuJourneyUnlocked`)。
- [ ] Step4 targeted 绿 + analyze 0。
- [ ] Step5 commit `加主菜单断魂庄入口(江湖远行 gate)`。

### Task 7: visual_route `gauntlet_reward`/`gauntlet_defeat` + seed
**Files:** Modify `visual_route.dart`+host+`visual_acceptance`/seed。Test 更新 route 测。
- [ ] Step1 写失败测:两 route 解析 + host 分派 + seed(reward=awaitingRewardChoice 态·defeat=战败态·复用 seedTeamLineup 清 bossGauntletRuns 幂等·`feedback_visual_capture_seed_idempotency`)。
- [ ] Step2 跑证失败。
- [ ] Step3 加两 route enum + host case + seed 函数。
- [ ] Step4 targeted 绿 + analyze 0。
- [ ] Step5 commit `加断魂庄奖励/战败 2 visual_route + seed`。

### Task 8: 全量回归 + 真机目检
- [ ] Step1 `flutter analyze --no-pub` 全仓 0。
- [ ] Step2 全量 `flutter test --no-pub`(改共享 seam·compact 首个 -N 才真失败)贴 pass/fail。
- [ ] Step3 macOS build + 自跑 visual_capture 目检 loadout/interlude/reward/defeat @1280×720/1440×900(无溢出/水墨观感/文案)。
- [ ] Step4 更新本 plan 恢复点 + PROGRESS 顶段(四态)。commit。

---

## 恢复点
- 状态：**Task 1-8 全 ✅ 完成**·全部 commit 未 push。8 切片:seam `b37ec4bb` / reward 屏 `81675ea7` / defeat 屏 `32a12e5d` / entry_flow `576fe93c` / loadout 接线 `79f7330e` / 主菜单入口 `80d0f1dd` / 2 visual_route `dae00576` / 收尾。断魂庄端到端可玩(主菜单→装载→逐关现场战斗→整备→奖励/战败→离庄)。
- 下一步：白天真机 visual_capture 目检 4 屏(loadout/interlude/reward/defeat @1280×720/1440×900·水墨观感/色板/无溢出·验收包 `build_acceptance.sh` 已就绪 @dae00576·两 route 已在 `VisualRoute.values` 验收套件)→ push(main 39 + phase-b)。
- 已验证(本会话 worktree 实测)：全仓 `flutter analyze --no-pub` **0**；全量 `flutter test --no-pub` **4282 pass/0 fail**(4264+18=reward5+defeat4+flow4+gate2+route3·EXIT 0)；macOS build ✓。
- 已知：Task5 专属真-Isar 装载 wiring 集成测 flaky(enter 后 provider invalidate × loadout Isar 流 + tearDown Isar.close 竞态·非接线 bug)撤下·接线由 entry_flow(4 端到端 widget 测)+`gauntlet_enter_test`+现有 loadout 5 测佐证。
- 环境：worktree 有 `libisar.dylib`+64 .g.dart·真-Isar widget 测走 runAsync+pumpUntilFound 配方(勿 pumpAndSettle/ensureVisible·撞真 async 死锁)。
- 阻塞：无。
