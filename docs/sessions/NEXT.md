# 新会话开局清单

> 交接时间：2026-08-08 12:59 · 工作收口于 HEAD `410066b0` · 与 origin 同步、工作树干净、worktree 与本地分支已全清
> 本清单自身的落盘 commit 排在 `410066b0` 之后，故实际 HEAD 会比它新 1 个纯文档 commit——**这不是漂移**，判据见【开局动作】第 4 步。
> ⚠ 该 commit **默认未 push**（`/handoff` 未带 `--push`）。若 `git status -sb` 显示 `ahead 1`，那就是它，不是异常。

## 【本会话契约】（置顶，最高优先级）

- **模式：只读**
- **只读模式**：完成【开局动作】并提交【先报告】后，等用户指令才可动代码。
- **范围围栏**：只做用户选定的任务。过程中发现的其他问题分两类处置——
  - **非阻塞型**（不影响当前任务正确性）→ 记入根目录 `BACKLOG.md`，附 file:line 与复现步骤，**不动代码**；
  - **阻塞型**（当前任务建立在它之上，不修就是在错地基上盖楼）→ **停下报告**，不要记了账继续干。
- **拍板点**（设计取舍、多方案选型、观感判断）：只读模式下停下列选项等用户，**禁代拍**。
- **决策三级**：🟢 路径纠正/假阳性过滤/只读审计可自决 · 🟡 新增审计方向/范围增减 >30%/跨模块重构可调查不可合并 · 🔴 GDD 解释/数值规则/schema/玩家可见 UI/正式美术替换/删字段**必须停在 [BLOCKED] 等用户**。

项目：挂机武侠（`/Users/a10506/Desktop/Projects/挂机武侠`）

08-08 夜批 5 单已全部关闭合入；同日上午又清了一轮夜批遗留（含**推翻自己昨夜的一个误诊**）。
当前**无在途实装**，**6 项等用户拍板 / 5 项可直接做**。

## 【开局动作】

1. 读 PROGRESS.md 顶段「2026-08-08 夜批（8h 挂机）」条目（**注意末尾的【同日上午续:清夜批遗留】段是最新状态**）
2. 读 `docs/sessions/2026-08-08_125900_清夜批遗留_main.md`
3. 读 `docs/dispatch/reports/2026-08-08_夜批收账早报.md`（决策菜单 5 项，用户拍板前必读）
4. `git worktree list` + `git branch --list`：**预期只有 main**。若见其他分支属异常，停下报告。
5. **只 `git fetch`，不自动 rebase/autostash**：

   ```bash
   git status -sb | head -1
   git fetch origin
   git rev-list --left-right --count origin/main...HEAD
   git merge-base --is-ancestor 410066b0 HEAD && echo ANCESTOR_OK
   ```

   - 工作树 dirty / 有分叉 / 有其他活跃写者 → **停下报告**，不自行更新；干净且可 FF 才 `git merge --ff-only origin/main`
   - `ANCESTOR_OK` 且 `ahead ≤1`（那 1 个是本清单自身的 commit）→ 快照有效
   - `--is-ancestor` 不成立 → **快照作废**：停下报告差异，重测基线，禁转抄下方数字
   - **并发检查**：`~/.claude/locks/` 下协调锁。⚠ 该锁 `heartbeat_at` **全程不更新**（v2 缺口，池内 P9），**不能用心跳新鲜度判活**，须查 pid 存活 + git tip 是否推进
6. 选读 memory：`reference_anti_hallucination`（固定）+ `feedback_developer_dir_breaks_flutter_macos_build` / `feedback_probe_must_prove_its_load` / `feedback_measure_from_config_not_render` / `feedback_no_effort_saving_in_recommendations`

## 【环境快照】（实测；改动代码后必重测，禁转抄）

- HEAD `410066b0`（夜批 22 commit + 上午清遗留 6 commit，**已 push**，`origin/main...main` = `0 0` 反验同步）
- `flutter analyze --no-pub` → **No issues found**，4.3s｜2026-08-08 12:5x 主 checkout 实测
- 全量 `flutter test --no-pub` → **4910 pass / 0 fail**，exit 0，4m05s｜2026-08-08 02:4x 主 checkout 实测（跑在 `053dc6dd`）
  - **未重跑的依据（本会话实测）**：`git diff --name-only 053dc6dd..HEAD -- '*.dart'` = **0 文件**，其后全是 BACKLOG/PROGRESS/docs 改动。守 memory `feedback_test_cadence_no_blind_full`
  - **守恒核对**：4910 = 上轮基线 4903 + 新增 7（`numbers_config_rarity_test.dart` 新文件 6 例 + `encounter_service_test` 出生锁死红线 1 例）
- CI：对 `44ee808a` **conclusion=success**（headSha 与本地 rev-parse 逐字符一致）；其后仅文档 commit
- **在途 PR / 分支：本地无**。远端留 4 个**已合并的备份分支**（`worktree-claude-rarity` / `codex/taohua-art-0807` / `pi/p6-link-label-0808` / `qoder/p4-audit-scripts-0808`）——实测 2 个 `main..origin/<b>`=0，另 2 个是 rebase/cherry-pick **前**的旧 SHA（内容在 main，SHA 不同）。**等用户拍是否清，已续传 1 轮**
- 滚动池（`docs/dispatch/pool/README.md`）：P2 真机录屏 · P3 checklist reconcile · **P7 扫描器修复待拍板** · P8 真实 git fixture 测试 · P9 v2 门禁缺口（四缺口中 `dispatch_template` 一条已于 08-08 上午修）

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | **P8 扫描器补真实 git fixture 测试（推荐）** | opus | 60-90min | 已确证 `tools/test_doc_link_scan.py:34-39` mock 掉 `git_ls_files`/`git_check_ignore` 且无 `git init`；**它决定 P7 补丁能不能放心合**。Bug B 可在 mock 层测、Bug A2 须建真 git 仓 |
| 2 | 拍 P7 扫描器假阳修复合不合 | 用户 | 5-10min | 补丁已全验证（死链 940→909、工作树漂移 17→0、10 类样例仍全过、总数守恒），提案含可 `git apply` 补丁 |
| 3 | 拍资质三连（BACKLOG 一#15 老存档迁移 / 一#16 chip 拼法分叉 / 视觉档位化） | 用户 + opus | 20min 拍 + 30-60min 实装 | 同一决策面，攒一起效率高；真机图已有可直接看 |
| 4 | C2b 桃花岛 4 张图取舍 | 用户 | 15-30min | 复检图 `~/Desktop/Projects/挂机武侠素材/桃花岛美术候选_20260807/_复检_*.png` |
| 5 | P9 v2 门禁余三缺口 | opus | 30-45min | preflight 漏报待拍板 / approved_tasks 子串误匹配 / 锁无心跳 |
| 6 | 追 capture 根因（BACKLOG 二#11） | opus | 不定 | 只剩「锁屏」一条假设，**需夜间无人时段才能复现**，白天验不了 |

## 【硬约束沿用】

- `DEVELOPER_DIR` 只给 git 用，带进 `flutter build macos` 即报 xcodebuild 找不到 → memory `feedback_developer_dir_breaks_flutter_macos_build`
- 探针/修复必须自证有负载，对照组要跑**未修版** → memory `feedback_probe_must_prove_its_load`
- 图像法结论前必过基准图自校验 → memory `feedback_measure_from_config_not_render`
- 机制断言先做最小可逆隔离实验 → memory `feedback_verify_mechanism_before_building_on_it`
- commit message 必须中文动宾（§11 + 合并 Gate ⓓ）→ memory `feedback_wuxia_commit_message_chinese_gate`
- 写守卫看会话 cwd 不看目标路径；worktree 隔离态 Bash 拒复合命令 → memory `feedback_bg_session_write_guard_subagent_dev`
- 派单包必须显式列全执行端禁区 → memory `feedback_night_batch_dispatch_protocol`（08-08 已升级进 `/afk` skill Phase 2）
- 推荐不得为省工作量缩水，出推荐前做「工作量无关」自检 → memory `feedback_no_effort_saving_in_recommendations`
- 破坏证红必须在 commit 之后做 → memory `feedback_break_red_after_commit`
- 写完 dart 必 `dart format`（CI 门禁）→ memory `feedback_wuxia_ci_format_gate_not_in_merge_gate`

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测快照；改动代码后**必须重测**，禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功；**退出码要看归属**（管道后 `$?` 是末端命令的码；`gh run watch` 非零可能是 run 被后续 push 取代成 cancelled 而非红）。
- **「登记进 BACKLOG」不等于「已处置」**——08-08 上午实录：昨夜把猜的根因写进 BACKLOG 就走，次日一查日志即塌。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】（与置顶契约呼应）

读完上述清单后先提交一份报告，**不动代码**：

1. **防装读要求**：须引用本清单里**不存在**的原文——PROGRESS.md 顶段条目的**原文标题行与日期**，以及 `docs/sessions/2026-08-08_125900_清夜批遗留_main.md`「重要决策」小节的**原文首条**。只复述本清单已有信息不算完成。
2. 报告【开局动作】第 4、5 步结果：在途分支情况 + HEAD 校验判定（有效 / 作废）。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`（Step 0-4 为 canonical 流程，此处不复述）。
