> 交接时间：2026-07-28 14:57 · 最后**内容** commit `37f3d396`（在 PR #90 分支）
> main 侧末尾均为 docs commit；**HEAD 本身不钉**——以现跑 `git rev-parse --short HEAD` + `git status -sb` 为准

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

battle-ui-v2 视觉验收子系统**全阶段收官**（阶段 1-5 完成，终验 94/100 ≥85 目标，用户接受）。
main 工作树干净、与 origin 同步。**但 PR #90 尚未合并**——本轮 2 个 commit
（`57c6b164` 生产改动 + `37f3d396` 收尾文档）在分支 `worktree-battle-ui-v2-stage5-fix` 上，
不在 main。CI `macos-build` 已 SUCCESS，`test` 交接时仍 IN_PROGRESS。

开局动作：
1. 读 PROGRESS.md 顶段 2026-07-28 battle-ui-v2 阶段 5 条目
2. 读 docs/sessions/2026-07-28_1457_阶段5终验.md
3. git pull --rebase --autostash
4. 选读 memory：reference_anti_hallucination（固定）
   + feedback_measure_from_config_not_render（**本轮新增**：量测优先读配置不从渲染反推）
   + feedback_visual_score_first_pass_underestimate（**本轮新增**：视觉评分首轮系统性低估）
   + feedback_living_doc_state_drift（交接带的诊断本身会错，照做前必证伪）
   + feedback_exit_worktree_merged_branch_warning（清 worktree 三验）
   + feedback_gh_pr_mergeable_vs_local_divergence（PR 合并前本地 merge-tree 复算）

【环境快照】（2026-07-28 本会话实测，新会话改动后须重测）
- 主 checkout：本会话 docs commit 直落 main 并 push（session 记录 + 本 NEXT.md）；代码改动 2 commit 在 PR #90 分支未合。**HEAD sha 不钉，现跑取**
- 主 checkout `flutter analyze --no-pub` **EXIT=0 · No issues found**（6.0s）
- **全量 4712 pass / 0 fail** EXIT=0（5m26s）—— 该数字来自 **PR #90 分支** worktree 实测；
  main 当前仍是 4711 基线（+1 为分支上新增的视觉守卫测），合并后才会变 4712
- main：18 章 90 关 / cap 42 / assets 101M
- battle-ui-v2：阶段 1-5 全收官，终验 94/100（A20/B22/C23/D15/E10/F4，A~E 各 ≥88%）

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 武圣段 spec 起草（推荐） | opus xhigh | ~2h | 宗师段 Ch16-18 已整段收官，武圣段是下一里程碑且 **cross-tier**（抬 cap 破 42），reconcile 面重新变大，需专会话 |
| 2 | 合并 PR #90 + 清 worktree/分支 | opus high | ~20min | 等 CI `test` 绿；清理走三验（is-ancestor / `main..分支` 计数 0 / `--merged`） |
| 3 | 三弟子年龄 1 句改 | opus high | ~15min | `stage_18_04_opening:7`「五十上下」vs `:15`「守了几十年」；便宜可搭车 |
| 4 | 补 F2 动作 route 拿最后 1 分 | opus high | ~1-2h | 纯补工具（新建动作帧 route 或 CGEvent 逐拍驱动），不碰已终拍美术 |

【硬约束沿用】
- **量测布局比例优先读代码常量，别从截图反推**：本轮图像分析三次全败（暗缝低谷/最大连续亮带/宽度众数），
  改读 `battle_layout_tokens.dart` 一次解决。图像法若非用不可，**必先在基准图上自校验**。
- **视觉评分首轮系统性低估**：判据外加码、同一问题重复扣分、把内容差异当缺陷、没找既有实现就判缺失——
  本轮 71→94 有 13.5 分是判错而非修复。交付时必须写清改判溯源，否则会误导成「修好了」。
- **改全局 token 前先 grep 使用面**：`WuxiaColors.internalForce` 有 35 处 + Material `secondary`，
  只改单个调用点而非 token 值。同理 `_mainlineSceneColorGrade` 是全主线矩阵，动它波及 90 关已终拍美术。
- **`gh pr checks` 在 CI pending 时返回非 0**，会把等待循环搞挂；轮询改用 `gh pr view --json statusCheckRollup`。

【防幻觉守则】
- 本提示词【环境快照】里的数字是上一会话实测的快照；新会话改动代码后**必须重新实测**，禁直接转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 `file:line`；不确定写「不知道」，不凭记忆硬答。
- 含中文的绝对路径跑 `find`/`cd` 会给错结果 → 先 `cd` 再用相对路径。
- 完整守则见 memory `reference_anti_hallucination`。

【先报告】
读完上述清单后：1. 报告 PROGRESS.md 和 session 记录的关键信息 2. 确认环境状态
（现跑 HEAD / status / worktree list / PR #90 状态） 3. 不要直接动代码。
