# 新会话开局清单

> 交接时间:2026-08-05 07:35 · 白班批 C 终拍复核会话收尾 · main=`0bb16d37` 与 origin 同步、工作树干净(本清单落盘 commit 后 HEAD +1,**非漂移**,判据见【开局动作】4)
> **本版已整合夜班分支上的 NEXT**(`night/20260805-capture-window-pid` 那份;其 songguan tip `2c5278f1`/「等出图」信息已过时,以本版为准)。合并夜班分支遇 `docs/sessions/NEXT.md` 冲突时**取 main 版**。

## 【本会话契约】(置顶,最高优先级)

- **模式:只读**
- **只读模式**:完成【开局动作】并提交【先报告】后,等用户指令才可动代码。
- **范围围栏**:只做用户选定的任务。其他发现分两类——非阻塞型 → 记项目根 `BACKLOG.md`(附 file:line+复现步骤),不动代码;阻塞型 → 停下报告,不要记了账继续干。
- **拍板点**:夜班三份报告的调参/美术方向全是拍板项,禁代拍;白布返修与色调重出的视觉判定只归用户终拍。
- 合并任一夜班分支前按 §8.2 Gate 独立复核(夜班会话是作者,本会话是复核者,别采信作者自报);songguan-baibu tip `[BLOCKED]` = 待终拍,终拍通过前勿合(§8.3)。

项目:挂机武侠(/Users/a10506/Desktop/Projects/挂机武侠)

白班批 C 终拍放行合入(PR #118 `6cf4d5c3` + 用户落账 `0bb16d37`),塔 49 层三批全收口;夜班自主批产出 1 条修复分支 + 3 份拍板报告,songguan 白布返修已完成,等评审/终拍。

## 【开局动作】

1. 读 PROGRESS.md 顶段「2026-08-04 批 C」条目(含文末收口段)
2. 读 `docs/sessions/2026-08-05_0732_批C终拍.md`(白班复核会话)+ 夜班全貌 `git show night/20260805-capture-window-pid:docs/sessions/2026-08-05_夜班N1-N4.md`
3. `git worktree list` + `git branch --list 'worktree-*' 'night/*'`:在途 = worktree `night-shift`/`night-songguan-baibu` + 分支 `night/20260805-capture-window-pid`(tip `2bf7ec03`,N1 修复+报告,可评审)/`night/20260805-songguan-baibu`(tip `a404d35f` **[BLOCKED] 白布返修完成待终拍**)/`worktree-night-shift`(tip=main 殻分支,收账时清)
4. `git pull --rebase --autostash`,校验:

   ```bash
   git merge-base --is-ancestor 0bb16d37 HEAD && echo ANCESTOR_OK
   git status -sb | head -1
   ```

   - `ANCESTOR_OK` 且与 origin 同步 → 快照有效(HEAD 比 `0bb16d37` 新 1-2 个纯文档 commit 正常,不是漂移)。
   - `--is-ancestor` 不成立 → 快照作废:停下报告差异,重测 analyze/test 基线,禁转抄下方数字。
5. 选读 memory:`reference_anti_hallucination`(固定)+ `feedback_visual_capture_seed_idempotency`(N1 关联,合并后需补「错拍」形态)+ `feedback_visual_acceptance`(白布/色调终拍 SOP)+ `feedback_flutter_test_batch_silent_skip`(Gate targeted 逐文件)

## 【环境快照】(交接时实测;本会话改动代码后必须重测,禁转抄)

- HEAD `0bb16d37`(与 origin 同步、树净,2026-08-05 07:32 实测;本 handoff commit 后 +1)
- `flutter analyze --no-pub` → **EXIT=0 · No issues(18.6s)**|主 checkout 2026-08-05 07:32 实测
- 全量 `flutter test --no-pub` → **4854 pass / 0 fail**(2026-08-04 批 C 分支树实测=合并态树,PR #118 CI 双绿背书;批 C 零新增测试守恒 4854+0;白班复核会话纯评审未重跑;夜班 N1 零 lib/ 生产改动[全在 tools/],基线沿用)
- 在途 PR:无|在途分支:见【开局动作】3(夜班两条 + 殻分支一条)
- 证据目录(gitignored):N1 验证 `build/visual_acceptance/night_n1_verify/`;二#7 量测 `build/visual_acceptance/night_n5_cliff/`;**错拍取证唯一留存** = job tmp `/Users/a10506/.claude/jobs/01a1207d/tmp/batch_c_smoke_review/`(18 张),N1 合并前勿删
- 子系统:塔 49 层三批全收口进 main;capture「错拍」修复在夜班分支待收;BACKLOG 一#14 色调(N3 报告已备)/二#8 白布(返修完成待终拍)/二#10 fixture 漂移(N1 关联)

## 【下波候选】

| # | 任务 | 模型 | 预估 | 备注 |
|---|------|------|------|------|
| 1 | 评审合并夜班 N1 分支 + BACKLOG 批改(推荐) | opus high | 30-45min | Gate 复核 tools/ 两文件 diff+验证证据 → 合 main(NEXT 冲突取 main 版);随批 BACKLOG:二#9 销(N4)/二#10 销改「错拍已修」(N1)/一#14 注记 N3。推荐理由=代码修复先收,BACKLOG 批改绑此批 |
| 2 | songguan-baibu 白布终拍 → 通过即 Gate 合 | opus high | 15-30min | 返修已完成(硬规格过+接线零改+targeted 33 绿+smoke 过),只差用户终拍;比夜班 NEXT 记录的「等出图」已推进一步 |
| 3 | 色调方案拍板 → 若 a 重出我方 3 张 | opus high | 1 美术批 | N3 报告 `player_standee_tone_audit_2026-08-05.md` 数据+出图规范已备;BACKLOG 一#14 |
| 4 | 远征周目调参拍板 | opus high | 15min | N2 报告 `expedition_cycle_numbers_probe_2026-08-05.md` 候选 a-d,核心=整数件奖励 round 吞没 |

## 【硬约束沿用】

- 视觉判定用户终拍 → memory `feedback_visual_acceptance`
- 首轮打分判据外不加码 → memory `feedback_visual_score_first_pass_underestimate`
- flutter test 批跑静默漏跑,验收逐文件 → memory `feedback_flutter_test_batch_silent_skip`
- 推荐不得为省工作量缩水 → memory `feedback_no_effort_saving_in_recommendations`
- 全量默认并发;自包含改动只 targeted → memory `feedback_test_cadence_no_blind_full`
- 夜批收账以 git 为唯一真相源,tip `[READY]/[BLOCKED]` 语义 → CLAUDE §8.3 + memory `feedback_night_batch_dispatch_protocol`

## 【防幻觉守则】

- 本清单【环境快照】的数字是交接时实测快照;改动代码后**必须重测**,禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出,launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line;不确定写「不知道」,不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】(与置顶契约呼应)

读完上述清单后先提交一份报告,**不动代码**:

1. **防装读要求**:须引用本清单里**不存在**的原文——PROGRESS.md 顶段条目的**原文标题行与日期**,以及 `docs/sessions/2026-08-05_0732_批C终拍.md`「下一步建议」小节的**原文首条**。只复述本清单已有的信息不算完成。
2. 报告【开局动作】第 3、4 步结果:在途分支实况(含两夜班分支 tip 前缀)+ 快照判定(有效/作废)。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`(Step 0-4 为 canonical 流程,此处不复述,防拷贝漂移)。
