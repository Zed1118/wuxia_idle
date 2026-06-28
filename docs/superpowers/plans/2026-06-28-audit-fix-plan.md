# 审计修复第一批计划（2026-06-28）

## 目标

基于 2026-06-28 三份审计报告，先完成低风险事实修复与只读模拟，不改关卡、掉落、Boss 数值或核心战斗公式。

## 分支

- `codex/audit-fix-plan`
- worktree: `.worktrees/codex-audit-fix-plan`

## 验收标准

- production 新档单人空手首章战斗路径有红线测试覆盖。
- 桃花岛银两总量使用真实 7 建筑配置做断言，旧 52,200 口径不再作为真实配置结论。
- 强化材料供需有只读模拟测试，能量化 `+15/+30/+49` 的磨剑石与心血结晶期望。
- 被动离线 fallback 不产银两的当前口径被测试固定，不引入在线 buff 或加速。
- 爬塔 24→25、29→30 的 Boss 体感有只读模拟或诊断覆盖，不直接改 `data/towers.yaml`。
- targeted tests 与 touched-file analyze 通过。

## 任务切片

1. 建立计划文件并跑基线验证。
2. TDD 补 `production onboarding` 首章战斗红线测试。
3. TDD 修正桃花岛真实总银两 sink 测试与旧口径说明。
4. TDD 新增强化材料供需只读模拟。
5. TDD 固化被动离线 fallback 银两口径。
6. TDD 补爬塔 Boss 体感只读模拟。
7. 更新恢复点，运行 targeted tests/analyze，按小切片提交。

## 当前恢复点

- 状态：被动离线银两红线切片已完成，待提交。
- 最后完成：`offline_passive_settle_test` 覆盖被动结算不新建 `item_silver`，且不改动既有银两数量。
- 下一步：提交被动离线切片，然后补爬塔 Boss 体感只读诊断。
- 已跑验证：
  - `git status --short --branch`
  - `git log --oneline --decorate -12`
  - `codegraph_status`
  - `dart run build_runner build --delete-conflicting-outputs`
  - `flutter test test/features/onboarding/application/onboarding_service_test.dart test/features/taohua_island/taohua_island_config_test.dart test/features/taohua_island/island_upgrade_curve_b_test.dart test/features/seclusion/application/offline_passive_service_test.dart test/features/tower/domain/tower_floor_def_test.dart test/features/equipment/application/enhancement_service_test.dart`
  - `flutter test test/features/onboarding/onboarding_first_30min_battle_test.dart`
  - `flutter test test/data/game_repository_test.dart test/features/onboarding/onboarding_first_30min_battle_test.dart`
  - `flutter test test/features/taohua_island/taohua_island_config_test.dart test/features/taohua_island/island_upgrade_curve_b_test.dart`
  - `flutter test test/tools/enhancement_material_supply_test.dart`
  - `flutter test test/features/seclusion/application/offline_passive_service_test.dart test/features/seclusion/application/offline_passive_redline_test.dart test/features/seclusion/application/offline_passive_settle_test.dart test/features/seclusion/application/offline_recap_detail_test.dart`
- 阻塞项：无。
