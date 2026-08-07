# 新会话开局清单

> 交接时间：2026-08-08 02:40 · 工作收口于 HEAD `053dc6dd` · 与 origin 同步、工作树干净、执行端 worktree 已全清
> 本清单自身的落盘 commit 排在 `053dc6dd` 之后，故实际 HEAD 会比它新 1-2 个纯文档 commit——**这不是漂移**，判据见【开局动作】第 4 步。

## 【本会话契约】（置顶，最高优先级）

- **模式：只读**
- **只读模式**：完成【开局动作】并提交【先报告】后，等用户指令才可动代码。
- **范围围栏**：只做用户选定的任务。过程中发现的其他问题分两类处置——
  - **非阻塞型**（不影响当前任务正确性）→ 记入根目录 `BACKLOG.md`，附 file:line 与复现步骤，**不动代码**；
  - **阻塞型**（当前任务建立在它之上，不修就是在错地基上盖楼）→ **停下报告**，不要记了账继续干。
- **拍板点**（设计取舍、多方案选型、观感判断）：只读模式下停下列选项等用户，**禁代拍**。
- **决策三级**：🟢 路径纠正/假阳性过滤/只读审计可自决 · 🟡 新增审计方向/范围增减 >30%/跨模块重构可调查不可合并 · 🔴 GDD 解释/数值规则/schema/玩家可见 UI/正式美术替换/删字段**必须停在 [BLOCKED] 等用户**。

项目：挂机武侠（`/Users/a10506/Desktop/Projects/挂机武侠`）

上一会话是 8h `/afk` 挂机，已批准 5 单（稀有度收口 / C2b 桃花岛美术闭环 / P4 审计脚本入仓 / P5 PROGRESS 瘦身 / P6 死链标注验证）**全部关闭并合入 main**，WIP 清零。**剩两件卡用户拍板**：扫描器修复合不合、C2b 四张图取舍。

## 【开局动作】

1. 读 PROGRESS.md 顶段「2026-08-08 夜批（8h 挂机）」条目
2. 读 `docs/sessions/2026-08-08_023200_夜批五单收口_main.md`
3. 读 `docs/dispatch/reports/2026-08-08_夜批收账早报.md`（含代拍决策清单 + 决策菜单，用户拍板前必读）
4. `git worktree list` + `git branch --list`：确认在途分支。**本轮无执行端在途任务**；若仍见 `afk-coordinator-0808`，其内容已全部 FF 进 main，可直接清。
5. **只 `git fetch`，不自动 rebase/autostash**：

   ```bash
   git status -sb | head -1
   git fetch origin
   git rev-list --left-right --count origin/main...HEAD
   git merge-base --is-ancestor 053dc6dd HEAD && echo ANCESTOR_OK
   ```

   - 工作树 dirty / 有分叉 / 有其他活跃写者 → **停下报告**，不自行更新；干净且可 FF 才 `git merge --ff-only origin/main`
   - `ANCESTOR_OK` 且与 origin 同步 → 快照有效（HEAD 比 `053dc6dd` 新 1-2 个纯文档 commit 属正常）
   - `--is-ancestor` 不成立 → **快照作废**：停下报告差异，重测基线，禁转抄下方数字
   - **并发检查**：`~/.claude/locks/` 下协调锁是否仍被他人持有。⚠ 该锁的 `heartbeat_at` **全程不更新**（v2 缺口，已入池 P9），不能用心跳新鲜度判活，须查 pid 存活 + git tip 是否推进
6. 选读 memory：`reference_anti_hallucination`（固定）+ `feedback_developer_dir_breaks_flutter_macos_build` / `feedback_bg_session_write_guard_subagent_dev` / `feedback_measure_from_config_not_render` / `feedback_no_effort_saving_in_recommendations`

## 【环境快照】（2026-08-08 主 checkout 实测，改动代码后必重测禁转抄）

- HEAD `053dc6dd`（本 session 22 commit，**已 push**，`origin/main...main` = `0 0` 反验同步）
- `flutter analyze --no-pub` → **No issues found**，4.2s｜主 checkout 实测
- 全量 `flutter test --no-pub` → **4910 pass / 0 fail**，exit 0，4m05s｜主 checkout 实测（HEAD `053dc6dd`）
  - **守恒核对**：= 上轮基线 4903 + 本次新增 7（`numbers_config_rarity_test.dart` 新文件 6 例 + `encounter_service_test` 的「奇遇加点跨档不改 rarity」红线 1 例），逐值吻合
- CI：对 `9c4d00d0` **conclusion=success**（headSha 与本地 rev-parse 逐字符一致）；`053dc6dd` 的 run 为纯文档变更，收尾时仍在跑
- **在途 PR / 分支：无执行端在途任务**。远端留有 4 个**已合并的备份分支**（`worktree-claude-rarity` / `codex/taohua-art-0807` / `pi/p6-link-label-0808` / `qoder/p4-audit-scripts-0808`），是上一会话主动推的备份，等用户决定是否清；其中 `pi/p6-link-label-0808` 含一个**故意未合并**的 commit（执行端越界改 PROGRESS.md，已弃用）
- 滚动池（`docs/dispatch/pool/README.md`）：P2 真机录屏 · P3 checklist reconcile · **P7 扫描器修复待拍板** · P8 扫描器真实 git fixture 测试 · P9 `/afk` v2 门禁缺口

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 拍 P7 扫描器修复合不合（推荐） | opus | 5-10min | **补丁已写好并全验证**（死链 940→909、工作树漂移 17→0、既有 10 类样例 10/10、总数守恒），提案在 `docs/dispatch/reports/2026-08-08_scanner_fp_fix_proposal.md`，用户点头即可合，是所有候选里性价比最高的 |
| 2 | C2b 四张桃花岛图取舍 | 用户 + Claude | 15-30min | 靠看图；证据 `~/Desktop/Projects/挂机武侠素材/桃花岛美术候选_20260807/_复检_*.png` 两张；🔴 级不可代拍 |
| 3 | P9 修 `/afk` v2 四处门禁缺口 | opus | 30-45min | preflight 漏报待拍板 / approved_tasks 子串误匹配 / doctor 不透 dispatch_template / 锁无心跳 |
| 4 | P8 扫描器引真实 git fixture 的测试 | qoderclicn 或 kimi | 60-90min | P7 的最大缺口：现有样例 mock 了 git 调用，**测不出**那两个 bug，加了也是假绿 |
| 5 | 资质 chip 真机观感 + BACKLOG 二#11 抓图修复 | 用户 + Claude | 30-60min | 上一会话 1280×720 smoke 两轮失败（`could not create image from rect`），资质 UI 无视觉证据 |

## 【硬约束沿用】

- `DEVELOPER_DIR` 只给 git 用，带进 `flutter build macos` 即报 xcodebuild 找不到 → memory `feedback_developer_dir_breaks_flutter_macos_build`
- 写守卫看会话 cwd 不看目标路径；worktree 隔离态下 Bash 拒复合命令 → memory `feedback_bg_session_write_guard_subagent_dev`
- 机制断言先做最小可逆隔离实验，不能安全实验则标假设 → memory `feedback_verify_mechanism_before_building_on_it`
- commit message 必须中文动宾（§11 + 合并 Gate ⓓ）→ memory `feedback_wuxia_commit_message_chinese_gate`
- 命令名/路径/API 从事实源取，`which` 查空≠未安装 → memory `feedback_identifier_from_source_not_guessed`
- 图像法结论前必过基准图自校验 → memory `feedback_measure_from_config_not_render`
- 推荐不得为省工作量缩水，出推荐前做「工作量无关」自检 → memory `feedback_no_effort_saving_in_recommendations`
- 破坏证红必须在 commit 之后做，还原后必重跑绿 → memory `feedback_break_red_after_commit`
- 写完 dart 必 `dart format`（CI 门禁）→ memory `feedback_wuxia_ci_format_gate_not_in_merge_gate`
- 派单包必须显式列全执行端禁区（`numbers.yaml`/`GDD.md`/`PROGRESS.md`/`strings.dart`/`pubspec.yaml`）→ memory `feedback_night_batch_dispatch_protocol`

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测快照；改动代码后**必须重测**，禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功；**退出码要看归属**（管道后的 `$?` 是末端命令的码；`gh run watch` 非零可能是 run 被后续 push 取代成 cancelled 而非红）。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】（与置顶契约呼应）

读完上述清单后先提交一份报告，**不动代码**：

1. **防装读要求**：须引用本清单里**不存在**的原文——PROGRESS.md 顶段条目的**原文标题行与日期**，以及 `docs/dispatch/reports/2026-08-08_夜批收账早报.md`「决策菜单」小节里**第 2 项的原文选项**。只复述本清单已有信息不算完成。
2. 报告【开局动作】第 4、5 步结果：在途分支情况 + HEAD 校验判定（有效 / 作废）。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`（Step 0-4 为 canonical 流程，此处不复述）。
