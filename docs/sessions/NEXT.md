# 新会话开局清单

> 交接时间：2026-09-17 20:05 · 工作收口于 HEAD `29ddf974a` · 与 origin `codex/p2-player-flow-20260910` 同步；主 checkout 脏文件仅 4 个用户文件（`AGENTS.md` / `CLAUDE.md` / `.qoder/settings.json` / `docs/_archive/CLAUDE_v2.00_frozen_2026-09-06.md`，设计如此）
> 本清单自身的落盘 commit 排在 `29ddf974a` 之后，故实际 HEAD 会比它新 1 个纯文档 commit——**这不是漂移**，判据见【开局动作】第 4 步。

## 【本会话契约】（置顶，最高优先级）

- **模式：只读**
- **只读模式**：完成【开局动作】并提交【先报告】后，等用户指令才可动代码。
- **范围围栏**：只做用户选定的任务。过程中发现的其他问题分两类处置——
  - **非阻塞型**（不影响当前任务正确性）→ 记入项目根 `BACKLOG.md`，附 file:line 与复现步骤，**不动代码**；
  - **阻塞型**（当前任务建立在它之上）→ **停下报告**，不要记了账继续干。
- **拍板点**（设计取舍、多方案选型、观感判断）：停下列选项等用户，禁代拍。
- **主线分支是 `codex/p2-player-flow-20260910`（受控集成链），不是 main**；main `342d19275` 未经用户授权不合、不推。

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

夜批 A/B 与兜底收口已入链、分支治理收口完毕；当前无在途执行端任务，下一步以用户拍板为准。

## 【开局动作】

1. 读 PROGRESS.md 顶段「2026-09-17 当前候选」与「在途 worktree 台账」
2. 读 `docs/sessions/2026-09-17_200441_夜批收账_p2-player-flow.md`
3. `git worktree list` + `git branch --list 'worktree-*'`：确认有无在途分支。PROGRESS.md 只反映链上状态，在途工作不在其中，别在不知情的情况下重做一遍。
4. **只 `git fetch`，不自动 rebase/autostash**。按下列顺序判定：

   ```bash
   git status -sb | head -1                                                  # 先看脏不脏（预期只有 4 个用户文件）
   git fetch origin
   git rev-list --left-right --count origin/codex/p2-player-flow-20260910...HEAD   # 看分叉
   git merge-base --is-ancestor 29ddf974a HEAD && echo ANCESTOR_OK
   ```

   - 除 4 个用户文件外还有脏文件 / 存在分叉 / 有其他活跃写者 → **停下报告**，不自行更新
   - 干净且可 fast-forward → 才 `git merge --ff-only origin/codex/p2-player-flow-20260910`

   **接手前并发检查**：`git worktree list`（预期 14 个，见记录「已知问题」）· 本地与远端 tip 是否已超过 `29ddf974a` 之后 1 个文档 commit · 协调锁 `~/.claude/locks/` 是否仍被他人持有且心跳新鲜。任一显示活跃 → 先确认对方已停止，再动。

   - `ANCESTOR_OK` **且** 与 origin 同步 → 快照有效，继续。
   - `--is-ancestor` 不成立 → **快照作废**：停下报告差异，重测 analyze/test 基线，禁止转抄下方数字。
5. 选读 memory：`reference_anti_hallucination`（固定）+ `feedback_night_batch_dispatch_protocol` + `feedback_wip_limit_over_executor_utilization` + `feedback_codex_batch_merge_via_integration_worktree` + `feedback_codex_worktree_dispatch_sandbox` + `feedback_test_bypasses_production_path`

## 【环境快照】（上一会话实测；本会话改动代码后必须重测，禁转抄）

- HEAD `29ddf974a`（本次 session 链上新增 30 commits：`c307b3ffc..29ddf974a`，已 push origin 同名分支；main 未动）
- `flutter analyze --no-pub lib test` → EXIT 0 · `No issues found! (ran in 6.1s)`｜主 checkout 2026-09-17 20:04 实测
- 全量 `flutter test --no-pub` → `07:38 +6948: All tests passed!`（+6948/0 失败 · 退出码未经 zsh pipestatus 捕获，以末行与 0 个 `[E]` 块为准 · 墙钟 20:04:04→20:11:46 = 7m42s）｜主 checkout 2026-09-17 实测
  - **守恒核对**：夜批 A 后 +6935 → 兜底收口后 +6948（新增 13 = `stage_boss_recruit_probability_test` 等，见 `docs/dispatch/reports/2026-09-17_residue_receipt.yaml`）；主 checkout 数字须与此一致，不一致先查是哪一类
- 在途 PR / 分支：无在途执行端任务。保留 worktree 14 个：主 checkout 1 · 协调者 `worktree-review-followup-20260912`（locked，与链分叉，只作历史记录不再作集成基线）· Codex 证据 `~/Documents/Codex/2026-09-1{3,5,6}/…` 6 个 · ③ 代码类 6 个待拍板（记录「已知问题」）· `.codex/worktrees/1454`
- 数值/闸门/塔层/schema/saveVersion（0.50.0）本会话零改动；M0–M9 仍 1/10（仅 M1）

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 拍板 6 个 ③ 代码类 worktree 处置（归档标签后删 / 保留）（推荐） | opus | 15min | 09-16 台账已判「可删」，连续两轮挂账；执行同 6A 脚本口径，先逐条核 tip |
| 2 | B-2 零引用 key 复核单（派 codex，只读产清单） | codex | 60–90min | `docs/audit/numbers_yaml_unused_keys_2026-09-17.md` 202 条逐 key 查动态路径消费；不改 yaml |
| 3 | 集中真人试玩 01_01 + 黑风岭并出报告 | 用户主导 | — | 用户曾定「试玩后置」，需用户点名 |
| 4 | `tools/phase0minus_probe` 子包 analyze 噪声处理（pub get 或排除） | sonnet | 20min | 全仓 analyze 1892 条全在该子包 |

## 【硬约束沿用】

- 夜批派单/收账五步流程，git 为真相源，READY≠可合 → memory `feedback_night_batch_dispatch_protocol`
- WIP 上限优先于执行端利用率；READY 待复核 ≤1 → memory `feedback_wip_limit_over_executor_utilization`
- Codex 批合并走链 tip 开的集成 worktree，不在分叉的协调者分支上合 → memory `feedback_codex_batch_merge_via_integration_worktree`
- codex `-s workspace-write` 需 `--add-dir <主仓>/.git`；resume 不继承 → memory `feedback_codex_worktree_dispatch_sandbox`
- 破坏证红 commit 后做双向并精确还原 → memory `feedback_break_red_after_commit`
- 数字一律本会话实测，禁转抄 → memory `reference_anti_hallucination`
- 一律简体中文 → memory `feedback_reply_in_simplified_chinese`
- 不动主 checkout 4 个用户文件；真实存档只读（sha256 允许） → memory `feedback_codex_worktree_dispatch_sandbox`

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测的快照；改动代码后**必须重测**，禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】（与置顶契约呼应）

读完上述清单后先提交一份报告，**不动代码**：

1. **防装读要求**：须引用本清单里**不存在**的原文——PROGRESS.md 顶段条目的**原文标题行与日期**，以及 session 记录「下一步建议」小节的**原文首条**。只复述本清单已有的信息不算完成。
2. 报告【开局动作】第 3、4 步结果：在途分支情况 + HEAD 校验判定（有效 / 作废）。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`（Step 0-4 为 canonical 流程，此处不复述，防拷贝漂移）。
