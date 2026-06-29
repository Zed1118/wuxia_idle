# 2026-06-29 通用空状态与锁定态视觉统一

## 目标

- 在 `lib/shared/widgets/wuxia_ui/` 新增可复用水墨空状态/锁定态组件。
- 支持 `empty` / `locked` / `unavailable` 三种语义，允许标题、正文、图标与可选按钮。
- 接入低冲突生产路径，保持业务行为不变。

## 分支

- `codex/visual-empty-locked-states`
- worktree: `/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/visual-empty-locked-states`

## 验收标准

- 新组件视觉水墨克制，不使用 Material 默认饱和色。
- UI 中文文案集中在 `UiStrings` 或由调用方已有集中字符串传入，不在业务调用点新增散落中文。
- 不新增业务功能、解锁规则、催促式留存、目标追踪、缺口提醒或来源聚合。
- 生产接线证据：至少接入资源总览空/不可用态；若风险低，再接入存档空槽外壳。
- Targeted widget test 覆盖 title/body/icon/action 渲染。
- 运行 `dart run build_runner build --delete-conflicting-outputs`、目标测试、`flutter analyze`、`git diff --check`。
- 工作区最终干净，tip commit 前缀为 `[READY]`。

## 任务切片

1. 读取 `AGENTS.md`、`CLAUDE.md`、`docs/spec/rejected_task_registry.md`。
2. 定位共享 UI 组件和低冲突空态调用点。
3. 先写 `InkEmptyState` widget test 并确认红灯。
4. 实现共享组件、集中通用文案、barrel export。
5. 接入资源总览分区空态与读取不可用态。
6. 视风险接入存档空槽视觉外壳，保持点击/确认流程不变。
7. 跑验收命令并修复问题。
8. 更新恢复点，提交并打 `[READY]`。

## 收口记录

- 已新增 `InkEmptyState` 共享组件，覆盖 empty / locked / unavailable 三态。
- 已接入存档选择屏空槽外壳；点击空槽仍走原「新开江湖」确认流程。
- 未改任何解锁、存档、删除、重命名或新建逻辑。
