# 时钟与随机源残留登记（2026-09-17）

## 状态与阻塞

**A-3：BLOCKED；未修改任何 A-3 生产代码。A-4：按遇阻即停规则未启动。**

固定全部现有可注入输入，真实 `applyVictoryResolution` 两次结算生产 `stage_01_01`，返回装备 `armor_xunchang_bu_yi` 的身份、基础数值及 `obtainedAt` 相同，延续典故 `lores.addedAt` 分别为 `2026-09-17T00:41:36.631815` 与 `2026-09-17T00:41:36.801423`。完整返回相等要求因该字段而失败。

- 有效阻塞探针：`../logs/A-3_determinism_blocker_probe_test.dart`；原始输出 `../logs/A-3_determinism_blocker_probe.log`，退出码 `1`，末行 `00:00 +0 -1: Some tests failed.`。探针仅为范围冲突证据，不冒充 A-3 完整确定性守卫。
- 第一次探针尝试为非 const 构造误用 const 的编译错误，另存 `_compile_error.log/.exit`，不计入行为证据。
- 所有数据库均为新建临时 Isar；未访问真实存档。
- 主线 `mainline_settlement.dart:707–717` 将返回掉落中的原装备传给事件服务，`:937` 返回同一掉落；塔 `tower_settlement.dart:518–529` 同样调用事件服务并原样返回掉落。
- 最小阻塞：`lib/features/event/application/game_event_service.dart:143–155` 直接用真实时间追加原装备的 `lores[].addedAt`；服务构造没有时钟入口。`:138` 的事件时间同样使用真实时钟。
- 最小额外授权：允许事件服务增加可选的既有 `SystemClock` 注入口，并让获得装备事件的两处时间使用它；由两个结算入口传入同一时钟和既有随机源，默认行为保持。全库逐字段确定性还涉及下表中的首次建档时间等，不能据局部验证宣称全部解决。
- 用户要求其余文件只登记不动；未获得扩大范围的回复，因此未实施域外改动，也未通过删除、归一化履历字段或挑无装备分支绕过。

## 统计口径

以 A-2 READY `1565f31fa0419588f0b0b023d0a7d3c9c0665275` 的源码为快照；后续只新增收工文档，源码位置不变。

- 扫描 697 个非生成 Dart 源文件，排除注释与函数声明，共 154 个调用或函数引用：134 次 `DateTime.now()`、4 处 `DateTime.now` 函数引用、11 次 `newMathRandom` 调用、5 处 `Random` 构造。
- 四个结算函数范围内共 4 个裸时钟点；范围外共 150 点。A-3 未实施，4 个范围内点仍保留。
- `passive_idle_integrator.dart`、`offline_passive_service.dart`、`seclusion_service.dart`、`retreat_settlement_calculator.dart` 自身无上述裸调用；这不代表下游持久字段已确定。
- 原始 `grep DateTime.now()` 会包含注释，并漏掉函数引用；不要把不同统计口径直接对撞。
- 影响分类是静态判断；中置信度项尚未完成完整调用图证明，表中明确保留待核边界。
- 被动积分在线入口 `online_presence_controller.dart` 仍有真实时钟默认回调，闭关收功 UI 入口仍传真实时间，均未接线。闭关 `DefaultRng(seed: stableRetreatSeed(...))` 基于持久会话和节点生成稳定 seed；不可改成共享可变 RNG 而改变分段结算、防重刷或重启复现规则。
- 可复跑清单生成器与原始 JSON：`../logs/A-3_clock_rng_inventory.py`、`../logs/A-3_clock_rng_inventory.json`。

## 逐点清单

范围内、范围外均逐点保留；没有把默认时钟实现或已经显式播种的随机工厂误称为必须删除的错误。

| 位置 | 表达式 | 范围 | 离线结算或回放影响 | 建议 | 分类置信度 |
|---|---|---|---|---|---|
| `lib/core/application/system_clock_provider.dart:17` | `DateTime.now()` | 范围外 | 间接: 既有系统时钟默认实现 | 允许在抽象默认实现保留真实系统时钟；消费者通过 provider 或已有 SystemClock 实例注入。 | 高 |
| `lib/data/isar_setup.dart:113` | `DateTime.now()` | 范围外 | 间接: 存档创建、迁移或保存时间；可能影响离线锚点 | 与存档初始化/保存契约分开验证；已有 now 则调用方注入，避免借结构整改改真实存档。 | 中 |
| `lib/data/isar_setup.dart:315` | `DateTime.now()` | 范围外 | 间接: 存档创建、迁移或保存时间；可能影响离线锚点 | 与存档初始化/保存契约分开验证；已有 now 则调用方注入，避免借结构整改改真实存档。 | 中 |
| `lib/data/isar_setup.dart:1184` | `DateTime.now()` | 范围外 | 间接: 存档创建、迁移或保存时间；可能影响离线锚点 | 与存档初始化/保存契约分开验证；已有 now 则调用方注入，避免借结构整改改真实存档。 | 中 |
| `lib/features/activity/application/durable_activity_automation_coordinator.dart:81` | `newMathRandom(seed: admission.run.seed)` | 范围外 | 直接: 按持久化或测试 seed 重建战斗随机序列 | 此点已经显式播种；保留每次战斗重建语义，不替换为会共享可变序列的全局单例。 | 高 |
| `lib/features/activity/application/durable_activity_automation_coordinator.dart:177` | `newMathRandom(seed: admission.run.seed)` | 范围外 | 直接: 按持久化或测试 seed 重建战斗随机序列 | 此点已经显式播种；保留每次战斗重建语义，不替换为会共享可变序列的全局单例。 | 高 |
| `lib/features/activity/application/durable_activity_automation_coordinator.dart:207` | `DateTime.now()` | 范围外 | 直接: 无界面差遣回放入口的耗时/结算时刻 | 回放计时与传入四结算的时间也须注入，否则上游覆盖会绕过下游固定时钟。 | 高 |
| `lib/features/activity/application/durable_activity_automation_coordinator.dart:219` | `DateTime.now()` | 范围外 | 直接: 无界面差遣回放入口的耗时/结算时刻 | 回放计时与传入四结算的时间也须注入，否则上游覆盖会绕过下游固定时钟。 | 高 |
| `lib/features/activity/application/durable_activity_automation_service.dart:124` | `DateTime.now()` | 范围外 | 直接: 其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/activity/application/durable_activity_automation_service.dart:221` | `DateTime.now()` | 范围外 | 直接: 其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/activity/application/durable_activity_automation_service.dart:364` | `DateTime.now()` | 范围外 | 直接: 其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/activity/application/durable_activity_automation_service.dart:457` | `DateTime.now()` | 范围外 | 直接: 其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/activity/application/durable_activity_automation_service.dart:489` | `DateTime.now()` | 范围外 | 直接: 其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/activity/application/durable_activity_automation_service.dart:514` | `DateTime.now()` | 范围外 | 直接: 其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/ascension/application/ascend_service.dart:239` | `DateTime.now()` | 范围外 | 间接或待核: 其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/ascension/presentation/ascension_screen.dart:216` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/baike/presentation/baike_screen.dart:126` | `DateTime.now()` | 范围外 | 无直接写入影响: 展示倒计时、入口提示或显示条件 | 保留表现层范围；仅在需要固定展示快照时注入，不据此扩大结算整改。 | 中 |
| `lib/features/battle_record/application/boss_memory_hook.dart:87` | `DateTime.now()` | 范围外 | 间接: 战后图鉴/战绩记录包装层时间 | 持久记录可能与回放结果一起读取；明确输出边界后按已有服务 now 参数透传。 | 中 |
| `lib/features/boss_gauntlet/application/gauntlet_service.dart:383` | `DateTime.now()` | 范围外 | 直接: 其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/boss_gauntlet/application/gauntlet_service.dart:428` | `DateTime.now()` | 范围外 | 直接: 其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/boss_gauntlet/application/gauntlet_service.dart:573` | `DateTime.now()` | 范围外 | 直接: 其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/boss_gauntlet/application/gauntlet_service.dart:693` | `DateTime.now()` | 范围外 | 直接: 其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/boss_gauntlet/application/gauntlet_service.dart:987` | `DateTime.now()` | 范围外 | 直接: 其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/boss_gauntlet/application/gauntlet_service.dart:1157` | `DateTime.now()` | 范围外 | 直接: 其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/boss_gauntlet/application/gauntlet_service.dart:1290` | `DateTime.now()` | 范围外 | 直接: 其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/boss_gauntlet/application/gauntlet_service.dart:1351` | `DateTime.now()` | 范围外 | 直接: 其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/boss_gauntlet/application/phase0a_gauntlet_stage_runner.dart:99` | `newMathRandom(seed: seed)` | 范围外 | 直接: 按持久化或测试 seed 重建战斗随机序列 | 此点已经显式播种；保留每次战斗重建语义，不替换为会共享可变序列的全局单例。 | 高 |
| `lib/features/boss_gauntlet/presentation/phase0a_gauntlet_battle_host.dart:74` | `newMathRandom(seed: plan.seed)` | 范围外 | 直接: 按持久化或测试 seed 重建战斗随机序列 | 此点已经显式播种；保留每次战斗重建语义，不替换为会共享可变序列的全局单例。 | 高 |
| `lib/features/combat_shared/domain/damage_calculator.dart:86` | `newMathRandom()` | 范围外 | 间接: 战斗回放领域计算的缺省随机源 | ctx.rng 为空才创建无种子源；保持现有规则，回放调用方必须传入既有固定种子的随机对象。 | 高 |
| `lib/features/cultivation/application/technique_learn_flow_service.dart:106` | `DateTime.now()` | 范围外 | 间接或待核: 其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/debug/application/phase0a_debug_battle_fixture.dart:157` | `Random(config.seed)` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:268` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:410` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:427` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:445` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:544` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:606` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:675` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:803` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:907` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:946` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:974` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:1043` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:1067` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:1093` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:1118` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:1442` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:1456` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:1580` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/redline_audit.dart:350` | `Random(7)` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/presentation/visual_route_host.dart:395` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/presentation/visual_route_host.dart:432` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/presentation/visual_route_host.dart:573` | `Random(20260824)` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/presentation/visual_route_host.dart:855` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/presentation/visual_route_host.dart:894` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/presentation/visual_route_host.dart:1049` | `DateTime.now()` | 范围外 | 无生产直接影响: 调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/encounter/application/encounter_service.dart:136` | `DateTime.now()` | 范围外 | 间接: 结算下游：新建奇遇进度 createdAt | getOrCreate 增加既有时钟/结算时刻注入并由主线、闭关入口透传；已有进度行不经过此分支。 | 高 |
| `lib/features/equipment/application/drop_service.dart:69` | `DateTime.now` | 范围外 | 间接: 结算下游：装备 obtainedAt | 已有 now 回调；结算创建 DropService 时传入固定结算时刻，服务默认值可列域外残留。 | 高 |
| `lib/features/equipment/application/equipment_disposal_service.dart:233` | `DateTime.now()` | 范围外 | 间接或待核: 其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/equipment/application/forging_service.dart:151` | `DateTime.now()` | 范围外 | 间接或待核: 其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/equipment/application/milestone_equipment_grant_service.dart:27` | `DateTime.now` | 范围外 | 间接: 装备授予时间默认回调 | 已有 now 回调；需要逐字段重放时由调用方固定注入，暂不扩大本单域。 | 中 |
| `lib/features/event/application/game_event_service.dart:72` | `newMathRandom()` | 范围外 | 间接: 结算下游：事件与装备典故持久化 | 为服务补既有 SystemClock 注入口并传入结算时刻；复用已有 random 注入，防止典故文本和时间戳漏出固定输入。 | 高 |
| `lib/features/event/application/game_event_service.dart:94` | `DateTime.now()` | 范围外 | 间接: 结算下游：事件与装备典故持久化 | 为服务补既有 SystemClock 注入口并传入结算时刻；复用已有 random 注入，防止典故文本和时间戳漏出固定输入。 | 高 |
| `lib/features/event/application/game_event_service.dart:112` | `DateTime.now()` | 范围外 | 间接: 结算下游：事件与装备典故持久化 | 为服务补既有 SystemClock 注入口并传入结算时刻；复用已有 random 注入，防止典故文本和时间戳漏出固定输入。 | 高 |
| `lib/features/event/application/game_event_service.dart:138` | `DateTime.now()` | 范围外 | 间接: 结算下游：事件与装备典故持久化 | 为服务补既有 SystemClock 注入口并传入结算时刻；复用已有 random 注入，防止典故文本和时间戳漏出固定输入。 | 高 |
| `lib/features/event/application/game_event_service.dart:143` | `DateTime.now()` | 范围外 | 间接: 结算下游：事件与装备典故持久化 | 为服务补既有 SystemClock 注入口并传入结算时刻；复用已有 random 注入，防止典故文本和时间戳漏出固定输入。 | 高 |
| `lib/features/event/application/game_event_service.dart:175` | `DateTime.now()` | 范围外 | 间接: 结算下游：事件与装备典故持久化 | 为服务补既有 SystemClock 注入口并传入结算时刻；复用已有 random 注入，防止典故文本和时间戳漏出固定输入。 | 高 |
| `lib/features/event/application/game_event_service.dart:193` | `DateTime.now()` | 范围外 | 间接: 结算下游：事件与装备典故持久化 | 为服务补既有 SystemClock 注入口并传入结算时刻；复用已有 random 注入，防止典故文本和时间戳漏出固定输入。 | 高 |
| `lib/features/event/application/game_event_service.dart:226` | `DateTime.now()` | 范围外 | 间接: 结算下游：事件与装备典故持久化 | 为服务补既有 SystemClock 注入口并传入结算时刻；复用已有 random 注入，防止典故文本和时间戳漏出固定输入。 | 高 |
| `lib/features/event/application/game_event_service.dart:245` | `DateTime.now()` | 范围外 | 间接: 结算下游：事件与装备典故持久化 | 为服务补既有 SystemClock 注入口并传入结算时刻；复用已有 random 注入，防止典故文本和时间戳漏出固定输入。 | 高 |
| `lib/features/event/application/game_event_service.dart:272` | `DateTime.now()` | 范围外 | 间接: 结算下游：事件与装备典故持久化 | 为服务补既有 SystemClock 注入口并传入结算时刻；复用已有 random 注入，防止典故文本和时间戳漏出固定输入。 | 高 |
| `lib/features/event/application/game_event_service.dart:277` | `DateTime.now()` | 范围外 | 间接: 结算下游：事件与装备典故持久化 | 为服务补既有 SystemClock 注入口并传入结算时刻；复用已有 random 注入，防止典故文本和时间戳漏出固定输入。 | 高 |
| `lib/features/expedition/application/expedition_service.dart:159` | `DateTime.now()` | 范围外 | 直接: 其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/expedition/application/expedition_service.dart:542` | `DateTime.now()` | 范围外 | 直接: 其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/expedition/application/expedition_service.dart:736` | `DateTime.now()` | 范围外 | 直接: 其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/expedition/application/expedition_service.dart:764` | `DateTime.now()` | 范围外 | 直接: 其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/expedition/application/expedition_service.dart:1171` | `DateTime.now()` | 范围外 | 直接: 其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/expedition/application/phase0a_expedition_combat_runner.dart:213` | `newMathRandom(seed: nodeSeed)` | 范围外 | 直接: 按持久化或测试 seed 重建战斗随机序列 | 此点已经显式播种；保留每次战斗重建语义，不替换为会共享可变序列的全局单例。 | 高 |
| `lib/features/expedition/presentation/phase0a_expedition_milestone_battle_host.dart:85` | `newMathRandom(seed: plan.nodeSeed)` | 范围外 | 直接: 按持久化或测试 seed 重建战斗随机序列 | 此点已经显式播种；保留每次战斗重建语义，不替换为会共享可变序列的全局单例。 | 高 |
| `lib/features/festival/application/festival_service.dart:24` | `DateTime.now()` | 范围外 | 间接: 节日条件可影响奇遇资格 | 已有 when 参数；确定性结算需基于同一结算日期派生 festivalToday，不能读取墙钟日期。 | 高 |
| `lib/features/inventory/application/item_use_service.dart:36` | `DateTime.now()` | 范围外 | 间接或待核: 其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/inventory/application/item_use_service.dart:198` | `DateTime.now()` | 范围外 | 间接或待核: 其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/jianghu/application/npc_relation_service.dart:42` | `DateTime.now()` | 范围外 | 间接: 声望/关系记录写入时间 | 事务接口如已有 now 则保持透传；包装层时钟作为域外余项。 | 中 |
| `lib/features/jianghu/application/npc_relation_service.dart:47` | `DateTime.now()` | 范围外 | 间接: 声望/关系记录写入时间 | 事务接口如已有 now 则保持透传；包装层时钟作为域外余项。 | 中 |
| `lib/features/jianghu/application/reputation_service.dart:28` | `DateTime.now()` | 范围外 | 间接: 声望/关系记录写入时间 | 事务接口如已有 now 则保持透传；包装层时钟作为域外余项。 | 中 |
| `lib/features/lineage/application/disciple_join_service.dart:83` | `DateTime.now()` | 范围外 | 间接或待核: 其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/main_menu/application/main_menu_status_summary_provider.dart:101` | `DateTime.now()` | 范围外 | 无直接写入影响: 展示倒计时、入口提示或显示条件 | 保留表现层范围；仅在需要固定展示快照时注入，不据此扩大结算整改。 | 中 |
| `lib/features/main_menu/presentation/main_menu_retreat_banner.dart:30` | `DateTime.now()` | 范围外 | 无直接写入影响: 展示倒计时、入口提示或显示条件 | 保留表现层范围；仅在需要固定展示快照时注入，不据此扩大结算整改。 | 中 |
| `lib/features/mainline/application/mainline_settlement.dart:454` | `DateTime.now()` | 四结算：主线胜利、参与者战败及搬迁私有辅助逻辑 | 直接: 范围内写入时间或随机源 | 在既有依赖入口注入 SystemClock/Rng，并保持同一结算时刻与原调用顺序。 | 高 |
| `lib/features/mainline/application/mainline_settlement.dart:983` | `DateTime.now()` | 四结算：主线胜利、参与者战败及搬迁私有辅助逻辑 | 直接: 范围内写入时间或随机源 | 在既有依赖入口注入 SystemClock/Rng，并保持同一结算时刻与原调用顺序。 | 高 |
| `lib/features/mainline/presentation/phase0a_mainline_battle_host.dart:119` | `newMathRandom(seed: widget.seedForTest)` | 范围外 | 直接: 按持久化或测试 seed 重建战斗随机序列 | 此点已经显式播种；保留每次战斗重建语义，不替换为会共享可变序列的全局单例。 | 高 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:236` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:295` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:539` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:596` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:626` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:655` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:705` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:872` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:879` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1052` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1153` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1241` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1310` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1321` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1356` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1361` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1372` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1378` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1400` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1476` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1481` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1487` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_list_screen.dart:1881` | `DateTime.now()` | 范围外 | 无直接写入影响: 展示倒计时、入口提示或显示条件 | 保留表现层范围；仅在需要固定展示快照时注入，不据此扩大结算整改。 | 中 |
| `lib/features/onboarding/application/master_builder.dart:163` | `DateTime.now()` | 范围外 | 间接或待核: 其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/onboarding/application/onboarding_service.dart:94` | `DateTime.now()` | 范围外 | 间接或待核: 其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/progressive_unlock/presentation/progressive_unlock_seal.dart:29` | `DateTime.now()` | 范围外 | 无直接写入影响: 展示倒计时、入口提示或显示条件 | 保留表现层范围；仅在需要固定展示快照时注入，不据此扩大结算整改。 | 中 |
| `lib/features/recruitment/application/recruitment_service.dart:87` | `DateTime.now()` | 范围外 | 间接或待核: 其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/save_management/application/save_management_service.dart:18` | `DateTime.now` | 范围外 | 间接: 存档管理默认时钟 | 已有 now 回调，可从既有 SystemClock 透传；不是本单四结算范围。 | 高 |
| `lib/features/seclusion/application/online_presence_controller.dart:32` | `DateTime.now` | 范围外 | 间接: 被动积分上游生命周期与心跳时钟 | 已有 clock 回调可注入；生产 provider 可接 systemClockProvider.now，保留串行结算行为。 | 高 |
| `lib/features/seclusion/presentation/active_retreat_screen.dart:59` | `DateTime.now()` | 范围外 | 无直接写入影响: 闭关展示计时器 | 用于界面刷新，写入按钮的 now 另项处理。 | 高 |
| `lib/features/seclusion/presentation/active_retreat_screen.dart:61` | `DateTime.now()` | 范围外 | 无直接写入影响: 闭关展示计时器 | 用于界面刷新，写入按钮的 now 另项处理。 | 高 |
| `lib/features/seclusion/presentation/active_retreat_screen.dart:107` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/seclusion/presentation/offline_recap_gate.dart:48` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/seclusion/presentation/seclusion_gate.dart:94` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/seclusion/presentation/seclusion_map_list_screen.dart:296` | `DateTime.now()` | 范围外 | 无直接写入影响: 展示倒计时、入口提示或显示条件 | 保留表现层范围；仅在需要固定展示快照时注入，不据此扩大结算整改。 | 中 |
| `lib/features/seclusion/presentation/seclusion_map_list_screen.dart:611` | `DateTime.now()` | 范围外 | 无直接写入影响: 展示倒计时、入口提示或显示条件 | 保留表现层范围；仅在需要固定展示快照时注入，不据此扩大结算整改。 | 中 |
| `lib/features/seclusion/presentation/seclusion_setup_screen.dart:70` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/sect/presentation/sect_recruit_handler.dart:69` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/sect/presentation/sect_recruit_handler.dart:97` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/shop/application/shop_service.dart:67` | `DateTime.now()` | 范围外 | 间接或待核: 其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/sweep/application/sweep_readiness_service.dart:13` | `DateTime.now()` | 范围外 | 间接或待核: 其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/sweep/application/sweep_readiness_service.dart:29` | `DateTime.now()` | 范围外 | 间接或待核: 其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/sweep/application/sweep_settlement.dart:140` | `DateTime.now()` | 范围外 | 直接: 扫荡结算调用方时间 | 调用四结算时沿用同一注入时钟；下游接受固定时钟不代表上游已固定。 | 高 |
| `lib/features/sweep/application/sweep_settlement.dart:228` | `DateTime.now()` | 范围外 | 直接: 扫荡结算调用方时间 | 调用四结算时沿用同一注入时钟；下游接受固定时钟不代表上游已固定。 | 高 |
| `lib/features/sweep/presentation/sweep_readiness_status.dart:231` | `DateTime.now()` | 范围外 | 无直接写入影响: 展示倒计时、入口提示或显示条件 | 保留表现层范围；仅在需要固定展示快照时注入，不据此扩大结算整改。 | 中 |
| `lib/features/taohua_island/application/island_action_service.dart:106` | `DateTime.now()` | 范围外 | 直接: 桃花岛积分/动作会先结算离线收益 | 使用同一注入时刻驱动动作前积分；现有 now 参数入口保持可覆写。 | 中 |
| `lib/features/taohua_island/application/island_action_service.dart:199` | `DateTime.now()` | 范围外 | 直接: 桃花岛积分/动作会先结算离线收益 | 使用同一注入时刻驱动动作前积分；现有 now 参数入口保持可覆写。 | 中 |
| `lib/features/taohua_island/application/island_providers.dart:74` | `DateTime.now()` | 范围外 | 直接: 桃花岛积分/动作会先结算离线收益 | 使用同一注入时刻驱动动作前积分；现有 now 参数入口保持可覆写。 | 中 |
| `lib/features/taohua_island/presentation/taohua_island_screen.dart:134` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/taohua_island/presentation/taohua_island_screen.dart:188` | `DateTime.now()` | 范围外 | 无直接写入影响: 桃花岛展示计时器 | 仅界面刷新；采收/升阶动作时间另项处理。 | 高 |
| `lib/features/taohua_island/presentation/taohua_island_screen.dart:314` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/tower/application/tower_progress_service.dart:69` | `DateTime.now()` | 范围外 | 间接: 结算下游：新建塔进度或补发门票 | getOrCreate 新进度行 createdAt 未接结算时刻；补可选 now/既有 SystemClock 并透传。 | 高 |
| `lib/features/tower/application/tower_progress_service.dart:228` | `DateTime.now()` | 范围外 | 间接: 结算下游：新建塔进度或补发门票 | 补票入口已有 now 参数；getOrCreate 的回填调用还需透传相同结算时刻。 | 高 |
| `lib/features/tower/application/tower_settlement.dart:111` | `DateTime.now()` | 四结算：塔胜利、塔战斗结算及掉落写入辅助逻辑 | 直接: 范围内写入时间或随机源 | 在既有依赖入口注入 SystemClock/Rng，并保持同一结算时刻与原调用顺序。 | 高 |
| `lib/features/tower/application/tower_settlement.dart:323` | `DateTime.now()` | 四结算：塔胜利、塔战斗结算及掉落写入辅助逻辑 | 直接: 范围内写入时间或随机源 | 在既有依赖入口注入 SystemClock/Rng，并保持同一结算时刻与原调用顺序。 | 高 |
| `lib/features/tower/presentation/phase0a_tower_battle_host.dart:79` | `newMathRandom(seed: widget.seedForTest)` | 范围外 | 直接: 按持久化或测试 seed 重建战斗随机序列 | 此点已经显式播种；保留每次战斗重建语义，不替换为会共享可变序列的全局单例。 | 高 |
| `lib/features/tower/presentation/tower_entry_flow.dart:210` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/tower/presentation/tower_entry_flow.dart:329` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/tower/presentation/tower_entry_flow.dart:562` | `DateTime.now()` | 范围外 | 间接: 前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/weapon_codex/application/equipment_catalog_hook.dart:19` | `DateTime.now()` | 范围外 | 间接: 战后图鉴/战绩记录包装层时间 | 持久记录可能与回放结果一起读取；明确输出边界后按已有服务 now 参数透传。 | 中 |
| `lib/shared/utils/math_random.dart:21` | `newMathRandom()` | 范围外 | 间接: 既有 dart:math 随机源边界 | 默认入口本身不是绕注入；须检查上游是否显式提供固定 seed 或 provider override。 | 高 |
| `lib/shared/utils/math_random.dart:25` | `Random(seed)` | 范围外 | 间接: 既有 dart:math 随机源边界 | 默认入口本身不是绕注入；须检查上游是否显式提供固定 seed 或 provider override。 | 高 |
| `lib/shared/utils/rng.dart:25` | `Random(seed)` | 范围外 | 间接: 既有随机源基础实现 | 保留 DefaultRng(seed) 构造；生产消费者通过 rngProvider/seededRngFactoryProvider 选择种子。 | 高 |
