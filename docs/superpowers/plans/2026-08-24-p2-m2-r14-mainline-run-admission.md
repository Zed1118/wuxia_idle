# P2-M2-R14 主线运行准入合同计划

## 目标与边界

在既有 `ActivityParticipationRequest`、`MainlineParticipationPolicy` 与
`MainlineRun` 之上新增一个薄 application seam，把显式参与请求解析为实际参与者，
再以该参与者建立第一关 run。该切片不查询角色占用、伤势、当前掌门或装配内容，
不接 host、save、UI、persistence、production data 或 tuning，也不引入第二套
loadout preset。

- 分支：`codex/phase2-m2-r14-mainline-run-admission-20260824`
- 工作树：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-r14-mainline-run-admission`
- 精确基线：Batch14 READY `7bc31c5f5463aac26e127912576350487ac0a8d3`
- owned files：本计划、`mainline_run_admission.dart` 与对应测试，共 3 文件。
- 禁止修改：registry、audit、main、既有 policy/run/request、production host 与其他文件。

## 冻结 API

- `MainlineRunAdmission`：不可变保存 caller 的 exact
  `ActivityParticipationRequest request`、policy 返回的既有
  `MainlineParticipantSelection selection` 和新建的 `MainlineRun run`；构造器私有，
  避免外部拼出参与者不一致的 admission。
- `admitMainlineRun(...)`：唯一入口，所有参数必填：`request`、
  `currentLeaderId`、`requestedIdleEligible`、`runId`、`stageId`、
  `loadoutSnapshotId`。
- 调用顺序固定为
  `MainlineParticipationPolicy.resolveParticipant(...)` →
  `MainlineRun.begin(participantId: selection.participantId, ...)` →
  `MainlineRunAdmission`。不捕获、不包装、不回退任何异常。
- admission 保留原始 request identity；每次成功调用返回 fresh admission、selection、
  run。实际 run participant 与成长/伤势 owner 继续由既有 selection/run 合同决定。

## 验收标准

- [x] realtime replay（human / playerBot）保留 requested eligible participant。
- [x] headless replay、first clear、sweep 恒使用 caller 提供的 current leader。
- [x] policy rejection 的准确类型与消息向 caller 传播；即使 run 参数同时无效，也先由
      policy 拒绝；source guard 证明 seam 无 catch/wrap/fallback。
- [x] runId、stageId、不透明 loadoutSnapshotId 原样交给 `MainlineRun.begin`，参与者只取
      `selection.participantId`，实际 owner 一致。
- [x] 重复成功调用产生 fresh admission/selection/run，同时保留同一个 request。
- [x] policy 或 run validation 失败时不返回半成品 admission。
- [x] source guard 证明仅依赖三个既有合同，无 fallback、重复校验、查询、host/save/UI/
      persistence/data/tuning/双 preset 或生产接线。
- [x] 新测试及 participation policy、mainline run、activity request、current leader
      去重 targeted 全绿；scoped analyze 0 issue；format/diff/path/status 通过。
- [x] 红线影响：不修改玩法数值、三系、在线/离线、反主流系统或玩家文案；Dart
      不新增 production 数值/文案。
- [x] 生产接线证据诚实：本切片只交付 application admission seam；真实 host 消费、
      save/persistence 与 eligibility/occupancy 查询仍是后续显式 Gate。

## 任务切片

1. 读取 CLAUDE 红线/§8/§11、已否清单和 request/policy/run/current-leader 合同，提交本计划恢复点。
2. 新增目标 API 测试并确认因文件/API 缺失红灯。
3. 实现单一薄组合入口，运行新测试转绿并提交代码测试切片。
4. 运行去重 targeted、scoped analyze、format/diff/path/status，更新验证恢复点。
5. 追加空 READY 提交：`[READY][CODEX][P2-M2-R14] 组合主线运行准入合同`。

## 当前恢复点

- 状态：实现、初始证据/READY、独立复审 P2 修正与修正后复跑均完成；旧 READY 已由
  后续修正取代，本记录后以同文本新 READY 重新冻结。
- 最后完成：计划 `2f68253c`、实现/测试 `387b44cc`、初始证据 `c3dbae25` 与旧 READY
  `e5b7a0c3` 已完成。独立复审指出 canonical const 的跨调用 identity 断言不能证明本次
  异常实例传播，已以 `0262adaf` 删除该假证明，改为单次 admission 调用的准确 typed
  message 与零 admission 断言；生产 API 未改。唯一入口仍严格执行 policy → run →
  admission，source guard 证明无 catch/wrap/fallback。修正证据已提交为 `99bddf74`。
- 下一步：追加同文本新 READY 空提交并交还主控；无其他代码或证据修改。
- 已跑验证：修正后新测试 9/9、五文件去重 targeted 54/54 PASS（新准入 9、
  participation policy 18、
  mainline run 18、activity request 5、current leader 4）；scoped analyze 2 files
  `No issues found`；Dart format 2 files 0 changed；`git diff --check` 与严格三文件
  白名单通过。
- 阻塞项：无。
- 残留 Gate：production host/save/persistence、occupancy/eligibility/伤势查询、
  current-leader 解析及 dual preset 均不在 R14 实现范围。
