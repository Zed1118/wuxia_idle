# 二阶段 M2 Batch16 事务化宿主就绪接缝审计（2026-08-24）

## 基线与授权

- 共同集成基线：Batch15 READY `cf6a4ab61c06e3141658b37473cfa23b838342db`。
- 用户已授权持续自动推进并充分并行使用 Pi + DeepSeek Flash、Qoder CLI + Qwen3.8-Max 与 Codex 多 Agent；本批只做 host-neutral 结构接缝，不需要新的产品语义签字。
- main/origin main 初始均为 `e292d3a069fbc0e129dd74fafc1ebb3746f53557`，禁止直接修改。

## 预检结论

- R12b 已把 immutable lease runtime 放进 candidate Session，固定 prepare → validate → observer → reducer → commit → tail publish 顺序；outer-flow 失败只回滚 Session-owned state，caller-owned planner/observer/resolver 副作用不在承诺内。
- assembler 当前只能透传旧 stateless batch gate；R12c 可增加显式 pair 参数，但不能在没有稳定 action ID 和 lifecycle facts 时自动构造 gate/runtime 或修改 migrated 默认。
- settlement adapter 当前只接受旧 `Phase0aStageMapping`；R17 可对显式 encounter mapping 做机械适配并与旧入口共用核心，不需要决定 objective/reward/injury。
- R14 与 R15 均无 caller；R18 可用 request 的显式 `firstClear`、caller stage/choice/blocking facts 组成 owner-bound prepared admission，但不可冒充持久事务。

## 风险控制

- split-brain：R12c 成对与互斥校验继续由 Session 单一持有，assembler 只透传。
- settlement 漂移：R17 不复制事件/技能/伤害/critical 聚合规则，用 legacy/encounter 等价输入逐字段对照。
- 原子性过报：R18 只承诺进程内 exact predecessor / single commit；durable run/outbox/occupancy persistence 继续 Gate。
- 生产越权：三个来源均禁止 host/repository/save/data/candidate/tuning/Profile/G2/真人验收接线。

## 环境与来源状态

- R12b 来源 89/89 targeted、4969/4969 full、analyze 0、Qoder/Codex P0/P1/P2=0；READY `72e274aa`。
- R12b 五个非空提交已重放到 Batch16，source→integration stable patch-id 逐项一致；共同代码恢复点 `a952274781a11283ff5d7675ad270034a94cfd69`，主控在重放态复跑 8 文件 89/89 PASS。
- Batch16 integration 已完成 lockfile pub get、build_runner 126 outputs、63 个 `.g.dart` 与 `libisar.dylib` SHA-256 `f22f60782156ff3205c4ef72ff157337640604a8a0c4c416555a2432c764742d` 恢复。
- R12c worktree 已创建并开始 Pi 设计审查/TDD；R17/R18 在本登记恢复点后创建独立 worktree。

## 集成验证

- 主控逐项重算 22 个 R12b/R12c/R17/R18 source→integration stable patch-id，四来源 owned blobs 与各自 READY tip 完全一致。
- 五个变更测试文件去重联合 targeted 261/261 PASS；changed-Dart scoped analyze 10 items / 0 issue；format 10 files / 0 changed。
- `flutter test --no-pub --reporter compact` 从 clean integration 起点一次完成 5035/5035 PASS；未并行启动第二个 full 进程。
- registry 87 tasks / 0 duplicate IDs / 0 dangling prerequisite IDs；17-file path guard、`git diff --check` 与 clean status 通过。
- main 与 origin/main 终验仍均为 `e292d3a069fbc0e129dd74fafc1ebb3746f53557`。
- Codex 独立代码终审重跑五个变更测试文件 55/55、scoped analyze 10 items / 0 issue、format 10 files / 0 changed，结论 P0/P1/P2=0；确认 R12b 事务顺序、R12c pair 透传、R17 单一 settlement core、R18 私有 successor 与全部 Gate 均保持。
- 最终 registry/audit/plan 与 READY marker 的 docs-only 闭环仍待本验证提交后复核，因此此处不提前宣称 READY。

## 已完成来源

- R12c：计划 `a306bd67`、红测 `a6d1296d`、红测恢复点 `16cc71ac`、实现 `e6ddf3b7`、验收证据 `a6f77288`，来源 READY `f48f3d45`。Pi 0.84.1 使用精确 `deepseek/deepseek-v4-flash`、thinking `high`、只读工具完成设计与终审，P0/P1=0；Codex 独立终审 P0/P1/P2=0。八文件 targeted 89/89、scoped analyze 5 items 0、format/diff/path/status clean。集成提交 `c6238b5d` / `02192e4b` / `0e63a2d8` / `6ec3d462` / `93150353` 的 stable patch-id 与来源逐项一致，主控在集成态复跑 89/89；migrated host、ActionTimeline、action lifecycle 与 tuning 继续 Gate。
- R17：计划 `439c57e8`、API/Pi 设计证据 `f9538bc1`、红测 `ff434ec7`、实现 `394b442c`、验收 `f1a2e387`，来源 READY `5676460e`。Pi 0.84.1 使用精确 `deepseek/deepseek-v4-flash`、thinking `high` 两轮只读审查 PASS，唯一文档 P2 已关闭；Codex 独立终审 P0/P1/P2=0。九文件 targeted 94/94、scoped analyze 2 items 0、format/diff/path/status clean。集成提交 `9dd15905` / `ef92df28` / `2821fc52` / `e8a5fad9` / `1e31f2a2` 的 stable patch-id 与来源逐项一致，主控在集成态复跑 94/94；route/objective/reward/injury/host/persistence/data/tuning 继续 Gate。
- R18：计划 `f472c37c`、初始红测/实现 `e64f65a2` / `54d058bb`。主控预审发现公开 R15 successor 可绕过组合提交的 P1，`7d55e8f6` 先加绕过红测，`e862b308` 将 committable successor 私有化，`fc5df96b` / `f88a12fc` 更新验证与有效终审证据，来源 READY `05edb486`。Qoder CLI 1.1.28 使用精确 selector `Qwen3.8-Max`、reasoning `high`、Read/Grep/Glob-only；修前终审主动中止，修后有效终审 FINAL PASS 0/0/0，并诚实记录 Qoder 自述模型披露限制。Codex 独立终审 P0/P1/P2=0；六文件 targeted 93/93、scoped analyze 2 items 0、format/diff/path/status clean。七个非空集成提交 `fc1817c7` / `475c5b82` / `72beb491` / `4b8300fd` / `b60740d3` / `06e34157` / `8262fafd` 的 stable patch-id 与来源逐项一致，主控在集成态复跑 93/93；durable/global CAS、host/persistence/claim/tuning 继续 Gate。
