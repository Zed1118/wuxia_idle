# 派单：测试质量目标序列（flaky 根治 + coverage 补强 + 注释回中文）

你在挂机武侠项目的隔离 worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/test-quality-20260719`（分支 `kimi/test-quality-20260719`，基点 main@2f74e192，环境已预热：pub get / build_runner / analyze 冒烟均已跑过）。先读项目根 `CLAUDE.md`（§8.0/§8.2/§8.3 工作流与交付协议）与 `docs/spec/rejected_task_registry.md`。

自建计划文件 `docs/superpowers/plans/2026-07-19-kimi-test-quality.md`（目标/验收/切片/恢复点），每完成一个目标 commit（中文动宾）并更新恢复点。

## 目标 1 · 根治两个 main 既有隔离型 flaky（核心目标）

对象（均为项目记录在案的并发隔离型 flaky，全量并发跑偶红、单独跑绿）：
1. `test/features/equipment/presentation/equipment_detail_screen_test.dart`（路径以实际 find 为准，文件名 equipment_detail_screen_test）
2. `test/data/drop_table_reference_redline_test.dart`（CLAUDE §8.0 v1.29 点名「排查隔离型 flaky 如 drop_table_reference_redline 时才用 -j1」）

要求：
- 先复现：构造并发组合（如全量 `flutter test --no-pub` 或该文件与邻近目录并发）跑出红，记录失败摘要作为 RED 证据；若 20 分钟内无法复现，改为代码审读定位隔离性风险点（共享临时目录/全局单例残留/文件名碰撞/端口竞争等），写明推断依据。
- 根治隔离性根因（每测试独立 createTemp 目录/唯一命名/setUp 重置全局态/轮询替代固定延时等）。**禁止**用 retry、skip、`-j1` 标记、加长 sleep 糊弄。参考先例：本项目 online_presence R2/R6 coverage flaky 用轮询根治（git log 可溯，2026-07-19 合入 `98ea6873`）。
- 证明：修后全量 `flutter test --no-pub` 连续 2 次全绿（贴两次的通过数+EXIT），且两个目标文件单独跑绿。全量验证集中在目标 1 收尾做，不要反复跑全量。

## 目标 2 · coverage 补强 2-3 个低覆盖生产文件

- 先实测：`flutter test --coverage --no-pub`（或分目录跑）生成 lcov，统计行覆盖率挑出 top 低覆盖的**生产文件**（lib/ 下），排除：`lib/features/debug/**`（调试工具不计）、`lib/features/battle/**`（另一执行端在途热区，禁碰）、纯 def/生成文件。
- 挑 2-3 个有真实行为逻辑的文件补**行为测试**（断言行为语义，不写「调用即通过」的空测）；报每个文件改前→改后覆盖率数字。
- 只新增/修改测试文件，不为凑覆盖改生产代码；发现生产代码疑似 bug 一律只记录到计划文件「发现项」，不修。

## 目标 3 · expedition_combat_runner 注释回中文（捎带小活）

`lib/features/expedition/application/expedition_combat_runner.dart` 的类级/方法级英文 doc comment 是外部执行端违背项目惯例翻译的，全部改回中文（语义忠实翻译即可，零逻辑改动，对齐项目其余文件的中文注释风格）。此文件的**代码逻辑一行不动**。

## 禁区（碰=立即 [BLOCKED] 停）

- `lib/features/battle/**` 与 `test/features/battle/**`（另一执行端在途）
- `data/` 全目录、`pubspec.yaml`、`GDD.md`、`CLAUDE.md`、`PROGRESS.md`、saveVersion、结算公式层、`lib/shared/strings.dart`
- 除目标 3 的注释外不改任何 lib/ 生产代码；flaky 根治若确需动生产代码（如全局单例加 reset 钩子），先在计划文件写明方案并以 `[BLOCKED]` tip 冻结待拍板，不要硬做
- 主 checkout（/Users/a10506/Desktop/Projects/挂机武侠 顶层）只读

## 交付（§8.2 四证据齐全才算完）

1. 生产接线/根因证据：每个 flaky 的根因一句话+修法；coverage 文件选择依据（实测数字）
2. targeted 结果：命令+通过数（目标1 另附全量两连绿证据）
3. 红线影响：应为「零触及」，如实声明
4. 残留风险：未能复现的 flaky/未覆盖分支列清
- `flutter analyze --no-pub` 0 issue；改动文件 `dart format` 干净
- 全部完成：树净 + tip 前缀 `[READY] 测试质量批交付`；中途停：更新恢复点，tip 保持 WIP
