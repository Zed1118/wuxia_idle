# 新会话开局清单

> 交接时间：2026-08-26 20:34 · 工作收口于 HEAD `b0644ce5` · 领先 `origin/main` 703 commit、**未 push**；主 checkout 工作树干净
> 本清单自身的落盘 commit 排在 `b0644ce5` 之后，故实际 HEAD 会比它新 1 个纯文档 commit——**这不是漂移**，判据见【开局动作】第 4 步。

## 【本会话契约】（置顶，最高优先级）

- **模式：只读**
- **只读模式**：完成【开局动作】并提交【先报告】后，等用户指令才可动代码。
- **范围围栏**：只做用户选定的任务。过程中发现的其他问题分两类处置——
  - **非阻塞型** → 记入 `BACKLOG.md`，附 `file:line` 与复现步骤，**不动代码**；
  - **阻塞型** → **停下报告**，不要记了账继续干。
- **拍板点**（设计取舍、多方案选型、观感判断）：只读模式下停下列选项等用户，**禁代拍**。当前已有两条挂起待拍（见【下波候选】#2/#3），不得替用户决定。
- **角色**：本会话是协调者，**不干具体的活**——实装下放 codex，我只做派单、复核、Gate、合并。

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

二阶段战斗核心接线：W0 差异分析已合 main，P1 统一姿态接线复核不过待返修，D 破防技崩溃待用户拍处置方案。

## 【开局动作】

1. 读 PROGRESS.md 顶段「二阶段结果仪表盘（2026-08-26 夜批收账后）」
2. 读 `docs/sessions/2026-08-26_203415_姿态接线_p2-handoff-20260826b.md`
3. `git worktree list` + `git branch --list 'codex/p2-*'`：确认在途分支。**当前 worktree 共 169 条**（历史债），二阶段在途的只有下列两条，别在不知情下重做。
4. **只 `git fetch`，不自动 rebase/autostash**。按下列顺序判定：

   ```bash
   git status -sb | head -1
   git fetch origin
   git rev-list --left-right --count origin/main...HEAD
   git merge-base --is-ancestor b0644ce5 HEAD && echo ANCESTOR_OK
   ```

   - 工作树 dirty / 存在分叉 / 有其他活跃写者 → **停下报告**，不自行更新
   - 本项目 `origin/main` 落后本地 703 commit 且 **push 未获授权**，故**不要** `merge --ff-only origin/main`，也不要 push
   - `ANCESTOR_OK` 成立 → 快照有效，继续；不成立 → 快照作废，停下报告并重测基线
5. 选读 memory：`reference_anti_hallucination`（固定）+ `feedback_multi_anchor_test_actual_attribution`、`feedback_flutter_test_batch_silent_skip`、`feedback_premature_completion_report`、`feedback_dispatch_first_orchestrator`

## 【环境快照】（2026-08-26 本会话实测，禁转抄）

- HEAD `b0644ce5`（本会话 main 新增 3 commit，全部纯文档，**0 行 `lib/`**；未 push）
- **main 全量基线沿用 `6a0c2945` 的 `5611/5611`**（2026-08-26 夜批实测）——本会话实测 `git diff 6a0c2945..b0644ce5` 为：`PROGRESS.md` + 3 份派单包 + 1 份 spec + 1 个测试文件的**纯 `///` 注释块**（`test/data/phase2/ch1_candidate_combat_catalog_test.dart`，13 行全是注释），`lib/` 改动 0 文件，故基线仍成立，未重跑全量（属 handoff 0a「纯文档 session」情形）
- **分支 `codex/p2-posture-wiring-20260826` @ `2c8015d9` 本会话实测**：`flutter analyze --no-pub lib test` **0 issue**；`dart format` 1523 文件 **0 changed**；全量 `flutter test --no-pub` **`5612 +/ 4 -`，耗时 5m41s，退出码 0（掩盖了失败）**
  - 4 条失败（本会话从 `[E]` 块定位，非猜测）：
    1. `test/features/battle/domain/phase0a/phase0a_source_contract_test.dart:89` 「不得出现数值参数默认值」——`phase0a_combat_reducer.dart` 出现 `"= 0,"`
    2/3. `test/features/battle/presentation/phase0a/phase0a_battle_screen_test.dart:175` 「首屏威胁去噪 HUD(双视口)」1280×720 与 1440×900 均红——普通满血敌人 `wave1_blade` 常驻姓名「山贼刀客」被渲染
    4. 同文件「键盘 J 普攻…目标血条强调保持后自动消退」——血条 key `phase0a_hp_wave1_archer` 未消退
  - 根因：2/3/4 同源，新增 `_BossStatusTag` 姿态计数把普通敌人姓名/血条一并拉出；1 是红线契约违规
- 在途 PR / 分支：
  - `codex/p2-posture-wiring-20260826` @ `2c8015d9` `[READY]` — **复核不过，不可合**（worktree `挂机武侠-p2-posture`）
  - `codex/p2-defense-break-reachability-20260826` @ `39ae8f83` `[BLOCKED]` — 仅审计+复现测，零 `lib/`；我复跑 1/1 通过；待用户拍处置（worktree `挂机武侠-p2-dbrk-diag`）
  - `codex/p2-w0-wiring-delta-20260826` @ `130a57c6` — **已合 main**，可清
  - 协调 worktree：`挂机武侠-coord-handoff2`（本次交接落盘用）、`挂机武侠-coord-decisions`、`挂机武侠-p2-break`（scratch，破坏证红待用）
- 子系统状态：二阶段战斗核心三条接线（POSTURE / TIMELINE / QI）中，POSTURE 是第一条动工的，语义正确但 UI 回归未过；TIMELINE、QI 尚未开工。M0–M9 仍 `1/10`。

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 把 P1 连同 4 条失败清单返 codex 返修（推荐） | opus 调度 + codex 执行 | 派单 10min / 执行 40-60min | 根因已定位到 `file:line`，返修范围小、不需重设计；返修后须由我复跑**全量**才谈合并 |
| 2 | 用户拍 #4 真人试玩门槛 | — | — | A 合 main 前须过试玩（我的立场）/ B 豁免 / C 连已合的 TOKEN 一并回滚。方案 §0.1 要求 TUNING 值须经真人试玩定标，我生成候选时只跑了模拟 |
| 3 | 用户拍 #5 破防技崩溃处置 | — | — | A 并入 POSTURE 批按姿态伤害处理（合 §5.3/§5.4）/ B 独立止血批 / C 砍字段 |
| 4 | 定义 M0–M9 权重 | opus | 60-90min | 结构性问题：整条 TUNE-* 接线不推动 `1/10` 这个权威分母，不定义权重就无法回答「二阶段做到哪了」 |
| 5 | worktree 债清理（169 条） | sonnet | 30-45min | 已续传第 2 轮，按 handoff 0c 本轮须强制处置；清理前三验（`is-ancestor` / `main..branch` 计数 0 / `branch --merged`） |

## 【硬约束沿用】

- `flutter test` 退出码 0 不代表全绿，reporter 的 `-N` 打在刚跑完那条旁边而非失败那条 → memory `feedback_multi_anchor_test_actual_attribution`
- 多路径批跑会静默漏跑文件，验收须逐文件数「All tests passed」出现次数 → memory `feedback_flutter_test_batch_silent_skip`
- launch ≠ 成功，报「完成/全绿」前必跑验证并贴输出 → memory `feedback_premature_completion_report`
- 能派就派，协调者只留 Gate 与终审，不承接实装 → memory `feedback_dispatch_first_orchestrator`
- 执行端禁区逐个列进派单包：`data/numbers.yaml` / `GDD.md` / `PROGRESS.md` / `lib/shared/strings.dart` / `pubspec.yaml`；禁 push / 禁 merge / 禁碰 main / 禁 revert → memory `feedback_night_batch_dispatch_protocol`
- commit message 中文动宾，合并 Gate ⓓ 明查 → memory `feedback_wuxia_commit_message_chinese_gate`
- fresh worktree 必预热：`cp libisar.dylib` + `pub get` + `build_runner` → memory `feedback_fresh_worktree_libisar_dylib` / `feedback_wuxia_pen_build_runner`
- 测试绕开生产路径是假绿最高发入口，自检「破坏那行，这条断言必然红吗」 → memory `feedback_test_bypasses_production_path`
- 推荐不得为省工作量缩水范围 → memory `feedback_no_effort_saving_in_recommendations`
- 开工与收尾各查一次在途 worktree/分支，PROGRESS 只反映 main → memory `feedback_phase0_check_inflight_worktrees`

## 【防幻觉守则】

- 本清单【环境快照】的数字是 2026-08-26 实测快照；改动代码后**必须重测**，禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 `file:line`；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】（与置顶契约呼应）

读完上述清单后先提交一份报告，**不动代码**：

1. **防装读要求**：须引用本清单里**不存在**的原文——PROGRESS.md 顶段条目的**原文标题行与日期**，以及 session 记录「下一步建议」小节的**原文首条**。只复述本清单已有的信息不算完成。
2. 报告【开局动作】第 3、4 步结果：在途分支情况 + HEAD 校验判定（有效 / 作废）。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`（Step 0-4 为 canonical 流程，此处不复述）。
