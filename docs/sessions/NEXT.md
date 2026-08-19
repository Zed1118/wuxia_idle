# 新会话开局清单

> 交接时间：2026-08-19 晨 · 工作收口于 HEAD `1fceb0ad` · 与 origin/main 同步、工作树干净
> 本清单自身的落盘 commit 排在 `1fceb0ad` 之后，故实际 HEAD 会比它新 1 个纯文档 commit——**这不是漂移**，判据见【开局动作】第 4 步。

## 【本会话契约】（置顶，最高优先级）

- **范围围栏**：只做用户选定的任务。过程中发现的其他问题分两类处置——
  - **非阻塞型**（不影响当前任务正确性）→ 记入根目录 `BACKLOG.md`，附 file:line 与复现步骤，**不动代码**；
  - **阻塞型**（当前任务建立在它之上，不修就是在错地基上盖楼）→ **停下报告**，不要记了账继续干。
- **拍板点**（设计取舍、多方案选型、观感判断）：停下列选项等用户，**禁代拍**。
- **决策三级**：🟢 路径纠正/假阳过滤/只读审计可自决 · 🟡 新增审计方向/范围增减 >30%/跨模块重构可调查不可合并 · 🔴 GDD 解释/数值规则/schema/玩家可见 UI/删字段**必须停在 [BLOCKED] 等用户**。

项目：挂机武侠（`/Users/a10506/Desktop/Projects/挂机武侠`）

上一会话是 2026-08-18 夜批（RP0 队列 N1/N2/N3 全收账），连同 08-18 日批（0C 工程嵌入验收等）一起把工程面清到干净态：旧 3v3 拆除范围首次定量、死链残余 71→65 逐条实证接受、长寿文档漂移成清单。**当前最大瓶颈仍是决策积压（§7.4 ADR 为首），不是工程执行**。

## 【开局动作】

1. 读 PROGRESS.md 顶段三条夜批收账条目（N3 `86c9004f` / N2 `3f4228bf` / N1 `92ebedac`）
2. 读三份夜批报告：`docs/audit/legacy_3v3_removal_scope_2026-08-18.md`（§7.4 ADR 事实底座）/ `docs/audit/doclink_residue_disposition_2026-08-18.md` / `docs/audit/living_doc_drift_2026-08-18.md`
3. `git worktree list` + `git branch --list`：预期只见主 checkout + 五条 0818 已合分支（`audit/legacy-3v3-removal-scope` / `audit/living-doc-drift` / `fix/doclink-residue` / `feat/phase0c-engineering-embed-verify` / 本清单分支如未删）。已合分支可随手删。
4. **只 `git fetch`,不自动 rebase/autostash**：

   ```bash
   git status -sb | head -1
   git fetch origin
   git rev-list --left-right --count origin/main...HEAD
   git merge-base --is-ancestor 1fceb0ad HEAD && echo ANCESTOR_OK
   ```

   - 工作树 dirty / 有分叉 / 有其他活跃写者 → **停下报告**，不自行更新；干净且可 FF 才 `git merge --ff-only origin/main`
   - `ANCESTOR_OK` 且 ahead ≤1（那 1 个是本清单自身的 commit）→ 快照有效
   - `--is-ancestor` 不成立 → **快照作废**：停下报告差异，重测基线，禁转抄下方数字
5. 选读 memory：`reference_anti_hallucination`（固定）+ `feedback_gh_run_watch_exit_code_masks_cancelled` / `feedback_living_doc_state_drift` / `feedback_negative_grep_not_proof_of_absence`

## 【环境快照】（上一会话实测；本会话改动代码后必须重测，禁转抄）

- HEAD `1fceb0ad`（夜批收账 + RP0 勾选，**已 push**；与 origin/main 同步）
- 全量 `flutter test` → **5167 pass / 0 fail**（CI run `32149125730` + `32151519112` 显式读 conclusion=success 双证；夜批三批均纯 md/dart 零改动，计数守恒）
- 死链扫描器：dead **65** 残余 = B 23 + D 42，逐条实证接受（台账含三条再开条件：legal 线/0A 资产落地自愈/归档类扩容须拍板）
- **战斗终态已在案**（2026-08-18 用户拍板）：Phase 0A 单角色 ARPG 替换旧 3v3，不做两模式并存。但 GDD v1.25 / CLAUDE v1.42 的战斗形态描述**仍是旧 3v3 口径**（drift 审计 D1/D2，🔴 须与 §7.4 ADR 同批升版，禁单独改）
- 「v2 方案」正文**未入库**（D4）：08-18 三文档引用其 §7.4/§11/§15.2，本地库/桌面资料/会话缓存均穷尽未得，来源待用户指认（codex 派单会话产物）
- 桌面资料：`/Users/a10506/Desktop/挂机武侠_桌面资料/`（说明文档 = 0A 下一步执行清单 + 试玩招募文案；当前验收包 = 0A 正式验收包 `965e948e` + 0B 连续地图纵切 `06ab4162`）

## 【下波候选】

| # | 任务 | 性质 | 备注 |
|---|------|------|------|
| 1 | **§7.4 ADR 拍板（首要）** | 用户拍板 | 路线 A 双轨/B 分批改造/C 重做替换 + 4 子项（headless 内核替代/65 路由与证据归档/共享层落点/过渡期空窗）。事实底座 = N1 报告。拍完解锁 GDD/CLAUDE 升版批 |
| 2 | 6 人主观 Gate + 试玩局 | 用户排期 | 合并一#19/#4/#5/#6 同一局；`当前验收包/挂机武侠_Phase0A_正式验收包_965e948e/` 已备（主持试玩.command/键位卡/问卷模板） |
| 3 | Windows 实机 Gate | 用户操作 | 0C 裁决后置项，进正式生产前必须执行 |
| 4 | D4 v2 方案归档 | 用户指认来源 | 指认后入库 + 三份引用文档补路径 |
| 5 | 0B `MANUAL_RIG_PENDING` | 33-55 人日人工美术 | 非会话可执行项，只跟进度 |

## 【硬约束沿用】

> **主从原则**：canonical 正文只住 memory，此处每条只留一行摘要 + memory 指针。

- 裸 `date` 可能返回 UTC,判时刻须 `%Z` + `date -u` 交叉验 → memory `feedback_date_may_return_utc_verify_timezone`
- `gh run watch --exit-status` 返 0 ≠ CI 通过(cancelled 也返 0),必显式读 conclusion → memory `feedback_gh_run_watch_exit_code_masks_cancelled`
- fresh worktree 预热必含 `build_runner` + 拷 `libisar.dylib`,否则级联红 → memory `feedback_subagent_driven_fresh_worktree_env_prep`
- 破坏证红必须在 commit 之后做 → memory `feedback_break_red_after_commit`
- 测试不得绕开生产路径,自检「破坏那行,这条断言必然红吗」 → memory `feedback_test_bypasses_production_path`
- commit message 必须中文动宾(§11 + 合并 Gate ⓓ) → memory `feedback_wuxia_commit_message_chinese_gate`
- 写完 dart 必 `dart format`(CI 门禁,不在 §8.2 Gate 清单里易漏) → memory `feedback_wuxia_ci_format_gate_not_in_merge_gate`
- 推荐不得为省工作量缩水,出推荐前做「工作量无关」自检 → memory `feedback_no_effort_saving_in_recommendations`
- 否定式 grep 不是存在性证明 → memory `feedback_negative_grep_not_proof_of_absence`
- 长寿文档的行号/路径/「已实装」状态会 drift,引用前重新定位 → memory `feedback_living_doc_state_drift`
- PROGRESS ≤100 行纪律:当前 99 行,下一条收账前先看是否要先归档旧条

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测快照；改动代码后**必须重测**，禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出，launch ≠ 成功；**退出码要看归属**——管道后 `$?` 是末端命令的码,`gh run watch` 的 0 也可能是 cancelled。
- **空 grep 结果不是不存在**：先怀疑自己的正则/路径写法，换写法或纯字符串交叉验证一遍。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」，不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【收尾】

会话结束前跑 `/handoff`（Step 0-4 为 canonical 流程，此处不复述）。
