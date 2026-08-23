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

## 待完成验证

待 R12c/R17/R18 来源 READY 后补充工具证据、来源/集成提交、联合 targeted、scoped analyze、full suite、仓库闸门、独立终审与最终 READY。

## 已完成来源

- R12c：计划 `a306bd67`、红测 `a6d1296d`、红测恢复点 `16cc71ac`、实现 `e6ddf3b7`、验收证据 `a6f77288`，来源 READY `f48f3d45`。Pi 0.84.1 使用精确 `deepseek/deepseek-v4-flash`、thinking `high`、只读工具完成设计与终审，P0/P1=0；Codex 独立终审 P0/P1/P2=0。八文件 targeted 89/89、scoped analyze 5 items 0、format/diff/path/status clean。集成提交 `c6238b5d` / `02192e4b` / `0e63a2d8` / `6ec3d462` / `93150353` 的 stable patch-id 与来源逐项一致，主控在集成态复跑 89/89；migrated host、ActionTimeline、action lifecycle 与 tuning 继续 Gate。
