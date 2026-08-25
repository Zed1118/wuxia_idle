# Phase 2 M5 守城自动准入结果合同

- 单一目标：守城已首通关通过 typed request 进入真实 bot/headless/差遣 runner，保留阵型、实际参与者与共享结算。
- 固定验收门：`0/1 → 1/1`；typed admission、生产 runner、阵型输入与 settlement 必须同链成立。
- 基线：生产只有逐次选人后调用共享 `runStageFlow` 的 realtime 手动路径；守城 feature 没有 typed request 或自动 runner。
- 阻塞：真实 runner 不存在，不得新增孤立 policy 或第二执行内核。
- 成本：90 分钟停止线；只读 owner 审计与守城域回归。
- 非目标：schema/saveVersion、YAML、TUNING、奖励、经济、解锁、叙事、战斗规则或 main。

## 结果

- 验收门保持 `0/1 BLOCKED`。
- 守城域 `13/13 PASS`，只证明现有进度、阵型、逐次选人与手动 stage seam 未回归。
