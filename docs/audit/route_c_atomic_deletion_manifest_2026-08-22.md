# 路线 C · 旧 3v3 原子删除清单

> 初始基线：`c2c55784`；删除候选工程基线：`01bf00fe`（2026-08-22，北京时间）
> 状态：`DELETE_CANDIDATE_MATERIALIZED / EXTERNAL_MERGE_GATE_LOCKED`

## 已完成前置

- 主线、爬塔、扫荡、远征、断魂庄五个生产消费面均永久走 Phase 0A；远征与
  断魂庄的新建入口已在 UI 和应用服务边界锁为恰好一名角色。
- 五个灰度门、旧 BattleScreen Host、模块旧 runner 与多人回退均已删除。
- 历史多人远征/断魂庄会话仅作为旧存档兼容在入口恢复时按既定事务安全退役；
  奖励选择态保留，现行生产 API 不再能制造新的多人会话。
- HP/真气、补给、阶段、失败、恢复、奖励与门票事务继续由原应用服务持久化。
- `numbersConfigProvider` / `dropServiceProvider` 已迁至 `combat_shared`；生产消费面负向守卫见
  `test/route_c/phase0a_production_route_contract_test.dart`。
- 仍被 Phase 0A/结算 UI 使用的共享实现已迁出待删目录：伤害公式、战后成长与
  provider 失效、周目选择、战斗统计、HUD 字阶、英雄镜头和胜利仪式。
- 伤势、恩怨、心魔镜像与旧 SFX 的 3v3 adapter 已全部收拢回
  `lib/features/battle/`；对应中立服务不再 import 或提及旧状态类型。
- 全局源码守卫已锁定：除 debug 与旧 battle 自身外，生产模块从 battle 目录只能
  import `application/domain/presentation/phase0a/`。
- 删除演练已同步清除仍指向 `battle_tap_live` / `battle_scene` / `battle_v2_*` 的可执行
  视觉工具、AB 主持脚本与专用测试；通用截图 manifest 写入器改为 route-neutral，
  历史截图和报告只在 `docs/` 留档。负向守卫保证 `tools/` 不得重新启动退役 route。
- 隔离的 `tools/phase0minus_probe` 包保留 Phase 0/0B 历史性能与美术观察资产；它不接
  生产存档、奖励或路由，也不是旧 3v3 产品引擎。其旧 AB 主持入口已删，剩余成绩明确
  不得签 Route C Gate；根项目分析口径为 `flutter analyze lib test tool`，该嵌套包按自身
  `pubspec.yaml` 独立维护。

## 候选已物化的删除包

以下内容已在独立候选中同批删除；本节保留为 merge 前范围核对，禁止拆成“先删源码、后修编译”的中间态：

1. `lib/features/battle/` 中除 `phase0a/` 外的旧 domain/application/presentation；基线统计 62 个 Dart 文件，候选中已删除。
2. 旧 `BattleScreen` debug 菜单、visual route 与 62 个旧战斗验收路由；候选中已删除，历史截图原位保留并标注“路由已删”。
3. 已收拢到旧 battle 目录、随旧核同批删除的临时适配：
   - `legacy_battle_injury_adapter.dart`；
   - `legacy_enmity_battle_modifier.dart`；
   - `legacy_inner_demon_mirror_builder.dart`；
   - `legacy_battle_sfx.dart`；
   - `legacy_hero_camera_deriver.dart`；
   - `legacy_3v3_combatant_adapter.dart` 与 `battle_resolution.dart`。
4. 仅验证上述旧实现的测试与诊断；基线直接 import 核心旧入口的静态口径为 145 个
   测试文件，另有旧表现组件测试已按删除编译闭包纳入。共享 RPG、Phase 0A、战绩册、
   结算 UI 和群战内容测试未随旧核误删。
5. GDD/CLAUDE/PROGRESS 当前态已随候选同步；fresh build_runner、全量 analyze/test、Mac build/Profile 必须在最终候选提交冻结后复跑，Windows 构建/实机复验仍待外部设备。

## 硬 Gate

取证前先执行
[`docs/phase0/route-c-external-gate-preflight.md`](../phase0/route-c-external-gate-preflight.md)
定义的生产版预检。旧 `phase0minus_probe` 成绩和 `battle_tap_live` AB 包不得纳入
Route C 删除裁决。

全局删除候选仅在以下证据同时成立后 merge：

- 整合态 Mac 工程 Gate 与自动目检通过；
- Windows 本地物理机按 `docs/phase0/phase0a-windows-physical-gate.md` 通过生产兼容性矩阵，且证据 commit 与本删除基线一致。

2026-08-23 用户取消六人真人 Gate，并将 Windows 标准由目标最低档性能 Gate 改为本地物理机生产兼容性 Gate。当前联网实体机具备签字资格，但仍须取得与最终候选同 commit 的原始矩阵证据；本 Gate 不定义产品最低配置。证据完成前不能把候选误报为已合入主线或已发布。

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
最终 merge 时以 Gate 对应候选 commit 重新核对源码/测试闭包；不得沿用 08-18 或初始
`c2c55784` 的旧计数替代候选树与证据清单。
