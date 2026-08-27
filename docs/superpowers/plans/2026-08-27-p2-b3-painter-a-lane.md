# 2026-08-27 二阶段 B3 Painter A 道审计计划

## 目标与边界

- 唯一结果：在同一受控链串行关闭 A1 五类墨效像素守卫与 A2 六类 painter mutation sweep，或在冻结派单包定义的停止条件命中时留下真实 `[BLOCKED]`。
- A1 分支：`codex/p2-b3-f2-ink-pixel-tests-20260827`，固定基线 `6d59c895dd5922adde1b64c50b3895c52d7926e9`。
- A2 分支：`codex/p2-b3-painter-mutation-sweep-20260827`，固定基线为 A1 收工 tip。
- 允许改动：`test/features/battle/presentation/phase0a/`、本审计计划、`receipt.yaml`。
- 禁止改动：`lib/` 产品代码、数值/YAML、文案、schema/saveVersion、`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml`、`~/.claude/skills/`；禁 push、merge、main、revert。

## 固定验收清单

- [x] 生产接线：经真实 `Phase0aBattleScreen` 定位生产 `CustomPaint`，只从公共 `painter` 属性复绘，不直接实例化私有 painter。
- [x] A1 覆盖 melee / palm / gather / clear / defeat 五类，每类至少一帧 `PictureRecorder → toImage → rawRgba` 非透明像素。
- [x] A2 对 `_GatherPullPainter`、`_GuardianWardRingPainter`、`_GuardianMechanicPainter`、`_StageWashPainter`、`_PaperBannerPainter`、`_OutcomeSealPainter` 逐类 mutation；六类原有测试均实测假绿，故六类全部补守卫。
- [x] 每个子门实现 commit 后依序完成 `remove_implementation` 与 `force_degenerate_value` 两向破坏证红，记录原始命令、reporter 末行、`[E]` 数与失败数，再用精确反向补丁还原。
- [x] 每个子门依序通过 targeted、`flutter analyze --no-pub lib test`、整仓 format、带全量锁的 `flutter test --no-pub`、`git diff --check`。
- [x] 每个子门写审计型 `receipt.yaml`：`break_red` 留空、唯一 `audit_verification`、changed files 字节序升序、原文 last line、patch SHA-256。
- [x] 红线影响：零产品行为、零玩法数值、零三系/在线离线/反主流规则变化、零新增 UI 文案。
- [x] 残留风险：本执行端不做 S5 独立验收、不 merge；Claude 仍须独立复跑与破坏证红。
- [x] 收工 tip 以 `[READY]` 或真实 `[BLOCKED]` 开头，HEAD 与 receipt 对齐且 worktree clean。

## 任务切片

1. A1：复用真实战斗 fixture，在既有布局合同中加入五类生产 painter 非透明像素证据。
2. A1：实现 commit 后完成两向证红与八步收工，冻结 tip。
3. A2：从 A1 tip 建分支，逐类 mutation，记录原有守卫是否已足够。
4. A2：只补实测假绿类别，完成两向证红与八步收工，冻结 tip。

## 当前恢复点

- 状态：A1 已冻结 `[READY]`；A2 已完成执行端八步收工，准备冻结 `[READY]` tip，等待 Claude 独立 S5 复核。
- 最后完成：六类原有守卫假绿均已实测；补齐生产 painter 像素守卫后，在最终 checkpoint `6e05b8a575f48d030571b771aee2e585c71e5840` 上逐类完成两向证红。targeted、analyze、整仓 format、锁内全量与 diff check 全部通过，零 `lib/` 和禁止路径改动。
- 下一步：生成外置机器 receipt 并冻结 A2 `[READY]` tip；本执行端不自签 S5、不 merge。
- 已跑验证：见下方 A2 八步原始命令与结果。
- 阻塞项：无。

## A1 八步原始命令与结果

1. 实现并提交
   - `git commit -m '补全五类墨效像素守卫'`
   - checkpoint：`3eed30e8fa642a60a93e653f7409c0756a1e5f27`
2. 提交后两向破坏证红
   - `remove_implementation`：在 `_InkEffectPainter.paint` 首行临时加入 `return;`；运行 `flutter test --no-pub test/features/battle/presentation/phase0a/phase0a_battle_screen_test.dart --reporter compact`。
   - 结果：exit 1；末行 `00:04 +24 -4: Some tests failed.`；`[E]=4`；实测失败测试数 4。
   - 精确反向补丁删除 `return;` 后：HEAD=`3eed30e8fa642a60a93e653f7409c0756a1e5f27`，`git diff --quiet` exit 0，`git status --short` 空。
   - `force_degenerate_value`：在同一方法首行临时加入 `canvas.clipRect(Rect.zero);`；复跑同一 targeted 命令。
   - 结果：exit 1；末行 `00:04 +24 -4: Some tests failed.`；`[E]=4`；实测失败测试数 4。
   - 精确反向补丁删除退化 clip 后：HEAD=`3eed30e8fa642a60a93e653f7409c0756a1e5f27`，`git diff --quiet` exit 0，`git status --short` 空。
3. Targeted（逐文件）
   - `flutter test --no-pub test/features/battle/presentation/phase0a/phase0a_battle_screen_test.dart --reporter compact` → exit 0；末行 `00:04 +28: All tests passed!`；`[E]=0`。
   - `flutter test --no-pub test/features/battle/presentation/phase0a/phase0a_ink_vfx_test.dart --reporter compact` → exit 0；末行 `00:00 +3: All tests passed!`；`[E]=0`。
4. Analyze
   - `flutter analyze --no-pub lib test` → exit 0；末行 `No issues found! (ran in 15.3s)`。
5. 整仓 format
   - `dart format --output=none --set-exit-if-changed .` → exit 0；末行 `Formatted 1624 files (0 changed) in 4.28 seconds.`。
6. 全量锁内测试
   - 锁：`/Users/a10506/.claude/locks/wuxia_full_test.lock`；测试前确认 absent，原子创建；测试结束以 `unlink` 删除，结束后确认 absent。
   - `flutter test --no-pub --reporter compact` → exit 0；末行 `05:05 +5633: All tests passed!`；`[E]=0`。
7. Diff check
   - `git diff --check 6d59c895dd5922adde1b64c50b3895c52d7926e9..HEAD` → exit 0。
8. Receipt / tip
   - 本任务为零 `lib/` 的审计单；`break_red` 在 receipt 留空，两向证红仅记录于本计划。
   - receipt 以最终 A1 tip 重新计算 `changed_files` 与 patch SHA-256 后生成；tip 使用 `[READY]` 中文动宾标记并保持 clean。

## A2 逐类 mutation 结果

每项均在目标类 `paint()` 首行临时加入 `return;`，运行表中原始命令，随后用精确反向补丁删除该行；六次还原后均为 HEAD=`2c84404bf081bb56038fd7cf86c16f8066fd8ac1`、`git diff --quiet` exit 0、`git status --short` 空。

| 目标 painter | 原始测试命令 | exit / reporter 末行 / `[E]` / 失败数 | 结论 |
| --- | --- | --- | --- |
| `_GatherPullPainter` | `flutter test test/features/battle/presentation/phase0a/phase0a_battle_screen_test.dart` | `0` / `00:04 +28: All tests passed!` / `0` / `0` | 假绿，补守卫 |
| `_GuardianWardRingPainter` | `flutter test test/features/battle/presentation/phase0a/phase0a_mechanics_presentation_test.dart` | `0` / `00:01 +6: All tests passed!` / `0` / `0` | 假绿，补守卫 |
| `_GuardianMechanicPainter` | `flutter test test/features/battle/presentation/phase0a/phase0a_mechanics_presentation_test.dart` | `0` / `00:01 +6: All tests passed!` / `0` / `0` | 假绿，补守卫 |
| `_StageWashPainter` | `flutter test test/features/battle/presentation/phase0a/phase0a_battle_screen_test.dart` | `0` / `00:03 +28: All tests passed!` / `0` / `0` | 假绿，补守卫 |
| `_PaperBannerPainter` | `flutter test test/features/battle/presentation/phase0a/phase0a_battle_screen_test.dart` | `0` / `00:04 +28: All tests passed!` / `0` / `0` | 假绿，补守卫 |
| `_OutcomeSealPainter` | `flutter test test/features/battle/presentation/phase0a/phase0a_battle_screen_test.dart` | `0` / `00:03 +28: All tests passed!` / `0` / `0` | 假绿，补守卫 |

## A2 八步原始命令与结果

1. 实现并提交
   - `git commit -m '补全六类画笔像素守卫'` → `2eeca061f408dfdc07a822053e3e2aa4a5edcac3`。
   - 首次整仓 format 检出 mechanics 测试待格式化；执行 `dart format test/features/battle/presentation/phase0a/phase0a_mechanics_presentation_test.dart` 后提交 `git commit -m '格式化守护画笔像素守卫'`，最终 checkpoint=`6e05b8a575f48d030571b771aee2e585c71e5840`。因 tip 变化，以下两向证红与全部正式门均在该 checkpoint 重新执行。
2. 提交后逐类两向破坏证红
   - `remove_implementation`：逐类在目标 `paint()` 首行临时加入 `return;`。
   - `force_degenerate_value`：逐类在目标 `paint()` 首行临时加入 `canvas.clipRect(Rect.zero);`。
   - battle 类每次原始命令：`flutter test --no-pub test/features/battle/presentation/phase0a/phase0a_battle_screen_test.dart --reporter compact`。
   - guardian 类每次原始命令：`flutter test --no-pub test/features/battle/presentation/phase0a/phase0a_mechanics_presentation_test.dart --reporter compact`。

| painter | remove：exit / 末行 / `[E]` / 失败数 | degenerate：exit / 末行 / `[E]` / 失败数 |
| --- | --- | --- |
| `_GatherPullPainter` | `1` / `00:09 +27 -1: Some tests failed.` / `1` / `1` | `1` / `00:09 +27 -1: Some tests failed.` / `1` / `1` |
| `_GuardianWardRingPainter` | `1` / `00:05 +5 -1: Some tests failed.` / `1` / `1` | `1` / `00:03 +5 -1: Some tests failed.` / `1` / `1` |
| `_GuardianMechanicPainter` | `1` / `00:03 +5 -1: Some tests failed.` / `1` / `1` | `1` / `00:05 +5 -1: Some tests failed.` / `1` / `1` |
| `_StageWashPainter` | `1` / `00:08 +26 -2: Some tests failed.` / `2` / `2` | `1` / `00:11 +26 -2: Some tests failed.` / `2` / `2` |
| `_PaperBannerPainter` | `1` / `00:11 +27 -1: Some tests failed.` / `1` / `1` | `1` / `00:12 +27 -1: Some tests failed.` / `1` / `1` |
| `_OutcomeSealPainter` | `1` / `00:10 +27 -1: Some tests failed.` / `1` / `1` | `1` / `00:14 +27 -1: Some tests failed.` / `1` / `1` |

   - 12 次破坏均以精确反向补丁还原；每次还原后 HEAD=`6e05b8a575f48d030571b771aee2e585c71e5840`、`git diff --quiet` exit 0、`git status --short` 空。
3. Targeted（逐文件）
   - `flutter test --no-pub test/features/battle/presentation/phase0a/phase0a_battle_screen_test.dart --reporter compact` → exit 0；末行 `00:10 +28: All tests passed!`；`[E]=0`。
   - `flutter test --no-pub test/features/battle/presentation/phase0a/phase0a_mechanics_presentation_test.dart --reporter compact` → exit 0；末行 `00:05 +6: All tests passed!`；`[E]=0`。
4. Analyze
   - `flutter analyze --no-pub lib test` → exit 0；末行 `No issues found! (ran in 9.0s)`。
5. 整仓 format
   - `dart format --output=none --set-exit-if-changed .` → exit 0；末行 `Formatted 1624 files (0 changed) in 6.78 seconds.`。
6. 全量锁内测试
   - 首次尝试发现 `/Users/a10506/.claude/locks/wuxia_full_test.lock` 被另一真实全量测试持有，返回 exit 75；未抢锁、未删锁，等其正常释放后原子创建本任务锁。
   - `flutter test --no-pub --reporter compact` → exit 0；末行 `05:55 +5633: All tests passed!`；`[E]=0`；退出后锁 absent。
7. Diff check
   - `git diff --check 2c84404bf081bb56038fd7cf86c16f8066fd8ac1..HEAD` → exit 0。
   - changed files 仅本计划与两个测试文件；`lib/`、数值/YAML、文案和全部禁止路径零改动。
8. Receipt / tip
   - 审计型 receipt 使用外置忽略路径 `build/phase2_wiring_receipts/A2/receipt.yaml`，`break_red` 留空、仅一条 `audit_verification`；最终 tip 后重算 patch SHA-256 与 HEAD。
   - tip 使用 `[READY] 完成六类画笔假绿清扫`；本执行端不做 S5 独立验收、不 merge。
