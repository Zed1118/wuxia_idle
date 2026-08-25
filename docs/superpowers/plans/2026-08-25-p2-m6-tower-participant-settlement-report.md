# P2-M6 塔实际参与者结算报告

## 结果合同

- 唯一目标：在既有“江湖地图 → 九霄塔 → 逐次选人 → `Phase0aTowerBattleHost` → `applyTowerCombatResolution`”生产链上，让塔胜利报告明确显示本次 exact participant。
- 固定门：M6 塔“选人—亲战—共享结算—身份报告”必要生产子门 `0/1 → 1/1`；不晋升 M6 或 Phase 2 顶层门。
- 当前基线：塔逐次选人与单角色共享结算已 READY，但 `TowerVictoryContent` 没有消费实际参与者身份；`HeroCameraData` 仅是可选的最高输出高光，不能代替身份报告。
- 预期增量：报告身份从缺失变为由现有 `applyTowerCombatResolution` 的 exact settlement participant 派生并展示；错误/悬空结算不猜测、不回退。
- 成本边界：90 分钟内完成；周用量无可靠读数，只记录可观察耗时与集成返工。

## 范围与不变项

- 只扩展现有塔胜利报告参数和展示，不新建 reducer、session、headless 内核、provider 或结算真相源。
- 不改塔层、周目、排行榜、仪式、奖励、经济、解锁、数值、战斗规则、schema/saveVersion、YAML 或 main。
- `applyTowerCombatResolution` 继续是共享结算所有者；报告只消费其 exact participant 结果。

## 验收

1. RED：`TowerVictoryContent` 给定 exact participant name 时当前缺少身份报告的断言失败。
2. GREEN：生产塔胜利路径将结算中唯一且经 `expectedParticipantId` 校验的角色名传给报告；无有效角色名时不猜测。
3. 定向塔报告/参与者/结算测试、相邻塔生产域、scoped/root app analyze、`git diff --check` 通过。
4. registry、audit、PROGRESS/CLAUDE/GDD 事实同步后，分支 tip 为 `[READY]` 且工作树 clean。

## 停止条件

若身份报告必须修改塔奖励模型、存档/schema、结算服务所有权、战斗规则或新增产品决策，立即保留 clean/WIP 现场并标记 `[BLOCKED]`，不猜测。
