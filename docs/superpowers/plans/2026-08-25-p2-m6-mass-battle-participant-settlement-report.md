# P2-M6 守城实际参与者结算报告纵切

## 结果合同

- 单一目标：把“江湖地图 → 守城地点详情 → 每次挑战选择 eligible 角色 → 保留既有阵型选择 → 真实 `Phase0aMainlineBattleHost` → 共享胜负结算 → 实际参与者报告”接成一条生产路径。
- 不做：不改 reducer/session/headless、战斗规则、阵型配置或数值、YAML、奖励经济、解锁、叙事、schema/saveVersion、main；不把本切片写成 M6 或二阶段完成。
- 固定门：M6 守城必要生产子门 `0/1 → 1/1`；顶层 M0–M9 仍按权威记录报告，不因子门 READY 晋升。
- 基线：`2bf020b004aeb8f6f2d0c6e28a92c4f1bcdf2847`，由 `9354ff9521ee469c238226bd29a1702bec7631cb` 串行链进入；primary main 不触碰。
- 成本边界：约 90 分钟内完成或精确停在 BLOCKED；周用量无可靠读数，记录可观察耗时与集成返工。

## 生产路径假设

1. `CharacterOccupancyService` + `loadDiscipleSchedulingSummary` 是候选和进入复核的共同事实源。
2. `MassBattleScreen` 只负责关卡状态与选择入口；`runStageFlow` 继续作为唯一挑战流程。
3. `Phase0aMainlineBattleHost` 继续作为唯一 live controller/Host；`massBattleFormation` 继续由既有 `_pickFormation` 注入 `Phase0aStageContentMapper.mapMassBattle`。
4. 共享 `applyVictoryResolution` / `applyParticipantDefeatResolution` 继续经 `CombatResolutionService.resolveSnapshot` 写成长、伤势、装备 battle count、心法使用和报告；仅扩大 exact participant 校验到守城。

## 验收证据

- 红测覆盖候选顺序与边界、快照 exact identity、悬空装备/心法、活动占用/疗养/死亡/无主修、地图详情可用人数、阵型注入、胜负 settlement/report actual participant。
- 守城定向与相邻活动测试；scoped/root `flutter analyze --no-pub` 0 issue；format、`git diff --check`、owned-file 双向白名单和语义复核；候选稳定后一次必要全量。
- 最终 clean READY tip、registry/audit/CLAUDE/GDD/PROGRESS 与实现一致；main/origin main 不变。

## 停止条件

- 若发现 schema、数据/调优、奖励/解锁/叙事、阵型规则或第二 reducer/session/settlement 真相源需求，停止实现并标记 BLOCKED。
- 若约 90 分钟没有把守城生产子门从 `0/1` 推进，暂停扩展并报告最高价值下一步。
