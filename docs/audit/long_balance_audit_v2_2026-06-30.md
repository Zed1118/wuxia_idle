# 长线平衡只读审计 v2（2026-06-30）

## Scope

本轮是只读审计加文档提交，复核 2026-06-29 之后进入主线的长线闭环改动：单人主线 Ch1-6、弟子终局加入后的通过性风险、塔 Boss / 高周目阶段覆盖、扫荡、桃花岛消费与协同、闭关/离线收益、在线=离线红线、极值伤害不进百万红线。

本轮未修改 `numbers.yaml`、`data/*.yaml` 数值、Dart 结算代码、测试断言，也未触碰 `PROGRESS.md`、`CLAUDE.md`、`GDD.md`。

主要输入：

- `docs/audit/long_balance_audit_2026-06-28.md`
- `docs/spec/playability_phase2_backlog.md`
- `PROGRESS.md` 中 2026-06-29 至 2026-06-30 的合入记录
- 相关测试：`test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart`、`test/data/ngplus_boss_phase_config_test.dart`、`test/balance/full_build_damage_redline_test.dart`、`test/features/taohua_island/*`、`test/features/seclusion/*`、`test/features/sweep/*`
- CodeGraph 状态：索引可用，450 files / 8452 nodes / 9586 edges

## Verified Guardrails

- 单人主线 Ch1-6 有生产数据回归测试兜底：`solo_mainline_ch1_ch6_balance_test.dart` 连续跑 `stage_01_01` 到 `stage_06_05`，保持祖师单人路径，并要求每关不撞 `maxTicks`、不出现右方胜利。该测试已通过。
- 高周目 Boss 阶段覆盖有静态配置红线：`ngplus_boss_phase_config_test.dart` 断言主线 6 个章末 Boss 均有二周目 `cycleBossPhases`，且塔 20/25/30 基础阶段阈值保持第一梯队配置、高周目走覆盖。该测试已通过。
- 扫荡当前有三层兜底：资格测试保证本周目全通后才可扫；状态机/recap 测试保证累计与中止语义；widget 回归测试保证扫荡真跑战斗到胜负、跨场不卡黑屏。相关 `test/features/sweep` 已通过。
- 桃花岛在线=离线有真实配置测试：`island_offline_online_invariant_test.dart` 覆盖 72h 一次性 settle 等于 72 次 1h 分块，含默认、高阶、疗伤丹双输入配方；`island_production_service_test.dart` 覆盖协同倍率、加工守恒、cap、境界门槛、纯函数不变性。相关测试已通过。
- 闭关/离线疗伤有时间等价测试：`injury_recovery_test.dart` 验证闭关收功与离线 settle 均按真实小时扣减重伤、清轻伤；`offline_passive_settle_test.dart` 验证离线被动发放磨剑石/经验且不改银两。相关测试已通过。
- 极值伤害不进百万红线仍存在并通过：`full_build_damage_redline_test.dart` 覆盖满 build 普攻、AOE 单次不抬高、Boss 弱点叠乘、满破甲、破绽窗口极值；本轮实测最高打印点为 136,261，均远低于 1,000,000。真实战斗峰值仍由 `test/tools/balance_simulator_test.dart` 中极值×周目诊断负责。

本轮实际验证：

- `dart run build_runner build --delete-conflicting-outputs`：通过，生成本地验证产物；参数提示已废弃但构建成功。
- `flutter analyze`：0 issue。
- `flutter test --no-pub -j1 test/features/onboarding/solo_mainline_ch1_ch6_balance_test.dart test/data/ngplus_boss_phase_config_test.dart test/balance/full_build_damage_redline_test.dart test/features/taohua_island/island_offline_online_invariant_test.dart test/features/taohua_island/island_production_service_test.dart test/features/seclusion/injury_recovery_test.dart test/features/seclusion/application/offline_passive_settle_test.dart test/features/sweep`：72/72 passed。
- `git diff --check`：通过。

验证插曲：初次直接跑用户建议的大集合时，因本 worktree 缺少生成产物，`flutter test` 在 native assets 测试编译阶段报 `Bad state: No element` 并写出 `flutter_01.log` 至 `flutter_05.log`。补跑 `build_runner` 后 targeted tests 正常进入并通过；这些日志未纳入提交。

## Risk Register（P1/P2/P3）

### P1

无确认的 P1 阻断项。本轮没有发现必须今晚改数值或改结算才能避免红线破坏的问题。

### P2

1. 桃花岛 7 建筑 + 协同 + 闭关小产出的总量经济仍缺集成模拟。上一轮审计已指出真实 7 建筑总银两 sink 约 88,800、心血结晶可能存在过量/断流两面风险；6/29 后新增固定协同和闭关地图专属小产出，测试证明公式/在线=离线成立，但没有证明长线供需曲线合适。
2. 塔 Boss / 高周目目前主要由配置红线和部分阶段阈值回归兜住，缺少“塔 20/25/30、cycle2+、真实玩家 build、阶段触发率、胜率、耗时”的成套模拟。尤其 floor30 曾经出现过秒杀导致二阶段不触发，虽然已通过血量/阈值修复并有静态测试，但仍需要真战斗诊断确认不同 build 下的体验。
3. 单人主线 Ch1-6 已有“不会硬卡死”的强回归，但测试会主动提升祖师到关卡要求境界并做确定性整备，证明的是可通性下限，不证明真实玩家在 Ch4-6 的练级时长、掉落波动、伤势压力和终局弟子加入后的节奏手感。
4. 扫荡真战斗链路已兜住不卡和不提前开放，但扫荡收益预估是只读展示派生，尚未和“实际扫荡 N 次后的材料/银两/熟练度净流入”做经济一致性统计。

### P3

1. 离线被动仍不产银两，测试明确 `offline_passive_settle_test.dart` 不改 `item_silver`。这延续上一轮审计的开放口径：可能是设计意图，但需要产品确认“无 active 闭关时无银两 fallback”是否长期保留。
2. 桃花岛/闭关/扫荡相关新增 UI 已有大量表现层测试，但长线审计无法替代真机手感：回归卡密度、扫荡 recap 可读性、塔阶段表现、桃花岛协同说明是否让玩家理解“产物去哪了”，仍需要真机目检。
3. `test/tools/balance_simulator_test.dart` 中部分诊断输出仍是历史日期文件名（例如 2026-06-14 / 2026-06-27）。它们可继续作为回归工具，但后续若做 v3 审计，建议输出新日期快照，避免误读旧结果为新跑结果。

## Recommended Next Simulations / Manual Play Checks

1. 资源经济集成模拟：按 7 阶、主线重打、塔、扫荡、闭关地图小产出、桃花岛协同、装备出售/分解，模拟磨剑石、心血结晶、银两、疗伤丹、开锋辅材的 7/14/30 天净流入与主要 sink。
2. 强化/开锋材料期望模拟：以一件装备 +15/+30/+49 和三件终局装备为单位，量化磨剑石、心血结晶、开锋辅材是否过剩或卡死。
3. 单人主线真机校值：新档祖师单人从 Ch1 到 `stage_06_05`，记录每章建议挂机/闭关时长、失败点、伤势压力、经验丹使用节奏、弟子加入后的体感转折。
4. 塔 Boss / 高周目战斗模拟：塔 10/20/25/30 × cycle1/2/3 × floor/ceiling/extreme build，输出胜率、平均 ticks、阶段触发率、玩家掉血、峰值伤害；重点确认 floor30 二阶段不会再被常规 build 秒跳。
5. 扫荡经济一致性检查：同一章手动重打 N 次 vs 扫荡 N 次，比较掉落类别、熟练度、材料分类、银两、失败中止账本，确认扫荡没有隐性加速或收益折损。
6. 在线=离线真机检查：闭关中退出 8h / 桃花岛离开 8h / 反复进出分块 settle，手动记录回归卡与实际库存变化，确认测试覆盖的等价性在 UI 层也能被玩家理解。

## Explicit Non-Actions（今晚不改数值/不改结算）

- 不改 `data/numbers.yaml`、`data/stages.yaml`、`data/towers.yaml`、`data/items.yaml`、桃花岛或闭关产出配置。
- 不改 `DamageCalculator`、`BattleEngine`、`StageBattleSetup`、`IslandProductionService`、`SeclusionService`、`OfflinePassiveService`、扫荡 controller/settle 代码。
- 不改任何测试断言来适配审计结论。
- 不因为 P2/P3 风险盲调 Boss 血量、掉落概率、协同倍率、cap、离线产出、银两/材料 sink。
- 不把“测试已通过”解读为“长线经济已校准完成”；测试兜住的是红线和回归，经济手感仍需要下一轮模拟与真机校值。
