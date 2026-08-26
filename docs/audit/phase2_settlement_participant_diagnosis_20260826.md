# P2-D1 主线结算参与者诊断（2026-08-26）

## Q1 纯净新存档还复现吗？

**结论：是，稳定复现。** 不使用 `phase2_seed_service`，从空 Isar 走生产
`OnboardingService.createFoundingMaster`，真人控制器+键盘输入真打赢 `stage_01_05`，
进入胜利结算仍抛 `StateError`，且 `stage_01_05` 进度未写入、胜利弹窗不可达。

- 新档/生产创建：`test/diagnostics/settlement_participant_diagnosis_test.dart:40,64-90`。
- 最小合法初始化：只用 `MainlineProgressService.recordVictory` 记录 `01_01–01_04`，
  使 `01_05` 处于 `available`且未通关；跳过的只是前四关战斗，未改角色、
  装配、参与请求或结算：`settlement_participant_diagnosis_test.dart:92-113`。
- 真打证据：`Phase0aMainlineBattleHost` + `ActivityController.human` + `keyJ`，
  终局 `BattleResult.leftWin`：`settlement_participant_diagnosis_test.dart:142-170`。
- 抛错及零进度污染：`settlement_participant_diagnosis_test.dart:186-237`。
- 命令：`flutter test --no-pub test/diagnostics/settlement_participant_diagnosis_test.dart`；
  输出：`00:00 +1: All tests passed!`（测试以期望抛错为通过条件）。

## Q2 两类 ID 的值、来源与首个分叉点

**`expectedParticipantId = 1`。** 纯净新档创建时祖师固定为 id 1，并写入
`SaveData.founderCharacterId`：`lib/features/onboarding/application/onboarding_service.dart:88-98,142-146`。
真实首通启动再由 `CurrentLeaderResolver` 解析为 `participantId`，写入
`MainlineRun.begin`：`lib/features/mainline/presentation/stage_entry_flow.dart:483-520`；单关流程从
`playerSnapshot.characterId` 设定 expected：`stage_entry_flow.dart:759-766`。本次在战前证明
`playerSnapshot.characterId == MainlineRun.participantId == 1`：诊断测试 `:115-137`。

**实际 `participantCharacterIds` 元素数 = 7，内容 =
`{-20004, -20003, -20002, -20001, -20000, -1, 1}`。** 诊断断言：
`settlement_participant_diagnosis_test.dart:169-184`。其中正 id 只有玩家 1，六个负 id 均为敌方。

**首个分叉点：`lib/features/battle/application/phase0a/phase0a_settlement_adapter.dart:87-90`。**
`participants` 在此对全部 `combatants`（玩家+敌方）建 `CombatParticipantSnapshot`，
而非只对 `playerActorId`；后续 `combat_settlement_snapshot.dart:60-62` 无过滤地取全部
`characterId` 成集。因此在该 adapter 之前锁定 id 始终是 1，正是 adapter
创建结算参与者列表时首次变成含敌方 id 的集合。

## Q3 五处 fail-closed 守卫的真实路径

| 守卫 | 真实路径与触发条件 | 本次命中 |
|---|---|---|
| `stage_entry_flow.dart:1793-1801` | 可见胜/败结算传入 expected 后，集合非唯一或不含 expected；胜利调用点 `:1842-1851`，败北 `:2248-2257` | **是**，抛指定可见结算异常 |
| `mainline_run_coordinator.dart:88-92` | 第一章连续首通 run 启动，`initialRun.participantId != initialPlayerSnapshot.characterId` | 否，本次二者均为 1 |
| `mainline_run_coordinator.dart:136-150` | 连续首通胜利选“下一关”并重载装配快照后，快照角色不等于 run 锁定角色 | 否，本次为定点 `01_05` 诊断 |
| `sweep_settlement.dart:86-100` | 主线扫荡/快速 headless 重打（生产调用 `sweep_unit.dart:86-99,148-164`）；结算未完成、expected 缺失、集合非唯一或错人 | **是**，同一纯净新档 settlement 抛指定 headless 异常 |
| `sweep_settlement.dart:181-197` | 真实塔扫荡（`sweep_unit.dart:188-232`）；先重验 admission，再对过滤后的正 id 集检查未完成/非唯一/不含 admission 角色 | 否，本次不跑塔 |

## 定性结论

**生产 bug，高把握。** 纯净新档在真实 Phase 0A 终局与两条主线结算均复现；
seed 不是必要条件。根因是引擎中性 settlement 合理携带敌方快照，但两处主线
“exact participant”守卫把未过滤的全 combatant id 集误当成玩家参与者集。

## 协调者复跑步骤

1. 在冻结基线/本分支执行 `flutter test --no-pub test/diagnostics/settlement_participant_diagnosis_test.dart`。
2. 确认唯一测试为 PASS；它已硬断言新档创建、`01_05 available`、真打左胜、
   7 个实际 id、两个指定 `StateError`、以及 `01_05` 未写进度。
3. 可执行 `rg -n "phase2_seed" test/diagnostics/settlement_participant_diagnosis_test.dart`；
   应为 0 匹配。本单不需改任何产品文件。
