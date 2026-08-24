# 水墨招式三垂直样片计划

## 目标

在不接入生产战斗、不改变 Phase 2 数据合同与数值的前提下，提供三个可动态重播的 Flutter 视觉样片：轻墨普攻、破招断势、R 清场入画。

## 分支

- branch: `codex/ink-vfx-vertical-slices-20260824`
- baseline: `e292d3a0`
- worktree: `/Users/a10506/.codex/worktrees/ink-vfx-demo/挂机武侠`

## 文件白名单

- `docs/superpowers/plans/2026-08-24-ink-vfx-vertical-slices.md`
- `lib/features/debug/application/visual_route.dart`
- `lib/features/debug/presentation/visual_route_host.dart`
- `lib/features/debug/presentation/ink_vfx_vertical_slice_demo.dart`
- `lib/shared/strings.dart`
- `test/features/debug/ink_vfx_vertical_slice_demo_test.dart`
- `test/features/debug/visual_route_test.dart`

## 验收标准

- 三个稳定 debug route 可分别打开轻墨、破招、入画样片，且同页按钮可切换并重播。
- 三个样片共用既有角色、敌人和水墨场景资产；不复制外部视频素材。
- 仅表现层动画，不读写战斗状态、数值、存档或 Phase 2 合同。
- UI 文案集中在 `UiStrings`；表现参数集中在 Demo token 类；不引入依赖或游戏引擎。
- Widget test 覆盖三个 route、三种切换和动画重播；先取得真实红测。
- `flutter analyze --no-pub` 与相关 targeted tests 通过。
- 1280x720、1440x900 至少各完成一轮视觉 smoke；无布局溢出。

## 红线影响

- 数值硬红线：不触及。
- 境界/装备/心法锁：不触及。
- 在线=离线：不触及。
- 反主流清单：不触及。
- 中文文案：仅新增至 `UiStrings` 集中层。
- 生产接线：本任务经用户明确要求为视觉 Demo，刻意保持 debug-only；不得误接生产入口。

## 任务切片

1. 增加 route 与 widget 契约红测。
2. 实现共享舞台、三种 Painter 与交互控制。
3. 接入 VisualRouteHost，补 route roundtrip。
4. 跑 targeted/analyze，执行常规视口动态目检。

## 当前恢复点

- 状态：完成，等待用户视觉决策；未合并、未接入生产战斗。
- 最后完成：三个 debug route、共享水墨舞台、三类动态 Painter、切换/重演控制和定向测试。
- 下一步：由用户从飞白断痕、一笔截势、江山入墨中确认一个方向，再另立生产任务包。
- 已跑验证：真实红测后 8 个 targeted tests 通过；相关 6 文件 scoped analyze 为 0 问题；`git diff --check` 通过；六张 1280x720 / 1440x900 截图无溢出或运行异常。
- 分支边界：`main == origin/main == e292d3a0`；所有变更仅在 `codex/ink-vfx-vertical-slices-20260824` 独立 worktree。
- 阻塞项：无。
