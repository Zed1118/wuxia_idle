> 交接时间：2026-07-26 11:16 · **HEAD = `78da778d`**（main·与 origin 同步·工作树净·现跑 `git rev-parse --short HEAD` 实证）
> 新会话打「开工」= 读本文件按其执行。核对方式：`git log --oneline -3` 顶部应为 `78da778d`（PR #82 merge）→ `4daa8df5` → `2942af60`（PR #81 merge）；对不上先报偏差再动。

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

上一会话把两个 PR 合进 main：PR #81（生产随机源收口·BACKLOG §一#8 销账）与 PR #82（PROGRESS 条目订正为已合并态 + 压缩归档 98→90 行）。两条远端分支经三验后已删，**origin 现只余 `main`**。本次交接记录在 PR #83（draft·**未合**，不合则 main 看不到该文件）。

开局动作：
1. 读 PROGRESS.md 顶段 2026-07-26「生产随机源接线收口合 main」条
2. 读 docs/sessions/2026-07-26_1116_PR合并与压缩归档.md
   （若 PR #83 未合：`git show origin/worktree-session-handoff-0726:docs/sessions/2026-07-26_1116_PR合并与压缩归档.md`）
3. git pull --rebase --autostash
4. 选读 memory：reference_anti_hallucination（固定）
   + feedback_phase0_check_inflight_worktrees（codex 在途·开局与收尾各查一次）
   + feedback_bg_parallel_session_handoff_collision（codex 仍在写，勿碰）
   + feedback_exit_worktree_merged_branch_warning（清 worktree 会误报丢弃）
   + feedback_chinese_path_shell_pitfalls（本轮新增实例：内联 until/while 解析失败）
   + 候选 1 加读 feedback_wuxia_add_mainline_chapter_reconcile + feedback_wuxia_pen_build_runner

【环境快照】
- HEAD `78da778d`（本会话 2 merge commit + 1 docs commit，全 push）
- **main @ 78da778d 主 checkout 本次实测（2026-07-26 11:1x）**：`flutter analyze` **EXIT=0 · No issues found**（4.8s）；
  全量 `flutter test --no-pub` **4661 pass / 0 fail**（FULL_EXIT=0 · `[E]` 0 · 无 `-1` 标记）
- PROGRESS **90 行**（100 上限·留约 5 批余量）；BACKLOG §一 余 5 条开启（#3/#4/#5/#6/#11），
  **#4/#5/#6 全卡在「待真人试玩数据」**
- **他方在途**：`codex/global-visual-polish`（worktree `.worktrees/global-visual-polish`·tip `fb5a8851`·
  **tip 无 `[READY]`** → 按 CLAUDE §8.3 判 WIP 不碰·已连续多轮未打标记）
- `build/visual_acceptance/` 累积 **429M** gitignored 证据，其中 401M 为往批遗留待拍板存废

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | Ch17「沙海纵深」实装批（推荐） | opus **xhigh 专会话** | ~3.5-4h | 当前唯一能推进主线的实质任务；spec §8 前瞻已定向（cap 38→40→42·末 Boss vulnerability 0.20 教学），`idle_horizon` s1 45.6/下沿 45 贴线必破须重校 |
| 2 | 真人试玩半小时 | — | ~30min | 只有用户能做，一次解锁 §一#4/#5/#6 三项数值拍板 |
| 3 | 视觉目检债清账 | opus high | ~1h | 飘字分段排版 / 23 处 UiStrings 搬迁 / webp q80 观感 / Ch16 立绘真机战斗屏；需独占屏幕，与 codex 抢 app |
| 4 | `build/visual_acceptance/` 401M 存废拍板 | — | ~5min | 一句话决定，删完省 400M 本地盘 |
| 5 | 合并 PR #83（本交接记录） | opus high | ~10min | 纯 docs 单文件；不合则 main 看不到本次交接 |

【硬约束沿用】
- **bg 会话禁 merge / 推 main**：只能开 draft PR，合并需用户逐 PR 显式授权。draft 直接 `gh pr merge` 报
  `still a draft`，须先 `gh pr ready`；合完必显式查 `gh pr view <n> --json state,mergeCommit`。
- **别信单一信号判绿红**：① 后台任务 exit code 可能来自 shell 解析失败或命令链末尾的 `grep -c`（真值取命令
  自己 echo 的变量）；② GitHub run 级 conclusion 可能假红，判红必须下钻 job/step 级；③ **targeted 传目录
  ≠ 目录下文件都跑到**（本轮实例：传 `test/shared` 但 `test/shared/utils/` 未跑），验收单文件请单跑取证。
- **本会话 shell 无法解析内联 `until` / `while [ ]`**（`parse error near 'until'`），须写 `.sh` 文件用
  `bash script.sh` 跑；后台任务会因此被报 "failed with exit code 1"，实为解析失败非 CI 红。
- **worktree/本地分支会被 harness 在会话结束时自动回收**，「留置 worktree」不是可靠承诺；要留必须 push 到远端。
- flutter test 禁裸接管道：`> file 2>&1; echo EXIT=$?`；破坏证红必须在 commit 后做；
  Edit dart 文件 commit 前必 `dart format`（CI format gate 先于测试）。

【防幻觉守则】
- 本提示词【环境快照】数字是 2026-07-26 11:1x 主 checkout 实测快照；新会话改动后必须重新实测，禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

【先报告】
读完上述清单后：1. 报告 PROGRESS 与 session 记录关键信息 2. 确认环境状态（含 PR #83 是否已合、codex 在途
分支现状）3. 不要直接动代码。
