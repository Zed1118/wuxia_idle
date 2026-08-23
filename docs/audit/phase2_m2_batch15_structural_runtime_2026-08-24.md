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

## 集成验证

- 三个来源共 15 个非空提交均逐项通过 stable patch-id；集成内容与 R14 `ddb931d0`、R15 `66d9a5e1`、V01 修后 `bb26671b` 的 owned-file tree 一致。
- 15 文件去重联合 targeted 170/170 PASS；changed-Dart scoped analyze 5 items、0 issue；format 5 files、0 changed。
- registry YAML 82 tasks、0 duplicate、0 dangling；`git diff --check`、owned-path、clean status 与中文动宾提交守卫通过。
- 首轮 compact full 在约第 1550 项出现一次未稳定复现的 transient，未把红态作为验收证据并主动终止该轮；随后使用 `--fail-fast --reporter expanded` 从头完整重跑，越过原计数点并最终 4988/4988 PASS。集成实现未为该 transient 做掩盖性修改。
- full 重跑后本地 `main` 与 `origin/main` 仍均为 `e292d3a069fbc0e129dd74fafc1ebb3746f53557`；集成分支不修改或推进主分支。

## 已完成来源

- R14：计划 `2f68253c`、实现 `387b44cc`、初始证据/READY 后独立复审发现两项证据 P2：canonical const 跨调用 identity 假证明与恢复点滞后。`0262adaf` 改为单次 admission 的准确异常类型/消息/零 admission，`99bddf74` / `e58d2187` 同步复审证据，新 READY `ddb931d0`；修后独立复审 P0/P1/P2=0。五文件去重 54/54、scoped analyze 0。集成提交 `7ac204e6` / `477576f9` / `faf98b48` / `6883617f` / `c6f0387b` / `9e5049cc` 的 stable patch-id 与来源逐项一致；主控复跑 54/54、analyze 0。
- R15：计划 `a10edae6`、Pi/API 证据 `535b59e2`、红测 `cfe1e5c7`、实现 `a29206d5`、验收证据 `dfde55cb`，来源 READY `66d9a5e1`。Pi 0.84.1 使用精确 `deepseek/deepseek-v4-flash`、thinking `high`、只读工具完成设计与终审，两轮均 PASS；Codex 独立复审 P0/P1/P2=0。四文件去重 65/65、scoped analyze 0、format/diff/path/status clean。集成提交 `30d3fbc8` / `04e7f984` / `fc55be7d` / `31f3fab1` / `9c23496f` 保留来源内容；production host、persistence、共享占用反向接线、成长 cap/比例与 durable claim 继续 Gate。
- V01：计划 `663f6e1a`、初始实现 `934d0cfd`、Qoder 验收证据 `6d545ea4`，前一 READY `277bbabd`。Qoder CLI 1.1.28 使用精确 `Qwen3.8-Max`、reasoning `high`、Read/Grep/Glob-only 完成设计与终审，P0/P1=0。Codex 初审提出“0 数值/公式”措辞过宽与五关单 test 定位粒度两项 P2，`5517ec10` 将边界精确为无 production/candidate tuning 数值/公式变更，并拆成五个 stage ID 命名 case；新 READY `bb26671b` 修后独立复审 P0/P1/P2=0。六文件去重 51/51、scoped analyze 0、format/diff/path/status clean。集成提交 `c0d4e34a` / `fc0694b6` / `a152f164` / `b88b16bd` 的 stable patch-id 与来源逐项一致；objective 可执行性、candidate 晋升、production host/data、性能/Profile 与真人试玩继续 Gate。

## 最终收口

- 独立集成初审确认实现与 15 个来源 patch 无行为缺陷，仅发现 V01 四个集成 commit 在 registry 误挂 R15 的文档 P2；`e597f30c` 前已修为 R14 6 + R15 5 + V01 4，Batch15 总表精确 15 项。
- 修后独立复核 P0/P1/P2=0，并独立重跑 analyze 5 items 0、format 5 files 0 changed、registry 82/0/0；确认 11 个预期 baseline diff 文件、clean status 与 main refs 不变。
- 验证冻结提交为 `e597f30cda427cb010e8960538ada155335fb95f`；本证据提交后只追加精确空提交 `[READY][CODEX][P2-M2-BATCH15] 冻结结构构造与主线运行时合同`。
- Batch15 只关闭 construction-only evidence、mainline admission 与 mentor occupancy runtime 合同；不宣称 production vertical slice、objective executable、candidate 晋升、G2、Profile 或真人验收通过。
