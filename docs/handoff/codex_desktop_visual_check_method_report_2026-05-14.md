# Codex Desktop 视觉验收方法复盘（2026-05-14）

> 给 Claude Code / Mac 端 review 用。本文记录 Pen Windows 本机 Codex Desktop 在 W7-W11 五周累积视觉验收自动化首跑中的实际工作方法、判断依据、踩坑点和可复用流程。

## 1. 我的工作姿态

这次任务本质不是“写自动化测试代码”，而是一次 Windows Flutter Desktop 可视化验收探路。我遵守的核心边界是：

- 不改 `lib/` / `test/` 业务代码。
- 不动 `GDD.md` / `CLAUDE.md` / `numbers.yaml` / DeepSeek 文案领地。
- 不安装额外 GUI 自动化包。
- 不 push，所有结果留在本地 main。
- 遇到跑不通的场景，优先产出可复查截图和 closeout，而不是硬撑。

第一次执行时，`build_runner` 环境损坏导致首跑未能进入 GUI。我按派单纪律先停下并写失败 closeout。用户随后明确要求“解决遇到的问题，必须完成测试的截图”，我才进入第二阶段：修复本机环境、继续 GUI 自动化、完成 15 个目标文件名的截图归档，并把失败/弱证据如实写进 closeout。

## 2. 开工前阅读顺序

我先读了这些文件，避免只按记忆做：

1. `docs/handoff/codex_dispatch_w7_w11_2026-05-13.md`
2. `docs/handoff/w7_w11_visual_check_spec_2026-05-13.md`
3. `PROGRESS.md`
4. `CLAUDE.md` 的 §5 / §12
5. `docs/handoff/week10_phase4_defeat_resolution_2026-05-13.md`
6. `docs/handoff/week11_victory_resolution_2026-05-13.md`
7. `docs/handoff/t62_visual_check_spec_2026-05-13.md`

读完后，我把任务拆成三层：

- 先确认本地基线能否生成、分析、测试。
- 再确认 Flutter Windows GUI 能否稳定启动和截图。
- 最后按 A-G 场景逐项收集视觉证据，跑不通的地方保留反证。

## 3. 环境修复方法

首个阻断点是 `flutter pub run build_runner build --delete-conflicting-outputs` 失败，表现为 Pub cache 中 `build_runner` / `build_runner_core` 文件不完整或入口不匹配。

我采用的修复顺序是：

1. 先跑 `flutter pub get`，看是否能自然修复。
2. 检查 Pub cache 目录：`C:\Users\Administrator\AppData\Local\Pub\Cache\hosted\pub.flutter-io.cn`。
3. 只删除确认损坏的包目录：
   - `build_runner-2.15.0`
   - `build_runner_core-7.3.2`
4. 再跑 `flutter pub get` 重新拉取。
5. 删除本地生成缓存 `.dart_tool/build`。
6. 改用 `dart run build_runner build --delete-conflicting-outputs`。

结果：

- `dart run build_runner build` 成功，生成 42 个输出。
- `flutter analyze` 通过。
- `flutter test` 剩 1 个失败：`test/data/game_repository_test.dart` 中 T64 心法招式分布 fail-fast 用例没有抛预期 `StateError`。

这里我的判断是：该失败属于数据/仓储红线测试问题，但用户第二次明确要求必须完成截图，因此我没有再卡在测试层，也没有修改测试或业务代码，而是把失败写入 closeout。

## 4. GUI 自动化工具链

我没有使用外部安装工具，实际使用的是 PowerShell + Windows API：

- 窗口控制：`user32.dll` 的 `SetWindowPos`
- 鼠标移动/点击/滚轮：`SetCursorPos`、`mouse_event`
- 键盘：`keybd_event`
- 截图：`.NET System.Drawing.Bitmap.CopyFromScreen`
- 启动应用：`Start-Process flutter run -d windows`
- 日志：重定向到 `.dart_tool/codex_flutter_run.out.log` / `.err.log`

选择这条路线的原因：

- 当前机器能直接运行，不需要 pip/npm/choco 额外依赖。
- Flutter Desktop 对传统坐标点击响应稳定。
- 截图文件可以直接按 spec 命名落到 `docs/screenshots/phase4_w7_w11/`。

主要缺点：

- 坐标依赖窗口位置。
- 1280x720 下底部菜单有时被挡住，需要把窗口临时移动到 `Y=-220` 或改成 1280x900。
- Flutter 的语义树没有被深入利用，所以它不是语义级自动化，只是可靠的坐标级探路。

## 5. 截图执行策略

我使用了“先固定窗口，再按场景顺序截图”的方式：

1. 清理应用存档：删除 `$env:APPDATA\wuxia_idle`。
2. 启动 `flutter run -d windows`。
3. 找到 `wuxia_idle` 窗口进程。
4. 固定窗口位置和尺寸。
5. 通过 P5 师徒种子进入角色面板。
6. 按场景 A-G 采集截图。
7. 每个截图直接保存为 spec 要求的最终文件名。
8. 临时 `_*.png` 检查图在提交前删除。

我没有追求“视觉上最漂亮的一张”，而是优先保留能解释当前状态的截图。对于跑不通的验收点，我没有伪造通过截图，而是用占位/反证截图保留现场，并在 closeout 标清原因。

## 6. 场景级判断方法

### A / W7 装备

目标是 35 件装备 fixture。实际 P5 存档只显示当前持有装备，而不是全图鉴。我采集了仓库当前状态，作为“降级完成”证据，不把它写成强通过。

### B / W8 心法

目标是 21 本心法 fixture。实际 UI 显示当前持有/已学心法面板。我采集面板状态，结论同样是降级完成，而不是全量 fixture 验收通过。

### C / W9 爬塔 UI

这是本次最稳定的场景。我通过滚动列表截到了：

- 爬塔顶部列表和进度。
- 小 Boss outline。
- 30 层大 Boss outline。

这里可以作为较强视觉证据，因为 UI 中层数、锁定状态和 Boss 轮廓都可见。

### D / W11 主线 victory 副作用

我进入 `stage_01_01` 重打并获胜，然后回角色面板截图。但 UI 只显示共鸣阶段，不显示 `battleCount=N`；心法进度也仍是 `0/100`。所以这组只能证明“可进入并胜利”，不能证明 battleCount 或 progress 副作用。

### E / W11 stage drop 入背包

由于缺少明确的战前/战后新增物品对比，截图只能作为仓库当前状态证据，不能强证明 drop 入包。

### F / W11 爬塔首通 / 重打

塔 1 层战斗可以胜利，但返回塔列表后 UI 仍显示：

- 已通 0 / 30 层
- 总尝试 0 次
- 失败 0 次

因此无法形成“首通发奖、重打不发奖、但 battleCount 仍增长”的视觉闭环。我保留了战斗胜利图，并把后续文件标为占位/弱证据。

### G / W10 Boss 战败

`stage_01_05` 在当前 P5 队伍下实际左队胜，没有触发战败 banner 或散功代价。因此截图 `14` 是反证：它证明当前 fixture 无法触发预期 defeat path。`15` 只能占位，不能当作通过证据。

## 7. 我如何处理“必须完成截图”和“不能伪造通过”的冲突

用户第二次指令强调“必须完成测试的截图”。我的理解是：

- 文件名必须齐。
- GUI 自动化必须实际跑。
- 遇到产品/fixture 不支持的场景，也要留下可审计证据。
- 不能把弱证据包装成通过。

所以我最终交付 15 张目标文件名，但在 closeout 中明确分成：

- 真实有效 / 可用截图。
- 弱证据。
- 占位截图。
- 失败反证。

这对后续 Claude Code / Mac 端 review 更有用，因为它能区分“自动化没跑通”和“产品状态不支持验收点”。

## 8. Git 与文件边界

本次最终新增/更新内容是：

- `docs/screenshots/phase4_w7_w11/*.png`
- `docs/handoff/codex_w7_w11_visual_check_closeout_2026-05-13.md`

提交：

- `530fd0c feat(visual-check): W7-W11 五周累积视觉验收 Codex 桌面自动化首跑`
- `05d9a1a feat(visual-check): 补跑 W7-W11 五周视觉验收截图`

没有 push。

工作区里还有一些非本次任务的未提交文件/生成文件，我没有回滚，也没有混进截图提交：

- `macos/Flutter/GeneratedPluginRegistrant.swift`
- `windows/flutter/generated_plugin_registrant.cc`
- `windows/flutter/generated_plugins.cmake`
- 若干未跟踪临时/历史文件

## 9. 给 Claude Code 的建议

如果 Claude Code 后续要接这件事，我建议优先看三类问题：

1. 测试失败：确认 T64 心法招式分布 fail-fast 是否真实回归。
2. 验收可视性：为 W11 增加可截图字段，例如装备 tile 显示 `battleCount=N`，心法 tile 显示 usage/progress 明细。
3. fixture 可控性：给视觉验收加专用 seed，让：
   - Ch1 状态可预测。
   - `stage_01_05` 必败。
   - Tower floor 1 首通后确实更新 progress。

GUI 自动化方面，PowerShell/.NET 坐标法已证明可用。若要长期复用，建议把点击点位和截图函数整理成项目外脚本，不放进仓库，避免污染产品代码。

## 10. 可复用命令摘要

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test --concurrency=1
```

```powershell
Remove-Item -LiteralPath "$env:APPDATA\wuxia_idle" -Recurse -Force
Start-Process flutter -ArgumentList @("run", "-d", "windows")
```

截图自动化的核心是：

```powershell
Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap($width, $height)
$gfx = [System.Drawing.Graphics]::FromImage($bmp)
$gfx.CopyFromScreen($x, $y, 0, 0, $bmp.Size)
$bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
```

这条路线足够完成当前阶段的探路，但要做成稳定 CI 级自动化，还需要应用侧暴露更可测试的状态和专用 fixture。
