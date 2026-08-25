# P2-M6-U09-REWARD-LAYERS-PRODUCTION-WIRING 结果合同

- 唯一目标：让首通解锁、重复产出、个人成长三层奖励在生产路径消费同一可持久 claim 合同，宗门共享与个人 scope 不串扰，崩溃恢复不重复也不丢失。
- 固定验收门：`0/1 → 1/1`，分母为“一个跨模式 durable reward receipt/outbox 边界”。
- 实时基线：`RewardPolicy` / `RewardClaimKey` / `RewardGrantGuard` 纯合同已存在，但 guard 仅内存；生产消费方为 0。主线另有专用 durable settlement journal，塔与其他模式使用彼此不同的进度或 run 生命周期。
- 当前关键阻塞：未授权 schema/saveVersion 或共享真相源调整，无法在崩溃窗口下为三层奖励建立统一 durable claim。
- 成本上限：30 分钟只读 owner/崩溃窗审计；一旦证明需要 schema 或共享真相源，立即 `BLOCKED`，不写兼容性假实现。
- 非目标：奖励数量/概率、经济、解锁阈值、TUNING/candidate、新货币、手动奖励倍率、main 修改。

## 停线结果

`0/1` 无变化，状态 `BLOCKED`。解锁条件只有二选一：

1. 授权新增版本化 durable `RewardClaimReceipt` / outbox collection 与迁移；或
2. 明确批准把同一 canonical `RewardClaimKey` 及 effect ledger 扩展到每个现有模式 journal，并对跨模式共享/个人 scope 给出单一 owner。
