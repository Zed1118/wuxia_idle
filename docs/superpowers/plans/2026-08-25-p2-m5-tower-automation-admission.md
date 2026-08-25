# Phase 2 M5 九霄塔自动准入结果合同

- 单一目标：九霄塔已首通层以 typed `ActivityParticipationRequest` 进入真实 production headless runner，并继续复用既有参与者快照、Phase 0A 内核与塔结算 owner。
- 固定验收门：`0/1 → 1/1`；policy、admission、真实 runner、结算与报告必须在同一生产路径成立。
- 重资格化基线：玩家可达生产链实际位于 sweep application 域：`_TowerSweepButton → SweepScreen → TowerSweepUnit → Phase0aSweepHeadlessRunner → settleTowerSweepVictory`。旧审计只检索 `lib/features/tower`，遗漏该 owner。
- 成本上限：单门约 90 分钟无验收门变化即停线；原“整仓全量约 5 小时”系把 reporter `5:00` 误读为小时，实际基线约 4–7 分钟。稳定子门先跑风险匹配域，跨门候选稳定后只跑一次必要全量。
- 非目标：新 reducer/session/headless 内核/provider/settlement 真相源、schema/saveVersion、YAML、TUNING、奖励、经济、解锁、叙事、战斗规则或 main。

## READY 结果

- 固定验收门达到 `1/1 READY`，代码候选 `e0069f7e`。
- 首通前仍仅人工实时路径；只有持久塔进度已标记该层完成时，`direct + playerBot + headless + sweep` 精确 tuple 才可进入自动重演。
- `CurrentLeaderResolver`、`TowerAutomationAdmissionService`、`resolveTowerParticipantSnapshot`、`CharacterOccupancyService`、既有 sweep runner、共享塔 settlement 与 sweep recap 实际参与者姓名在同一生产链贯通。
- 无效/悬空/跨代掌门、死亡、疗养、无主修、角色或装配占用、provider/进度异常、悬空或错主装备心法、stale admission 与错人 settlement 均在业务写入前 fail closed。
- 验证：最终定向 `18/18`、塔+sweep `177/177`、相邻占用/主线/结算 `22/22`、truth guard `9/9`、analyze 0、diff check 通过。
- 边界：仅关闭九霄塔自动准入子门；M0–M9 仍 `1/10`，M5/M6/U14/Phase 2 仍开放。
