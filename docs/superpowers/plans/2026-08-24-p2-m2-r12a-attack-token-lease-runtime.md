# P2-M2-R12a 攻击令牌租约运行时计划

## 恢复点

- 状态：计划冻结，尚未写实现。
- 基线：Batch13 READY `77c5520e04355e041a5db6b40dde05b169874117`。
- 工作树：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r12a-attack-token-lease-runtime`。
- 分支：`codex/phase2-m2-r12a-attack-token-lease-runtime-20260824`。
- 已完成：复核 `CLAUDE.md` 红线、§8 可恢复任务协议、§11 提交纪律，读取 `attack_token_director.dart`、objective runtime tracker 的 owner-bound CAS 及异常迭代测试、ActionTimeline 纯候选边界。
- 下一步：先补失败测试，再实现纯租约合同并运行定向验证。
- 阻塞：无。

## 目标与边界

本切片只建立攻击令牌租约的不可变领域合同，不接入 combat session、batch gate、ActionTimeline、adapter、reducer、combat events 或 production host。运行时不推断何时 acquire/release；caller 必须显式提交有序 lifecycle mutations。

冻结的最小 API：

- `AttackTokenLeaseId`：显式、值相等、非空的租约身份。
- `AttackTokenLease`：绑定 `id` 与 caller 提供的完整 `AttackTokenRequest`；不重算、不删减 request 事实。
- `AttackTokenLeaseMutation`：密封基类。
- `AcquireAttackTokenLease` / `ReleaseAttackTokenLease`：显式有序 mutation。
- `AttackTokenLeaseSnapshot`：`revision` 与只读 `activeLeases` map。
- `AttackTokenLeaseRuntime.empty()` / `AttackTokenLeaseRuntime.restore(...)`：创建独立 owner lineage；restore 防御性复制 caller map。
- `AttackTokenLeasePreparedSuccessor prepare(Iterable<AttackTokenLeaseMutation>)`：先完整物化 caller iterable，再在局部 map 中按声明顺序验证并生成 `base` / `next` 与只读 `mutations`。
- `AttackTokenLeaseRuntime commit(AttackTokenLeasePreparedSuccessor prepared)`：仅 exact predecessor、同 owner、未消费 prepared 可提交；返回新的 successor runtime，原 runtime 与 snapshot 永不改变。

`commit(prepared)` 的语义是显式不可变分支，不是全局可变 CAS：同一 predecessor 可以分别 prepare 并 commit 不同 prepared 值，得到隔离的 sibling successors。prepared 自身只能成功消费一次；caller 通过不发布某个 successor 完成未来 fork/rollback。该合同不宣称已经完成跨 tick production lifecycle。

## Fail-closed 规则

- active lease ID 重复时拒绝 acquire。
- unknown lease ID 时拒绝 release。
- 同一 actor 同时拥有多个 active leases 时拒绝；先 release 后 acquire 则依声明顺序允许。
- restore map key 与 `lease.id` 冲突时拒绝。
- foreign owner、非 exact predecessor、prepared double commit 均拒绝。
- lazy iterable 物化、mutation 验证任一步骤抛错时不产生 successor，predecessor identity/snapshot 保持不变。
- 不从 actor、intent、role、命中、冷却、败北、位置或缺席推断 mutation；不内置 budget、缺省值或 tuning。

## TDD 验收

1. 初始空 snapshot 与 revision 0。
2. acquire、release、同批 acquire+release 按声明顺序成功，revision 每个成功 successor 增加一次。
3. snapshot map 与 prepared mutation list 均不可改；caller map/iterable 后改不污染内部快照。
4. lazy iterable 中途抛错、duplicate actor/lease、unknown release 均零发布。
5. foreign predecessor、sibling/stale predecessor、double commit fail closed。
6. 失败后原 runtime identity 与 snapshot identity/内容不变；不同 successor/fork 相互隔离。
7. `AttackTokenRequest` 的 kind、priority 与全部 safety facts 原样保留。
8. source guard 只允许依赖 attack-token request 合同，并禁止 production 接线与 lifecycle 推断来源。

## 切片与提交

1. 提交本计划恢复点。
2. 写测试并确认定向测试红灯。
3. 实现最小合同，format，运行定向测试与 scoped analyze。
4. 审查 owned-files-only diff，更新本恢复点与验证证据。
5. 创建空 READY 提交：`[READY][CODEX][P2-M2-R12A] 建立攻击令牌租约合同`。

## Gates

- R12b 才能评估 batch gate/session 接线及 transaction publication 顺序。
- 真实 ActionTimeline consumer/action identity 与完成、取消、中断、失败终态尚未冻结；不得在 R12a 中补写或推断。
- `TUNE-WEAPON-TIMELINE-01` 与相关攻击节奏/数值调优不在本切片范围。
