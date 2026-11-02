# 新会话开局清单

> 交接时间：2026-11-02 11:38 CST · 工作收口于 HEAD `54354f913` · 本地领先 origin/main（`7dab6f1e7`）1 个纯文档 commit；工作树干净。本清单 commit 后会再新 1 个纯文档 commit——这不是漂移，判据见【开局动作】第 4 步。
> 本清单由 2026-11-02 handoff 生成；旧 2026-09-22 恢复入口已被覆盖。

## 【本会话契约】（置顶，最高优先级）

- **模式：只读**
- **只读模式**：完成【开局动作】并提交【先报告】后，等用户指令才可动代码。
- **范围围栏**：只做用户选定任务。过程中发现的其他问题分两类——非阻塞型记入 `BACKLOG.md`（file:line + 复现），不动代码；阻塞型停下报告。
- **拍板点**：设计取舍 / 多方案选型 / 观感判断，停下列选项等用户，禁代拍。

项目：挂机武侠（`/Users/a10506/Desktop/Projects/挂机武侠/.claude/worktrees/integration-g2-20261102`）
> 原主 checkout `/Users/a10506/Desktop/Projects/挂机武侠` 当前在 `codex/p2-player-flow-20260910`，含 `AGENTS.md` / `CLAUDE.md` 等未提交改动；新会话使用干净 merged-main worktree，勿在主 checkout 合并或清理。

G2 首章候选已 `--no-ff` 合入 main `9f1602949`，收账 `7dab6f1e7`，两次 CI success；下一步真人 G2 与 yin_rou 01_01 objective。

## 【开局动作】

1. 读 PROGRESS.md 顶段 `2026-11-01 G2 第一章可读性候选（已合 main ...）`
2. 读 `docs/sessions/2026-11-02_113818_G2首章_main.md`
3. `git worktree list` + `git branch --list 'worktree-*'`：在途分支见【环境快照】。PROGRESS.md 只反映 main，在途工作不在其中。
4. 只 `git fetch`，不自动 rebase/autostash；按序判定：
   `git status -sb`; `git fetch origin`; `git rev-list --left-right --count origin/main...HEAD`; `git merge-base --is-ancestor 7dab6f1e7 HEAD && echo ANCESTOR_OK`
   dirty / 分叉 / 其他活跃写者 → 停下报告；干净且可 FF → `git merge --ff-only origin/main`。
   并发检查：worktree list、远端 tip、协调锁。
   `ANCESTOR_OK` 且同步 → 快照有效（HEAD 比 `7dab6f1e7` 新 1–2 个纯文档 commit 属正常）。
5. 选读 memory：`reference_anti_hallucination`、`feedback_wuxia_pen_build_runner`、`feedback_fresh_worktree_libisar_dylib`、`feedback_phase0_check_inflight_worktrees`、`feedback_gh_run_watch_exit_code_masks_cancelled`、`feedback_visual_acceptance`、`feedback_wuxia_self_execute_no_dispatch_20261012`。

## 【环境快照】（上一会话实测；改代码后必须重测）

- HEAD `54354f913`（本会话 4 commits：`6a6e7a1d3` feature、`9f1602949` merge、`7dab6f1e7` docs、`54354f913` handoff record；merge/docs 已 push，handoff commit 未 push）
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

> 主从原则：canonical 正文只住 memory，此处每条只留一行摘要 + memory 指针。

- 不删历史分支 / worktree、不自动 push main → CLAUDE.md §8.2 · memory `reference_anti_hallucination`
- fresh worktree 必 build_runner + 拷 `libisar.dylib` → memory `feedback_wuxia_pen_build_runner` / `feedback_fresh_worktree_libisar_dylib`
- 视觉 / 真人验收不可用自动化代签 → memory `feedback_visual_acceptance`
- 挂机武侠现阶段不派外部 agent → memory `feedback_wuxia_self_execute_no_dispatch_20261012`

## 【防幻觉守则】

- 本清单数字为上一会话实测快照；改动代码后必须重测，禁转抄。
- 报「完成 / 已修复 / 0 引用 / 全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】

读完上述清单后先提交报告，**不动代码**：

1. **防装读**：引用本清单里不存在的原文——PROGRESS.md 顶段条目的原文标题行与日期，以及 session 记录「下一步建议」小节的原文首条。
2. 报告【开局动作】第 3、4 步结果：在途分支情况 + HEAD 校验判定（有效 / 作废）。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`（Step 0-4 canonical，此处不复述，防拷贝漂移）。
