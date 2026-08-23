# 二阶段 M2 Batch15 结构构造与主线运行时审计（2026-08-24）

## 基线与授权

- 共同基线：Batch14 READY `7bc31c5f5463aac26e127912576350487ac0a8d3`。
- 用户已授权持续自动推进并充分并行使用 Pi + DeepSeek Flash、Qoder CLI + Qwen3.8-Max 与 Codex 多 Agent；本批三项均不需要新的产品语义决策。
- main/origin main 初始均为 `e292d3a069fbc0e129dd74fafc1ebb3746f53557`，禁止直接修改。

## 预检结论

- V01 只关闭“五个 candidate assignment 能否完整构造显式 migrated runtime 对象图”的结构证据缺口。R13 要求 actor defeat projection exact coverage，因此测试只能逐 actor 显式声明空 projection；不得按 entry/role/string 猜 objective，也不得宣称目标可执行。
- R14 只关闭 R01 已冻结的 participant selection 与 `MainlineRun.begin` 之间的薄组合缺口。current leader、requested eligibility、run/stage/loadout ID 都保持 caller facts；任一既有合同拒绝时不产生 admission。
- R15 只关闭 R02 单关 occupancy 的状态机缺口。不可变 prepared successor 可证明 failure/foreign owner/stale predecessor/double commit 零发布，但不承担活动查询、成长发放或 durable claim。
- R12b 只读预检确认可用显式 planner 做 transactional session plumbing，但 session/outer-flow publication 是独立高风险切片；ActionTimeline 与 action completion/cancel/interrupt identity 仍未冻结，本批不接。

## 风险控制

- candidate promotion 泄漏：V01 owned files 仅新测试与计划，现有 fixture 与 production data 均只读。
- 第二真相源：R14/R15 必须调用或消费既有 R01/R02 合同，不复制 participant、blocking、release 或 claim 规则。
- 原子性：R14 先完成 selection 后才构造并返回 admission；R15 所有 iterable/transition 在 successor 发布前完整验证。
- 生产越权：三项均禁止 host/repository/save/UI/data/tuning/Profile/真人验收接线。
- 可恢复性：四 worktree 从同一 READY 创建，来源小切片 commit；主控只按 stable patch-id 集成并在批末独立终审。

## 环境恢复

- 四 worktree 均执行 `flutter pub get --enforce-lockfile` 与 build_runner，分别生成 126 个 gitignored outputs；63 个 `.g.dart` 存在。
- 四份 `libisar.dylib` SHA-256 均为 `f22f60782156ff3205c4ef72ff157337640604a8a0c4c416555a2432c764742d`。

## 待完成验证

待三来源 READY 后补充实际 Qoder/Pi 证据、来源/集成提交、联合 targeted、scoped analyze、full suite、仓库闸门、独立终审与最终 READY。

## 已完成来源

- R14：计划 `2f68253c`、实现 `387b44cc`、初始证据/READY 后独立复审发现两项证据 P2：canonical const 跨调用 identity 假证明与恢复点滞后。`0262adaf` 改为单次 admission 的准确异常类型/消息/零 admission，`99bddf74` / `e58d2187` 同步复审证据，新 READY `ddb931d0`；修后独立复审 P0/P1/P2=0。五文件去重 54/54、scoped analyze 0。集成提交 `7ac204e6` / `477576f9` / `faf98b48` / `6883617f` / `c6f0387b` / `9e5049cc` 的 stable patch-id 与来源逐项一致；主控复跑 54/54、analyze 0。
