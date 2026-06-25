# 一键挂机扫荡 · design

> 阶段：1.0 长线打磨期 · 挂机流程 QoL
> 范围：新增「一键扫荡」——整章主线 / 整座 30 层塔自动快速连播打完，前提本周目已手工首通。
> 红线自检：✅ 非快进券（真跑每场战斗·不压缩离线时间）/ ✅ 守 §5.7（首通后才解锁）/ ✅ 守 §5.5（在线=离线）/ ✅ 数值走 numbers.yaml / ✅ 文案走 UiStrings。

## 1. 需求（用户拍板）

- 一键自动打完**主线一整章** 或 **一整座 30 层塔**。
- **门槛**：该单位本周目所有关卡已首通（未全清→按钮灰/隐）。
- **执行**：快速连播、可中途停（用户拍板，非瞬时黑箱结算）。
- **战败处理**：停在该关，报「扫到第 N 关战败 + 原因」（伤势/内力累积致败）。
- **掉落**：照常掉落（走标准结算；扫荡恒为已首通重打 → 自然走重打掉落规则，秘籍不补）。
- **入口按钮做明显**（章节 header / 塔屏顶部醒目主按钮，非角落小图标）。

## 2. 边界（不做 / 留后）

- 扫荡**只重打已清内容**：不推进未通关、不触发首通、不解锁新周目 —— 纯 re-farm。
- 不新增加速道具 / 不改离线收益 / 不动战斗数值或 16 项「形与势」战斗轴。
- 副本类（心魔/轻功/群战）一期不做扫荡，仅主线章 + 爬塔（用户原话两类）。

## 3. 现状复用（Phase 0 已核 · file:line）

| 复用点 | 位置 | 用途 |
|---|---|---|
| 首通/周目追踪 | `mainline_progress.dart:37` clearedStageCycleKeys · `tower_progress.dart:27/57` highestClearedFloor/currentCycleIndex | 算门槛 + 范围 |
| chapterKey | `mainline_progress_service.dart:200` chapterKeyForStage | 章→关枚举 |
| 纯函数结算 | `battle_resolution.dart:101` BattleResolutionService.resolve | 战果副作用（脱 UI） |
| 纯函数掉落 | `drop_service.dart:68` rollDrops / rollTowerRewards | 掉落 |
| 自动战斗 | `auto_play_mode.dart:8` AutoPlayMode.auto | 战斗已能无输入连播 |

**待抽**：`stage_entry_flow.dart:716 _applyVictoryResolution`（结算副作用 + UI 返回 record 耦合）→ 抽出**纯结算 service**（ref-free，返回副作用摘要），正常 flow 与扫荡共用。塔侧 `tower_entry_flow` 同理。

## 4. 架构（4 层）

### ① 纯逻辑层 `SweepPlan`（可测·无 Flutter 依赖）
- `SweepUnit`：一个扫荡单位（chapter / tower），含有序 `stageRefs`（主线 StageDef 列表 / 塔 floor 列表）。
- `SweepEligibility.forChapter(progress, chapterKey, cycle, stages)` → bool（章内每关 cycleKey 都在 cleared → 可扫）。
- `SweepEligibility.forTower(towerProgress)` → bool（highestClearedFloor==30 → 本周目整塔已通 → 可扫）。
- 纯函数，TDD 红线锁门槛语义（部分清不可扫 / 全清可扫 / 新周目重置）。

### ② 结算 service（抽共享 · ref-free）
- `StageVictorySettlement.settle(...)` / `TowerVictorySettlement.settle(...)`：入 finalState + 参战角色/装备/心法 + def，做 resolve + 掉落 + 经验 + 伤势 + 进度记录 + writeTxn，返回 `SettlementSummary`（drops/silver/exp/advancements/injuryDelta）。
- 正常 flow 改为调此 service + 自行 shape UI dialog record（零行为回归，旧测兜底）。
- 扫荡循环每关调同一 service。

### ③ 驱动层 `SweepRunner`（UI 协调 · 状态机）
- 输入 `SweepUnit` + 加速倍率。循环：`for unit in stageRefs`：
  1. 装配队伍 + 启动战斗（AutoPlayMode.auto 强制·跳关间剧情/仪式）。
  2. 加速 tick 跑到 terminal（注入 `sweep.action_interval_ms` 覆盖正常节奏）。
  3. victory → 调结算 service，累加 `SweepRecap`，进下一关。
  4. defeat → halt，记 `stoppedReason = defeated(stageIndex)`。
  5. 每 tick 检 `stopRequested` 标志 → 用户停则 halt，记进度。
- 不触发首通/不解锁周目（恒重打路径）。

### ④ UI 层
- `SweepScreen`：连播中显当前关 X/N + 实时 recap 累加 + 常驻「停止」按钮（醒目）。结束/停/败 → `SweepRecapDialog`（总掉落/银两/经验/升层/伤势变化·数字跳动复用桃花岛纪事体例）。
- **入口（明显）**：① 主线选关屏章节 header 区一枚醒目「一键扫荡本章」主按钮（`stage_list_screen.dart`，eligible 才亮）；② 塔屏顶部「一键扫荡 30 层」主按钮（`tower_screen.dart`）。未 eligible → 灰显 + tooltip「需本周目通关全部关卡」。

## 5. 数值（numbers.yaml 新增 `sweep` 段）

- `sweep.action_interval_ms`（连播加速节奏·初值 ~250ms，正常 1000）。
- `sweep.inter_battle_gap_ms`（关间过场·初值 ~150ms）。
- schema 校验 + `AnimationNumbers` 同步（连带规约见 §九战斗节奏）。

## 6. 红线 / 风险

- **§5.5 在线=离线**：扫荡真跑战斗、按真实战果结算，只是快放动画 + 省手点；不压缩离线时间、不发券。✅
- **§5.7**：门槛=本周目手工首通，先感受再省事。✅
- **回归风险**：抽 `_applyVictoryResolution` 是改动既有关键路径 → 用既有 stage/tower flow 测兜底，行为零变更（纯提取）。
- **伤势螺旋**：扫荡恒重打、恒接伤势（与正常重打一致）；塔 Boss 战败不接重伤沿用既有拍板。

## 7. 验收

- 门槛单测（章/塔 eligibility 全分支）。
- 结算抽取零回归（既有 flow 全测过）。
- recap 聚合单测。
- 连播 + 停 + 战败 halt 行为测（驱动层 notifier 级，参 battle 确定性测体例）。
- analyze 0 / 全量无回归。GUI 手感本环境 headless 抓不到 → 留用户副屏目检。
