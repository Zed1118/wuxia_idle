# 新会话开局清单

> 交接时间：2026-08-04 14:16 · 工作收口于 main HEAD `e36884f9` · 主 checkout 与 origin/main 同步、工作树干净
> 本清单自身的落盘 commit 排在 `e36884f9` 之后，故实际 HEAD 会比它新 1-2 个纯文档 commit——**这不是漂移**，判据见【开局动作】第 4 步。

## 【本会话契约】（置顶，最高优先级）

- **模式：只读**
- **只读模式**：完成【开局动作】并提交【先报告】后，等用户指令才可动代码。
- **范围围栏**：只做用户选定的任务。过程中发现的其他问题分两类处置——
  - **非阻塞型**（不影响当前任务正确性）→ 记入项目根 `BACKLOG.md`，附 file:line 与复现步骤，**不动代码**；
  - **阻塞型**（当前任务建立在它之上，不修就是在错地基上盖楼）→ **停下报告**，不要记了账继续干。
- **拍板点**（设计取舍、多方案选型、观感判断）：停下列选项等用户，禁代拍。
- **本轮额外围栏**：批 B/C 体量均不小，**不压缩、不切「最小闭环」**（CLAUDE §7 打磨期原则）；
  出推荐前过「假设工作量不是考虑因素，这条会变吗」自检 → memory `feedback_no_effort_saving_in_recommendations`。

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

塔 49 层 1:1 锚死批 A 主体已完成（PR #115 draft **未合**，含数据/代码/28 篇叙事/机制校准），
批 B（周目语义）/批 C（8 张立绘）未开工。

## 【开局动作】

1. 读 PROGRESS.md 顶段。**注意**：main 顶段是「2026-08-04 批 A · A0」条目；**批 A 主体的
   条目在 PR #115 分支上未进 main**，看全貌须读分支版 PROGRESS 或 PR #115 body。
2. 读 `docs/sessions/2026-08-04_1416_批A塔重排.md`
3. `git worktree list` + `git branch --list 'worktree-*'`：**本轮确有在途分支**（见下方在途行），
   PROGRESS.md 只反映 main，别在不知情的情况下重做一遍。
4. `git pull --rebase --autostash`，然后校验本清单是否仍然有效：

   ```bash
   git merge-base --is-ancestor e36884f9 HEAD && echo ANCESTOR_OK
   git status -sb | head -1
   ```

   - `ANCESTOR_OK` **且**与 origin 同步 → 快照有效，继续。（HEAD 比 `e36884f9` 新几个纯文档
     commit 属正常，**不是**漂移，别误报）
   - `--is-ancestor` 不成立 → **快照作废**：停下报告差异，重测 analyze/test 基线，禁转抄下方数字。
5. 选读 memory：`reference_anti_hallucination`（固定）+ `feedback_no_effort_saving_in_recommendations`
   + `feedback_wuxia_long_term_polish_no_backlog` + `feedback_living_doc_state_drift`
   + `feedback_test_cadence_no_blind_full` + `feedback_break_red_after_commit`
   + `reference_codex_image_gen_art_pipeline`（若做批 C）

## 【环境快照】（上一会话实测；本会话改动代码后必须重测，禁转抄）

- main HEAD `e36884f9`（= PR #114 merge；本 session main 上 0 功能 commit，批 A 主体 6 commit
  在分支 `f5b71742..c6eaca80`，已全 push）
- `flutter analyze --no-pub` → **EXIT=0 · No issues found · 6.8s**｜主 checkout `e36884f9` 2026-08-04 实测
- 全量 `flutter test --no-pub`：
  - main（A0 态）→ **CI run 30872962995 全绿**（21m14s success，PR #114 合并后 push run）
  - 分支（批 A 主体）→ **4813 pass / 0 fail**｜worktree 2026-08-04 实测
  - **守恒核对**：4813 = 上轮基线 4805 + A0 新增 8（isFirstClear 上界 1 + availableFloor/canChallenge
    上界 3 + tower coverage 守卫 4）；批 A 主体净增 0（23 文件全是改断言/采样重排），逐值吻合
- **在途 PR / 分支**：
  - PR **#115**（draft，OPEN，未合）`worktree-tower-batch-a` @ `c6eaca80` — 批 A 主体全部产物；
    worktree `.claude/worktrees/tower-batch-a` 保留
  - **PR #115 CI 首跑 format 门禁红**（python 批量编辑 6 文件），`c6eaca80` 修复后重跑中——
    **合并前必须现查 `gh pr checks 115` 双 job 绿**，别转抄本行
- 子系统状态：塔 49 层数据/代码/叙事/机制校准全部完成；批 D worktree 与分支已四侧清理；
  codegraph 索引已重建（lib/ 521 文件全覆盖，test/ 基本未索引仍须 grep）

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 等 PR #115 CI 绿 → review → 合并（推荐） | opus high | 30-45min | 2438 行数值+8 新 Boss 命名+16 篇文案+机制校准拍板，方向性内容多值得扫一眼；合并前可选真机 720p smoke（塔列表 49 行/总览滚动/新 Boss 战斗屏三处 UI） |
| 2 | 批 B 周目语义修正（B1-B5） | opus xhigh | 60-90min | 属性缩放→境界段推进；与批 A 文件不重叠可并行；含 spec §1.3「净威胁 ~2.4×」实测与 cycle2 败率统一重校 |
| 3 | 批 C 8 张 Boss 立绘 | codex image_gen | 随批 | 18/21/25/28/35/39/42/46 现为主线敌池占位；配方 memory `reference_codex_image_gen_art_pipeline`；出图后换 iconPath+脚底校准+真机目检 |
| 4 | 真机视觉 smoke（塔三处 UI） | opus high | ~20min | 若不随 #1 做则单独跑；widget 测已绿但 49 行滚动/定位滚动手感须真机 |

## 【硬约束沿用】

- 推荐不得为省工作量缩水范围；抄来的形状必自己算 → memory `feedback_no_effort_saving_in_recommendations`
- backlog 只承载「依赖未解除 / 待拍板」两类 → memory `feedback_wuxia_long_term_polish_no_backlog`
- 长寿文档状态/行号会 drift，引用前重新定位 → memory `feedback_living_doc_state_drift`
- 全量默认并发，交接不重复验已记录的绿 → memory `feedback_test_cadence_no_blind_full`
- 破坏证红必须在 commit 后做 → memory `feedback_break_red_after_commit`
- python/perl 批量编辑 dart 后必跑 `dart format`（管道 tail 会吞 analyze exit code）→ 本轮踩坑，详 session 记录
- vuln 型 Boss 迁数值段必须血量-乘子-相位联动校准（bootstrapping）→ 详 session 记录「踩坑提醒」

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测的快照；改动代码后**必须重测**，禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】（与置顶契约呼应）

读完上述清单后先提交一份报告，**不动代码**：

1. **防装读要求**：须引用本清单里**不存在**的原文——main 上 PROGRESS.md 顶段条目的**原文标题行
   与日期**，以及 `docs/sessions/2026-08-04_1416_批A塔重排.md`「下一步建议」小节的**原文首条**。
   只复述本清单已有的信息不算完成。
2. 报告【开局动作】第 3、4 步结果：在途分支情况 + HEAD 校验判定（有效 / 作废）+
   `gh pr checks 115` 现查结果。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`（Step 0-4 为 canonical 流程，此处不复述，防拷贝漂移）。
