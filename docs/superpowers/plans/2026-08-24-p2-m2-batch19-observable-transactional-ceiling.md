# P2 M2 Batch19：可观测事务与执行上限

## 目标

从 Batch18 READY `b6fd77242d8d72fd75822b70e7353e60b9542e0a` 出发，并行闭合三个 owned files 不重叠且无需新产品决策的切片：EncounterFlow 只读运行时观测、migrated plan 显式 transactional lease 装配桥、Ch1 candidate defeat-objective 可执行上限矩阵。本批不接 production host，不晋升 candidate，不伪造 checkpoint/anchor projector，不推断 action lifecycle 或 durable transaction。

## 并行任务

1. R25 / Pi + DeepSeek V4 Flash high：只读暴露 nullable `objectiveProgress` 与 exact `lastAttackTokenLeaseBatchReceipt`，证明所有 candidate advance 失败均保留旧观测。
2. R26 / Qoder CLI + exact Qwen3.8-Max high：新增独立显式 lease assembler，逐项透传 caller gate/runtime/source/numbers/RNG，并为每个 flow 创建 fresh objective tracker；旧 stateless assembler 完全不变。
3. V02A / Codex high + Pi 终审：以 95 条逐 entry 显式声明，经 R11→R22→R13→R06 验证五关 defeat 分支；只冻结 67 Target、3 Commander、25 empty，不生成声明或 checkpoint/anchor 事实。

## 硬边界

- R25 不修改 `Phase0aBattleFlow` 接口，不暴露 session/tracker/lease owner 或 prepare/commit 能力；compatibility/unconfigured 为 null。
- R26 不给旧方法添加 nullable lease 参数，不同时接 stateless 与 transactional gate，不构造 gate/runtime 默认，也不证明 caller gate 与 plan budgets 等价。
- V02A 不从 ID/role/position/objectives 反推 declaration；`stage_01_01` checkpoint 与 `stage_01_02` anchor 路径继续不可执行。
- production route/host、candidate promotion、durable store/schema/CAS/outbox、settlement identity、tuning/Profile/G2/真人验收继续 Gate。

## 验收

- 三来源独立 worktree TDD；R25/R26 分别经精确外部模型设计与终审，V02A 经独立只读终审；来源 targeted/analyze/format/path/diff/status 全部 clean 后追加各自 READY。
- 主控逐项复核 actual diff、stable patch-id、owned blobs、失败零发布与 Gate 诚实性。
- 集成态运行去重联合 targeted、changed-Dart scoped analyze、format、registry/diff/path/main refs、单次 full suite 与独立终审；清零后追加 Batch19 READY。

## 当前恢复点

- [x] Batch18 READY `b6fd77242d8d72fd75822b70e7353e60b9542e0a` 已冻结，full 5102/5102、独立终审 P0/P1/P2=0，main/origin main 未修改。
- [x] Batch19 三任务契约已由三路只读预检核验，无用户决策依赖。
- [x] Batch19 integration 已完成 `flutter pub get`、build_runner 126 outputs（63 个 `.g.dart`）与 `libisar.dylib` 恢复；三 source worktree 已从登记提交 `cc09030c` 创建并派发。
- [ ] R25/R26/V02A 各自在 source worktree 完成并行实现与来源 READY。
- [ ] 联合/full 验证、独立终审与 Batch19 READY。
