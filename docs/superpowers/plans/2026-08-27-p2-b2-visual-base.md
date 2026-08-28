# P2 批二视觉基线

## 目标与基线

- 分支：`codex/p2-b2-visual-base-20260827`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-p2-b2-visual-base`
- 起点：集成候选 `870f9832 [BLOCKED] G2候选集成态待8项真人试玩`
- 目的：在不修改原集成 worktree 的前提下，吸收批二视觉路径必需的 N16 防御可见修复、批一图层渲染 y 同源修复与注释订正，作为批二三项串行堆叠基线。

## 已吸收依赖

- N16：`eb2909fb [READY] 修复防御特效零像素渲染`
- 图层同源：`2a77d309` + `1ea2646c [READY] 完成图层排序同源验收`
- 图层注释：`7fbf324e [READY] 修正图层排序注释`

## 验证

- 防御表现：3/3
- actor 实际 Stack 顺序：1/1
- stage transform：7/7
- battle screen：28/28
- mechanics presentation：5/5
- `flutter analyze --no-pub lib test`：0 issue
- 原集成、main、各来源分支不修改；本 worktree 提交后保持 clean。

## 边界

本分支只建立依赖基线，不计入批二 3 项表现层验收门，不作视觉方向实现，不 merge、不 push、不碰 main。
