# Phase 2 M5 九霄塔自动准入阻塞复核与 READY 收口

## 结论

旧阻塞结论已被生产路径重资格化纠正：玩家可达的塔扫荡链位于 sweep application 域，而非 `lib/features/tower`。在该既有 runner 前接 typed admission、在共享 settlement 前重验后，`P2-M5-TOWER-AUTOMATION-ADMISSION` 固定验收门达到 `1/1 READY`。

- branch: `codex/phase2-tower-automation-admission-20260825`
- base: `218f74094473b7a20de705d523f10ff6307c35c0`
- code candidate: `e0069f7e`
- 顶层 M0–M9：仍 `1/10`
- M5 / M6 / U14 / Phase 2：仍开放

## Owner 核对

| 边界 | 当前真实 owner | 结论 |
| --- | --- | --- |
| 手动入口 | `TowerFloorListScreen._onChallenge` | 首通与可见实时挑战继续逐次选择实际参与者并调用 `runTowerFlow` |
| 自动入口 | `_TowerSweepButton` → `SweepScreen` | 当前周目全塔已完成后玩家可达；逐层提交 `TowerSweepUnit` |
| typed 请求/准入 | `TowerSweepUnit` / `TowerAutomationAdmissionService` | 只放行已首通层的 `direct + playerBot + headless + sweep` 精确 tuple |
| participant snapshot | `resolveTowerParticipantSnapshot` | live Host 组装前 fail closed |
| occupancy | `CharacterOccupancyService` | 角色、装备与心法占用在装配前拒绝 |
| automation runner | `Phase0aSweepHeadlessRunner.runTower` | 消费 admission exact snapshot，复用 mapper/assembler/同核 headless |
| settlement | `settleTowerSweepVictory` → `applyTowerCombatResolution` / `CombatResolutionService` | 写入前重验 admission 与 exact participant |
| 报告 | `SweepRecap.participantName` | 来自 runner admission snapshot 的实际参与者 |
| progress/reward | `TowerProgressService` 与既有塔奖励 hooks | 不得在本门复制或改语义 |

## Fail-closed 证据

请求内容/ID/装配计划/controller/clock/entry tuple 不符、未首通、无效或悬空掌门、历史/跨代、死亡、疗养、无主修、重复或已占用角色/装备/心法、悬空或错主装配、进度/provider 异常、角色身份或 snapshot/loadout/progress 变 stale、缺 admission、非终局或错人 settlement 均在塔进度/奖励写入前抛错，不回退其他角色。

## 验证

- RED/green 过程中先命中 nullable fixture 编译失败、缺角色 fixture、typed 使用账本断言不匹配，修复后最终定向 `18/18 PASS`。
- `flutter test --no-pub test/features/tower test/features/sweep`：`177/177 PASS`。
- 相邻活动、lineup occupancy、主线参与者、sweep settlement、current leader：`22/22 PASS`。
- `flutter test --no-pub test/data/truth_source_guard_test.dart`：`9/9 PASS`。
- `flutter analyze --no-pub lib test`：0 issue；`git diff --check`：PASS。
- 原“整仓全量约 5 小时”系把 reporter `5:00` 误读为小时，实际基线约 4–7 分钟。本子门未冒称整仓全量；跨门候选稳定后只跑一次必要全量。

## 非变更边界

零新 reducer、session、headless 内核、provider、settlement 真相源、schema/saveVersion、YAML、TUNING/candidate、奖励、经济、解锁、叙事、战斗规则或 main 变更。此 READY 不晋升 M5/M6/U14/Phase 2；顶层仍 `1/10`。
