# 路线 C · 旧 3v3 原子删除清单

> 基线：`c2c55784`（2026-08-22，北京时间）  
> 状态：`CONSUMER_CUTOVER_COMPLETE / GLOBAL_DELETE_GATE_LOCKED`

## 已完成前置

- 主线、爬塔、扫荡、远征、断魂庄五个生产消费面均永久走 Phase 0A。
- 五个灰度门、旧 BattleScreen Host、模块旧 runner 与多人回退均已删除。
- 历史多人远征/断魂庄会话在入口恢复时按既定事务安全退役；奖励选择态保留。
- HP/真气、补给、阶段、失败、恢复、奖励与门票事务继续由原应用服务持久化。
- `numbersConfigProvider` / `dropServiceProvider` 已迁至 `combat_shared`；生产消费面负向守卫见
  `test/route_c/phase0a_production_route_contract_test.dart`。

## 当前剩余删除包

以下内容必须在同一删除批完成，禁止拆成“先删源码、后修编译”的中间态：

1. `lib/features/battle/` 中除 `phase0a/` 外的旧 domain/application/presentation；当前 63 个 Dart 文件。
2. 旧 `BattleScreen` debug 菜单、visual route 与 62 个旧战斗验收路由；历史截图原位保留并标注“路由已删”。
3. 仅服务旧引擎的外部适配：
   - `InjuryService.applyBattleInjuries`（保留中立 `applySettlementInjuries`）；
   - `InnerDemonService.buildMirrorEnemyTeam`（生产心魔已走 `mapInnerDemon`）；
   - `EnmityBattleModifier.bakeMultipliers`（保留仍被江湖规则消费的中立事实）；
   - `audio_assets.dart` 中接收 `BattleAction` / `BattleState` 的旧 SFX 映射（保留 Phase 0A SFX 与 BGM enum）。
4. 仅验证上述旧实现的测试与诊断；当前静态口径约 164 个测试文件。共享 RPG、Phase 0A、战绩册和群战内容测试不随旧核误删。
5. 删除后同步 GDD/CLAUDE/PROGRESS 的 3v3 漂移指针，并执行 fresh build_runner、全量 analyze/test、Mac build 与 Windows 构建/实机复验。

## 硬 Gate

全局删除提交仅在以下证据同时成立后执行：

- 整合态 Mac 工程 Gate 与自动目检通过；
- 六人主观 Gate 具备有效原始记录；
- 目标最低档 Windows 物理机按 `docs/phase0/phase0a-windows-physical-gate.md` 过线，且证据 commit 与本删除基线一致。

目前 Windows 物理机与六人原始证据均未取得，因此本批只完成生产切换和删除包冻结，不能把旧全局引擎删除伪报为完成。

## 删除后负向核对

```bash
flutter test --no-pub test/route_c/phase0a_production_route_contract_test.dart
rg -n "BattleScreen|BattleState|battleProvider|StageBattleSetup|legacy_3v3" lib \
  --glob '*.dart' --glob '!**/phase0a/**'
flutter analyze --no-pub lib test
flutter test --no-pub
flutter build macos --debug
flutter build windows --debug
```

基线事实底座与历史定量口径见 `docs/audit/legacy_3v3_removal_scope_2026-08-18.md`。
