# Phase 0B 遭遇编排与统一事件输出(Qoder 执行)

> 日期:2026-08-14 · 分支:`feat/phase0b-qoder-encounter-events`(worktree 隔离)
> 状态:进行中。目标是把现有 playable domain 做成「可确定性回放的遭遇编排 + 统一事件输出」,为后续把 Kimi HUD(feedback draft)接到真实玩法状态做准备。不是 Gate、不是 Phase 0C、不是正式生产。

## 1. 目标与边界

在 `tools/phase0minus_probe/lib/phase0b/encounter/` 新增纯 Dart 的遭遇编排层:orchestrator + snapshot + 中性事件模型,驱动既有 `DraftEnemyGroupSim`、`DraftBossBrain`、`DraftStyleProfile`(**以仓内真实 API 为准,不复制第二套规则**),固定 seed + 固定 dt 时事件序列完全一致。

**隔离红线**:

- 只改 `tools/phase0minus_probe/` 与本计划文件;不触碰根 `lib/`、`data/`、`test/`、根 `pubspec.yaml`、GDD/CLAUDE/PROGRESS/BACKLOG;不调用 Jarvis。
- **不直接依赖 `lib/phase0b/feedback/`**(避免 playable/encounter ↔ feedback 双向耦合);encounter 输出中性字段,由未来接线切片映射到 FeedbackEvent。
- 不写文件、不持久化、不接 ResultWriter/Gate writer/human gate;`gate_eligible=false` 口径不变。
- 不实现 `rejected_task_registry.md` 中已否的「敌方连环窗口链」与「敌方集火对称化」;编排层不新增目标选择逻辑。
- 保持 readability pocket 与最大并发预兆约束(由既有 sim 执行,编排层不削弱、不重复实现)。
- 初稿数值不扩正式配置,全部沿用 `PlayableDraftTuning` 与 `DraftStyleProfile` 既有 probe 本地常量。

## 2. 设计要点

### 2.1 新文件(`lib/phase0b/encounter/`,纯 Dart、可单测、确定性)

- `encounter_events.dart` — 中性事件模型(sealed class,字段稳定、无文案):
  - `EncounterStarted`(time/seed/style)
  - `EnemyEntered` / `EnemyTelegraphStarted` / `EnemyStrikeResolved`(hitHero/damage)/ `EnemyRetreated`(groupId/enemyId)
  - `EnemyDamaged`(damage/defeated)
  - `BossTelegraphStarted`(shape circle|arc、center/radius/halfArc/direction)、`BossStrikeResolved`(slam|sweep、hitHero、damage)、`BossPhaseChanged`(phase/total)、`BossExhaustedStarted`、`BossDamaged`、`BossDefeated`
  - `HeroDamaged`(amount/healthAfter)、`HeroResourceChanged`(qi delta/value)、`HeroStyleChanged`
  - `GroupCleared`(groupId)
  - `BattleConcluded`(victory|defeat)
  - `LootRequested`(sourceId;**只请求,不生成正式奖励**,无物品生成逻辑)
  - 每个事件带 `time`(tick 时间)与稳定 `signature`(供确定性比对)。
- `encounter_snapshot.dart` — 中性快照:hero health/qi/style/position、boss phase(1-based)/health/state/当前危险区(telegraph 形状与窗口)、每组存活数与预兆中数、并发预兆总数、战斗结果。
- `encounter_script.dart` — 回放脚本:`ScriptCommand { at, moveBy(dx) | castGather | castClear | setStyle }`;basic 攻击按流派 `basicInterval` 自动节奏(与既有 readout 一致),aim 固定向东。
- `encounter_orchestrator.dart` — 编排器:
  - 构造:`seed`、初始流派、英雄起点、遭遇 setup(组:count/seed/cameraLeft/激活时机;Boss:spawn)。
  - `advance(dt)`:按序消费脚本指令 → 各组 `DraftEnemyGroupSim.advance` → Boss `advance` → 英雄自动 basic/气韵 → 依据状态迁移发事件(前后状态 diff,不在 sim 内加逻辑)。
  - 流派差异全部经既有 API:surge=applyPull/圆形清场;sinister=applySlowField/直线清场/内伤 DoT(`draftInternalInjuryTick`)。
  - Boss 击败 → `LootRequested(sourceId)` + `BattleConcluded(victory)`;英雄血量归零 → `BattleConcluded(defeat)`;结束后 advance 为 no-op。
  - `runScripted(dt, seconds)` 辅助:一次性跑完返回全部事件(测试与回放入口用)。

### 2.2 可观察脚本入口(不做视觉大改)

- `phase0b_playable_draft_app.dart` 增加一个 `REPLAY SCRIPT` 按钮:用固定 seed/脚本同步跑完编排器,状态行显示结果(victory/defeat、事件数、命中/受击统计)。不新增页面、不改布局结构、不写任何文件。

### 2.3 测试(`test/phase0b/encounter/`)

1. **确定性**:同 seed + 同 dt + 同脚本,两次运行事件序列(逐条 signature)与逐步快照完全一致;异 seed 布局不同。
2. **状态转换**:敌人入场→预兆→攻击→退让顺序成立;Boss phase 1→2→击败事件链成立;两流派同脚本输出可区分(普攻节奏、清场形状、内伤/缓速事件)。
3. **红线/隔离**:整场口袋不穿入;并发预兆 ≤ 令牌上限;无连环窗口链/集火(目标恒为主角当前位置、无目标状态读取);encounter 源不 import feedback/、无 dart:io/Isar/result_writer/gate 字样。
4. **非 Gate**:不写结果文件;app 入口保持 NOT FINAL / `gate_eligible=false` 文案;`playable_draft_mode_test` 既有约束不回归。

## 3. 验收清单

- [ ] `dart format` 无 diff;`flutter analyze --no-pub` 0 issue(tools/phase0minus_probe)。
- [ ] 新增 encounter 测试全绿;probe 全量 `flutter test --no-pub` 全绿(基线 162)。
- [ ] 固定 seed + dt 双跑事件序列逐条一致(测试证明)。
- [ ] 事件/快照字段中性稳定:hero health/resource/style、danger telegraph、boss phase/health、enemy hit/defeat、battle result、loot request(只请求)。
- [ ] 编排层驱动既有 sim,无第二套规则;无连环窗口链/集火对称化;口袋与并发预兆约束保持。
- [ ] encounter 源零 `feedback/` 依赖、零文件写入、零 Gate 接线。
- [ ] 隔离:根 `lib/`、`data/`、`test/`、根 `pubspec.yaml` 零改动(`git status` 证明)。
- [ ] 工作区干净,tip commit `[READY]` 前缀。

## 4. 任务切片

| # | 切片 | 状态 |
|---|---|---|
| 1 | 计划文件 | 完成 |
| 2 | encounter_events + snapshot + script 模型 | 待做 |
| 3 | orchestrator + 确定性测试 | 待做 |
| 4 | 状态转换/红线隔离/非 Gate 测试 | 待做 |
| 5 | playable app 脚本回放入口 + README 一句 | 待做 |
| 6 | format/analyze/全量测试 + 恢复点收口 + [READY] | 待做 |

## 5. 当前恢复点

- 状态:切片 1 完成,准备进入切片 2。
- 最后完成:AGENTS/CLAUDE §5 §7 §8、0B 规格、rejected registry、playable/feedback 实现与测试、隔离契约通读;基线 analyze + 全量测试验证中。
- 下一步:写 `encounter_events.dart` / `encounter_snapshot.dart` / `encounter_script.dart`。
- 已跑验证:基线 `flutter analyze --no-pub` 与 `flutter test --no-pub` 跑动中(结果待回填)。
- 阻塞项:无。
