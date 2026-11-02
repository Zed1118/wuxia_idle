# 新会话开局清单（branch fragment）

> **未覆盖 `docs/sessions/NEXT.md`**：协调锁为 2026-09-19 死锁 `51cd6f8f`（pid 79105 不存在，心跳 43 天未更新）；`reclaim_evidence` 因 main / dispatch / Codex m4 三个 dirty worktree 返回 `false`。主协调者回收或确认后导入本文件。
> 交接时间：2026-11-02 11:38 CST · HEAD `7dab6f1e7` · origin/main 同 SHA · 工作树干净（本 fragment commit 后 HEAD 新 1 个纯文档 commit，不是漂移）
> 本清单在干净的 merged-main worktree `.../integration-g2-20261102` 落盘；原主 checkout 在 codex 分支且有用户改动，勿动。

## 【本会话契约】（置顶，最高优先级）

- **模式：只读**
- **只读模式**：完成【开局动作】并提交【先报告】后，等用户指令才可动代码。
- **范围围栏**：只做用户选定任务；非阻塞问题记入 `BACKLOG.md`（file:line + 复现），阻塞型停下报告。
- **拍板点**：设计取舍 / 多方案 / 观感判断停下列选项等用户，禁代拍。

项目：挂机武侠（`/Users/a10506/Desktop/Projects/挂机武侠/.claude/worktrees/integration-g2-20261102`）
> 原主 checkout `/Users/a10506/Desktop/Projects/挂机武侠` 当前在 `codex/p2-player-flow-20260910`，含用户未提交改动；新会话使用干净 merged-main worktree。

G2 首章候选已 `--no-ff` 合入 main `9f1602949`，收账 `7dab6f1e7`，两次 CI success；下一步真人 G2 与 yin_rou 01_01 objective。

## 【开局动作】

1. 读 PROGRESS.md 顶段 `2026-11-01 G2 第一章可读性候选（已合 main ...）`
2. 读 `docs/sessions/2026-11-02_113818_G2首章_main.md`
3. `git worktree list` + `git branch --list 'worktree-*'`：在途分支见【环境快照】。PROGRESS.md 只反映 main，在途工作不在其中。
4. 只 `git fetch`，不自动 rebase/autostash；按序判定：
   `git status -sb`; `git fetch origin`; `git rev-list --left-right --count origin/main...HEAD`; `git merge-base --is-ancestor 7dab6f1e7 HEAD && echo ANCESTOR_OK`
   dirty / 分叉 / 其他活跃写者 → 停下报告；干净且可 FF → `git merge --ff-only origin/main`。
   并发检查：worktree list、远端 tip、协调锁。
   `ANCESTOR_OK` 且同步 → 快照有效（HEAD 比 `7dab6f1e7` 新 1 个 handoff docs commit 属正常）。
5. 选读 memory：`reference_anti_hallucination`、`feedback_wuxia_pen_build_runner`、`feedback_fresh_worktree_libisar_dylib`、`feedback_phase0_check_inflight_worktrees`、`feedback_gh_run_watch_exit_code_masks_cancelled`、`feedback_visual_acceptance`、`feedback_wuxia_self_execute_no_dispatch_20261012`。

## 【环境快照】

- HEAD `7dab6f1e7`（本会话 3 commits：`6a6e7a1d3` feature、`9f1602949` merge、`7dab6f1e7` docs；merge/docs 已 push，handoff docs commit 未 push）
- `flutter analyze --no-pub` → exit 0 · `No issues found!` · 17.1s｜干净 merged-main worktree 实测（主 checkout 被用户 codex 分支占用）
- 全量 `flutter test --no-pub` → `+7345 All tests passed!` · exit 0 · 9:07｜同上；本轮无测试增删
- 在途 PR / 分支：无 PR；`claude/p2-g2-first-chapter-20261101`=`6a6e7a1d3`（已合 main，保留）；`integration/g2-first-chapter-20261102`=`7dab6f1e7` local / `9f1602949` origin（已合，保留）；预存 `claude/dispatch-20260917`、`worktree-review-followup-20260912`、`codex/p2-boss-label-layout-20260915` 未清（非本轮，按项目不删历史）。
- 子系统：M2 工程候选已合 main；真人 G2 `NOT_RUN`；yin_rou 01_01 objective 未收口；首通 HP / 自动技能字段无生产消费者。

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 真人 G2 首章验收（推荐） | 用户 | 45–60min | 候选已合 main 且两次 CI 绿，正式 Gate 只差真人签字 |
| 2 | yin_rou 01_01 objective / 连续链 | opus | 30–60min | 先定位 objective 未收口是流程还是数值 |
| 3 | 首通 HP / 自动技能字段接线 | opus | 30–45min | 当前只有 attack 乘子有生产消费者 |
| 4 | M0 / M4 / M3 人类门与 Windows 实机 | 用户 | — | 依赖真人 / 硬件，不可自动代签 |

## 【硬约束沿用】

- 不删历史分支 / worktree、不自动 push main → CLAUDE.md §8.2 · memory `reference_anti_hallucination`
- fresh worktree 必 build_runner + `libisar.dylib` → memory `feedback_wuxia_pen_build_runner` / `feedback_fresh_worktree_libisar_dylib`
- 视觉 / 真人验收不可用自动化代签 → memory `feedback_visual_acceptance`
- 挂机武侠现阶段不派外部 agent → memory `feedback_wuxia_self_execute_no_dispatch_20261012`

## 【防幻觉守则】

- 本清单数字为上一会话实测快照；改动代码后必须重测，禁转抄。
- 报「完成 / 已修复 / 0 引用 / 全绿」前必跑验证并贴输出。
- 引用代码现 grep/codegraph 带 file:line；不确定写「不知道」。

## 【先报告】

读完上述清单后先提交报告，不动代码：

1. **防装读**：引用本清单里不存在的原文——PROGRESS.md 顶段条目的原文标题行与日期，以及 session 记录「下一步建议」小节的首条原文。
2. 报告【开局动作】第 3、4 步结果：在途分支情况 + HEAD 校验判定。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`（Step 0-4 canonical，此处不复述）。
