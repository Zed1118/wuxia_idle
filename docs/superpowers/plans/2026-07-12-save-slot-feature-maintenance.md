# 存档槽启动 Feature 维护编排执行计划

## 目标

将战绩册、兵器谱启动回填从 `IsarSetup` 移到 save-slot application 编排，保持
现有幂等、容错、迁移、恢复和多槽行为不变。

## 分支与工作区

- 分支：`codex/save-slot-feature-maintenance`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/save-slot-feature-maintenance`
- 基线：`main` 的 `62164693`

## 验收标准（CLAUDE.md §8.2）

- [ ] 生产接线：`SaveSelectScreen` 已有档/新档入口均通过 save-slot 启动 service 开槽。
- [ ] data 边界：`isar_setup.dart` 不再依赖 battle_record/weapon_codex application implementation。
- [ ] targeted tests：新编排测试、两项 feature 回填、SaveSelect、迁移、恢复和多槽测试通过。
- [ ] 静态检查：`flutter analyze --no-pub` 为 0 issue。
- [ ] 红线说明：不改数值、三系、在线/离线、反主流项、文案、schema 或 saveVersion。
- [ ] 存档门禁：验证旧档迁移、失败回滚和多槽隔离；路径/文件名/恢复策略不变。
- [ ] 残留风险：记录未覆盖项；本任务无 UI 外观/交互变更，不要求视觉 smoke。
- [ ] 仓库卫生：仅提交相关源码、测试与计划，worktree 干净。
- [ ] 就绪信号：tip commit 以 `[READY]` 开头。

## 任务切片

1. 提交设计、边界与恢复点。
2. RED：新增 save-slot 启动维护行为测试与 data→feature application 导入守卫。
3. GREEN：新增 `SaveSlotStartupService`，从 `IsarSetup` 删除两个 feature 回填，迁移真实入口。
4. 跑直接测试、存档迁移/恢复/多槽回归与 analyze。
5. 更新恢复点并以 `[READY]` tip 冻结。

## 当前恢复点

- 状态：进行中（完成证据核验与设计，尚未修改测试/生产代码）。
- 最后完成：确认回填位于 `_ensureSaveData()` 且只在已有 SaveData 分支运行；确认真实
  开槽入口为 `SaveSelectScreen._enterSlot/_confirmNewGame`；已读取 rejected registry，
  不命中已否方向。
- 下一步：先写新启动 service 行为测试和 import 守卫，运行得到预期 RED。
- 已跑验证：`flutter pub get`；build_runner 写 114 个本地忽略输出；
  基线 `flutter analyze --no-pub` 0 issue。
- 阻塞项：无。

