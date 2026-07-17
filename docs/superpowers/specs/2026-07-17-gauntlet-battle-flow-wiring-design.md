# 断魂庄战斗驱动全链导航 wiring 设计

- 日期：2026-07-17 · 分支：`feat/baicao-duanhun-phase-b` · effort：xhigh
- 前置：C2.1–C2.5 已闭环（后端内核 + loadout/interlude 两屏信息架构 + 2 visual_route）
- 本片 = C2 组前端最后一环：接线后断魂庄端到端可玩

## 1. 目标

把 loadout / interlude 两屏 + 后端 `GauntletService` 接成端到端流程：
主菜单断魂庄入口 → 装载入庄 → **逐关现场战斗（BattleScreen）** → 整备 → 通关三选一奖励 / 战败结算 → 离庄。

## 2. 决策（2026-07-17 用户拍板）

1. **设计 A：BattleScreen 现场跑**（非无头摘要）——契合 plan「逐关战斗[BattleScreen]」+ 战斗爽感主旋律（memory `feedback_wuxia_combat_satisfaction_principle`）。
2. reward 三选一屏 + defeat 结算屏 **本批一起建**（现不存在，"→reward" 要求达成）。
3. 主菜单入口挂 `SaveData.jianghuJourneyUnlocked` gate（同江湖远行/远征，断魂庄属江湖远行 Phase C）。
4. effort 升 xhigh。

## 3. 架构

### 3.1 编排器（新）`boss_gauntlet/presentation/gauntlet_entry_flow.dart`
镜像 `mainline/.../stage_entry_flow.dart` 与 `tower/.../tower_entry_flow.dart`：
`runGauntletFlow(context, ref)` 循环驱动三关，push BattleScreen（不 await·胜利留栈由 flow 播完再 pop）+ onVictory/onDefeat 回调推进。**widget 内零直接 Isar 写**——全经 `GauntletService`。

全链：
1. loadout `_enter` 扣帖建会话（现状）→ 成功后**不再 `maybePop`**，改 push `runGauntletFlow`。
2. 循环（`run.currentStage` 1..N，读 `activeRun()`）：
   - `service.prepareStage()` → `(playerTeam 继承态, enemyDefs, seed, isBoss)`（事务外纯计算）
   - 镜像 stage/tower host「挂空团 → postFrame startBattle」设 `battleProvider` + push `BattleScreen(live, onVictory, onDefeat)`
   - **onVictory**：读 `battleProvider` 战末 `BattleState` → `service.settleStageResult(finalState)`（单 writeTxn：advance + 快照继承 HP/真气/冷却 + stageBossReward）→
     - 非终关（→ interlude 态）：push `GauntletInterludeScreen`（整备用药）→「继续闯关」`continueToNextStage` → 回循环
     - 终关（→ awaitingRewardChoice 态）：push `GauntletRewardScreen`（三选一）→ `chooseReward` → 离庄
   - **onDefeat**：读战末态 → `settleStageResult`（advance 记败不推进）→ `service.settleDefeat` → push `GauntletDefeatScreen` → 离庄
3. 主菜单 `journeyItems` 加断魂庄项（gate `jianghuJourneyUnlocked` · `onAllowed` → push `GauntletLoadoutScreen`）。

### 3.2 Service seam 重构 `gauntlet_service.dart`（behavior-preserving）
从 `fightCurrentStage`（当前 = build+stagePlayerTeam → runStage 无头 → 单 writeTxn advance+stageBossReward+put）抽两段：
- `prepareStage({config, numbers}) → GauntletStagePlan(playerTeam, enemyDefs, seed, isBoss)`（事务外纯计算）
- `settleStageResult({finalState, config}) → void`（单 writeTxn：re-load fresh → advance + stageBossReward + put）
- `fightCurrentStage` = `prepareStage` + `GauntletBattleRunner.runStage` + `settleStageResult`（headless 路径保留给 recover/测试，行为零改）

### 3.3 新屏（表现层 · 零 Isar 直写 · 深底 lineup 体例 + WuxiaPaperPanel · 一屏不依赖滚动）
- `GauntletRewardScreen`：读 `run.rewardCandidateDefIds` 三件装备卡三选一（首通/重复标）→ `chooseReward(chosenEquipmentDefId)` → 回主菜单。
- `GauntletDefeatScreen`：读 settleDefeat 摘要（已击败精英经验 / 轻重伤）→ 确认离庄。

## 4. 测试策略（严格 TDD · red→green→refactor）

- **service seam**：`prepareStage` / `settleStageResult` 纯单测（继承态正确、advance 推进、幂等 no-op）+ `fightCurrentStage` / `recover` 行为不变回归（红绿双验）。
- **entry_flow**：widget 测走真 `ProviderContainer` + seed；`gauntletServiceProvider` 需 Isar，无 Isar 测中 `service==null` 屏内旁路（同 C2.5）。
- **2 新屏**：widget 测 @1280×720 / 1440×900 无溢出 + 三选一 / 离庄动作真触发 service（沿 C2.5 体例）。
- **端到端导航**：loadout enter → battle → interlude → battle → reward seed 场景（mirror `feedback_battle_determinism_test_via_notifier`，经 notifier.advance 非 strategy.tick）。
- **全量回归**：改共享 service seam → 跑全量 `flutter test --no-pub`（compact reporter 首个 -N 才是真失败·`feedback_flutter_test_minus1_carryforward`）。

## 5. 视觉验收
新增 visual_route `gauntlet_reward` / `gauntlet_defeat`（+ 已有 loadout/interlude），wired 全链自跑 macOS visual_capture 目检 1280×720 / 1440×900。

## 6. 红线 / 约束
- 数值全 TODO(batch3-probe)，本片零调平衡。
- Isar 嵌套 writeTxn 死锁：settleStageResult 内不调自开 txn 的 service（inline，同 chooseReward/settleDefeat）。
- 异步 config flag vs 控制器 final 字段竞态（`feedback_flutter_async_config_race_controller_final`）：flow 层 config 经 provider watch，不构造期定死。

## 7. 恢复点
- 状态：设计已批（xhigh / 全屏一起建 / gate 三拍 · 2026-07-17）。
- 下一步：writing-plans 出 TDD 切片 plan → 逐片实装。
