# 新会话开局清单

> 交接时间：2026-09-18 15:17 · 工作收口于 HEAD `a301e2a7b` · 与 `origin/claude/dispatch-20260917` 及链 `origin/codex/p2-player-flow-20260910` 同 tip，工作树干净
> 本清单自身的落盘 commit 排在 `a301e2a7b` 之后，故实际 HEAD 会比它新 1 个纯文档 commit——**这不是漂移**，判据见【开局动作】第 4 步。
> ⚠️ **主 checkout 本地链分支仍在 `c64b16593`（落后 20 commit）**：开局若在主 checkout，第 4 步会显示可 fast-forward，先 `git pull --ff-only` 再核 HEAD。

## 【本会话契约】（置顶，最高优先级）

- **模式：只读**
- **只读模式**：完成【开局动作】并提交【先报告】后，等用户指令才可动代码。
- **范围围栏**：只做用户选定的任务。过程中发现的其他问题分两类处置——
  - **非阻塞型**（不影响当前任务正确性）→ 记入 `BACKLOG.md`（项目根），附 file:line 与复现步骤，**不动代码**；
  - **阻塞型**（当前任务建立在它之上）→ **停下报告**，不要记了账继续干。
- **拍板点**（删配置字段 / 数值 / 规则 / schema / GDD 合同 = 🔴）：只读模式下停下列选项等用户，禁代拍。
- **链 ≠ main**：受控集成链是 `codex/p2-player-flow-20260910`；**不合并、不推送 main，不 force-push，不 rebase**。
- 不动主 checkout 4 个用户文件（`AGENTS.md` / `CLAUDE.md` / `.qoder/settings.json` / `docs/_archive/CLAUDE_v2.00_frozen_2026-09-06.md`）；不删锁定 worktree `.claude/worktrees/review-followup-20260912`；真实存档目录只读。

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

B2 numbers.yaml 复核已落地（3A 头注 / 4A 合同转守卫 / 6A analyze 噪音 / 5A 对照单），链 tip `a301e2a7b`；下一步等用户拍 5A 五段并同步主 checkout。

## 【开局动作】

1. 读 PROGRESS.md 第 19 行「在途 worktree 台账」中 **2026-09-17 晚续 / 同晚续** 两段
2. 读 `docs/sessions/2026-09-18_151300_B2复核落地_claude-dispatch-20260917.md`
3. `git worktree list` + `git branch --list 'worktree-*'`：确认在途分支（交接时 10 个 worktree，见【环境快照】）。PROGRESS.md 只反映链/main，在途工作不在其中。
4. **只 `git fetch`，不自动 rebase/autostash**。按序判定：

   ```bash
   git status -sb | head -1
   git fetch origin
   git rev-list --left-right --count origin/codex/p2-player-flow-20260910...HEAD
   git merge-base --is-ancestor a301e2a7b HEAD && echo ANCESTOR_OK
   ```

   - 工作树 dirty / 存在分叉 / 有其他活跃写者 → **停下报告**
   - 主 checkout 在 `c64b16593` 且干净 → `git pull --ff-only`（预期快进到 `a301e2a7b` 之后 1 个文档 commit）
   - `ANCESTOR_OK` 且与 origin 同步 → 快照有效；`--is-ancestor` 不成立 → 快照作废，重测 analyze/test，禁转抄下方数字
   - 并发检查：`git worktree list` 有无他人持有的 worktree；协调锁 `~/.claude/locks/` 是否被他人持有且心跳新鲜。
5. 选读 memory：`reference_anti_hallucination`（固定）+ `feedback_measure_before_adding_gate_criterion` + `feedback_yaml_config_unused_field` + `feedback_flutter_test_bg_kill_and_10min_cap` + `feedback_chinese_literal_audit_helper_extraction` + `feedback_superseded_authorization_expires`

## 【环境快照】（上一会话实测；本会话改动代码后必须重测，禁转抄）

- HEAD `a301e2a7b`（本 session 20 commits：`c64b16593..a301e2a7b`，first-parent 13；已 push 到 `origin/codex/p2-player-flow-20260910` 与 `origin/claude/dispatch-20260917`，`ls-remote` 反验两者 = `a301e2a7b`）
- `flutter analyze lib test tool` → EXIT 0 · No issues found · 4.2s｜2026-09-18 15:1x 在 worktree `.claude/worktrees/dispatch-20260917` @ `a301e2a7b` 实测（主 checkout 仍在 `c64b16593` 未同步，故未在主 checkout 测）
- 全量 `flutter test --no-pub` → **6971 PASS / 0 FAIL · EXIT 0 · 8m40s**（2026-09-17 23:06:57→23:15:37，冷 worktree @ `00ca60825`；其后 4 个 commit 均纯文档，`git diff --stat 00ca60825..a301e2a7b` = 4 个 docs 文件）
  - 守恒核对：上轮基线 6948（`c64b16593`，上版 NEXT 2026-09-17 20:04 主 checkout 实测）+ 本次新增 23（`numbers_tier_contract_guard_test` 5 + `attribute_bounds_from_numbers_test` 14 + `numbers_config_required_keys_test` 按路径参数化 +4）= 6971，逐值吻合
- `dart format --output=none --set-exit-if-changed lib test tool` → 1766 files · 0 changed
- 在途 PR / 分支：
  - `claude/dispatch-20260917`（协调者，= 链 tip）；main 未动（`origin/main...HEAD` = 0 / 90）
  - B2 codex worktree `~/Documents/Codex/2026-09-17/b2-review/wt`（`codex/b2-unused-keys-review-20260917` @ `964c5be02`，已入链）：沙箱 `Operation not permitted` 无法 remove，**留置 1 轮**；用户在主 checkout `git worktree remove` + `git branch -d` 即可
  - 锁定 `.claude/worktrees/review-followup-20260912` @ `2de185780`（不删）
  - 09-13/15/16 codex worktree 6 个（`m4-54aed-worktree` e743b6026 · `p2-native-lifecycle/source` detached e743b6026 · `p2-native-readiness` 5c1105cfa · `p2-onboarding-chain/batch1` 50e6f5383 · `batch2` e6161d566 · `p2-m4-production-matrix/wt` 564d3aaf6）沿 `docs/audit/worktree_ledger_2026-09-16.md` 口径，未动
- numbers.yaml 零引用 202 叶 → 99 叶（3A 头注 53 叶 + 待拍板 43 叶 + 3）；`numbers_unused_keys_review.py --check` 按设计 fail-closed（审计源已变），下次 B 类审计以链 tip 重锚

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 主 checkout `git pull --ff-only` + 拍 5A 五段（`docs/audit/numbers_unused_keys_pending_decision_2026-09-17.md`，回 `T-A S-A C-A I-A E-A` 式）（推荐） | opus | 拍板 5min + 执行 T/S/C/E 约 40min | 全 🔴/🟡 待拍板，是 B2 唯一未闭环项；不同步主 checkout 则守卫/头注/对照单全看不到 |
| 2 | I-A 前置量测：`lineage_onboarding.disciple_joins` 收徒事件所在关卡境界是否 ≥ `can_take_disciple_at: yiLiu` | opus | 15min | 5A 选 I-A 才做，不满足退 I-B/I-C |
| 3 | 上一份 NEXT #3 真人试玩 01_01 + 黑风岭（用户主导，Claude 只记录） | — | 用户定 | 需用户在场 |
| 4 | day_report 末两问：receipt 自引用口径封装 + gate 白名单自动读派单包 §0 | sonnet | 30min | 工具层，不改玩法 |

## 【硬约束沿用】

- 用户改口后旧授权作废，push/派单前先 ps 查在途 → memory `feedback_superseded_authorization_expires`
- 加守卫先量存量再定断言，几何量常分不出对错 → memory `feedback_measure_before_adding_gate_criterion`
- yaml 配置而不消费 = 头注 UNUSED 或砍字段，禁静默留死数据 → memory `feedback_yaml_config_unused_field`
- 破坏证红在 commit 后做、双向并精确还原 → memory `feedback_break_red_after_commit`
- 数字一律本会话实测，禁转抄 → memory `reference_anti_hallucination`
- 一律简体中文；commit 中文动宾 → memory `feedback_reply_in_simplified_chinese` / `feedback_wuxia_commit_message_chinese_gate`
- 后台全量 >8min 脱离会话跑，pkill 打 `flutter_tools.snapshot test` → memory `feedback_flutter_test_bg_kill_and_10min_cap`
- 不动主 checkout 4 个用户文件；真实存档只读 → memory `feedback_codex_worktree_dispatch_sandbox`

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测的快照；改动代码后**必须重测**，禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】（与置顶契约呼应）

读完上述清单后先提交一份报告，**不动代码**：

1. **防装读要求**：引用 PROGRESS.md 第 19 行「在途 worktree 台账」中「**同晚续**」段的**原文首句**，以及 session 记录「下一步建议」小节的**原文首条**。只复述本清单已有的信息不算完成。
2. 报告【开局动作】第 3、4 步结果：在途分支情况 + HEAD 校验判定（有效 / 作废）+ 主 checkout 是否已从 `c64b16593` 快进。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`（Step 0-4 为 canonical 流程，此处不复述，防拷贝漂移）。
