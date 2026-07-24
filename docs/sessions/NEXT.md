# NEXT — 新会话开局提示词(2026-07-24 11:25 交接·主 checkout HEAD 9ce4e8ef)

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

Ch15「关山一程」整章实装已完成并交付 **draft PR #67**（分支 `ch15-impl`@`4044a58f`·已 push·worktree 留置为在途载体）；批内自验全绿（worktree 批末全量 4652/0 EXIT=0·analyze 0·破坏证红 RED→GREEN 留档·全内容 Lv112=spec 预估恰好命中）。主 checkout main@`9ce4e8ef` = origin/main 树净未动。新会话任务 = PR #67 Gate 审查 + 合并收账。

开局动作：
1. 读 docs/sessions/2026-07-24_1120_Ch15实装批.md（本批交接记录·踩坑三条）
2. `gh pr view 67` + 审 diff（PROGRESS Ch15 条随分支走，合并前主 checkout 不可见）
3. git pull --rebase --autostash
4. 选读 memory：reference_anti_hallucination（固定）+ feedback_verify_full_ci_not_scoped_lint + reference_codex_image_gen_art_pipeline & feedback_visual_acceptance（美术批用）

【环境快照】
- 主 checkout HEAD `9ce4e8ef`（= origin/main · 树净 · 本 session main +1 handoff commit 已 push — 2026-07-24 11:2x 现跑实证）
- 主 checkout analyze 0（2026-07-24 实测）；全量基线 **4652/0** = worktree `ch15-impl` 批末实测（2026-07-24·EXIT=0 显式取码·**合并后主 checkout 必复验**）
- 在途载体：worktree `.claude/worktrees/ch15-impl`@`4044a58f` + 本地/远端分支 + PR #67 OPEN draft（合并收账时全清）
- kimi 2026-07-26 10:10 前配额不可用（派单走 Claude/codex）

【下波候选】

| # | 任务 | 工具/模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | PR #67 Gate 审查 + --no-ff 合并收账（推荐） | Claude opus high | ~30-45min | 自审全绿批走 §8.2 Gate 后合入即解锁美术批；合并态 build_runner（预期 0 outputs·无 schema）+analyze+全量复验+载体清理+PROGRESS 补 PR 号 |
| 2 | Ch15 美术 11 图 codex image_gen 专批 | codex | 随批 | 依赖 1；guanshan_*×5+chapter_15_cover+narrative_stage_15_01..05·沿 Ch11-14 配方（BACKLOG §二#2） |
| 3 | battle-ui-v2 阶段 5（Windows 缩放） | codex | 随批 | plan 既定末段·与 1/2 无依赖可并行 |
| 4 | 宗师段 spec（先拍 §一#9 HP 头寸机制层方向） | Claude xhigh | 专会话 | Ch16+ 前置·feng_juan/yang_guan 两 deferred 归此段 |

【硬约束沿用】
- 合并纪律：draft PR 审 diff 后 --no-ff；合并后主 checkout analyze+全量复验必做（4652/0 是 worktree 侧数字）
- 红线已验：末 Boss 59500<60000 / 孤城闭 mult 4800≤8000（破坏证红留档）/ 敌攻 ≤1850 / 三系锁死
- flutter test 禁裸接管道：`> file 2>&1; echo EXIT=$?` 显式取码（本批 full1 的 1 fail 曾被外层 exit 0 掩盖）
- idle_horizon s3 50.7/下沿 50、s4 7.0/下沿 7.0 **双贴线**——下批扩章必破必重校
- ExitWorktree 对已合并分支「1 commit will be discarded」保守误报：先 `git merge-base --is-ancestor <tip> main` 实证再 discard
- 随机 fail 未捕获名第 4 轮续传：本批两轮全量未复现——下批全量仍无复现建议销账（请用户拍板）

【防幻觉守则】
- 本提示词【环境快照】数字是 2026-07-24 交接时实测快照；新会话改动/合并后必须重新实测，禁转抄。
- 报「完成/已修复/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」。
- 完整守则见 memory reference_anti_hallucination。

【先报告】
读完上述清单后：1. 报告 session 记录/PR #67 关键信息 2. 确认环境状态（HEAD/树净/同步/在途载体） 3. 不要直接动代码。
