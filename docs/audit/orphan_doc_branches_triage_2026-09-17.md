# 孤立文档类分支价值评估（2026-09-17）

本次对台账范围的 **21 条本地分支**完成 Git 元数据实测；逐分支独有提交数合计 **42**（同一提交可能出现在多条分支，不能把此合计解释成去重提交数）。链基线固定为 `c307b3ffcb155af58d4efb9179e36453297b1360`，本次 `origin/codex/p2-player-flow-20260910` 解析为同一 SHA。所有判断为只读建议，没有 cherry-pick、打标签、删分支、运行游戏或读取真实存档。

## 范围与复核命令

台账 `docs/audit/worktree_ledger_2026-09-16.md` 的文档类原表 23 条；按末节执行记录，排除 `codex/tower-multi-recon-20260912`（目录已移除，分支未丢）及 locked 的 `worktree-review-followup-20260912`，得到 21 条。**“文档类”是旧台账对残余价值的称呼，不保证 merge-base 差异只有 Markdown**：下列文件清单原样列出 lib/data/test，不能据旧分类整支合入。

```sh
C=c307b3ffcb155af58d4efb9179e36453297b1360
python3 tools/audit/orphan_doc_branches_triage.py
python3 tools/audit/orphan_doc_branches_triage.py --chain "$C"
# 以下 B 替换为逐条章节的完整分支名；命令均只读。
B=codex/p2-defense-vfx-fix-20260827
git rev-parse "$B"
git rev-list --count origin/codex/p2-player-flow-20260910.."$B"
git merge-base "$C" "$B"
git diff --name-only "$(git merge-base "$C" "$B")..$B"
git log --reverse --format='%H %s' "$C..$B"
git cherry "$C" "$B"
git merge-base --is-ancestor "$B" "$C"
```

脚本仅标准输出 JSON，不写缓存/文件、不执行分支工具。表中独有提交采用 rev-list 的拓扑差异；`git cherry` 的 `+/-` 是非空补丁差异，空提交可使二者总数不同。21 条 tip 对链 `is-ancestor` 本次均为退出码 **1**；这不等于所有内容都未集成。每个 `file:line` 无另注均指固定链 SHA；旧报告内容通过 `git show <分支>:<路径>` 阅读。历史测试/CI/截图数字只作为原结论的审查对象，不被转录为本轮实测通过。

## 逐分支结果

### 01. `codex/c2-fragment-economy-20260823`

- tip：`8fc409551da8be98c2dba8294724522337fe1801`；tip 原文：`[READY] add fragment economy diagnostic evidence`。
- merge-base：`444612881d3372dc28eb29764c7feea300b9aa92`；独有提交 **1**；patch-id 等价 **0** / 独有非空补丁 **1**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `8fc409551da8be98c2dba8294724522337fe1801` [READY] add fragment economy diagnostic evidence

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `test/tools/output/phase0a_fragment_economy_diagnostic.csv` — 链内存在但不同 blob。
- `test/tools/output/phase0a_fragment_economy_diagnostic.md` — 链内存在但不同 blob。
- `test/tools/phase0a_fragment_economy_diagnostic_test.dart` — 链内存在但不同 blob。

核心结论复核：

原结论是残页阈值、掉落概率及固定随机种子的经济模拟；本次确认参数仍为 5 / 0.20（`data/numbers.yaml:2155-2156`，命令 `git grep -n -E 'fragment_threshold:|tower_fragment_drop_prob:' "$C" -- data/numbers.yaml`，2 行）。这只支持配置参数未变；历史 Monte Carlo 分位数没有在当前生产仓储重跑，**未能判定**其整表仍成立。分支三文件在链上均已有不同 blob 的后续版本；`git diff codex/c2-fragment-economy-20260823 "$C" -- test/tools/phase0a_fragment_economy_diagnostic_test.dart test/tools/output/phase0a_fragment_economy_diagnostic.md` 可复核链内版本改了采样方案，并新增集合总胜场与轮数的单位区分，旧输出已被更完整版本替代。该工具是会写 CSV/MD 的 Dart 测试，未执行、未生成 pub 前置，不能标“可直接运行”。

建议：**打归档标签后删**；保留历史经济采样与测试脚本，避免把旧输出当成本轮生产验收。

### 02. `codex/phase2-m5-r01-inner-demon-cultivation-penalty-removal-20260824`

- tip：`83755eb597bf4f8315f86e2ad9eeac9f0b4ec254`；tip 原文：`[READY][PI][P2-M5-R01] 冻结心魔修炼度惩罚移除`。
- merge-base：`f1dc0c9efd0a4548b31a3531e7332b91a1febbd4`；独有提交 **7**；patch-id 等价 **3** / 独有非空补丁 **4**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `dcbd9945b3b505e0c9d58ad9375a6e465af10408` 登记心魔惩罚移除设计证据
- `8c0d8db975e3a3310e0c702b4c0f3d7436937c0f` 冻结心魔修炼度不变红测
- `80f9a7b86ed7430df9c8060c2cfb531325a3ed93` [schema] 移除心魔主修修炼度失败惩罚
- `d4eca252d7ebd89d48e1b4a34bbb025774380db2` 记录心魔惩罚移除绿测证据
- `82f07ab737fb57a787ecc4229d4180e2c4d6532c` 记录心魔惩罚移除终审结论
- `8a8f68ddc1be1bcdc91190e392bbee310fa6fd11` 闭合心魔惩罚移除交付证据
- `83755eb597bf4f8315f86e2ad9eeac9f0b4ec254` [READY][PI][P2-M5-R01] 冻结心魔修炼度惩罚移除

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `data/numbers.yaml` — 链内存在但不同 blob。
- `docs/superpowers/plans/2026-08-24-p2-m5-r01-inner-demon-cultivation-penalty-removal.md` — 链内存在但不同 blob。
- `lib/data/defs/inner_demon_def.dart` — 链内同 blob。
- `lib/features/combat_shared/application/combat_resolution_service.dart` — 链内存在但不同 blob。
- `lib/features/inner_demon/application/inner_demon_service.dart` — 链内同 blob。
- `test/data/inner_demon_dead_config_test.dart` — 链内同 blob。
- `test/features/inner_demon/application/inner_demon_failure_penalty_test.dart` — 链内同 blob。
- `test/features/inner_demon/application/inner_demon_failure_resolution_test.dart` — 链内存在但不同 blob。
- `test/features/inner_demon/application/inner_demon_service_test.dart` — 链内同 blob。
- `test/features/inner_demon/domain/inner_demon_def_test.dart` — 链内同 blob。
- `test/features/inner_demon/domain/inner_demon_panel_test.dart` — 链内同 blob。
- `test/features/inner_demon/domain/inner_demon_progress_test.dart` — 链内同 blob。

核心结论复核：

核心结论“心魔失败不扣主修，旧 failure_penalty 键拒绝”仍成立：`lib/features/inner_demon/application/inner_demon_service.dart:74-94` 只调用 `InnerBreathDisorder.apply`，`progressAfter: progressBefore`；`lib/data/defs/inner_demon_def.dart:83-86` 拒绝旧键；`lib/features/combat_shared/application/combat_resolution_service.dart:253` 仍有生产调用。`git cherry "$C" <分支>` 实测 3 个等价补丁、4 个独有非空补丁；8/12 个变动文件 blob 与链完全相同。独有部分以计划/评审证据为主，原绿测数量未重跑、不转录为本轮通过。

建议：**打归档标签后删**；实现已经有链内对应物，保留原签字/评审及失败边界的考古价值。

### 03. `codex/phase2-governance-integration-20260825`

- tip：`503d1ad3f2c1f845027b48fb9cdc940d9147b3ff`；tip 原文：`[READY][CODEX][P2-GOVERNANCE-INTEGRATION] 整合二阶段结果驱动规则`。
- merge-base：`8671f8920a9e2ef3cd7bf869a047808d0fd742b1`；独有提交 **2**；patch-id 等价 **0** / 独有非空补丁 **2**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `92444546cab414c2d0f4602ac99d2a1a3f6a6700` 整合二阶段结果驱动门禁
- `503d1ad3f2c1f845027b48fb9cdc940d9147b3ff` [READY][CODEX][P2-GOVERNANCE-INTEGRATION] 整合二阶段结果驱动规则

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `CLAUDE.md` — 链内存在但不同 blob。
- `PROGRESS.md` — 链内存在但不同 blob。
- `docs/dispatch/phase0a_overhaul/task_registry.yaml` — 链内存在但不同 blob。
- `docs/superpowers/plans/2026-08-25-phase2-governance-integration.md` — 链内不存在。

核心结论复核：

核心规则已被链吸收：`CLAUDE.md:493-502` 有固定分母、一个权威 Gate、四项证据、孤立集成债/main 发布债、真实墙钟与无人值守约束；`PROGRESS.md:6,14,18` 按当前候选、正式 1/10 与待处理分支分类报告。旧计划要求的“四项测量”名称与当前规则不完全同字，但不能因此判治理缺失。原分支独有提交同时改 CLAUDE、PROGRESS、登记簿，不适合整体回放到今天。

建议：**打归档标签后删**；治理意图已有当前文本，旧仪表盘和登记簿快照会覆盖后续事实。

### 04. `codex/p2-defense-break-reachability-20260826`

- tip：`39ae8f83564f413566df0178c8777520869f6c39`；tip 原文：`[BLOCKED] 钉住破防技可达崩溃`。
- merge-base：`e4f0f1713023dba97c08b4d1e9843100e9e9a535`；独有提交 **1**；patch-id 等价 **0** / 独有非空补丁 **1**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `39ae8f83564f413566df0178c8777520869f6c39` [BLOCKED] 钉住破防技可达崩溃

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `docs/audit/phase2_defense_break_reachability_20260826.md` — 链内不存在。
- `test/features/battle/application/phase0a/phase0a_defense_break_reachability_test.dart` — 链内不存在。

核心结论复核：

“真实破防技能进入数字槽即崩溃”已由 `c0d6df8d8dc6d37639223c1c46cf70cee9ed455b` 接通姿态消费替代。当前 `phase0a_numeric_skill_binding.dart:44` 仅在缺消费授权时拒绝；`phase0a_stage_content_mapper.dart:1081,1235` 明传 `consumesDefenseBreakAsPostureDamage: true`，`:1036` 计算姿态伤害，reducer `:210,974` 消费。原诊断测试不在当前链，不能建议把“期待旧崩溃”的用例原样并入。

建议：**打归档标签后删**；保留故障定位来源，当前故障结论已过时。

### 05. `codex/p2-n4-falsegreen-20260826`

- tip：`57fb6416f0dd86170cbf981ce6a5a1ea25c844f6`；tip 原文：`[READY] 完成测试假绿审计`。
- merge-base：`6ab440260318100032e484c904cad9f46c4ca6c1`；独有提交 **1**；patch-id 等价 **0** / 独有非空补丁 **1**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `57fb6416f0dd86170cbf981ce6a5a1ea25c844f6` [READY] 完成测试假绿审计

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `docs/audit/phase2_test_false_green_audit_20260826.md` — 链内不存在。

核心结论复核：

旧假绿报告的扫描分母与问题清单不能当今日计数。本次 `git ls-files test` 重数为 1014 文件 / 976 Dart；旧报告逐 23 个表行所指文件比较分支与链 blob，11 行同 blob、12 行变化、0 缺失，**这不是 11 个现存缺陷的判定**。明确变化：`ch1_production_catalog_test.dart:80-83` 预算已改为 1/1/1/1，`:105` 起校验总数；`mainline_all_mode_consistency_test.dart:271-285,357-383` 已实点生产 UI/headless 入口，原“仅源码匹配”的概括过时。仍有可定位的静态形态：`encounter_objective_test.dart:219` 自我比较 `expect(first.initialProgress, first.initialProgress)`；`combat_progression_settlement_wiring_contract_test.dart:12-27`、`disciple_scheduling_production_route_test.dart:11-15`、`recruitment_dialog_visual_contract_test.dart:7-15` 仍有源码 contains；`phase0a_guardian_coop_test.dart:234` 仍用 maxHp:200000。未执行 mutation，因此**未能判定**旧 23 项今天有多少仍会放过真实缺陷。

复核：`git show codex/p2-n4-falsegreen-20260826:docs/audit/phase2_test_false_green_audit_20260826.md`；`git grep -n -F 'expect(first.initialProgress, first.initialProgress)' "$C" -- test`；`git log "$C" -S 'expect(encounter.tokenBudgets.melee, 1)' -- test/data/phase2/ch1_production_catalog_test.dart`。相关 `9967c8959090e03abcd59d820b25831bc71e3407`、`50777d14e3fc1c7ff31f8f14621dfd11d34026e9` 已为链祖先。

建议：**打归档标签后删**；旧测试审查仍有线索价值，今日清单必须区分已补强与尚需证红的条目。

### 06. `codex/p2-n5-ci-20260826`

- tip：`fa6e7ad0d387dc3f928bc76ca0be2e9b59a42684`；tip 原文：`[READY] 记录CI健康度实测`。
- merge-base：`6ab440260318100032e484c904cad9f46c4ca6c1`；独有提交 **1**；patch-id 等价 **0** / 独有非空补丁 **1**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `fa6e7ad0d387dc3f928bc76ca0be2e9b59a42684` [READY] 记录CI健康度实测

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `docs/audit/ci_health_20260826.md` — 链内不存在。

核心结论复核：

旧“main 落后巨大、最新 Windows 红”的时间性结论已过时。本次本地 `origin/main` 解析为 `342d1927529b8306582431be597ef1975bd69deb`；`git rev-list --count origin/main.."$C"` 为 39。现场 `gh run list --repo Zed1118/wuxia_idle --limit 5 --json databaseId,workflowName,headBranch,conclusion,headSha,status,createdAt` 的最近 5 条均 completed/success，最新 run `34973784383` 对应 `5c1105cfa8ee38c0eea7777f0bd7bf42a30f164b`（2026-09-15T13:15:00Z）；又经 `gh run view 34973784383 --repo Zed1118/wuxia_idle --json conclusion,headSha,status` 精确复核。**该成功不证明 c307 链 tip 的 CI 成功**：按下面 head_sha 查询总数为 0。

```sh
gh api 'repos/Zed1118/wuxia_idle/actions/runs?head_sha=c307b3ffcb155af58d4efb9179e36453297b1360&per_page=5' --jq '{total_count: .total_count, runs: [.workflow_runs[] | {id,head_sha,conclusion,status}]}'
```

输出为 `total_count: 0`、`runs: []`。当前 `.github/workflows/windows-release.yml:48-49` 分析范围已限定 lib/test/tool，不再由该命令直接扫旧 tools/phase0minus_probe；Flutter 固定版本仍为 3.41.5（ci.yml `:41`、windows-release.yml `:35`）。本轮没有运行本地 Flutter，因此“本地与 CI 完全一致”**未能判定**。远端结果是本次观察时间的快照，未来重跑可以变化。

建议：**打归档标签后删**；保留历史 CI 故障原始记录，不用旧最新 run 判断今日健康度。

### 07. `codex/p2-spec-reality-audit-20260826`

- tip：`0ec0280a02e0422106be9dba3bbd70d58e78f127`；tip 原文：`核对二阶段方案生产偏差 [READY]`。
- merge-base：`0378df73b88f011d4a686e4ec63f1b92f6771330`；独有提交 **1**；patch-id 等价 **0** / 独有非空补丁 **1**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `0ec0280a02e0422106be9dba3bbd70d58e78f127` 核对二阶段方案生产偏差 [READY]

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `docs/audit/phase2_spec_reality_audit_20260826.md` — 链内不存在。

核心结论复核：

旧报告的汇总数字属于 `0378df73`，本次没有重做原方案全部断言的独立划组，故“完整汇总仍成立”**未能判定**；禁止继续把旧总数当当前欠债。关键前提已实测失效：`stage_assignments.yaml` 中 `migration_state: migrated` 为 105 行，manifest `archetype_sources` 为 6 个来源；`EquipmentDef` 已有 `weaponArchetype`，reducer 已消费 `ActionTimeline`，姿态接线也已存在。听剑比例仍为 tuning、六槽旧字段仍有残留，不能把报告整体改判“全修完”。逐项核心方向见附录 A。

建议：**打归档标签后删**；本报告保留复核索引，原大表需要重审后才能成为当前派单依据。

### 08. `codex/p2-token-candidate-rerun-20260826`

- tip：`bae8f89b6ac8e682a540d4249e65f8e68184b860`；tip 原文：`并入探针工具格式化基线`。
- merge-base：`db2a1e6655aebbe54f3b4f289728ac4141e8a130`；独有提交 **2**；patch-id 等价 **0** / 独有非空补丁 **1**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `af326685f6bf0e7f67c8469938055e54f366335d` [BLOCKED] 固化攻击令牌候选证据
- `bae8f89b6ac8e682a540d4249e65f8e68184b860` 并入探针工具格式化基线

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `docs/spec/phase2_token_budget_candidates_le4_20260826.md` — 链内不存在。
- `docs/superpowers/plans/2026-08-26-p2-token-budget-candidates-le4.md` — 链内不存在。
- `test/tuning/phase2_combat_core_tuning_candidates_test.dart` — 链内存在但不同 blob。

核心结论复核：

旧台架推荐 `2/1/1/0`，当前生产采用 `1/1/1/1`：`data/combat/encounters/black_wind_ridge.yaml:3-6,14-18` 明记选择候选 A、仍为 TUNING。`d1a5864c1f0fd6e7914a7a6115ae9b3242f97832` 是链上撤回“双方查无实据”错判的后续记录。总预算为 4，可由四行现值求和；不能把旧推荐解释成被批准方案。旧 65 组 Dart 台架未执行，分位数/授予率在当前内核是否重现**未能判定**。

建议：**打归档标签后删**；保留被比较过的候选及其代价，不把非选中候选重新并入生产守卫。

### 09. `codex/p2-b1-vfx-short-circuit-audit-20260827`

- tip：`22e67d9256c311f06d238722b5a9bc6ce9148d96`；tip 原文：`[READY] 完成VFX同类短路核查`。
- merge-base：`aed517e964aa6ae89f9594929a2bb8c2c2a1e187`；独有提交 **2**；patch-id 等价 **1** / 独有非空补丁 **1**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `eb2909fbace19ad29cdb5b6749ba00c315234b2a` [READY] 修复防御特效零像素渲染
- `22e67d9256c311f06d238722b5a9bc6ce9148d96` [READY] 完成VFX同类短路核查

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `docs/audit/p2_batch1_vfx_short_circuit_audit_20260827.md` — 链内不存在。
- `lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart` — 链内存在但不同 blob。
- `test/features/battle/presentation/phase0a/phase0a_defense_presentation_test.dart` — 链内存在但不同 blob。

核心结论复核：

原“gatherPull 三字段不是恒空”在当前静态路径仍成立：controller `phase0a_vfx_controller.dart:433-445` 在 source/target 缺失时跳过，否则同时写 targetId/source/vfxTarget；screen `:3049-3055` 读取相同三字段。guardian 两端仍由事件坐标传入（controller `:531-547`），palm/ink 的视觉强度与实际像素本轮没有 GUI 复验，不能外推原 PASS 为今日全 VFX 验收。依赖的零像素修复 `eb2909fba` 对链 patch-id 等价；链内对应为 `2f554d54038a68f7b7adca26f7357a6196eca404`，screen `:2694-2709` 仍走 banner。

建议：**打归档标签后删**；当前保留静态合同，旧报告的视觉和绿测结论仅有历史价值。

### 10. `codex/p2-backlog-scan-20260826`

- tip：`8d704d2740f04b1e1eb8878dc5d5dc7c2344a7e7`；tip 原文：`[READY] 提交BACKLOG补给扫描提案`。
- merge-base：`07f175e0f68b71e8082ab1421c479d0a3eeabb6a`；独有提交 **1**；patch-id 等价 **0** / 独有非空补丁 **1**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `8d704d2740f04b1e1eb8878dc5d5dc7c2344a7e7` [READY] 提交BACKLOG补给扫描提案

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `docs/audit/backlog_replenish_proposal_20260826.md` — 链内不存在。

核心结论复核：

旧补给菜单已有多项过期：U01 的总令牌 6 已变为 4（black_wind_ridge `:14-18`）；U04 的历史分叉分类已有台账执行记录；D02/D03 的 durable 自动化已有 `DurableActivityAutomationPolicy`（`lib/features/activity/domain/durable_activity_automation_policy.dart:99-102`）、service/coordinator/UI；D04 已有 `RewardClaimReceipt` 与 `DurableRewardClaimService`；M3/M7 生产内容也已经推进。P01 权重仍待批准（CLAUDE `:493`），D06 听剑比例仍 tuning（decision registry `:309-317`），M8/M9 仍有正式验收缺口（PROGRESS `:14`）。其余跨系统经济、字体许可及招募决策未复跑/未查原批准会话，**未能判定**；原三类合计不得沿用。

建议：**打归档标签后删**；旧依赖菜单含已经解除的前置和仍开放的决策，整表入链会重复派单。

### 11. `codex/p2-defense-vfx-fix-20260827`

- tip：`f16c09efcc7d26c163de52b700a087da1c626d29`；tip 原文：`[READY] 消除防御测试删除误报`。
- merge-base：`aed517e964aa6ae89f9594929a2bb8c2c2a1e187`；独有提交 **2**；patch-id 等价 **1** / 独有非空补丁 **1**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `eb2909fbace19ad29cdb5b6749ba00c315234b2a` [READY] 修复防御特效零像素渲染
- `f16c09efcc7d26c163de52b700a087da1c626d29` [READY] 消除防御测试删除误报

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `lib/features/battle/presentation/phase0a/phase0a_battle_screen.dart` — 链内存在但不同 blob。
- `test/features/battle/presentation/phase0a/phase0a_defense_presentation_test.dart` — 链内存在但不同 blob。

核心结论复核：

底层防御 banner 修复 `eb2909fba` 已按 patch-id 进入链。独有 `f16c09efcc7d26c163de52b700a087da1c626d29` 只把 `defense_resolution.dart` 的 import 移动两行，`git show --format= --stat f16c09efc` 与完整 diff 可复核：无断言/行为增删。当前 `phase0a_defense_presentation_test.dart:171,182` 仍检查 start/resolved banner，screen `:2694-2709` 实现仍在。所称“测试删除误报”是差异顺序而非尚缺生产修复。

建议：**直接删**；唯一非等价残差是无语义 import 顺序，所依赖的生产修复已保存于链内。只提出建议，本单不删除分支。

### 12. `codex/p2-density-fx-evidence-20260827`

- tip：`94a93293c2d3d3c98c281e7a1b70c2af313e79e0`；tip 原文：`[BLOCKED] 固化密度视效阻塞验收`。
- merge-base：`5440f931bebfc9245a162bb97a8f76c29443f844`；独有提交 **2**；patch-id 等价 **0** / 独有非空补丁 **2**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `f8eca675083d647601bc356a1d0180939dd30357` [BLOCKED] 记录密度视效生产前置缺口
- `94a93293c2d3d3c98c281e7a1b70c2af313e79e0` [BLOCKED] 固化密度视效阻塞验收

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `docs/audit/phase2_density_fx_evidence_20260827.md` — 链内不存在。
- `docs/superpowers/plans/2026-08-27-n15-density-fx-evidence.md` — 链内不存在。
- `test/features/battle/application/phase0a/phase2_density_fx_evidence_test.dart` — 链内不存在。

核心结论复核：

原“reduceFlashing 只存在设置页、战斗零消费”已过时：`phase0a_mainline_battle_host.dart:358,387` 读取并传入，`phase0a_battle_screen.dart:1729` 消费；链上 `1158548fa5faf9a95b1df6f70ed073d0dcb5364e` 接线。原另一核心前提“独立高/低特效密度设置缺失”仍可复核：`git grep -n -E 'EffectDensity|effectDensity|VfxDensity|vfxDensity|lowEffects|lowEffectDensity' "$C" -- lib` 为 0 行/退出 1。减少闪光不等于高低密度设置。原四格测试含 skip，不在本轮执行；塔 14/群战密度和逐 tick parity 全矩阵未复跑，**未能判定**。不能继续使用原 `reduceFlashing=零消费` 作为阻塞理由。

建议：**打归档标签后删**；保留真实曾受阻的边界，今日应以生产矩阵和未齐验收项重写需求。

### 13. `codex/p2-claudemd-drift-20260826`

- tip：`be0e8582def944ad4644a01dd29249677aa5d85c`；tip 原文：`[BLOCKED] 核对 CLAUDE 文档漂移`。
- merge-base：`07f175e0f68b71e8082ab1421c479d0a3eeabb6a`；独有提交 **1**；patch-id 等价 **0** / 独有非空补丁 **1**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `be0e8582def944ad4644a01dd29249677aa5d85c` [BLOCKED] 核对 CLAUDE 文档漂移

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `docs/audit/claude_md_drift_20260826.md` — 链内不存在。

核心结论复核：

旧正文 drift 不是全过时：`CLAUDE.md:229,258,305,314,523,557,570,572-575` 仍含迁位路径、旧枚举、旧 Boss 层、旧战斗核与固定标价描述。关键更正是 QiCycle：`git grep -n -E 'QiCycle.effectiveSkillDelta|QiCycle.schoolBonus' "$C" -- lib` 本次为 1 行，mapper `:1152` 已消费 effectiveSkillDelta；因此旧“两个均零消费”的总括已错，schoolBonus 精确调用仍 0。四个遗物字段排除 parser 后仍 0 行；内伤 `BattleState/internalInjurySlot` 旧符号仍 0，但当前 adapter `:260` 已读取 `appliedEffects`，不能据旧类型消失判断阴柔内伤今天仍未接线。更多逐项复核见附录 B。未将文档冲突推断为应该改数值或改代码。

建议：**打归档标签后删**；本次已保留可操作的当前定位，原行号与部分未消费断言已漂移。

### 14. `codex/p2-milestone-facts-20260826`

- tip：`d56b214a8d0413e35ae6ec178d990ffb1e305928`；tip 原文：`[READY] 对账G0决策签字与实况`。
- merge-base：`07f175e0f68b71e8082ab1421c479d0a3eeabb6a`；独有提交 **1**；patch-id 等价 **0** / 独有非空补丁 **1**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `d56b214a8d0413e35ae6ec178d990ffb1e305928` [READY] 对账G0决策签字与实况

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `docs/audit/g0_decision_reconciliation_20260826.md` — 链内不存在。

核心结论复核：

当前登记簿仍列 `MENTOR-INSIGHT-RATE-01` 为 `rate_status: tuning`、`production_change_authorized: false`（`:309-317`），`INNER-DEMON-AI-01` 仍有 `keep_existing_ai`（`:351-362`）；`INNER-DEMON-LEGACY-01` 精确检索仍 0。心魔旧键拒绝/不扣修炼度的代码事实仍成立（第 2 条）。旧表将原始用户会话作为批准来源，这些外部会话本单没有重新读取，**未能判定**“全体批准依据已完整核验”仍适用于新增后续决策；也不能从实现反推用户签字。当前 M0 正式门仍未关闭，故旧“不阻塞某些工程启动”不能改写成 M0 PASS。

建议：**打归档标签后删**；保留原会话锚点的历史价值，当前批准状态应继续由权威登记簿与原会话复核。

### 15. `codex/p2-mutation-probe-20260826`

- tip：`e9a3aa8a2d79907763bbf8c1c20a44a4733b870a`；tip 原文：`[READY] 完成变异测试探针首轮跑批`。
- merge-base：`07f175e0f68b71e8082ab1421c479d0a3eeabb6a`；独有提交 **3**；patch-id 等价 **0** / 独有非空补丁 **3**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `3287391711995b4f29151c4e24dd06b4b9bc4e67` 建设变异测试探针
- `1d5c6bba0d564b5559e84129d95cb1deead4acd6` 修正变异超时清理
- `e9a3aa8a2d79907763bbf8c1c20a44a4733b870a` [READY] 完成变异测试探针首轮跑批

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `docs/audit/mutation_probe_round1_20260826.md` — 链内不存在。
- `tools/mutation/README.md` — 链内不存在。
- `tools/mutation/mutation_probe.py` — 链内不存在。
- `tools/mutation/test_mutation_probe.py` — 链内不存在。

核心结论复核：

工具具有可复用价值，但旧测试数量与候选数不能沿用。独立复核从精确分支 Git blob 载入 Python 模块，内存执行 `main(['--root','.','map'])` / `main(['--root','.','list'])` 均退出 0；只读取当前链文件。当前静态映射为 reducer 347 / screen 135 个 suite，候选 2383 = reducer 715 + screen 1668；这是可枚举性，不是变异杀伤率。没有执行 test/run，也没有写 lib。旧报告引用的 `/tmp/n11-mutation-round1-20260826.json` 本次不存在，旧幸存/击杀结论及当前完整 run 兼容性**未能判定**。

分支工具 `tools/mutation/mutation_probe.py:627-655` 为 map/list 分支，`:669` 起 run 会写目标，本轮未进入；README 的中断恢复仍建议 `git checkout -- lib/...`，可能清掉用户未提交修改，与当前保全纪律冲突，不能原样作为推荐操作带入。只读复跑核心（标准输出较长，可在内存汇总）：

```python
import subprocess, sys, types
source = subprocess.check_output(['git', 'show', 'codex/p2-mutation-probe-20260826:tools/mutation/mutation_probe.py'], text=True)
module = types.ModuleType('readonly_mutation_probe')
sys.modules[module.__name__] = module
exec(compile(source, 'git-blob', 'exec'), module.__dict__)
module.main(['--root', '.', 'map'])
module.main(['--root', '.', 'list'])
```

建议：**打归档标签后删**；工具保留复用价值，下一次真要引入时单独选取工具、订正恢复流程并按新基线校验。

### 16. `codex/p2-n6-deadfield-20260826`

- tip：`766549115d8e05d29c8c0414031c77635588750a`；tip 原文：`[READY] 清点死字段与零引用资产`。
- merge-base：`6ab440260318100032e484c904cad9f46c4ca6c1`；独有提交 **1**；patch-id 等价 **0** / 独有非空补丁 **1**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `766549115d8e05d29c8c0414031c77635588750a` [READY] 清点死字段与零引用资产

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `docs/audit/phase2_dead_field_audit_20260826.md` — 链内不存在。

核心结论复核：

旧“死字段/零引用”整表已有部分反例：`ActionTimeline` 已在 reducer `:635,642,676,1040` 消费（含 cooldownRemainingTicks）；`totalPassiveMojianshi/Experience` 在 `expedition_timeline.dart:189,191` 做生产差分，`isar_missing_field_defaults.dart:573-578` 也迁移读取。因此旧“仅 test/tuning”标签不可全部沿用。本次 tracked data YAML 709 个；assets 排除 .gitkeep/README 为 697 个。资产数恰与旧文相同，不等于旧引用分析仍有效。

仍成立的窄事实：`rg -n daily_attempts lib`、`rg -n refresh_at lib` 各 0 命中/退出 1；定义在 `data/numbers.yaml:1496-1497`，UNUSED 段注释在 `:1488`。旧六个 PNG `assets/enemies/{shiye,fu_zhaizhu,shidi_b,killer_a,killer_b,wulin_bazhu}.png` 都存在，对每条完整路径在 lib/data 精确搜索均 0；没有据此排除动态拼接，所以不能直接授权删除。其余逐字段动态接线总量没有完整重审，**未能判定**今日精确死字段总数；numbers 反向引用由本夜 B-2 的独立实测清单负责。

建议：**打归档标签后删**；保留历史线索，避免“已有生产消费”的字段被旧清单误删。

### 17. `codex/p2-leftover-pool-20260826`

- tip：`258b3e8ef1f384915be2c73ac194ba6a63cabb63`；tip 原文：`[READY] 编制二阶段拍板菜单`。
- merge-base：`0378df73b88f011d4a686e4ec63f1b92f6771330`；独有提交 **3**；patch-id 等价 **0** / 独有非空补丁 **3**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `0ec0280a02e0422106be9dba3bbd70d58e78f127` 核对二阶段方案生产偏差 [READY]
- `f1e645f021e1548a61f8cb77a1cf50f5a3c33ea8` [READY] 整理二阶段遗留任务池提案
- `258b3e8ef1f384915be2c73ac194ba6a63cabb63` [READY] 编制二阶段拍板菜单

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `docs/audit/phase2_spec_reality_audit_20260826.md` — 链内不存在。
- `docs/dispatch/pool/phase2_decision_menu.md` — 链内不存在。
- `docs/dispatch/pool/phase2_leftover_pool_proposal.md` — 链内不存在。
- `docs/superpowers/plans/2026-08-27-n13-phase2-decision-menu.md` — 链内不存在。

核心结论复核：

这条包含第 7 条同一 N2 审计及其派单池、拍板菜单。旧菜单的生态、密度、武器、三态解锁等多条前置已经有后续实现；当前主线配置为 105 migrated、6 生态；weaponArchetype 存在；`ProgressiveUnlockState.heard/open` 已进入地图。旧菜单仍把部分方向列为待拍，不能恢复成当前授权清单。其关于“一套装配/独立活动摘要不得凭旧方案重开”的边界仍需尊重（`docs/spec/rejected_task_registry.md` 的既有约束）。整张图的解锁计数未按当前依赖重算，**未能判定**，不能沿用旧排名。

建议：**打归档标签后删**；保留历史依赖推导，今天的依赖与决策序列已改变。

### 18. `codex/p2-d1-input-blocker-diagnosis-20260828`

- tip：`6884cb4c45b1cf104bc4a1acab839a5eb9eba5a4`；tip 原文：`[BLOCKED] 冻结试玩输入诊断交付`。
- merge-base：`1ba913a633beb0fd8f9b47764161f47c54260707`；独有提交 **4**；patch-id 等价 **2** / 独有非空补丁 **2**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `5d9b70a767c8175c1abe917c37c942031c56d8a4` 记录试玩输入阻塞诊断
- `b83c4cd401d2cf96f617a62b6977e4365e267bb2` [BLOCKED] 标记试玩输入诊断受阻
- `bffeb62a3436480eaf6450f502311f79d0e844e8` 更新输入诊断收工状态
- `6884cb4c45b1cf104bc4a1acab839a5eb9eba5a4` [BLOCKED] 冻结试玩输入诊断交付

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `docs/audit/playtest_input_blocker_diagnosis_20260828.md` — 链内不存在。
- `docs/superpowers/plans/2026-08-28-playtest-input-blocker-diagnosis.md` — 链内不存在。

核心结论复核：

旧“在特定第 8 章样本不能复现输入全失效”的历史实验无法用静态检索升级为今日结论。当前持键路径仍可定位：screen `:675-678,1168,1215` 采样并维护 WASD，input adapter `:164` 发 `Phase0aMoveIntent`。这是代码接线存在证据，不证明某台真机焦点/旧存档根因已经解决；本单禁止启动 GUI/读写真档，因此真实现象**未能判定**。旧文记录的真档备份恢复和哈希仅属原轮，不在本轮重读或复核。

建议：**打归档标签后删**；保留特定样本的排除法和已披露限制，不能拿其历史 BLOCKED 推断当前可玩性。

### 19. `codex/p2-e1-visual-fail-triage-20260828`

- tip：`9f8f8c93e6d72ab7a890b90fc399a656ac52566f`；tip 原文：`[READY] 完成视觉验收失败分类`。
- merge-base：`1ba913a633beb0fd8f9b47764161f47c54260707`；独有提交 **2**；patch-id 等价 **1** / 独有非空补丁 **1**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `fbdb5d911ceabe0dd9e2fe87be2e61f779a07b4e` 核定视觉验收失败分类
- `9f8f8c93e6d72ab7a890b90fc399a656ac52566f` [READY] 完成视觉验收失败分类

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `docs/audit/visual_acceptance_fail_triage_20260828.md` — 链内不存在。

核心结论复核：

当前仍有可复核静态残留：screen `:1201-1208` 的 Esc 只切暂停，`:1453-1468` 是暂停 banner；未发现退出回调。心魔卡 `:294`、主页摘要 `:164`、奖励卡 `:241`、门派谱 `:375` 仍直接 InkWell。对旧报告 9 个主卡文件检索 `button: true` 共 2 行，位于主线叙事子按钮 `stage_list_screen.dart:1328` 与塔传闻子控件 `tower_floor_card.dart:351`，不能当主卡 role 已补。原“双视口真缺陷/判据误用”数量没有真机/semantics 树重跑，**未能判定**原 54 条计数仍精确成立；静态残留足够保留为待复核线索，但不能代签无障碍验收。

建议：**打归档标签后删**；用本轮定位继续审查，原视觉计数和行号不宜未经复测直接并入当前验收账。

### 20. `codex/p2-e2-playtest-capture-pipeline-20260828`

- tip：`ca09853b68661c8c0c4f247de1eeada2fe4ac171`；tip 原文：`[READY] 完成真机打局管线收工`。
- merge-base：`1ba913a633beb0fd8f9b47764161f47c54260707`；独有提交 **3**；patch-id 等价 **1** / 独有非空补丁 **2**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `b0ba6a046ae0e1ed7b90078244261bb1ca00ad71` 沉淀真机打局录屏管线
- `89cda04996ef343f66239da8355da8e521b07c2f` 记录真机管线收工证据
- `ca09853b68661c8c0c4f247de1eeada2fe4ac171` [READY] 完成真机打局管线收工

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `docs/superpowers/plans/2026-08-28-e2-playtest-capture-pipeline.md` — 链内不存在。
- `tools/playtest/cgevent_driver.swift` — 链内不存在。
- `tools/playtest/cgevent_driver_test.py` — 链内不存在。
- `tools/playtest/extract_keyframes.py` — 链内不存在。
- `tools/playtest/extract_keyframes_test.py` — 链内不存在。
- `tools/playtest/playtest_capture.sh` — 链内不存在。
- `tools/playtest/playtest_capture_test.sh` — 链内不存在。
- `tools/playtest/scenarios/stage_01_03.json` — 链内不存在。
- `tools/playtest/write_playtest_manifest.py` — 链内不存在。
- `tools/playtest/write_playtest_manifest_test.py` — 链内不存在。

核心结论复核：

原工具/首用例/三槽回填成功结论是 1ba913a6 的历史记录。当前链没有这批 tools/playtest 文件与场景，脚本元数据 `exists_on_chain=false` 可复核。本轮只读预检：精确 shell blob 的 `bash -n` 退出 0；五份 Python 源（extract_keyframes、write_playtest_manifest 与三测试）`ast.parse` 均通过。在内存只替换 shell 的 BASH_SOURCE 自定位到当前 worktree 后，`--help` 退出 0；`--dry-run --scenario tools/playtest/scenarios/stage_01_03.json --output /tmp/night-b-no-output --save-backup /tmp/night-b-nonexistent-fixture --save-dir /tmp/night-b-nonexistent-save` 退出 2，明确 `Scenario does not exist`，没有输出文件。故结论为：**语法/help 可用，链 tip 不能直接完成 dry-run；完整参数 dry-run 与当前 GUI 导航兼容性未能判定**。

源码边界：分支 `playtest_capture.sh:18` 默认真实容器目录；`:141-145` 即便 dry-run 也检查三槽备份，`:148-156` 才提前返回；`:210-227` 是三槽复制/比对，`:245` 结束应用，`:268` 读存档哈希，`:277` 启动游戏，`:337` 还原。场景仍是旧菜单坐标。此次没有拿真实备份补输入，没有执行录屏/启动/回填分支，也没有读取真实存档。读取语法的原始入口为 `git show codex/p2-e2-playtest-capture-pipeline-20260828:tools/playtest/playtest_capture.sh | bash -n`。

建议：**打归档标签后删**；保留工具与演示证据，后续应用前须先把存档与应用运行范围明确隔离并重验当前导航。

### 21. `codex/save-migration-verify-20260912`

- tip：`811caf4172f98add41bacbfcaf2772694822791d`；tip 原文：`验证旧档迁移并刷新进度摘要`。
- merge-base：`a48aab668d5fbf631c94a06e1a00baa41244de8b`；独有提交 **1**；patch-id 等价 **0** / 独有非空补丁 **1**；tip 非链祖先（退出 1）。

独有提交（旧到新，原始标题保留用于核对，不属于本单新 commit）：

- `811caf4172f98add41bacbfcaf2772694822791d` 验证旧档迁移并刷新进度摘要

merge-base 到分支 tip 的完整文件清单（“链内同 blob”只证明文件内容相同）：

- `PROGRESS.md` — 链内存在但不同 blob。

核心结论复核：

旧 PROGRESS 文档有独有的三槽副本迁移记录，但当前 `PROGRESS.md:13` 与 `docs/audit/save_migration_050_verification_2026-09-16.md` 已记录后续副本续验、`54aed6b51` 修复以及真实三档仍未由当前候选打开的边界。当前 `lib/data/isar_setup.dart:252` 版本是 0.50.0。原样 cherry-pick 会覆盖整个当前首屏，并重新引入“另线尚未集成”等过期状态。旧 26 集合/样本计数与 CI 本轮未重读原外部日志且未碰存档，**未能判定**其全部历史数字；不得称这次又验证了真实迁移。

建议：**打归档标签后删**；保留早期副本证据，当前链已有更新且更细的验收边界。

## 附录 A：旧 N2 表 39 个差异行的当前去向

此表对应第 7、17 条中的旧 N2 表行号，复核其核心事实方向；“有后续实现”只撤回旧“完全不存在”的判断，不自动宣告整个产品合同通过。原报告的断言分组数量没有重新计算。

| 旧行 | 当前判断 | 固定链证据 / 未能判定原因 |
|---:|---|---|
| 1 | 原“方案落后六几何”仍有依据 | `lib/features/battle/domain/phase0a/combat_geometry.dart:13` 定义六类；不据此声称各类均生产可达。 |
| 2 | 保留冷却事实仍在 | `data/numbers.yaml` 精确检索 `preserve_cooldowns: true`；不沿用旧测试通过数。 |
| 3 | 掌门失效拒绝仍在 | `lib/shared/battle_shared/current_leader_resolver.dart:9-25`。 |
| 4 | 心魔扣修炼度的旧说法已退役 | 第 2 条代码/配置键证据。 |
| 5 | 旧输入方案与实现仍不能直接等同 | screen `:1228-1240` 仍映射 R 与数字 1–6；本轮不做键鼠体验裁定。 |
| 6 | cooldownTurns 仍是解析字段 | `lib/data/defs/skill_def.dart:57,207`；不能写“YAML 只表达秒”。 |
| 7 | “时间线无 reducer”已过时 | reducer `:635,676,1040` 调用 ActionTimeline；全部技能退款/失败冷却合同未逐场运行，未能判定完整闭环。 |
| 8 | “无武器来源”已过时 | `lib/data/defs/equipment_def.dart:11,70-88` 有 weaponArchetype；`lib/data/phase0a_weapon_mapping_config.dart:12,21` 有生产 profile；五武器全部体感未验。 |
| 9 | “姿态无生产接线”已过时 | mapper `:1036,1081,1235` 与 reducer `:210,974`；纯模块头注不能代替调用图。 |
| 10 | 听剑成长完整合同仍未能判定 | decision registry `:309-317` 比例 tuning、生产改值未授权；存在 claim 类型不等于发放闭环。 |
| 11 | “只有纯失败合同”不足以描述现状 | `CombatResolutionService` 已有心魔分支及共享结算；全模式失败/一次伤势矩阵未运行，未能判定全部规则。 |
| 12 | 双套方案不能按旧表恢复 | `docs/spec/rejected_task_registry.md:87` 明确一套持久装配；是否迁完每个旧槽非本轮动态验收。 |
| 13 | 未能判定全局当值槽合同 | 旧描述是跨活动产品容量决策；当前活动服务已扩展，未重新核原批准会话，不能从单个 occupancy 类名推定。 |
| 14 | 统一报告提案不可直接执行 | `docs/spec/rejected_task_registry.md:59` 保留各活动独立摘要；旧“未实装”不等于今天欠债。 |
| 15 | 连续流已不是原黑风岭单切片口径 | coordinator `:125-137` 按 nextStageOf 推进；当前 105 assignment 全 migrated；所有 UI 路径连续可玩性仍需动态矩阵，未能判定。 |
| 16 | 四关 legacy 的旧数量已过时 | 当前 `stage_assignments.yaml` migrated 105 行，包括第一章五关。 |
| 17 | 总令牌 6 已过时 | black_wind_ridge `:14-18` 为 1+1+1+1=4。 |
| 18 | 原歧义不能继续当未处置事实 | 同文件 `:3-6` 记录候选 A / TUNING，链上 `d1a5864c1f0fd6e7914a7a6115ae9b3242f97832` 订正来源判断；原会话本轮未重核。 |
| 19 | “无批准依据”不能照搬 | 上述后续订正为反证；本轮未重新审阅全部原会话，具体每值授权未能判定。 |
| 20 | 全塔旧结构的概括过时；全塔完成亦不成立 | `phase0a_tower_encounter_host.dart:39` 生产迁移集合仅 `{1,2,3,4,5,6,7}`；不将 7 层推成 49 层。 |
| 21 | 已有后续塔 durable 工具链 | 当前 `lib/features/tower/presentation/tower_durable_automation_ui.dart` 存在；任意角色与全部模式矩阵未运行，未能判定全部旧差异消失。 |
| 22 | “轻功/群战无自动化”已过时 | `DurableActivityAutomationPolicy` `:99-102` 与同目录 service/coordinator/UI 已存在。 |
| 23 | “远征没有首次里程碑门”已过时 | `expedition_service.dart:184-198` 对未手动清除 milestone 阻止新 dispatch，`:457-486` 有 pending/manual 准入。 |
| 24 | 原“仅两套 policy”概括过时 | 共享 durable automation policy 已新增；是否等同旧五字段产品模型，未能判定。 |
| 25 | “无 durable reward owner”已过时 | `lib/features/reward/domain/reward_claim_receipt.dart:13`、`application/durable_reward_claim_service.dart:10`；全模式幂等矩阵未重跑。 |
| 26 | 残页自动转换仍无此生产分支 | `skill_unlock_service.dart:71-73` 对已解锁直接返回 none；不据此擅选转换材料。 |
| 27 | “没有 hidden/heard/open”已过时 | `progressive_unlock.dart:11` 三态；地图 `jianghu_map_screen.dart:52-94` 使用 heard/open。 |
| 28 | 旧单关/旧塔作为全部密度分母已过时 | 当前 105 migrated、6 source；塔仅迁 1–7；各模式最大 active 与补兵区间未重新统计，未能判定完整密度合同。 |
| 29 | “仅山匪一个生态来源”已过时 | manifest `archetype_sources` 本次 6 项；24 逻辑角色/美术变体逐 ID 完整性未重跑。 |
| 30 | “只有第一章单关分配”已过时 | 当前 manifest assignments 覆盖 105 个 migrated 项；配置覆盖不等于全部内容通过真人验收。 |
| 31 | 未能判定七模板完整闭环 | 当前 encounter_sources 已扩展，不能只凭旧 black_wind 单一 objective 推断全局；本轮未重做七模板的胜负/超时动态矩阵。 |
| 32 | “21 章未生产编排”已过时 | 当前 105 个 migrated assignment；是否与原设计每行内容完全相符不在本轮盲猜。 |
| 33 | 旧 HUD/表现数量不能沿用 | 当前 screen 已大量改写（该文件 branch 与链 blob 不同），原逐事件数量/屏外指标须画面和计数器重测，未能判定原 13 组仍成立。 |
| 34 | 原单生态/四关 legacy 前提已失效 | 当前 105 migrated；塔仍兼容旧层，故也不能宣布全产品 legacy 清零。 |
| 35 | 指定类型仍不存在 | `git grep -n -F 'class CharacterAvailabilityService' "$C" -- lib` 为 0；类型名不同不等于行为未实现，跨入口合同未能判定。 |
| 36 | 武器 schema 已变、秒字段退役未完成 | equipment weaponArchetype 已存在；skill cooldownTurns 仍解析；原“三者均未落地”应拆开。 |
| 37 | 旧性能覆盖仅黑风岭的判断已过时 | 当前 PROGRESS `:14` 引用 09-16 生产矩阵；本轮未跑性能/Windows，也不把所引用旧数字当本次实测。 |
| 38 | reduceFlashing 零消费已过时 | 第 12 条；独立特效密度符号仍 0，视觉等价性未能判定。 |
| 39 | 全模式 parity 未能判定 | 当前新增 durable 活动/奖励路径已使旧抽样范围失效；本轮未运行所有 fixed tick/hash/掉落矩阵。 |

## 附录 B：旧 CLAUDE 正文漂移表逐项复核

对应旧文的 19 行，序号按其原表顺序。只判断“文档与当前实现是否仍有该差异”，不裁决设计应改成哪一方。

| 序号 | 当前判断与证据 |
|---:|---|
| 1 | ranks.yaml 路径漂移仍在：CLAUDE `:229` 写该文件；`git ls-tree -r --name-only "$C" -- data/ranks.yaml` 输出 0 行。 |
| 2 | EquipmentRepository 示例符号仍不在 lib；CLAUDE `:248` 保留该例，但示例不是必须存在的产品合同，不能当运行时缺陷。 |
| 3 | RealmStratum/enum Style 仍 0 命中；真实枚举在 `lib/core/domain/enums.dart:22,33,115`。 |
| 4 | Boss 层号/乘子正文仍旧：CLAUDE `:305`；当前 towers `:1433,1464,2377,2407,2412` 对应 32/49 与 0.35、0.15×0.10。 |
| 5 | battle_log 集中 sink 描述仍旧：CLAUDE `:314`；`git ls-tree -r --name-only "$C" -- lib` 未见 basename battle_log.dart；enum 文件仍在 shared/battle_shared。 |
| 6 | 公式正文未罗列实际全部乘项：当前 `damage_calculator.dart:249-260` 有 attackPowerMultiplier/proficiency/output/defenderSchool/ward。这属于文档简化还是设计缺陷需另判。 |
| 7 | 速度还扣伤势：`derived_stats.dart:166`；旧简式不完整的窄事实仍在。 |
| 8 | **部分已变**：effectiveSkillDelta 生产调用已在 mapper `:1152`；schoolBonus 精确调用 0。不得再并列写两者零消费。 |
| 9 | damage_calculator/derived_stats 的旧目录已迁位；当前分别 `lib/features/combat_shared/domain/` 与 `lib/shared/battle_shared/`。 |
| 10 | encounters→events 仍为单向枚举：`game_repository.dart:666-670` 遍历 encounterDefs；不能用此循环证明孤儿 event 被反向校验。 |
| 11 | asset_audit 仍走图片 `stageNarrativePath`（`:55`）；不能替代 narrative YAML 完整性守卫；两份专用 completeness 测试仍存在。 |
| 12 | WuxiaPaperPanel 旧名仍在 CLAUDE `:523`；实际 `LightPaperPanel` 在 `light_paper_panel.dart:15`。 |
| 13 | 商店“Phase 5+ 再回头”仍在 CLAUDE `:557`；真实 ShopService/ShopScreen 分别 `:19/:45`。 |
| 14 | enum_localizations.dart 旧引用仍迁位，真实路径在 shared/battle_shared；不重造旧目录。 |
| 15 | joint skill 配置位置/收支旧描述仍不一致：CLAUDE `:570`；numbers `:810-825` 位于装备 resonance，skills `:1145-1150` 为 qiDelta -50；旧 battle_ai 文件不存在。 |
| 16 | **消费结论已变**：旧 BattleState/internalInjurySlot 不存在，但 adapter `:243-275` 把 appliedEffects 的 internal_injury 转成 TimedStatusSpec，reducer `:497,548` 消费；不能保留“当前无内伤消费方”的结论。 |
| 17 | 四遗物规则字段排除 numbers_config.dart 后仍 0 命中（精确四字段 grep）；这只证明未由字段驱动，不能说明硬编码行为必错。 |
| 18 | _FounderBuffSection 已迁 `lineage_character_detail_screen.dart:486`；CLAUDE `:574` 仍旧页名。 |
| 19 | 商店固定标价/不卖出旧描述仍与实现冲突：ShopService `:8` 明记经验丹 ETL 动态价格；EquipmentDisposalService `:81,93` 有 sell/disassemble。是否应保留行为需产品决策，不在本单改代码。 |

## 本轮额外机器复核入口

```sh
C=c307b3ffcb155af58d4efb9179e36453297b1360
git grep -c -E '^    migration_state: migrated$' "$C" -- data/combat/manifest/stage_assignments.yaml
git grep -c -E '^  - data/combat/archetypes/' "$C" -- data/combat/manifest.yaml
git grep -n -E 'QiCycle.effectiveSkillDelta|QiCycle.schoolBonus' "$C" -- lib
git grep -n -E 'transferTrigger|multiDiscipleAllocation|stackAcrossGenerations|conflictSlotResolution' "$C" -- lib ':!lib/data/numbers_config.dart'
git grep -n -E 'RealmStratum|enum Style|class EquipmentRepository|class BattleState|internalInjurySlot|class WuxiaPaperPanel' "$C" -- lib
git grep -n -F 'INNER-DEMON-LEGACY-01' "$C" -- docs/dispatch/phase0a_overhaul/decision_registry.yaml
```

本次依次输出命中数：**105、6、1、0、0、0**；后面三个零命中的 grep 退出码为 1，属于“未找到”，不是工具失败。`git merge-base --is-ancestor <SHA> "$C"` 对本报告引用的 `c0d6df8d8dc6d37639223c1c46cf70cee9ed455b`、`2f554d54038a68f7b7adca26f7357a6196eca404`、`1158548fa5faf9a95b1df6f70ed073d0dcb5364e`、`d1a5864c1f0fd6e7914a7a6115ae9b3242f97832`、`54aed6b51`、`2b35f7eae` 本次均退出 **0**。

## 处置建议汇总（仅供明早拍板）

| 建议 | 数量 | 分支编号 |
|---|---:|---|
| cherry-pick 进链 | 0 | 无 |
| 打 `archive/<完整分支名>` 标签后删 | 20 | 除 11 外全部 |
| 直接删 | 1 | 11 |

本轮建议 cherry-pick 提交列表为 `[]`，预期冲突文件不适用。原因是旧数值/判定部分过时、工具部分未完成当前运行验证，或原提交同时修改权威文档/配置/测试；可用的新定位已汇入本报告。归档保留历史与可复用工具，不表示其中仍开放的问题已经修好。

拟归档清单如下，本次未创建任何标签；这些完整标签名本次与已有本地标签无重名。真正处置前由协调者再检查 tip/活动 worktree，当前报告不是删除执行记录。

| 分支 | 拟标签 | 固定 tip |
|---|---|---|
| `codex/c2-fragment-economy-20260823` | `archive/codex/c2-fragment-economy-20260823` | `8fc409551da8be98c2dba8294724522337fe1801` |
| `codex/phase2-m5-r01-inner-demon-cultivation-penalty-removal-20260824` | `archive/codex/phase2-m5-r01-inner-demon-cultivation-penalty-removal-20260824` | `83755eb597bf4f8315f86e2ad9eeac9f0b4ec254` |
| `codex/phase2-governance-integration-20260825` | `archive/codex/phase2-governance-integration-20260825` | `503d1ad3f2c1f845027b48fb9cdc940d9147b3ff` |
| `codex/p2-defense-break-reachability-20260826` | `archive/codex/p2-defense-break-reachability-20260826` | `39ae8f83564f413566df0178c8777520869f6c39` |
| `codex/p2-n4-falsegreen-20260826` | `archive/codex/p2-n4-falsegreen-20260826` | `57fb6416f0dd86170cbf981ce6a5a1ea25c844f6` |
| `codex/p2-n5-ci-20260826` | `archive/codex/p2-n5-ci-20260826` | `fa6e7ad0d387dc3f928bc76ca0be2e9b59a42684` |
| `codex/p2-spec-reality-audit-20260826` | `archive/codex/p2-spec-reality-audit-20260826` | `0ec0280a02e0422106be9dba3bbd70d58e78f127` |
| `codex/p2-token-candidate-rerun-20260826` | `archive/codex/p2-token-candidate-rerun-20260826` | `bae8f89b6ac8e682a540d4249e65f8e68184b860` |
| `codex/p2-b1-vfx-short-circuit-audit-20260827` | `archive/codex/p2-b1-vfx-short-circuit-audit-20260827` | `22e67d9256c311f06d238722b5a9bc6ce9148d96` |
| `codex/p2-backlog-scan-20260826` | `archive/codex/p2-backlog-scan-20260826` | `8d704d2740f04b1e1eb8878dc5d5dc7c2344a7e7` |
| `codex/p2-density-fx-evidence-20260827` | `archive/codex/p2-density-fx-evidence-20260827` | `94a93293c2d3d3c98c281e7a1b70c2af313e79e0` |
| `codex/p2-claudemd-drift-20260826` | `archive/codex/p2-claudemd-drift-20260826` | `be0e8582def944ad4644a01dd29249677aa5d85c` |
| `codex/p2-milestone-facts-20260826` | `archive/codex/p2-milestone-facts-20260826` | `d56b214a8d0413e35ae6ec178d990ffb1e305928` |
| `codex/p2-mutation-probe-20260826` | `archive/codex/p2-mutation-probe-20260826` | `e9a3aa8a2d79907763bbf8c1c20a44a4733b870a` |
| `codex/p2-n6-deadfield-20260826` | `archive/codex/p2-n6-deadfield-20260826` | `766549115d8e05d29c8c0414031c77635588750a` |
| `codex/p2-leftover-pool-20260826` | `archive/codex/p2-leftover-pool-20260826` | `258b3e8ef1f384915be2c73ac194ba6a63cabb63` |
| `codex/p2-d1-input-blocker-diagnosis-20260828` | `archive/codex/p2-d1-input-blocker-diagnosis-20260828` | `6884cb4c45b1cf104bc4a1acab839a5eb9eba5a4` |
| `codex/p2-e1-visual-fail-triage-20260828` | `archive/codex/p2-e1-visual-fail-triage-20260828` | `9f8f8c93e6d72ab7a890b90fc399a656ac52566f` |
| `codex/p2-e2-playtest-capture-pipeline-20260828` | `archive/codex/p2-e2-playtest-capture-pipeline-20260828` | `ca09853b68661c8c0c4f247de1eeada2fe4ac171` |
| `codex/save-migration-verify-20260912` | `archive/codex/save-migration-verify-20260912` | `811caf4172f98add41bacbfcaf2772694822791d` |

直接删候选只有 `codex/p2-defense-vfx-fix-20260827`，理由与完整提交证据见第 11 条。所有原分支的完整独有提交列表与文件列表均已保留在逐条章节；不对任何分支执行删除、merge、rebase、revert、push。

## 验证与范围

- 元数据脚本成功运行两种链参数，均得 21 分支 / 42 个逐分支独有提交计数；同 SHA 固定输入重复结果逐字相同。
- 新 Python 源通过 `ast.parse` 语法解析；没有运行 Dart、Flutter、测试变异或游戏 GUI。
- 本目标只新增本报告与 `tools/audit/orphan_doc_branches_triage.py`；没有改动已有 audit、登记簿、生产配置/代码/测试。
- 动态行为、原始批准会话、历史原始日志缺失或只读围栏不允许本轮重复的部分均明确标记“未能判定”；这不是对旧报告的默认采信。
