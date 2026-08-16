# Phase 0A 根应用生产接线审计计划（Qoder）

## 目标

基于 `5a107a5b` 已通过用户实测的 Phase 0A 水墨 ARPG 切片，追踪根应用现有战斗入口、状态、结算、配置与存档边界，产出不保留旧 3v3 交互假设的最小生产接线方案。本单只读审计，不实施生产代码。

## 分支与执行域

- 分支：`audit/phase0a-qoder-production-wiring`（worktree `phase0a-qoder-production-wiring-audit`）
- 只写本 worktree 内的两份交付文档；不触根应用 Dart / YAML / schema / 存档版本 / 数值 / UI / probe 实现。
- 执行端禁区：禁改 `data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/l10n/strings.dart`、`pubspec.yaml`；禁 push / merge / 碰 main / revert；不装软件不改本机环境。

## 验收标准

1. 计划文件（本文件）含目标、验收、切片与恢复点，≤150 行。
2. 审计报告 `docs/audit/phase0a-production-wiring-audit-2026-08-16.md` ≤100 行，覆盖：
   - 根应用真实入口→组队/关卡→战斗状态→胜负结算→掉落/存档的精确链路；
   - probe 可迁移纯规则、必须重写的隔离实现、绝不应进生产的 replay/profile/human-gate 工具；
   - 旧 3v3 假设残留位置与影响面（不得默认保留 3v3 交互）；
   - 最小、可回退、可分步验证的生产接线路线（每步列文件域、消费方、测试、停止条件）；
   - 数值红线 / 三系锁死 / 在线=离线 / 存档 schema / 结算一致性影响矩阵；
   - 未有仓库真相源支撑的决策项只列选项/证据/推荐，不代拍。
3. 每个入口、调用方与计数经结构搜索复核，报告附核心复现命令。
4. 冻结：tip 以 `[READY]`/`[BLOCKED]` 开头、worktree 干净、`git diff --check` 通过。

## 必读基线

- `CLAUDE.md` §5（红线）/ §8.0（可恢复任务）/ §8.2（交付门槛）/ §8.3（就绪信号）。
- `GDD.md` §1（定位：半横版 3v3 自动战斗）/ §2.1（反主流）/ §5（战斗数值与公式）。
- `docs/spec/rejected_task_registry.md`：已否项不得复活（本审计未引入任何已否方向）。
- 切片恢复点：`docs/superpowers/plans/2026-08-16-phase0a-combat-feel-slice.md`（2026-08-16 用户拍板切片可进评审/合并/后续推进；声明「本切片不代表根应用生产接线完成」）。

## 任务切片

1. ✅ 读必读文档与切片恢复点，确认范围与禁区。
   - 注：派单范围写的 `lib/features/stage/` 在仓库中不存在；战斗装配实际在 `lib/features/battle/application/stage_battle_setup.dart`，关卡内容在 `lib/features/mainline/` + `data/stages.yaml`。
2. ✅ 追踪生产战斗链路：BattleScreen 挂载点 6 处（生产 4 + 调试 2）、runStageFlow 调用方 4 处、BattleResolutionService.resolve 生产调用 4 处、存档边界（20 collection / saveVersion 0.39.0）。
3. ✅ 盘点 probe：`combat_rules.dart`（326 行，import flame，非纯 Dart）/ `gameplay_game.dart`（2085 行，extends FlameGame）/ 探针基建目录清单；probe 与根应用双向零代码依赖。
4. ✅ 撰写审计报告（含最小接线路线、影响矩阵、决策项）。
5. ✅ 复核验证 + 冻结提交。

## 关键审计结论摘要

- 根应用战斗为 actionPoint 时间行动制 + seeded 确定性 RNG（`BattleNotifier` + `BattleStrategy` 三实装）；probe 为 Flame 实时 ARPG。二者驱动模型、数值体系（probe 固定伤害 vs 根内力/装备攻击公式）、胜负判定完全不同构。
- 根应用 CLAUDE.md §9 明文禁引入 Flame 等第三方游戏引擎 → probe 的 `GameplayGame` 不可直接迁移，必须纯 Flutter 重写；纯规则可剥离 flame 依赖后迁移。
- GDD §5.1 仍定义战斗形态为「半横版队伍战 3v3」，与用户已拍板的 Phase 0A 水墨 ARPG 方向存在设计层冲突 → 本审计不代拍，列入决策项。
- 3v3 硬编码残留 10+ 处（装配/编成/镜像/派遣/UI 站位/塔 schema 红线），详见审计报告。

## 当前恢复点

- 状态：审计完成，报告已产出；因含 GDD 形态冲突与引擎/数值/schema 级决策项，tip 以 `[BLOCKED]` 冻结待拍板。
- 最后完成：两份交付文档写完；入口计数（BattleScreen 6 挂载 / runStageFlow 4 调用 / resolve 4 生产调用）、3v3 残留、probe 隔离均经 rg 复核。
- 下一步：派单方独立复查调用链/计数 → 用户对审计报告 §6 决策项拍板 → 另行派实施单。
- 已跑验证：`git diff --check` 干净；越界文件零（仅新增 2 份 docs）；未装任何依赖。
- 阻塞项：审计报告 §6 的 4 项决策（引擎选型 / GDD §5.1 形态口径 / 数值接线分层 / 无头自动刷表达）需用户拍板。
