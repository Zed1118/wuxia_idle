# 时钟与随机源残留登记（2026-09-17）

## 当前状态与范围

A-3 已按后续授权完成接线并通过本单验收：完整套件 `07:33 +6932: All tests passed!`，分析零问题、格式零改动；主线时钟破坏证红 2 失败，已完整还原。四个应用层结算函数、被动积分在线入口和闭关收功入口已使用既有 `SystemClock` 注入口；直接调用链中的事件、装备典故及首次进度记录接收同一结算时刻。这里登记剩余点，不替代最终全量验证收据，也不宣称全库离线活动或回放已具有确定性。

事件文案的 `eventRandom` 与里程碑属性的 `milestoneRng` 为独立可选注入，未提供时保留原服务各自的随机源，不消耗技能残页或其他奖励的随机序列。`MilestoneEquipmentGrantService` 原有 `now`/`rng` 默认仍保留，主线胜利路径通过 `grantMilestoneForClearedStageInTxn` 透传，其他调用方不变。闭关继续采用持久会话与节点生成的稳定 seed，不改变分段结算、防重刷和重启复现规则。

## 历史阻塞证据与处理

此前 `[BLOCKED]` 是授权范围不足时的历史状态：固定全部当时可注入输入，真实 `applyVictoryResolution` 两次结算生产 `stage_01_01`，装备 `armor_xunchang_bu_yi` 的 `lores.addedAt` 分别为 `2026-09-17T00:41:36.631815` 和 `2026-09-17T00:41:36.801423`，完整返回相等断言失败。后续用户已允许直接调用链的域外注入，现已向相关 `GameEventService` 传递固定结算时刻，并补齐首次塔/奇遇进度及装备写入的时间透传。

- 原探针与日志继续保留：`../logs/A-3_determinism_blocker_probe_test.dart`、`../logs/A-3_determinism_blocker_probe.log`；退出码 `1`，末行 `00:00 +0 -1: Some tests failed.`。该探针仅作历史行为证据。
- 第一次探针的非 const 构造误用 const 编译错误另存 `_compile_error.log/.exit`，不计入行为证据。
- 原始开工清单 `../logs/A-3_clock_rng_inventory.py/.json` 不覆盖：697 个非生成源码文件、154 点，其中范围内 4 点、范围外 150 点。原清单中的源代码行号只对应当时快照。
- 所有取证数据库均为新建临时 Isar；未访问真实存档。A-4 是否执行由最终计划与收据单独报告。

## 现状统计口径

本次扫描对应源码基点 `10466e12422170e6831ad001ba66db077dd43ddc`；具体源码内容以完成版 JSON 中逐文件 SHA256 为准。

扫描 697 个非生成 Dart 源文件，共 138 个调用或函数引用：119 次 `DateTime.now()`、3 处 `DateTime.now` 函数引用、11 次 `newMathRandom` 调用、5 处实际 `Random` 构造。六个核心范围文件中目标裸调用为 0，剩余 138 点逐条列在下表。

- 剔除行注释和嵌套块注释，保留原行号；排除 `newMathRandom` 函数声明。每次调用单列，同一行可有多条。
- 为保留 Dart 插值中的真实调用，源码字符串未删；本次命中均按源码调用或函数引用核对。
- `DefaultRng` 不计入实际 `Random` 构造的字面扫描；闭关稳定种子和里程碑默认另有明确说明。
- 原始 `grep` 按文本逐行计数，会包含注释、漏掉时钟函数引用，并把 `_readMathRandom()` 当成 `Random(` 命中；不能与语义条目数直接对撞。
- 分类来自静态源码及已核对调用链；中置信度项未作完整全仓调用图证明，保留后续核验边界。
- 复跑：在 worktree 根执行 `python3 ../logs/A-3_completed_clock_rng_inventory.py`；同时刷新本文件及 `../logs/A-3_completed_clock_rng_inventory.json`。JSON 记录扫描时刻、基点 SHA、每个被扫描源码文件 SHA256。旧阻塞证据不受影响。

## 范围内接线与原始 grep 例外

| 位置 | 本轮接线 |
|---|---|
| `lib/core/application/system_clock_provider.dart:16` | 既有 SystemClock 增加固定时刻构造；默认实现继续读系统时间。 |
| `lib/features/mainline/application/mainline_settlement.dart:145` | 主线胜利、参与者战败通过可注入依赖读同一时钟；独立 eventRandom/milestoneRng 默认为空。 |
| `lib/features/tower/application/tower_settlement.dart:92` | 塔胜利、塔战斗结算通过可注入依赖读时钟；掉落时间和事件时间沿链透传。 |
| `lib/features/equipment/application/milestone_grant_hook.dart:50` | InTxn 里程碑 hook 透传可选既有时钟和独立 Rng；主线传入固定结算时刻，其他入口不变。 |
| `lib/features/seclusion/application/online_presence_controller.dart:24` | 真实 onlinePresenceControllerProvider 接入既有时钟 provider，构造回调仍可单独注入。 |
| `lib/features/seclusion/presentation/active_retreat_screen.dart:108` | 收功写入时间走既有 provider；两个界面展示计时点保持原样。 |
| `lib/features/seclusion/presentation/seclusion_gate.dart:95` | 入口自动收功向 completeRetreat 传入同一抽象的时间。 |

四个结算函数所在两个 application 文件均无裸 `DateTime.now()` 或时钟函数引用。原始 `grep -c 'Random('` 在两个文件各命中 1 行，均为读取已注入回调的 getter，并非构造随机源。

| 文件 | 原始 `DateTime.now()` 行数 | 原始 `Random(` 行数 | 例外解释 |
|---|---:|---:|---|
| `lib/features/mainline/application/mainline_settlement.dart` | 0 | 1 | 第 144 行 `math.Random get mathRandom => _readMathRandom();` 是 getter 委托 |
| `lib/features/tower/application/tower_settlement.dart` | 0 | 1 | 第 91 行 `math.Random get mathRandom => _readMathRandom();` 是 getter 委托 |
| `lib/features/seclusion/application/passive_idle_integrator.dart` | 0 | 0 | 无上述裸调用 |
| `lib/features/seclusion/application/offline_passive_service.dart` | 0 | 0 | 无上述裸调用 |
| `lib/features/seclusion/application/seclusion_service.dart` | 0 | 0 | 无上述裸调用 |
| `lib/features/seclusion/application/retreat_settlement_calculator.dart` | 0 | 0 | 无上述裸调用 |
| `lib/features/seclusion/application/online_presence_controller.dart` | 0 | 0 | 无上述裸调用 |
| `lib/features/seclusion/presentation/seclusion_gate.dart` | 0 | 0 | 无上述裸调用 |
| `lib/features/seclusion/presentation/active_retreat_screen.dart` | 2 | 0 | 第 60 行为展示计时，不参与 completeRetreat 写入；第 62 行为展示计时，不参与 completeRetreat 写入 |

闭关稳定种子保留点：`lib/features/seclusion/application/retreat_settlement_calculator.dart:84`。不属于 Random/newMathRandom 字面扫描；继续用 saveDataId/session.id/startedAt/nodeIndex 构造稳定 seed，不替换为共享可变 RNG。

`active_retreat_screen.dart` 的两处真实时间仅初始化/刷新界面展示，作为明确范围例外保留；实际收功与 `seclusion_gate.dart` 的完成调用均读 `systemClockProvider`。`passive_idle_integrator.dart`、`offline_passive_service.dart`、`seclusion_service.dart` 和 `retreat_settlement_calculator.dart` 沿用权威 `now`/经过时间输入。

## 已核验的被动积分与闭关证据

- 新增 `test/features/seclusion/application/settlement_clock_determinism_test.dart`：真实在线 provider 固定时钟重放一致、改变时钟收益不同；完整闭关结果和 8 张相关表逐字段比较一致，改变完成时间或持久会话 seed 输入产生差异。生产稳定 seed 规则不变。
- `../logs/A-3_seclusion_determinism.log`：`00:02 +4: All tests passed!`。时钟 provider 临时恢复 `DateTime.now` 后，`../logs/A-3_clock_provider_break_red.log` 为退出码 `1`、1 失败/3 通过；第一条固定时间断言失败。随后字节级还原，`../logs/A-3_seclusion_determinism_restored.log`：`00:02 +4: All tests passed!`。
- 既有聚焦回归：`../logs/A-3_online_presence_regression.log` 为 `00:03 +15: All tests passed!`；`../logs/A-3_seclusion_drop_regression.log` 为 `00:01 +4: All tests passed!`。
- 本节只列已经执行的局部验证；四函数确定性测试、完整套件、analyzer 与格式检查由最终恢复点和收据记录。

## 逐点残留清单

以下均为六个核心范围文件之外的剩余点。服务默认实现不等于每个调用方都仍有缺口：事件/掉落/里程碑/补票已接线与未改调用方在建议中分别说明。

| 位置 | 表达式 | 离线结算或回放影响 | 建议 | 分类置信度 |
|---|---|---|---|---|
| `lib/core/application/system_clock_provider.dart:21` | `DateTime.now()` | 间接：既有系统时钟默认实现 | 允许在抽象默认实现保留真实系统时钟；消费者通过 provider 或已有 SystemClock 实例注入。 | 高 |
| `lib/data/isar_setup.dart:113` | `DateTime.now()` | 间接：存档创建、迁移或保存时间；可能影响离线锚点 | 与存档初始化/保存契约分开验证；已有 now 则调用方注入，避免借结构整改改真实存档。 | 中 |
| `lib/data/isar_setup.dart:315` | `DateTime.now()` | 间接：存档创建、迁移或保存时间；可能影响离线锚点 | 与存档初始化/保存契约分开验证；已有 now 则调用方注入，避免借结构整改改真实存档。 | 中 |
| `lib/data/isar_setup.dart:1184` | `DateTime.now()` | 间接：存档创建、迁移或保存时间；可能影响离线锚点 | 与存档初始化/保存契约分开验证；已有 now 则调用方注入，避免借结构整改改真实存档。 | 中 |
| `lib/features/activity/application/durable_activity_automation_coordinator.dart:83` | `newMathRandom(seed: admission.run.seed)` | 直接：按持久化或测试 seed 重建战斗随机序列 | 此点已经显式播种；保留每次战斗重建语义，不替换为会共享可变序列的全局单例。 | 高 |
| `lib/features/activity/application/durable_activity_automation_coordinator.dart:179` | `newMathRandom(seed: admission.run.seed)` | 直接：按持久化或测试 seed 重建战斗随机序列 | 此点已经显式播种；保留每次战斗重建语义，不替换为会共享可变序列的全局单例。 | 高 |
| `lib/features/activity/application/durable_activity_automation_coordinator.dart:209` | `DateTime.now()` | 直接：无界面差遣回放入口的耗时/结算时刻 | 回放计时与传入四结算的时间也须注入，否则上游覆盖会绕过下游固定时钟。 | 高 |
| `lib/features/activity/application/durable_activity_automation_coordinator.dart:221` | `DateTime.now()` | 直接：无界面差遣回放入口的耗时/结算时刻 | 回放计时与传入四结算的时间也须注入，否则上游覆盖会绕过下游固定时钟。 | 高 |
| `lib/features/activity/application/durable_activity_automation_service.dart:124` | `DateTime.now()` | 直接：其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/activity/application/durable_activity_automation_service.dart:221` | `DateTime.now()` | 直接：其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/activity/application/durable_activity_automation_service.dart:364` | `DateTime.now()` | 直接：其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/activity/application/durable_activity_automation_service.dart:457` | `DateTime.now()` | 直接：其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/activity/application/durable_activity_automation_service.dart:489` | `DateTime.now()` | 直接：其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/activity/application/durable_activity_automation_service.dart:514` | `DateTime.now()` | 直接：其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/ascension/application/ascend_service.dart:239` | `DateTime.now()` | 间接或待核：其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/ascension/presentation/ascension_screen.dart:216` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/baike/presentation/baike_screen.dart:126` | `DateTime.now()` | 无直接写入影响：展示倒计时、入口提示或显示条件 | 保留表现层范围；仅在需要固定展示快照时注入，不据此扩大结算整改。 | 中 |
| `lib/features/battle_record/application/boss_memory_hook.dart:87` | `DateTime.now()` | 间接：战后图鉴/战绩记录包装层时间 | 持久记录可能与回放结果一起读取；明确输出边界后按已有服务 now 参数透传。 | 中 |
| `lib/features/boss_gauntlet/application/gauntlet_service.dart:383` | `DateTime.now()` | 直接：其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/boss_gauntlet/application/gauntlet_service.dart:428` | `DateTime.now()` | 直接：其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/boss_gauntlet/application/gauntlet_service.dart:573` | `DateTime.now()` | 直接：其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/boss_gauntlet/application/gauntlet_service.dart:693` | `DateTime.now()` | 直接：其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/boss_gauntlet/application/gauntlet_service.dart:987` | `DateTime.now()` | 直接：其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/boss_gauntlet/application/gauntlet_service.dart:1157` | `DateTime.now()` | 直接：其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/boss_gauntlet/application/gauntlet_service.dart:1290` | `DateTime.now()` | 直接：其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/boss_gauntlet/application/gauntlet_service.dart:1351` | `DateTime.now()` | 直接：其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/boss_gauntlet/application/phase0a_gauntlet_stage_runner.dart:99` | `newMathRandom(seed: seed)` | 直接：按持久化或测试 seed 重建战斗随机序列 | 此点已经显式播种；保留每次战斗重建语义，不替换为会共享可变序列的全局单例。 | 高 |
| `lib/features/boss_gauntlet/presentation/phase0a_gauntlet_battle_host.dart:74` | `newMathRandom(seed: plan.seed)` | 直接：按持久化或测试 seed 重建战斗随机序列 | 此点已经显式播种；保留每次战斗重建语义，不替换为会共享可变序列的全局单例。 | 高 |
| `lib/features/combat_shared/domain/damage_calculator.dart:86` | `newMathRandom()` | 间接：战斗回放领域计算的缺省随机源 | ctx.rng 为空才创建无种子源；保持现有规则，回放调用方必须传入既有固定种子的随机对象。 | 高 |
| `lib/features/cultivation/application/technique_learn_flow_service.dart:106` | `DateTime.now()` | 间接或待核：其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/debug/application/phase0a_debug_battle_fixture.dart:157` | `Random(config.seed)` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:268` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:410` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:427` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:445` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:544` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:606` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:675` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:803` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:907` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:946` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:974` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:1043` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:1067` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:1093` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:1118` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:1442` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:1456` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/phase2_seed_service.dart:1580` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/application/redline_audit.dart:350` | `Random(7)` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/presentation/visual_route_host.dart:395` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/presentation/visual_route_host.dart:432` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/presentation/visual_route_host.dart:573` | `Random(20260824)` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/presentation/visual_route_host.dart:855` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/presentation/visual_route_host.dart:894` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/debug/presentation/visual_route_host.dart:1049` | `DateTime.now()` | 无生产直接影响：调试种档或视觉夹具 | 保留调试范围；固定 seed 已可复现，不据此宣称生产结算确定。 | 高 |
| `lib/features/equipment/application/drop_service.dart:69` | `DateTime.now` | 间接：装备 obtainedAt 的可选时钟默认值 | 已有 now 回调；本轮结算通过依赖或本地构造注入，同类域外调用仍可走默认。 | 高 |
| `lib/features/equipment/application/equipment_disposal_service.dart:233` | `DateTime.now()` | 间接或待核：其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/equipment/application/forging_service.dart:151` | `DateTime.now()` | 间接或待核：其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/equipment/application/milestone_equipment_grant_service.dart:27` | `DateTime.now` | 间接：里程碑装备授予的可选时钟默认值 | 主线通过 InTxn hook 透传同一时刻及独立可选 milestoneRng；其他调用方继续使用默认 now 和独立 DefaultRng。 | 高 |
| `lib/features/event/application/game_event_service.dart:81` | `newMathRandom()` | 间接：事件典故的可选独立随机源默认值 | 主线和塔已透传独立 eventRandom；未注入时仍用原独立随机源，不挪用技能残页序列。其他调用方保留默认。 | 高 |
| `lib/features/event/application/game_event_service.dart:121` | `DateTime.now()` | 范围外直接：奇遇触发、习得心法或武学领悟事件时间 | 这些事件方法未进入本轮四结算及闭关直接调用链，仍用墙钟；相关交互或完整奇遇重放另行接线。 | 高 |
| `lib/features/event/application/game_event_service.dart:184` | `DateTime.now()` | 范围外直接：奇遇触发、习得心法或武学领悟事件时间 | 这些事件方法未进入本轮四结算及闭关直接调用链，仍用墙钟；相关交互或完整奇遇重放另行接线。 | 高 |
| `lib/features/event/application/game_event_service.dart:202` | `DateTime.now()` | 范围外直接：奇遇触发、习得心法或武学领悟事件时间 | 这些事件方法未进入本轮四结算及闭关直接调用链，仍用墙钟；相关交互或完整奇遇重放另行接线。 | 高 |
| `lib/features/expedition/application/expedition_service.dart:159` | `DateTime.now()` | 直接：其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/expedition/application/expedition_service.dart:542` | `DateTime.now()` | 直接：其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/expedition/application/expedition_service.dart:736` | `DateTime.now()` | 直接：其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/expedition/application/expedition_service.dart:764` | `DateTime.now()` | 直接：其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/expedition/application/expedition_service.dart:1171` | `DateTime.now()` | 直接：其他离线活动的会话/推进/奖励写入 | 多数入口已有 now；逐调用链透传固定时间，裸写入点列后续范围，不宣称本批已统一。 | 中 |
| `lib/features/expedition/application/phase0a_expedition_combat_runner.dart:213` | `newMathRandom(seed: nodeSeed)` | 直接：按持久化或测试 seed 重建战斗随机序列 | 此点已经显式播种；保留每次战斗重建语义，不替换为会共享可变序列的全局单例。 | 高 |
| `lib/features/expedition/presentation/phase0a_expedition_milestone_battle_host.dart:85` | `newMathRandom(seed: plan.nodeSeed)` | 直接：按持久化或测试 seed 重建战斗随机序列 | 此点已经显式播种；保留每次战斗重建语义，不替换为会共享可变序列的全局单例。 | 高 |
| `lib/features/festival/application/festival_service.dart:24` | `DateTime.now()` | 间接：节日条件可影响奇遇资格 | 已有 when 参数；确定性结算需基于同一结算日期派生 festivalToday，不能读取墙钟日期。 | 高 |
| `lib/features/inventory/application/item_use_service.dart:36` | `DateTime.now()` | 间接或待核：其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/inventory/application/item_use_service.dart:198` | `DateTime.now()` | 间接或待核：其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/jianghu/application/npc_relation_service.dart:42` | `DateTime.now()` | 间接：声望/关系记录写入时间 | 事务接口如已有 now 则保持透传；包装层时钟作为域外余项。 | 中 |
| `lib/features/jianghu/application/npc_relation_service.dart:47` | `DateTime.now()` | 间接：声望/关系记录写入时间 | 事务接口如已有 now 则保持透传；包装层时钟作为域外余项。 | 中 |
| `lib/features/jianghu/application/reputation_service.dart:28` | `DateTime.now()` | 间接：声望/关系记录写入时间 | 事务接口如已有 now 则保持透传；包装层时钟作为域外余项。 | 中 |
| `lib/features/lineage/application/disciple_join_service.dart:83` | `DateTime.now()` | 间接或待核：其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/main_menu/application/main_menu_status_summary_provider.dart:101` | `DateTime.now()` | 无直接写入影响：展示倒计时、入口提示或显示条件 | 保留表现层范围；仅在需要固定展示快照时注入，不据此扩大结算整改。 | 中 |
| `lib/features/main_menu/presentation/main_menu_retreat_banner.dart:30` | `DateTime.now()` | 无直接写入影响：展示倒计时、入口提示或显示条件 | 保留表现层范围；仅在需要固定展示快照时注入，不据此扩大结算整改。 | 中 |
| `lib/features/mainline/presentation/phase0a_mainline_battle_host.dart:119` | `newMathRandom(seed: widget.seedForTest)` | 直接：可选测试 seed 的战斗随机工厂 | 固定 seed 时可重建序列；默认 seed 仍可能为空，不把可注入能力当作所有调用已确定。 | 高 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:237` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:296` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:540` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:597` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:627` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:656` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:706` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:873` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:880` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1053` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1154` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1242` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1311` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1322` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1357` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1362` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1373` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1379` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1401` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1477` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1482` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_entry_flow.dart:1488` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/mainline/presentation/stage_list_screen.dart:1881` | `DateTime.now()` | 无直接写入影响：展示倒计时、入口提示或显示条件 | 保留表现层范围；仅在需要固定展示快照时注入，不据此扩大结算整改。 | 中 |
| `lib/features/onboarding/application/master_builder.dart:163` | `DateTime.now()` | 间接或待核：其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/onboarding/application/onboarding_service.dart:94` | `DateTime.now()` | 间接或待核：其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/progressive_unlock/presentation/progressive_unlock_seal.dart:29` | `DateTime.now()` | 无直接写入影响：展示倒计时、入口提示或显示条件 | 保留表现层范围；仅在需要固定展示快照时注入，不据此扩大结算整改。 | 中 |
| `lib/features/recruitment/application/recruitment_service.dart:87` | `DateTime.now()` | 间接或待核：其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/save_management/application/save_management_service.dart:18` | `DateTime.now` | 间接：存档管理默认时钟 | 已有 now 回调，可从既有 SystemClock 透传；不是本单四结算范围。 | 高 |
| `lib/features/seclusion/presentation/active_retreat_screen.dart:60` | `DateTime.now()` | 无直接写入影响：闭关展示计时器（明确例外） | 仅初始化和刷新显示时间；completeRetreat 写入已改读 systemClockProvider，不改变展示 timer。 | 高 |
| `lib/features/seclusion/presentation/active_retreat_screen.dart:62` | `DateTime.now()` | 无直接写入影响：闭关展示计时器（明确例外） | 仅初始化和刷新显示时间；completeRetreat 写入已改读 systemClockProvider，不改变展示 timer。 | 高 |
| `lib/features/seclusion/presentation/offline_recap_gate.dart:48` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/seclusion/presentation/seclusion_map_list_screen.dart:296` | `DateTime.now()` | 无直接写入影响：展示倒计时、入口提示或显示条件 | 保留表现层范围；仅在需要固定展示快照时注入，不据此扩大结算整改。 | 中 |
| `lib/features/seclusion/presentation/seclusion_map_list_screen.dart:611` | `DateTime.now()` | 无直接写入影响：展示倒计时、入口提示或显示条件 | 保留表现层范围；仅在需要固定展示快照时注入，不据此扩大结算整改。 | 中 |
| `lib/features/seclusion/presentation/seclusion_setup_screen.dart:70` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/sect/presentation/sect_recruit_handler.dart:69` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/sect/presentation/sect_recruit_handler.dart:97` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/shop/application/shop_service.dart:67` | `DateTime.now()` | 间接或待核：其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/sweep/application/sweep_readiness_service.dart:13` | `DateTime.now()` | 间接或待核：其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/sweep/application/sweep_readiness_service.dart:29` | `DateTime.now()` | 间接或待核：其他持久写入/服务入口 | 本点位于范围外；按真实消费者验证是否进入离线/回放输出后，再透传既有时钟。 | 中 |
| `lib/features/sweep/application/sweep_settlement.dart:142` | `DateTime.now()` | 直接：扫荡结算调用方时间 | 调用四结算时沿用同一注入时钟；下游接受固定时钟不代表上游已固定。 | 高 |
| `lib/features/sweep/application/sweep_settlement.dart:230` | `DateTime.now()` | 直接：扫荡结算调用方时间 | 调用四结算时沿用同一注入时钟；下游接受固定时钟不代表上游已固定。 | 高 |
| `lib/features/sweep/presentation/sweep_readiness_status.dart:231` | `DateTime.now()` | 无直接写入影响：展示倒计时、入口提示或显示条件 | 保留表现层范围；仅在需要固定展示快照时注入，不据此扩大结算整改。 | 中 |
| `lib/features/taohua_island/application/island_action_service.dart:106` | `DateTime.now()` | 直接：桃花岛积分/动作会先结算离线收益 | 使用同一注入时刻驱动动作前积分；现有 now 参数入口保持可覆写。 | 中 |
| `lib/features/taohua_island/application/island_action_service.dart:199` | `DateTime.now()` | 直接：桃花岛积分/动作会先结算离线收益 | 使用同一注入时刻驱动动作前积分；现有 now 参数入口保持可覆写。 | 中 |
| `lib/features/taohua_island/application/island_providers.dart:74` | `DateTime.now()` | 直接：桃花岛积分/动作会先结算离线收益 | 使用同一注入时刻驱动动作前积分；现有 now 参数入口保持可覆写。 | 中 |
| `lib/features/taohua_island/presentation/taohua_island_screen.dart:134` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/taohua_island/presentation/taohua_island_screen.dart:188` | `DateTime.now()` | 无直接写入影响：桃花岛展示计时器 | 仅界面刷新；采收/升阶动作时间另项处理。 | 高 |
| `lib/features/taohua_island/presentation/taohua_island_screen.dart:314` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/tower/application/tower_progress_service.dart:235` | `DateTime.now()` | 间接：独立补票入口的可选 now 默认值 | getOrCreate 已接收既有时钟并向补票透传；独立调用未传 now 时保持旧默认，不作为本轮调用链阻塞。 | 高 |
| `lib/features/tower/presentation/phase0a_tower_battle_host.dart:79` | `newMathRandom(seed: widget.seedForTest)` | 直接：可选测试 seed 的战斗随机工厂 | 固定 seed 时可重建序列；默认 seed 仍可能为空，不把可注入能力当作所有调用已确定。 | 高 |
| `lib/features/tower/presentation/tower_entry_flow.dart:211` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/tower/presentation/tower_entry_flow.dart:330` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/tower/presentation/tower_entry_flow.dart:564` | `DateTime.now()` | 间接：前台业务入口时间、会话标识或动作参数 | 区分交互发生时刻与结算时刻；需精确回放时从既有时钟注入，当前仅登记。 | 中 |
| `lib/features/weapon_codex/application/equipment_catalog_hook.dart:19` | `DateTime.now()` | 间接：战后图鉴/战绩记录包装层时间 | 持久记录可能与回放结果一起读取；明确输出边界后按已有服务 now 参数透传。 | 中 |
| `lib/shared/utils/math_random.dart:21` | `newMathRandom()` | 间接：既有 dart:math 随机源边界 | 默认入口本身不是绕注入；须检查上游是否显式提供固定 seed 或 provider override。 | 高 |
| `lib/shared/utils/math_random.dart:25` | `Random(seed)` | 间接：既有 dart:math 随机源边界 | 默认入口本身不是绕注入；须检查上游是否显式提供固定 seed 或 provider override。 | 高 |
| `lib/shared/utils/rng.dart:25` | `Random(seed)` | 间接：既有随机源基础实现 | 保留 DefaultRng(seed) 构造；生产消费者通过 rngProvider/seededRngFactoryProvider 选择种子。 | 高 |
