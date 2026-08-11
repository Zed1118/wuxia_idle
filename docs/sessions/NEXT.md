# 新会话开局清单

> 交接时间：2026-08-11 15:36 · 工作收口于 HEAD `9311f1d6` · 与 origin 同步(`0 0`)、工作树干净、worktree 与本地分支只剩 main
> 本清单自身的落盘 commit 排在 `9311f1d6` 之后，故实际 HEAD 会比它新 1 个纯文档 commit——**这不是漂移**，判据见【开局动作】第 4 步。
> ⚠ 该 commit **默认未 push**(`/handoff` 未带 `--push`)。若 `git status -sb` 显示 `ahead 1`，那就是它。

## 【本会话契约】（置顶，最高优先级）

- **模式：只读**
- **只读模式**：完成【开局动作】并提交【先报告】后，等用户指令才可动代码。
- **范围围栏**：只做用户选定的任务。过程中发现的其他问题分两类处置——
  - **非阻塞型**（不影响当前任务正确性）→ 记入根目录 `BACKLOG.md`，附 file:line 与复现步骤，**不动代码**；
  - **阻塞型**（当前任务建立在它之上，不修就是在错地基上盖楼）→ **停下报告**，不要记了账继续干。
- **拍板点**（设计取舍、多方案选型、观感判断）：只读模式下停下列选项等用户，**禁代拍**。
- **决策三级**：🟢 路径纠正/假阳过滤/只读审计可自决 · 🟡 新增审计方向/范围增减 >30%/跨模块重构可调查不可合并 · 🔴 GDD 解释/数值规则/schema/玩家可见 UI/正式美术替换/删字段**必须停在 [BLOCKED] 等用户**。

项目：挂机武侠（`/Users/a10506/Desktop/Projects/挂机武侠`）

上一会话跨 08-08→08-11 两天，收口了死链扫描器全线（P6 标注→P7 修复→P8 真 git fixture 测试）+ `/afk` 门禁三缺口 + 底账同步，并完成资质三连的 Phase 0。**当前无在途实装**，资质三连（P11）已拍板、可直接开工。

## 【开局动作】

1. 读 PROGRESS.md 顶段「2026-08-08 夜批(8h 挂机)」条目——**注意它末尾有两段续写**，最新状态在 **【2026-08-11 续】** 段
2. 读 `docs/sessions/2026-08-11_153624_扫描器收口_main.md`
3. `git worktree list` + `git branch --list`：**预期只有 main**。若见其他分支属异常，停下报告
4. **只 `git fetch`，不自动 rebase/autostash**：

   ```bash
   git status -sb | head -1
   git fetch origin
   git rev-list --left-right --count origin/main...HEAD
   git merge-base --is-ancestor 9311f1d6 HEAD && echo ANCESTOR_OK
   ```

   - 工作树 dirty / 有分叉 / 有其他活跃写者 → **停下报告**，不自行更新；干净且可 FF 才 `git merge --ff-only origin/main`
   - `ANCESTOR_OK` 且 `ahead ≤1`（那 1 个是本清单自身的 commit）→ 快照有效
   - `--is-ancestor` 不成立 → **快照作废**：停下报告差异，重测基线，禁转抄下方数字
   - **并发检查**：`~/.claude/locks/` 下协调锁。⚠ 该锁 `heartbeat_at` **全程不更新**（v2 缺口，池内 P9 已修的是别的三条），**不能用心跳新鲜度判活**，须查 pid 存活 + git tip 是否推进
5. 选读 memory：`reference_anti_hallucination`（固定）+ `feedback_negative_grep_not_proof_of_absence` / `feedback_bg_session_write_guard_subagent_dev` / `feedback_chinese_path_shell_pitfalls` / `feedback_wuxia_pen_build_runner` / `feedback_no_effort_saving_in_recommendations`

## 【环境快照】（实测；改动代码后必重测，禁转抄）

- HEAD `9311f1d6`（本 session 5 commit，**已 push**，`origin/main...main` = `0 0` 反验同步）
- `flutter analyze --no-pub` → **No issues found!** exit 0，5.1s｜2026-08-11 15:3x 主 checkout 实测
- 全量 `flutter test --no-pub` → **4910 pass / 0 fail**，exit 0，14m11s｜主 checkout 实测（跑在 `b408829c` 的树上）
  - **未重跑的依据（本会话实测）**：`git diff --name-only b408829c..HEAD -- '*.dart'` = **0 文件**，其后 6 个文件全是 md 底账 + `tools/` 下 Python。守 memory `feedback_test_cadence_no_blind_full`
  - **守恒核对**：4910 与上轮基线逐值相同——本 session 新增的 15+15 例都在 Python 侧，不进 Flutter 计数
- 工具层三套（均 `python3 <文件>` 直接跑，**不进 CI**）：`tools/test_doc_link_scan.py` **10/10**、`tools/test_doc_link_scan_gitfixture.py` **15/15**、`~/.claude/skills/afk/scripts/test_preflight.py` **34/34**，全 exit 0
- CI：对 `9311f1d6` **conclusion=success**（headSha 与本地 `rev-parse` 逐字符一致）。`ab38b43c` 那次显示 cancelled = 被随后的 push 取代，**不是红**
- 扫描器底账（P7 修复后）：`refs=7442 alive=5929 dead=908 ignored=605`，**两地逐值相同**（有/无 `build/` 的工作树），漂移 0
- **在途 PR / 分支：本地无**。远端留 4 个遗留备份分支——`codex/taohua-art-0807`、`qoder/p4-audit-scripts-0808` 实测 `main..分支` = **0 条独有**（可安全删）；`pi/p6-link-label-0808` = 2、`worktree-claude-rarity` = 3（rebase 前旧 SHA）。**已续传 2 轮，本轮登记为滚动池 P12 交用户拍**
- 滚动池（`docs/dispatch/pool/README.md`）：待发 4 条 = **P2** 真机录屏管线（需真机位）· **P10** 扫描范围收敛（待拍范围）· **P11** 资质三连（已拍待做）· **P12** 远端分支清理（待拍）
- BACKLOG：一区 **7** 项待拍板（含新补的 #17 C2b 四图 / #18 README 定位）· 二区 2 项可派 · 三区 3 项上游依赖锁死

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | **资质三连实装 P11（推荐）** | opus xhigh | 90-150min | Phase 0 已完且结论全部实测在案；**唯一玩家可见的现存缺陷**（老档显示错档位 + 新档「资优(27)」自相矛盾）。用户已拍板三个子项，含存档迁移 |
| 2 | 拍 P10 扫描范围收敛的范围 | 用户 + opus | 10min 拍 + 30-45min 装 | 939 条 dead 里 600 条来自 `docs/handoff/` 归档文档；唯一能把文档信噪比从根上抬起来的活 |
| 3 | 拍 P12 远端 4 分支 / 一#17 C2b 四图 / 一#18 README 定位 | 用户 | 20-30min | 三项同为纯拍板，攒一起效率高；C2b 复检图已备 |
| 4 | 安排一次试玩局 | 用户 30-60min | — | 一次解锁 BACKLOG 里 6 项卡「没人真玩过」的条目（丹房强度/残页数量/难度微调/立绘融合/C2b 目检/资质视觉） |
| 5 | P2 真机录屏验收管线 | opus | 不定 | 需真机位；与 BACKLOG 二#11 capture 根因同域，建议合并处理 |

## 【硬约束沿用】

- `DEVELOPER_DIR` 只给 git 用，带进 `flutter build macos` 即报 xcodebuild 找不到 → memory `feedback_developer_dir_breaks_flutter_macos_build`
- 否定式 grep 不是存在性证明；`git grep -E` 是 POSIX ERE 不认 `\s` → memory `feedback_negative_grep_not_proof_of_absence`
- 破坏证红必须在 commit 之后做（未提交时 checkout 还原会抹掉改动）→ memory `feedback_break_red_after_commit`
- 测试不得绕开生产路径，自检「破坏那行，这条断言必然红吗」 → memory `feedback_test_bypasses_production_path`
- commit message 必须中文动宾（§11 + 合并 Gate ⓓ）→ memory `feedback_wuxia_commit_message_chinese_gate`
- 写守卫看会话 cwd 不看目标路径；文档也不得用 heredoc 绕守卫 → memory `feedback_bg_session_write_guard_subagent_dev`
- schema/provider 批 merge 回主 checkout 后必跑 `build_runner` → memory `feedback_wuxia_pen_build_runner`
- 写完 dart 必 `dart format`（CI 门禁，不在 §8.2 Gate 清单里易漏）→ memory `feedback_wuxia_ci_format_gate_not_in_merge_gate`
- 推荐不得为省工作量缩水，出推荐前做「工作量无关」自检 → memory `feedback_no_effort_saving_in_recommendations`
- 长寿文档的行号/路径/「已实装」状态会 drift，引用前重新定位 → memory `feedback_living_doc_state_drift`

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测快照；改动代码后**必须重测**，禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功；**退出码要看归属**——管道后 `$?` 是末端命令的码（本会话实录：`python3 test.py | tail` 掩盖过一次真实 exit 1）。
- **空 grep 结果不是不存在**：先怀疑自己的正则/路径写法，换写法或纯字符串交叉验证一遍。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】（与置顶契约呼应）

读完上述清单后先提交一份报告，**不动代码**：

1. **防装读要求**：须引用本清单里**不存在**的原文——PROGRESS.md 顶段条目**【2026-08-11 续】段的原文首句**，以及 `docs/sessions/2026-08-11_153624_扫描器收口_main.md`「重要决策」小节的**原文首条**。只复述本清单已有信息不算完成。
2. 报告【开局动作】第 3、4 步结果：在途分支情况 + HEAD 校验判定（有效 / 作废）。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`（Step 0-4 为 canonical 流程，此处不复述）。
