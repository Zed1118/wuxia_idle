# 二阶段 M2 Batch13 装配、目标与路由接缝审计（2026-08-24）

## 基线与范围

- 基线：Batch12 READY `81d47f16880b2b9d7a860379cf308cca3f6110e2`。
- R08、R09、R10 文件所有权互不重叠；assembler 汇合点只归 R08，encounter flow/tracker 只归 R09，route selector 为 R10 新文件。
- 本批只交付显式可选的 application/data-validation 合同，不启用 production stage route。

## 预注册风险与控制

- assembler 偷带默认调优：R08 仅透传 exact optional gate，source guard 禁止预算/角色推断与 host 改动。
- objective 双真相源：R09 在配置 objective runtime 时屏蔽旧 survive/director 自动胜利；null 时保持旧语义，玩家死亡始终优先。
- objective 半提交：R09 用 prepared transition 在 flow 其余可失败投影完成后单次 commit；source/lazy iterable/controller 异常不提交 objective progress。
- 集成误启用：R08 合入后，主控只允许 assembler 成对透传 caller 显式提供的 objective tracker/event source；不构造 controller、objective、默认 mapper 或 host route。
- RNG 过度承诺：当前 resolver/RNG 无 rewind 接口；审计只要求本任务不新增随机消费且保留既有行为，不宣称异常可回退 RNG。
- route fallback：R10 必须让现有 migration resolver 复核 assignment/allowlist/encounterCount/legacyContent shape；migrated 异常不得走 legacy。
- production promotion：生产 YAML、host、mainline mapper、candidate fixtures 全部不在 owned files。

## 验证记录

### 来源任务

- R08：实现 `2f68aabc`、证据 `89460888`、READY `46bc5573`。Pi CLI 0.84.1 实际使用 `deepseek/deepseek-v4-flash`、thinking high 完成设计审查、最终 diff 审查与 post-triage 复核，最终 PASS；71/71、scoped analyze 0，独立复审 P0/P1/P2=0。
- R09：实现 `b20bdd74` / `bb6a3792`，初始 READY `08bab759`。独立复审发现 objective frame 复用 actor 内五组可变容器的 P2；`0c59ee91` 深冻 before/after player/enemy、`bossPhases` 及嵌套 `unlockSkillIds`、`unlockedEnemySkillIds`、`enemySkillCooldowns`、`phaseChargeCasts`、`guardianDefIds`，`1f6fccc1` 同步证据，新 READY `ec6d9acf`。修后 119/119、scoped analyze 0，独立复审 P0/P1/P2=0。
- R10：实现 `a121d15b`、READY `6ffa3bd2`。Qoder CLI 1.1.28 实际使用 `Qwen3.8-Max`、reasoning high 完成设计与最终 diff 审查，最终 PASS；45/45、scoped analyze 0，独立复审 P0/P1/P2=0。

### 主控集成

- 来源集成提交：R08 `ac86e7b1` / `17e571dc`，R09 `3bacf62d` / `dc9c03cd` / `8130c9c5` / `fd470c8e` / `697a4145`，R10 `a9ea9e0e`；逐项 stable patch-id 与 source commit 一致。
- 主控提交 `87e84a66` 只在 assembler 的 direct/mapping bridge 成对透传显式 objective tracker/event source，并新增 2 项联合接缝测试；不构造 controller、objective、token budget、mapper、默认值或 host route。
- 19 个合同、应用与数据测试文件联合 targeted：183/183；相对 Batch12 基线的 10 个变更 Dart 项 scoped analyze 0 issue，format 0 changed，`git diff --check` 通过。
- 批末 full Flutter test：4913/4913 通过，exit 0。
- fresh integration worktree 已执行 `flutter pub get` 和 build_runner，生成 126 个 gitignored outputs；63 个 `.g.dart` 存在，`libisar.dylib` 与主 checkout SHA-256 均为 `f22f60782156ff3205c4ef72ff157337640604a8a0c4c416555a2432c764742d`。
- task/decision registry 已验证 74 个任务 ID 唯一、prerequisite 0 悬空；49 项决策中 20 个 `TUNE-*` 全部继续保持 `tuning`。相对基线无 `data/`、mainline host/stage entry、GDD/CLAUDE/PROGRESS 或 candidate fixture 变更。
- `main` 与 `origin/main` 均保持 `e292d3a069fbc0e129dd74fafc1ebb3746f53557`。

### 批末待完成

- full Flutter test 与集成态证据已完成；本记录提交后启动独立集成终审，P0/P1/P2 清零后再冻结 Batch13 READY。
