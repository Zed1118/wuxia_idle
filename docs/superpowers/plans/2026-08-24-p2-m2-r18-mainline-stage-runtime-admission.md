# P2-M2-R18：组合主线单关运行时准入

## 目标与边界

从 Batch16 前置恢复点 `a952274781a11283ff5d7675ad270034a94cfd69`
出发，把 R14 的 exact `MainlineRunAdmission` 与 R15 的 owner-bound
occupancy prepared successor 组合成一个可延迟提交的内存态准入值。
本切片只证明返回值的一次性发布，不声称 durable transaction，
不接 production host、持久化或发放。

- 分支：`codex/phase2-m2-r18-mainline-stage-runtime-admission-20260824`
- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r18-mainline-stage-runtime-admission`
- owned files 严格限定为：
  - `lib/features/mainline/application/mainline_stage_runtime_admission.dart`
  - `test/features/mainline/application/mainline_stage_runtime_admission_test.dart`
  - 本计划文件

## 冻结 API 与发布顺序

- `prepareMainlineStageRuntimeAdmission` 只接显式
  `request/currentLeaderId/requestedIdleEligible/runId/stageId/`
  `loadoutSnapshotId/occupancyPredecessor/mentorChoice/blockingStatus`。
- 顺序固定为：
  1. 拒绝非 `mainline` 或非 `firstClear` request；
  2. 按原始入参字面比较 `mentorChoice.stageId == stageId`，不做
     trim/归一化；
  3. 调用 R14 `admitMainlineRun`，不复制 participation/run 规则；
  4. 调用 R15 `occupancyPredecessor.prepare` 且只声明一条
     `AcquireMentorInsightStageOccupancy`；
  5. 返回持有 exact run admission、exact predecessor 和 exact R15
     prepared successor 的 `MainlineStageRuntimeAdmissionPrepared`。
- prepared 的 `commit(exactPredecessor)` 先校验 predecessor identity，再校验
  R18 自有 single-use flag，最后委托 R15 commit；成功后才置位并
  返回不可变 `MainlineStageRuntimeAdmission`。
- final admission 只持有 exact `runAdmission` 和 occupancy successor runtime。
- empty mentor choice 仍经 R15 prepare/commit，必须保持 snapshot identity 与
  revision；不另建 no-op 规则。
- foreign/stale predecessor 与 double commit fail closed。R15 为不可变分支
  lineage，先 commit sibling 不会让 exact 原 predecessor 失效；本切片不
  冒充全局 CAS。

## 不做

- 不查询或推断 mentee eligibility、participant/mentee 关系、healing
  或四类活动字段；`blockingStatus` 原样透传给 R15。
- 不接 claim/grant/rate/cap/reward/injury/persistence/save/Isar/UI/host/
  repository/data/candidate/tuning/default/fallback。
- 不捕获、包装或降级 R14/R15 异常，不新建第二套
  participant、run 或 occupancy 真相源。
- 调用方仍可绕过 R18 直接使用 R14/R15；本切片不封锁上层
  API，底层 owner/predecessor 安全仍由 R15 保证。

## TDD 验收矩阵

1. `mainline + firstClear + companion` 准备成功；prepared 保留 exact
   run admission/predecessor/R15 successor，commit 后 revision +1 与 exact companion。
2. empty choice 在全 blocked/已占用 predecessor 上仍为 strict no-op，
   snapshot identity 与 revision 不变。
3. 非 mainline 及 replay/sweep/offlineResume 在 R14 前精确拒绝；拒绝时
   零 prepared/final admission，predecessor 不变。
4. choice/stage 字面不等先于 R14 run 参数校验失败；不 trim。
5. R14 participation/run 校验异常原样穿透；R15 四类 blocked 与已占用
   异常原样穿透，predecessor 始终不变。
6. foreign/stale/double commit 拒绝；先提交 sibling 后 exact predecessor
   仍可提交本 prepared。
7. mentee ID 与 participant ID 相同时仍原样通过，证明本层不推断关系。
8. source contract 锁定校验→R14→R15 顺序、无 catch/switch/fallback/
   default，且禁止所有越界依赖与 `blockingStatus` 成员访问。
9. 新测试及 R14/R15 去重 targeted、scoped analyze、format、
   diff/path/status 全绿；最终 Qoder 只读 diff 审查后再 READY。

## Qoder 只读审查证据

- CLI/version：`qoderclicn` 1.1.28；`--list-models` 实测含精确
  `Qwen3.8-Max`。
- 编码前审查：实际使用 `Qwen3.8-Max` +
  `--reasoning-effort high` + `--permission-mode dont_ask` +
  Read/Grep/Glob-only + `--no-session-persistence`；命令边界禁止
  Edit/Write/Bash。
- 结论：`DESIGN PASS`，P0=0。审查要求编码前冻结两项：
  stage ID 原始字面比较；R18 自有 single-use flag。两项已写入
  上述 API/测试矩阵。其建议的 `[READY][CODEX]` 标记与本任务
  用户精确要求冲突，将使用用户指定的 `[READY][QODER]`。
- 最终 diff 审查：待实现与本地验证后追加真实证据。

## 任务切片

1. 恢复环境，运行 Qoder 编码前只读审查，提交计划恢复点。
2. 先补新测试并记录缺失 API 的有效红灯。
3. 实现最小 prepared/final admission，运行受影响 targeted 与静态检查。
4. Qoder 最终只读 diff 审查，收口证据与 READY。

## 当前恢复点

- 状态：设计已冻结，未编码。
- 最后完成：精确基线验证；`flutter pub get --enforce-lockfile`；
  build_runner 126 outputs / 63 `*.g.dart`；`libisar.dylib` SHA-256
  `f22f60782156ff3205c4ef72ff157337640604a8a0c4c416555a2432c764742d`；
  Qoder 编码前审查 `DESIGN PASS`。
- 下一步：先写 `mainline_stage_runtime_admission_test.dart`，运行缺失源文件
  红灯后提交。
- 已跑验证：仅环境恢复与 Qoder 设计审查；尚未跑任务测试。
- 阻塞：无。production/durable/tuning/G2 继续作为明示 Gate。

## READY

最终精确空提交：
`[READY][QODER][P2-M2-R18] 组合主线单关运行时准入`。
