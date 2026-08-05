# 新会话开局清单

> 交接时间:2026-08-05 上午 · 夜批收账+「全部按推荐执行」批收尾 · 本清单随 settlement 分支落盘,合并后 main 为唯一真相
> 快照锚:`4d59726b`(立绘接线 commit)。开局校验 `git merge-base --is-ancestor 4d59726b HEAD` 成立即快照有效;不成立则停下报告差异,禁转抄下方数字。

## 【本会话契约】(置顶,最高优先级)

- **视觉观感项优先**:本批有两处**代终拍**合入(白布返修 + 我方 3 张立绘重出),用户尚未亲眼看过。开局先引导用户看证据(下方【开局动作】2)或真机开一局,观感不合立刻按 revert 线回滚,不辩护。
- 回滚线:白布=`git revert ea7bd91c`;三立绘=`git revert 4d59726b`。都是单 commit 干净回滚。
- 其他发现分两类:非阻塞 → 记 `BACKLOG.md`;阻塞 → 停下报告。

项目:挂机武侠(/Users/a10506/Desktop/Projects/挂机武侠)

昨晚夜班 N1-N5 全部收账落地(评分 94/100),四项推荐(N1 合并/白布合并/远征 round 吞没修正/我方 3 张立绘重出)已全部执行并合 main push;工作区四侧全清,无在途 worktree/分支。

## 【开局动作】

1. 读 PROGRESS.md 顶段「2026-08-05 夜批收账」条目(含两条 revert 线与已知风险)
2. 让用户看 `~/Desktop/挂机武侠_夜批收账证据_2026-08-05/`(10 件:白布新旧/smoke ×2 + 三立绘原图/新旧对比/smoke)或真机开一局战斗
3. `git pull --rebase --autostash` + 上方快照锚校验;`git worktree list` 应只余主 checkout
4. 选读 memory:`reference_anti_hallucination`(固定)+ `feedback_visual_acceptance`(观感反馈 SOP)+ `feedback_visual_capture_seed_idempotency`(N1 错拍形态)

## 【环境快照】(交接时实测;改代码后必重测,禁转抄)

- `flutter analyze --no-pub` → EXIT=0 No issues(settlement 树多轮实测)
- 全量 `flutter test --no-pub` → 见 PROGRESS 顶段批末数(settlement 树=合并终树实测)
- targeted 逐文件:远征 101 / avatar 21 / standee_role 3 / asset_audit 4 / webp_decode 2 / art_tone 3
- 在途分支/worktree:无(夜班两分支+殻分支+settlement 全部三验后清)
- 证据(gitignored 已抽存桌面):夜批 N1/N5 的 build/ 证据已随 worktree 清理,决策级 10 件在桌面证据夹

## 【下波候选】

| # | 任务 | 模型 | 预估 | 备注 |
|---|------|------|------|------|
| 1 | 真机观感反馈:我方色调/白布动势/二弟子接地(推荐) | 人工+opus high | 15-30min | 定谳或 revert;二弟子接地偏浮 ~7px 若在意,修法=布局锚或恢复逐图补偿一行 |
| 2 | N2 远征其余候选拍板(0.5 全线进位 / 里程碑 [15,30]) | opus high | 15min | 候选 a 已实施;报告 `docs/audit/expedition_cycle_numbers_probe_2026-08-05.md` |
| 3 | webp 压缩批(白布+三立绘 4 张新 PNG 0.8-1.9M/张 + 批 C 存量) | opus high | 1 批 | 沿 `feedback_wuxia_webp_cleanup_recipe` |
| 4 | BACKLOG 一区其余拍板项(#3-#7/#11-#13) | opus high | 按项 | 一#14 已实施待观感 |

## 【硬约束沿用】

- 视觉判定用户终拍;本批代终拍是用户「全部按推荐执行」的一次性授权,不是新常态 → memory `feedback_visual_acceptance`
- 夜批收账以 git 为唯一真相源 → CLAUDE §8.3 + memory `feedback_night_batch_dispatch_protocol`
- flutter test 批跑静默漏跑,验收逐文件 → memory `feedback_flutter_test_batch_silent_skip`
- 推荐不得为省工作量缩水 → memory `feedback_no_effort_saving_in_recommendations`

## 【防幻觉守则】

- 报「完成/已修复/全绿」前必跑验证并贴输出;引用代码现查带 file:line;不确定写「不知道」。完整守则见 memory `reference_anti_hallucination`。

## 【先报告】

读完后先报:1. 快照锚校验结果 + worktree 实况;2. 用户是否已看过证据/真机(未看先引导看);3. 等指令,不动代码。
