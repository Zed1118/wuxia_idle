# Phase 0B 表现反馈硬化（Kimi）

## 目标

硬化既有 `phase0b_feedback_draft` 反馈组件，使其能在下一步被真实玩法模式复用；**本任务不接玩法事件、不新建 mode、不改 `main.dart`**，feedback 切片保持独立。回答：「HUD 只读视图/控制器输入边界是否清晰可复用、常规桌面视口下是否无溢出且有响应式、语义/键盘焦点/状态公告是否最小可用、cue 映射与内存掉落是否仍确定性无持久化」；不回答玩法接线、正式美术、正式音频。

## 分支

`feat/phase0b-kimi-feedback-hardening`（当前 worktree 分支），基线 tip `314ebafd`（`[READY] Phase 0B 可玩与反馈初稿收口`）。基线实测：`flutter analyze --no-pub` 0 issue，probe 全量 162 pass / 0 fail（本计划开工时复测确认，见恢复点）。

## 验收标准

- 只改 `tools/phase0minus_probe/`（feedback 源与其测试）与本计划文件；不改根 `lib/`、`data/`、`test/`、`pubspec.yaml`、GDD/CLAUDE/PROGRESS/BACKLOG；不调用 Jarvis；不改探针 `lib/main.dart`、不新建 mode。
- 抽出可复用的只读 HUD 视图组件：`FeedbackHud(state, onReset)` 纯参数驱动、不持有 controller；controller 唯一输入口保持 `apply(FeedbackEvent)` sealed 事件；`FeedbackHudState` 作为只读 view model（列表不可变）。现有 `phase0b_feedback_draft` 键盘演示行为不变、仍可运行。
- HUD 在 1280×720 与 1440×900 下无 overflow；窄/矮视口有真实响应式差异（紧凑档：量表宽度、面板内边距收敛），保持克制水墨色板，不引入 Material 饱和色（朱砂仍只用于危险预兆）。
- 最小可用无障碍：量表/危险横幅/终局面板带 Semantics 标签，危险升级与终局转换有 `SemanticsService.announce` 状态公告；终局时 reset 按钮自动获得键盘焦点、可键盘激活；终局锁输入（controller 层已有，widget 层保持只有 reset 生效），reset 后焦点与状态恢复。不做教程弹窗。
- cue 映射保持纯函数确定性；静音 sink 仍零依赖；内存 loot 有界、reset 清空、绝不持久化——隔离守卫测试继续兜底并自动覆盖新增文件。
- 输入契约硬化：`PlayerDamaged.fraction` / `ResourceAdjusted.delta` 拒绝非有限值，`PlayerDamaged` 拒绝负值（治疗不是本契约的职责），非法输入 `ArgumentError`；既有 `total>=1`、终局 result 非 none 校验保持。
- 避开 `docs/spec/rejected_task_registry.md` 已否/暂缓方向（不做 Boss 技能预兆图标、掉落缺口标记、战斗关键回合摘要等）。
- 新增测试至少覆盖：响应式 widget tests（两视口无 overflow + 紧凑档生效）、语义/焦点/公告测试、controller 输入契约、只读 view model（不可变列表）、非持久化/非 Gate guard（沿用并确认覆盖新文件）。
- 跑 `dart format`、`flutter analyze --no-pub`、feedback 专项测试、probe 全量测试，记录命令与通过数。
- 小切片提交；最终工作区干净，tip commit 以 `[READY]` 开头；硬阻塞打 `[BLOCKED]` 并写明。

## 任务切片

1. 本计划文件。
2. 纯 Dart 层硬化：controller 输入校验（非有限/负值拒绝）+ `FeedbackHudState` 只读化（`recentCues` 等列表不可变）+ 输入契约与只读契约测试。
3. 视图抽取：新增 `FeedbackHud` 可复用视图组件（LayoutBuilder 响应式，紧凑档断点），draft app 改薄壳复用它，键盘演示行为不变；响应式 widget tests（1280×720 / 1440×900）。
4. 无障碍最小集：Semantics 标签、危险/终局 `announce`、终局 reset 自动焦点与键盘激活；语义/焦点/公告测试。
5. 守卫确认 + `dart format` + analyze + feedback 专项 + probe 全量；更新恢复点，冻结打 `[READY]`。

## 当前恢复点

- 状态：**已完成**。五个切片全部落地，分支 tip 打 `[READY]`。
- 最后完成：① controller 输入契约（`PlayerDamaged.fraction` 拒绝非有限/负值、`ResourceAdjusted.delta` 拒绝非有限，`ArgumentError`）+ `FeedbackHudState` 只读化（`recentCues` 不可变，loot 本就不可变）；② 抽取可复用只读视图 `FeedbackHud(state, onReset)`（`feedback_hud_view.dart`），LayoutBuilder 响应式：紧凑档断点 `宽<1320 或 高<800`（1280×720→紧凑：量表条 150px/面板 padding 8；1440×900→舒适：200px/12），draft app 变薄壳复用、键盘演示行为不变；③ 无障碍最小集：量表 `semanticsLabel`（progressBar 数字值语义）、Boss pips 单标签、危险横幅/终局面板 live region、危险升级与终局 `SemanticsService.sendAnnouncement` 边沿公告、终局 reset 按钮 autofocus + Enter/Space/R 激活、reset 后 draft app 焦点恢复；④ format/analyze/全量验证。
- 下一步：无。等待合并审核；玩法事件对接属 Qoder 切片（消费 `FeedbackHud` + `FeedbackHudController.apply` 即可，本切片已备边界）。
- 已跑验证（本会话实测，cwd=`tools/phase0minus_probe`）：
  - `flutter analyze --no-pub` → No issues found（1.6s）；
  - `flutter test --no-pub test/phase0b/feedback` → **61 pass / 0 fail**（基线 43 + 新增 18：输入契约 3、只读 view model 2、响应式 5、语义/公告/焦点 7、demo 焦点恢复 1）；
  - `flutter test --no-pub`（probe 全量）→ **180 pass / 0 fail**（基线 162 + 18）；
  - `dart format` 已跑并单独提交；范围核查 `git diff 314ebafd..HEAD` 仅触 `tools/phase0minus_probe/` 与本计划文件。
- 阻塞项：无。真人/Windows Gate、正式美术与正式音频、玩法逻辑（Qoder 切片）不在本任务内，未伪造替代。
