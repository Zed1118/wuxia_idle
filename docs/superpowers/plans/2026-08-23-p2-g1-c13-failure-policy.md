# P2-G1-C13 FailurePolicyResolver 纯合同候选

## 元数据

- taskId：`P2-G1-C13`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-c13-failure-policy`
- base：`29f04073`（G1 Batch1 READY，与 P2-G1-BATCH2-INTEGRATION 同基）
- 来源：二阶段优化方案 §17.7 主线连续流程与失败策略 / §20.1 任务清单 C13

## 目标

以纯 Dart typed 合同冻结失败策略核心：`FailurePolicyResolver(contentKind,
participantId, sessionId, failureReason, performanceSnapshot)` 经注入规则表
决议 injury / disorder / partialReward / noPenalty 四分支；缺失规则 fail
closed；挑战 session 用 `sessionId + participantId + contentKind` 幂等索赔键
保证多次重试只结一次伤势，失败应用不记账、批量应用记账原子。

## 本切片（文件白名单，仅此五个）

- `lib/shared/battle_shared/failure_policy.dart`
- `lib/shared/battle_shared/failure_policy_resolver.dart`
- `test/shared/battle_shared/failure_policy_test.dart`
- `test/shared/battle_shared/failure_policy_resolver_test.dart`
- `docs/superpowers/plans/2026-08-23-p2-g1-c13-failure-policy.md`

## 合同设计

### 类型（failure_policy.dart）

- `FailureContentKind`：mainline / tower / innerDemon / expedition / gauntlet /
  lightFoot / massBattle（与 `StageType` 独立：远征/断魂庄无 StageType 仍可被覆盖）。
- `FailureReason`：defeat / surrender（主动退出）/ timeout（限时超时）/ aborted（中断恢复结算）。
- `FailureResolution`：injury / disorder / partialReward / noPenalty 四分支（§17.7）。
- `FailurePerformanceSnapshot`：剩余生命比例、承受重击/不可阻挡次数、倒地/被破势次数、
  主动退出标记、内容危险档；构造期强校验（比例须有限且 ∈ [0,1]、计数 ≥0、危险档 ≥1）。
- `FailureClaimKey`：`sessionId|participantId|contentKind` 三元组——确定性（trim
  规范化）、非空且禁止分隔符注入（非法即抛 `InvalidFailureClaimKeyError`）、作用域不含
  failureReason（重试换原因仍是同一次索赔）；值相等性 + hashCode。
- 错误族：`FailurePolicyException` 基类 → `MissingFailurePolicyRuleError` /
  `InvalidFailureClaimKeyError` / `FailureClaimConflictError`，诊断均英文。

### 解析与记账（failure_policy_resolver.dart）

- `FailurePolicyResolver`（无状态）：`resolve(...)` 按 `(contentKind, failureReason)`
  查注入规则表 → `FailurePolicyVerdict{resolution, claimKey}`；规则缺失抛
  `MissingFailurePolicyRuleError` fail closed，不静默猜测。
- `FailureClaimLedger`（内存态，无持久化）：`applySingle` 效果成功后才记账、失败
  不记账；`applyBatch` 先全量预校验（批内无重复键、无已结算键）再逐个执行效果，
  任一效果失败 → 全部键不记账（索赔记账原子性；效果目标的事务性由调用方
  outbox/事务负责，§17.7）。

## 边界（本切片不做）

- **无 injury 权重**：解析只依赖规则表，`performanceSnapshot` 仅校验透传；
  具体权重在 M0/M2 模拟中定标（§17.7）。
- **无 MainlineRun 参与者 / 换装 / 中断策略**：`leaderId + loadoutSnapshotId`
  锁定、连续关卡间换装、伤势中断推进均为 G0 PROPOSED，不拍板、不实现。
- **不接生产路径**：SettlementPipeline / 挑战 session 接线属后续批；
  规则表内容（哪个 contentKind×failureReason 映射到哪个决议）由主审/应用层在
  接线批提供，本合同只冻结解析与幂等语义。
- **无持久化 / schema 变更**：台账纯内存；不改 model / Isar / yaml / UI。

## 验证

- `dart format lib/shared/battle_shared/failure_policy.dart lib/shared/battle_shared/failure_policy_resolver.dart test/shared/battle_shared/failure_policy_test.dart test/shared/battle_shared/failure_policy_resolver_test.dart`
- `flutter analyze lib/shared/battle_shared/failure_policy.dart lib/shared/battle_shared/failure_policy_resolver.dart test/shared/battle_shared/failure_policy_test.dart test/shared/battle_shared/failure_policy_resolver_test.dart`
- `flutter test --no-pub test/shared/battle_shared/failure_policy_test.dart test/shared/battle_shared/failure_policy_resolver_test.dart`
- 测试覆盖：分支解析（五分支四决议）、缺失规则 fail closed（含空规则表）、
  键确定性/非空/隔离（session/participant/kind 三轴）、同键重复拒绝、
  失败应用不记账 + 回滚重试、批量成功全记账、批量失败原子性、批内重复/
  已结算键效果前拒绝、快照不参与解析（无权重钉界）。

## 恢复点与风险

- 状态：候选已由 Codex 主审修正，待冻结 READY。主审修复了 claim key 枚举插值、
  分隔符碰撞，并补齐非有限生命比例校验。
- 已跑验证：targeted tests 20/20、targeted analyze 0 issue、`git diff --check` 通过。
- 下一步：与 C12/C14/C16/C11 联合 targeted、全仓 analyze、diff-check、外部交叉复核。
- 风险：台账记账原子性 ≠ 效果目标事务性（后者归调用方 outbox）；接线批须在
  同一事务或 outbox 中消费 `FailureEffect`，否则崩溃恢复仍可能双写副作用。
