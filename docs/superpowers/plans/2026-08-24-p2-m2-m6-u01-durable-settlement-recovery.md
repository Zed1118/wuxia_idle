# P2 M2/M6 U01 主线持久结算与崩溃恢复计划

## 目标与批准口径

- 基线：`d134f68d6b3f5a239554a33df5970d26a8a3a7ee`。
- 分支：`codex/phase2-m2-m6-u01-durable-settlement-20260824`。
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-m6-u01-durable-settlement`。
- 用户已批准：存档升至 `0.40.0`，新增专用 settlement journal/outbox；战斗未完成结算时崩溃重试当前关，已原子结算的 receipt 只恢复后置 UI/推进，不重复奖励、成长或伤势。
- 本批只处理第一章连续首通生产流，不外推到 replay/manual/auto/headless/扫荡全模式、U04/U05、M2/M6 或整个二阶段。

## 实现约束

1. 复用 Isar collection + service 体例，不新增第二套 reducer/session/headless 内核，也不把 `GameEvent` 或 `MainlineProgress` 冒充 claim ledger。
2. 持久 settlement identity 绑定 `runId + stageId + loadoutVersion + participantId`，canonical 唯一且 fail closed。
3. `prepared` 表示当前关尚未完成权威结算；重启只允许重新挑战同一关、同一参与者。
4. 核心角色/装备/心法/掉落/伤势/进度与 receipt 必须在同一 Isar 事务落库；事务回滚时 claim 不得残留。
5. 后置 effect 通过 receipt/outbox 逐项恢复；任何会写存档的 effect 必须自身幂等或与 effect claim 同事务，不能靠进程内 Set。
6. 不改数值、奖励金额/概率、听剑比例/cap、解锁表、叙事或候选调优。

## 初始白名单

- `lib/features/mainline/domain/mainline_settlement_journal.dart`
- `lib/features/mainline/domain/mainline_settlement_journal.g.dart`
- `lib/features/mainline/application/mainline_settlement_journal_service.dart`
- `lib/features/mainline/application/mainline_progress_service.dart`
- `lib/features/mainline/domain/mainline_run.dart`
- `lib/features/mainline/presentation/stage_entry_flow.dart`
- `lib/data/isar_setup.dart`
- `test/features/mainline/domain/mainline_settlement_journal_test.dart`
- `test/features/mainline/application/mainline_settlement_journal_service_test.dart`
- `test/features/mainline/presentation/mainline_durable_settlement_recovery_test.dart`
- `test/data/mainline_settlement_journal_migration_test.dart`
- `test/data/save_migration_version_gate_test.dart`
- `docs/superpowers/plans/2026-08-24-p2-m2-m6-u01-durable-settlement-recovery.md`
- `docs/audit/phase2_m2_m6_u01_durable_settlement_recovery_2026-08-24.md`
- `docs/dispatch/phase0a_overhaul/task_registry.yaml`
- `CLAUDE.md`
- `GDD.md`
- `PROGRESS.md`
- `docs/_archive/GDD_CHANGELOG.md`

若审计证明既有后置 effect 必须修改其他文件，先在本计划记录理由并扩白名单，不静默扩大。

## 红测与验收

1. 缺失 journal schema/API 的真实红测。
2. canonical identity、状态机非法跳转、同槽唯一 active run、错参与者/错关卡 fail closed。
3. `0.39.0 → 0.40.0` 旧档幂等迁移，旧档无伪造 active journal；未来版本继续拒绝。
4. `prepared` 重启回到同一关；`coreApplied` 重启不重放成长、伤势、掉落或进度。
5. 注入事务中断，验证全部业务字段和 receipt 一并回滚。
6. 第一章五关恢复后仍锁同一参与者、快照版本单调且不跨章。
7. 定向测试、主线目录、迁移矩阵、G2 保护链、root analyze、diff/白名单；最终候选只跑一次全量。

## 当前恢复点

- 状态：`in_progress / admission_and_design`。
- 最后完成：从 clean READY `d134f68d` 建立隔离分支/worktree；确认 registry 无其他 `in_progress` owner；确认现有 reward/failure ledger 仅进程内且存档无 settlement identity。
- 下一步：登记任务后，细查第一章所有后置写 effect 的幂等边界，锁定 journal 状态与 outbox effect 集合，再提交缺失 API 红测。
- 已跑验证：基线 `5274/5274 PASS`、root analyze 0 来自前批 READY；本批尚未运行测试。
- 阻塞：无；schema 与恢复策略已由用户批准。若 effect 原子化要求改变玩法/概率或扩至 U04/U05，立即停下。
