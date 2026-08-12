# 新会话开局清单

> 交接时间：2026-08-12 00:11 · 工作收口于 HEAD `be029505` · 与 origin 同步(`feat/aptitude-birth-rarity` 已 push)、工作树干净
> ⚠ **本清单住在分支 `feat/aptitude-birth-rarity` 上,不在 main**。PR #119 合并前,main 上的 `docs/sessions/NEXT.md` 还是**上一轮(2026-08-11 15:36)的旧版**。若你在 main 上读到「资质三连已拍待做」那份,说明 PR 还没合——先合 PR 再回来读这份。
> 本清单自身的落盘 commit 排在 `be029505` 之后,故实际 HEAD 会比它新 1 个纯文档 commit——**这不是漂移**,判据见【开局动作】第 4 步。

## 【本会话契约】（置顶，最高优先级）

- **模式：只读**
- **只读模式**：完成【开局动作】并提交【先报告】后，等用户指令才可动代码。
- **范围围栏**：只做用户选定的任务。过程中发现的其他问题分两类处置——
  - **非阻塞型**（不影响当前任务正确性）→ 记入根目录 `BACKLOG.md`，附 file:line 与复现步骤，**不动代码**；
  - **阻塞型**（当前任务建立在它之上，不修就是在错地基上盖楼）→ **停下报告**，不要记了账继续干。
- **拍板点**（设计取舍、多方案选型、观感判断）：只读模式下停下列选项等用户，**禁代拍**。
- **决策三级**：🟢 路径纠正/假阳过滤/只读审计可自决 · 🟡 新增审计方向/范围增减 >30%/跨模块重构可调查不可合并 · 🔴 GDD 解释/数值规则/schema/玩家可见 UI/正式美术替换/删字段**必须停在 [BLOCKED] 等用户**。

项目：挂机武侠（`/Users/a10506/Desktop/Projects/挂机武侠`）

上一会话实装 P11 资质三连(BACKLOG 一#15 旧档档位回填 + 一#16 chip 括注),已推分支开 PR #119 待合;过程中**踩到并登记了一个真实缺陷:跑视觉路由会静默迁移生产存档**(BACKLOG 二#12),且它已经把用户的存档 slot 1 顶到了 `0.39.0`。

## 【开局动作】

1. 读 PROGRESS.md 顶段「**2026-08-11 P11 资质三连实装**」条目
2. 读 `docs/sessions/2026-08-12_001100_资质三连_p11-aptitude.md`
3. `git worktree list` + `git branch --list`：**预期见到 main + `feat/aptitude-birth-rarity` 两个 worktree**(后者在 `.claude/worktrees/p11-aptitude`,故意保留等 PR 合)。若 PR 已合且分支已删,只见 main 也正常
4. **只 `git fetch`,不自动 rebase/autostash**：

   ```bash
   git status -sb | head -1
   git fetch origin
   git rev-list --left-right --count origin/main...HEAD
   git merge-base --is-ancestor be029505 HEAD && echo ANCESTOR_OK
   ```

   - 工作树 dirty / 有分叉 / 有其他活跃写者 → **停下报告**，不自行更新；干净且可 FF 才 `git merge --ff-only origin/main`
   - `ANCESTOR_OK` 且 `ahead ≤1`（那 1 个是本清单自身的 commit）→ 快照有效
   - `--is-ancestor` 不成立 → **快照作废**：停下报告差异，重测基线，禁转抄下方数字
   - **并发检查**：`~/.claude/locks/` 下协调锁。⚠ 该锁 `heartbeat_at` **全程不更新**，**不能用心跳新鲜度判活**，须查 pid 存活 + git tip 是否推进
5. 选读 memory：`reference_anti_hallucination`（固定）+ `feedback_isar_pitfalls` / `feedback_wuxia_pen_build_runner` / `feedback_bg_session_write_guard_subagent_dev` / `feedback_no_effort_saving_in_recommendations` / `feedback_negative_grep_not_proof_of_absence`

## 【环境快照】（实测；改动代码后必重测，禁转抄）

- HEAD `be029505`（本 session 3 commit，**已 push**；`feat/aptitude-birth-rarity` 与 origin 同步)
- **main 仍在 `c25a29fa` 未动**(`git worktree list` 实测)。main 的测试基线沿用上轮 **4910 pass / 0 fail**(2026-08-11 实测,其后 main 无 `.dart` 改动)
- 以下数字**在 worktree `p11-aptitude` 实测**(该分支即 PR #119 内容)：
  - `flutter analyze --no-pub` → **No issues found!** exit 0
  - 全量 `flutter test --no-pub` → **4917 pass / 0 fail**，exit 0，5m22s
  - **守恒核对**：4917 = 上轮基线 4910 + 本批新增 7(`rarity_birth_migration_test` 5 例 + `lineage_character_detail_screen_test` 资质 chip 2 例)，逐值吻合
  - CI 对 `be029505` 与 `1c6f5af8` **均 conclusion=success**(两 job:`macos-build` 含 format 门禁 + `test` 含带覆盖率跑测与行覆盖率棘轮)
- **在途 PR / 分支**：
  - **PR #119** `feat/aptitude-birth-rarity` → main，**OPEN / MERGEABLE**,CI 全绿,**等用户合**。合它同时会把上一轮未 push 的交接 commit `c25a29fa` 带进 origin/main
  - worktree `.claude/worktrees/p11-aptitude` 故意保留(PR 未合);合后可 `git worktree remove` + `git branch -d`
  - 远端 4 个遗留备份分支(`codex/taohua-art-0807` / `pi/p6-link-label-0808` / `qoder/p4-audit-scripts-0808` / `worktree-claude-rarity`)= 滚动池 P12 待拍，**已续传 3 轮**
- **⚠ 用户存档 slot 1 已被顶到 `0.39.0`**(上一会话跑视觉路由烟测所致,BACKLOG 二#12)。**数据零损**(逐角色探针确认),但 **main 构建打不开它**,合 PR #119 即恢复。slot 2/3(`0.33.0`)未受影响
- 滚动池：待发 3 条 = **P2** 真机录屏管线(需真机位) · **P10** 扫描范围收敛(**范围已拍板取 (b) 单列一类,可直接实装**) · **P12** 远端分支清理(待拍)
- BACKLOG：一区 **6** 项待拍板(#4/#5/#6/#17/#18/#19) · 二区 3 项可派(含新登记的 **二#12**) · 三区 3 项上游依赖锁死

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | **修 BACKLOG 二#12 视觉路由存档隔离(推荐)** | opus high | 20-30min | 备局的**前置**——备局交付就是让用户跑 8 条视觉路由,不修等于递雷;且每次 saveVer bump 都会复现,是长期地雷 |
| 2 | 备真机决策局 | opus | 60-90min | 一局解 8 项积压决策(工程面 9.5/10 vs 流程面 4.5/10,瓶颈明写在决策积压)。构建与路由映射已就绪,差清单+启动脚本。**须先做 #1** |
| 3 | P10 扫描范围收敛 | opus | 30-45min | 范围已拍板 (b) 单列一类;顺带接上 `doc_link_scan.py:59` 那个「定义后全仓零消费」的 `EXCLUDE_DIRS` |
| 4 | 拍 P12 远端 4 分支 / 一#17 C2b 四图 / 一#18 README 定位 | 用户 | 20-30min | 三项同为纯拍板,攒一起效率高;C2b 复检图已备在素材目录 |
| 5 | 安排试玩局 | 用户 30-60min | — | 依赖候选 2 的备局产出才划算 |

## 【硬约束沿用】

- 跑 debug 构建的视觉路由会开并迁移**真实存档** → BACKLOG 二#12(修之前别随手跑)
- isar_community 把 Isar collection 的类内公开 getter 生成成**持久化属性**,派生值走 extension → memory `feedback_isar_pitfalls`
- `DEVELOPER_DIR` 带进 `flutter build macos` 即报 xcodebuild 找不到 → memory `feedback_developer_dir_breaks_flutter_macos_build`
- 否定式 grep 不是存在性证明;`git grep -E` 是 POSIX ERE 不认 `\s` → memory `feedback_negative_grep_not_proof_of_absence`
- 破坏证红必须在 commit 之后做 → memory `feedback_break_red_after_commit`
- 测试不得绕开生产路径,自检「破坏那行,这条断言必然红吗」 → memory `feedback_test_bypasses_production_path`
- commit message 必须中文动宾(§11 + 合并 Gate ⓓ) → memory `feedback_wuxia_commit_message_chinese_gate`
- 写守卫看会话 cwd 不看目标路径;文档也不得用 heredoc 绕守卫 → memory `feedback_bg_session_write_guard_subagent_dev`
- schema/provider 批 merge 回主 checkout 后必跑 `build_runner` → memory `feedback_wuxia_pen_build_runner`
- 写完 dart 必 `dart format`(CI 门禁,不在 §8.2 Gate 清单里易漏) → memory `feedback_wuxia_ci_format_gate_not_in_merge_gate`
- 推荐不得为省工作量缩水,出推荐前做「工作量无关」自检 → memory `feedback_no_effort_saving_in_recommendations`
- 长寿文档的行号/路径/「已实装」状态会 drift,引用前重新定位 → memory `feedback_living_doc_state_drift`

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测快照；改动代码后**必须重测**，禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功；**退出码要看归属**——管道后 `$?` 是末端命令的码(上一会话实录:`flutter test | tail -30` 报 exit 0,真实是 1 fail 且详情被截掉,整轮重跑才找回)。
- **空 grep 结果不是不存在**：先怀疑自己的正则/路径写法，换写法或纯字符串交叉验证一遍。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】（与置顶契约呼应）

读完上述清单后先提交一份报告，**不动代码**：

1. **防装读要求**：须引用本清单里**不存在**的原文——PROGRESS.md 顶段条目的**原文标题行与日期**，以及 `docs/sessions/2026-08-12_001100_资质三连_p11-aptitude.md`「重要决策」小节的**原文首条**。只复述本清单已有信息不算完成。
2. 报告【开局动作】第 3、4 步结果：在途分支情况 + HEAD 校验判定（有效 / 作废）+ **PR #119 是否已合**。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`（Step 0-4 为 canonical 流程，此处不复述）。
