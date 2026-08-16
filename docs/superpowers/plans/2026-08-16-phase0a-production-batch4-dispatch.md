# Phase 0A 根应用生产化第四批协调计划

## 目标

在第三批真实伤害链路之上补齐确定性的波次与终局状态机，产出 `wave_started`、`wave_cleared`、`battle_victory`、`battle_defeat` 强类型事件；只冻结模拟核到 session 的唯一结果，不接奖励、存档、UI 或旧 3v3。

## 已冻结边界

- 既有 `BattleResolutionService` 是终局事件下游副作用结算，不得被 Phase0a domain/application 导入；本批不发掉落、不写 Isar、不改角色成长。
- 新 flow/session 包装既有 `Phase0aCombatSession`，不得复制移动、AI、命中、伤害、CD 或真气规则。
- 首波 `wave_started` 全场一次，且排在首个战斗事件前；击杀末敌的顺序固定为 `enemy_defeated → wave_cleared → next wave_started | battle_victory`。
- 每拍 reducer 结束后唯一派生终局：玩家死亡优先 `battle_defeat`；玩家存活且当前波敌人清空才 cleared/推进/胜利。病态双方同时为空也按 defeat，禁止双终局。
- 终局事件全场至多一条；终局后 `advance` 返回空事件，不推进 tick/seq，不调用 AI、resolver 或 RNG。
- 换波只替换敌人；玩家 HP/真气/普攻 CD、技能槽 CD/可用态、tick/seq 全部连续保留。
- 波次列表与敌人列表做防御性不可修改副本；波次非空、每波敌人非空/均为 enemy side、全场 actor id 唯一，非法配置构造期 fail-fast。
- 不新增调优数值默认值，不改 YAML/schema/saveVersion/GDD/PROGRESS/probe/路由/旧战斗文件。

## 验收

1. 单波胜利、玩家战败、双波切换的事件顺序和 seq/tick 连续性精确可测。
2. 波间玩家生命/真气/CD/技能槽状态连续；下一波敌人只在 cleared 后出现。
3. 同初态、同 seed、同命令序列得到相等状态/事件/终局。
4. 终局唯一，终局后连续调用零事件、零状态变化、零 resolver 调用。
5. 非法波次、重复 actor id、首态/首波不一致等输入明确 fail-fast。
6. Phase0a 全套、damage calculator 回归、probe 8 项、根 analyze 与 diff-check 全绿。

## 切片

1. [x] 主窗口审计旧 `BattleResolutionService` 与 Phase0a session/reducer，冻结副作用边界和事件顺序。
2. [ ] Kimi 独立 worktree：计划 → 红测 → 最小状态机 → 验证 → `[READY]`。
3. [ ] 主窗口独立复核终局唯一性、换波状态连续性和回放确定性。
4. [ ] 合入协调分支，复验并冻结 `[READY]`。

## 当前恢复点

- 状态：派单冻结中。
- 最后完成：第三批 `[READY] 8d86fd3e`；确认 `BattleResolutionService.resolve` 会修改成长/掉落/伤势，故只作为未来终局事件下游，不进入本批状态机。
- 下一步：提交派单并创建 Kimi 独立 worktree。
- 已跑验证：新协调 worktree 已完成根 `pub get`、build_runner 与 nested probe `pub get`，worktree 干净。
- 阻塞项：无。

