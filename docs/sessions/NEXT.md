> 交接时间：2026-07-25 15:48 · **HEAD = 本文件自己的 handoff commit**（末次纯 docs commit；其父 `9194c2c8` 是最后一个代码 commit）
> 新会话打「开工」= 读本文件按其执行。核对方式：`git log -1` 应是本 handoff 的 docs commit、`git log -1 --format=%p` 应含 `9194c2c8`；对不上再报偏差。

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

工程侧三批已闭环合 main（中文散写门禁 + CI 随机红根因根治 + §一#12 拍板 D 落地），
main@`9194c2c8` = origin/main、树净、零孤儿 worktree/分支。下一波转内容/资产面。

开局动作：
1. 读 PROGRESS.md 顶段 2026-07-25「工程门禁 + CI 随机红根治三批」条
2. 读 docs/sessions/2026-07-25_1547_门禁与CI随机红根治.md
3. git pull --rebase --autostash
4. 选读 memory：reference_anti_hallucination（固定）+ 候选 1 加读
   feedback_wuxia_pen_build_runner；候选 2 加读 feedback_paper_vs_dark_text_color_palette；
   候选 4 加读 feedback_wuxia_add_mainline_chapter_reconcile + feedback_wuxia_release_cap_raise_reconcile

【环境快照】
- 最后代码 commit `9194c2c8`（本会话 main +3 = PR #74/#75/#76 三个 merge·全 push·2026-07-25 现跑
  `git rev-parse` + `git show --stat` 逐个实证）
- 主 checkout 实测（合 #76 后·build_runner 66 outputs 在先）：analyze **0**；
  全量 **4657 pass / 0 fail**（EXIT=0·-1 标记 0 处）
- 中文门禁已上线：`test/tools/chinese_literal_audit*` 双 guard 绿，allowlist 生效条目实测 **26**
- 主线 16 章 80 关·cap 38·美术全补齐（known_missing 非注释行 0）
- **CI 随机红已除**：稀有彩头打翻精确掉落断言的根因已根因修（PR #75），
  再见同型红按「新增回归」查，别当已知 flaky 重跑
- kimi 2026-07-26 10:10 前配额不可用（派单走 Claude/codex）

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | webp 清账小批（Ch16 11 图 17M）（推荐） | opus high | ~30min | 沿 #63/#66/#70 先例，`convert_assets_webp.py` 幂等；面小闭环快，销掉 Ch16 美术批最后一项已知风险 |
| 2 | 中文散写存量 26 条清理（§二#3） | opus high | ~1-1.5h | A 类（synergy_def 6 / asset_fallback / equipment_glyph / item_slot / tower_entry_flow）+ B 类（master_builder 4 / gauntlet 3）迁 UiStrings；C 类占位可留 |
| 3 | `damage_popup` parse-back 耦合（§二#4） | opus high | ~30-45min | 消除对 `UiStrings.criticalDamagePopup` 输出的反解析，上游传结构化数据；修完销 allowlist 最后一条 E 类 |
| 4 | Ch17「沙海纵深」实装批 | opus **xhigh 专会话** | ~3.5-4h | spec §8 前瞻已定向；idle_horizon s1 45.6/下沿 45 贴线必破须重校 |
| 5 | BACKLOG §一#8 剩余 8 处 DefaultRng 收口 | opus high | ~1h | 非阻塞洁癖项，CI 红已不再由它引发，优先级低于上四项 |

【硬约束沿用】
- **`gh pr merge` 对 draft PR 会失败**（`still a draft`），且接管道时 `echo EXIT=$?` 取的是管道尾码
  会把失败读成成功。先 `gh pr ready <n>`，合完必查 `gh pr view <n> --json state,mergeCommit`。
- flutter test 禁裸接管道：`> file 2>&1; echo EXIT=$?` 显式取码；破坏证红在 commit 后做
  （commit 前 `git checkout --` 会抹掉全部未提交改动）。
- Edit dart 文件 commit 前必 `dart format`（CI format gate 先于测试）。
- 合并纪律：审 diff 后合，合并后主 checkout `build_runner` + `analyze` + 复验。
- **单次 CI 绿不构成 flake 已除的证据**；要证随机性问题得用破坏证红 + 重复跑。

【防幻觉守则】
- 本提示词【环境快照】数字是 2026-07-25 15:47 主 checkout 实测快照；新会话改动后必须重新实测，禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

【先报告】
读完上述清单后：1. 报告 PROGRESS 顶段与 session 记录关键信息 2. 确认环境状态（HEAD/树净/同步）
3. 不要直接动代码。
