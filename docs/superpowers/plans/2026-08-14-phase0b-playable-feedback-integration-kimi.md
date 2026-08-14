# Phase 0B 玩法 + 反馈纵切初稿（Kimi）

## 目标

在隔离探针内交付 Phase 0B 最小可运行「玩法 + 反馈」纵切初稿：用现有 `EncounterOrchestrator` 的中立 `EncounterEvent` 真实驱动现有 `FeedbackHudController`/HUD，打通 遭遇 → 组合层 adapter → 表现反馈 的完整链路。回答「中立事件契约能否零改动地同时服务玩法纵切与表现层」，不回答正式美术、正式音频、正式掉落/奖励与任何 Gate。

## 分支

`feat/phase0b-kimi-playable-feedback-integration`（独立 worktree），基线 `87aaa710`。

## 验收标准

- 只改 `tools/phase0minus_probe/` 与本计划文件；不改根 `lib/`、`data/`、`test/`、`pubspec.yaml`、`GDD.md`、`CLAUDE.md`、`PROGRESS.md`、`BACKLOG.md`；不调 Jarvis。
- 组合层新增 `lib/phase0b/integration/`：adapter 把 `EncounterEvent` 译为 `FeedbackEvent`，bridge 把 orchestrator 事件增量 drain 进 `FeedbackHudController`。**encounter 不得 import feedback，feedback 不得 import encounter**，依赖只存在于 integration 层，由源码守卫测试兜底。
- 新模式 `phase0b_vertical_slice_draft` 用真实 encounter 状态驱动 HUD：hero 生命/资源/流派、敌人与 Boss 危险预兆、Boss phase、命中/受伤、胜负；`LootRequested` 只生成现有有界内存掉落（`LootFeed`），不写正式奖励、不持久化。
- 使用现有 `SilentFeedbackCueSink` 与确定性 `cueForEvent` 映射；reset 重建同 seed 场景并清空 HUD、cue（重建 sink）、内存掉落。
- 新模式在 probe `main.dart` 注册，原 `phase0b_playable_draft` / `phase0b_feedback_draft` 模式不变；界面醒目标记 `NOT FINAL` 与 `gate_eligible=false`。
- 1280×720 与 1440×900 无 overflow；键盘可操作（移动/聚怪/清场/流派/reset）；终局锁输入、可 reset。
- 禁止项：敌人连锁窗口接力、对称集火、正式奖励、任何持久化、新美术、真实音频、Gate/证据/存档接线；不扩大架构。
- 测试：adapter 单测（事件→HUD 状态映射、掉落、胜负、reset 确定性）、模式 widget 测试（真实事件驱动 HUD、终局面板、双视口无 overflow）、隔离边界测试（双向 import 禁令 + 无持久化/音频/Gate 接线）。
- 每切片小提交；跑 `dart format`、`flutter analyze --no-pub`、相关 phase0b 测试与 probe 全量 `flutter test --no-pub`，记录命令与通过数。
- 收尾：工作区干净，tip commit 以 `[READY]` 开头；硬阻塞则 `[BLOCKED]` 并写明。

## 任务切片

1. 本计划文件。
2. orchestrator 增运行时输入小 API（move/gather/clear/setStyle，终局忽略）+ integration 层 adapter/bridge + adapter 单测。
3. `phase0b_vertical_slice_draft` 应用（计时器推进 orchestrator → bridge → HUD，键盘输入，终局锁 + reset 重建）+ `main.dart` mode 注册 + probe README 登记。
4. 模式 widget 测试（双视口、真实事件驱动、终局锁、reset 确定性）+ 隔离边界守卫测试。
5. format/analyze/相关测试/probe 全量验证；更新恢复点；冻结打 `[READY]`。

## 当前恢复点

- 状态：**进行中**。
- 最后完成：计划文件落盘（切片 1）。
- 下一步：切片 2——orchestrator 运行时输入 API + integration adapter/bridge + 单测。
- 已跑验证：无（尚未改代码）。
- 阻塞项：无。
