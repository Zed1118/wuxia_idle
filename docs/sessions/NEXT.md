# 新会话开局清单

> 交接时间:2026-08-05 15:10 · 工作收口于 HEAD `08abf6a5` · 与 origin 同步、工作树干净
> 本清单自身的落盘 commit 排在 `08abf6a5` 之后,故实际 HEAD 会比它新 1 个纯文档 commit——**这不是漂移**,判据见【开局动作】第 4 步。

## 【本会话契约】(置顶,最高优先级)

- **模式:只读**
- **只读模式**:完成【开局动作】并提交【先报告】后,等用户指令才可动代码。
- **目检反馈优先**:白布+三立绘两处代终拍待用户观感,4 张图本批已 webp 转码。**否决时 revert 由本会话代跑**(直接 revert 碰二进制冲突):`git revert --no-commit <sha>` 撞冲突后 `git checkout <sha>^ -- <该 commit 的文件>` 取旧版(旧版本就是 webp-in-png 压缩态,无需重压)再 commit;白布=`ea7bd91c`、三立绘=`4d59726b`。
- **范围围栏**:只做用户选定的任务。非阻塞发现 → 记项目根 `BACKLOG.md`(附 file:line+复现步骤)不动代码;阻塞型 → 停下报告。
- **拍板点**(设计取舍/多方案选型/观感判断):停下列选项等用户,禁代拍。
- **回复格式**:进度汇报用「当前完成/接下来」双表格(memory `feedback_progress_report_table_format`,2026-08-05 新拍);多选项决策菜单仍小节式。

项目:挂机武侠(/Users/a10506/Desktop/Projects/挂机武侠)

今日两批全销:webp 压缩批(18 张省 19.9M)+ N2 远征双拍板(①A 维持 0.25 / ②A 维持 [20,40],模拟证伪战败墙);唯一开放项=白布+三立绘观感目检(用户晚间)。

## 【开局动作】

1. 读 PROGRESS.md 顶段「2026-08-05 webp 压缩批+N2 远征①A 拍板」条目
2. 读 `docs/sessions/2026-08-05_1510_webp批与N2销账.md`
3. `git worktree list` + `git branch --list 'worktree-*' 'night/*'`:应只余主 checkout 与 main(本批四侧已清;有新增=其他会话在途,别不知情重做)
4. `git pull --rebase --autostash`,校验本清单是否仍然有效:

   ```bash
   git merge-base --is-ancestor 08abf6a5 HEAD && echo ANCESTOR_OK
   git status -sb | head -1
   ```

   - `ANCESTOR_OK` **且**与 origin 同步 → 快照有效,继续。(HEAD 比 `08abf6a5` 新 1 个纯文档 commit 属正常,不是漂移)
   - `--is-ancestor` 不成立 → **快照作废**:停下报告差异,重测 analyze/test 基线,禁转抄下方数字。
5. 选读 memory:`reference_anti_hallucination`(固定)+ `feedback_visual_acceptance`(目检 SOP)+ `feedback_progress_report_table_format`(回复格式新拍)+ `feedback_wuxia_webp_cleanup_recipe`(转码态背景)

## 【环境快照】(上一会话实测;本会话改动代码后必须重测,禁转抄)

- HEAD `08abf6a5`(本 session 5 commit:webp×2+账面×3,全 push;本 handoff commit 后 +1)
- `flutter analyze --no-pub` → EXIT=0 · No issues(3.6s)|主 checkout 2026-08-05 15:10 实测
- 全量 `flutter test --no-pub` → **4858 pass / 0 fail**(2026-08-05 上午会话实测;本 session 纯资产转码+纯文档、零新增测,守恒 4858+0=4858,按 v1.29 免全量)
  - 本 session targeted 实测:webp_in_png_decode 2 / pubspec_asset_declaration 3 / character_avatar 21 / visual_route 45 全绿;临时探针 18 测破坏证红后已删
- 在途 PR / 分支:**无**(webp worktree 三验后删,远端只 main)
- 子系统:全仓真 PNG 只余 110 张 equipment 池(评估无收益保持);远征 cycle2/3 门槛与奖励配置全维持零改动;两处代终拍视觉待目检

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 目检反馈处理(推荐) | opus high | 5-30min | 通过=全清收尾;否决=代 revert(冲突解法见契约),一句话定向 |
| 2 | BACKLOG 一区拍板项(#3-#7/#11-#13) | opus high | 按项 | 一#14(三立绘)随目检定谳 |

## 【硬约束沿用】

- 视觉判定用户终拍,代终拍是一次性授权非常态 → memory `feedback_visual_acceptance`
- 进度汇报双表格式(2026-08-05 拍) → memory `feedback_progress_report_table_format`
- 推荐不得为省工作量缩水 → memory `feedback_no_effort_saving_in_recommendations`
- flutter test 批跑静默漏跑,验收逐文件确认 → memory `feedback_flutter_test_batch_silent_skip`
- 全量默认并发,自包含改动只 targeted → memory `feedback_test_cadence_no_blind_full`

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测的快照;改动代码后**必须重测**,禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出,launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line;不确定写「不知道」,不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】(与置顶契约呼应)

读完上述清单后先提交一份报告,**不动代码**:

1. **防装读要求**:须引用本清单里**不存在**的原文——PROGRESS.md 顶段条目的**原文标题行与日期**,以及 `docs/sessions/2026-08-05_1510_webp批与N2销账.md`「下一步建议」小节的**原文首条**。只复述本清单已有的信息不算完成。
2. 报告【开局动作】第 3、4 步结果:在途分支情况 + HEAD 校验判定(有效/作废)。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`(Step 0-4 为 canonical 流程,此处不复述,防拷贝漂移)。
