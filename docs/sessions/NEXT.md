# 新会话开局清单

> 交接时间：2026-08-02 18:35 · HEAD `0ef9de71` · 与 origin/main 完全同步、工作树干净
> 动手前先核头部 HEAD sha 与 git 实况；漂移（HEAD 不符/明显过期）先报告偏差再动。

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

上一会话独立终审并合入了战斗界面样板还原度 95+ 分支，顺带把暴露出的证据溯源缺口修在
工具层，并清掉了全部在途 worktree 与分支。HEAD `0ef9de71`，工作树干净，与 origin/main
完全同步，无在途 worktree/分支，是干净开局点。

开局动作：
1. 读 PROGRESS.md（顶段 2026-08-02 条目）
2. 读 docs/sessions/2026-08-02_1835_战斗界面终审.md
3. `git pull --rebase --autostash`
4. 选读 memory：`reference_anti_hallucination`（固定）+ `feedback_capture_commit_vs_screenshot_code_state`（本次新增）
   + `feedback_visual_acceptance` + `feedback_check_backlog_before_investigating`
   + `feedback_backlog_premise_experiment_on_clean_tree` + `feedback_desktop_keyboard_reachability_audit`
   + `feedback_flutter_test_batch_silent_skip` + `feedback_wuxia_pen_build_runner`

【环境快照】
- HEAD `0ef9de71`（本 session 23 commits `acc31ee8..0ef9de71`，全部已 push）
- `flutter analyze --no-pub` → **No issues found (3.7s)**｜主 checkout HEAD `3b091b69` 实测；
  `3b091b69..0ef9de71` 仅新增 1 个 session 记录 `.md`，零代码差异
- 全量 `flutter test --no-pub` → **4802 pass / 0 fail (4m01s)**｜同上实测点
- `tools/visual_capture` python 单测 → **18 pass**（HEAD 实测）
- 战斗界面样板还原度 95+：**complete**（F=min(G,P)=95，用户终拍通过，merge `c9a7fdc2`）
- 视觉验收工具链：manifest `schema_version: 3`，已记 `tree`/`dirty`（merge `d307f9a2`）
- 无在途 worktree 与本地分支（只剩 `main`），仓库内零未跟踪文件

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | BACKLOG §二#6 战斗样板复刻批余下 2 分 —— **先证伪前提**（推荐） | opus high | 40-45min | 净树正是零风险证伪窗口；该条前提可能已被 95+ 批覆盖（handoff P6 记 Tab/Enter/hover/ESC/cursor/双视口 10/10），先核是否 stale 再决定补证还是销账 |
| 2 | 爬塔扩展 spec 复核 + 7 项拍板点过会 | opus **xhigh** | 40-60min | `docs/spec/2026-08-01-tower-extension-design.md` 自述「high 下起草，实装前须 xhigh 复核」；含四方案，需用户逐项拍板，属方向级大活 |
| 3 | `avatar_status_tags.dart` 两处整洁 | opus high | ~15min | `:200` `edge..color=` 级联改共享 Paint 致第二道断毫按 0.20 渲染；`:169` `color` 字段 `paint()` 不消费。**改前先确认是否要保持终拍认可的现有观感** |
| 4 | BACKLOG §二#7 B3 立绘融合观感 | opus high | ~20min | 阻塞于真机实拍图，需用户先提供；只动三个常量，门禁测守边界 |
| 5 | BACKLOG §二#8 送关旧部立绘白布动势 | 美术返修 | 随批 | 07-30 目检半中项，语义达成但动势缺失 |

【硬约束沿用】
- **外部报告与 manifest 的 commit 字段不可当代码态证明**（§8.2 外审只进 triage）：抓图常发生在
  未 commit 的工作树上；视觉判定以**截图像素本身**为真相源。旧的 schema 2 manifest 尤其如此。
- **`flutter test` 传多个文件路径会静默漏跑**却仍报 All tests passed：验收须逐文件核出现次数，
  且 grep 模式别写错文件名 stem（本次就先写错过一次）。
- **新建 worktree 跑 `flutter analyze` 报海量 error 先查 `.g.dart`**（gitignored，不随 merge 走）；
  零 Dart 改动时以主 checkout 结果为准，别当成代码回归。

【防幻觉守则】
- 本清单【环境快照】里的数字是上一会话实测的快照；新会话改动代码后**必须重新实测**，禁直接转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 `file:line`；不确定就写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`（已列入上方「选读 memory」）。

【先报告】
读完上述清单后：1. 报告 PROGRESS.md 与 session 记录的关键信息 2. 确认环境状态（HEAD/同步/工作树）
3. 不要直接动代码。
