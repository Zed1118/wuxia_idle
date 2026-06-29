# 2026-06-29 今晚挂机任务 14：高周目 Boss 阶段差异

## 目标

二周目以上 Boss 不只获得周目数值/词条强化，还能通过配置追加轻量阶段变化或技能顺序变化，提升重复挑战感；一周目行为和第一梯队已合入的塔 floor20/25/30 Boss 基础机制保持不变。

## 分支

`codex/night-tier2-ngplus-boss-phases`

## 验收标准

- `cycleIndex == 1` 时现有 `bossPhases` 完全沿用，塔 floor20/25/30 已合入机制不被覆盖。
- `cycleIndex >= 2` 时可按 Boss 配置启用高周目阶段覆盖，阶段差异以阈值、解锁招、`aiMode`、`onEnterMechanic` 等既有范式表达，不新增数值 buff。
- 配置基础表 Boss 血量仍低于红线，战斗 setup 的周目缩放仍走现有 clamp，不破 Boss 血量 <1M 与项目软红线。
- 新增/调整 targeted tests 覆盖：解析、红线校验、cycle 1 零回归、cycle 2/3 阶段覆盖、塔 20/25/30 基础阶段保留。
- 跑 targeted tests 与 `flutter analyze`；若全量测试不跑，说明原因。

## 任务切片

1. [x] 读取必读文档与当前 main 合入状态，确认分支与边界。
2. [x] 写计划文件并提交恢复点。
3. [x] 扩展 Boss 阶段配置 schema：新增按周目覆盖字段，复用 `BossPhaseDef`。
4. [x] 接入战斗 setup：按 `cycleIndex` 选择运行时 Boss phases，仅影响敌方快照。
5. [x] 配置代表性主线/塔 Boss 的二周目以上阶段差异，避免覆盖一周目基础机制。
6. [x] 补 targeted tests：解析、红线、setup、关键配置诊断。
7. [x] 跑 targeted tests / analyze，按结果修正。
8. [x] 更新 backlog/PROGRESS 与本计划恢复点，做收尾提交。

## 当前恢复点

- 状态：完成，待主窗口复核/合并。
- 最后完成：`cycleBossPhases` schema、运行时选择、主线 6 个章末 Boss 与塔 10/20/25/30 高周目覆盖配置、targeted tests、backlog/PROGRESS 同步均已完成。
- 下一步：主窗口复核分支 `codex/night-tier2-ngplus-boss-phases`；如需更细手感，再跑 tower/mainline 体感诊断或真机目检。
- 已跑验证：`dart run build_runner build --delete-conflicting-outputs`（工具提示该参数已移除但生成成功，未产生 git diff）；`flutter analyze` 0 issue；`flutter test --no-pub -j1 test/data/defs/defs_test.dart test/data/boss_phase_redline_test.dart test/features/battle/enemy_cycle_scale_test.dart test/data/ngplus_boss_phase_config_test.dart` 61 passed。
- 阻塞项：无。备注：首次不带 `-j1` 的同组 targeted test 在 Flutter tool native-assets 路径触发 `Bad state: No element` 崩溃，重跑 `-j1` 已通过；CodeGraph 未初始化于当前 worktree，按项目说明未擅自执行 `codegraph init -i`。
