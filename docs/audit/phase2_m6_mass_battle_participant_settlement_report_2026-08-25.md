# Phase 2 M6 守城实际参与者结算报告纵切审计

日期：2026-08-25
任务：`P2-M6-MASS-BATTLE-PARTICIPANT-SETTLEMENT-REPORT`
基线：`2bf020b004aeb8f6f2d0c6e28a92c4f1bcdf2847`
分支：`codex/phase2-m6-mass-battle-participant-settlement-report-20260825`

## 结论

守城必要生产子门由 `0/1` 推进为 `1/1`，可标记 `ready_reviewed`。顶层 M0–M9 仍只验收 `1/10`，M6 仍为 WIP；本结论不代表 M6 或 Phase 2 完成。

生产路径现为：江湖地图守城地点详情 → `MassBattleScreen` → 每次挑战选择当前掌门或当代存活门人中的 eligible 空闲角色 → 二次复核并由 `PlayerCombatantSnapshotAssembler.loadExactRoster` 装配 exact snapshot → 既有 `runStageFlow` → 既有 `_pickFormation` / `Phase0aMainlineBattleHost` / `Phase0aStageContentMapper.mapMassBattle` → 既有 `applyVictoryResolution` 或 `applyParticipantDefeatResolution` → `CombatResolutionService.resolveSnapshot`。胜负报告继续复用既有报告组件并使用实际参与者姓名。

## 边界与 fail-closed

- 候选只来自 `loadDiscipleSchedulingSummary`，复用 `CurrentLeaderResolver`、当代关系和 `CharacterOccupancyService`；不再由地点详情固定注入掌门。
- 活动占用、疗养、死亡、无主修、历史/跨代角色、掌门指针异常、重复占用、角色缺失以及装备/主修心法悬空均拒绝或不可选；选人后再次复核，不回退掌门。
- 共享结算要求 settlement participant IDs 是唯一且等于 exact participant；错人或未完成快照抛出并零写入。普通守城最终放弃重试的战败也进入同一 exact participant 伤势结算路径。
- 阵型、关卡链、周目、奖励、叙事、战斗规则、schema/saveVersion、YAML、调优、经济和解锁语义未改；未新建 reducer、session、headless 或结算真相源。

## 现场证据

- 参与者服务、选择器、地点详情、守城屏和共享 stage flow 定向集合：`48/48 PASS`。
- 守城/主线共享结算、战斗 Host 接线、轻功相邻回归集合：`71/71 PASS`。
- `flutter analyze --no-pub` scoped changed files：`0 issues`；应用根目录 `flutter analyze --no-pub lib test`：`0 issues`。
- `dart format`、`git diff --check`：通过。
- 最终全量：`5549/5549 PASS`，耗时 `5:01`。首轮异步句柄未返回退出摘要，未据此冒称通过；随后以可轮询会话补获明确 `exit_code=0`。
- 默认整仓 analyze 仍会扫描独立 `tools/phase0minus_probe`，因其 worktree 缺 package 依赖报告错误；该目录不属于本应用验收范围，`lib test` 根应用 analyze 已独立通过。
- registry、audit、CLAUDE/GDD/PROGRESS/GDD_CHANGELOG 已同步；提交前另做 owned-files 双向白名单、语义复核与 clean READY 检查。main 与 primary main 不修改。

## 未关闭范围

该纵切只关闭守城“逐次选人—真实生产战斗—共享结算—身份报告”必要子门。U01 全模式一致性、U08 完整差遣策略、M6 其他必要子门及 M0–M9/Phase 2 顶层验收仍按 registry 保持开放。
