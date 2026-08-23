# P2-M2-R19：主线单关听剑释放边界

## 目标与边界

从 Batch17 登记 tip `88e1413486889a0b98d027bd56f56b7ba51cbc5d`
出发，扩展 R18 admission provenance，并把 caller 明示提供的
R02 四种 release reason 组合成 R15 owner-bound prepared successor。
本任务只交付 host-neutral 的内存态释放值，不声称 durable
transaction，不接 settlement/result/claim/reward/host/persistence/data/
candidate/tuning。

- 分支：`codex/phase2-m2-r19-mainline-stage-runtime-release-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r19-mainline-stage-runtime-release`
- owned files 仅：
  - `lib/features/mainline/application/mainline_stage_runtime_admission.dart`
  - `test/features/mainline/application/mainline_stage_runtime_release_test.dart`
  - 本计划文件

## 冻结合同

- `MainlineStageRuntimeAdmissionPrepared` 和
  `MainlineStageRuntimeAdmission` 新增 nullable `admittedCompanion`。
  非空 choice 只取本次 R15 `next.companion` 的 exact object；empty
  choice 恒为 null，即使 predecessor 已有 occupancy。
- `prepareMainlineStageRuntimeRelease` 只接 exact admission 与 caller 明示
  `MentorInsightReleaseReason`。null provenance 必须委托 R15
  `occupancyRuntime.prepare(const [])`；非空 provenance 先精确校验
  admission occupancy active stage/character，再声明唯一一条
  `ReleaseMentorInsightStageOccupancy`。
- release prepared 公开 exact admission/reason/predecessor/base/next/
  read-only mutations，但 R15 committable successor 必须 library-private。
  `commit(exactPredecessor)` 仅成功一次，foreign/stale/double 拒绝；
  sibling 不冒充全局 CAS。
- R15/R18 异常不捕获、不包装、不降级。不从 settlement/
  result/exit 推断 reason，不扩 claim/grant/reward/host/persistence/
  repository/data/candidate/tuning/default/fallback。

## 验收 checklist（CLAUDE §8.2）

- [ ] Pi CLI 0.84.1 + exact `deepseek/deepseek-v4-flash` + thinking high
  完成实现前设计与最终 diff 两轮只读审查，仅启用
  `read,grep,find,ls`。
- [ ] TDD 红→绿覆盖 provenance（含 empty+occupied）、四 reason、
  empty no-op、stage/character mismatch 零发布、foreign/stale/
  double/sibling predecessor、private successor/read-only views、异常传播与
  source guard。
- [ ] 生产接线如实标为未接；只交付 R18→R15 可组合释放
  seam，不冒充 host 或 durable transaction。
- [ ] targeted、scoped analyze、format、diff-check、owned path/status
  和 Codex 独立自审通过。
- [ ] 红线：0 tuning/YAML/玩家文案/数值/三系/在线离线/
  反主流/reward/save/UI 变更；不跑 full suite。
- [ ] 中文动宾小提交完成，最后追加精确 READY 空提交。

## 任务切片

1. 复读 CLAUDE/AGENTS、Batch17 plan/audit/registry、R15/R18
   source/test/plan，完成 Pi 实现前只读审查。
2. 新建 R19 专用测试，跑出缺失 API 的有效红灯并提交。
3. 最小扩展 R18 source，跑新测试及 R15/R18 影响回归。
4. 运行 scoped analyze/format/diff/path/status，Pi 最终 diff 只读
   审查，triage 后收口证据与 READY。

## 当前恢复点

- 状态：已完成边界复读与计划初稿，待 Pi 实现前只读审查。
- 最后完成：核对 R15/R18 的 exact predecessor、single-use、
  sibling 和 private successor 体例；确认 empty+occupied 不能从
  occupancy snapshot 反推 provenance。
- 下一步：运行指定 Pi 设计审查，再先写测试。
- 已跑验证：尚未跑测试。
- 阻塞项：无。
- 生产接线：未接；host/persistence/claim/reward/settlement
  identity 继续 Gate。
