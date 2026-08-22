# Phase 0A 敌方行动结算判定兼容计划

## 目标

让敌方技能起手与 Boss 蓄力起手继续符合旧 runner
`hadActions = actionLog.isNotEmpty` 的语义，避免玩家仅移动/闪避且敌方走
skill-only 循环时，战后少一次内息调息。只改结算事实判定。

## 分支

`main`（夜班直接收口、提交并推送）。

## 验收标准

- [x] 生产接线：`Phase0aEnemySkillStarted` 与
      `Phase0aBossChargeStarted` 均令 settlement `hadActions=true`。
- [x] targeted test：仅含上述事件的结算快照精确为有效战斗；既有
      settlement/charge 测试全绿。
- [x] 红线影响：不改 reducer、AI、伤害、胜负、奖励、YAML、文案或玩法数值。
- [x] 残留风险：移动本身仍不算战斗行动；这是 Phase 0A 新交互，与旧 runner
      无可比事件，本批不扩大口径。
- [x] 批末：analyze 0、format/diff check 通过。

## 任务切片

1. 对照旧 actionLog 与当前 21 类 Phase0aEvent，证伪伤害/施法其余漏项。
2. 只在 settlement switch 补两个敌方行动事件。
3. 补精确回归、更新总账、提交推送。

## 当前恢复点

- 状态：已完成，待提交推送。
- 最后完成：settlement 对敌方技能与 Boss 蓄力起手置 `hadActions=true`；
  伤害、施法记录与 reducer 均未改。
- 下一步：更新总账，提交推送。
- 已跑验证：Phase 0A application 139/139、主线结算 14/14、扫荡结算
  3/3，共 156/156；analyze 0、全仓 format 0 变更、diff check 通过。
  父提交 full 4226/4226；release 双架构构建及 codesign verify 通过。
- 阻塞项：无。
