# 新会话开局清单

> 交接时间:2026-08-06 13:20 · 工作收口于 main HEAD `29f6e1a0` · 与 origin 同步、工作树干净
> 本清单自身的落盘 commit 排在 `29f6e1a0` 之后,故实际 HEAD 会比它新 1 个纯文档 commit——**这不是漂移**,判据见【开局动作】第 4 步。

## 【本会话契约】(置顶,最高优先级)

- **模式:只读**
- **只读模式**:完成【开局动作】并提交【先报告】后,等用户指令才可动代码。
- **范围围栏**:只做用户选定的任务。非阻塞发现 → 记项目根 `BACKLOG.md`(附 file:line+复现步骤)不动代码;阻塞型 → 停下报告。
- **拍板点**(设计取舍/多方案选型/观感判断):停下列选项等用户,禁代拍。出选项沿 memory `feedback_settlement_decision_menu`+`feedback_plain_language_option_framing`;出推荐前做「工作量无关」自检(`feedback_no_effort_saving_in_recommendations`)。
- **回复格式**:进度汇报用「当前完成/接下来」双表格(memory `feedback_progress_report_table_format`);多选项决策菜单仍小节式。

项目:挂机武侠(/Users/a10506/Desktop/Projects/挂机武侠)

第八阶段(敌方协同)全五切片已收官进 main(机制层+塔 42 首实例+校准闭环+守卫),CI 绿;头号候选=真机塔 42 目检协同演出(第八阶段最后一验,需用户在场)。

## 【开局动作】

1. 读 PROGRESS.md 顶段「2026-08-06 第八阶段两批收口」条目
2. 读 `docs/sessions/2026-08-06_1259_第八阶段收官.md`
3. `git worktree list` + `git branch --list 'worktree-*' 'night/*'`:应**零在途**(本批四侧全清);有新增=其他会话在途,先查明
4. `git pull --rebase --autostash`,校验本清单是否仍然有效:

   ```bash
   git merge-base --is-ancestor 29f6e1a0 HEAD && echo ANCESTOR_OK
   git status -sb | head -1
   ```

   - `ANCESTOR_OK` **且**与 origin 同步 → 快照有效,继续。(HEAD 比 `29f6e1a0` 新 1 个纯文档 commit 属正常,不是漂移)
   - `--is-ancestor` 不成立 → **快照作废**:停下报告差异,重测 analyze/test 基线,禁转抄下方数字。
5. 选读 memory:`reference_anti_hallucination`(固定);若做候选 1 加读 `feedback_visual_acceptance`+`feedback_user_screenshot_read_local`;若动 dart 文件必读 `feedback_wuxia_ci_format_gate_not_in_merge_gate`

## 【环境快照】(2026-08-06 本会话实测;改动代码后必须重测,禁转抄)

- main HEAD `29f6e1a0`(本 session 6 commits:`714e68a0` 切片1-3 merge→`8e689c79` 切片4-5 实装→`727b794d` 白名单→`6e2653a4` PROGRESS→`9e4dc275` 切片4-5 merge→`29f6e1a0` format,全 push;本 handoff commit 后 +1)
- `flutter analyze --no-pub` → 0 issues(3.3s,主 checkout 实测)
- 全量 `flutter test --no-pub` → **4880 pass / 0 fail**(4m31s,主 checkout 实测)
  - **守恒核对**:= 基线 4876 + 新增 4(`floor42_coop_guard_diagnostic_test` 1 + `floor42_coop_guard_battle_test` 3),逐值吻合
- CI run 31072448344 **success**(18m25s,format+全量双过;此前一 run 因 format 门禁红已修,详 PROGRESS 顶段)
- 在途 PR / 分支:无(worktree/本地/远端全清)
- 子系统:第八阶段全五切片收官;塔 42=协同 Boss 首实例(三态 100%/15%/0% 校准定稿);真机观感未目检;BACKLOG 一区余 #4/#5/#6/#11 等表态;`.codegraph` 索引打不开待重建(grep 兜底)

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 真机塔 42 打一局目检协同演出(推荐) | opus high | ~20min | 需用户在场;第八阶段最后一验:合击题字/hit-stop/蓄力条/战报专句,自动战斗即可见 |
| 2 | #4/#5/#6/#11 表态收尾 | opus high | 10min | 一句话拍板即销,可与 #1 同会话捎带 |
| 3 | 二区#7 B3 立绘融合观感真人拍 | opus high | ~20min | 需真机实拍图,用户在场时做 |
| 4 | spec §1 Phase 0 描述 drift 回改 | opus high | 5min | 纯文档顺手项(「14/21/28/32 已用」→实况 {42,49}),可与任一批捎带 |

## 【硬约束沿用】

- 视觉判定用户终拍,代终拍是一次性授权非常态 → memory `feedback_visual_acceptance`
- 进度汇报双表格式 → memory `feedback_progress_report_table_format`
- 推荐不得为省工作量缩水 → memory `feedback_no_effort_saving_in_recommendations`
- flutter test 批跑静默漏跑,验收逐文件确认 → memory `feedback_flutter_test_batch_silent_skip`
- 全量默认并发,自包含改动只 targeted → memory `feedback_test_cadence_no_blind_full`
- **写完 dart 文件必 format,Gate 复核当第 ⓔ 项** → memory `feedback_wuxia_ci_format_gate_not_in_merge_gate`
- 合并复核不只信 gh mergeable,本地 merge-tree 复算 → memory `feedback_gh_pr_mergeable_vs_local_divergence`
- bg 会话写守卫:代码改动 EnterWorktree,纯文档 Bash heredoc;合 main/handoff 先 ExitWorktree → memory `feedback_bg_session_write_guard_subagent_dev`
- 红线测写约束语义(白名单/集合自洽)不写瞬时事实 → memory `feedback_red_line_test_semantics`

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测的快照;改动代码后**必须重测**,禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出,launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line;不确定写「不知道」,不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】(与置顶契约呼应)

读完上述清单后先提交一份报告,**不动代码**:

1. **防装读要求**:须引用本清单里**不存在**的原文——PROGRESS.md 顶段「2026-08-06 第八阶段两批收口」条目的**「已知风险」小节原文首条**,以及 `docs/sessions/2026-08-06_1259_第八阶段收官.md`「踩坑提醒」小节的**原文首条**。只复述本清单已有的信息不算完成。
2. 报告【开局动作】第 3、4 步结果:在途分支情况(应零在途)+ HEAD 校验判定(有效/作废)。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`(Step 0-4 为 canonical 流程,此处不复述,防拷贝漂移)。
