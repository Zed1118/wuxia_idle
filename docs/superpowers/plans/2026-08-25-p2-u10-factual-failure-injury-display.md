# P2-M6-U10-FACTUAL-FAILURE-INJURY-DISPLAY 结果合同

- 唯一目标：七类内容的失败/返程界面只展示本次事实、实际参与者和本次新增伤势，不给配装、战术或消耗品建议。
- 固定验收门：`4/7 → 7/7`，分母为 mainline、tower、innerDemon、expedition、gauntlet、lightFoot、massBattle。
- 基线：主线 Boss、心魔、断魂庄、远征已有事实摘要；塔败北落账后静默返回，轻功/守城/普通主线放弃重试后不显示新增伤势；重试框仍有建议型文案。
- 预期增量：共享 stage flow 一次覆盖 mainline/lightFoot/massBattle，塔补独立事实弹层，因而关闭 3 个缺口。
- fail closed：结算参与者不匹配、角色消失或伤势 before/after 不可比时不猜测。
- 成本上限：90 分钟无分母变化停线；主成本读数为墙钟，只跑定向+相邻失败/伤势域和 scoped analyze。
- 非目标：FailurePolicy 权重、伤势数值、奖励/经济/解锁、TUNING、schema/saveVersion、YAML、统一完成报告、main。
