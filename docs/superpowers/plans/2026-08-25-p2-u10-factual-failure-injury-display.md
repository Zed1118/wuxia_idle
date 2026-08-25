# P2-M6-U10-FACTUAL-FAILURE-INJURY-DISPLAY 结果合同

- 唯一目标：七类内容的失败/返程界面只展示本次事实、实际参与者和本次新增伤势，不给配装、战术或消耗品建议。
- 固定验收门：`4/7 → 7/7`，分母为 mainline、tower、innerDemon、expedition、gauntlet、lightFoot、massBattle。
- 基线：主线 Boss、心魔、断魂庄、远征已有事实摘要；塔败北落账后静默返回，轻功/守城/普通主线放弃重试后不显示新增伤势；重试框仍有建议型文案。
- 预期增量：共享 stage flow 一次覆盖 mainline/lightFoot/massBattle，塔补独立事实弹层，因而关闭 3 个缺口。
- fail closed：结算参与者不匹配、角色消失或伤势 before/after 不可比时不猜测。
- 成本上限：90 分钟无分母变化停线；主成本读数为墙钟，只跑定向+相邻失败/伤势域和 scoped analyze。
- 非目标：FailurePolicy 权重、伤势数值、奖励/经济/解锁、TUNING、schema/saveVersion、YAML、统一完成报告、main。

## 收口结果

- 固定验收门已由 `4/7` 提升为 `7/7`。
- 共享 stage flow 在放弃重试后只展示 exact participant 与 before/after 差分得到的本次新增轻/重伤，入场前既有伤势不冒充本次后果；主线、轻功、守城同时受益。
- 九霄塔败北落共享战斗账本后展示实际参与者与本次新增伤势；心魔、断魂庄、远征保留既有独立事实摘要。
- 重试框的“换装备/先历练”建议型诊断文案已从生产与测试源删除，不新增配装或战术建议。
- 验证：首轮 RED `0/4`，定向 `24/24`，主线+塔展示域 `213/213`，七内容失败/伤势域 `551/551`，`flutter analyze --no-pub lib test` 0 issue。
