# Phase 0A reducer 首轮返修（Qoder）

## 背景

首轮 `[READY] e59906e0` 的结构与验证总体合格，但派单方独立审查确认两处玩家可见语义缺陷。本单只修下列问题，不扩 UI/公式/结算范围。

## 必修 1：Q/R 显式作用半径

- `Phase0aGatherIntent` 与 `Phase0aClearIntent` 都必须携带无默认值的 `effectRadius`（或同义强类型字段），玩家适配器配置同样显式接收并透传。
- reducer 只对以 caster 位置为圆心、距离 `<= effectRadius` 的存活敌对单位调用 resolver、改变位置/生命、写 outcomes；范围外目标不得出现在 outcomes，不得被拉拢、扣血、失衡或死亡。
- `ringRadius` 仍只决定 Q 目标落点；不得用它冒充作用半径。若 `ringRadius > effectRadius`，构造/结算需有明确、可测的非法参数处置，禁止把目标从作用区内推到作用区外。
- 补边界测试：恰在半径上命中；半径外不入 outcomes；R 仅清理近身敌人；输入适配器透传半径；源码仍无调优默认值。

## 必修 2：同拍刷新全部技能印

- 任一技能成功施放并改变 caster 真气后，必须在同一 reducer tick 重新计算该玩家**全部**技能槽的 availability。
- 施放槽进入 cooldown；其他槽若因剩余真气不足须同拍进入 qi，并立即发 `skill_availability_changed`，不得等下一 tick 才变暗。
- 事件不得重复：每槽本拍只发真实迁移；按技能槽稳定顺序；payload 的 `cooldownRemaining` / `qiCurrent` / `qiRequired` 可直接驱动 HUD。
- 补测试：两个初始 ready 槽，释放低耗槽后余气低于另槽门槛；本拍同时收到施放槽 cooldown + 另槽 qi，最终 state 两槽一致；下一空拍不得重发。

## 守门与冻结

- 保持首单全部禁区与 §8.2 四证据。
- 先补红测并记录红，再最小实现；逐文件 targeted、首片 24、probe 8、根 analyze、diff-check 全绿。
- 更新原计划恢复点，新增中文动宾 commit；最终再以 `[READY]` 冻结且 worktree 干净。
