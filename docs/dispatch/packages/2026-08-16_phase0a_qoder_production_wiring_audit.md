# Phase 0A 根应用生产接线审计派单（Qoder）

## 目标

基于 `5a107a5b` 已通过用户实测的 Phase 0A 水墨 ARPG 切片，追踪根应用现有战斗入口、状态、结算、配置和存档边界，产出不保留旧 3v3 交互假设的最小生产接线方案。本单只读审计，不实施生产代码。

## 必读与基线

- 必读：`CLAUDE.md` §5/§8.0/§8.2/§8.3、`GDD.md` §1/§2.1/§5、`docs/spec/rejected_task_registry.md`。
- 切片恢复点：`docs/superpowers/plans/2026-08-16-phase0a-combat-feel-slice.md`。
- 主要范围：`tools/phase0minus_probe/lib/gameplay/`、`lib/features/battle/`、`lib/features/stage/`、战斗 providers/services/models、`data/` 的战斗相关 schema 及相关测试。

## 交付物

1. 创建 `docs/superpowers/plans/2026-08-16-phase0a-qoder-production-wiring-audit.md`，写明目标、验收、切片和恢复点（≤150 行）。
2. 创建 `docs/audit/phase0a-production-wiring-audit-2026-08-16.md`（≤100 行），至少覆盖：
   - 根应用真实入口→组队/关卡→战斗状态→胜负结算→掉落/存档的精确链路；
   - probe 中可迁移的纯规则/组件、必须重写的隔离实现、绝不应进生产的 replay/profile/human-gate 工具；
   - 旧 3v3 战斗假设的残留位置与影响面，不得默认继续测试或保留 3v3 交互；
   - 一条最小、可回退、可分步验证的生产接线路线，每步列精确文件域、消费方、测试和停止条件；
   - 对数值红线、三系锁死、在线=离线、存档/schema、结算一致性的影响矩阵；
   - 尚未有仓库真相源支撑的决策项，只列选项/证据/推荐，不代拍。
3. 用结构搜索或 `rg` 验证每个入口、调用方和计数；报告列出核心复现命令。

## 明确不做

- 不修改根应用 Dart、YAML、schema、存档版本、数值、玩家可见 UI 或 probe 实现。
- 不在根应用中并存第二套隐藏战斗规则，不用新 demo 代替生产接线。
- 不执行合并、rebase、push、依赖安装或本机环境改动。

## 执行端禁区（逐项强制）

- 禁改 `data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/l10n/strings.dart`、`pubspec.yaml`。
- 禁 push、禁 merge、禁碰 main、禁 revert，只写自己的 worktree。
- 不得安装软件、依赖或改动本机环境。

## 冻结与出口

- commit message 用中文动宾；完成后 tip 以 `[READY]` 开头且 worktree 干净。
- 遇到 GDD 与用户已拍板战斗方向冲突、需要 schema/数值/存档决策、或无法从仓库证明生产边界时，完成可完成的审计后用 `[BLOCKED]` 冻结，禁止自作主张。
- 验收：派单方会独立复查调用链/计数、`git diff --check`、越界文件、tip 与工作区状态。
