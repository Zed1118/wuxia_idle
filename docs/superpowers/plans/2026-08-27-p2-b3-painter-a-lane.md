# 2026-08-27 二阶段 B3 Painter A 道审计计划

## 目标与边界

- 唯一结果：在同一受控链串行关闭 A1 五类墨效像素守卫与 A2 六类 painter mutation sweep，或在冻结派单包定义的停止条件命中时留下真实 `[BLOCKED]`。
- A1 分支：`codex/p2-b3-f2-ink-pixel-tests-20260827`，固定基线 `6d59c895dd5922adde1b64c50b3895c52d7926e9`。
- A2 分支：`codex/p2-b3-painter-mutation-sweep-20260827`，固定基线为 A1 收工 tip。
- 允许改动：`test/features/battle/presentation/phase0a/`、本审计计划、`receipt.yaml`。
- 禁止改动：`lib/` 产品代码、数值/YAML、文案、schema/saveVersion、`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml`、`~/.claude/skills/`；禁 push、merge、main、revert。

## 固定验收清单

- [ ] 生产接线：经真实 `Phase0aBattleScreen` 定位生产 `CustomPaint`，只从公共 `painter` 属性复绘，不直接实例化私有 painter。
- [ ] A1 覆盖 melee / palm / gather / clear / defeat 五类，每类至少一帧 `PictureRecorder → toImage → rawRgba` 非透明像素。
- [ ] A2 对 `_GatherPullPainter`、`_GuardianWardRingPainter`、`_GuardianMechanicPainter`、`_StageWashPainter`、`_PaperBannerPainter`、`_OutcomeSealPainter` 逐类 mutation；只给实测假绿的类别补守卫。
- [ ] 每个子门实现 commit 后依序完成 `remove_implementation` 与 `force_degenerate_value` 两向破坏证红，记录原始命令、reporter 末行、`[E]` 数与失败数，再用精确反向补丁还原。
- [ ] 每个子门依序通过 targeted、`flutter analyze --no-pub lib test`、整仓 format、带全量锁的 `flutter test --no-pub`、`git diff --check`。
- [ ] 每个子门写审计型 `receipt.yaml`：`break_red` 留空、唯一 `audit_verification`、changed files 字节序升序、原文 last line、patch SHA-256。
- [ ] 红线影响：零产品行为、零玩法数值、零三系/在线离线/反主流规则变化、零新增 UI 文案。
- [ ] 残留风险：本执行端不做 S5 独立验收、不 merge；Claude 仍须独立复跑与破坏证红。
- [ ] 收工 tip 以 `[READY]` 或真实 `[BLOCKED]` 开头，HEAD 与 receipt 对齐且 worktree clean。

## 任务切片

1. A1：复用真实战斗 fixture，在既有布局合同中加入五类生产 painter 非透明像素证据。
2. A1：实现 commit 后完成两向证红与八步收工，冻结 tip。
3. A2：从 A1 tip 建分支，逐类 mutation，记录原有守卫是否已足够。
4. A2：只补实测假绿类别，完成两向证红与八步收工，冻结 tip。

## 当前恢复点

- 状态：A1 READY，等待 Claude 独立 S5 复核；A2 将从本 tip 串行开分支。
- 最后完成：在真实 `Phase0aBattleScreen` 的既有近战/掌风、Q、R、击败流程中，从生产 `CustomPaint.painter` 取得五类 painter，以 `PictureRecorder → toImage → rawRgba` 断言至少一个非透明像素；未直接实例化私有 painter，既有 key/尺寸/坐标合同保留。两向破坏均红且已精确还原，正式 targeted/analyze/format/full/diff check 均通过。
- 下一步：冻结 A1 `[READY]` tip 与外置机器 receipt；从该 tip 创建 `codex/p2-b3-painter-mutation-sweep-20260827` 执行 A2。
- 已跑验证：见下方 A1 八步原始命令与结果。
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
