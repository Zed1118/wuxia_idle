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

- 来源集成提交：R08 `b7142184` / `7f3ea4fe`，R09 `8422be25` / `cdc33b25` / `75a2db75` / `1a70b9c2` / `c6e80a0e`，R10 `9aba4f95`；逐项 stable patch-id 与 source commit 一致。
- 主控提交 `e6574159` 只在 assembler 的 direct/mapping bridge 成对透传显式 objective tracker/event source，并新增 2 项联合接缝测试；不构造 controller、objective、token budget、mapper、默认值或 host route。
- 19 个合同、应用与数据测试文件联合 targeted：183/183；相对 Batch12 基线的 10 个变更 Dart 项 scoped analyze 0 issue，format 0 changed，`git diff --check` 通过。
- 批末 full Flutter test：4913/4913 通过，exit 0。
- fresh integration worktree 已执行 `flutter pub get` 和 build_runner，生成 126 个 gitignored outputs；63 个 `.g.dart` 存在，`libisar.dylib` 与主 checkout SHA-256 均为 `f22f60782156ff3205c4ef72ff157337640604a8a0c4c416555a2432c764742d`。
- task/decision registry 已验证 74 个任务 ID 唯一、prerequisite 0 悬空；49 项决策中 20 个 `TUNE-*` 全部继续保持 `tuning`。相对基线无 `data/`、mainline host/stage entry、GDD/CLAUDE/PROGRESS 或 candidate fixture 变更。
- `main` 与 `origin/main` 均保持 `e292d3a069fbc0e129dd74fafc1ebb3746f53557`。

### 终审与残留 Gate

- 独立集成终审复跑 19 文件 targeted 183/183，并复核 10 项 scoped analyze 0、format 0 changed、full 4913/4913 证据、8 组 source→integration stable patch-id、74 个任务 ID、49 个决策 ID、20 个 `TUNE-*` 状态与 main refs。
- 首轮终审只发现 4 条英文提交信息违反 CLAUDE.md §8.2/§11 的 P2；隔离分支保留 `codex/phase2-m2-batch13-pre-message-fix-b1f3fde8` 备份后，已把 4 条消息重写为中文动宾，并在 `58526d0e` 同步 registry/audit 的新集成哈希。修后 `lib/`、`test/` 及全部非文档文件相对备份零差异，终审 PASS，P0/P1/P2=0。
- 实现、来源工具审查、三项来源独立复审、集成独立终审、联合 targeted、analyze、format、full test 与仓库审计全部通过；本记录提交后追加空 `[READY][CODEX][P2-M2-BATCH13] 收口装配目标路由接缝`。
- production candidate/tuning 晋升、真实 host/stage route 切换、Mac/Windows Profile 与真人 G2 试玩继续保持 Gate；Batch13 不宣称这些产品验收完成。
