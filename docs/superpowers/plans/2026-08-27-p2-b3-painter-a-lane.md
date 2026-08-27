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

- 状态：A1 WIP。
- 最后完成：在真实 `Phase0aBattleScreen` 的既有近战/掌风、Q、R、击败流程中，从生产 `CustomPaint.painter` 取得五类 painter，以 `PictureRecorder → toImage → rawRgba` 断言至少一个非透明像素；未直接实例化私有 painter，既有 key/尺寸/坐标合同保留。
- 下一步：提交 A1 实现 checkpoint；随后按固定顺序执行两向破坏证红并精确还原。
- 已跑验证：`flutter test --no-pub test/features/battle/presentation/phase0a/phase0a_battle_screen_test.dart --reporter compact` → `00:07 +28: All tests passed!`，`[E]=0`。
- 阻塞项：无。
