# Phase 2 U09 奖励三层生产接线 BLOCKED 审计

## 结论

U09 固定验收门保持 `0/1`，状态 `BLOCKED`。阻塞是 schema 与共享真相源授权，不是缺少一个 UI 标签或内存去重容器。本审计没有修改生产代码、schema/saveVersion、YAML、奖励、经济、解锁或 main。

## 证据链

1. 冻结纯合同已有 `RewardLayer { firstClear, repeat, personalGrowth }`、`RewardScope { personal, sectShared }` 与 canonical `RewardClaimKey`。
2. `RewardGrantGuard` 只把 claim 保存在进程内 `Set<String>`；原计划也明文“仅内存态，不代表 durable storage”。进程重启后无法证明已领取。
3. 生产代码没有 `RewardPolicy` / `RewardGrantGuard` 消费方；现有首通和重打奖励由各模式自己的 progress/run 字段门控。
4. 主线已有专用 `MainlineSettlementJournal`，能把核心写入和 effect claim 放在同一 Isar 事务，但它的 identity 和恢复语义只属于主线。
5. 塔的 `TowerProgressService.recordClear` 先在事务内提升 progress，生产 entry 随后在事务外调用 `rollTowerRewards` / `_persistDrops`。两者之间崩溃可以造成“已记首通但奖励未落库”；仅加内存 guard 既不防丢失也不支持恢复。
6. 断魂庄通过单事务发奖+删除 run 实现自身幂等，远征使用 run 暂存账本，其他模式又各自不同。它们不能被假定为一个跨模式共享 claim owner。
7. 当前纯合同回归 `33/33 PASS`，只证明 key/policy/内存 guard 本身稳定，不能替代 durable 生产验收。

## 为什么必须停线

冻结要求是“关键唯一奖励按存档/宗门共享，个人成长归实际参与者，手动/自动/差遣/扫荡不突破首通边界”。若不先选定一个 durable receipt/outbox owner，直接把纯合同接到七套现有字段会制造多个不一致的真相源，并在崩溃窗口丢奖或重复。这正是用户红线中要求停线的 schema/共享真相源耦合。

## 解锁后验收分母

解锁后仍使用同一 `1/1` 门：七类内容的首通/重复/个人成长生产写入必须共用 canonical claim 合同，在 callback 失败、批中失败、重复提交、进程重启和事务中断下均证明零重复/零丢失，并证明共享 scope 不因换角色重领。
