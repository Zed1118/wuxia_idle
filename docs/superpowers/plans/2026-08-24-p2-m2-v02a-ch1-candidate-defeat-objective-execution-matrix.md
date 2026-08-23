# P2 M2 V02A：Ch1 候选败北目标执行上限矩阵

## 目标

从 Batch19 登记基线 `cc09030ce371be064425f3fef929f53f0c562a33`
出发，用一个 candidate-only 测试矩阵证明 Ch1 五个 fixture 能经
fixture loader → R11 migrated encounter plan → R22 defeat projection mapper
→ R13 explicit event source → R06 objective tracker，执行当前已冻结的
Target / Commander 败北目标上限。这不是 production 接线、candidate
promotion 或全目标 executable 声明。

## 分支与 owned files

- worktree：`/Users/a10506/Desktop/Projects/挂机武侠-phase2-m2-v02a-ch1-candidate-defeat-objective-execution-matrix`
- 基线：`cc09030ce371be064425f3fef929f53f0c562a33`
- 只允许修改：
  - `test/data/phase2/ch1_candidate_defeat_objective_execution_matrix_test.dart`
  - `docs/superpowers/plans/2026-08-24-p2-m2-v02a-ch1-candidate-defeat-objective-execution-matrix.md`

## 验收标准

- [ ] 95 个 encounter entry 都有 caller 逐条硬编码 declaration：67
  个 Target、3 个 Commander、25 个 empty；不从 entry / actor / role /
  position / objective 字符串或类型生成 projection。
- [ ] R11 每个 runtime actor ID 与 content entry ID 明显不同；R22 仅经
  exact `bindingByEntryId` 交付 R13。
- [ ] 按 roster/content 顺序提交 95 个 defeat facts，R13 产生类型、
  payload、顺序精确的 70 个 events，R06 保持 clause 顺序与
  all / any 聚合语义。
- [ ] 冻结关卡结果：01_01 `[true,false] / false`；01_02
  `[false,true] / true`；01_03 `[true] / true`；01_04
  `[true,true] / true`；01_05 `[true] / true`。checkpoint / anchor 无事件。
- [ ] R22 在真实 Ch1 fixture/plan 上对 missing / foreign / wrong-kind /
  duplicate declaration fail closed。
- [ ] source guard 禁止 projection 推断、手写 checkpoint/anchor event、
  `flow.advance`、fixture/production/tuning/candidate promotion 写入或 IO default。
- [ ] 生产接线证据如实限定为已有 R11/R22/R13/R06 组合合同；
  本任务只新增 candidate-only test，不宣称 host 或 production route。
- [ ] 运行新矩阵、candidate catalog/V01、R11/R22/R13/R06、
  primitive mapper/controller 影响集；1-item analyze；format/diff/path/status。
- [ ] 数值红线、三系锁死、在线=离线、反主流不做项与文案/
  数值硬编码均不受影响；未改 production / data / schema / tuning。
- [ ] Pi CLI 0.84.1 exact `deepseek/deepseek-v4-flash` thinking high，
  Read/Grep/Find/Ls-only 完成最终只读审查，P0/P1/P2 清零。
- [ ] 残留 Gate 明示保留 checkpoint/anchor projector、production host、
  candidate promotion、flow tick/runtime simulation、tuning/Profile/G2/真人验收。

## 任务切片

1. 恢复 `flutter pub get`、build_runner 与 ignored `libisar.dylib`，确认
   tracked worktree clean。
2. 固定本计划并提交。
3. 写矩阵红测，确认在缺少真实 execution harness 时失败。
4. 完成 95 条显式 declaration、70 事件和五关进度断言，再加
   fail-closed/source guard。
5. 运行指定影响集、scoped analyze 与 repository guards，记录真实证据。
6. 用 Pi 做最终 actual-diff 只读审查，triage 并清零 findings。
7. 更新恢复点，冻结 clean worktree，追加空 READY marker。

## 当前恢复点

- 状态：进行中。
- 最后完成：红测已以 `25b4e420` 提交；95 条硬编码
  declaration、70 条独立期望事件、五关 R11→R22→R13→R06 进度
  矩阵及真实 fixture fail-closed/source guard 已实现。
- 下一步：提交实现，运行全部指定影响集与 scoped analyze。
- 已跑验证：`flutter pub get`；`dart run build_runner build`（126 outputs）；
  `git status --short` clean；新矩阵红测 0 pass / 1 fail（预期）；
  实现后新矩阵 8/8 PASS。
- 阻塞项：无。
