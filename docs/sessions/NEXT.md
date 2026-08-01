# 新会话开局提示词

**交接时间：** 2026-08-01 08:47 · **HEAD：** `a60db250`（现跑 `git rev-parse` 取得，禁转抄）

> 代码态锚点 `42d7e00c`：其后 2 条均为 docs commit，`git diff 42d7e00c..HEAD -- lib data test` 为空。
> 开局自验该命令为空即无漂移。

---

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

上一会话合掉两条 PR（#107 codex 战斗样板复刻批 / #108 账面订正批），把工作区从 13G 清到 3.0G，
并做了一次阶段性全面审查。main 全绿且干净，**零在途交付物、零遗留债**。

开局动作：
1. 读 PROGRESS.md 顶段 2026-08-01 条
2. 读 `docs/sessions/2026-08-01_0828_账面订正与全面审查.md`
3. 读 `docs/audit/stage_review_2026-08-01.md`（本轮审查，含 P1 缺口与路线图）
4. `git pull --rebase --autostash`
5. 选读 memory：`reference_anti_hallucination`（固定）
   + `feedback_chinese_path_shell_pitfalls`（本次新增第 6 条 · git ls-files 转义中文名致存在性检查假报）
   + `feedback_probe_must_prove_its_load`（量测本身会假报）
   + `feedback_exit_worktree_merged_branch_warning`
   + `feedback_bg_session_git_push_gh_auth`

【环境快照】（2026-08-01 主 checkout 实测，非转抄）
- HEAD `a60db250`（本会话 25 commit，全部已 push，与 origin 同步）
- `flutter analyze --no-pub` **EXIT=0 · No issues**（handoff 时现跑）
- 全量 **4780 pass / 0 fail · EXIT=0**（于 `42d7e00c` 实测；其后仅 docs commit，lib/test/data 零改动）
- main CI run 30675641102 **双 job success**（headSha `2c4a411e`）
- worktree：只剩主 checkout；本地分支只 main；远端只 main；untracked 0
- 项目占用 3.0G（清理前 13G）；`BACKLOG.md` 43 行 / `PROGRESS.md` 96 行

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 规模类文案扩真相源守卫（推荐） | opus high | ~40min | 本轮审查唯一新增 P1；约 11 处 UI 文案写死数字且无守卫（塔30层×5/心魔7关×2/轻功5/群战5/断魂庄3关×2），当前值实测全对但扩内容即静默 drift——章数那处已这样活了 5 章 |
| 2 | 断魂庄 / 百草岭远征补 audit 路由 | opus high | ~1h | 153 关视觉验收覆盖外唯一缺口；BACKLOG §二#5 |
| 3 | 查 `audioplayers` 6.8.1 是否解 VS2026 | opus high | ~15min | 解了即可松开 windows-release 的 `windows-2022` 钉；BACKLOG §二#11 |
| 4 | 战斗样板复刻批余下 2 分 | opus high | ~40min | 顶栏 Tab/tooltip 键盘走查取证 + 方法学局限前置；BACKLOG §二#6 |
| 5 | B3 立绘融合观感真人拍方向 | opus high | ~20min | 只动 3 个常量，门禁测守边界；需先看真机实拍图；BACKLOG §二#7 |

【硬约束沿用】
- **量测本身会假报，两法互证再下结论**：上一会话三次实录——`git ls-files`（不带 `-z`）对中文名
  转义致「跟踪文件缺失 268」（实为 0）、`grep -c 'stageType: innerDemon'` 报 8（第 8 个是注释行，
  生效 7）、`towers.yaml` grep 报 60（`- floor:`/`- id:` 双模式重复计数，实为 30 层）。
- **ExitWorktree「Discarded N commit」对已合并分支是误报**：删前跑三验
  （`is-ancestor` / `main..branch` 计数 0 / `branch --merged`），过了再 `discard_changes: true`。
- **GitHub 合并后不自动删远端分支**：本仓未开 auto-delete，需显式 `push origin --delete` + `fetch --prune`。
- 不动 `numbers.yaml` / `GDD.md` / `CLAUDE.md` / `data_schema.md`（改前 ask）。

【防幻觉守则】
- 本提示词【环境快照】里的数字是上一会话实测的快照；新会话改动代码后**必须重新实测**，禁直接转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 `file:line`；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

【先报告】
读完上述清单后：1. 报告 PROGRESS.md 与 session 记录、审查报告的关键信息 2. 确认环境状态
（HEAD / 工作树 / 代码态锚点自验）3. 不要直接动代码。
