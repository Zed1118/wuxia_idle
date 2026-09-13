# 新会话开局清单

> 交接时间：2026-09-13 12:39 · 工作收口于 HEAD `2b35f7eae`（分支 `worktree-review-followup-20260912`，无 upstream）· 该 HEAD 的六个 commit 已全部进入候选 `codex/p2-player-flow-20260910` = `198ec8641`（本地=origin）· main `342d19275` = origin/main，未动
> 本清单自身的落盘 commit 排在 `2b35f7eae` 之后，故实际 HEAD 会比它新 1 个纯文档 commit——**这不是漂移**，判据见【开局动作】第 4 步。

## 【本会话契约】（置顶，最高优先级）

- **模式：只读**
- **只读模式**：完成【开局动作】并提交【先报告】后，等用户指令才可动代码。
- **范围围栏**：只做用户选定的任务。过程中发现的其他问题分两类处置——
  - **非阻塞型**（不影响当前任务正确性）→ 记入 `docs/spec/playability_phase2_backlog.md`，附 file:line 与复现步骤，**不动代码**；
  - **阻塞型**（当前任务建立在它之上，不修就是在错地基上盖楼）→ **停下报告**，不要记了账继续干。
- **拍板点**（设计取舍、多方案选型、观感判断）：只读模式下停下列选项等用户，禁代拍；自主模式下自行决策并写入「本会话决策清单」，收尾一并报（memory `feedback_user_offline_autonomous`）。
- **本项目专属红线**：不合 main / 不 push main / 不 force-push / 不 rebase；不动主 checkout 的 4 个用户文件（`AGENTS.md`、`CLAUDE.md`、`.qoder/settings.json`、`docs/_archive/CLAUDE_v2.00_frozen_2026-09-06.md`）；不删 `.claude/worktrees/review-followup-20260912`（locked）及 4 个 20260912 在途 worktree；不迁塔层、不翻闸门；真实存档在 `~/Library/Containers/com.pen.wuxia.wuxiaIdle/Data/Documents/`，不碰。

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

候选分支已分片 CI 但结论 failure（shard 3 三个平台分歧红 + shard 2 分片失衡超时）；單 D 旧档迁移验证已完成未并入。当前唯一阻塞是把 CI 修到真 success，候选才能落 main。

## 【开局动作】

1. 读 PROGRESS.md 顶段 2026-09-12 条目（注意：單 D 分支 `811caf417` 上有更新版顶段，尚未进候选；读候选/main 上的版本时知道它落后）
2. 读 `docs/sessions/2026-09-13_123938_整改派单_review-followup-20260912.md`
3. `git worktree list` + `git branch --list 'worktree-*' 'codex/*20260912*'`：确认有无在途分支。PROGRESS.md 只反映 main，在途工作不在其中，别在不知情的情况下重做一遍。交接时的在途见【环境快照】。
4. **只 `git fetch`,不自动 rebase/autostash**。按下列顺序判定:

   ```bash
   git status -sb | head -1                                   # 先看脏不脏（主 checkout 预期 4 个用户文件脏，属正常）
   git fetch origin
   git rev-list --left-right --count origin/main...main       # 预期 0 0
   git merge-base --is-ancestor 2b35f7eae codex/p2-player-flow-20260910 && echo ANCESTOR_OK
   ```

   - 主 checkout 4 个用户文件以外还有脏 / main 与 origin 分叉 / 有其他活跃写者 → **停下报告**,不自行更新
   - 本清单不要求 ff main：候选还没落 main，main 保持 `342d19275` 是预期

   **接手前并发检查**：`ps aux | grep -iE "codex|flutter_tester"` 看 app 端 Codex 是否还在跑；候选 tip 是否已超过 `198ec8641`；`~/.claude/locks/` 协调锁是否被他人持有且心跳新鲜。任一显示活跃 → 先确认对方已停止,再动。

   - `ANCESTOR_OK` **且** 候选 tip = `198ec8641` → 快照有效，继续。
   - 候选 tip 已前进 → 快照部分作废：先 `git log 198ec8641..codex/p2-player-flow-20260910` 看新增了什么，再决定下方 CI 结论是否仍成立。
5. 选读 memory：`reference_anti_hallucination`（固定）+ `feedback_gh_run_watch_exit_code_masks_cancelled` + `feedback_flutter_ci_local_green_red_divergence` + `feedback_superseded_authorization_expires` + `feedback_phase0_check_inflight_worktrees`

## 【环境快照】（上一会话实测；本会话改动代码后必须重测，禁转抄）

- HEAD `2b35f7eae`（本次 session 6 commits `c93b50512..2b35f7eae`，未 push 本分支；六个 commit 已经由單 C 并入候选并随候选推到 origin）
- `flutter analyze --no-pub lib test tool` → EXIT 0 · No issues found · 4.8s｜2026-09-13 12:39 在 `review-followup-20260912` worktree 实测（主 checkout 是 main，不含本批代码，故不在那里测）
- 全量测试：**本次 handoff 未重跑**（理由见 session 记录「重要决策」）。可引用的实测：
  - 本机 exact `a48aab668`：`flutter test --coverage --no-pub` 6562 PASS / 0 fail / 870.3s，coverage 49118/56864 = 86.38%（單 A 日志，單 D 复用）
  - CI run `34732200859` exact `198ec8641`（ubuntu）：shard 0 success 8m03s · shard 1 success 7m47s · shard 3 **failure** 1657 pass / 3 fail（8m52s）· shard 2 **cancelled** 25m18s 撞分片超时 · coverage skipped · macos-build success 2m37s
  - **守恒核对**：候选比 a48 多 `test/tools/run_test_shard_test.dart` + `ci_workflow_contract_test.dart` 扩展，总数应 >6562；shard 2 未完成，CI 侧总数不可得，本会话若要数字必须本机重跑
- 在途 PR / 分支：
  - `codex/p2-player-flow-20260910` = `198ec8641`（候选，本地=origin，含分片 ci.yml + `tool/run_test_shard.dart`）
  - `codex/ci-shard-budget-20260912` = `198ec8641`，worktree `/Users/a10506/Desktop/Projects/挂机武侠-ci-budget-20260912`（單 C，已交付）
  - `codex/save-migration-verify-20260912` = `811caf417`（未推），worktree `挂机武侠-save-migration-20260912` + `挂机武侠-save-migration-main-20260912`（detached main，對照用）（單 D，已交付，只改 PROGRESS.md）
  - `codex/tower-multi-recon-20260912` = `1aaa08940`，worktree `~/.codex/worktrees/tower-multi-recon-20260912/`（8–14 层侦察，已交付）
  - `worktree-review-followup-20260912` = 本清单落盘处，locked
- 存档：真档 3 槽原版 `0.40.0`，候选迁到 `0.50.0` 已在副本上验证（單 D）；容器目录 mtime 仍 2026-09-05，未被任何一单写过
- 闸门：`review_gaps_block_floor_migration: false`（执行链自清已标注）、`next_batch_floor_migration_requires_user_signoff: true`（`task_registry.yaml:8139`）；生产迁塔仍 1–7 层

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 修 CI 两红拿真 success（推荐） | opus | 60–90min | 唯一阻塞项。① shard 3：`lib/data/isar_setup.dart` 开档路径无 `on IsarError` 分支，Linux 上 libmdbx `MDBX_INVALID` 直接穿透，需映射为 `UnreadableSaveException`——改 lib/ 先拍板；② shard 2：`tool/run_test_shard.dart` 从 sorted round-robin 改按实测时长分箱。改完 `gh workflow run CI --ref codex/p2-player-flow-20260910` 并显式读 `conclusion` |
| 2 | 單 D `811caf417` 普通 merge 进候选 | sonnet | 15min | 零文件重叠（PROGRESS.md vs ci.yml/tool），不能 ff；merge 后 PROGRESS 顶段仍需补 CI 分片结果 |
| 3 | 候选落 main | — | 用户拍板 | 前提：#1 拿到 conclusion=success 且 headSha=候选 tip |
| 4 | 8–14 层多敌迁移 | opus | 另立单 | 前提：用户翻 signoff；侦察见 `docs/audit/phase2_m7_tower_8_14_multi_enemy_recon_2026-09-12.md` |

## 【硬约束沿用】

> **主从原则**：canonical 正文只住 memory，此处每条只留**一行摘要 + memory 指针**。

- 事实性数字一律本会话实测，禁转抄 → memory `reference_anti_hallucination`
- `gh run watch --exit-status` 对 cancelled 返 0，必读 `conclusion` + 核 headSha → memory `feedback_gh_run_watch_exit_code_masks_cancelled`
- 本地绿 / CI 红五类根因，平台分歧优先排查 → memory `feedback_flutter_ci_local_green_red_divergence`
- 用户改口即撤销旧授权；派单/push 前 ps 查在途 → memory `feedback_superseded_authorization_expires`
- 开工与收尾各查一次 worktree list → memory `feedback_phase0_check_inflight_worktrees`
- commit message 中文动宾 → memory `feedback_wuxia_commit_message_chinese_gate`
- 推荐不得为省工作量缩水 → memory `feedback_no_effort_saving_in_recommendations`
- fresh worktree 先 `dart run build_runner build` + 拷 `libisar.dylib` → memory `feedback_wuxia_pen_build_runner` / `feedback_fresh_worktree_libisar_dylib`
- codex CLI 派单沙箱：`-s danger-full-access` 才含网络与主仓 .git → memory `feedback_codex_worktree_dispatch_sandbox`

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测的快照；改动代码后**必须重测**，禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】（与置顶契约呼应）

读完上述清单后先提交一份报告，**不动代码**：

1. **防装读要求**：须引用本清单里**不存在**的原文——PROGRESS.md 顶段条目的**原文标题行与日期**，以及 session 记录「下一步建议」小节的**原文首条**。只复述本清单已有的信息不算完成。
2. 报告【开局动作】第 3、4 步结果：在途分支情况 + 候选 tip 校验判定（有效 / 部分作废）+ app 端 Codex 是否仍在跑。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`（Step 0-4 为 canonical 流程，此处不复述，防拷贝漂移）。
