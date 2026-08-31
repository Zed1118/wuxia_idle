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

## 2026-08-31 授权与实施结果

用户已选择第一条路线并明确授权加法 Isar collection、`schemaVersion` / `saveVersion` 提升、canonical `RewardClaimKey` 扩展，以及七类既有奖励写入与 receipt 的同事务合并。实现遵守以下边界：

- `saveVersion` 加法提升至 `0.42.0`，新增唯一索引 `RewardClaimReceipt.claimKey`；
- mainline、tower、light-foot、mass-battle、inner-demon、gauntlet、expedition 共用 v2 content-layer key；
- 首通为宗门共享，心魔首通按实际参战者个人隔离；重复产出和个人成长按实际参战者隔离；
- 奖励 effect 与全部 claim receipt 同事务提交或回滚；重复 canonical key 在 effect 前 fail closed；
- 旧档仅从主线/轻功/守城的已通关关卡、塔已通楼层/周目、断魂庄已通副本建立首通墓碑；心魔缺实际领取者、百草岭缺 durable run identity，均不猜测建墓碑；
- 迁移不补发、不伪造奖励，也未修改奖励金额、概率、经济、解锁、玩家数值、技能或战斗规则。

固定验收门由 `0/1` 推进到工程候选 `1/1`。最终关闭仍要求精确恢复后的定向回归、整仓 format/analyze/full suite、测试契约迁移 Gate 与总 Gate 全部通过；这不代表 M6 或 Phase 2 已完成，真人目检继续挂账。
