# 新会话开局清单

> 交接时间:2026-08-05 16:21 · 工作收口于 HEAD `92b3d1a2` · 与 origin 同步、工作树干净
> 本清单自身的落盘 commit 排在 `92b3d1a2` 之后,故实际 HEAD 会比它新 1 个纯文档 commit——**这不是漂移**,判据见【开局动作】第 4 步。

## 【本会话契约】(置顶,最高优先级)

- **模式:只读**
- **只读模式**:完成【开局动作】并提交【先报告】后,等用户指令才可动代码。
- **范围围栏**:只做用户选定的任务。非阻塞发现 → 记项目根 `BACKLOG.md`(附 file:line+复现步骤)不动代码;阻塞型 → 停下报告。
- **拍板点**(设计取舍/多方案选型/观感判断):停下列选项等用户,禁代拍。一区拍板批出选项沿 memory `feedback_settlement_decision_menu`(1A 2B 式小节菜单)+`feedback_plain_language_option_framing`(先大白话类比再对照表)。
- **回复格式**:进度汇报用「当前完成/接下来」双表格(memory `feedback_progress_report_table_format`);多选项决策菜单仍小节式。

项目:挂机武侠(/Users/a10506/Desktop/Projects/挂机武侠)

夜批收账线全清(目检定谳全过+站位均匀分布已实装),开放项归零;唯一储备=BACKLOG 一区 8 条拍板项(#3-#7/#11-#13)+二区已解锁可派。

## 【开局动作】

1. 读 PROGRESS.md 顶段「2026-08-05 webp 压缩批+N2 远征①A 拍板」条目(目检定谳+站位批追加在该条目末段)
2. 读 `docs/sessions/2026-08-05_1621_目检定谳与站位.md`
3. `git worktree list` + `git branch --list 'worktree-*' 'night/*'`:应只余主 checkout 与 main(本批四侧已清;有新增=其他会话在途,别不知情重做)
4. `git pull --rebase --autostash`,校验本清单是否仍然有效:

   ```bash
   git merge-base --is-ancestor 92b3d1a2 HEAD && echo ANCESTOR_OK
   git status -sb | head -1
   ```

   - `ANCESTOR_OK` **且**与 origin 同步 → 快照有效,继续。(HEAD 比 `92b3d1a2` 新 1 个纯文档 commit 属正常,不是漂移)
   - `--is-ancestor` 不成立 → **快照作废**:停下报告差异,重测 analyze/test 基线,禁转抄下方数字。
5. 选读 memory:`reference_anti_hallucination`(固定)+ `feedback_settlement_decision_menu` + `feedback_plain_language_option_framing` + `feedback_no_effort_saving_in_recommendations`(拍板批出推荐前自检)

## 【环境快照】(上一会话实测;本会话改动代码后必须重测,禁转抄)

- HEAD `92b3d1a2`(本 session 2 commit:站位 `dc74f43a`+落账 `92b3d1a2`,全 push;本 handoff commit 后 +1)
- `flutter analyze --no-pub` → EXIT=0 · No issues(14.7s)|主 checkout 2026-08-05 16:21 实测
- 全量 `flutter test --no-pub` → **4858 pass / 0 fail**(2026-08-05 上午会话实测;本 session 改动=站位 2 行(1 生产+1 测试断言值)零新增测,守恒 4858+0=4858,自包含表现层按 v1.29 免全量;targeted `battle_stage_geometry_test` 单文件 8 pass 本会话实测)
- 在途 PR / 分支:**无**(站位 worktree 三验后删,远端只 main)
- 子系统:目检定谳全过(白布+三立绘,revert 线作废),一#14 已销;站位 slot1 锚 x=0.241 均匀分布;证据夹已进废纸篓;`.codegraph` 索引本会话打不开待重建

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | BACKLOG 一区拍板项逐条过(#3-#7/#11-#13)(推荐) | opus high | 30-60min | 一区仅剩 8 条待拍板,逐条给选项批量销账;#11/#12/#13 账上已有完整决策数据无需重查 |
| 2 | 二区已解锁可派项 | 按项 | 按项 | 用户点单后派 |

## 【硬约束沿用】

- 视觉判定用户终拍,代终拍是一次性授权非常态 → memory `feedback_visual_acceptance`
- 进度汇报双表格式 → memory `feedback_progress_report_table_format`
- 推荐不得为省工作量缩水 → memory `feedback_no_effort_saving_in_recommendations`
- flutter test 批跑静默漏跑,验收逐文件确认 → memory `feedback_flutter_test_batch_silent_skip`
- 全量默认并发,自包含改动只 targeted → memory `feedback_test_cadence_no_blind_full`
- open 真机后必查窗口 bounds 防恢复到主屏外 → memory `feedback_flutter_macos_drive_screenshot`

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测的快照;改动代码后**必须重测**,禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出,launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line;不确定写「不知道」,不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】(与置顶契约呼应)

读完上述清单后先提交一份报告,**不动代码**:

1. **防装读要求**:须引用本清单里**不存在**的原文——PROGRESS.md 顶段条目的**原文标题行与日期**,以及 `docs/sessions/2026-08-05_1621_目检定谳与站位.md`「下一步建议」小节的**原文首条**。只复述本清单已有的信息不算完成。
2. 报告【开局动作】第 3、4 步结果:在途分支情况 + HEAD 校验判定(有效/作废)。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`(Step 0-4 为 canonical 流程,此处不复述,防拷贝漂移)。
