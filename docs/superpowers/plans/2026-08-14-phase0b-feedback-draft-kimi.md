# Phase 0B 表现反馈初稿（Kimi）

## 目标

在隔离探针内交付 Phase 0B 横版 ARPG 方向的表现反馈初稿：克制水墨色基础 HUD（生命 / 资源 / 流派 / Boss 阶段 / 危险预兆 / 结束状态）、仅内存的掉落事件与展示、可测试的临时音效 cue/event 映射与静音实现。回答「HUD 信息层级在水墨克制基调下是否成立、cue 映射是否可测试、掉落展示是否能在不接正式掉落的前提下演示」，不回答玩法、数值、正式美术与正式音频。

## 分支

`feat/phase0b-kimi-feedback-draft`，基线 `4fa32038`。

## 验收标准

- 只改 `tools/phase0minus_probe/` 与本计划文件；不改根 `lib/`、`data/`、`pubspec.yaml`，不接存档、正式掉落、正式奖励或正式战斗，不用 Jarvis。
- 新增独立 mode `phase0b_feedback_draft`，界面醒目标记 `NOT FINAL` 与 `gate_eligible=false`；不接任何 Gate writer / human_gate / 观察矩阵目录。
- HUD 覆盖六要素：生命、资源、流派（rigid/agile/sinister 沿用 GDD 词汇）、Boss 阶段、危险预兆（朱砂只在危险窗口出现）、结束状态（victory/defeat/reset）。
- 掉落事件仅内存、有界、可随 reset 清空；feedback 目录零持久化 API（无 dart:io / Isar / SharedPreferences / path_provider），由源码守卫测试兜底。
- cue/event 映射为纯函数、确定性可测；静音实现不引入任何依赖、不伪造音频资产；界面有 cue 触发可视日志。
- 组件与状态模型独立于 AI/Boss/流派玩法逻辑（输入为语义事件 sealed 类型，由另一个 Qoder 切片未来对接）。
- 避开 `docs/spec/rejected_task_registry.md` 已否/暂缓方向（不做 Boss 技能预兆图标正式化、不做掉落缺口标记、不做战斗关键回合摘要等）。
- 测试至少覆盖：非 Gate、掉落不持久化、cue 映射确定性、HUD 状态转换。
- 跑 `dart format`、`flutter analyze --no-pub`、相关测试与 probe 全量测试，记录命令与通过数。
- 小切片提交；最终工作区干净，tip commit 以 `[READY]` 开头；硬阻塞则 `[BLOCKED]` 并写明。

## 任务切片

1. 本计划文件。
2. 纯 Dart 层：事件 sealed 类型 + cue 映射/静音 sink + 仅内存掉落 feed + HUD 状态机（ValueNotifier），配 cue 确定性与状态转换测试。
3. Widget 层：可复用 HUD 组件 + `phase0b_feedback_draft` 应用与键盘演示驱动，接入 `main.dart` mode 表，配 widget 测试与隔离守卫测试。
4. 探针 README 补 mode 登记；format/analyze/全量验证；冻结分支打 `[READY]`。

## 当前恢复点

- 状态：**进行中**。文档与既有 probe 模式已读完（AGENTS/CLAUDE/GDD/rejected registry/art-sample spec/probe README/scroll_review 体例/isolation contract）。
- 最后完成：计划文件落盘。
- 下一步：切片 2（纯 Dart 层 + 测试）。
- 已跑验证：无（尚未改代码）。
- 阻塞项：无。真人/Windows Gate、正式美术与正式音频、玩法逻辑（Qoder 切片）明确不在本任务内，不伪造替代。
