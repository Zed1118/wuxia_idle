# P2 M2/M6 U01 可见主线重打参与者归属纵切

## 任务包

- taskId：`P2-M2-M6-U01-VISIBLE-REPLAY-PARTICIPANT`
- milestone：M2/M6
- owner：`codex_root`
- baseCommit：`94b5f0e9b4b9bcfd57a4c83a1abb808bdaf47a3c`
- branch：`codex/phase2-m2-m6-u01-participant-attribution-parity-20260825`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-m6-u01-participant-attribution-parity`
- status：`in_progress`

## 已确认生产缺口

G0 `MAINLINE-REPLAY-PARTICIPANT-01` 已冻结：可见重打与前台 bot 可选
eligible 空闲角色，记录、成长与伤势归实际参与者；headless/扫荡固定当前掌门。
当前 `StageListScreen -> runStageFlow -> Phase0aMainlineBattleHost` 的可见重打
没有选择入口，宿主默认重新解析当前掌门；`applyVictoryResolution` 虽按 settlement
参与者结算成长，但装备/Boss 历史事件仍以 `SaveData.founderCharacterId` 归属。

本纵切关闭“可见真人重打选择 + 实际参与者归属”这一条生产链，不冒充前台 bot、
无人值守 headless、扫荡、听剑或 U01 全量完成。

## 文件白名单

- `lib/features/mainline/presentation/stage_list_screen.dart`
- `lib/features/mainline/presentation/stage_entry_flow.dart`
- `lib/features/combat_shared/application/combat_progression_settlement_service.dart`
- `lib/shared/strings.dart`
- `test/features/mainline/presentation/mainline_visible_replay_participant_test.dart`
- `test/features/mainline/presentation/apply_victory_resolution_test.dart`
- `test/features/battle/application/combat_progression_settlement_service_test.dart`
- `docs/superpowers/plans/2026-08-25-p2-m2-m6-u01-visible-replay-participant.md`
- `docs/audit/phase2_m2_m6_u01_visible_replay_participant_2026-08-25.md`
- `docs/dispatch/phase0a_overhaul/task_registry.yaml`
- `CLAUDE.md`
- `GDD.md`
- `PROGRESS.md`
- `docs/_archive/GDD_CHANGELOG.md`

若实现需要其他文件，必须先写明真实依赖与理由再扩白名单。

## 生产合同

1. 仅可见 `realtime + human + replay` 主线入口显示选择；首推仍固定当前掌门。
2. 候选来自当前 active roster，必须存活、有主修且不被闭关/远征/断魂庄占用；
   最终装配失败继续 fail closed，不回退掌门。
3. 选择经既有 `MainlineParticipationPolicy` 解析后，把同一角色快照注入真实
   `Phase0aMainlineBattleHost`，不得只在 UI 留一个未消费 ID。
4. 战斗 settlement、经验/熟练度/伤势、装备与 Boss 历史事件归实际参与者；
   founder tutorial 语义继续只认真实 founder，不把事件 owner 偷换成 tutorial owner。
5. 不改 headless/扫荡固定掌门，不实现前台 bot，不碰听剑比例/cap、数值、奖励、
   解锁、概率、schema/saveVersion 或叙事。

## TDD 与验收

- 红测：双角色可见重打选择非掌门后，现生产入口缺参数/快照消费而报红；Boss 历史
  事件当前错误归 founder，断言实际参与者时失败。
- 定向：选择 UI 双视口、占用/死亡/无主修过滤、无 leader fallback、宿主快照消费、
  胜负结算和事件归属、founder tutorial 保持。
- 回归：mainline 目录、相关 combat settlement service、root analyze；最终一次全量。
- 最终 Gate：`git diff --check`、YAML、白名单 0 越界、独立语义复核 P0/P1=0、
  clean `[READY][CODEX][P2-M2-M6-U01-VISIBLE-REPLAY]` tip。

## 停止边界

若出现 schema bump、听剑调优、前台 bot 新产品入口或与活跃 owner 文件冲突，记录
精确阻塞并转向无冲突切片；不得借本任务扩大 UI 信息架构。
