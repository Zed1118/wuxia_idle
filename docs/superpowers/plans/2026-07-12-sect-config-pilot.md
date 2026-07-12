# 宗门月结配置 Module 试点执行计划

## 目标

在不改变任何游戏行为或数值的前提下，将 `SectMonthlyTickService` 从完整
`NumbersConfig` 解耦到其唯一实际依赖 `SectEventDef`，作为配置模块化的最小试点。

## 分支与工作区

- 分支：`codex/config-module-sect-pilot`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠/.worktrees/config-module-sect-pilot`
- 基线：`main` 的 `62164693`

## 验收标准（CLAUDE.md §8.2）

- [x] 生产接线：`sectMonthlyTickServiceProvider` 从真实
  `numbersConfigProvider` 取 `.sectEvent` 并注入服务。
- [x] targeted tests：月结纯服务、宗门 Isar 持久化及相邻宗门战斗集成测试通过。
- [x] 静态检查：`flutter analyze --no-pub` 为 0 issue。
- [x] 红线说明：不改 YAML、数值、公式、三系、在线/离线、商业化红线或中文文案。
- [x] 残留风险：交付恢复点明确记录未覆盖项；本任务无 UI，无视觉/键鼠验收要求。
- [x] 仓库卫生：仅提交相关源码、测试与计划，worktree 干净。
- [x] 就绪信号：冻结流程将以 `[READY]` 空提交作为最终 tip。

## 任务切片

1. 记录设计、边界、恢复点并提交。
2. RED：测试先改为期望的 `config: SectEventDef` API，确认生产代码尚不满足。
3. GREEN：修改服务与 provider，清理只为宽依赖存在的 test stub。
4. 运行 targeted tests、格式化及 analyze；按改动范围决定是否需要全量。
5. 更新恢复点、提交验证证据并打 `[READY]` 冻结。

## 当前恢复点

- 状态：实现与验证完成，待 `[READY]` tip 冻结。
- 最后完成：服务字段/构造器改为 `SectEventDef config`；production provider 从
  `numbersConfigProvider` 注入 `.sectEvent`；3 个调用点已迁移。测试 RED 由
  `dart analyze` 观察到 6 个预期的 `config` 未定义/`numbers` 缺失错误，随后 GREEN。
- 下一步：提交本恢复点，并追加 `[READY]` tip；冻结后不再写此 worktree。
- 已跑验证：
  - `dart run build_runner build --delete-conflicting-outputs`：写入 114 个本地忽略生成输出；
  - `flutter test --no-pub test/features/sect/sect_monthly_tick_service_test.dart test/features/sect/sect_isar_persistence_test.dart test/features/sect/sect_battle_integration_test.dart`：23 tests passed；
  - `flutter analyze --no-pub`：0 issue；
  - `dart format --output=none --set-exit-if-changed <4 touched files>`：0 changed；
  - `git diff --check`：通过。
- 残留风险：未跑本分支全量测试；本改动是单 feature 构造依赖收窄，批次前一分支已有全量绿，本分支按 §8.0 采用 targeted + analyze。未修改 UI，无视觉验收项。首次 RED 的 `flutter test` 因 worktree 缺少自身 `.dart_tool` 误用父仓配置而触发 Flutter native-assets 工具崩溃；已通过本 worktree `flutter pub get` + build_runner 修复，之后 targeted 测试正常。
- 阻塞项：无。
