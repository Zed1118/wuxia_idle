# 2026-06-29 今晚挂机任务 03：爬塔单人路径打磨 + 塔 20/25/30 Boss 机制增强

## 目标

- 爬塔只按境界解锁，不新增弟子入队门槛；面向高境界单人爬塔补足敌阵、机制与提示层支持。
- 强化塔 20/25/30 Boss：优先使用既有 `bossPhases`、`mechanic`、`skills`、`enemyTeam` 范式补阶段控场、多目标压力、反制窗口，避免单纯堆数值。
- 保持 Boss 血量 < 1M、配置基础表值红线、三系锁死与在线=离线红线。

## 分支

- `codex/night-tower-solo-boss-mechanics`

## 验收标准

- `data/towers.yaml` 的 20/25/30 层有明确机制升级，且 Boss HP 仍低于红线。
- 塔层解锁仍仅依赖 `requiredRealm`/顺序进度，不按弟子数量或队伍人数锁门。
- 高境界单人爬塔路径有 targeted simulation 或测试覆盖，能说明 20/25/30 的体感目标与剩余风险。
- 新增/调整的 Boss skill、phase、mechanic 引用均通过现有 schema/redline 测试。
- 完成后有小切片 commit，最终提交前更新本恢复点。

## 任务切片

1. 读取必读文档，确认现状、分支与恢复协议。
2. 建计划文件并提交，建立可恢复起点。
3. 读取塔配置、Boss phase/schema、现有模拟测试，确定最小改动面。
4. 调整塔中后段单人路径与 20/25/30 Boss 机制。
5. 增加或更新 targeted tests/simulation，覆盖红线、引用、单人路径诊断。
6. 运行 targeted verification，必要时迭代。
7. 更新恢复点、提交最终切片并汇报。

## 当前恢复点

- 状态：实现完成，targeted verification 已通过，待提交最终切片。
- 最后完成：`data/towers.yaml` 20/25/30 层改为主 Boss + 护法/影侍多目标压力；20 层补三段阶段反扑，25/30 层扩为三段；6 个 Boss 主敌均标 `isBoss: true`；加载红线从“Boss 固定 1 敌”改为“Boss 层 1-3 敌且至少 1 个 isBoss 主敌”；测试覆盖后段 Boss 机制与塔挑战不按队伍人数锁门。
- 下一步：提交最终切片并汇报分支、提交、验证、风险。
- 已跑验证：
  - `ruby -ryaml -e ...`：20/25/30 多目标 Boss 结构、阶段、弱点与血量红线轻量检查通过。
  - `dart run build_runner build --delete-conflicting-outputs`：补齐本地生成产物，112 outputs，生成文件未进入 git diff。
  - `flutter test --no-pub --no-test-assets test/features/tower/domain/tower_floor_def_test.dart test/features/tower/application/tower_progress_service_test.dart test/data/boss_phase_redline_test.dart test/data/weakness_redline_test.dart`：53 tests passed。
  - `flutter analyze`：No issues found。
- 阻塞项：无。
