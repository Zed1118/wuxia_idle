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
  派生机制钉死为 `mentorChoice.hasCompanion ?
  occupancyPreparedSuccessor.next.companion : null`；非空 choice 只取
  本次 R15 `next.companion` 的 exact object，empty choice 恒为 null，
  即使 predecessor 已有 occupancy。final admission 从 prepared 原样
  携带，不从 successor snapshot 反推。
- `prepareMainlineStageRuntimeRelease` 签名只接已 commit 的 final
  `MainlineStageRuntimeAdmission` 与 caller 明示
  `MentorInsightReleaseReason`；prepared admission 在类型上不可传入。
  release predecessor 恒为 `admission.occupancyRuntime`。null provenance
  必须委托 R15
  `occupancyRuntime.prepare(const [])`；非空 provenance 先精确校验
  admission occupancy active stage/character，再声明唯一一条
  `ReleaseMentorInsightStageOccupancy`。
- release prepared 公开 exact admission/reason/predecessor/base/next/
  read-only mutations，但 R15 committable successor 必须 library-private。
  `commit(exactPredecessor)` 仅成功一次，foreign/stale/double 拒绝；
  sibling 不冒充全局 CAS。成功回返
  `MainlineStageRuntimeRelease`，持有 exact admission/caller reason 与释放后
  occupancy runtime。
- null provenance 的 no-op prepared 仍记录并只读暴露 caller reason，
  但不声明 Release mutation，不报错也不推断其他事实。
- R15/R18 异常不捕获、不包装、不降级。不从 settlement/
  result/exit 推断 reason，不扩 claim/grant/reward/host/persistence/
  repository/data/candidate/tuning/default/fallback。

## 验收 checklist（CLAUDE §8.2）

- [x] Pi CLI 0.84.1 + exact `deepseek/deepseek-v4-flash` + thinking high
  完成实现前设计与最终 diff 两轮只读审查，仅启用
  `read,grep,find,ls`。
- [x] TDD 红→绿覆盖 provenance（含 empty+occupied）、四 reason、
  empty no-op、stage/character mismatch 零发布、foreign/stale/
  double/sibling predecessor、private successor/read-only views、异常传播与
  source guard。
- [x] provenance identity 显式断言：非空 prepared 与
  `occupancyNext.companion` 同一对象，commit 后 final 与 successor
  snapshot companion 同一对象；empty+occupied 的 final provenance 为
  null 而旧 companion/snapshot identity/revision 全保留。
- [x] release 行为矩阵：四 reason 逐项保留 exact reason/companion；
  非空 release 仅 revision +1 并置空；no-op 保持 snapshot identity；
  mutations 不可改；foreign 失败不消费，double 拒绝，sibling
  均可从 exact predecessor 提交。
- [x] 原 R18 `mainline_stage_runtime_admission_test.dart` 16/16 必须原样
  回归通过；实现里 release 提交参数名钉为
  `exactPredecessor`，prepare receiver 用 `releasePredecessor`，不新增
  import，source 注释/字符串避开 R18 已冻结 forbidden raw
  substrings，不破坏既有 method-call 计数。
- [x] 生产接线如实标为未接；只交付 R18→R15 可组合释放
  seam，不冒充 host 或 durable transaction。
- [x] targeted、scoped analyze、format、diff-check、owned path/status
  和 Codex 独立自审通过。
- [x] 红线：0 tuning/YAML/玩家文案/数值/三系/在线离线/
  反主流/reward/save/UI 变更；不跑 full suite。
- [x] 中文动宾小提交完成，最后追加精确 READY 空提交。

## 任务切片

1. 复读 CLAUDE/AGENTS、Batch17 plan/audit/registry、R15/R18
   source/test/plan，完成 Pi 实现前只读审查。
2. 新建 R19 专用测试，跑出缺失 API 的有效红灯并提交。
3. 最小扩展 R18 source，跑新测试、R15 与原 R18 16/16
   影响回归；原 R18 source guard 不可修改或绕过。
4. 运行 scoped analyze/format/diff/path/status，Pi 最终 diff 只读
   审查，triage 后收口证据与 READY。

## Pi 只读审查证据

### 实现前设计审查

- 版本/selector：Pi CLI `0.84.1`，exact
  `deepseek/deepseek-v4-flash`，thinking `high`。
- 权限：`--no-session --no-skills --no-prompt-templates --tools
  read,grep,find,ls --print`；无 Bash/Edit/Write，零修改、零测试。
- 首轮完整审查结论：`FAIL`，P0=0、P1=3、P2=4。P1 要求
  钉死 final-admission-only 签名、用 choice 判定 exact provenance，
  并守住原 R18 全文 source-contract 的 import/命名/计数/禁词；
  P2 要求冻结 release 返回值、no-op reason 和具体测试矩阵。
  全部在代码实现前写入冻结合同。
- 修订后的精简复核调用 60 秒无输出，按时限 Ctrl-C
  终止（exit 130），未伪造该轮结论；首轮有效 findings 已逐项
  落地后才进入红测。

### 最终 actual diff 审查

- 版本/model/thinking/权限与实现前审查一致；由 Codex 先物化
  `88e1413486889a0b98d027bd56f56b7ba51cbc5d...fd268f49` 三份
  owned files 的 actual diff 并嵌入 prompt，Pi 本身仍只读。
- 结论：代码与测试 `PASS`，P0=0、P1=0；确认 exact
  provenance、empty+occupied、四 reason、R15 `prepare([])`、private
  successor、exact-predecessor/single-use/sibling、异常不包装、禁止
  推断/越界与原 R18 source guard 全部通过。
- Pi 只有两项非代码 P2：本计划 checklist/恢复点过时；
  final admission 私有构造不变量下 R19 的 stage/character 预检分支
  防御性不可达。前者已在本次收口；后者不放宽私有构造/
  不加测试后门，权威 mismatch 行为继续由 R15 测试覆盖，
  R19 source guard 则钉住防御比较存在。两项均已关闭。

## 当前恢复点

- 状态：三份 owned files 的实现、TDD、验证、Pi 两轮有效只读
  审查与 Codex 独立终审均完成，P0/P1/P2=0，待本证据提交后
  追加 READY。
- 提交：`cd20dc1c` 计划、`3e458f2d` 收紧合同、`5ec27f7d`
  红测、`fd268f49` 最小实现。
- TDD：首次 Flutter native-assets metadata 异常在
  `flutter pub get --enforce-lockfile` 后恢复；有效红灯精确为缺少
  `admittedCompanion` 与 `prepareMainlineStageRuntimeRelease`。绿灯为
  R19 11/11 + 原 R18 16/16 + R15 18/18 = 45/45。
- 静态验证：scoped `flutter analyze --no-pub` 4 items 0 issue；
  最终 format 2 files 0 changed；`git diff --check`、baseline owned-path
  audit 与 status/main refs 通过。按任务约束未跑 full suite。
- 独立审查：Codex 复核 actual diff 及 45/45/analyze/format/
  path/status 证据，结论 P0=0、P1=0、P2=0。
- 下一步：提交本收口证据，追加精确
  `[READY][PI][P2-M2-R19] 冻结主线单关听剑释放边界` 空提交。
- 阻塞项：无。
- 生产接线：未接；host/persistence/claim/reward/settlement
  identity 继续 Gate。
