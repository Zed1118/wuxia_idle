# 新会话开局清单

> 交接时间:2026-08-06 09:43 · 工作收口于 main HEAD `888a7ce0` · 与 origin 同步、工作树干净
> 本清单自身的落盘 commit 排在 `888a7ce0` 之后,故实际 HEAD 会比它新 1 个纯文档 commit——**这不是漂移**,判据见【开局动作】第 4 步。

## 【本会话契约】(置顶,最高优先级)

- **模式:只读**
- **只读模式**:完成【开局动作】并提交【先报告】后,等用户指令才可动代码。
- **范围围栏**:只做用户选定的任务。非阻塞发现 → 记项目根 `BACKLOG.md`(附 file:line+复现步骤)不动代码;阻塞型 → 停下报告。
- **拍板点**(设计取舍/多方案选型/观感判断):停下列选项等用户,禁代拍。出选项沿 memory `feedback_settlement_decision_menu`+`feedback_plain_language_option_framing`;出推荐前做「工作量无关」自检(`feedback_no_effort_saving_in_recommendations`)。
- **回复格式**:进度汇报用「当前完成/接下来」双表格(memory `feedback_progress_report_table_format`);多选项决策菜单仍小节式。

项目:挂机武侠(/Users/a10506/Desktop/Projects/挂机武侠)

第八阶段机制层(切片 1-3:掩护重定向+护法合击+配置 schema)已在分支 `worktree-phase8-boss-coop` 收口并 push,**未合 main**;头号候选=Gate 合入+切片 4-5(实例+校准,需 xhigh)。

## 【开局动作】

1. 读 PROGRESS.md 顶段(main 版顶条=「2026-08-05 晚 BACKLOG 一区拍板批」;**本批第八阶段条目在分支上**:`git show worktree-phase8-boss-coop:PROGRESS.md | head -12` 读之,合并后才进 main)
2. 读 `docs/sessions/2026-08-06_0943_第八阶段实装.md`
3. `git worktree list` + `git branch --list 'worktree-*' 'night/*'`:**应见 `worktree-phase8-boss-coop`(worktree+本地分支+远端分支三件套)在途——这是本批交付物,有意保留,勿惊讶勿重做**;除此之外应无其他残留(另有新增=其他会话在途,先查明)
4. `git pull --rebase --autostash`,校验本清单是否仍然有效:

   ```bash
   git merge-base --is-ancestor 888a7ce0 HEAD && echo ANCESTOR_OK
   git status -sb | head -1
   ```

   - `ANCESTOR_OK` **且**与 origin 同步 → 快照有效,继续。(HEAD 比 `888a7ce0` 新 1-2 个纯文档 commit 属正常,不是漂移)
   - `--is-ancestor` 不成立 → **快照作废**:停下报告差异,重测 analyze/test 基线,禁转抄下方数字。
5. 选读 memory:`reference_anti_hallucination`(固定);若开合并+切片 4-5 批加读:`feedback_gh_pr_mergeable_vs_local_divergence`(合并复核)+`feedback_wuxia_boss_balance_crosstier`+`feedback_debug_battle_seed_real_power`+`feedback_probe_must_prove_its_load`(校准三件)+`feedback_subagent_driven_fresh_worktree_env_prep`(若新开 worktree)

## 【环境快照】(上一会话实测;本会话改动代码后必须重测,禁转抄)

- main HEAD `888a7ce0`(本 session main 零代码改动,纯 handoff 文档;本 handoff commit 后 +1)
- **在途分支:`worktree-phase8-boss-coop` @ `a6a7f34b`**(=main+2 commits:`e25c3e35` 实装+`a6a7f34b` PROGRESS,已 push origin,分支树净与远端同步 2026-08-06 09:43 实测)
- main `flutter analyze --no-pub` → 0 issues(2026-08-05 22:37 主 checkout 实测沿用;main 其后零代码改动)
- main 全量 → **4858 pass / 0 fail**(2026-08-05 上午实测沿用;main 零代码改动守恒)
- 分支侧(2026-08-06 worktree 实测):analyze 0(11.9s);全量 **4876 pass / 0 fail** = 基线 4858 + 新增 18(`phase8_coop_guard_test` 13 + `enemy_def_guard_intercepts_test` 5),逐值吻合,首跑即绿;破坏证红 ×2 各精确命中后还原复绿
- 子系统:第八阶段机制层收口待合;切片 4-5(塔 35-49 实例+balance_simulator 校准)待做;BACKLOG 一区余 4 条(#4/#5/#6/#11)全等用户输入;`.codegraph` 索引打不开待重建(grep 兜底)

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 分支 §8.2 Gate 合入 main + 开切片 4-5(实例+校准闭环)(推荐) | opus xhigh | 一个专注会话 | 机制层独立可验已 4876 绿,按批 A/B/C 惯例每批独立合入;切片 4-5 沿 floor32「满配必胜/同阶偶胜/跨阶全败」校准体例,spec §4 已列范围 |
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
- worktree 隔离会话 git 越界被拒/cwd 钉扎,显式 -C 绝对路径;合 main 与 /handoff 文档都必须先 ExitWorktree → 上上轮踩坑+本轮 handoff 变体,详 session 记录「踩坑提醒」
- 合并复核不只信 gh mergeable,本地 merge-tree 复算 → memory `feedback_gh_pr_mergeable_vs_local_divergence`

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测的快照;改动代码后**必须重测**,禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出,launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line;不确定写「不知道」,不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】(与置顶契约呼应)

读完上述清单后先提交一份报告,**不动代码**:

1. **防装读要求**:须引用本清单里**不存在**的原文——分支版 PROGRESS 顶段条目的**原文标题行**(须真跑 `git show worktree-phase8-boss-coop:PROGRESS.md`),以及 `docs/sessions/2026-08-06_0943_第八阶段实装.md`「下一步建议」小节的**原文首条**;若准备开切片 4-5,另引 spec `docs/spec/2026-08-05-phase8-boss-coop-guard-charge-design.md` §4「实例落点与范围」的**首句原文**。只复述本清单已有的信息不算完成。
2. 报告【开局动作】第 3、4 步结果:在途分支情况(应恰见 phase8 三件套)+ HEAD 校验判定(有效/作废)。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`(Step 0-4 为 canonical 流程,此处不复述,防拷贝漂移)。
