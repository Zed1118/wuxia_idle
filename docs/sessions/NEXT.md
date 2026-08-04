# 新会话开局清单

> 交接时间：2026-08-04 15:16 · 工作收口于 HEAD `ce114bac`（PR #115 merge）· 与 origin/main 同步、工作树干净
> 本清单自身的落盘 commit 排在 `ce114bac` 之后，故实际 HEAD 会比它新 1-2 个纯文档 commit——**这不是漂移**，判据见【开局动作】第 4 步。

## 【本会话契约】（置顶，最高优先级）

- **模式：只读**
- **只读模式**：完成【开局动作】并提交【先报告】后，等用户指令才可动代码。
- **范围围栏**：只做用户选定的任务。过程中发现的其他问题分两类处置——
  - **非阻塞型**（不影响当前任务正确性）→ 记入项目根 `BACKLOG.md`，附 file:line 与复现步骤，**不动代码**；
  - **阻塞型**（当前任务建立在它之上，不修就是在错地基上盖楼）→ **停下报告**，不要记了账继续干。
- **拍板点**（设计取舍、多方案选型、观感判断）：停下列选项等用户，禁代拍。
- **本轮额外围栏**：批 B/批 C 体量各约等于一个专批，**不压缩、不切「最小闭环」**（CLAUDE §7 打磨期原则）；
  出任何推荐前先过「假设工作量不是考虑因素，这条会变吗」自检 → memory `feedback_no_effort_saving_in_recommendations`。

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

塔 49 层扩展批 A（A0-A4+断魂帖 16/33/49+机制校准）已全部合入 main（PR #114/#115），批 B（周目语义）/批 C（立绘）未开工。

## 【开局动作】

1. 读 PROGRESS.md 顶段「2026-08-04 批 A 主体」条目（含末尾**已合并**落账段）
2. 读 `docs/sessions/2026-08-04_1516_批A合并落账.md`
3. `git worktree list` + `git branch --list 'worktree-*'`：上会话收尾判定应为**无在途**；若有残留即上会话
   worktree 清理未完成，按 /handoff Step 0c 处置后再继续。
4. `git pull --rebase --autostash`，然后校验本清单是否仍然有效：

   ```bash
   git merge-base --is-ancestor ce114bac HEAD && echo ANCESTOR_OK
   git status -sb | head -1
   ```

   - `ANCESTOR_OK` **且**与 origin 同步 → 快照有效，继续。（HEAD 比 `ce114bac` 新几个纯文档 commit 属正常，**不是**漂移，别误报）
   - `--is-ancestor` 不成立 → **快照作废**：停下报告差异，重测 analyze/test 基线，禁止转抄下方数字。
5. 选读 memory：`reference_anti_hallucination`（固定）+ `feedback_no_effort_saving_in_recommendations`
   + `feedback_wuxia_long_term_polish_no_backlog` + `feedback_living_doc_state_drift`
   + `feedback_test_cadence_no_blind_full` + `feedback_backlog_premise_experiment_on_clean_tree`
   + `feedback_wuxia_boss_balance_crosstier`（批 B 周目平衡相关）

## 【环境快照】（上一会话实测；本会话改动代码后必须重测，禁转抄）

- HEAD `ce114bac`（本次 session 0 个代码 commit；合并 PR #115 + 纯文档收尾）
- `flutter analyze --no-pub` → **EXIT=0 · No issues found · 7.5s**｜本会话于分支 tip `c6eaca80` 实测
  （合并态 main 与该树差异仅 2 纯 markdown 文档，结论等价传递）
- 全量 `flutter test --no-pub` → **4813 pass / 0 fail · EXIT=0**｜本会话同树实测（首跑即绿未触发在册 flaky）
  - **守恒核对**：= 批 A 两会话后基线 4813（A0 会话 +8 例后即 4813），本会话零测试增减，逐值吻合
  - `save_data`/`isar_setup` 无 @collection 字段增删 → 主 checkout **免 build_runner**（已实证判定）
- 在途 PR / 分支：**无**（#113/#114/#115 全合，`worktree-tower-batch-a` 四侧已清）
- 子系统状态：塔 49 层数据/机制/叙事/断魂帖全落 main；批 A 残留 4 条传递风险见 PROGRESS 顶段已知风险

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 批 B 周目语义修正（推荐） | opus xhigh | 60-90min | 属性缩放→境界段推进；解锁 cycle2 败率重校/净威胁 ~2.4× 实测/撞线语义 3 项挂账，塔扩展收口关键路径；plan B1-B5 在 `docs/superpowers/plans/2026-08-03-tower-extension.md` |
| 2 | 批 C 新 Boss 立绘 | opus high（派单 codex） | 派单 30min+异步 | 8 新 Boss 专属图（image_gen 管线）+ 塔 49 层 1280×720 视觉 smoke（列表滚动/总览定位/新 Boss 战斗屏，合并时判非阻塞传递至此）；与批 B 文件不重叠可并行 |
| 3 | `codegraph` 索引重建 | opus high | 10min | 主 checkout 索引 stale（A0 会话证伪「未初始化」）；批 B 大量查调用链前值得 |

## 【硬约束沿用】

- 推荐不得为省工作量缩水范围；抄来的形状必自己算一遍 → memory `feedback_no_effort_saving_in_recommendations`
- backlog 只承载「依赖未解除 / 待用户拍板」两类，「没空做」不合法 → memory `feedback_wuxia_long_term_polish_no_backlog`
- 长寿文档状态与行号会 drift，引用前重新定位 → memory `feedback_living_doc_state_drift`
- 净树是零风险实验窗口，BACKLOG 定性先证伪再动手 → memory `feedback_backlog_premise_experiment_on_clean_tree`
- 全量测试默认并发（`-j1` 仅排查 flaky）；自包含改动只跑 targeted → memory `feedback_test_cadence_no_blind_full`
- 章末/终局 Boss 跨阶才能真难，同阶必胜是结构事实 → memory `feedback_wuxia_boss_balance_crosstier`

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测的快照；改动代码后**必须重测**，禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】（与置顶契约呼应）

读完上述清单后先提交一份报告，**不动代码**：

1. **防装读要求**：须引用本清单里**不存在**的原文——PROGRESS.md 顶段条目的**原文标题行与日期**，
   以及 `docs/sessions/2026-08-04_1516_批A合并落账.md`「下一步建议」小节的**原文首条**。
   只复述本清单已有的信息不算完成。
2. 报告【开局动作】第 3、4 步结果：在途分支情况 + HEAD 校验判定（有效 / 作废）。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`（Step 0-4 为 canonical 流程，此处不复述，防拷贝漂移）。
