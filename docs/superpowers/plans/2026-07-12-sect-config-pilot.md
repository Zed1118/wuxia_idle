# 宗门月结配置 Module 试点执行计划

## 目标

在不改变任何游戏行为或数值的前提下，将 `SectMonthlyTickService` 从完整
`NumbersConfig` 解耦到其唯一实际依赖 `SectEventDef`，作为配置模块化的最小试点。

## 分支与工作区

- 分支：`codex/config-module-sect-pilot`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/config-module-sect-pilot`
- 基线：`main` 的 `62164693`

## 验收标准（CLAUDE.md §8.2）

- [ ] 生产接线：`sectMonthlyTickServiceProvider` 从真实
  `numbersConfigProvider` 取 `.sectEvent` 并注入服务。
- [ ] targeted tests：月结纯服务、宗门 Isar 持久化及相邻宗门战斗集成测试通过。
- [ ] 静态检查：`flutter analyze --no-pub` 为 0 issue。
- [ ] 红线说明：不改 YAML、数值、公式、三系、在线/离线、商业化红线或中文文案。
- [ ] 残留风险：交付恢复点明确记录未覆盖项；本任务无 UI，无视觉/键鼠验收要求。
- [ ] 仓库卫生：仅提交相关源码、测试与计划，worktree 干净。
- [ ] 就绪信号：tip commit 以 `[READY]` 开头。

## 任务切片

1. 记录设计、边界、恢复点并提交。
2. RED：测试先改为期望的 `config: SectEventDef` API，确认生产代码尚不满足。
3. GREEN：修改服务与 provider，清理只为宽依赖存在的 test stub。
4. 运行 targeted tests、格式化及 analyze；按改动范围决定是否需要全量。
5. 更新恢复点、提交验证证据并打 `[READY]` 冻结。

## 当前恢复点

- 状态：进行中（设计完成，尚未修改测试/生产代码）。
- 最后完成：确认服务只读取 `numbers.sectEvent`；确认 3 个构造调用点；已读取
  `docs/spec/rejected_task_registry.md`，本任务不命中已否方向。
- 下一步：先修改两组测试为新 `config:` API，运行 targeted test 观察预期编译失败。
- 已跑验证：基线 `flutter analyze --no-pub`，0 issue。
- 阻塞项：无。

