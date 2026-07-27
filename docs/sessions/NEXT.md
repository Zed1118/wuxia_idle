# 新会话开局提示词（覆盖式 · 新会话打「开工」= 读本文件按其执行）

**交接时间：** 2026-07-27 14:49
**主 checkout HEAD：** `bc6064f9`（ahead origin/main 1 · 未 push）
**PR 分支 HEAD：** `fcf3e344`（已 push · PR #86 draft OPEN）

> 动手前先核头部 HEAD sha / 时间与 git 实况；漂移（HEAD 不符 / 明显过期）先报告偏差再动。

---

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

Ch18「阳关故人」宗师段收官章内容层已全部实装完成并全绿，**停在 draft PR #86 待审合并**。
主 checkout 干净、领先 origin 1 commit（`bc6064f9` = Ch18 章级 spec，纯文档，未 push）。
注意：**main 上仍是 17 章 85 关 / cap 40**，18 章 90 关 / cap 42 全在 PR #86 里，未合。

开局动作：
1. 读 PROGRESS.md 顶段 2026-07-27「Ch18「阳关故人」宗师段收官章实装」条
2. 读 docs/sessions/2026-07-27_1449_Ch18实装.md
3. git pull --rebase --autostash
4. 选读 memory：reference_anti_hallucination（固定）
   + feedback_wuxia_add_mainline_chapter_reconcile（加主线章站点清单）
   + feedback_wuxia_release_cap_raise_reconcile（抬 cap 站点）
   + feedback_visual_acceptance + reference_codex_image_gen_art_pipeline（若开美术批）
   + feedback_chinese_path_shell_pitfalls（中文名 heredoc / zsh 不分词）
   + feedback_bg_worktree_baseref_fresh_diverge（bg 开 worktree 会基于 origin 漏本地 commit）

【环境快照】
- 主 checkout HEAD `bc6064f9`（ahead origin/main **1**，未 push；该 commit 同时在 PR 分支内，PR 合后本地可直接快进，无分叉）
- PR 分支 `worktree-ch18-yangguan` HEAD `fcf3e344`（已 push · PR #86 draft OPEN · MERGEABLE）
- 主 checkout `flutter analyze --no-pub` **EXIT=0 · No issues found（4.9s）** —— 2026-07-27 本会话实测
- 主 checkout **全量本会话未跑**（代码改动全在 PR 分支）。最近一次主 checkout 全量 = **4711/0 @ `80531d37`**（2026-07-26 实测）
- PR 分支 `fcf3e344`：analyze EXIT=0 + 全量 **4711 pass / 0 fail**（EXIT=0 · `[E]` 0 · `-1` 0 · 4m35s）—— 2026-07-27 worktree 实测
- 内容规模：**main 上 17 章 85 关 / cap 40**；PR #86 内 **18 章 90 关 / cap 42 / mount_deferred 全仓归零**
- assets **99M** · `build/dispatch` **25M** · `build/visual_acceptance` **204M**（含 111M 待阶段 5 终验）
- PROGRESS：PR 分支内 **96 行**（main 上仍 98 行）

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 审并合 PR #86（推荐） | opus high | ~30min | 内容层已全绿只卡 review；不合就没法开美术批，且本地 main 一直领先 origin |
| 2 | Ch18 美术 11 图 codex image_gen 专批 | opus high | ~2h | 沿 Ch14-17 配方；**须先合 PR #86** |
| 3 | 压缩全局 `MEMORY.md` 163→<140 行 | opus high | ~20min | hook 已提示；需逐条判断可合并/过时项 |
| 4 | battle-ui-v2 阶段 5 全模式终验 | opus high | ~1.5h | 需独占 app 与屏幕；做完可回收 111M |

【硬约束沿用】
- **spec / 代码注释里写的「判据公式」可能压根不是活代码**：`data/numbers.yaml:206` 连写三章的 `RealmTier.values[(cap-1)~/7]` 在全 `lib/` grep 不到，真判据是 `getRealmByAbsoluteLevel(cap).tier`（`game_repository.dart:865` → `skill_red_lines_validator.dart:109`）。引用任何「判据/公式」前先 grep 确认它存在，别信注释自述。本批已订正该注释。
- **既有人物复出的关，先 grep 其原始 def 再写数值**：Ch18 三弟子 school 在 Ch5 已定 `yinRou`，spec 草案凭印象写成 gangMeng。人物连续性优先于配平美观。
- **叙事人物关系必须全 narratives grep**：`chapter_07`/`chapter_09` 才证得出「李寒 = 主角师父」，Ch16/17 一律用「那个背剑的人」指代，只读近两章会误判成路人。
- **bg 会话 Write 被守卫拦时纯文档走 Bash heredoc，但中文文件名不能做重定向目标**（静默不落盘）——用 ASCII 临时文件 + `cp` 落中文名，写完必 `ls` 实证。
- **bg 开 worktree 会基于 origin 而非本地 HEAD**：本地有未 push commit 时新 worktree 会缺，须 `git merge --ff-only main` 先对齐（本批踩过）。

【防幻觉守则】
- 本提示词【环境快照】里的数字是上一会话实测的快照；新会话改动代码后**必须重新实测**，禁直接转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 `file:line`；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

【先报告】
读完上述清单后：1. 报告 PROGRESS.md 和 session 记录的关键信息 2. 确认环境状态（现跑 HEAD / status / worktree list / PR 状态） 3. 不要直接动代码。
