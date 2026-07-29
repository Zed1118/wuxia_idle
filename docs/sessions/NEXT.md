# 新会话开局提示词

**交接时间：** 2026-07-29 23:14 · **代码态锚点：** `5f049a79`

> 锚的是**代码态**不是 HEAD：`5f049a79` 之后只有 NEXT.md 自身的 docs commit，`lib/`/`data/`/`test/` 零改动。
> 开局请 `git rev-parse --short HEAD` 自验——只要 `git diff --stat 5f049a79..HEAD -- lib data test` 为空即无漂移。

---

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

主线内容与配套美术已全闭环（21 章 105 关 / cap 49 封顶 / 缺图 allowlist 全表归零），本会话 4 个 PR 全合。HEAD `5f049a79`，工作树干净，与 origin/main 已同步。下一波转 1.0 打磨期的验收/UI 线。

开局动作：
1. 读 PROGRESS.md 顶段 2026-07-29「主线终章闭环批」条目
2. 读 docs/sessions/2026-07-29_2314_主线终章闭环.md
3. git pull --rebase --autostash
4. 选读 memory：reference_anti_hallucination（固定）
   + feedback_visual_acceptance（真机目检 SOP，下一波主线）
   + feedback_flutter_macos_drive_screenshot（驱动运行中 app 截图，AX click 无效需 CGEvent + retina 2x 换算）
   + feedback_codex_imagegen_moderation_and_framing（本会话新增）
   + feedback_redline_test_fixture_vs_production_guard（本会话新增）
   + feedback_visual_check_real_target_bg（alpha 素材必合成到真面板底色验）
   + feedback_visual_score_first_pass_underestimate（视觉打分首轮系统性低估）

【环境快照】（全部 2026-07-29 23:0x 主 checkout 实测，非转抄）
- 代码态锚点 `5f049a79`（本会话 18 commit + 2 个 docs commit，**已全部 push**）
- 主 checkout `flutter analyze --no-pub` **EXIT=0 · No issues found**（4.4s）
- 主 checkout 全量 **4719 pass / 0 fail · EXIT=0**（`[E]` 0 · 失败行 0 · 6m11s）
- 主线 **21 章 105 关 / cap 49 封顶**；飞升条件③ 首次可达（系统早已实装，只差 cap）
- `known_missing_assets` **待补项 0**（主线全章美术补齐）；`assets/` **107M**
- worktree：主 checkout + 遗留的 `.claude/worktrees/ch21-dropfix`（detached HEAD·零改动·可删）
- 分支：本地/远端均只剩 main

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | Ch20/Ch21 共 10 张立绘真机战斗屏目检（推荐） | opus high | ~40min | 这两批唯一没做的验收维度；美术已冻结，拖久返修成本更高 |
| 2 | battle-ui-v2 遗留 B3/C5/F2 三项差距评估与处置 | opus xhigh | ~1.5h | B3 要动 `_mainlineSceneColorGrade` 波及 90 关已终拍美术，须先拍板范围 |
| 3 | 桌面语义（semantics/键盘/focus/cursor）专项量测 | opus high | ~1h | 阶段 5 终验明确未做，是一票否决 6 条里唯一没量测的 |
| 4 | `build/` 5.5G 陈旧 dill 缓存回收 | 任意 | ~2min | 一条命令：`find build -maxdepth 1 -name '*.cache.dill.track.dill' -delete` |

【硬约束沿用】
- **codex 自报一律不可信**：本会话它自报「11 张出齐」时 `out/` 实为空、自报「已补褪白绳」实为未加。规格与目检必须自己复测。
- **破坏证红别按文件名挑测**：名字带 `redline` 的可能是合成 fixture、不读生产 yaml，会给假绿；真守卫常在 `loadAllDefs` 加载链上。
- **alpha 素材的画质/边缘判断必须合成到真实面板底色**，别拿裸 RGB 比（近零 alpha 像素会给出 255 的假报）。
- zsh 在本 harness 不吃 `for` / `while` / `{ }` 分组，改逐条命令或 python 脚本文件。

【防幻觉守则】
- 本提示词【环境快照】里的数字是上一会话实测的快照；新会话改动代码后**必须重新实测**，禁直接转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`（已列入上方「选读 memory」）。

【先报告】
读完上述清单后：1. 报告 PROGRESS.md 和 session 记录的关键信息 2. 确认环境状态（HEAD/status/worktree/assets/allowlist）3. 不要直接动代码。
