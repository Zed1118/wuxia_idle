# Phase 2 M5 九霄塔自动准入结果合同

- 单一目标：九霄塔已首通层以 typed `ActivityParticipationRequest` 进入真实 production headless runner，并继续复用既有参与者快照、Phase 0A 内核与塔结算 owner。
- 固定验收门：`0/1 → 1/1`；policy、admission、真实 runner、结算与报告必须在同一生产路径成立。
- 实时基线：塔只有 `Phase0aTowerBattleHost` 的 visible realtime 手动路径；headless 仅由 `phase0a_tower_wiring_test.dart` 直接组装通用 runner，没有塔 production headless runner/admission。
- 当前关键阻塞：用户明确要求真实 production runner 不存在时 clean BLOCKED；不得把测试中的 `Phase0aHeadlessRunner` 组装复制成孤立 policy 表或第二套执行端。
- 成本上限：90 分钟无分母变化停线；主成本读数为墙钟，审计只运行塔域与源码消费者核对。
- 非目标：新 reducer/session/headless 内核/provider/settlement 真相源、schema/saveVersion、YAML、TUNING、奖励、经济、解锁、叙事、战斗规则或 main。

## 审计结果

- 固定验收门保持 `0/1`，状态 `BLOCKED`。
- 塔域 `117/117 PASS`，证明既有手动 Host、参与者、进度、结算与 UI 未回归，不证明自动生产路径存在。
- 解阻条件：先授权并实现一个由生产入口消费、复用既有 mapper/assembler/`Phase0aHeadlessRunner` 的塔 runner owner；之后才能在其前方增加首通门槛与 typed admission。
