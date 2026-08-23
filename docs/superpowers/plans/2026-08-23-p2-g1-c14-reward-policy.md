# P2-G1-C14：纯领域 RewardPolicy / claim key 候选

## 元数据

- taskId：`P2-G1-C14-REWARD-POLICY`
- branch：`codex/phase2-g1-c14-reward-policy-20260823`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-c14-reward-policy`
- base：`29f04073`（会话开局 tip）

## 目标

提供与生产奖励表/数额/存档/UI 完全解耦的纯领域候选件，供后续生产接线批消费：

1. `RewardClaimKey`（`lib/shared/battle_shared/reward_claim_key.dart`）：
   - 两种 key 形态：`battleSessionId + stageId + rewardGrantId`、`runId + rewardChoiceId`；
   - 确定性 canonical 串为唯一身份源（`==`/`hashCode` 均由 canonical 派生）；
   - 全组件非空/非空白校验、禁止分隔符注入；
   - 版本化（`v1|...`），`parse` 对外部版本/畸形串/未知 kind/组件数不符一律 `FormatException` fail closed。
2. `RewardPolicy`（`lib/shared/battle_shared/reward_policy.dart`）：
   - 三层奖励 `RewardLayer { firstClear, repeat, personalGrowth }`；
   - `RewardScope { personal, sectShared }` 表达个人与宗门共享；
   - layer→scope 表由调用方注入（生产预期读 yaml），部分覆盖直接 `ArgumentError`，域内不硬编码任何玩法奖励数值或模式表。
3. `RewardGrantGuard`（同文件）纯内存 grant guard：
   - 重复 key 在回调执行前拒绝（`RewardAlreadyClaimedException`）；
   - 回调抛错不标记 claimed（回滚语义，可重试）；成功返回后才 claim；
   - `claimBatch` 先全量校验（含批内重复）再执行全部回调、最后统一提交，失败批零部分 claim ledger；奖励副作用的事务/Outbox 原子性仍由后续生产接线层负责；
   - scope 隔离由调用方按实例拆分（宗门共享一份、个人每角色一份），域内不假设。

## 硬边界

- 只新增/修改五个白名单文件：两个 `lib/`、两个 `test/`、本计划文件；
- 不碰生产奖励表/数额、存档 schema、saveVersion、UI、yaml；
- 不接线任何生产消费方（接线属后续批，需主审拍板）；
- 外部执行端不 commit、不 push；由 Codex 主审修正并冻结 READY 候选。

## 验收标准

- key 稳定性：同输入 canonical 恒定、`==`/hash 一致、parse 往返；
- key 隔离：session/stage/grant、run/choice 任一维度不同即不相等，两形态互不碰撞；
- 非空与格式校验：空/空白组件、含分隔符组件、畸形/异版本 canonical 全部拒绝；
- 重复拒绝：二次 claim 同 key 抛错且不执行回调；
- 失败回滚：回调抛错后 key 未 claimed，重试成功；
- 批量 claim 原子性：成功批全提交；含抛错回调或重复 key 的批全部不 claim，且重复批在回调执行前即拒绝。回调已发生的外部副作用不由此纯内存守卫回滚，必须在生产事务/Outbox 内执行。

## 验证计划

- `flutter test --no-pub test/shared/battle_shared/reward_claim_key_test.dart test/shared/battle_shared/reward_policy_test.dart`（逐文件确认 All tests passed）；
- `flutter analyze lib/shared/battle_shared/reward_claim_key.dart lib/shared/battle_shared/reward_policy.dart test/shared/battle_shared/`。

## 当前恢复点

- 状态：候选件已由 Codex 主审比对二阶段方案并修正，待冻结 READY。
- 主审修正：`parse` 的畸形组件统一转为 `FormatException`；文档明确纯内存守卫只保证 claim ledger 原子性，奖励副作用仍需生产事务/Outbox。
- 已跑验证：targeted tests 25/25、targeted analyze 0 issue、`git diff --check` 通过。
- 后续：生产奖励表、数额、持久化 schema 与事务接线另批处理。
