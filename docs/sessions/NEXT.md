项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

Ch17「沙海纵深」美术 11 图已全部出图并接线，Ch17 全章闭环，主线 17 章 85 关美术齐备、缺图 allowlist 清零。**代码成果在 draft PR #84，尚未合入 main**——main 上只有本次 handoff 的 docs commit，无 Ch17 美术改动；工作树净、与 origin 同步。

开局动作：
1. 读 PROGRESS.md 顶段 2026-07-26「Ch17 美术 11 图接线」条
2. 读 docs/sessions/2026-07-26_2323_Ch17美术.md
3. git pull --rebase --autostash（应为 no-op；先确认不会打乱）
4. 选读 memory：reference_anti_hallucination（固定）
   + reference_codex_image_gen_art_pipeline（美术管线·本轮新增两条教训）
   + feedback_visual_acceptance（Claude 终判闸门·本轮实锤 codex 自评说反话）
   + feedback_wuxia_webp_cleanup_recipe（若做 webp 清账批）
   + feedback_flutter_test_batch_silent_skip（targeted 必逐个单跑）

【环境快照】
- main HEAD：**现跑 `git rev-parse --short HEAD` 取，禁转抄本文**。main 上本会话只落了 handoff docs commit；**代码成果在分支 `worktree-ch17-art`（2 commit·已 push·PR #84）**，未合 main
- PR **#84** draft · OPEN · MERGEABLE · 14 文件（11 图 + PROGRESS + character_avatar + allowlist）
- `flutter analyze --no-pub` **EXIT=0 · No issues found** —— 2026-07-26 23:2x **主 checkout** 实测
- 全量 `flutter test --no-pub` **4711 pass / 0 fail**（EXIT=0 · `All tests passed!` · `-1` 0 · `[E]` 0）—— 2026-07-26 **分支 `b420fc56` worktree 实测**；main 未含本批改动，其绿态沿用 `754c96b6` 同数字。**改动代码后必须重新实测。**
- 主线 17 章 85 关 · cap 40 · `known_missing_assets` **清零** · asset_audit **430 引用/430 存在/缺失 0**
- assets **114M**（本批 +14M 真 PNG 待 webp 清账）
- PROGRESS **98 行**（100 上限内·本轮净增长 0）

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 审并合 PR #84（推荐） | opus high | ~20min | Ch17 美术只有合入 main 才算真闭环；14M 体积债也要等合入后才能清 |
| 2 | 清 8 个僵死 flutter_tester + 删残留远端分支 | — | ~5min | 两条命令均已验零风险，仅需授权；疑僵死进程拖慢全量 7m33s vs ~2.5min |
| 3 | Ch17 webp 清账小批 | opus high | ~40min | 14M→~1.5M，配方成熟；**须在 #84 合入后做** |
| 4 | Ch18「天地之远」spec 起草 | opus high | ~2h | 宗师段收官章；cap 40→42 封顶·yang_guan 收编·全机制 0.12 |

【硬约束沿用】
- **Ch18 spec 起草前必读 Ch17 spec §1**：那里记了上游段级 spec 的三处事实错（skill 计数 / fang 变体性质 / 三灵巧向），段级 spec 本身**未回改**，不读会再踩。
- **codex 自报不可采信为验收依据**：本轮它自评黑风刀客「厚背阔刀识别明确」，实为双刃直身剑。Claude 视觉终判必须逐图自己看。
- **`git show ref:中文路径` 比对必看字节数**：两侧都取不到会得到相同空哈希、**假报「内容一致」**。
- **zsh 无 `$PIPESTATUS`**（是 `$pipestatus` 且 1-indexed）：取到空值会让「EXIT=0」变成无证据断言，改用 `cmd > log; echo $?`。

【防幻觉守则】
- 本提示词【环境快照】里的数字是上一会话实测的快照；新会话改动代码后**必须重新实测**，禁直接转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

【先报告】
读完上述清单后：1. 报告 PROGRESS.md 和 session 记录的关键信息 2. 确认环境状态（main HEAD / PR #84 状态 / 有无在途 worktree）3. 不要直接动代码。
