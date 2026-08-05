# 新会话开局清单

> 交接时间:2026-08-05 11:40 · 工作收口于 HEAD `108842f6` · 与 origin 同步、工作树干净
> 本清单自身的落盘 commit 排在 `108842f6` 之后,故实际 HEAD 会比它新 1 个纯文档 commit——**这不是漂移**,判据见【开局动作】第 4 步。

## 【本会话契约】(置顶,最高优先级)

- **模式:只读**
- **只读模式**:完成【开局动作】并提交【先报告】后,等用户指令才可动代码。
- **观感反馈优先**:上批有两处**代终拍**合入(白布返修+我方 3 张立绘重出),用户尚未亲眼看过。开局先引导用户看证据夹或真机开一局;观感不合立刻按 revert 线回滚,不辩护——白布=`git revert ea7bd91c`,三立绘=`git revert 4d59726b`,各单 commit 干净回滚。
- **范围围栏**:只做用户选定的任务。其他发现分两类——非阻塞型 → 记项目根 `BACKLOG.md`(附 file:line+复现步骤),不动代码;阻塞型 → 停下报告,不要记了账继续干。
- **拍板点**(设计取舍/多方案选型/观感判断):停下列选项等用户,禁代拍。

项目:挂机武侠(/Users/a10506/Desktop/Projects/挂机武侠)

昨晚夜班 N1-N5 已收账(评分 94/100),四项推荐(N1 合并/白布合并/远征 round 吞没修正/三立绘重出)已全部执行合 main 并 push,CI 绿;工作区四侧全清,唯一开放项=视觉观感反馈。

## 【开局动作】

1. 读 PROGRESS.md 顶段 2026-08-05 条目
2. 读 `docs/sessions/2026-08-05_1100_夜批收账全推荐执行.md`
3. `git worktree list` + `git branch --list 'worktree-*' 'night/*'`:应只余主 checkout 与 main(上批四侧已清;若有新增=其他会话在途,别不知情重做)
4. `git pull --rebase --autostash`,然后校验本清单是否仍然有效:

   ```bash
   git merge-base --is-ancestor 108842f6 HEAD && echo ANCESTOR_OK
   git status -sb | head -1
   ```

   - `ANCESTOR_OK` **且**与 origin 同步 → 快照有效,继续。(HEAD 比 `108842f6` 新 1 个纯文档 commit 属正常,不是漂移)
   - `--is-ancestor` 不成立 → **快照作废**:停下报告差异,重测 analyze/test 基线,禁转抄下方数字。
5. 选读 memory:`reference_anti_hallucination`(固定)+ `feedback_visual_acceptance`(观感反馈 SOP)+ `feedback_visual_capture_seed_idempotency`(错拍第二形态)+ `reference_cli_dispatch_pipeline`(codex -i 坑新记)

## 【环境快照】(上一会话实测;本会话改动代码后必须重测,禁转抄)

- HEAD `108842f6`(本 session 3 merge+3 分支 commit,已 push;本 handoff commit 后 +1)
- `flutter analyze --no-pub` → EXIT=0 · No issues(5.9s)|主 checkout 2026-08-05 实测
- 全量 `flutter test --no-pub` → **4858 pass / 0 fail**(5m45s 首跑即绿;settlement 树实测,合并态树哈希 `f3e692e5` 逐字节同故即 main 数;CI run 30970142684 同树 SUCCESS 21m36s 双保险)
  - **守恒核对**:= 批 C 基线 4854 + 本次新增 4(expedition_cycle_test 缩放组:恒等短路/整数件反吞没/exp round 判别/内力 round 判别),逐值吻合
- 受影响测族主 checkout 复跑:expedition_cycle 9 / character_avatar 21 全绿(2026-08-05 实测)
- 在途 PR / 分支:**无**(夜班两分支+殻分支+settlement 三验后全删,远端只 main)
- 子系统:塔 49 层三批+夜批全收口;白布+三立绘代终拍待观感;远征 cycle≥2 整数件奖励已 ceil 化

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 观感反馈:我方色调/白布动势/二弟子接地(推荐) | 人工+opus high | 15-30min | 证据 10 件在 `~/Desktop/挂机武侠_夜批收账证据_2026-08-05/`;定谳或 revert 一条命令;二弟子接地偏浮 ~7px 要修=布局锚或恢复逐图补偿一行 |
| 2 | N2 远征其余候选拍板(0.5 全线进位/里程碑 [15,30]) | opus high | 15min | 候选 a 已实施;报告 `docs/audit/expedition_cycle_numbers_probe_2026-08-05.md` |
| 3 | webp 压缩批(4 新 PNG 0.8-1.9M/张 + 批 C 存量) | opus high | 45-60min | 沿 memory `feedback_wuxia_webp_cleanup_recipe`(勿先 dry-run/alpha 逐值 Δ=0 验证) |
| 4 | BACKLOG 一区拍板项(#3-#7/#11-#13) | opus high | 按项 | 一#14 已实施待观感 |

## 【硬约束沿用】

- 视觉判定用户终拍;上批代终拍是「全部按推荐执行」一次性授权非新常态 → memory `feedback_visual_acceptance`
- 夜批收账以 git 为唯一真相源,tip `[READY]/[BLOCKED]` 语义 → CLAUDE §8.3 + memory `feedback_night_batch_dispatch_protocol`
- flutter test 批跑静默漏跑,验收逐文件确认 → memory `feedback_flutter_test_batch_silent_skip`
- 推荐不得为省工作量缩水 → memory `feedback_no_effort_saving_in_recommendations`
- 全量默认并发;自包含改动只 targeted → memory `feedback_test_cadence_no_blind_full`

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测的快照;改动代码后**必须重测**,禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出,launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line;不确定写「不知道」,不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】(与置顶契约呼应)

读完上述清单后先提交一份报告,**不动代码**:

1. **防装读要求**:须引用本清单里**不存在**的原文——PROGRESS.md 顶段条目的**原文标题行与日期**,以及 `docs/sessions/2026-08-05_1100_夜批收账全推荐执行.md`「下一步建议」小节的**原文首条**。只复述本清单已有的信息不算完成。
2. 报告【开局动作】第 3、4 步结果:在途分支情况 + HEAD 校验判定(有效/作废)。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`(Step 0-4 为 canonical 流程,此处不复述,防拷贝漂移)。
