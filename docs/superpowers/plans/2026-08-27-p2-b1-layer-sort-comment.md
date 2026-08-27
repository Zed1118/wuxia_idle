# P2 批一 1.3：修正图层排序注释

## 目标

让 `Phase0aStage.sortActors` 的注释准确描述 Flutter `Stack` 的绘制顺序：世界 y 较小的远处角色先画，世界 y 较大的近处角色后画并覆盖。

## 分支与边界

- 分支：`codex/p2-b1-layer-sort-comment-20260827`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-p2-b1-layer-comment`
- 基线：`main@0d006c9f`
- 只改注释，不改排序实现、视觉策略或测试语义。
- 禁止修改：`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml`。

## 验收标准

1. 注释与 y 升序及 Stack 后画覆盖语义一致。
2. stage transform 相关测试、analyze、format 与禁区核查通过。
3. 工作区 clean，tip 为中文 `[READY]` 或 `[BLOCKED]`。

## 当前恢复点

- 状态：READY，等待协调者后续集成。
- 已跑验证：stage transform 7/7 全绿；相关 source/test analyze 0 issue；format 0 changed；禁区 diff 为空。
- 阻塞项：无。
