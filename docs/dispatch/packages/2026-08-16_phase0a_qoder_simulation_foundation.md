# Phase 0A 纯 Dart 战斗模拟基础首片（Qoder）

## 目标

把 probe 中已经策略/真机验证的最小战斗几何规则迁入根应用纯 Dart domain，作为后续确定性 simulation reducer 的无 Flame 基础。本片不是完整战斗引擎，不接生产入口、UI、结算、YAML 或存档。

## 必读

- `CLAUDE.md` §5/§8.0/§8.2/§8.3/§9，`GDD.md` §2.1/§5，`docs/spec/rejected_task_registry.md`。
- `docs/audit/phase0a-production-wiring-audit-2026-08-16.md`。
- 参考实现：`tools/phase0minus_probe/lib/gameplay/combat_rules.dart`与其 `combat_rules_test.dart`。

## 实装范围

1. 先创建 `docs/superpowers/plans/2026-08-16-phase0a-qoder-simulation-foundation.md`（≤150 行），写清目标、验收、小切片和恢复点。
2. 新建 `lib/features/battle/domain/phase0a/`，只实现以下经证实规则：
   - 不依赖 `dart:ui`/Flutter/Flame 的不可变二维坐标值对象，零向量安全归一化；
   - 四向输入的对角线移动归一化；
   - 目标同时满足距离与朝向扇区的判定，零朝向默认向右的既有语义须保持；
   - 聚怪目标点落在以玩家为中心的可读环上，已在环内者不被推走；
   - 精英破招窗口只是预告末段（remaining > 0 且 <= window）。
3. 数值必须由调用方显式传入；生产 Dart 不得提供 probe 数值默认值，不新增 `GameplayTuning` 副本。
4. 在 `test/features/battle/domain/phase0a/` 加直接单测，至少覆盖：对角归一化、反向/超距目标、零朝向、聚怪环内/环外、破招三个边界；加源码契约测防 Flame/Flutter/probe import 与数值默认值回流。
5. 符号命名不得继续使用 `Gameplay*`/`probe*`，改为根应用 Phase 0A domain 语义。

## 验收

- 先用旧实现语义写测试，再实现；记录一个可证明测试有判别力的局部破坏证红。
- `dart format`；`flutter analyze --no-pub`；新增 targeted tests；相关 probe `combat_rules_test.dart` 仍绿。
- 如认为需要更大状态 reducer、新 YAML/schema/公共 API 或生产接线，立即停止扩展，在恢复点记下后续片，不得顺手实装。

## 明确禁区

- 禁改 `data/numbers.yaml`、任何 YAML、`GDD.md`、`PROGRESS.md`、`lib/l10n/strings.dart`、`pubspec.yaml`、schema/saveVersion。
- 禁改旧 3v3 文件、生产入口、UI、结算、probe 源码、玩家可见行为。
- 禁安装依赖/软件，禁 push/merge/rebase/revert/碰 main，只写自己 worktree。

## 冻结出口

- commit message 中文动宾；完成后 tip 以 `[READY]` 开头、worktree 干净。
- 结果必带 §8.2 四证据：生产域落点、精确验证命令/通过数、红线影响、残留风险。
