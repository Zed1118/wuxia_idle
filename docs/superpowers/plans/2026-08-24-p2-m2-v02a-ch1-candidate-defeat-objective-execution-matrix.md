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

- [x] 95 个 encounter entry 都有 caller 逐条硬编码 declaration：67
  个 Target、3 个 Commander、25 个 empty；不从 entry / actor / role /
  position / objective 字符串或类型生成 projection。
- [x] R11 每个 runtime actor ID 与 content entry ID 明显不同；R22 仅经
  exact `bindingByEntryId` 交付 R13。
- [x] 按 roster/content 顺序提交 95 个 defeat facts，R13 产生类型、
  payload、顺序精确的 70 个 events，R06 保持 clause 顺序与
  all / any 聚合语义。
- [x] 冻结关卡结果：01_01 `[true,false] / false`；01_02
  `[false,true] / true`；01_03 `[true] / true`；01_04
  `[true,true] / true`；01_05 `[true] / true`。checkpoint / anchor 无事件。
- [x] R22 在真实 Ch1 fixture/plan 上对 missing / foreign / wrong-kind /
  duplicate declaration fail closed。
- [x] source guard 禁止 projection 推断、手写 checkpoint/anchor event、
  `flow.advance`、fixture/production/tuning/candidate promotion 写入或 IO default。
- [x] 生产接线证据如实限定为已有 R11/R22/R13/R06 组合合同；
  本任务只新增 candidate-only test，不宣称 host 或 production route。
- [x] 运行新矩阵、candidate catalog/V01、R11/R22/R13/R06、
  primitive mapper/controller 影响集；1-item analyze；format/diff/path/status。
- [x] 数值红线、三系锁死、在线=离线、反主流不做项与文案/
  数值硬编码均不受影响；未改 production / data / schema / tuning。
- [x] Pi CLI 0.84.1 exact `deepseek/deepseek-v4-flash` thinking high，
  Read/Grep/Find/Ls-only 完成最终只读审查，P0/P1/P2 清零。
- [x] 残留 Gate 明示保留 checkpoint/anchor projector、production host、
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

- 状态：实现、验证与最终只读审查全部完成，待空 READY。
- 最后完成：计划 `0b35f02f`、红测 `25b4e420`、实现
  `e7e60561`、guard/triage 收口 `85e83185`。Pi CLI 0.84.1 使用
  exact `deepseek/deepseek-v4-flash`、thinking high、Read/Grep/Find/Ls-only；
  首轮 `FINAL PASS` 的唯一可操作 P2（checklist 滞后）已关闭，
  post-triage 首次调用五分钟无输出后有界中止，同 exact 配置精简
  prompt 重试在五分钟边界内返回 `FINAL PASS`，P0/P1/P2=0；纯方法
  限制单列 non-finding。
- 下一步：提交本证据恢复点，追加空 READY marker。
- 已跑验证：`flutter pub get`；`dart run build_runner build`（126 outputs）；
  红测 0/1（预期）；新矩阵 8/8 PASS；9 个影响集逐文件
  89/89 PASS；`flutter analyze --no-pub <new-test>` 0 issue；format 1 file /
  0 changed。加固 guard 后新矩阵再次 8/8、analyze 0；最终
  format 1 file / 0 changed、`git diff --check` clean、精确 2 owned paths。
- 阻塞项：无。
