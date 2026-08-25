# Phase 2 M5 轻功自动准入结果合同

- 单一目标：轻功已首通路线通过 typed request 进入真实 bot/headless/差遣 runner，并复用 exact participant、共享 Phase 0A 与结算。
- 固定验收门：`0/1 → 1/1`；typed admission、真实 production runner 与共享 settlement 必须同链成立。
- 基线：生产只有逐次选人后调用 `runStageFlow` 的 realtime 手动路径；`lib/features/light_foot` 没有 typed request 或 bot/headless/dispatch runner。
- 阻塞：真实 runner 不存在；不得写孤立 policy 表或新建执行内核冒充接线。
- 成本：90 分钟停止线；本门只做只读 owner 审计与轻功域回归。
- 非目标：新 reducer/session/headless 内核/provider/settlement 真相源、schema/saveVersion、YAML、TUNING、奖励、经济、解锁、叙事、战斗规则或 main。

## 结果

- 验收门保持 `0/1 BLOCKED`。
- 轻功域 `12/12 PASS`，只证明当前手动逐次选人和三态进度未回归。
