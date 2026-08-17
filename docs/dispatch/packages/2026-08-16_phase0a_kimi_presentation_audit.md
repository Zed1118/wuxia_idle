# Phase 0A 表现层补齐审计派单（Kimi）

## 目标

基于 `5a107a5b` 已通过用户实测的 Phase 0A 水墨 ARPG 切片，盘点正式美术、音效和动作补齐需求，产出可直接拆单的优先级清单。本单只读审计，不实装玩家可见改动。

## 必读与基线

- 必读：`CLAUDE.md` §8.0/§8.2/§8.3、`GDD.md` §1 与战斗相关段、`docs/spec/rejected_task_registry.md`。
- 切片恢复点：`docs/superpowers/plans/2026-08-16-phase0a-combat-feel-slice.md`。
- 主要范围：`tools/phase0minus_probe/`、`assets/`、`lib/features/battle/`、现有音频后端与视觉验收文档。

## 交付物

1. 创建 `docs/superpowers/plans/2026-08-16-phase0a-kimi-presentation-audit.md`，写明目标、验收、切片和恢复点（≤150 行）。
2. 创建 `docs/audit/phase0a-presentation-gap-audit-2026-08-16.md`（≤80 行），至少覆盖：
   - 普攻/掌风、Q 聚怪、R 清场、敌人命中/死亡、精英破招、波次转场、HUD 状态七类反馈；
   - 每类的「现有可复用 / 当前占位 / 明确缺失 / 建议交付规格 / 优先级」；
   - 对应的精确文件路径和生产消费方，不得只写主观判断；
   - 1280×720 / 1440×900 验收要点与不得回退的性能/可读性约束；
   - 按 P0/P1/P2 排序的后续小切片，每片标明预计改动域和验收方式。
3. 所有计数、路径、依赖和“已有/未有”结论都须用仓库命令实测；报告列出核心复现命令。

## 明确不做

- 不生成、替换或批量转码任何美术/音频资产。
- 不修改 Dart、YAML、依赖、数值、战斗逻辑、GDD 或玩家可见 UI。
- 不执行根应用生产接线，不跑 Windows Gate，不组织六人 Gate。

## 执行端禁区（逐项强制）

- 禁改 `data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/l10n/strings.dart`、`pubspec.yaml`。
- 禁 push、禁 merge、禁碰 main、禁 revert，只写自己的 worktree。
- 不得安装软件、依赖或改动本机环境。

## 冻结与出口

- commit message 用中文动宾；完成后 tip 以 `[READY]` 开头且 worktree 干净。
- 如需拍板新美术方向、新音频依赖、玩家可见语义或战斗规则，只写选项与证据，tip 标 `[BLOCKED]`，禁止代拍。
- 验收：派单方会独立复查路径/计数、`git diff --check`、越界文件、tip 与工作区状态。
