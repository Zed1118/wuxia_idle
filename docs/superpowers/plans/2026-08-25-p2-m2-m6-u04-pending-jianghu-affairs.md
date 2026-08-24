# P2 M2/M6 U04 待处理江湖事持久队列计划

## 任务包

- taskId：`P2-M2-M6-U04-PENDING-JIANGHU-AFFAIRS`
- milestone：M2/M6
- priority：P0 night batch first
- owner：`codex_root`
- goal：把第一章结算后需要玩家选择的互动奇遇与 Boss 招降迁入可恢复、FIFO、只消费一次的 typed 持久队列。
- playerVisibleOutcome：战斗结算后即使崩溃，未完成选择仍会恢复；已确认选择不会重复发奖、招人或改关系。
- nonGoals：不恢复 opening/victory/defeat 强制叙事；不改奇遇/招降概率、奖励、解锁、数值、文案或任何 `TUNE-*`。

## 基线与隔离

- baseCommit：`6c849cccaec85703438bc53e7e4d958e3962d358`
- branch：`codex/phase2-m2-m6-u04-pending-jianghu-affairs-20260825`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-m6-u04-pending-jianghu-affairs`
- prerequisites：`P2-M2-M6-U01-DURABLE-SETTLEMENT-RECOVERY` clean READY。
- schemaVersion：只批准到 `0.40.0`；新增 Isar collection/字段或 saveVersion 前必须取得用户批准。
- forbiddenFiles：`data/**`、`lib/features/battle/**`、`main` checkout、任何调优/概率/奖励数据。

## 初始文件白名单

- `lib/features/mainline/domain/mainline_pending_jianghu_affair.dart`
- `lib/features/mainline/application/mainline_pending_jianghu_affair_service.dart`
- `lib/features/mainline/application/mainline_settlement_journal_service.dart`
- `lib/features/mainline/presentation/stage_entry_flow.dart`
- `lib/features/encounter/application/encounter_service.dart`
- `lib/features/encounter/presentation/encounter_hook.dart`
- `lib/features/sect/presentation/stage_boss_recruit_hook.dart`
- `lib/features/sect/presentation/sect_recruit_handler.dart`
- `lib/features/sect/application/sect_recruit_transaction_service.dart`
- `lib/shared/utils/rng_provider.dart`
- `test/features/mainline/domain/mainline_pending_jianghu_affair_test.dart`
- `test/features/mainline/application/mainline_pending_jianghu_affair_service_test.dart`
- `test/features/mainline/application/mainline_settlement_journal_service_test.dart`
- `test/features/mainline/presentation/mainline_pending_jianghu_affair_recovery_test.dart`
- `test/features/mainline/presentation/mainline_durable_settlement_recovery_test.dart`
- `test/features/encounter/application/encounter_service_test.dart`
- `test/features/sect/application/sect_recruit_transaction_service_test.dart`
- `test/data/mainline_settlement_journal_migration_test.dart`
- `test/data/experience_threshold_production_usage_contract_test.dart`
- `CLAUDE.md`
- `GDD.md`
- `PROGRESS.md`
- `docs/_archive/GDD_CHANGELOG.md`
- `docs/superpowers/plans/2026-08-25-p2-m2-m6-u04-pending-jianghu-affairs.md`
- `docs/audit/phase2_m2_m6_u04_pending_jianghu_affairs_2026-08-25.md`
- `docs/dispatch/phase0a_overhaul/task_registry.yaml`

若审计证明需要其他文件，必须先在本计划写明理由再扩白名单。

`encounter_service_test.dart` 在 transaction-owned API 抽取后扩入，专门证明
outcome/trigger 写入可被 caller 事务整体回滚；不扩大产品行为。
`mainline_durable_settlement_recovery_test.dart` 扩入用于把旧的“直接
close receipt”预期升级为“先排空 typed outbox 再 close”，保留上批
durable settlement 的不重发回归。
`CLAUDE.md` / `GDD.md` / `PROGRESS.md` / `GDD_CHANGELOG.md` 在代码候选、
独立复审和最终验证成立后扩入，仅同步 U04 本纵切的真实消费边界、
证据与剩余缺口，不修改设计决议或调优状态。
`rng_provider.dart` 与 `experience_threshold_production_usage_contract_test.dart` 是全量
门禁首轮精确报红后的最小扩围：前者提供可 override 的 seeded RNG factory，
后者只把新的 RealmDef 派生角色创建 sink 登记为已审计例外，不放宽全仓扫描口径。

## 冻结合同与生产边界

1. settlement journal 仍是“本关核心结算是否提交”的唯一真相源；pending affair 只引用已提交 settlement identity，不复制成长、伤势、掉落或进度 receipt。
2. 每个事项使用 canonical `sourceKind + sourceId + settlementId + ordinal` 去重；payload 为 typed 字段，不保存 callback、不复用 `GameEvent` 历史表、不用字符串猜测。
3. 队列按单调 `sequence` FIFO；`pending/presenting/resolved` 中 `presenting` 重启后仍重新呈现。
4. 玩家选择产生的所有业务写入与 `resolved` 标记必须在同一 Isar 事务；注入失败整体回滚。
5. 无事项时不弹 UI、不改导航；不把主线 opening/victory/defeat 重新强制化。

## 实现切片与 TDD

1. 只读核对现有事件、招降、journal、导航与 Isar schema；已证明 `0.40.0` journal 是可复用的专用 outbox，无需 schema 变更。
2. 写缺失 typed ref/严格 codec/FIFO 消费 API 的真实红测，覆盖 canonical 去重、presenting 恢复、原子 resolve 与失败回滚合同。
3. 在核心 settlement 同一事务内完成 trigger/RNG 判定并生成 refs；调用方只经严格 parser 读取，禁止 `startsWith`/随手 `split` 猜类型。
4. 最小接第一章连续首通生产路径，再跑定向、主线回归、analyze、全量；不改可见布局则不伪造双视口结论。

## 验收与停止条件

- red evidence：删除/缺失 typed queue contract 时目标测试必须编译失败或断言失败。
- targeted：队列领域/服务、第一章普通/Boss/无事项、返回地图/下一关、durable settlement 回归。
- final gates：analyze 0、`git diff --check`、白名单 0 越界、独立语义复核 P0/P1=0、clean tip。
- stopConditions：实现中若新发现必须 schema bump/新 Isar collection/字段、调优值、活跃 owner 文件冲突或用户决策。
- escalationQuestion：是否批准在 `0.41.0` 新增专用 `PendingJianghuAffair` Isar collection 及迁移？
- READY tip：`[READY][CODEX][P2-M2-M6-U04] 收口待处理江湖事持久队列`
- BLOCKED tip：`[BLOCKED][CODEX][P2-M2-M6-U04] 等待待处理江湖事 schema 授权`

## 当前恢复点

- 状态：`ready_reviewed`。
- 最后完成：候选 `96196ac6ce0e1c768e5aab7ec8b0c1361a6af863` 已将第一章互动奇遇/Boss 招降接入现有 journal outbox，typed ref、FIFO、稳定 seed、重启重现、幂等 claim 及业务写入同事务成立；无 schema 变更。
- 下一步：本切片停止；整体目标继续按独立任务包推进 U01 听剑/全模式一致性、U05 及 M2-M9 未闭环项。
- 已跑验证：缺失 typed contract 编译红；首轮全量精确捕获 seeded RNG 不可注入与新角色创建 sink 未登记 2 条红线，修复后最终 **5315/5315 PASS**；`flutter analyze --no-pub lib test tool` 0 issue；独立复审 P0/P1=0。
- 阻塞：无。
