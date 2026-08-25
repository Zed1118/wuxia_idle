# Phase 2 M5 九霄塔自动准入阻塞审计

## 结论

`P2-M5-TOWER-AUTOMATION-ADMISSION` 固定验收门保持 `0/1`，状态 `BLOCKED`。当前生产塔战只有 visible realtime 手动 Host；headless parity 只是测试直接消费通用内核，不能作为玩家可达的真实 runner 证据。

- branch: `codex/phase2-tower-automation-admission-blocked-audit-20260825`
- base: `29df638e008a532fc4ecb107428b1f52a107a507`
- 顶层 M0–M9：仍 `1/10`
- M5 / M6 / U14 / Phase 2：仍开放

## Owner 核对

| 边界 | 当前真实 owner | 结论 |
| --- | --- | --- |
| 手动入口 | `TowerFloorListScreen._onChallenge` | 逐次选择实际参与者后调用 `runTowerFlow` |
| participant snapshot | `resolveTowerParticipantSnapshot` | live Host 组装前 fail closed |
| visible controller | `Phase0aTowerBattleHost` + `Phase0aBattleController` | production 存在 |
| 通用 headless 内核 | `Phase0aHeadlessRunner` | production 共用基础存在，但塔 `lib/` 无消费者 |
| 塔 headless runner/admission | 无 | 阻塞本门 |
| settlement | `applyTowerCombatResolution` / `CombatResolutionService` | live 胜败共享账本存在 |
| progress/reward | `TowerProgressService` 与既有塔奖励 hooks | 不得在本门复制或改语义 |

`test/features/tower/presentation/phase0a_tower_wiring_test.dart` 能用 mapper、assembler 与通用 headless runner 证明同 seed 末态一致，但该文件位于 test，生产入口、首通门槛、stale participant 复核、headless settlement/报告均未消费它。

## 验证

- `flutter test --no-pub test/features/tower`：`117/117 PASS`。
- `lib/features/tower` 中 `ActivityParticipationRequest` 消费者：0。
- `lib/features/tower` 中 `Phase0aHeadlessRunner` 消费者：0。
- 未创建 policy、runner、provider、schema 或业务写入。

## 解阻条件

需要先建立一个真实 production tower headless runner owner，明确由哪一玩家入口触发以及如何复用现有 participant snapshot、mapper/assembler、通用 headless kernel、共享 settlement 和 `TowerProgressService`。在此之前，只写 typed allowlist 会把产品许可冒充可达能力。

## 非变更边界

零 reducer、session、headless 内核、provider、settlement 真相源、schema/saveVersion、YAML、TUNING/candidate、奖励、经济、解锁、叙事、战斗规则或 main 变更。
