# 路线 C · 旧 3v3 原子删除清单

> 初始基线：`c2c55784`；删除前置收口截至当前分支 HEAD（2026-08-22，北京时间）
> 状态：`CONSUMER_CUTOVER_COMPLETE / GLOBAL_DELETE_GATE_LOCKED`

## 已完成前置

- 主线、爬塔、扫荡、远征、断魂庄五个生产消费面均永久走 Phase 0A。
- 五个灰度门、旧 BattleScreen Host、模块旧 runner 与多人回退均已删除。
- 历史多人远征/断魂庄会话在入口恢复时按既定事务安全退役；奖励选择态保留。
- HP/真气、补给、阶段、失败、恢复、奖励与门票事务继续由原应用服务持久化。
- `numbersConfigProvider` / `dropServiceProvider` 已迁至 `combat_shared`；生产消费面负向守卫见
  `test/route_c/phase0a_production_route_contract_test.dart`。
- 仍被 Phase 0A/结算 UI 使用的共享实现已迁出待删目录：伤害公式、战后成长与
  provider 失效、周目选择、战斗统计、HUD 字阶、英雄镜头和胜利仪式。
- 伤势、恩怨、心魔镜像与旧 SFX 的 3v3 adapter 已全部收拢回
  `lib/features/battle/`；对应中立服务不再 import 或提及旧状态类型。
- 全局源码守卫已锁定：除 debug 与旧 battle 自身外，生产模块从 battle 目录只能
  import `application/domain/presentation/phase0a/`。

## 当前剩余删除包

以下内容必须在同一删除批完成，禁止拆成“先删源码、后修编译”的中间态：

1. `lib/features/battle/` 中除 `phase0a/` 外的旧 domain/application/presentation；当前 62 个 Dart 文件。
2. 旧 `BattleScreen` debug 菜单、visual route 与 62 个旧战斗验收路由；历史截图原位保留并标注“路由已删”。
3. 已收拢到旧 battle 目录、随旧核同批删除的临时适配：
   - `legacy_battle_injury_adapter.dart`；
   - `legacy_enmity_battle_modifier.dart`；
   - `legacy_inner_demon_mirror_builder.dart`；
   - `legacy_battle_sfx.dart`；
   - `legacy_hero_camera_deriver.dart`；
   - `legacy_3v3_combatant_adapter.dart` 与 `battle_resolution.dart`。
4. 仅验证上述旧实现的测试与诊断；当前直接 import 核心旧入口的静态口径为 145 个
   测试文件，另有旧表现组件测试须按删除编译闭包纳入。共享 RPG、Phase 0A、战绩册、
   结算 UI 和群战内容测试不随旧核误删。
5. 删除后同步 GDD/CLAUDE/PROGRESS 的 3v3 漂移指针，并执行 fresh build_runner、全量 analyze/test、Mac build 与 Windows 构建/实机复验。

## 硬 Gate

取证前先执行
[`docs/phase0/route-c-external-gate-preflight.md`](../phase0/route-c-external-gate-preflight.md)
定义的生产版预检。旧 `phase0minus_probe` 成绩和 `battle_tap_live` AB 包不得纳入
Route C 删除裁决。

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
最终删除时以 Gate 对应 commit 重新生成源码/测试闭包；不得沿用 08-18 或初始
`c2c55784` 的旧计数直接 `git rm`。
