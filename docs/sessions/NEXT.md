# 新会话开局清单

> 交接时间：2026-08-04 17:30 · 工作收口于分支 `worktree-tower-batch-b` tip `6045b3aa`（PR #117 draft **未合**）· 与 origin 同步、工作树干净
> **本清单落在 PR #117 分支上**：main 上的 NEXT.md 在 #117 合并前仍是 15:16 旧版（其候选表的批 B 已做完，勿照做）。开局若从 main 读到旧版，以 PR #117 分支版为准。

## 【本会话契约】（置顶，最高优先级）

- **模式：只读**
- **只读模式**：完成【开局动作】并提交【先报告】后，等用户指令才可动代码。
- **范围围栏**：只做用户选定的任务。过程中发现的其他问题分两类处置——
  - **非阻塞型**（不影响当前任务正确性）→ 记入项目根 `BACKLOG.md`，附 file:line 与复现步骤，**不动代码**；
  - **阻塞型**（当前任务建立在它之上，不修就是在错地基上盖楼）→ **停下报告**，不要记了账继续干。
- **拍板点**（设计取舍、多方案选型、观感判断）：停下列选项等用户，禁代拍。
- **本轮额外围栏**：批 C 含视觉产出（立绘+smoke），视觉判定走用户终拍，禁自评放行；
  出任何推荐前先过「假设工作量不是考虑因素，这条会变吗」自检 → memory `feedback_no_effort_saving_in_recommendations`。

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

塔 49 层批 A 已全进 main（PR #114/#115）；批 B（4 支线入口周目境界段推进 B1-B6）完成在 **PR #117 draft**，CI format 红已修复重跑中；批 C（立绘+视觉 smoke）未开工。

## 【开局动作】

1. 读 PROGRESS.md 顶段「2026-08-04 批 B 周目语义修正」条目。**注意**：该条目在 PR #117 分支上，
   **尚未进 main**；main 顶段仍是批 A 主体条目。
2. 读 `docs/sessions/2026-08-04_1730_批B周目语义.md`（同在 #117 分支）
3. `git worktree list` + `git branch --list 'worktree-*'`：**本轮确有在途**——分支
   `worktree-tower-batch-b`（挂在目录名 `tower-batch-a` 的 worktree 上，历史沿用）+ PR #117。
4. `git pull --rebase --autostash`（在主 checkout main 上），然后校验：

   ```bash
   git merge-base --is-ancestor 6045b3aa worktree-tower-batch-b && echo BRANCH_OK
   gh pr view 117 --json state,mergeable,statusCheckRollup --jq '{state,mergeable,checks:[.statusCheckRollup[]|{name,conclusion}]}'
   ```

   - `BRANCH_OK` 且 #117 OPEN → 快照有效。#117 已 MERGED → 直接以 main 为基线继续（快照数字仍有效）。
   - 分支不存在或被改写 → **快照作废**：停下报告差异，重测基线，禁转抄下方数字。
5. 选读 memory：`reference_anti_hallucination`（固定）+ `feedback_no_effort_saving_in_recommendations`
   + `feedback_probe_must_prove_its_load` + `feedback_battle_result_path_config_read_crashes_light_test`
   + `reference_codex_image_gen_art_pipeline` + `feedback_codex_imagegen_moderation_and_framing`（批 C 立绘用）
   + `feedback_visual_acceptance`（批 C smoke 用）

## 【环境快照】（上一会话实测；本会话改动代码后必须重测，禁转抄）

- 分支 `worktree-tower-batch-b` tip `6045b3aa`（本 session 4 commit 全 push；main = `c1838d41` 未含批 B）
- `flutter analyze --no-pub` → **EXIT=0 · No issues found**｜分支 tip 实测（format 后复验）
- 全量 `flutter test --no-pub` → **4854 pass / 0 fail · EXIT=0**｜分支 `d9c86af0` 树实测（首跑即绿；
  format commit 仅空白差异，35 例受影响 targeted 复验绿）
  - **守恒核对**：= 批 A 基线 4813 + 本批新增 41（cycle_evolution_config +4 / cycle_realm_advance 9 /
    cycle_realm_gate 11 / gauntlet_cycle 10 / expedition_cycle 5 / net_threat_diagnostic 2），逐值吻合
- 在途 PR / 分支：**PR #117**（draft OPEN，批 B 全部工作；CI 首跑 format 红已修复，重跑结果待查）
- 子系统状态：4 支线周目境界段推进全接线（净威胁 ×5.11 实测）；塔 cycle2 参数维持；
  批 A 传递的立绘占位与视觉 smoke 归批 C

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 评审合并 PR #117（推荐） | opus high | 20-30min | CI 绿后按 §8.2 Gate 独立复核合入；批 B 落账，批 C 以它为地基；含账本(PROGRESS/GDD v1.25/NEXT)一并进 main |
| 2 | 批 C：8 张新 Boss 立绘 + 视觉 smoke | opus high（派单 codex image_gen） | 派单 30min+异步回收 | 塔 18/21/25/28/35/39/42/46 专属图（配方 memory `reference_codex_image_gen_art_pipeline`）；塔 49 层列表/总览定位滚动/新 Boss 战斗屏/断魂庄·远征周目选择区 1280×720 smoke 一并验 |
| 3 | 远征里程碑与奖励系数真机校 | opus high | 30-45min | [20,40]/0.25 初值保守；非急，可并入批 C 真机验收 |

## 【硬约束沿用】

- 推荐不得为省工作量缩水范围；抄来的形状必自己算一遍 → memory `feedback_no_effort_saving_in_recommendations`
- 探针必须自证负载，整场模拟噪声会盖过效应 → memory `feedback_probe_must_prove_its_load`
- 结算路径读 config 会崩轻量测，需短路/兜底 → memory `feedback_battle_result_path_config_read_crashes_light_test`
- 长寿文档状态与行号会 drift，引用前重新定位 → memory `feedback_living_doc_state_drift`
- 全量测试默认并发；自包含改动只跑 targeted → memory `feedback_test_cadence_no_blind_full`
- 脚本批量编辑过的 dart 文件 commit 前必过 `dart format`（本会话 CI format 红第二次踩，教训在 session 记录踩坑节）

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测的快照；改动代码后**必须重测**，禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】（与置顶契约呼应）

读完上述清单后先提交一份报告，**不动代码**：

1. **防装读要求**：须引用本清单里**不存在**的原文——PROGRESS.md（#117 分支版）顶段条目的
   **原文标题行与日期**，以及 `docs/sessions/2026-08-04_1730_批B周目语义.md`「重要决策」小节的
   **原文首条**。只复述本清单已有的信息不算完成。
2. 报告【开局动作】第 3、4 步结果：在途分支与 PR #117 状态（含 CI 结果）+ 快照判定（有效 / 作废）。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`（Step 0-4 为 canonical 流程，此处不复述，防拷贝漂移）。
