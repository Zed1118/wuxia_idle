# P2 批一 1.1：图层排序与渲染位置同源

## 目标

角色移动插值期间，Stack 绘制顺序必须使用与实际屏幕定位相同的渲染 y；图层只能在可见脚底线真正交叉时翻转。

## 分支与边界

- 分支：`codex/p2-b1-layer-sort-render-key-20260827`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-p2-b1-layer-sort`
- 基线：`main@0d006c9f`
- 不做阵营偏置、迟滞、玩家恒在上层或任何批二视觉决策。
- 禁止修改：`data/numbers.yaml`、`GDD.md`、`PROGRESS.md`、`lib/shared/strings.dart`、`pubspec.yaml`。

## 验收标准

1. 生产战斗屏由单一渲染位置同时驱动角色定位与 y-sort。
2. 保留既有一个 fixed tick 的线性移动过渡。
3. widget 测试断言移动中 Stack actor 顺序只在实际脚底交叉后翻转。
4. 新测试完成破坏证红并复绿；相关既有测试、`flutter analyze --no-pub lib test`、格式通过。
5. diff 只含本任务文件，工作区 clean，tip 为中文 `[READY]` 或 `[BLOCKED]`。

## 任务切片

- [x] 建立统一角色渲染位置状态。
- [x] 让定位与排序消费同一位置快照。
- [x] 补移动中实际绘制顺序测试。
- [ ] targeted、破坏证红、analyze、format、禁区与 clean 核查。

## 当前恢复点

- 状态：实现与常规验证完成，待 commit 后破坏证红。
- 最后完成：统一渲染位置已同时驱动定位和排序；新增测试覆盖脚底交叉前后 Stack 顺序。
- 下一步：复核 diff、提交，再用可自动还原的 mutant 证明新测试会红并复绿。
- 已跑验证：新增测试 1/1、stage transform 7/7、battle screen 27/27、focus nav 8/8、mechanics presentation 3/3 全绿；`flutter analyze --no-pub lib test` 0 issue；format 0 changed。
- 阻塞项：无。
