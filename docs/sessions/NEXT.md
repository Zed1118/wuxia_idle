# 新会话开局清单

> 交接时间：2026-08-12 13:10 · 工作收口于 HEAD `4f6aa225` · 与 origin/main 同步、工作树干净
> 本清单自身的落盘 commit 排在 `4f6aa225` 之后，故实际 HEAD 会比它新 1 个纯文档 commit——**这不是漂移**，判据见【开局动作】第 4 步。
> ⚠ **主 checkout(`~/Desktop/Projects/挂机武侠`)停在 `c25a29fa`,落后 10 个 commit**。上一会话全程在隔离 worktree、写守卫不允许操作主 checkout,**开局第一件事是在主 checkout 跑 `git pull`**。

## 【本会话契约】（置顶，最高优先级）

- **模式：只读**
- **只读模式**：完成【开局动作】并提交【先报告】后，等用户指令才可动代码。
- **范围围栏**：只做用户选定的任务。过程中发现的其他问题分两类处置——
  - **非阻塞型**（不影响当前任务正确性）→ 记入根目录 `BACKLOG.md`，附 file:line 与复现步骤，**不动代码**；
  - **阻塞型**（当前任务建立在它之上，不修就是在错地基上盖楼）→ **停下报告**，不要记了账继续干。
- **拍板点**（设计取舍、多方案选型、观感判断）：只读模式下停下列选项等用户，**禁代拍**。
- **决策三级**：🟢 路径纠正/假阳过滤/只读审计可自决 · 🟡 新增审计方向/范围增减 >30%/跨模块重构可调查不可合并 · 🔴 GDD 解释/数值规则/schema/玩家可见 UI/删字段**必须停在 [BLOCKED] 等用户**。

项目：挂机武侠（`/Users/a10506/Desktop/Projects/挂机武侠`）

上一会话是挂机批,A-F 六单全部合入 main(PR #120/#121/#122),修掉两个真缺陷(视觉路由清空玩家存档 / 扫描器漏扫 291 篇文档)并交付「真机决策局」备局产物。**当前最大瓶颈是决策积压,不是工程执行**。

## 【开局动作】

1. 读 PROGRESS.md 顶段「**2026-08-12 挂机批 A-F 六单(PR #120/#121/#122)**」条目
2. 读 `docs/sessions/2026-08-12_130500_挂机批六单_afk-coordinator-0812.md`
3. `git worktree list` + `git branch --list 'worktree-*'`:**预期只见主 checkout**(执行端 worktree 已全清)。若见到 `.claude/worktrees/afk-coordinator-0812` 残留,它是上一会话的协调者 worktree,已合并可删。
4. **只 `git fetch`,不自动 rebase/autostash**：

   ```bash
   git status -sb | head -1
   git fetch origin
   git rev-list --left-right --count origin/main...HEAD
   git merge-base --is-ancestor 4f6aa225 HEAD && echo ANCESTOR_OK
   ```

   - 工作树 dirty / 有分叉 / 有其他活跃写者 → **停下报告**，不自行更新；干净且可 FF 才 `git merge --ff-only origin/main`
   - `ANCESTOR_OK` 且 ahead ≤1（那 1 个是本清单自身的 commit）→ 快照有效
   - `--is-ancestor` 不成立 → **快照作废**：停下报告差异，重测基线，禁转抄下方数字
   - **并发检查**:`~/.claude/locks/` 下协调锁。⚠ 该锁 `heartbeat_at` **全程不更新**,**不能用心跳新鲜度判活**,须查 pid 存活 + git tip 是否推进
5. 选读 memory：`reference_anti_hallucination`（固定）+ `feedback_date_may_return_utc_verify_timezone` / `feedback_gh_run_watch_exit_code_masks_cancelled` / `feedback_wuxia_pen_build_runner` / `feedback_bg_session_write_guard_subagent_dev` / `feedback_no_effort_saving_in_recommendations`

## 【环境快照】（上一会话实测；本会话改动代码后必须重测，禁转抄）

- HEAD `4f6aa225`（上一会话 3 个 PR 全合入,**已 push**;与 origin/main 同步）
- **测量口径**:上一会话全程在隔离 worktree,但已用 `git rev-parse HEAD^{tree}` 证明其内容与 `origin/main` **tree hash 完全相同**(`939601e9`),故下列数字对 main 成立
- `flutter analyze --no-pub` → **No issues found!**，exit 0，3.3s
- 全量 `flutter test --no-pub` → **4920 pass / 0 fail**，exit 0，4m18s
  - **守恒核对**：4920 = 上轮基线 4917 + 本批新增 3(`test/features/debug/visual_route_isar_directory_test.dart` 三例:目录语义 / 清空语义 / 接线静态守卫),逐值吻合
- CI:三个 PR 的 run 均 `conclusion=success` 且 headSha == 各自最终 commit(`3d5ad06e` / `d437cf52` / `9c5692d0`)
- **在途 PR / 分支：无**。远端只剩 `main` + 用户 2026-08-12 明确指定保留的 `pi/p6-link-label-0808`(2 独有)与 `worktree-claude-rarity`(3 独有,均为 rebase 前旧 SHA)
- 死链扫描器现状:扫描源 **1230** 文件 / 引用 7929 / 存活 6283 / ignored 686 / 归档类 593 / **死链 367**。该 367 **第一次可直接当修复清单用**(F 修复漏扫前的数字不可信)
- 真机决策局已备好未开跑:`tools/playtest/decision_session.sh`(8 步,其中 7/8 两步已随上批拍掉),剩 A 组 3 项视觉 + B 组 3 项试玩,约 45 分钟

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | **跑真机决策局（推荐）** | 用户操作 | 45-60min | 一次清 6 项积压决策;决策积压是当前唯一瓶颈,清了才谈得上下一批做什么。A 已合,跑视觉路由不再碰生产存档 |
| 2 | dead=367 死链修复批 | opus high | 60-90min | 清单第一次可信;precision 95% 意味约 1/20 需人工否决,逐条目检 |
| 3 | 一#18 扫描器定位重评 | opus high | 60-90min | **必须先重做一次 P6 式标注验证**(样本扩大 31%,旧结论不能外推),不能只看数字变好看 |
| 4 | 一#17 桃花岛四图取舍 | 用户操作 | 15min | 已并入决策局步 1;单独做也行,证据夹已备齐 |

## 【硬约束沿用】

> **主从原则**：canonical 正文只住 memory，此处每条只留一行摘要 + memory 指针。

- 裸 `date` 可能返回 UTC,判时刻须 `%Z` + `date -u` 交叉验 → memory `feedback_date_may_return_utc_verify_timezone`
- `gh run watch --exit-status` 返 0 ≠ CI 通过(cancelled 也返 0),必显式读 conclusion → memory `feedback_gh_run_watch_exit_code_masks_cancelled`
- 本地 `main` ref 被主 checkout 占用时无法更新,分支比对一律用 `origin/main` → memory `feedback_gh_pr_mergeable_vs_local_divergence`
- fresh worktree 预热必含 `build_runner`,否则 analyze 报几千 error → memory `feedback_subagent_driven_fresh_worktree_env_prep`
- 写守卫看会话 cwd 不看目标路径;文档也不得用 heredoc 绕守卫 → memory `feedback_bg_session_write_guard_subagent_dev`
- 破坏证红必须在 commit 之后做 → memory `feedback_break_red_after_commit`
- 测试不得绕开生产路径,自检「破坏那行,这条断言必然红吗」 → memory `feedback_test_bypasses_production_path`
- commit message 必须中文动宾(§11 + 合并 Gate ⓓ) → memory `feedback_wuxia_commit_message_chinese_gate`
- 写完 dart 必 `dart format`(CI 门禁,不在 §8.2 Gate 清单里易漏) → memory `feedback_wuxia_ci_format_gate_not_in_merge_gate`
- 推荐不得为省工作量缩水,出推荐前做「工作量无关」自检 → memory `feedback_no_effort_saving_in_recommendations`
- 否定式 grep 不是存在性证明 → memory `feedback_negative_grep_not_proof_of_absence`
- 长寿文档的行号/路径/「已实装」状态会 drift,引用前重新定位 → memory `feedback_living_doc_state_drift`

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测快照；改动代码后**必须重测**，禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功；**退出码要看归属**——管道后 `$?` 是末端命令的码,`gh run watch` 的 0 也可能是 cancelled。
- **空 grep 结果不是不存在**：先怀疑自己的正则/路径写法，换写法或纯字符串交叉验证一遍。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】（与置顶契约呼应）

读完上述清单后先提交一份报告，**不动代码**：

1. **防装读要求**：须引用本清单里**不存在**的原文——PROGRESS.md 顶段条目的**原文标题行与日期**，以及 `docs/sessions/2026-08-12_130500_挂机批六单_afk-coordinator-0812.md`「重要决策」小节的**原文首条**。只复述本清单已有信息不算完成。
2. 报告【开局动作】第 3、4 步结果：在途分支情况 + HEAD 校验判定（有效 / 作废）+ **主 checkout 是否已 `git pull` 到 `4f6aa225` 之后**。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`（Step 0-4 为 canonical 流程，此处不复述）。
