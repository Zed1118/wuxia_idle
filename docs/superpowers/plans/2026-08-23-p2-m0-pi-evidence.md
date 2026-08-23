# 2026-08-23 P2-M0-PI-EVIDENCE 计划文件

> 本计划服务于已完成的本证据任务，恢复点如实记录；任务性质 = 只读证据审计，零生产代码改动。

## 任务元数据

- taskId：`P2-M0-PI-EVIDENCE`
- milestone：M0（设计冻结与测量基线）· 只读证据包
- priority：高（G0 清账前置事实底座）
- owner：PI（本执行端）
- tool / model：Pi + DeepSeek `deepseek-v4-flash`
- goal：严格证据化审计五项决策（COMBAT-WAVE-CD-01 / EXP-CONCURRENCY-01 / MAINLINE-PARTICIPANT-01 / INNER-DEMON-FAILURE-CORE-01 / INNER-DEMON-LEGACY-01）的真实生产文件、符号、配置、测试与当前行为；产出实现差距证据包
- playerVisibleOutcome：无（不改变任何玩法）
- nonGoals：不修改 lib/data/test/GDD.md/CLAUDE.md/PROGRESS.md；不运行全量测试；不把 PROPOSED 当已决定；不 push / 不合并 main / 不升级依赖 / 不删除文件

## 基线与环境

- baseCommit：`e292d3a0`（收口主线群怪爽感与实机布局 = origin/main tip）
- branch：`codex/phase2-m0-pi-evidence-20260823`（基于审计启动时的 origin/main tip）
- worktree：当前 cwd（`挂机武侠-phase2-pi`），工作树干净
- 上游文档：`/Users/a10506/Desktop/二阶段优化方案.md`（v2.0 · 2026-08-23 冻结前修订稿 · G0 未签字）
- 必读：AGENTS.md / CLAUDE.md / docs/spec/rejected_task_registry.md / 二阶段优化方案.md —— 均已完成并引用

## 文件白名单（唯一允许产物）

| 文件 | 状态 |
|---|---|
| `docs/audit/phase2_m0_implementation_gap_evidence_2026-08-23.md` | 证据包（主交付物，已写） |
| `docs/superpowers/plans/2026-08-23-p2-m0-pi-evidence.md` | 本计划文件（已写） |

- forbiddenFiles：lib/ data/ test/ GDD.md CLAUDE.md PROGRESS.md docs/ 下其余文件、assets/、pubspec* —— 一律不碰
- rejectedRegistryCheck：已读 `docs/spec/rejected_task_registry.md`；五项决策均不在已否清单内，无冲突

## frozenContracts（只读引用，不新增）

- 方案 §0.2 五列决策表语义（FROZEN / IMPLEMENTATION-GAP 状态按方案原样引用，不擅自改判）
- 现有生产合同：`Phase0aWaveTransitionPolicy` / `SaveData.founderCharacterId` / `InnerDemonFailurePenalty.mainCultivationMultiplier` / 远征单 active run 守卫

## 实施切片与证据要点（已完成）

1. **COMBAT-WAVE-CD-01**：`numbers.yaml:1868/1905` preserve_cooldowns:false → def(`mainline_wave_def.dart:155`/`mass_battle_def.dart:201`) → mapper `:172/:448` `resetSkillCooldowns:!preserveCooldowns` → `wave_battle_flow.dart:196-211` 换波清零；间歇自然推进未实现（同拍完成，无间歇拍）
2. **EXP-CONCURRENCY-01**：`expedition_service.dart:105-108` 二次 dispatch 抛错 + `:562-570` `_activeRun` 每存档最多一条 → 与 FROZEN 一致，无缺口
3. **MAINLINE-PARTICIPANT-01**：三宿主（`phase0a_mainline_battle_host.dart:154-163` / `phase0a_tower_battle_host.dart:121-130` / `phase0a_sweep_headless_runner.dart:109-118`）null → `findFirst()` 静默回退；传位改写 `ascend_service.dart:297`；悬空 ID 由 `player_combatant_snapshot_assembler.dart:47-58` fail closed
4. **INNER-DEMON-FAILURE-CORE-01**：永久内力不扣 ✅（`inner_demon_service.dart:76-106`）、紊乱 ✅（`inner_breath_disorder.dart` + `numbers.yaml:55-62`）、**伤势仍施加** ⚠（`combat_resolution_service.dart:265-280` + `stage_entry_flow.dart:930` isHardFight=isBossStage=true）
5. **INNER-DEMON-LEGACY-01**：`numbers.yaml:1751-1754` 死字段（internal_force_multiplier/floor_pct 等 5 字段，0 生产读方实测）+ `inner_demon_service.dart:10/66-74` 旧注释 + 测试名/断言残留

## 当前恢复点

- 状态：**已完成**
- 最后完成：两份交付文件已写入；证据链全部经 read/grep 实测（含行号）
- 验证：`git diff --check`、文件白名单、工作树 clean 与 READY tip 均已核验
- 下一步：由 Codex 集成主审合入候选整合分支，不直接改 `main`
- 已跑验证：全部只读（grep/read/git log/status），未运行任何测试
- 阻塞项：无

## targetedCommands（仅验收/证据复现，本任务不跑测试）

- 复现命令见证据包 §7 附录（grep 一行式）
- 未来实现任务的 targeted 建议已逐项写入证据包 §1.5/§3.5/§4.5/§5.5（不在此执行）

## redlineImpact / saveMigrationImpact

- 红线影响：零（未改任何数值/配置/代码）
- 存档影响：零（未触碰 schema / saveVersion / 迁移）
- 在线=离线 / 三系锁死：零影响

## handoffEvidence / residualRisks

- 交付证据：本计划 + 证据包（五列：current behavior / 精确路径与符号 / 现有测试 / 差距 / 建议 owner 与 targeted 命令）
- 残留风险：① 心魔伤势事实（INNER-DEMON-FAILURE-CORE-01）未被方案证据列记录，G0 处理时必须纳入；② `game_repository_test.dart:529` 会反向锁死群战 preserve_cooldowns=false，配置翻转需同步；③ 三宿主回退删除须同步，防行为漂移

## stopConditions / escalationQuestion

- 用户拍板前不实现任何差距修复；`PROPOSED`（主修修炼度扣减、重打/扫荡参与者）不推断实现
- 升级问题：无（本任务只读证据，无待拍板项）

## READY tip

- tip commit message 前缀：`[READY][PI][P2-M0] 完成实现差距证据包`（追加空 commit）
- 工作区干净（全部改动已 commit）
