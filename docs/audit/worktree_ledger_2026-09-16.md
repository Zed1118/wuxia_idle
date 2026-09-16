# Worktree / 分支台账（2026-09-16）

> 分类按 CLAUDE.md §8.4「孤立集成债 vs main 发布债」口径。分类阶段不删除；**2026-09-16 用户拍板「按推荐处理，86 个也一起清」后已执行清理**，结果见末节「执行记录」。下文分类表保留为清理前快照。
> 基准：main `342d19275`，统一候选链 `origin/codex/p2-player-flow-20260910` = `522c3ad40`。
> 判据：① tip 是 main/链祖先 → 已进；② `git cherry` 对链按 patch-id 全等价 → 内容已进、仅历史形状不同；③ 有链上没有的补丁 → 孤立。
> 未进入其他 worktree 读工作区脏净状态（会话隔离），脏净需删除前逐个 `git status` 确认。

## 总览

| 类别 | 数量 | 处置建议 |
|---|---|---|
| ① tip 已在 main/链上 | 18 | 可删（含 Codex 证据目录下的 source 检出与主 checkout 本身，删前核对 §保留名单） |
| ② 内容按 patch-id 已全进链 | 68 | 可删；均为 08-23～08-27 二阶段 G1/G2/M2 子切片，已经集成分支并入 |
| ③ 孤立 · 仅文档/证据/工具 | 23 | 归档类：审计/提案/记录 commit；决定是否把文档 cherry-pick 进链后再删 |
| ③ 孤立 · 含 lib/data 代码 | 8 | 见逐条判定；抽检表明多数已被链上后续实现覆盖 |
| 合计 | 117 | |

## 保留名单（用户/会话指定，不得删）

- `<主仓>`（主 checkout，`codex/p2-player-flow-20260910` 本地分支落后 origin，`git pull --ff-only` 即可）
- `<主仓>/.claude/worktrees/review-followup-20260912`（locked，审查报告分支）
- `~/Documents/Codex/2026-09-16/p2-m4-production-matrix/wt`（在途：M4 生产帧耗矩阵批）
- `~/Documents/Codex/2026-09-15/p2-onboarding-chain/batch1/source`、`batch2/source`、`~/Documents/Codex/2026-09-15/p2-native-readiness/source`（本轮证据检出，closeout 引用其路径）

## ③ 孤立 · 含 lib/data 代码（逐条判定）

| 日期 | 分支 | tip | 独有补丁 | 抽检 | 判定 |
|---|---|---|---|---|---|
| 2026-08-24 | `codex/ink-vfx-vertical-slices-20260824` | `00da01d4a` | 1 | 0/12 | 0/12 在链上 → 真孤立。是 debug 视觉路由的水墨招式三样片演示，非生产路径；是否要保留样片由用户拍板 |
| 2026-08-24 | `codex/phase2-m2-d01-ch1-candidate-data-20260824` | `a88d2bd4b` | 1 | 12/12 | 12/12 在链上 → 已进；可删 |
| 2026-08-24 | `codex/phase2-m5-r02-inner-demon-defeat-summary-alignment-20260824` | `50ae2d5c9` | 2 | 0/0 | 独有 commit 为文档/测试记录，lib 差异来自链上后续改动 → 可删 |
| 2026-08-26 | `codex/p2-defense-break-posture-20260826` | `bc1f568c8` | 1 | 2/2 | 2/2 在链上 → 已进；可删 |
| 2026-08-26 | `codex/p2-posture-wiring-20260826` | `1db64d0d1` | 1 | 2/2 | 2/2 在链上 → 已进；可删 |
| 2026-08-27 | `codex/p2-b1-layer-sort-comment-20260827` | `7fbf324e8` | 1 | 0/0 | 独有 commit 仅改注释（0 新增代码行）→ 可删 |
| 2026-08-31 | `codex/p2-m4-parallax-raster-boundary-20260831` | `a814385b6` | 1 | 2/3 | 2/3 在链上，缺 `RepaintBoundary` 光栅缓存一处 → 真孤立。基线 56a0856 时 p99 46ms 的优化候选，链上 a68933d 已用其他路径把 p99 压到 7.2ms；待 M4 生产矩阵结果决定是否还需要 |
| 2026-09-06 | `codex/p2-defend-feedback-quick-gather-20260906` | `5cb9c94f9` | 3 | 12/12 | 12/12 新增行已在链上 → 内容已进（经 09-06 阻塞修复批），历史形状不同；可删。注意该 worktree 曾是 09-13 误启事故的旧包来源 |

## ③ 孤立 · 仅文档/证据/工具

| 日期 | 分支 | tip | 标记 | 独有内容 |
|---|---|---|---|---|
| 2026-08-23 | `codex/c2-fragment-economy-20260823` | `8fc409551` | READY | test3：[READY] add fragment economy diagnostic evidence |
| 2026-08-24 | `codex/phase2-m5-r01-inner-demon-cultivation-penalty-removal-20260824` | `83755eb59` | READY | docs1：登记心魔惩罚移除设计证据 ; 记录心魔惩罚移除绿测证据 ; 记录心魔惩罚移除终审结论 ; 闭合心魔惩罚移除交付证据 |
| 2026-08-25 | `codex/phase2-governance-integration-20260825` | `503d1ad3f` | READY | PROGRESS.md1,docs2,CLAUDE.md1：整合二阶段结果驱动门禁 ; [READY][CODEX][P2-GOVERNANCE-INTEGRATION] 整合二阶段结果驱动规则 |
| 2026-08-26 | `codex/p2-defense-break-reachability-20260826` | `39ae8f835` | BLOCKED | docs1,test1：[BLOCKED] 钉住破防技可达崩溃 |
| 2026-08-26 | `codex/p2-n4-falsegreen-20260826` | `57fb6416f` | READY | docs1：[READY] 完成测试假绿审计 |
| 2026-08-26 | `codex/p2-n5-ci-20260826` | `fa6e7ad0d` | READY | docs1：[READY] 记录CI健康度实测 |
| 2026-08-26 | `codex/p2-spec-reality-audit-20260826` | `0ec0280a0` | WIP | docs1：核对二阶段方案生产偏差 [READY] |
| 2026-08-26 | `codex/p2-token-candidate-rerun-20260826` | `bae8f89b6` | WIP | docs2,test1：[BLOCKED] 固化攻击令牌候选证据 |
| 2026-08-27 | `codex/p2-b1-vfx-short-circuit-audit-20260827` | `22e67d925` | READY | docs1：[READY] 完成VFX同类短路核查 |
| 2026-08-27 | `codex/p2-backlog-scan-20260826` | `8d704d274` | READY | docs1：[READY] 提交BACKLOG补给扫描提案 |
| 2026-08-27 | `codex/p2-defense-vfx-fix-20260827` | `f16c09efc` | READY | test1：[READY] 消除防御测试删除误报 |
| 2026-08-27 | `codex/p2-density-fx-evidence-20260827` | `94a93293c` | BLOCKED | docs2,test1：[BLOCKED] 记录密度视效生产前置缺口 ; [BLOCKED] 固化密度视效阻塞验收 |
| 2026-08-27 | `codex/p2-claudemd-drift-20260826` | `be0e8582d` | BLOCKED | docs1：[BLOCKED] 核对 CLAUDE 文档漂移 |
| 2026-08-27 | `codex/p2-milestone-facts-20260826` | `d56b214a8` | READY | docs1：[READY] 对账G0决策签字与实况 |
| 2026-08-27 | `codex/p2-mutation-probe-20260826` | `e9a3aa8a2` | READY | tools3,docs1：建设变异测试探针 ; 修正变异超时清理 ; [READY] 完成变异测试探针首轮跑批 |
| 2026-08-27 | `codex/p2-n6-deadfield-20260826` | `766549115` | READY | docs1：[READY] 清点死字段与零引用资产 |
| 2026-08-27 | `codex/p2-leftover-pool-20260826` | `258b3e8ef` | READY | docs4：核对二阶段方案生产偏差 [READY] ; [READY] 整理二阶段遗留任务池提案 ; [READY] 编制二阶段拍板菜单 |
| 2026-08-28 | `codex/p2-d1-input-blocker-diagnosis-20260828` | `6884cb4c4` | BLOCKED | docs2：记录试玩输入阻塞诊断 ; 更新输入诊断收工状态 |
| 2026-08-28 | `codex/p2-e1-visual-fail-triage-20260828` | `9f8f8c93e` | READY | docs1：核定视觉验收失败分类 |
| 2026-08-28 | `codex/p2-e2-playtest-capture-pipeline-20260828` | `ca09853b6` | READY | tools9,docs1：沉淀真机打局录屏管线 ; 记录真机管线收工证据 |
| 2026-09-12 | `codex/tower-multi-recon-20260912` | `1aaa08940` | WIP | docs4,test2：记录九霄塔八至十四层多敌侦察证据 |
| 2026-09-13 | `codex/save-migration-verify-20260912` | `811caf417` | WIP | PROGRESS.md1：验证旧档迁移并刷新进度摘要 |
| 2026-09-15 | `worktree-review-followup-20260912` | `a91660425` | WIP | "docs1,docs2：交接会话记录与新会话开局清单(整改派单) ; 产出候选 6a70e79 全量代码审查报告 ; 订正全量审查报告首关结论与决策菜单 ; 清理审 |

## ② 内容已全进链（按 patch-id 等价）

`~/<主仓>-p2-break`, `codex/c3-idle-island-parity-44461288`, `codex/p2-b1-layer-sort-render-key-20260827`, `codex/p2-m3-product-contract-rebase-20260901`, `codex/p2-token-budget-realign-20260826`, `codex/phase0a-full-content-diagnostic-20260823`, `codex/phase2-ch1-repository-loader-20260824`, `codex/phase2-g1-c11-cooldown-seconds-20260823`, `codex/phase2-g1-c12-bot-tactics-20260823`, `codex/phase2-g1-c13-failure-policy-20260823`, `codex/phase2-g1-c14-reward-policy-20260823`, `codex/phase2-g1-c16-defense-hardening-20260823`, `codex/phase2-g2-batch6-baseline-regression-fixes-20260823`, `codex/phase2-g2-batch6-vulnerability-arc-fix-20260823`, `codex/phase2-g2-c02-forward-fan-20260823`, `codex/phase2-g2-c10-event-projection-20260823`, `codex/phase2-g2-d01-spawn-director-20260823`, `codex/phase2-g2-d02-attack-token-20260823`, `codex/phase2-g2-d03-battle-flow-20260823`, `codex/phase2-g2-d04-token-observe-20260823`, `codex/phase2-g2-d05-session-seams-20260823`, `codex/phase2-g2-d06-roster-events-20260823`, `codex/phase2-g2-d07-production-assembler-20260823`, `codex/phase2-g2-d08-runtime-observer-20260823`, `codex/phase2-g2-d09-typed-encounter-mapping-20260823`, `codex/phase2-g2-d10-dynamic-visual-roster-20260823`, `codex/phase2-g2-e01-participation-request-20260823`, `codex/phase2-g2-e02-encounter-compat-20260823`, `codex/phase2-g2-e03-dynamic-encounter-20260823`, `codex/phase2-g2-e05-encounter-migration-resolver-20260823`, `codex/phase2-g2-l01-combat-catalog-loader-20260823`, `codex/phase2-g2-o01-objective-primitives-20260823`, `codex/phase2-g2-s01-combat-content-schema-20260823`, `codex/phase2-g7-balance-reference-closeout-20260824`, `codex/phase2-m0-f01-fact-sync-20260823`, `codex/phase2-m2-c01-catalog-schema-gateway-20260824`, `codex/phase2-m2-c01-objective-reference-fix-20260824`, `codex/phase2-m2-r01-mainline-run-participation-20260824`, `codex/phase2-m2-r02-mentor-insight-contract-20260824`, `codex/phase2-m2-r03-objective-controller-20260824`, `codex/phase2-m2-r04-runtime-contract-mapper-20260824`, `codex/phase2-m2-r05-attack-token-batch-gate-20260824`, `codex/phase2-m2-r06-objective-runtime-tracker-20260824`, `codex/phase2-m2-r07-encounter-roster-mapper-20260824`, `codex/phase2-m2-r08-production-encounter-token-gate-20260824`, `codex/phase2-m2-r09-objective-aware-encounter-flow-20260824`, `codex/phase2-m2-r10-stage-encounter-route-selector-20260824`, `codex/phase2-m2-r11-migrated-encounter-plan-builder-20260824`, `codex/phase2-m2-r12a-attack-token-lease-runtime-20260824`, `codex/phase2-m2-r12b-attack-token-lease-session-wiring-20260824`, `codex/phase2-m2-r12c-attack-token-lease-assembler-seam-20260824`, `codex/phase2-m2-r13-explicit-objective-event-source-20260824`, `codex/phase2-m2-r14-mainline-run-admission-20260824`, `codex/phase2-m2-r15-mentor-insight-stage-occupancy-runtime-20260824`, `codex/phase2-m2-r17-migrated-encounter-settlement-adapter-20260824`, `codex/phase2-m2-r18-mainline-stage-runtime-admission-20260824`, `codex/phase2-m2-r19-mainline-stage-runtime-release-20260824`, `codex/phase2-m2-r20-mentor-insight-reverse-activity-guard-20260824`, `codex/phase2-m2-r21-mentor-insight-durable-claim-boundary-20260824`, `codex/phase2-m2-r22-encounter-defeat-objective-projection-mapper-20260824`, `codex/phase2-m2-r23-mainline-next-stage-runtime-admission-20260824`, `codex/phase2-m2-r24-attack-token-lease-batch-receipt-20260824`, `codex/phase2-m2-r25-encounter-flow-runtime-observation-20260824`, `codex/phase2-m2-r26-migrated-encounter-explicit-lease-assembler-20260824`, `codex/phase2-m2-r27-encounter-runtime-observation-snapshot-20260824`, `codex/phase2-m2-v01-ch1-candidate-runtime-construction-matrix-20260824`, `codex/phase2-m2-v02a-ch1-candidate-defeat-objective-execution-matrix-20260824`, `codex/phase2-m2-v02b-ch1-candidate-observable-transactional-composition-matrix-20260824`

## ① tip 已在 main/链上

`~/.codex/worktrees/a0d7/挂机武侠`@`58ae40bbc`, `~/.codex/worktrees/config-strict-20260907/挂机武侠`@`6c162e4bd`, `~/.codex/worktrees/gauntlet-rng-posture/挂机武侠`@`0d3a21833`, `~/.codex/worktrees/isar-deferred-triage-20260907/挂机武侠`@`df3be1365`, `~/.codex/worktrees/isar-missing-fields-048-20260907/挂机武侠`@`ecc75dba9`, `~/.codex/worktrees/isar-prerequisites-20260907/挂机武侠`@`ba29fc33d`, `~/.codex/worktrees/p2-m0-decision-batch-20260904`@`eea54b970`, `~/.codex/worktrees/p2-m7-tower-foundation-20260905/挂机武侠`@`431f28532`, `~/.codex/worktrees/tower-p0-20260907/挂机武侠`@`ba8144e14`, `~/<主仓>`@`5c1105cfa`, `~/<主仓>-ci-budget-20260912`@`198ec8641`, `~/<主仓>-save-migration-main-20260912`@`342d19275`, `~/Documents/Codex/2026-09-13/p2-ci-recovery/m4-54aed-worktree`@`e743b6026`, `~/Documents/Codex/2026-09-15/p2-native-lifecycle/source`@`e743b6026`, `~/Documents/Codex/2026-09-15/p2-native-readiness/source`@`5c1105cfa`, `~/Documents/Codex/2026-09-15/p2-onboarding-chain/batch1/source`@`50e6f5383`, `~/Documents/Codex/2026-09-15/p2-onboarding-chain/batch2/source`@`e6161d566`, `~/Documents/Codex/2026-09-16/p2-m4-production-matrix/wt`@`522c3ad40`

## 执行记录（2026-09-16 用户拍板后）

- **③ 代码类两条真孤立**：打归档标签并推送后删除本地分支——`archive/ink-vfx-vertical-slices-20260824` → `00da01d4a`、`archive/p2-m4-parallax-raster-boundary-20260831` → `a814385b6`。样片/优化候选随时可从标签恢复。
- **worktree**：`git worktree remove`（不带 `--force`，脏树/未跟踪文件会被拒绝）移除 **82 个**，**0 个被拒**；随后 `git worktree prune`。82 = 名单内 81（① ② 中不在保留名单的 + 两条归档）+ 1 条误删：`codex/tower-multi-recon-20260912` 的目录被手敲进批次误删，其分支与 commit `1aaa08940` 保留，需要时 `git worktree add` 即可复原。
- **本地分支**：删除前逐条现场重验（main 祖先 9 / 链祖先 1 / 归档标签指向 tip 2 / `git cherry` 对链全 `-` 67），**删除 79 个，0 失败**；远端分支未动。
- **清理后剩余 35 个 worktree**：主 checkout 1 + 保留名单 `~/Documents/Codex/` 下 6 + `review-followup-20260912`（locked）1 + ③ 未合入 27 = 文档类 21（原 23 减 `tower-multi-recon` 目录与本 locked worktree）+ 代码类 6（原 8 减归档 2；均在上表判定「可删」但本轮未拍板：`m2-d01`、`m5-r02`、`defense-break-posture`、`posture-wiring`、`b1-layer-sort-comment`、`p2-defend-feedback-quick-gather`）。本地分支 107 个。
- **未做**：③ 文档类 cherry-pick 进 `docs/audit`（n4 假绿审计、n6 死字段清点、mutation 探针、e2 真机管线工具）仍待用户拍板；主 checkout 本地 `codex/p2-player-flow-20260910` 落后 origin 13 个提交，需用户在主仓 `git pull --ff-only`。

