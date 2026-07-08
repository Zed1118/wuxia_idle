# 通宵体检修复(批5/4/2) · 可恢复计划

**日期**:2026-07-07 夜 · **分支**:worktree-overnight-audit-fixes(基 origin/main 0f9eede6)
**模式**:用户离线 8h 自主 · 逐批 TDD → 验证 → merge main → push → CI
**来源**:docs/audit/full_project_bughunt_2026-07-07.md 修复候选表 + 体检候选表

## 执行序(风险后调 · 先 bank 安全高值,批2 结构改压最后)

1. **批5 存档/负数防御**:P1-7(强化 txn 内校验+防抖 / 桃花岛 check-then-act / settle 旧快照覆盖)+ P1-10(迁移段2 版本门)+ P2 存档防御。低风险清晰守卫测。
2. **批4 战斗小修**:P0-4(interveneNow 边界)+ P1-9(敌 ult 进 AI)+ P1-12(iconPath 哨兵)+ P1-14(AOE 记账语义)。中风险,P1-9 需难度复测。
3. **批2 战斗 wiring**(结构改·xhigh 域):P0-1/2 formation/terrain/wave 进 tick/stepOne 生产路径 + P2 波间清 actorQueue。最高风险,压最后;若半途留 WIP 不 merge。

## 自主拍板决策(用户离线授权)

- **P1-14 AOE 记账**:改「每施放记 1」(非每命中记 N)。理由:熟练度/修炼度反映施放次数,AOE 记 N 会成刷熟练捷径(软 treadmill 违克制哲学)。以代码核实实现路径为准。
- **P1-9 敌 ult**:**启用**敌 ultimate 进 AI。理由:Boss kit 配的 ult 纯摆设、floor30 最强 AOE 从未用=Boss 弱于设计。启用后跑难度/e2e 复测,on-level 仍可胜则保留;若破坏可胜性则回退或调 boss 血/放招次数。

## 恢复点

- **2026-07-07 Codex 接手**:
  - 批5已完成:P1-7 强化/桃花岛 txn 内防负数与 P1-10 段2迁移版本门。
  - 批4已完成:P0-4 interveneNow 边界、P1-9 敌方 ultimate AI、P1-12 iconPath 显式清空、P1-14 AOE 每施放记 1。
  - 批2已完成:P0-1/2 MassBattle/LightFoot 的 formation/terrain/wave 接入 tick/stepOne 生产路径;wave 间清 actorQueue/pendingTargets。
  - 已验证:
    - `flutter test test/features/taohua_island/island_action_service_test.dart test/features/equipment/application/enhancement_persist_test.dart test/data/save_migration_version_gate_test.dart test/features/battle/intervene_determinism_test.dart test/features/battle/domain/battle_ai_test.dart test/features/inner_demon/inner_demon_mirror_injection_test.dart test/features/battle/application/battle_resolution_test.dart test/features/battle/domain/strategy/light_foot_strategy_test.dart test/features/battle/domain/strategy/mass_battle_strategy_test.dart`
    - `flutter analyze` 仅剩既有 info:`docs/audit/early_difficulty_gate_probe_2026_07_05.dart` 文件名非 lower_case。

## 生产路径关键事实(批2 Phase 0 已验)

- 生产战斗循环 = `battle_providers.dart`:`advance`→`_strategy.tick`(快进)/`advanceOneAction`→`_strategy.stepOne`(常速,battle_playback_controller.dart:449)。**从不调 runToEnd**。
- mass/light_foot 的 formation/terrain/wave 烘焙全在 `runToEnd` 入口 → 生产 no-op。修法核心=把烘焙+波次逻辑搬进 tick/stepOne 路径。
