# 新会话开局清单

> 交接时间:2026-08-05 22:37 · 工作收口于 HEAD `4fdb4fb3` · 与 origin 同步、工作树干净
> 本清单自身的落盘 commit 排在 `4fdb4fb3` 之后,故实际 HEAD 会比它新 1 个纯文档 commit——**这不是漂移**,判据见【开局动作】第 4 步。

## 【本会话契约】(置顶,最高优先级)

- **模式:只读**
- **只读模式**:完成【开局动作】并提交【先报告】后,等用户指令才可动代码。
- **范围围栏**:只做用户选定的任务。非阻塞发现 → 记项目根 `BACKLOG.md`(附 file:line+复现步骤)不动代码;阻塞型 → 停下报告。
- **拍板点**(设计取舍/多方案选型/观感判断):停下列选项等用户,禁代拍。出选项沿 memory `feedback_settlement_decision_menu`(1A 2B 式小节菜单)+`feedback_plain_language_option_framing`(先大白话再推荐);出推荐前做「工作量无关」自检(`feedback_no_effort_saving_in_recommendations`)。
- **回复格式**:进度汇报用「当前完成/接下来」双表格(memory `feedback_progress_report_table_format`);多选项决策菜单仍小节式。

项目:挂机武侠(/Users/a10506/Desktop/Projects/挂机武侠)

BACKLOG 一区拍板批收官(8→4 条)+第八阶段敌方协同范围 spec 已拍板合入;头号候选=第八阶段实装批(spec 在手,需 xhigh)。

## 【开局动作】

1. 读 PROGRESS.md 顶段「2026-08-05 晚 BACKLOG 一区拍板批」条目
2. 读 `docs/sessions/2026-08-05_2237_拍板与第八阶段.md`
3. `git worktree list` + `git branch --list 'worktree-*' 'night/*'`:应只余主 checkout 与 main(本批四侧已清;有新增=其他会话在途——同日已实证有并行会话推 main,别不知情重做)
4. `git pull --rebase --autostash`,校验本清单是否仍然有效:

   ```bash
   git merge-base --is-ancestor 4fdb4fb3 HEAD && echo ANCESTOR_OK
   git status -sb | head -1
   ```

   - `ANCESTOR_OK` **且**与 origin 同步 → 快照有效,继续。(HEAD 比 `4fdb4fb3` 新 1-2 个纯文档 commit 属正常,不是漂移)
   - `--is-ancestor` 不成立 → **快照作废**:停下报告差异,重测 analyze/test 基线,禁转抄下方数字。
5. 选读 memory:`reference_anti_hallucination`(固定);若开第八阶段实装批加读:`feedback_subagent_driven_fresh_worktree_env_prep` + `feedback_fresh_worktree_libisar_dylib` + `feedback_wuxia_pen_build_runner` + `feedback_strategy_immutable_vs_ui_tick` + `feedback_debug_battle_seed_real_power`

## 【环境快照】(上一会话实测;本会话改动代码后必须重测,禁转抄)

- HEAD `4fdb4fb3`(本 session 2 commits:拍板批 `043d2ac8`+phase8 spec `4fdb4fb3`,全 push;同日另一会话另有 2 commits 已在 main;本 handoff commit 后 +1)
- `flutter analyze --no-pub` → EXIT=0 · No issues(5.8s)|主 checkout 2026-08-05 22:37 实测
- 全量 `flutter test --no-pub` → **4858 pass / 0 fail**(2026-08-05 上午会话实测沿用;本 session 代码改动=1 处纯注释零行为+纯文档,新增 0 测,守恒 4858+0=4858)
- 在途 PR / 分支:**无**(worktree/本地分支/远端分支三件套三验后全清)
- 子系统:第八阶段范围 spec `docs/spec/2026-08-05-phase8-boss-coop-guard-charge-design.md` 待实装;BACKLOG 一区余 4 条(#4/#5/#6/#11)全等用户手感/观感输入;`.codegraph` 索引打不开待重建(grep 兜底)

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 第八阶段实装批切片 1-3(机制+合击+配置 schema)(推荐) | opus xhigh | 一个专注会话 | spec §5 切片已列;推荐理由=唯一在手的已拍板大活,机制层收口后切片 4-5(实例+校准)可下会话接力 |
| 2 | #4/#5/#6/#11 表态收尾 | opus high | 10min | 用户一句话拍板即销,可与 #1 同会话捎带 |
| 3 | 二区#7 B3 立绘融合观感真人拍 | opus high | ~20min | 需真机实拍图,用户在场时做 |

## 【硬约束沿用】

- 视觉判定用户终拍,代终拍是一次性授权非常态 → memory `feedback_visual_acceptance`
- 进度汇报双表格式 → memory `feedback_progress_report_table_format`
- 推荐不得为省工作量缩水 → memory `feedback_no_effort_saving_in_recommendations`
- flutter test 批跑静默漏跑,验收逐文件确认 → memory `feedback_flutter_test_batch_silent_skip`
- 全量默认并发,自包含改动只 targeted → memory `feedback_test_cadence_no_blind_full`
- fresh worktree 预热三件套(pub get+dylib+build_runner)再跑测 → memory `feedback_subagent_driven_fresh_worktree_env_prep`
- 战斗机制实装必查 Strategy↔UI wiring 维度 → memory `feedback_strategy_immutable_vs_ui_tick`
- worktree 隔离会话 git 越界被拒/cwd 钉扎,显式 -C 绝对路径 → 本批踩坑,详 session 记录「踩坑提醒」

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测的快照;改动代码后**必须重测**,禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出,launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line;不确定写「不知道」,不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】(与置顶契约呼应)

读完上述清单后先提交一份报告,**不动代码**:

1. **防装读要求**:须引用本清单里**不存在**的原文——PROGRESS.md 顶段条目的**原文标题行与日期**,以及 `docs/sessions/2026-08-05_2237_拍板与第八阶段.md`「下一步建议」小节的**原文首条**;若准备开第八阶段实装,另引 spec §2.1「破招重定向链」的**三步原文**。只复述本清单已有的信息不算完成。
2. 报告【开局动作】第 3、4 步结果:在途分支情况 + HEAD 校验判定(有效/作废)。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`(Step 0-4 为 canonical 流程,此处不复述,防拷贝漂移)。
