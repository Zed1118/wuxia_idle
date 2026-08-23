# P2 M2 R23：主线下一关运行时准入

## 目标

从 Batch17 READY `87ee8921` 出发，组合 R19 已提交的显式释放、R01
`MainlineRun.proceedToNext` 与 R15 单关听剑占用，建立一个新文件内的
host-neutral 下一关 prepared/commit 边界。不接 production host、不实现
durable coordinator/reward/settlement identity，不冒充下一关 R19 release 已组合。

## 冻结 API

```dart
MainlineNextStageRuntimeAdmissionPrepared
prepareNextMainlineStageRuntimeAdmission({
  required MainlineStageRuntimeRelease previousRelease,
  required String nextStageId,
  required String loadoutSnapshotId,
  required bool participantBattleEligibleForNextStage,
  required MentorInsightChoice mentorChoice,
  required MentorInsightBlockingStatus blockingStatus,
});
```

prepared 仅公开 exact `previousRelease`、`run`、`occupancyPredecessor`、nullable
`admittedCompanion` 及 R15 的 read-only base/next/mutations；committable successor 必须
private。`commit(exactPredecessor)` 成功后返回新的 final
`MainlineNextStageRuntimeAdmission`，不穿透 R18/R19 的 library-private 构造器。

## 顺序与不变量

1. 先要求 `mentorChoice.stageId == nextStageId`，失配抛
   `ArgumentError` (`name: mentorChoice.stageId`)，不 trim 或推断邻接关。
2. 只调用一次
   `previousRelease.admission.runAdmission.run.proceedToNext(...)`；保持 runId / participant，
   快照版本 +1，不重建 run 或 participant。
3. 推进成功后才从 `previousRelease.occupancyRuntime` 以恰好一条
   `AcquireMentorInsightStageOccupancy` 准备 successor；R01/R15 异常原样透传。
4. `admittedCompanion` 只能是本次 choice 非空时的
   `occupancyNext.companion` exact object；empty choice 恒为 null，不读旧 admission
   provenance 或 release reason。
5. commit 先验 `identical(exactPredecessor, occupancyPredecessor)`，再验 single-use；
   foreign/stale/double commit 均不消费合法提交机会。sibling prepared 可各自从
   immutable exact predecessor 提交，不冒充全局 CAS。
6. 任一 prepare 失败均不发布 run 或 occupancy successor；输入对象不变。

## Qoder 设计审查

- CLI/version：`qoderclicn` 1.1.28；`--list-models` 实测含精确
  `Qwen3.8-Max`。
- 实际使用 `-m Qwen3.8-Max --reasoning-effort high
  --permission-mode dont_ask --tools Read Grep Glob --no-session-persistence`，
  未授权 Bash/Edit/Write。审查完整读取 R19/R01/R15 及测试，结论
  `DESIGN PASS`，P0=0/P1=5/P2=5。P1 全部已在上述 API、顺序、私有
  successor、provenance 与 commit 不变量中关闭；P2 转为参数透传、
  source guard 与回归验证。Qoder 精确模型证据仅来自 CLI selector 与
  model catalog，不伪造底层模型自证。

## TDD 与验收

- 先以新测试证明 source/API 缺失，再实现最小组合。
- 覆盖带 companion / empty choice / 旧 occupancy、不可战、stage 失配、
  空快照 ID、R15 blocked/conflict、foreign/stale/double/sibling commit、输入不变与
  source guard。
- targeted：R23 + R19 + R01 + R15；scoped analyze 只分析新 lib/test 两文件。
- format、`git diff --check`、baseline path audit 与 clean status 必须通过；不跑 full。
- 最终使用同一 Qoder selector/permissions 做独立只读 diff 审查；无阻断后
  追加精确空 READY marker。

## 当前恢复点

- 状态：设计审查已 PASS，进入 TDD 红测。
- 基线：`1d64c04c78a729074fc387db64375cecd3704dfd`。
- Gate：production host、下一关 release 组合、durable run/coordinator、
  settlement/reward/claim、shared occupancy、data/candidate/tuning/Profile/G2 继续未解。
