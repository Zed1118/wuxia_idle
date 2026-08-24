# 二阶段 M2 Batch19 可观测事务与执行上限审计（2026-08-24）

## 基线与授权

- 集成基线：Batch18 READY `b6fd77242d8d72fd75822b70e7353e60b9542e0a`。
- 用户已授权持续自动推进并充分并行使用 Pi + DeepSeek Flash、Qoder CLI + Qwen3.8-Max 与 Codex 多 Agent；本批只做 frozen host-neutral 合同与 candidate-only 验证。
- main/origin main 初始均为 `e292d3a069fbc0e129dd74fafc1ebb3746f53557`，禁止直接修改。

## 预检结论

- EncounterFlow 已独占 runtime session 与 objective tracker，但缺少不泄露 mutation capability 的只读 progress/receipt 观测；两个 nullable getter 可直接转发 exact immutable 状态。
- 旧 migrated assembler 固定创建 stateless gate，不能再附加 transactional lease pair；R26 必须新增独立显式方法，复用 `assembleEncounterFromMapping` 并在方法体内 fresh objective tracker。
- Ch1 candidate 真实 fixture 为 5 stages / 95 entries；逐 entry 明示 67 Target、3 Commander、25 empty 后，R22→R13 可产生 70 defeat events 并由 R06 执行，无需用户决策。

## 风险控制

- observation 过权：R25 只读转发 `_objectiveTracker?.progress` 与 `_session?.lastAttackTokenLeaseBatchReceipt`；不得返回 session/tracker/runtime owner。
- gate 互斥：R26 使用独立方法，不改变旧 stateless assembler；不得同时传 `enemyIntentBatchGate` 与 transactional lease gate。
- fake-green：V02A 的 95 条声明必须逐 entry 硬编码，不能从 objective、ID 前缀、role 或 position 生成；runtime actor 必须与 entry ID 不同。
- objective 过报：stage 01 的 defeat clause 完成但 aggregate 因 checkpoint 为 false；stage 02 只由 commander `any` 分支完成，anchor 仍未执行。
- production/candidate promotion/checkpoint-anchor host/timeline/durable/tuning/Profile/G2/真人验收继续 Gate。

## 已完成来源

- R25：计划 `3098b000`、红测 `6ab21afa`、实现 `974c6b2a`、guard `46c0bde6` / `e79a50b1`、证据 `ac031f37`，来源 READY `55bead7e27a15301e041248b9cfacb20abead5bb`。Pi 0.84.1 使用精确 `deepseek/deepseek-v4-flash`、thinking high、Read/Grep/Find/Ls-only；设计 P1/P2 全采纳，最终原始 P0/P1/P2=0/0/2，修复 nullable owner getter guard 并关闭流程态后有效 P0/P1/P2=0。targeted 58/58、scoped analyze 2 items / 0 issue、format/path/diff/status clean；六个集成提交 `a5e00d67` / `5bae8bb2` / `d688bfc4` / `cfa22618` / `b1611ea7` / `9ed96c24` 的 patch-id 与来源逐项一致，3/3 blobs 一致。
- R26：计划 `784d76b6`、红测 `e8891ddb`、实现 `e5816b23`、证据 `9a72782a`，来源 READY `414d616d9e6d6969b60e3b8b7ba3f52a6b5f58d1`。Qoder CLI 1.1.28 使用精确 selector `Qwen3.8-Max`、reasoning high、Read/Grep/Glob-only，终审 P0/P1/P2=0；targeted 60/60、scoped analyze 2 items / 0 issue、format/path/diff/status clean。四个集成提交 `e04a3706` / `0448813e` / `ceb7587a` / `3c19fd28` 的 patch-id 与来源逐项一致，3/3 blobs 一致。
- V02A：计划 `0b35f02f`、红测 `25b4e420`、实现 `e7e60561`、guard/triage `85e83185`、证据 `b4986d13`，来源 READY `095ef9edafd6eca5d174b3d447156fbbafbf396f`。Pi 精确 DeepSeek Flash high 首轮 FINAL PASS P0/P1=0，关闭 checklist P2 并加固独立计数 guard；post-triage 首调超时后有界中止，同配置精简重试返回 FINAL PASS P0/P1/P2=0。影响集 89/89、scoped analyze 1 item / 0 issue、format/path/diff/status clean；五个集成提交 `aac4580e` / `80d56bb6` / `4839ae7a` / `db4fe573` / `cd6b02c4` 的 patch-id 与来源逐项一致，2/2 blobs 一致。

## 集成验证

- 主控逐项重算 R25/R26/V02A 共 15 个 source→integration stable patch-id 与 8 个 owned blobs，全部与来源 READY tip 一致。
- 影响集去重联合 targeted 197/197 PASS；changed-Dart scoped analyze 5 items / 0 issue；format 5 files / 0 changed。
- `flutter test --no-pub --reporter compact` 从 clean integration 起点单次完成 5129/5129 PASS；未并行启动第二个 full 进程。
- registry 99 tasks / 0 duplicate IDs / 0 dangling refs；相对 Batch18 精确 11-file path guard、`git diff --check` 与 clean status 通过。
- main 与 origin/main 仍均为 `e292d3a069fbc0e129dd74fafc1ebb3746f53557`。

## 最终结论

- Batch19 只冻结 EncounterFlow 只读 progress/receipt、显式 caller-owned lease assembler 与 candidate defeat-objective execution ceiling；不宣称 production host、candidate promotion、checkpoint/anchor projector、timeline 推断、durable store/schema/CAS/outbox、tuning/Profile/G2/真人验收已完成。
- 独立集成终审固定验证提交 `02397c8e53aaffa575ba82f09ad0e8df39f225e4`，重算 registry 99/0/0、15/15 stable patch-id、8/8 owned blobs，复跑 scoped analyze 5 items / 0 issue、format 5 files / 0 changed 与 V02A 8/8，结论 P0/P1/P2=0。
- registry/docs 闭环复核通过后只追加空 READY marker `[READY][CODEX][P2-M2-BATCH19] 冻结可观测事务执行上限`。

## 集成环境恢复点

- Batch19 integration 已执行 `flutter pub get`；依赖解析成功，未改动受版本控制文件。
- build_runner 成功写入 126 个生成输出，其中 `.g.dart` 共 63 个；生成后工作树保持 clean。
- 从 Batch18 READY worktree 恢复 ignored `libisar.dylib`，SHA-256 为 `f22f60782156ff3205c4ef72ff157337640604a8a0c4c416555a2432c764742d`；该运行库不进入提交。
- R25/R26/V02A source worktree 均从登记提交 `cc09030ce371be064425f3fef929f53f0c562a33` 创建，owned files 互不重叠并已并行派发。
