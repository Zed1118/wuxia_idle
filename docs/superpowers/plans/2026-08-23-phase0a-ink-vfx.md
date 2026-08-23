# Phase 0A 顺滑水墨战斗特效

## 目标

在表现层增强普攻命中、击杀与群体清场的水墨残影、墨溅、笔锋和宣纸晕染，同时控制 active VFX 的中间帧重绘、生命周期和同屏上限。不得改 reducer、stage mapper、`data/stages.yaml` 或伤害/血量数值。

## 范围

- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-wt-ink-vfx`
- branch：`codex/ink-vfx`
- 允许：`phase0a_vfx_controller.dart`、`phase0a_presentation_tokens.dart`、`phase0a_battle_screen.dart` 的 VFX/painter 局部、对应 presentation tests、本计划。
- 禁止：主仓、分支切换、reducer、stage mapper、stages/numbers 配置、中文文案进入 Dart。

## 根因与方案

现状中 `_FeedbackLayerState` 自己启动 ticker，并在每个 active VFX 帧 `setState()`；父级 `Phase0aBattleScreen` 也有自己的 ticker/反馈状态刷新。结果是 active VFX 中间帧存在两个刷新源，反馈层与父级可能重复重建；这不是 progress 静态，而是帧源重复。另有 painter 调用点未统一透传 progress，导致部分效果的中间帧层次不足。

方案：由父状态唯一推进反馈时间，并把不可变的 `feedbackFrame` 传入反馈层；反馈层移除独立 ticker，不再自己 setState。只在父级帧推进导致 active feedback 变化时重建，静态背景/角色仍由既有边界隔离。Painter 统一接收 progress，做固定数量、确定性的笔锋/墨滴/晕染层，不使用无上限粒子。

## 验收标准

1. 普攻命中、击杀和清场中间帧有顺滑的 progress 驱动层次；critical 语义仅透传。
2. active VFX 不再由 `_FeedbackLayer` 自建 ticker；父级是唯一刷新源。
3. 单次 entry、伤害飘字居民、反馈层 active 条目和 painter 固定绘制数量均受 token 约束。
4. 坐标快照和既有事件映射保持不变；不重算伤害、不新增 gameplay 事件。
5. targeted tests、`flutter analyze` 通过，并记录 1280×720 / 1440×900 smoke 结果。
6. 更新恢复点，逐切片 commit，最终 tip commit 以 `[READY]` 开头且 worktree clean。

## 切片

- [x] S1：确认 worktree、重建计划、定位 active VFX 中间帧重绘根因。
- [ ] S2：移除反馈层重复 ticker，集中 progress 刷新并补生命周期/上限契约。
- [ ] S3：增强命中/击杀/清场 painter 的分层水墨表现，补 controller/presentation tests。
- [ ] S4：targeted tests、analyze、双常规视口 smoke，审查 diff。
- [ ] S5：提交 `[READY]` 并确认 clean。

## 当前恢复点

- 状态：已在指定 worktree，尚未编辑。
- 最后完成：确认 `codex/ink-vfx` clean；计划文件已创建。
- 下一步：先修改刷新模型，再做 painter 层次与测试。
- 已跑验证：仅分支/工作区检查。
- 阻塞项：无。移动卡顿、普攻范围和主线小怪数量属于另行 gameplay/content 任务，不在本切片实现。
