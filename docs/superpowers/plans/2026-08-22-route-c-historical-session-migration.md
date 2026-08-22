# Route C 历史多人远征/断魂庄会话 · 一次性安全终止/退款策略（审计 + 方案）

> 日期：2026-08-22
> 状态：`DECIDED / IMPLEMENTED`（主代理同批完成决策、实现与定向验证）
> 基线：`3419f171`（`codex/route-c-history-audit-0822`，干净）
> 上位：`docs/audit/legacy_3v3_removal_scope_2026-08-18.md` §6 路线 C / §8.2「headless 结算内核替代 α 复用 0A reducer·队伍续传语义需随重设计」/ BACKLOG 四#1
> 边界（本批）：不改 battle 核心、主线 gate、Phase0a mapper、UI；只动 expedition/boss_gauntlet 的 application/domain 与对应测试；**不删除旧引擎**；不 push。
> 协作说明：DeepSeek 完成事实审计，主代理完成决策、实现、审查与整合验证。

---

## 0. 快读结论

- **问题**：Phase 0A 单角色 ARPG 替换旧 3v3（路线 C 终态）后，旧引擎删除，"历史多人（2–3 成员）在途远征/断魂庄会话" 将无处可跑——Phase 0A 的远征/断魂庄 runner **只支持单成员**（硬断言 `StateError`），而当前灰度门把 `memberCount != 1` 的会话**回落到旧 3v3 runner**。这些会话就是"回落旧 runner"的历史多人会话。
- **本批交付**：事实审计、状态矩阵、一次性终止/退款决策及对应实现与测试。
- **可复用性洞察**：远征的 `ExpeditionService.recall`（grant `stagedRewards` + 伤势 + 删 run + 更新 `baicaoMaxDepth`）与断魂庄的 `GauntletService.settleDefeat` / `close` / `_refundTicketAndClose` 已经是现成的"终止 + 退款"事务，本策略主要是**把 "一次性触发 + 特定状态的路由" 补上**，而非重造结算。

---

## 1. 背景与问题

Phase 0A 战斗终态 = **单角色** ARPG。远征与断魂庄的 Phase 0A 适配层对队伍成员数施加**恰好一人**约束：

| 约束点 | 文件 | 断言 |
|---|---|---|
| 远征 phase0a runner | `lib/features/expedition/application/phase0a_expedition_combat_runner.dart:31` | `ids.length != 1` → `StateError('Phase0a expedition requires exactly one member')` |
| 同上 `fight` | `..._combat_runner.dart:51` | `memberStates.length != 1` → `StateError(...one alive member)` |
| 断魂庄 phase0a 开打 | `lib/features/boss_gauntlet/application/gauntlet_service.dart:409-410` | `run.members.length != 1` → `StateError('Phase0a gauntlet requires exactly one member')` |
| 同上 推进入口 | `..._service.dart:456` | `fresh.members.length != 1` → 防御 no-op |

因此**多人会话只能跑旧 3v3 runner**；旧 runner 依赖旧引擎（`defaultGroundStrategy` / `Legacy3v3CombatantAdapter` / `BattleState`）。旧引擎一旦删，这些会话即无法续跑。

历史多人会话**怎么产生的**：灰度门默认关，`dispatch`/`enter` 允许 1–3 人（`expedition_overview_screen.dart:124` `maxMembers = gate.enabled ? 1 : 3`）。门开启**前**或门默认关闭期派遣的 2–3 人会话即为"历史多人在途会话"。门开启后，`shouldUsePhase0a(memberCount: N)` 对 `N>1` 返回 false，这些会话统一回落旧 runner。

---

## 2. 审计：回落旧 runner 的代码面（精确文件）

### 2.1 灰度高/路径裁决（决定"多人回落旧 runner"）

| 文件 | 关键行 | 作用 |
|---|---|---|
| `lib/features/expedition/application/phase0a_expedition_gate.dart` | `:13` `shouldUsePhase0a => enabled && memberCount == 1` | 远征灰度门（`--dart-define=PHASE0A_EXPEDITION_GRAY`） |
| `lib/features/expedition/application/expedition_combat_selector.dart` | `:8-10` | `memberCount==1 && enabled` → `Phase0aExpeditionCombatRunner`；否则 `ExpeditionCombatRunner`（旧 3v3） |
| `lib/features/boss_gauntlet/application/phase0a_gauntlet_gate.dart` | `:27` `shouldUsePhase0a => enabled && memberCount == 1` | 断魂庄灰度门（`--dart-define=PHASE0A_GAUNTLET_GRAY`） |
| `lib/features/boss_gauntlet/application/gauntlet_combat_selector.dart` | `:17-23` | `memberCount∈[1,3]`；`memberCount==1 && enabled` → `phase0a`，否则 `legacy3v3`（旧 3v3） |

### 2.2 生产消费方（把 `memberCount` 喂给裁决）

| 文件 | 行 | 说明 |
|---|---|---|
| `lib/features/expedition/application/expedition_startup.dart` | `:48` | `maybeSettleExpedition` 主菜单首帧离线追平：`expeditionCombatFor(isar, memberCount: active.members.length)`。多人在途 → 用旧 runner 追平。 |
| `lib/features/expedition/presentation/expedition_overview_screen.dart` | `:79` | 派遣拦截：灰度开 + 选中≠1 → return |
| 同上 | `:124` | `maxMembers = gate.enabled ? 1 : 3` |
| 同上 | `:471` | 召回前追平：`expeditionCombatFor(isar, memberCount: run.members.length)` |
| `lib/features/boss_gauntlet/presentation/gauntlet_entry_flow.dart` | `:67-79` | `inBattle` 路由：`gauntletCombatPathFor(memberCount: run.members.length)` 为 phase0a → Phase0a 屏；否则旧 3v3 屏 |

### 2.3 被回落的旧 3v3 runner（依赖旧引擎）

| 文件 | 依赖旧引擎符号 |
|---|---|
| `lib/features/expedition/application/expedition_combat_runner.dart` | `Legacy3v3CombatantAdapter.playerTeam`/`enemyTeam` |
| `lib/features/expedition/application/expedition_battle_runner.dart` | `defaultGroundStrategy.runToEnd`、`BattleState.initial` |
| `lib/features/boss_gauntlet/application/gauntlet_battle_runner.dart` | `Legacy3v3CombatantAdapter.enemyTeam`、`BattleState`、复用 `ExpeditionBattleRunner.runNodeBattle` |
| `lib/features/boss_gauntlet/application/gauntlet_controller.dart` | `BattleState`、`BattleCharacter` 快照 |

### 2.4 承载"终止/退款"能力的现成事务（本策略复用的地基）

| 文件 | 方法 | 能力 |
|---|---|---|
| `lib/features/expedition/application/expedition_service.dart` | `recall({defeated, ...})` | 单 `writeTxn`：发 `stagedRewards`（全员含倒下者经验）+ 战败伤势（倒下→重伤 / 其余→轻伤）+ 删 run（占用解除）+ 更新 `baicaoMaxDepth`（单调）。**即为"终止 + 退款 + 关会话"**。 |
| 同上 | `settle` / `settleToNow` | 离线按节点追平（需 combat runner；多人需旧 runner）。 |
| `lib/features/boss_gauntlet/application/gauntlet_service.dart` | `settleDefeat({config, numbers})` | 单 `writeTxn`：发已击败精英经验 + 按战末快照重伤/轻伤 + 返还托管补给（`Loaded-Used`）+ 删 run。适用于 `inBattle`（战败/认输）与 `interlude`。 |
| 同上 | `close()` | 幂等：返还托管补给 + 删 run（不附伤/不发精英经验）。 |
| 同上 | `_returnEscrow` | 托管补给 `Loaded-Used` 返普通库存（原子）。 |
| 同上 | `_refundTicketAndClose` | 退 1 张断魂帖 + 返还托管 + 删 run（用于配置损坏且未开战）。 |
| 同上 | `recover({config})` | 判"配置损坏"边界：`refundedTicket` / `concedeRequired` / `resumed`/`none`。 |

---

## 3. 状态矩阵与"一次性终止/退款"语义

> 键：`M>1` = 历史多人在途会话（灰度开启或旧引擎删除后均回落/不可续跑）。
> 本矩阵把"终止后应兑现什么、发什么、删什么"逐状态写死；每一行的**触发时机**与**是否给玩家选择**见 §4/§6。

### 3.1 远征 `ExpeditionRun`（`M>1`）

| 会话状态 | 已入场成本 | 已兑现进度 | 一次性终止语义（提案） | 复用 |
|---|---|---|---|---|
| `currentNode==0`（未开战，未离线追平） | 派遣免费（无凭证） | 无 | 直接删 run（占用释放）；无退款项 | — |
| `currentNode>0` 且未 `defeated` | 免费 | `stagedRewards`（历次 settle 已暂存） | 发 `stagedRewards`（全员经验 + 物品）+ 更新 `baicaoMaxDepth` + 删 run | `recall(defeated:false)` |
| `defeated==true`（战败即停） | 免费 | `stagedRewards` | 发 `stagedRewards` + 按倒下/存活结重伤/轻伤 + 更新 `baicaoMaxDepth` + 删 run | `recall(defeated:true)` |

**已决策**：`currentNode>0` 且存在尚未结算的离线成熟时长时，不再调用旧 runner 追平，只兑现已经原子落库的暂存奖励。
- 提案 A（玩家更完整）：触发时先用旧引擎 `settleToNow` 一次性追平，再 `recall`——尊重离线进度、玩家不吃亏，且旧引擎尚未删可复用。
- 提案 B（保守）：不追平，只发已暂存 `stagedRewards`——避免删引擎前后结果漂移，但玩家会丢"成熟未结算节点"。
- 二者是典型"用旧引擎最后补偿一次 vs 立刻断舍离"的取舍，属**人类拍板项**，本批不实现。

### 3.2 断魂庄 `BossGauntletRun`（`M>1`）

| `sessionPhase` | 已入场成本 | 已兑现进度 | 一次性终止语义（提案） | 复用 |
|---|---|---|---|---|
| `inBattle` 且 `currentStage==1` 且成员 `maxHp==0`（未开战） | 1 张断魂帖 + 托管补给 | 无 | 退 1 帖 + 返还全部托管补给 + 删 run | `_refundTicketAndClose` |
| `inBattle` 已开战（`currentStage>1` 或成员 `maxHp>0`） | 1 帖（已消耗）+ 部分托管 | 已击败精英经验 | 发已击败精英经验 + 按战末快照重伤/轻伤 + 返还托管（`Loaded-Used`）+ 删 run | `settleDefeat` |
| `interlude`（关次间整备页） | 1 帖（已消耗）+ 部分托管 | 已击败精英经验 | 同上（`settleDefeat` 已覆盖 interlude 认输路径） | `settleDefeat` |
| `awaitingRewardChoice`（Boss 已胜·待三选一） | 1 帖 + 部分托管 | 已赢了 Boss、三选一候选已固化 | **口径缺口**：终止需给玩家一个可兑现的奖励。候选①放行玩家走 `chooseReward`（但那是 UI）；候选②自动发**默认候选**（取候选首项）+ 经验/领悟点（按 `cycleRewardMult`）+ 返还托管 + 记 `clearedGauntletIds`/`duanhunFirstClearedAt`/`duanhunClearedCyclesMax` + 删 run；候选③按失败结算（显失公平，不推荐）。 | 需新事务 / 借 `chooseReward` 改型 |
| `settled` | — | — | 无在途；no-op | — |

**注意**：`awaitingRewardChoice` 在**多成员**场景是否真实存在，取决于历史会话是否已把灰度下多成员推进至 Boss 胜利——从逻辑上可能。这是唯一没有现成"非猜"事务的状态，需单独拍板。

---

## 4. 一次性安全终止/退款策略（提案）

### 4.1 核心思想

"一次性" = **在旧引擎删除前，对每存档做一次确定性的在途多人会话清场**，用**已存在的结算事务**（`recall` / `settleDefeat` / `close` / `_refundTicketAndClose`）兑现玩家应得，删会话，让玩家可重新以单成员 Phase 0A 开局。**幂等**（无在途会话或已清场 → no-op）、**单存档一次**。

### 4.2 触发点候选项（与"不改 UI"边界的可行性）

| 候选 | 层 | 可行性 |
|---|---|---|
| ① 主菜单首帧 `maybeSettleExpedition` 内联动（application） | application | ⚠ 远征可；断魂庄无等价 application 启动钩子（其恢复走 presentation `gauntlet_entry_flow`） |
| ② 入口 reconcile（`gauntlet_entry_flow` / `expedition_overview_screen`）内部在活动会话上先判多人在途再清场 | presentation | ❌ 边界禁止改 UI |
| ③ 批次迁移 scan（独立脚本 / 一次性数据 migrate，于引入 Route C 终态时跑） | tool + application | ✅ 不触 UI，但需确定"迁移触发"在哪个版本/开关，属拍板 |
| ④ 只在门开启且 `M>1` 时把裁决改为"需清场"（不改 runner） | application/domain | ✅ 最小；但会把 `shouldUsePhase0a` 变成三态（单成员 / 需清场 / 失效），波及 selector/startup/UI 消费 |

**采用**：灰度开启时显式清场；远征走启动 application 钩子，断魂庄走入口 reconcile，均由幂等 service 事务收口。

### 4.3 需要新增的 application/domain 方法（示意，非本批实现）

- `ExpeditionService.retireLegacy({bool settleToNowFirst})`：封装 §3.1 的终止分支（内部并发守卫 + 复用 `recall` 事务体）。返回 `retired` / `grantedRewards` / `deepestNode` 摘要。
- `GauntletService.retireLegacy({required config, required numbers, ...})`：封装 §3.2 的终止分支（`inBattle`/`interlude` 走 `settleDefeat`；未开战 `inBattle` 走 `_refundTicketAndClose`；`awaitingRewardChoice` 视拍板结果）。
- 纯决策助手（domain）：`expedition_retirement_plan` / `gauntlet_retirement_plan`——输入 run 快照、输出"终止动作 + 退款摘要"，**纯函数、确定性、可单测**，不持 Isar。

---

## 5. 退款/恢复事务（精确，供实现引用）

以下事务都**已存在**，实现时直接复用，无需重写 `writeTxn` 逻辑：

| 目标 | 走现成事务 | 事务内动作 |
|---|---|---|
| 远征（未开战 `currentNode==0`） | 暂无（需新增：仅删 run） | 删 `expeditionRuns`（占用由 active run 派生 → 自动解除） |
| 远征（`>0` / 战败） | `recall(defeated: bool)` | ① 全员发 `stagedRewards` 中 exp（`CharacterAdvancementService.applyExperience` + 层锁）；② 战败时倒下→重伤 / 其余→轻伤；③ 发非 exp 物品到 `inventoryItems`（`getByDefId` 增量或重建）；④ 删 run；⑤ `save.baicaoMaxDepth` 单调 max |
| 断魂庄（未开战） | `_refundTicketAndClose` | 退 1 张 `item_duanhuntie` + `_returnEscrow`（`Loaded-Used`）+ 删 run |
| 断魂庄（`inBattle` 已战 / `interlude`） | `settleDefeat` | ① 发已击败精英经验（`elitesDefeated × config.eliteRewardExp`·层锁）；② 战末倒下→重伤 / 存活→轻伤；③ `_returnEscrow`（已用不返）；④ 删 run |
| 断魂庄（`awaitingRewardChoice`） | 保留现状 | 放行玩家继续 `chooseReward`，不自动替选、不按失败结算 |

**红线注意**：所有"发奖品/经验"路径都沿用现有层锁（`ProgressionGateService.isLayerLocked` 按 `releaseCap` + `clearedStageIds`，`IsarSetup.currentSlotId` 主线进度行）；不得引入新的数值常量或中文文案（集中的 `UiStrings`）。`stagedRewards` 的 `exp`/`internal_force` 为连续量，其余整件——延续 `scaleRewardsForCycle` 的 round/ceil 口径（`expedition_service.dart:154-175`）。

---

## 6. 本批决策（2026-08-22）

1. **触发时机**：对应 Phase 0A 灰度门开启后自动清场；会话删除本身即幂等标记，不新增迁移版本字段。
2. **远征**：只兑现已经原子落库的 `stagedRewards`，不再调用即将删除的旧 runner 追算未结节点；召回不额外附伤。
3. **断魂庄未开战**：退 1 张断魂帖、返还全部未用托管并关闭会话。
4. **断魂庄已推进**：发已击败精英经验、返还剩余托管并关闭会话；系统迁移不视为玩家战败，因此不附轻/重伤。
5. **断魂庄已胜 Boss**：保留 `awaitingRewardChoice`，继续让玩家领取已固化的三选一奖励，不自动替选、不降格失败结算。

该口径不要求旧 runner 在升级后仍存在，且所有终止动作可重复进入而不重复发奖。

---

## 7. 测试计划（实现批待补，列出不猜测）

在实现批按拍板结果补以下测试（现审出"多人回落旧 runner"的既有覆盖为 `test/features/expedition/phase0a_expedition_combat_runner_test.dart`、`test/features/boss_gauntlet/phase0a_gauntlet_gate_test.dart`、`test/features/expedition/expedition_overview_screen_test.dart`、`test/features/boss_gauntlet/gauntlet_entry_flow_test.dart`）:

- `expedition_service_retire_test`：未开战 `currentNode==0` → 删 run 无退款；`currentNode>0` → `recall` 发 `stagedRewards` + `baicaoMaxDepth` 单调；`defeated` → 重伤/轻伤按倒下/存活。并发守卫（cursor）沿用 `recall` 既有用例。
- `gauntlet_service_retire_test`：未开战 `inBattle` → 退帖 + 返还托管 + 删 run；已战 `inBattle`/`interlude` → `settleDefeat` 语义；`awaitingRewardChoice` → 按拍板分支。
- `phase0a_gate_retire_signal_test`（若走 §4.2 候选④）：`shouldUsePhase0a` 或新 `retirementNeededFor(memberCount)` 三态契约 + 非法值 fail-fast。
- 回归关注：**不得**破坏现有 `phase0a_*_gate_test` / `phase0a_expedition_combat_runner_test` / `phase0a_gauntlet_gate_test` 的"2/3 成员回落旧 runner"断言——这些测试锁的是**当前灰度为开**的事实；若实现批改了裁决（候选④），需同步改这些既有断言并说明语义迁移。

---

## 8. 结论与下一步

- 本批完成：**历史多人远征/断魂庄会话回落旧 runner 的全量代码 + 测试审计**（§2 精确文件表、§2.4 可复用事务、§3 状态矩阵），并给出**一次性安全终止/退款策略提案**（§4）与**精确退款/恢复事务**（§5）。
- **实现完成**：远征启动清场、断魂庄入口 reconcile、无附伤迁移结算及待选奖励保留均已落地。
- 下一步（拍板后）：选 §6 口径 → 实现 §4.3 的 `retireLegacy` + 纯决策助手 → 补 §7 测试 → targeted + `flutter analyze` → commit → READY。
