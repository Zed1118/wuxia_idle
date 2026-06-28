# 审计修复第一批计划（2026-06-28）

## 目标

基于 2026-06-28 三份审计报告，先完成低风险事实修复与诊断；追加推进时已对 25/30 层塔 Boss 做窄范围数值/phase 修复，不改核心战斗公式。

## 分支

- `codex/audit-fix-plan`
- worktree: `.worktrees/codex-audit-fix-plan`

## 验收标准

- production 新档单人空手首章战斗路径有红线测试覆盖。
- 桃花岛银两总量使用真实 7 建筑配置做断言，旧 52,200 口径不再作为真实配置结论。
- 强化材料供需有只读模拟测试，能量化 `+15/+30/+49` 的磨剑石与心血结晶期望。
- 被动离线 fallback 不产银两的当前口径被测试固定，不引入在线 buff 或加速。
- 爬塔 24→25、29→30 的 Boss 体感有诊断覆盖；25/30 Boss 总 baseHp/baseAttack 不低于前一普通层，且二阶段在样本中稳定触发。
- targeted tests 与 touched-file analyze 通过。

## 任务切片

1. 建立计划文件并跑基线验证。
2. TDD 补 `production onboarding` 首章战斗红线测试。
3. TDD 修正桃花岛真实总银两 sink 测试与旧口径说明。
4. TDD 新增强化材料供需只读模拟。
5. TDD 固化被动离线 fallback 银两口径。
6. TDD 补爬塔 Boss 体感诊断。
7. 追加推进：TDD 把塔诊断升级为验收，修复 25/30 Boss 数值与 phase。
8. 更新恢复点，运行 targeted tests/analyze，按小切片提交。

## 当前恢复点

- 状态：本批修复计划与追加塔 Boss 修复已完成，等待人工/Claude review 与合并。
- 最后完成：25/30 层 Boss 调整为高于前一普通层的单体压强，并配置二阶段；targeted tests 与 touched-file analyze 全部通过。
- 下一步：由主窗口或 Claude 复核 `codex/audit-fix-plan` 分支，确认后合并。
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
  - `dart format test/tools/tower_boss_feel_diagnostic_test.dart`
  - `flutter test test/tools/tower_boss_feel_diagnostic_test.dart`
  - `flutter test test/data/game_repository_test.dart test/features/onboarding/onboarding_first_30min_battle_test.dart test/features/taohua_island/taohua_island_config_test.dart test/features/taohua_island/island_upgrade_curve_b_test.dart test/tools/enhancement_material_supply_test.dart test/features/seclusion/application/offline_passive_service_test.dart test/features/seclusion/application/offline_passive_redline_test.dart test/features/seclusion/application/offline_passive_settle_test.dart test/features/seclusion/application/offline_recap_detail_test.dart test/tools/tower_boss_feel_diagnostic_test.dart`
  - `flutter analyze test/features/onboarding/onboarding_first_30min_battle_test.dart test/features/taohua_island/taohua_island_config_test.dart test/features/taohua_island/island_upgrade_curve_b_test.dart test/tools/enhancement_material_supply_test.dart test/features/seclusion/application/offline_passive_settle_test.dart test/tools/tower_boss_feel_diagnostic_test.dart`
  - `flutter test test/tools/enhancement_material_supply_test.dart`
  - `dart format test/features/tower/domain/tower_floor_def_test.dart test/tools/tower_boss_feel_diagnostic_test.dart`
  - `flutter test test/data/game_repository_test.dart test/features/tower/domain/tower_floor_def_test.dart test/tools/tower_boss_feel_diagnostic_test.dart`
  - `flutter analyze test/tools/tower_boss_feel_diagnostic_test.dart test/features/tower/domain/tower_floor_def_test.dart`
- 阻塞项：无。
