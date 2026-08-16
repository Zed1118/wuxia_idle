# Phase 0A 根应用生产接线审计报告（2026-08-16 · Qoder 只读审计）

配套计划：`docs/superpowers/plans/2026-08-16-phase0a-qoder-production-wiring-audit.md`。基线 `5a107a5b`。全部计数经 rg 复核，复现命令见 §7。

## 1. 生产战斗精确链路

- **入口（BattleScreen 挂载 6 处 = 生产 4 + 调试 2）**：主线/心魔/轻功/群战统一 `mainline/presentation/stage_entry_flow.dart`（`runStageFlow`→`_StageBattleHost`→`StageBattleSetup.buildTeams`:503→`BattleScreen`:580），`runStageFlow` 调用方 4 处：`stage_list_screen.dart:228`、`inner_demon_screen.dart:100`、`light_foot_screen.dart:103`、`mass_battle_screen.dart:111`；爬塔 `tower_entry_flow.dart:823/850`；扫荡 `sweep_screen.dart:138`（headless `sweep_unit.dart:58/90`）；断魂庄 `gauntlet_entry_flow.dart:184/213`（headless `gauntlet_service.dart:392`、`gauntlet_battle_runner.dart:41`）；远征纯 headless `expedition_combat_runner.dart:25/60`；调试 `battle_test_menu.dart:1480`、`visual_route_host.dart:1597`。
- **组队**：`LineupService.apply`（`lineup_service.dart:61`，>3 人拒绝 :69）写 `SaveData.activeCharacterIds`；战斗侧 `stage_battle_setup._buildPlayerTeam` 消费（`i<3` 截断 :282；敌队 :138）。
- **战斗状态**：`BattleNotifier`（`battle_providers.dart:55`）`startBattle`:82 注入双队+strategy+seeded rng；UI Timer 驱动 `advance`:142/`advanceOneAction`:166/`step`:187，委托 `BattleStrategy.tick/stepOne`（DefaultGround/LightFoot/MassBattle 三实装）；手动介入 `interveneNow`:119（拖招插队）、`requestUltimate`:103。actionPoint 时间行动制，与 probe 实时制不同构。
- **胜负结算**：`BattleState.result` 翻转 → `BattleResolutionService.resolve`（`battle_resolution.dart:105`），生产调用 4 处：`stage_entry_flow.dart:820`(胜)/`:1036`(败)、`tower_entry_flow.dart:486`、`battle_providers.dart:220`。产出：装备 battleCount++、心法 skillUsageCount、主修升层、熟练度、`DropService.rollDrops` 掉落、散功/伤势；经验经 `combat_progression_settlement_service.dart:32`→`CharacterAdvancementService`。
- **存档**：进度回写 `MainlineProgressService.recordVictory` / `TowerProgressService.recordClear`，Isar writeTxn；`isar_setup.dart:109` `_allSchemas` 20 collection；`SaveData.saveVersion` 现 `0.39.0`（:203）+ `_migrateSaveData`。配置经 `GameRepository.loadAllDefs`（numbers/stages/towers.yaml）+ `lib/data/validation/` 7 个红线/引用 validator 启动期 fail-fast。

## 2. probe 资产三分类

- **可迁移（须先剥依赖）**：`combat_rules.dart`（326 行）纯规则函数（弧光命中/Q 聚怪失衡/R 清场/精英破招/连击）——但 import `package:flame`（Vector2）+ probe 专有 `probe_scenarios.yaml` 数值，迁移须去 flame 化并接根配置层。
- **必须重写**：`gameplay_game.dart`（2085 行，`extends FlameGame`——CLAUDE.md §9 禁第三方游戏引擎，纯 Flutter 重写是硬约束）、`gameplay_art.dart`（水墨长卷/图集绘制，依赖 probe assets/phase0b/ 素材路径）、`strategy/gameplay_strategy.dart`（294 行无头策略，依赖 GameplayGame）。
- **绝不进生产**：`gameplay_replay_controller.dart`（replay 跑分）、`gate/`、`human_gate/`、`metrics/`、`report/`、`run/`、`workload/`——探针性能/Gate 基建，`isolation_contract_test.dart` 已明文一次性。probe↔根应用双向零代码依赖（probe 无 `package:wuxia_idle` import；根 lib/pubspec 无 probe 引用，仅 `test/phase0b/phase0b_art_load_evidence_test.dart` 引素材路径作证）。水墨素材须迁根 `assets/` 并按 pubspec 声明守卫测逐目录声明。

## 3. 旧 3v3 假设残留（不得默认保留）

| 位置 | 影响面 |
|---|---|
| `stage_battle_setup.dart:138/:282`（敌我 `i<3`） | 队伍装配截断 |
| `lineup_service.dart:69` / `expedition_service.dart:50` / `gauntlet_service.dart:134` | 编成/派遣 >3 拒绝 |
| `inner_demon_service.dart:127` | 心魔镜像逐位复制 |
| `battle_visual_roster.dart:89` / `battle_bottom_bar.dart:125/:1652` | UI 站位/技能格 3 槽 |
| `progression_red_lines_validator.dart:61` | 塔敌队 ≤3 schema 红线 |
| `battle_test_menu.dart:1286-87`（调试断言）、GDD §5.1「3v3」文字 | 测试与设计层口径 |

## 4. 最小可回退接线路线

1. **决策先行（停止条件：未拍板不动手）**——§6 四项决策落地。
2. **规则层**：去 flame 化的 combat_rules 入 `lib/features/battle/domain/phase0a/`，数值走 yaml（新段需 schema+红线 validator），消费方=后续表现层；测试=规则单测移植；停止条件=红线 validator 不过。
3. **表现层**：纯 Flutter（Widget+AnimationController+CustomPaint）重写实时表现，素材进 `assets/`+pubspec 声明；仅 debug 入口可玩；测试=渲染契约+双视口 smoke；停止条件=帧预算超标（切片实测 p99 ≤9.1ms 为基线）。
4. **生产接线**：先接主线单一入口（`stage_entry_flow`），胜负/掉落/存档全部复用 `BattleResolutionService.resolve` 既有 4 调用方模式，零 schema 变更；headless 路径（扫荡/远征/断魂庄）暂不切；测试=`battle_resolution_test`/`stage_battle_setup_test` 族全绿；停止条件=任一头寸结算漂移。
5. **回退**：每步独立可 revert；旧 3v3 表现在最终拍板前不删，回退=开关还原。

## 5. 影响矩阵

| 红线域 | 影响 | 处置 |
|---|---|---|
| 数值红线 | probe 固定伤害（24/65/100 血）与根公式体系断裂 | 结算必走 `damage_calculator`/`derived_stats`；新 yaml 段入 schema 拦截（装备攻 ≤2000/血 ≤20000/倍率 ≤8000 等） |
| 三系锁死 | ARPG 单人形态下境界↔装备↔心法门槛与境界差修正映射未定义 | 入场校验（`isEquippableAtRealm` 等）必须保留；映射方案列决策项 |
| 在线=离线 | 实时操作天然在线 | 按 GDD §2.2：实时操作仅首通 gate；已通内容刷取走无头（离线经 `seclusion/offline_*_service`，与战斗解耦现状保持） |
| 存档/schema | 步骤 2-4 零 schema 变更 | 若需记录新战斗形态数据，须 saveVersion 迁移——决策项 |
| 结算一致性 | v1.32 规则：胜负自 `finalState.result` 派生 | 新形态不得绕开 resolve；扫荡/远征/headless 结算口径不动 |

## 6. 待拍板决策项（只列选项/证据/推荐，不代拍）

1. **引擎**：A 纯 Flutter 重写（证据：CLAUDE.md §2 技术栈+§9 禁令；**推荐**）｜B 解禁 Flame（触技术栈锁死，须用户显式拍板）。
2. **战斗形态与 GDD §5.1 冲突**：GDD 仍写「3v3 自动战斗」，用户已拍板水墨 ARPG 方向。A 新形态并存（`BattleStrategy` 插槽已有先例）｜B 替换 3v3（须修 GDD §5.1，本单禁改）。**推荐**接线期 A、方向终态 B，均待拍板。
3. **数值接线**：A 表现层 probe 手感参数 + 结算层根公式分层（**推荐**，守红线）｜B probe 数值直迁（违反红线体系，不推荐；且触 `data/numbers.yaml` 禁区）。
4. **无头自动刷**：ARPG 首通后自动刷如何表达（策略回放重算｜简化结算｜保留旧形态 headless），影响在线=离线与 §3 残留清理范围。

## 7. 核心复现命令

```bash
grep -rn 'BattleScreen(' lib --include='*.dart' | grep -v 'MassBattleScreen('
grep -rn 'runStageFlow(' lib --include='*.dart'
grep -rn 'BattleResolutionService.resolve(' lib --include='*.dart'
grep -rn 'i < 3\|take(3)\|length > 3' lib --include='*.dart'
grep -rn 'package:wuxia_idle' tools/phase0minus_probe/lib tools/phase0minus_probe/test
grep -rn 'phase0minus_probe' lib pubspec.yaml test --include='*.dart'
```
