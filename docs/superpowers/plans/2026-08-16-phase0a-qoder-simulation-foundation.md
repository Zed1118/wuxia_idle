# Phase 0A 纯 Dart 战斗模拟基础首片计划（Qoder）

## 目标

把 probe（`tools/phase0minus_probe/lib/gameplay/combat_rules.dart`）中已经策略/真机验证的最小战斗几何规则迁入根应用纯 Dart domain（`lib/features/battle/domain/phase0a/`），作为后续确定性 simulation reducer 的无 Flame 基础。本片不接生产入口、UI、结算、YAML、存档。

依据：`docs/audit/phase0a-production-wiring-audit-2026-08-16.md` §2（combat_rules 可迁移须去 flame 化）、§4 路线第 1 步、§6 已确定边界（引擎锁纯 Flutter、probe 固定数字不直迁）。

## 分支

`feat/phase0a-qoder-simulation-foundation`（本 worktree）。

## 实装范围（只迁已证实规则，符号去 `Gameplay*`/`probe*` 前缀）

1. 不可变二维坐标值对象（不依赖 `dart:ui`/Flutter/Flame），零向量安全归一化（零→零）。
2. 四向输入对角线移动归一化（保持 probe 语义：`length2 > 1` 才归一、y 轴向下为正）。
3. 距离 + 朝向扇区双条件判定（保持：超距 false / 原点目标 true / 零朝向默认向右 (1,0) / `acos ≤ halfArc` 闭区间）。
4. 聚怪目标点落玩家中心可读环（保持：环内 `length2 <= r²` 者原样不被推走；环外投影到环上）。
5. 精英破招窗口 = 蓄力预告末段（`remaining > 0 && remaining <= window`，窗口秒数由调用方传入）。

**数值纪律**：所有数值必须 required 参数显式传入；生产 Dart 零 probe 数值默认值；不新增 `GameplayTuning` 副本、不接 YAML。

## 验收标准（§8.2 转 checklist）

- [ ] TDD：先按旧实现语义写测试再实现；记录一次局部破坏证红（改坏一行→必红→复原）。
- [ ] 单测覆盖：对角归一化 / 反向与超距目标 / 零朝向默认向右 / 聚怪环内与环外 / 破招三边界。
- [ ] 源码契约测：禁 `dart:ui`/`package:flutter`/`package:flame`/probe import 回流；禁 `Gameplay*`/`probe*` 符号；禁数值参数默认值。
- [ ] `dart format` 干净；`flutter analyze --no-pub` 0 issue（本切片文件）。
- [ ] 新增 targeted tests 全绿；probe `test/gameplay/combat_rules_test.dart` 仍绿。
- [ ] 生产接线证据（本片段径）：落点 = `lib/features/battle/domain/phase0a/`，为审计 §4 第 1 步 simulation core 首块；当前无生产消费方是有意（后续片接 reducer）。
- [ ] 禁区自查：不改任何 YAML / GDD / PROGRESS / strings / pubspec / schema / 旧 3v3 / probe 源码；不装依赖；只写本 worktree。
- [ ] 冻结：tip `[READY]` 前缀 + worktree 干净 + commit message 中文动宾。

## 任务切片

1. **S1 计划文件**（本文档）。commit：计划落档。
2. **S2 测试先行**：写 `test/features/battle/domain/phase0a/` 行为单测 + 源码契约测；运行记录编译红（规则文件尚不存在）。
3. **S3 实装**：`lib/features/battle/domain/phase0a/arena_vector.dart`（值对象）+ `realtime_combat_rules.dart`（四规则函数）。测试转绿。
4. **S4 证红**：局部改坏一行（如破招 `<=` 改 `<`），跑 targeted 记录红，复原再绿。
5. **S5 冻结**：`dart format`、`flutter analyze --no-pub`、targeted + probe 回归，更新本恢复点，`[READY]` commit。

## 停止条件（触发即停，恢复点记后续片，不得顺手实装）

- 需要更大状态 reducer / 新 YAML / schema / 公共 API / 生产入口接线 → 记入「后续片」。
- 发现 probe 语义与根红线冲突 → 停下问人类。

## 后续片（本片不做，仅登记）

- 确定性 simulation reducer（tick/输入适配器同核，审计 §4 第 1-2 步）。
- 数值接根配置层（新 yaml 段须 schema + 红线 validator，审计 §4/§6）。
- 同种子手动/AI 一致性回归、表现层纯 Flutter 重写。

## 当前恢复点

- 状态：已冻结待评审（tip `[READY]`，worktree 干净）。
- 最后完成：S1–S5 全部完成。落点 `lib/features/battle/domain/phase0a/{arena_vector.dart, realtime_combat_rules.dart}` + `test/features/battle/domain/phase0a/{realtime_combat_rules_test.dart, phase0a_source_contract_test.dart}`。符号：`ArenaVector` / `normalizeMovementInput` / `isTargetInsideStrikeArc` / `gatherRingDestination` / `isEliteBreakWindowOpen`，无 `Gameplay*`/`probe*` 前缀、无数值默认值。
- 证红记录：① 初始红——实现不存在时 `flutter test --no-pub test/features/battle/domain/phase0a/` 6 红（行为测编译失败 + 契约测目录缺失）；② 局部破坏证红——把破招窗口上界 `<=` 改 `<`，「恰好等于窗口长度的上界按闭区间可破」立即红（Actual: false），复原后 24/24 绿。
- 已跑验证：`flutter test --no-pub test/features/battle/domain/phase0a/` 24/24 pass；probe 回归 `cd tools/phase0minus_probe && flutter test test/gameplay/combat_rules_test.dart` 8/8 pass；`dart format` 无改动；`flutter analyze --no-pub` No issues found（首跑 1943 条全为 fresh worktree probe 未 pub get 的既有噪声，`flutter pub get --offline` 解析其已锁依赖后归零，未新增任何依赖）。
- 阻塞项：无。残留风险：本片段当前无生产消费方（有意，后续 reducer 片接入）；y 轴向下为正的屏幕坐标口径已写入 `ArenaVector` 文档注释，后续 reducer/表现层须沿用。
