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

- `lib/features/jianghu/domain/pending_jianghu_affair.dart`
- `lib/features/jianghu/domain/pending_jianghu_affair.g.dart`
- `lib/features/jianghu/application/pending_jianghu_affair_service.dart`
- `lib/data/isar_setup.dart`
- `lib/features/mainline/presentation/stage_entry_flow.dart`
- `lib/features/encounter/application/encounter_service.dart`
- `lib/features/encounter/presentation/encounter_hook.dart`
- `lib/features/sect/presentation/stage_boss_recruit_hook.dart`
- `lib/features/sect/presentation/sect_recruit_handler.dart`
- `test/features/jianghu/domain/pending_jianghu_affair_contract_test.dart`
- `test/features/jianghu/application/pending_jianghu_affair_service_test.dart`
- `test/features/mainline/presentation/mainline_pending_jianghu_affair_recovery_test.dart`
- `test/data/pending_jianghu_affair_migration_test.dart`
- `docs/superpowers/plans/2026-08-25-p2-m2-m6-u04-pending-jianghu-affairs.md`
- `docs/audit/phase2_m2_m6_u04_pending_jianghu_affairs_2026-08-25.md`
- `docs/dispatch/phase0a_overhaul/task_registry.yaml`

若审计证明需要其他文件，必须先在本计划写明理由再扩白名单。

## 冻结合同与生产边界

1. settlement journal 仍是“本关核心结算是否提交”的唯一真相源；pending affair 只引用已提交 settlement identity，不复制成长、伤势、掉落或进度 receipt。
2. 每个事项使用 canonical `sourceKind + sourceId + settlementId + ordinal` 去重；payload 为 typed 字段，不保存 callback、不复用 `GameEvent` 历史表、不用字符串猜测。
3. 队列按单调 `sequence` FIFO；`pending/presenting/resolved` 中 `presenting` 重启后仍重新呈现。
4. 玩家选择产生的所有业务写入与 `resolved` 标记必须在同一 Isar 事务；注入失败整体回滚。
5. 无事项时不弹 UI、不改导航；不把主线 opening/victory/defeat 重新强制化。

## 实现切片与 TDD

1. 只读核对现有事件、招降、journal、导航与 Isar schema；先判定是否必须新增持久 schema。
2. 写缺失 typed collection/API 的真实红测，覆盖 canonical 去重、FIFO、presenting 恢复、原子 resolve 与失败回滚合同。
3. 若必须新增 collection/字段/saveVersion：提交红测与精确 schema 提案，状态改为 `BLOCKED_NEEDS_SCHEMA_APPROVAL`，不得绕过；立即切换 M3 无 schema 任务。
4. 若现有专用结构可合法复用：最小接生产路径，再跑定向、主线回归、analyze、全量和双视口（仅当可见 UI 改动）。

## 验收与停止条件

- red evidence：删除/缺失 typed queue contract 时目标测试必须编译失败或断言失败。
- targeted：队列领域/服务、第一章普通/Boss/无事项、返回地图/下一关、durable settlement 回归。
- final gates：analyze 0、`git diff --check`、白名单 0 越界、独立语义复核 P0/P1=0、clean tip。
- stopConditions：需要 schema bump/新 Isar collection/字段、调优值、活跃 owner 文件冲突或用户决策。
- escalationQuestion：是否批准在 `0.41.0` 新增专用 `PendingJianghuAffair` Isar collection 及迁移？
- READY tip：`[READY][CODEX][P2-M2-M6-U04] 收口待处理江湖事持久队列`
- BLOCKED tip：`[BLOCKED][CODEX][P2-M2-M6-U04] 等待待处理江湖事 schema 授权`

## 当前恢复点

- 状态：`in_progress / schema audit`。
- 最后完成：从 clean READY `6c849ccc` 建立独立分支/worktree；确认既有 journal 只有 effect id/完成 claim，招降业务写入与触发标记仍跨事务。
- 下一步：提交缺失 typed queue 合同红测与精确 schema 提案；若确认不可避免则冻结 BLOCKED 并切换 M3。
- 已跑验证：READY 祖先、worktree clean、全 worktree 脏状态扫描、registry `in_progress` 扫描。
- 阻塞：尚在完成 schema 必要性审计。

