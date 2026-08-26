# Phase 2 测试绕开生产路径审计（2026-08-26）

- 审计基线：`6ab44026`（分支 `codex/p2-n4-falsegreen-20260826`）。
- 扫描分母：`test/` 共 **854** 个 Git 跟踪文件；其中 **820** 个 Dart 测试/工具源，**34** 个 fixture/证据文件。
- 方法：全文扫描构造/集合变异/手算/同源 oracle/共享状态/偏差冻结/源码文本契约，再逐条打开上下文并回查生产消费方；未做破坏性验证。
- 新形态 **7（源码文本代验）**：仅对生产文件做 `contains` / `isNot(contains)`，不执行所声称的路由或业务链。
- 严重度：**S1** 守生产红线却可能失效；**S2** 普通功能路径可能假绿；**S3** 自反/冗余等风格问题。

## 可疑清单（按严重度）

| 严重度 | file:line | 形态 | 静态判读（破坏相应生产行时） |
|---|---|---:|---|
| S1 | `test/data/phase2/ch1_production_catalog_test.dart:187` | 6 | 把已知不合规的生产令牌 `2/2/1/1`逐项钉成期望，改回合规值反而会红。 |
| S1 | `test/features/battle/application/phase0a/phase0a_production_encounter_token_gate_test.dart:234` | 1 | 手建 budgets、request mapper、roster 和 mapping 后注入 assembler，生产 catalog/runtime-binding 漏接或越界不必红。 |
| S1 | `test/balance/full_build_damage_redline_test.dart:185` | 1 | 用手建 Equipment/SkillDef 直调 calculator 守“实战可见值”，注释亦承认未过 Phase 0A reducer，真实 adapter/reducer 坏掉可继续绿。 |
| S1 | `test/audit/cross_system_damage_test.dart:56` | 3 | 用 `_withApm` 手乘地形/阵型/恩怨 APM 模拟 strategy，生产 bake/adapter 未接或次序错误不会触发断言。 |
| S1 | `test/features/economy/stage_silver_ratio_redline_test.dart:103` | 3 | 银两占比由测试自行对 YAML 求期望并手解 `K30`，未经 DropService/结算入账，生产掉落算错仍可绿。 |
| S1 | `test/tools/phase0a_full_content_balance_diagnostic_test.dart:92` | 1 | 红线诊断用 `snapshot.copyWith(skillUses: ...)` 手填熟练度，持久使用次数→生产快照的接线损坏时仍可绿。 |
| S2 | `test/features/battle/application/phase0a/phase0a_charge_production_wiring_test.dart:320` | 1 | 名为 e2e 的两条用例手将 Boss 预置 `chargingCast`/重建 actor，生产 AI 启动蓄力那行被破坏也不必红。 |
| S2 | `test/features/tower/presentation/apply_tower_victory_resolution_test.dart:90` | 1 | 手填 settlement 的 `playerCharacterId` 与 participants 后验结算归属，生产 settlement adapter 错写参战者不会被本断言捕获。 |
| S2 | `test/features/mainline/presentation/apply_victory_resolution_test.dart:309` | 1 | 手建“0A 末态”并预填祖师身份，只验下游 consumer，上游快照生成错人时仍绿。 |
| S2 | `test/features/sweep/application/sweep_settlement_test.dart:120` | 1 | 扫荡结算断言注入手填 `CombatSettlementSnapshot`，headless runner 若生成错身份/错统计本用例不红。 |
| S2 | `test/features/expedition/expedition_manual_dispatch_contract_test.dart:131` | 1 | 直接构造 `ExpeditionReturnResult` 再断言刚填入的身份字段，生产返程 assembler 遗漏身份仍可绿。 |
| S2 | `test/features/battle/domain/phase0a/phase0a_guardian_coop_test.dart:220` | 1 | “真实塔42 production flow”使用测试 helper 手填不可达 `maxHp: 200000` 快照，绕过生产玩家 assembler/血量红线。 |
| S2 | `test/features/battle/presentation/phase0a/phase0a_stage_transform_test.dart:30` | 4 | 以 `screenToWorld(worldToScreen(point))` 互为 oracle，两个变换共享同一错误缩放/偏移时往返仍可绿。 |
| S2 | `test/features/battle/presentation/phase0a/phase0a_battle_screen_test.dart:1005` | 4 | Widget 实际位置与期望位置都调同一 `Phase0aStage.worldToScreen`，该生产变换本身改坏时三组定位断言会同步漂移。 |
| S2 | `test/features/battle/presentation/phase0a/phase0a_mechanics_presentation_test.dart:79` | 4 | 护法标签的实际偏移和期望集合共用 `guardianLabelLaneOffset`，token 被误改为错值乃至 0 也可绿。 |
| S2 | `test/features/inventory/presentation/bulk_disposal_dialog_test.dart:245` | 4 | 期望银两和期望文案直调 Widget 同款 `equipmentSellPrice`/`sellConfirmBody`，价格公式或格式化错误会双边同步。 |
| S2 | `test/features/mainline/presentation/mainline_all_mode_consistency_test.dart:136` | 7 | 所谓全局自动/前台 bot/headless 生产接线只查三个源文件含若干名字，名字留在死分支时仍绿。 |
| S2 | `test/features/mainline/presentation/mainline_ch1_continuous_run_test.dart:87` | 7 | 首清入口/run 锁定快照仅靠源码字符串拼片，实际路由不调用这些语句也可通过。 |
| S2 | `test/features/battle/application/combat_progression_settlement_wiring_contract_test.dart:6` | 7 | 主线/塔“委派共享结算”只用 `contains` 查类名和参数文本，无任何可观察的真结算调用。 |
| S2 | `test/features/lineup/presentation/disciple_scheduling_production_route_test.dart:6` | 7 | “生产入口”只查 import/类名出现与旧名消失，点击仍可路由到别处而不红。 |
| S2 | `test/features/recruitment/recruitment_dialog_visual_contract_test.dart:6` | 7 | 资质视觉“接线”仅匹配 `profile.total` 源码片段，没有 pump 真对话框或断言实际 badge 输入。 |
| S2 | `test/tools/progression_idle_horizon_simulation_test.dart:547` | 3 | 模拟器重写了商店价格与丹药经验公式，未调 ShopService/ItemUseService，两条真实消费路径漂移不会红。 |
| S3 | `test/features/battle/domain/phase0a/encounter_objective_test.dart:219` | 4 | `expect(first.initialProgress, first.initialProgress)` 是严格自反比较，无论生产等值实现如何坏掉都不会红。 |

## 计数与边界

- 已扫：**854/854 文件（100%）**；Dart 源 **820/820**，fixture/证据 **34/34**。
- 命中：**23 条，涉及 23 个文件**；S1 **6** / S2 **16** / S3 **1**。
- 边界：这是“静态可疑清单”，不将未命中文件判为无问题；无高置信形态 5 命中不等于已证明无残留态风险。
