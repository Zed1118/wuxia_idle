# 存档槽启动 Feature 维护编排执行计划

## 目标

将战绩册、兵器谱启动回填从 `IsarSetup` 移到 save-slot application 编排，保持
现有幂等、容错、迁移、恢复和多槽行为不变。

## 分支与工作区

- 分支：`codex/save-slot-feature-maintenance`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/save-slot-feature-maintenance`
- 基线：`main` 的 `62164693`

## 验收标准（CLAUDE.md §8.2）

- [x] 生产接线：`SaveSelectScreen` 已有档/新档入口均通过 save-slot 启动 service 开槽。
- [x] data 边界：`isar_setup.dart` 不再依赖 battle_record/weapon_codex application implementation。
- [x] targeted tests：新编排测试、两项 feature 回填、SaveSelect、迁移、恢复和多槽测试通过。
- [x] 静态检查：`flutter analyze --no-pub` 为 0 issue。
- [x] 红线说明：不改数值、三系、在线/离线、反主流项、文案、schema 或 saveVersion。
- [x] 存档门禁：验证旧档迁移、失败回滚和多槽隔离；路径/文件名/恢复策略不变。
- [x] 残留风险：记录未覆盖项；本任务无 UI 外观/交互变更，不要求视觉 smoke。
- [x] 仓库卫生：仅提交相关源码、测试与计划，worktree 干净。
- [x] 就绪信号：冻结流程将以 `[READY]` 空提交作为最终 tip。

## 任务切片

1. 提交设计、边界与恢复点。
2. RED：新增 save-slot 启动维护行为测试与 data→feature application 导入守卫。
3. GREEN：新增 `SaveSlotStartupService`，从 `IsarSetup` 删除两个 feature 回填，迁移真实入口。
4. 跑直接测试、存档迁移/恢复/多槽回归与 analyze。
5. 更新恢复点并以 `[READY]` tip 冻结。

## 当前恢复点

- 状态：实现与验证完成，待 `[READY]` tip 冻结。
- 最后完成：新增 `SaveSlotStartupService`；已有档/新档 production path 均改为先开槽、
  后执行 BossMemory/EquipmentCatalog 幂等维护；`IsarSetup` 删除两个 feature application
  import 与调用，保留角色字段完整性修复。RED 先观察到启动 service 文件/符号不存在，
  GREEN 后新增 3 项边界行为测试全过。
- 下一步：提交本恢复点，追加 `[READY]` tip，冻结后不再写此 worktree。
- 已跑验证：
  - `flutter pub get`；build_runner 写 114 个本地忽略输出；
  - `flutter test --no-pub <13 个存档/回填/SaveSelect 测试文件>`：53 tests passed；
  - 上述 53 项覆盖旧版本迁移、恢复候选与中断/失败回滚、多槽隔离、两项 feature 回填；
  - `flutter analyze --no-pub`：0 issue；
  - touched files format check：0 changed；`git diff --check`：通过；
  - `flutter test --no-pub --reporter json | jq ...`：`success: true`，346302 ms，
    无 error 或 non-success testDone 事件。
- 残留风险：未执行 Windows 实机/发布构建；本批没有 UI 外观变更。feature 维护仍采用
  既有 best-effort 策略，异常只记录 debug 日志并允许进档；这保持旧行为，但坏档时对应
  图鉴可能暂缺，后续正常进档仍会幂等重试。
- 阻塞项：无。
