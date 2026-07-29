> 交接时间：2026-07-29 16:30 · HEAD `0af07aaa`（main，ahead origin 1，**未 push**）

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

Ch20 三 PR 已由 codex 审查合并进 main；Ch21「绝顶交程」主线终章整章实装完毕在 **PR #96**（draft）待人工 review。main 工作树干净，本地领先 origin 1 个 commit（session 记录，待 push）。

开局动作：
1. 读 PROGRESS.md 顶段 2026-07-29 条目
2. 读 docs/sessions/2026-07-29_1630_Ch21终章.md
3. git pull --rebase --autostash（注意本地 ahead 1，先 push 或确认）
4. 选读 memory：reference_anti_hallucination（固定）
   + feedback_multi_anchor_test_actual_attribution（链式锚点逐环单文件复跑）
   + feedback_break_red_after_commit（破坏证红纪律）
   + feedback_wuxia_add_mainline_chapter_reconcile（加章站点面）
   + feedback_chinese_path_shell_pitfalls（zsh 坑，本轮 for/while/{} 全踩）
   + reference_codex_image_gen_art_pipeline（美术批配方）

【环境快照】（2026-07-29 16:30 主 checkout 现测）
- main HEAD `0af07aaa`（本会话 main +1 docs commit，**未 push**；sha 由 `git rev-parse --short HEAD` 现跑）
- 主 checkout `flutter analyze --no-pub` **EXIT=0 · No issues found**（4.9s）
- 主 checkout **全量 4713 pass / 0 fail · EXIT=0**（`[E]` 0 · 10m01s；慢因 codex 美术批抢 CPU）
- main 主线 **20 章 100 关 / cap 47**（Ch21 在 PR #96 未合）
- **PR #96** `9af9af1c` draft — Ch21 终章：5 关 / 真解 7800 / 神物收口 / 叙事 6673 字 / cap 47→49 / surviveTicks 主线首用+表现层；分支实测 analyze 0 + 全量 **4719/0** + 双破坏证红
- 遗留 1 worktree + 1 同名分支（撑 PR #96，合并后清）
- **Ch20 美术批在飞**：codex image_gen 后台跑（16:05 启动），产物落 `build/dispatch/ch20_art_20260729/out/`

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | Review PR #96 六项拍板 + 飞升 canon（推荐） | opus high | ~30min | 唯一需人拍板项；章名/末Boss 定错则 6673 字叙事全废，先拍最省返工 |
| 2 | 收 Ch20 美术批 → 接线 + 脚底 fraction 实测 + known_missing 清零 | opus high | ~40min | 依赖美术批跑完；沿 Ch16-19 体例 |
| 3 | Ch21 美术 11 图派单 | codex image_gen | ~1h | 前缀 `jueding_*`，五人全新无人物锚 |
| 4 | Ch19+Ch20 共 22 张 PNG webp 清账 | opus high | ~1h | 沿 PR #77/#85/#88 配方；别先 dry-run |

【硬约束沿用】
- **zsh 在本 harness 不吃 `for` / `while` / `{ }` 分组**（本轮多次 parse error）→ 改逐条命令或 python 脚本文件。
- **锚图 webp-in-png**：Ch15/16 清账过的图扩展名 `.png` 实为 WebP，喂 codex `-i` 前必 sips 解码。
- **探针与生产必须同路**：`progression_battle_probe` 曾不透传 `stage.winCondition`，校准配该条件的关前先确认探针没分叉。
- 破坏证红只在 commit 后做，且**不与在跑的全量并行**。

【防幻觉守则】
- 本提示词【环境快照】里的数字是上一会话实测的快照；新会话改动代码后**必须重新实测**，禁直接转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

【先报告】
读完上述清单后：1. 报告 PROGRESS.md 和 session 记录的关键信息 2. 确认环境状态（HEAD/status/worktree/PR/美术批产物）3. 不要直接动代码。
