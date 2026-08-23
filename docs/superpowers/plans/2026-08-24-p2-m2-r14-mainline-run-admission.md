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

- [ ] realtime replay（human / playerBot）保留 requested eligible participant。
- [ ] headless replay、first clear、sweep 恒使用 caller 提供的 current leader。
- [ ] policy rejection 原样传播；即使 run 参数同时无效，也先由 policy 拒绝。
- [ ] runId、stageId、不透明 loadoutSnapshotId 原样交给 `MainlineRun.begin`，参与者只取
      `selection.participantId`，实际 owner 一致。
- [ ] 重复成功调用产生 fresh admission/selection/run，同时保留同一个 request。
- [ ] policy 或 run validation 失败时不返回半成品 admission。
- [ ] source guard 证明仅依赖三个既有合同，无 fallback、重复校验、查询、host/save/UI/
      persistence/data/tuning/双 preset 或生产接线。
- [ ] 新测试及 participation policy、mainline run、activity request、current leader
      去重 targeted 全绿；scoped analyze 0 issue；format/diff/path/status 通过。
- [ ] 红线影响：不修改玩法数值、三系、在线/离线、反主流系统或玩家文案；Dart
      不新增 production 数值/文案。
- [ ] 生产接线证据诚实：本切片只交付 application admission seam；真实 host 消费、
      save/persistence 与 eligibility/occupancy 查询仍是后续显式 Gate。

## 任务切片

1. 读取 CLAUDE 红线/§8/§11、已否清单和 request/policy/run/current-leader 合同，提交本计划恢复点。
2. 新增目标 API 测试并确认因文件/API 缺失红灯。
3. 实现单一薄组合入口，运行新测试转绿并提交代码测试切片。
4. 运行去重 targeted、scoped analyze、format/diff/path/status，更新验证恢复点。
5. 追加空 READY 提交：`[READY][CODEX][P2-M2-R14] 组合主线运行准入合同`。

## 当前恢复点

- 状态：计划与 API 已冻结，尚未写测试或实现。
- 最后完成：确认工作树干净、HEAD 精确为 `7bc31c5f`；完整读取相关红线、已否清单、
  `ActivityParticipationRequest`、`MainlineParticipationPolicy`、`MainlineRun`、
  `CurrentLeaderResolver` 及其聚焦测试。
- 下一步：提交本恢复点，新增红测并运行定向测试确认有效红灯。
- 已跑验证：`git status` clean；三个 owned files 起始均不存在。
- 阻塞项：无。
- 残留 Gate：production host/save/persistence、occupancy/eligibility/伤势查询、
  current-leader 解析及 dual preset 均不在 R14 实现范围。
