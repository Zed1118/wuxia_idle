# 新会话开局清单

> 交接时间：2026-08-04 20:20 · 工作收口于分支 `worktree-tower-batch-c` tip `d77c04a4`（PR #118 draft **未合**）· 与 origin 同步、工作树干净
> **本清单落在 PR #118 分支上**：main 上的 NEXT.md 在 #118 合并前仍是批 B 交接版（17:30，其候选 1/2 本会话已做完，勿照做）。开局若从 main 读到旧版，以 PR #118 分支版为准。
> 本清单自身的落盘 commit 排在 `d77c04a4` 之后，故分支 tip 会比它新 1 个纯文档 commit——**这不是漂移**，判据见【开局动作】第 4 步。

## 【本会话契约】（置顶，最高优先级）

- **模式：只读**
- **只读模式**：完成【开局动作】并提交【先报告】后，等用户指令才可动代码。
- **范围围栏**：只做用户选定的任务。过程中发现的其他问题分两类处置——
  - **非阻塞型**（不影响当前任务正确性）→ 记入项目根 `BACKLOG.md`，附 file:line 与复现步骤，**不动代码**；
  - **阻塞型**（当前任务建立在它之上，不修就是在错地基上盖楼）→ **停下报告**，不要记了账继续干。
- **拍板点**（设计取舍、多方案选型、观感判断）：停下列选项等用户，禁代拍。
- **本轮额外围栏**：批 C 视觉判定（8 立绘 + 16 smoke）**只归用户终拍**，任何「初检通过」都不是放行依据；
  合 PR #118 前按 §8.2 Gate 独立复核（上一会话是作者，下一会话是复核者，别采信作者自报）。

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

塔 49 层三批收口：批 A/B 已进 main（main=`2e52ae1c`）；批 C（8 张新 Boss 立绘接线 + 周目 UI smoke）
完成在 **PR #118 draft**，等用户视觉终拍后合入。

## 【开局动作】

1. 读 PROGRESS.md 顶段「2026-08-04 批 C」条目。**注意**：该条目在 PR #118 分支上，**尚未进 main**；
   main 顶段仍是批 B 条目。
2. 读 `docs/sessions/2026-08-04_2020_批C立绘smoke.md`（同在 #118 分支）
3. `git worktree list` + `git branch --list 'worktree-*'`：**本轮确有在途**——worktree
   `.claude/worktrees/tower-batch-c`（分支 `worktree-tower-batch-c`）+ PR #118 draft。
4. `git pull --rebase --autostash`（主 checkout main 上），然后校验：

   ```bash
   git merge-base --is-ancestor d77c04a4 worktree-tower-batch-c && echo BRANCH_OK
   gh pr view 118 --json state,mergeable,statusCheckRollup --jq '{state,mergeable,checks:[.statusCheckRollup[]|{name,conclusion}]}'
   ```

   - `BRANCH_OK` 且 #118 OPEN → 快照有效。#118 已 MERGED → 直接以 main 为基线继续（快照数字仍有效）。
   - 分支不存在或被改写 → **快照作废**：停下报告差异，重测基线，禁转抄下方数字。
5. 选读 memory：`reference_anti_hallucination`（固定）+ `feedback_visual_acceptance`（终拍 SOP）
   + `feedback_visual_score_first_pass_underestimate`（首轮打分系统性低估）
   + `feedback_flutter_test_batch_silent_skip`（合并 Gate targeted 逐文件跑）

## 【环境快照】（上一会话实测；本会话改动代码后必须重测，禁转抄）

- 分支 `worktree-tower-batch-c` tip `d77c04a4`（本 session 3 commits 全 push；main=`2e52ae1c` 含批 A/B 不含批 C）
- `flutter analyze --no-pub` → **EXIT=0 · No issues（9.0s）**｜分支树实测
- 全量 `flutter test --no-pub` → **4854 pass / 0 fail · EXIT=0（4m29s）**｜分支 `d77c04a4` 树实测
  - **守恒核对**：= 批 B 基线 4854 + 批 C 新增 **0**（本批零新测试：纯资产 + 接线 + debug route），逐值吻合
- 在途 PR / 分支：**PR #118**（draft OPEN，批 C 全部工作）+ worktree `tower-batch-c`（本清单载体）
- 子系统状态：塔 49 层三批代码面全部收口；**终拍素材两目录在主 checkout `build/` 下**（gitignored）——
  立绘源图+自检报告 `build/dispatch/tower_boss_art_20260804/`、16 张 smoke `build/visual_acceptance/tower_batch_c/`，删前先终拍

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 批 C 视觉终拍 + 合 PR #118（推荐） | opus high | 30-45min | 用户逐张过 8 立绘+16 smoke；通过后按 §8.2 Gate 独立复核合入（CI 全量兜底）、四侧清 worktree/分支；批 C 落账塔三批全收口 |
| 2 | 远征里程碑 [20,40] / 奖励 0.25 真机校 | opus high | 30-45min | 批 B 续挂初值保守；可并入终拍同一真机会话 |
| 3 | 「已达最高周目」文案歧义拍板 | opus high | 10min | 境界门槛压 cap 时读作「没了」（实可升境界解锁）；先拍方向，若改 UI 随下批 |

## 【硬约束沿用】

- 视觉判定用户终拍，能力边界+闸门 → memory `feedback_visual_acceptance`
- 首轮打分系统性低估，判据外不加码 → memory `feedback_visual_score_first_pass_underestimate`
- flutter test 多文件批跑静默漏跑，验收逐文件 → memory `feedback_flutter_test_batch_silent_skip`
- 推荐不得为省工作量缩水范围 → memory `feedback_no_effort_saving_in_recommendations`
- 全量默认并发；自包含改动只 targeted → memory `feedback_test_cadence_no_blind_full`
- fresh worktree 预热三件套（pub get+dylib+build_runner）→ memory `feedback_subagent_driven_fresh_worktree_env_prep`

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测的快照；改动代码后**必须重测**，禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】（与置顶契约呼应）

读完上述清单后先提交一份报告，**不动代码**：

1. **防装读要求**：须引用本清单里**不存在**的原文——PROGRESS.md（#118 分支版）顶段条目的
   **原文标题行与日期**，以及 `docs/sessions/2026-08-04_2020_批C立绘smoke.md`「下一步建议」小节的
   **原文首条**。只复述本清单已有的信息不算完成。
2. 报告【开局动作】第 3、4 步结果：在途分支与 PR #118 状态（含 CI 结果）+ 快照判定（有效 / 作废）。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`（Step 0-4 为 canonical 流程，此处不复述，防拷贝漂移）。
