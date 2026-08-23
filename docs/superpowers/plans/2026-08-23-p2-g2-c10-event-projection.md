# P2-G2-C10 事件顺序只读生产投影

## 边界

本片只把已经生成的 `Phase0aEvent` 快照投影为 `CombatEventRecord`。适配器
严格消费 `seq`、`tick` 与事件自身 payload，生成稳定 canonical event ID；不
回查 arena state、不重算伤害、不接触 reducer、sequencer 或 VFX 输出。

当前所有 `Phase0aEvent` 子类均采用显式穷举映射。输入必须按严格递增 `seq`
到达，重复或乱序输入 fail closed；返回列表和事件输入均不被修改。终局事件
作为只读表现 feed 投影，其余事件保留领域阶段且不携带 feed 字段。

## 验证

- 适配器 targeted test：稳定 canonical ID、同拍阶段、重复/乱序拒绝、输入不可变。
- `flutter analyze` 适配器与测试文件。
- 不修改 `CombatEventRecord`、reducer、sequencer、VFX 或 SFX。
