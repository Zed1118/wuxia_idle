# 新会话开局提示词

**交接时间：** 2026-07-31 16:01 · **代码态锚点：** `ef443e4d`

> 锚的是**代码态**不是 HEAD：`ef443e4d` 之后只有 handoff 与本文件两条 docs commit，
> `lib`/`data`/`test` 零改动。开局自验：`git diff --stat ef443e4d..HEAD -- lib data test` 为空即无漂移。

---

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

上一会话合掉了夜批四 PR + 自做三 PR（B3 立绘自适应融合 / C5 行囊中性化+桌面焦点 / F2 证据订正），
并评审 codex 战斗样板复刻批（R1 82 分 → 派单返修一轮 → R2 98/100）。
main 全绿且干净；唯一在途是 codex 复刻分支，未推未合，等合并决策。

开局动作：
1. 读 PROGRESS.md 顶段 2026-07-30「用户拍板『按推荐执行』批」
2. 读 `docs/sessions/2026-07-31_1601_打磨批与复刻评审.md`
3. `git pull --rebase --autostash`
4. 选读 memory：`reference_anti_hallucination`（固定）
   + `feedback_codex_worktree_dispatch_sandbox`（本次新增·派单到 worktree 的沙箱坑）
   + `feedback_golden_frame_hides_viewport_defect`（本次新增·黄金帧掩盖真实视口缺陷）
   + `feedback_visual_acceptance`（视觉验收 SOP）
   + `feedback_visual_score_first_pass_underestimate`（评分别系统性低估）
   + `feedback_night_batch_dispatch_protocol`（派单收账以 git 为唯一真相源）

【环境快照】（2026-07-31 主 checkout 实测，非转抄）
- 代码态锚点 `ef443e4d`（本会话 main 上 3 条 merge + 2 条 docs commit，**已全部 push**）
- 主 checkout `flutter analyze --no-pub` **EXIT=0 · No issues**
- 主 checkout 全量 **4762 pass / 0 fail · EXIT=0**（= 合并前 4734 + B3 新增 16 + C5 新增 12）
- worktree：主 checkout + `codex-battle-ui-sample-replica`（**待合交付物，非孤儿**）
- 分支：本地 `main` + `codex/battle-ui-sample-replica`（20 commit · tip `[READY]` · 干净 · 纯本地）；远端只剩 `main`
- codex 分支我已独立验证：全量 **4779/0** · analyze 0 · 三视口原生截图零 overflow · 四条硬约束未违反

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 推 codex 分支开 PR → CI 复跑 → 合并（推荐） | opus high | ~30min | 唯一在途交付物，已本地验全绿，只差 CI 独立背书 |
| 2 | 复刻批剩余 2 分：顶栏 Tab/tooltip 走查取证 | opus high | ~40min | 98→100 的最后两分，需真机键盘走查 |
| 3 | 断魂庄 / 远征补 audit 路由 | opus high | ~1h | 解跨多轮挂账，同时补齐视觉验收覆盖面 |
| 4 | B3 观感真人拍方向后调档 | opus high | ~20min | 只动 3 个常量，门禁测守边界；需你先看实拍图 |

【硬约束沿用】
- **派 codex 到 worktree 必须 `--add-dir` 覆盖主仓 `.git`**：worktree 元数据在主仓 `.git/worktrees/` 下，
  只给 `-s workspace-write` 会让它活全干完却提不了 commit（本次实录）
- **派视觉单必须钉「在 1280×720 复拍」**：codex 只对样板黄金尺寸自验，缺陷会被掩盖
  （本次冷却签遮字在 1672 最不明显、720p 最严重）
- **§8.3 判就绪须 tip 前缀 + worktree 干净两条同时看**：只扫 `[READY]` 会撞上陈标记
- 不动 numbers.yaml / GDD.md / CLAUDE.md / data_schema.md（改前 ask）

【防幻觉守则】
- 本提示词【环境快照】里的数字是上一会话实测的快照；新会话改动代码后**必须重新实测**，禁直接转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

【先报告】
读完上述清单后：1. 报告 PROGRESS.md 与 session 记录的关键信息 2. 确认环境状态（HEAD / worktree / codex 分支）
3. 不要直接动代码。
