# 新会话开局提示词

**交接时间：** 2026-07-28 15:47 · **最后内容 commit：** `c4827304`（HEAD 本身不钉，以现跑 `git rev-parse --short HEAD` 为准）

---

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

武圣段（Ch19-21，主线终段）spec 已起草完成并 push，**9 项决策待拍板**，拍板是 Ch19 实装批的唯一前置。
main 工作树干净、与 origin 同步、零遗留 worktree/分支。battle-ui-v2 视觉验收子系统全阶段收官且 PR #90 已合并。
最后内容 commit `c4827304`；HEAD 本身不钉——以现跑 `git rev-parse --short HEAD` 为准。

开局动作：
1. 读 PROGRESS.md 顶段两条 2026-07-28 条目（武圣段 spec / battle-ui-v2 阶段 5 合并态）
2. 读 docs/sessions/2026-07-28_1547_武圣段spec.md
3. 读 docs/spec/2026-07-28-wusheng-arc-ch19-21-design.md（121 行 · 待拍板 9 项在 §6）
4. git pull --rebase --autostash
5. 选读 memory：reference_anti_hallucination（固定）
   + feedback_wuxia_add_mainline_chapter_reconcile（加章 ~11 测站点 + 6 生产站点）
   + feedback_wuxia_release_cap_raise_reconcile（抬 cap 4 站点 · 判据=releaseTier 变没变）
   + feedback_wuxia_boss_balance_crosstier（cross-tier Boss 配平）
   + feedback_living_doc_state_drift（交接带的诊断本身会错，照做前必证伪）
   + feedback_task_list_with_recommendation（候选表必带推荐项）

【环境快照】（2026-07-28 本会话主 checkout 实测，新会话改动后须重测）
- 最后内容 commit `c4827304`（本会话 3 commit：merge `d3ff1212` + docs `cec7cd1a` + docs `c4827304`，全已 push）
- `flutter analyze --no-pub` **EXIT=0 · No issues found**（7.5s）
- 全量 **4712 pass / 0 fail** EXIT=0（4m37s · `[E]` 0 · 失败标记 0）——实测于 merge commit `d3ff1212`；
  其后 2 commit 经 `git diff --stat` 实证**纯文档**（PROGRESS.md + spec），代码树未变，故该数字对当前 HEAD 仍有效
- main：**18 章 90 关 / cap 42 / assets 101M**（三值本会话现测）
- 遗留债：worktree 0 / `worktree-*` 分支 0 / 远端只有 `main` / untracked 0
- battle-ui-v2：阶段 1-5 全收官，终验 94/100，PR #90 已 MERGED
- 武圣段：spec 已交付，**待拍板 9 项**，未动任何代码

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 武圣段 spec 拍板（推荐） | opus high | ~10min | 9 项全待答，是 Ch19 唯一前置；回「全 A」或「1A 3B 9C」式即可解锁，成本极低收益最大 |
| 2 | Ch19 实装批（cross-tier 首章） | opus xhigh | ~3-4h | 须先完成 #1；reconcile 面见 spec §8，实装前必重跑 Phase-0 复定行号 |
| 3 | `build/visual_acceptance` 375M 清理拍板 | opus high | ~5min | 已连挂 2 轮交接；`build/` 全 gitignored 不影响仓库，但删除不可逆需一句授权 |
| 4 | 三弟子年龄 1 句改 | opus high | ~15min | `stage_18_04_opening:7`「五十上下」vs `:15`「守了几十年」；便宜，可搭 #2 车 |
| 5 | 三处 stale 注释顺修 | opus high | ~15min | `numbers.yaml:1392` / `masters.yaml:3` / `equipment.yaml:17` 均写「飞升 Demo 不做」已被推翻；建议并入 #2 |

【硬约束沿用】
- **别把「抬 cap」读成「玩家能到那一层」**：全内容参考路线实测终态 Lv121 = **绝对层 13**（三流·化境），
  cap 42 是成长上界不是到达点，玩家靠挂机爬境界（Lv121→Lv141 缺口 4425 EXP ≈ 37 天墙钟）。详 spec §2。
- **武圣段数值轴已尽**：Boss HP 只剩 500 头寸（59500/60000）、敌攻 2000 已用尽、tier7 招 cap 8000 = §5.4
  全局硬红线本身无上浮空间 → 难度只能 100% 走机制层，不要试图靠抬数值做难度。
- **CI 轮询用 `gh pr view --json statusCheckRollup`**，别用 `gh pr checks`（pending 时返回非 0 会搞挂等待循环）。
  查 PR 合并态用 `--json state,mergedAt,mergeCommit`，`merged` 字段不存在，字段名错会让整条 `&&` 链静默中断。
- **远端分支真实状态以 `git ls-remote` 为准**，`git branch -r` 在远端删除后仍留 stale ref，须 `fetch --prune`。

【防幻觉守则】
- 本提示词【环境快照】里的数字是上一会话实测的快照；新会话改动代码后**必须重新实测**，禁直接转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 含中文的绝对路径跑 find/cd 会给错结果 → 先 cd 再用相对路径。
- 完整守则见 memory `reference_anti_hallucination`（已列入上方「选读 memory」）。

【先报告】
读完上述清单后：1. 报告 PROGRESS.md 和 session 记录的关键信息 2. 确认环境状态（现跑 HEAD / status / worktree list）
3. 把武圣段 spec §6 的 9 项待拍板逐项摆出来请用户拍板。**不要直接动代码。**
