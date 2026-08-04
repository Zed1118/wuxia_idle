# 新会话开局清单

> 交接时间：2026-08-04 09:02 · 工作收口于 HEAD `8877560e` · 主 checkout 与 origin/main 同步、工作树干净
> 本清单自身的落盘 commit 排在 `8877560e` 之后，故实际 HEAD 会比它新 1-2 个纯文档 commit——**这不是漂移**，判据见【开局动作】第 4 步。

## 【本会话契约】（置顶，最高优先级）

- **模式：只读**
- **只读模式**：完成【开局动作】并提交【先报告】后，等用户指令才可动代码。
- **范围围栏**：只做用户选定的任务。过程中发现的其他问题分两类处置——
  - **非阻塞型**（不影响当前任务正确性）→ 记入项目根 `BACKLOG.md`，附 file:line 与复现步骤，**不动代码**；
  - **阻塞型**（当前任务建立在它之上，不修就是在错地基上盖楼）→ **停下报告**，不要记了账继续干。
- **拍板点**（设计取舍、多方案选型、观感判断）：停下列选项等用户，禁代拍。
- **本轮额外围栏**：批 A 体量约等于一个主线段，**不压缩、不切「最小闭环」**（CLAUDE §7 打磨期原则）；
  出任何推荐前先过「假设工作量不是考虑因素，这条会变吗」自检 → memory `feedback_no_effort_saving_in_recommendations`。

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

爬塔与支线终局适配已完成 spec 复核 + 8 项拍板 + 实装 plan（批 D，PR #113 draft **未合**），批 A/B/C 未开工。

## 【开局动作】

1. 读 PROGRESS.md 顶段条目。**注意**：本批（批 D）的 PROGRESS 条目在 PR #113 分支上，**尚未进 main**，
   main 顶段仍是上一批。要看批 D 全貌须读 `docs/spec/2026-08-01-tower-extension-design.md`（分支版）或 PR #113 body。
2. 读 `docs/sessions/2026-08-04_0902_爬塔spec复核.md`
3. `git worktree list` + `git branch --list 'worktree-*'`：**本轮确有在途分支**（见下方在途行），
   PROGRESS.md 只反映 main，别在不知情的情况下重做一遍。
4. `git pull --rebase --autostash`，然后校验本清单是否仍然有效：

   ```bash
   git merge-base --is-ancestor 8877560e HEAD && echo ANCESTOR_OK
   git status -sb | head -1
   ```

   - `ANCESTOR_OK` **且**与 origin 同步 → 快照有效，继续。（HEAD 比 `8877560e` 新几个纯文档 commit 属正常）
   - `--is-ancestor` 不成立 → **快照作废**：停下报告差异，重测 analyze/test 基线，禁止转抄下方数字。
5. 选读 memory：`reference_anti_hallucination`（固定）+ `feedback_no_effort_saving_in_recommendations`
   + `feedback_wuxia_long_term_polish_no_backlog` + `feedback_wuxia_release_cap_raise_reconcile`
   + `feedback_version_bump_test_assert_sync` + `feedback_living_doc_state_drift`
   + `feedback_backlog_premise_experiment_on_clean_tree` + `feedback_bg_worktree_baseref_fresh_diverge`

## 【环境快照】（上一会话实测；本会话改动代码后必须重测，禁转抄）

- HEAD `8877560e`（main 上本会话 **0 个功能 commit**；批 D 的 2 个 commit 在分支 `worktree-tower-extension-spec` 上，已 push）
- `flutter analyze --no-pub` → **EXIT=0 · No issues found · 6.5s**｜主 checkout 于 `8877560e` 实测
- 全量 `flutter test --no-pub` → **4805 pass / 0 fail · EXIT=0**｜**2026-08-03 上一会话主 checkout 实测**
  - 本会话（批 D）**零代码改动**（实测 `git diff --name-only 36fe9d80..b03dff15 | grep -v '\.md$'` = 0 个文件），
    按 CLAUDE §8.0 v1.29 测试节奏未重跑全量；批 A 动代码后必须重测
- **在途 PR / 分支**：
  - PR **#113**（draft，OPEN，未合）`worktree-tower-extension-spec` — 批 D 全部产物（spec/plan/PROGRESS/BACKLOG）
  - worktree `.claude/worktrees/tower-extension-spec`（locked 态，分支 tip `b03dff15`）
- 子系统状态：爬塔扩展 = spec 已拍板、plan 已出、代码零改动；批 A 前置阻塞已定位（见候选 1 备注）

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 合 PR #113 → 开批 A（A0 解硬编码起步）（推荐） | opus xhigh | 首切片 40-60min | 先合并让 PROGRESS/BACKLOG 进 main 再开工；A0 = `tower_progress_service.dart` 三处硬编码 30（`:78` 封顶 / `:89` 上界 / `:176` 周目完成判定）改从 `allFloors` 派生，**不解则新层进不去且静默失效**；A0 不阻塞于待拍项 |
| 2 | 拍断魂帖里程碑分布 | — | 5min | 现硬编码 10/20/30 层，扩层后须重定且影响奖励经济；plan 头部给三选项，推荐保持 3 张改 16/33/49 |
| 3 | 批 B 周目语义修正 | opus xhigh | 60-90min | 属性缩放→境界段推进；与批 A 文件不重叠可并行 |
| 4 | `codegraph init -i` 建索引 | opus high | 10min | 本会话结构性查询全部退回 grep；批 A 要大量查调用链 |

## 【硬约束沿用】

- 推荐不得为省工作量缩水范围；抄来的形状必自己算一遍 → memory `feedback_no_effort_saving_in_recommendations`
- backlog 只承载「依赖未解除 / 待用户拍板」两类，「没空做」不合法 → memory `feedback_wuxia_long_term_polish_no_backlog`
- 抬 cap / 改规模数字必查全站点 reconcile，硬编码断言会静默失效 → memory `feedback_wuxia_release_cap_raise_reconcile` + `feedback_version_bump_test_assert_sync`
- 长寿文档（CLAUDE.md/GDD/spec）状态与行号会 drift，引用前重新定位 → memory `feedback_living_doc_state_drift`
- 净树是零风险实验窗口，BACKLOG 定性先证伪再动手 → memory `feedback_backlog_premise_experiment_on_clean_tree`
- bg worktree baseRef=fresh 基于 origin 非本地 HEAD，注意分叉 → memory `feedback_bg_worktree_baseref_fresh_diverge`
- 全量测试默认并发（`-j1` 仅排查 flaky）；自包含改动只跑 targeted → memory `feedback_test_cadence_no_blind_full`

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测的快照；改动代码后**必须重测**，禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】（与置顶契约呼应）

读完上述清单后先提交一份报告，**不动代码**：

1. **防装读要求**：须引用本清单里**不存在**的原文——main 上 PROGRESS.md 顶段条目的**原文标题行与日期**，
   以及 `docs/sessions/2026-08-04_0902_爬塔spec复核.md`「下一步建议」小节的**原文首条**。
   只复述本清单已有的信息不算完成。
2. 报告【开局动作】第 3、4 步结果：在途分支情况 + HEAD 校验判定（有效 / 作废）。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`。
