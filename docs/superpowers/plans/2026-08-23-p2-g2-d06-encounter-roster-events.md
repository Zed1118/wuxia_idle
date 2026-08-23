# P2 G2 D06：Encounter Roster 与 Spawn 事件桥

## 任务

建立两个纯合同：

1. immutable `Phase0aEncounterRoster`：将 `SpawnDirector` 的每个 `entryId/enemyId` 精确绑定到一个完整 `Phase0aActor`（actor.position 即显式入场点）。
2. `Phase0aSpawnEventAdapter`：把 director `warningStarted/entered/graceExpired` 投影为带全局 seq/combat tick 的 `Phase0aEvent`，并接入 `Phase0aEventOrderAdapter`。

## Roster 冻结语义

- 输入包含 director、playerId 和 binding 列表；列表防御性复制并按 entryId 稳定排序。
- director 每个 entry 恰好一个 binding，不得 missing/extra/duplicate。
- binding.entryId 必须存在，binding.actor.id 必须等于该 entry.enemyId。
- actor 必须为 enemy side、初始存活、ID 不等于 playerId；全场 actor ID 唯一。
- 提供按 entryId/enemyId 的 fail-closed lookup，不暴露可变 map/list。

## 事件冻结语义

- 新增 `Phase0aSpawnWarningStarted`、`Phase0aEnemyEntered`、`Phase0aSpawnGraceExpired`。
- payload 包含 entryId、enemyId 和 roster actor.position；seq/tick 由调用方传入。
- adapter 要求 `seqStart >= 0`、`combatTick >= 0`，每个 director event.tick 必须等于 combatTick，否则 fail closed。
- 按 director events 原顺序分配连续 seq；不排序、不去重、不消费 RNG、不修改 director/roster/arena。
- `Phase0aEventOrderAdapter` 为三类新事件生成稳定 canonical payload。

## 文件边界

- `lib/features/battle/domain/phase0a/encounter_enemy_roster.dart`
- `lib/features/battle/domain/phase0a/phase0a_combat_events.dart`
- `lib/features/battle/application/phase0a/phase0a_spawn_event_adapter.dart`
- `lib/features/battle/application/phase0a/phase0a_event_order_adapter.dart`
- `test/features/battle/domain/phase0a/encounter_enemy_roster_test.dart`
- `test/features/battle/application/phase0a/phase0a_spawn_event_adapter_test.dart`
- 本计划文件

不改 CombatSession、reducer、SpawnDirector、AttackTokenDirector、EncounterFlow、assembler、data/UI/save/reward。

## 验收

- roster happy path、输入顺序无关、不可变与全部 fail-closed 边界通过。
- 三类事件 payload/tick/seq 正确，projection 与 canonical records 稳定。
- 非连续 director tick、未知 entry/enemy 映射和非法 seq/tick 拒绝。
- targeted tests、`dart analyze` 和 `git diff --check` 通过。
- 普通中文动宾提交，再创建空 READY commit：`[READY][QODER][P2-G2-D06] 完成 Encounter Roster 与 Spawn 事件桥`。

## 当前恢复点

- 状态：D06 已完成并冻结,等待主窗口评审。
- 最后完成：roster/事件/投影适配器与两套测试全部落地,20/20 targeted 通过。
- 已跑验证:`flutter analyze --no-pub lib/features/battle test/features/battle` 0 issue
  (全仓其余告警为既有 tools 等无关文件);两个新测试文件全过;相邻
  order adapter/spawn director/event mapping/ink vfx/source contract 回归无新增失败。
- 已知既有失败(基线同样失败,非本批引入):`phase0a_source_contract_test` 两条
  「不得出现数值参数默认值」指向未改动的 `qi_resource.dart` 与
  `phase0a_wave_battle_flow.dart`。
- 边界外最小机械修复:为保持编译,把三类新事件补进
  `phase0a_settlement_adapter.dart` 与 `phase0a_vfx_controller.dart` 的既有
  无操作分组(行为零变化,未新增表现件)。
- 下一步:主窗口复审后唤醒 E03。
- 阻塞项:无。
