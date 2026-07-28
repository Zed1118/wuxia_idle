# 新会话开局提示词

> 交接时间：2026-07-28 11:47 · HEAD `8d5f29c0`（现跑 `git rev-parse --short HEAD` 复核）
> 动手前先核头部 HEAD sha 与 git 实况，漂移先报告偏差再动。

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

Ch18「阳关故人」四项全闭环（内容 PR #86 / 美术 #87 / webp #88 / canon #89 全 MERGED），宗师段 Ch16-18 整段收官。主 checkout 干净、与 origin 同步、零在途分支与 worktree。

开局动作：
1. 读 PROGRESS.md 顶段 2026-07-27 Ch18 条目
2. 读 docs/sessions/2026-07-28_1147_Ch18三批收官.md
3. git pull --rebase --autostash
4. 选读 memory：reference_anti_hallucination（固定）
   + feedback_living_doc_state_drift（**类型 F 新增**：交接带的诊断本身会错，照做前必证伪）
   + feedback_visual_acceptance（Claude 视觉终判闸门）
   + feedback_wuxia_webp_cleanup_recipe（含新增 #5b：目检不能丢 alpha）
   + feedback_gh_pr_mergeable_vs_local_divergence（PR 合并前本地 merge-tree 复算）
   + feedback_exit_worktree_merged_branch_warning（清 worktree 三验）

【环境快照】（2026-07-28 主 checkout 实测，新会话改动后须重测）
- HEAD `8d5f29c0`（本会话 8 commit，已全部 push，与 origin 同步，工作树干净）
- `flutter analyze --no-pub` **EXIT=0 · No issues found**（4.4s）
- 受影响测族 9 文件 **59 pass / 0 fail**（逐文件 EXIT=0）
- 全量未在主 checkout 跑；PR #89 分支 CI 全量 test **pass（22m57s）**、macos-build pass
- main：18 章 90 关 / cap 42 / `mount_deferred` 全仓 0 / `known_missing_assets` 全表归零
- assets **101M**；`build/dispatch` 36M · `build/visual_acceptance` 204M（含待清 111M）

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | battle-ui-v2 阶段 5 全模式终验（推荐） | opus high | ~1.5h | 唯一必须真人独占 app 与屏幕的项，只有用户在场才做得了；做完可回收 111M |
| 2 | 三弟子年龄弱矛盾 1 句改 | opus high | ~15min | `stage_18_04_opening:7`「五十上下」vs `:15`「守了几十年」；便宜，可搭下批顺手做 |
| 3 | 武圣段 spec 起草 | opus xhigh | ~2h | cross-tier，reconcile 面重新变大，需专会话 |
| 4 | `chapter_16:18` 软点 | opus high | ~20min | 已判不改（会波及 Ch16 收束段），仅在用户改主意时做 |

【硬约束沿用】
- **交接文档里的「诊断/方案」当待证命题，不当事实**：本轮交接三条诊断两条不成立（形制不同=两件东西非缺陷；D3 早已写死在原文），照做会变 26 站点大改。站点数也别信，现 grep。
- **改已发布叙事前先翻原文找现成伏笔**：用伏笔（如 `chapter_05:6`「二十二天」）比新增设定便宜一个量级，且不破已有情感段落。
- **不采信 codex 自评**：Claude 逐图视觉终判是必过闸门；机械判据走 `build/dispatch/gate_precheck.py`（另存 `~/scripts/wuxia_gate_precheck.py`），身份对位另走「逐图对叙事原文」。
- codex CLI 正解 = `codex exec -C <dir> -s workspace-write -i a.png -- "$PROMPT" < /dev/null`（`--` 终止变参 + 显式喂 EOF，缺一挂死）。

【防幻觉守则】
- 本提示词【环境快照】里的数字是上一会话实测的快照；新会话改动代码后**必须重新实测**，禁直接转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 `file:line`；不确定写「不知道」，不凭记忆硬答。
- 含中文的绝对路径跑 `find`/`cd` 会给错结果 → 先 `cd` 再用相对路径。
- 完整守则见 memory `reference_anti_hallucination`。

【先报告】
读完上述清单后：1. 报告 PROGRESS.md 和 session 记录的关键信息 2. 确认环境状态（现跑 HEAD / status / worktree list） 3. 不要直接动代码。
