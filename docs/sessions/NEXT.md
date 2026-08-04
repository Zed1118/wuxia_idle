# 新会话开局清单

> 交接时间:2026-08-05 夜班收尾 · main=`0bb16d37`(批 C 全收口已推)· 夜班产出在本地分支 `night/20260805-capture-window-pid`(未 push,约束所限)
> **本清单在夜班分支上**:main 的 NEXT.md 仍是批 C 交接版(其任务已全部完成,勿照做)。开局若从 main 读到旧版,以本版为准。

## 【本会话契约】

- 开局动作完成后**先报告再动**;合并夜班分支前按 §8.2 Gate 独立复核(夜班会话是作者,本会话是复核者)。
- 三份报告的调参/美术方向全是**拍板项**,禁代拍。

项目:挂机武侠(/Users/a10506/Desktop/Projects/挂机武侠)

白班批 C 终拍放行合入(PR #118 `6cf4d5c3` + 落账 `0bb16d37`),塔 49 层三批全收口;夜班自主批产出 1 条代码修复分支 + 3 份拍板报告,等评审。

## 【开局动作】

1. 读 `docs/sessions/2026-08-05_夜班N1-N4.md`(夜班分支)——四任务全貌与评审入口
2. `git log --oneline main..night/20260805-capture-window-pid`——应见 N1 修复 commit(`365237ad`)+ docs commit
3. 校验:`git -C /Users/a10506/Desktop/Projects/挂机武侠 status --short --branch`(main 应与 origin 同步、树净)
4. 选读 memory:`reference_anti_hallucination` + `feedback_visual_capture_seed_idempotency`(N1 关联,合并后此 memory 需补一条「错拍」形态)

## 【环境快照】

- main=`0bb16d37` 与 origin 同步;夜班两分支基线即此,**零 lib/ 生产代码改动**(N1 全在 tools/),基线 analyze/test 绿沿用
- 夜班分支一:`night/20260805-capture-window-pid`(N1 修复 + N2-N5 报告/handoff,可评审合并)
- 夜班分支二:`night/20260805-songguan-baibu` tip `2c5278f1` **[BLOCKED]**(二#8 派单已备,卡 Codex 出图+用户终拍,§8.3 勿合;派单 `docs/superpowers/plans/2026-08-05-songguan-baibu-imagegen-dispatch.md`)
- N1 验证证据:`build/visual_acceptance/night_n1_verify/`;二#7 量测证据:`build/visual_acceptance/night_n5_cliff/`(均 gitignored)
- 错拍取证唯一留存:job tmp `batch_c_smoke_review/`(18 张当晚 smoke 平铺副本),N1 合并前勿删

## 【下波候选】

| # | 任务 | 模型 | 预估 | 备注 |
|---|------|------|------|------|
| 1 | 评审合并夜班 N1 分支 + BACKLOG 批改(推荐) | opus high | 30min | Gate 复核 tools/ 两文件 diff+验证证据 → 合 main;随批 BACKLOG:二#9 销(N4)/二#10 销改「错拍已修」(N1)/一#14 注记 N3 报告 |
| 2 | 色调方案拍板 → 若拍 a 开工重出 3 张 | opus high | 1 批 | N3 报告数据+出图规范已备(`player_standee_tone_audit_2026-08-05.md`) |
| 3 | 远征周目调参拍板 | opus high | 15min | N2 报告候选 a-d(`expedition_cycle_numbers_probe_2026-08-05.md`),核心=整数件奖励 round 吞没 |
| 4 | 二#8 白布返修:发 Codex 派单 → 复测接线 → 终拍 | opus high | 1 派单往返 | 派单已自包含备好([BLOCKED] 分支);BACKLOG 批改随 #1 一并:二#7 附带销/二#9 销/二#10 销/四·塔条目更新 |

## 【硬约束沿用】

- 视觉判定用户终拍 → memory `feedback_visual_acceptance`
- 全量默认并发;自包含改动只 targeted → memory `feedback_test_cadence_no_blind_full`
- 推荐不缩水范围 → memory `feedback_no_effort_saving_in_recommendations`

## 【先报告】

1. 报告开局动作 2/3 步结果(夜班分支 commit 清单 + main 同步态)。
2. 复述 N2 报告「三 · 奖励 0.25 真实效果」表格的**断魂帖行**结论(防装读)。
3. 等指令。
