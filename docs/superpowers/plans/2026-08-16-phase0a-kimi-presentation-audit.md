# Phase 0A 表现层补齐审计计划（Kimi 只读）

## 目标

基于 `5a107a5b` 已通过用户实测的 Phase 0A 水墨 ARPG 切片，盘点正式美术、音效和动作补齐需求，产出可直接拆单的 P0/P1/P2 优先级清单。本单只读审计，不实装任何玩家可见改动，不生成/转码任何资产。

## 分支 / Worktree

- 分支：`audit/phase0a-kimi-presentation`（独立 worktree `.worktrees/phase0a-kimi-presentation-audit`）
- 基线：切片验收点 `5a107a5b`；本 worktree HEAD `8e1a23ab`（派单冻结 commit）
- 禁区：禁改 `data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/l10n/strings.dart`、`pubspec.yaml`；禁 push/merge/碰 main/revert；不装依赖。

## 验收标准

- 交付 `docs/audit/phase0a-presentation-gap-audit-2026-08-16.md`（≤80 行），覆盖普攻/掌风、Q 聚怪、R 清场、敌人命中/死亡、精英破招、波次转场、HUD 状态七类反馈，每类写明「现有可复用 / 当前占位 / 明确缺失 / 建议交付规格 / 优先级」，全部带精确文件路径与生产/消费方。
- 写明 1280×720 / 1440×900 双视口验收要点与不得回退的性能/可读性约束（帧预算、对象池、遮挡）。
- 给出按 P0/P1/P2 排序的后续小切片，每片标明预计改动域与验收方式。
- 所有计数、路径、"已有/未有"结论用仓库命令实测，报告附核心复现命令。
- 不越界：除本计划文件与审计报告外零文件改动；`git diff --check` 干净；完成后 tip 打 `[READY]`、worktree 干净。

## 任务切片

1. 读基线文档：CLAUDE.md §8.0/§8.2/§8.3、GDD.md §1/§5、`docs/spec/rejected_task_registry.md`、切片恢复点 `docs/superpowers/plans/2026-08-16-phase0a-combat-feel-slice.md`。
2. 盘点切片表现层（`tools/phase0minus_probe/lib/gameplay/` + `lib/main.dart` HUD overlay）七类反馈的渲染机制、占位手法与资产消费。
3. 盘点资产与音频后端：`assets/`（实测 701 文件）、`assets/audio` 30 个 mp3 的消费映射、`lib/shared/audio` 三件套、`lib/features/battle` 生产表现层与切片的隔离关系。
4. 盘点视觉验收基建（`tool/visual_acceptance.dart`、`tools/visual_capture/`、双视口 Profile 基线）。
5. 写审计报告 + 复核关键计数，commit 并打 `[READY]`。

## 当前恢复点

- 状态：五个切片全部完成，审计报告已交付，待派单方按 §8.2 复查。
- 最后完成：`docs/audit/phase0a-presentation-gap-audit-2026-08-16.md`。核心结论：切片运行时仅消费 4 张图（长卷 + 祖师/山贼/精英姿势图集），动作 = 每帧按状态取格切换（无序列帧/骨骼，实测 grep 0 命中）；全部特效为 Canvas 直绘占位；probe 音频为零（无依赖、0 播放点，且隔离守卫测试黑名单禁音频依赖）；主仓音频全链路可复用（30/30 mp3 有消费点，battleUlt/battleChargeStart 系借用素材，battleDeath 槽位预留无资产）。
- 下一步：派单方复查路径/计数与越界情况后，按报告 P0→P2 拆单实装。
- 已跑验证：本单为只读审计，未改代码，无需跑测试；报告中全部计数由文末复现命令实测（30 个 mp3、probe 音频 0 命中、stages/towers 的 sceneBackgroundPath 122/49 与 iconPath 135/116、SpriteAnimation/Skeleton 0 命中、runtime 目录 4 张消费图在列）。
- 阻塞项：无。待派单方/用户拍板项（已在报告 P1-2 写明选项与证据，本单不代拍）：probe 内是否引入音频依赖（触 `feedback_isolation_guard_test.dart:18-21` 黑名单），或维持静音契约、音效随根应用生产接线实装。
