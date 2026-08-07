# 新会话开局清单

> 交接时间:2026-08-08 00:12 · 工作收口于 HEAD `90520869` · 与 origin 同步,工作树干净,worktree 已全清只剩 main
> 本清单自身的落盘 commit 排在 `90520869` 之后,故实际 HEAD 会比它新 1 个纯文档 commit——**这不是漂移**,判据见【开局动作】第 4 步。

## 【本会话契约】(置顶,最高优先级)

- **模式:只读**
- **只读模式**:完成【开局动作】并提交【先报告】后,等用户指令才可动代码。
- **范围围栏**:只做用户选定的任务。过程中发现的其他问题分两类处置——
  - **非阻塞型**(不影响当前任务正确性)→ 记入根目录 `BACKLOG.md`,附 file:line 与复现步骤,**不动代码**;
  - **阻塞型**(当前任务建立在它之上,不修就是在错地基上盖楼)→ **停下报告**,不要记了账继续干。
- **拍板点**(设计取舍、多方案选型、观感判断):只读模式下停下列选项等用户,**禁代拍**。
- **决策三级**(2026-08-07 外评后立):🟢 路径纠正/假阳性过滤/只读审计可自决 · 🟡 新增审计方向/范围增减 >30%/跨模块重构可调查不可合并 · 🔴 GDD 解释/数值规则/schema/玩家可见 UI/正式美术替换/删字段**必须停在 [BLOCKED] 等用户**。

项目:挂机武侠(`/Users/a10506/Desktop/Projects/挂机武侠`)

上一会话完成两批 Gate 全过的合并(K2 假绿抽查 + L1-D 扫描器根因修)、四轮外评驱动的 `/afk`+`/handoff` v2 重写、Q2/A1 审计报告抽验后合入。main 已 push 且 CI 绿。剩余任务里**只有一项不需要用户拍板**。

## 【开局动作】

1. 读 PROGRESS.md 顶段「2026-08-07 夜 收账批」条目(注:该条**只覆盖前半夜**,后半段缺口见【环境快照】)
2. 读 `docs/sessions/2026-08-08_001237_工作流v2与收账_main.md`
3. `git worktree list` + `git branch --list`:确认在途分支。**本轮有 2 个未合分支续传**(见【环境快照】),PROGRESS.md 只反映 main。
4. **只 `git fetch`,不自动 rebase/autostash**:

   ```bash
   git status -sb | head -1
   git fetch origin
   git rev-list --left-right --count origin/main...HEAD
   git merge-base --is-ancestor 90520869 HEAD && echo ANCESTOR_OK
   ```

   - 工作树 dirty / 有分叉 / 有其他活跃写者 → **停下报告**,不自行更新;干净且可 FF 才 `git merge --ff-only origin/main`
   - `ANCESTOR_OK` 且与 origin 同步 → 快照有效(HEAD 比 `90520869` 新 1 个纯文档 commit 属正常)
   - `--is-ancestor` 不成立 → **快照作废**:停下报告差异,重测基线,禁转抄下方数字
   - **并发检查**:`~/.claude/locks/` 下协调锁是否仍被他人持有且心跳新鲜;有则先确认对方已停止
5. 选读 memory:`reference_anti_hallucination`(固定)+ `feedback_verify_mechanism_before_building_on_it` / `feedback_wuxia_commit_message_chinese_gate` / `feedback_identifier_from_source_not_guessed` / `feedback_bg_worktree_baseref_fresh_diverge`

## 【环境快照】(2026-08-08 主 checkout 实测,改动代码后必重测禁转抄)

- HEAD `90520869`(本 session 26 commit,**已 push**,远端 tip 逐字符反验一致)
- `flutter analyze` → **No issues found**,5.6s|主 checkout 实测
- 全量 `flutter test --no-pub` → **4903 pass / 0 fail**,exit 0|主 checkout 实测(跑在 `cdfe647f` 前;其后 3 个 commit 均纯文档)
  - 守恒:= 上轮基线 4886 + K2 新增 17。CI 对最终 SHA `90520869` **conclusion=success**(headSha 与本地/远端三方一致)
- **在途分支(2 个,均卡用户决策非技术阻塞)**:

  | 分支 | 内容 | 状态 |
  |---|---|---|
  | `worktree-claude-rarity` | 稀有度派生实装 3 commit(含 `Character.rarity` late 无默认致 65 处构造点崩的真 bug 修复) | analyze 0 / 全量 4892·0 / 破坏证红全过,**卡产品拍板三问** |
  | `codex/taohua-art-0807` | C2 桃花岛美术 23/25 已出仓 `~/Desktop/Projects/挂机武侠素材/桃花岛美术候选_20260807/` | **验收未闭环**:清单全「待选」无逐图判定 / C 类 2 张缺自测 / D 类 2 张未产出 |

- **滚动池 5 单待发**(`docs/dispatch/pool/README.md`):P2 真机录屏管线 · P3 checklist reconcile · P4 审计脚本入仓 · P5 PROGRESS 瘦身 · P6 死链扫描器标注验证
- **工作流 v2 已落地但未跑过完整闭环**:`~/.claude/skills/afk/scripts/`(preflight 9 项门禁 + doctor + 19 条测试)、`~/.claude/automation-playbook/executors.json`(执行端唯一事实源)。首次真用须按**首跑**对待
- **PROGRESS 后半段缺口**:审计合入 / v2 脚本层 / `~/.claude` 纳管未进顶段

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 补 PROGRESS 后半段 + 派 P6 标注验证(推荐) | opus | 10min + 60min(派后异步) | **唯一不需用户拍板即可推进的**;前者消盘面缺口,后者给死链底账建 precision/recall |
| 2 | 稀有度三问拍板后收口 `worktree-claude-rarity` | opus | 20-40min | 🔴 红级需用户先拍;含真 bug 修复,不定则一直悬着 |
| 3 | 真机目检批:C2 美术 + 题字 20 张 + 第八阶段协同 | 用户 + Claude | 30-60min | 三项都靠看图,攒一次关三笔账;我可先整理证据目录配判定表 |
| 4 | P4 审计脚本入仓补齐可复现性 | qoderclicn 或 pi | 60-90min | 结论已验成立,缺的只是脚本;顺带订正 numbers.yaml 行号 drift |
| 5 | P5 PROGRESS 瘦身 | opus | 20-30min | 110 行 / 79KB / 最长单行 5043 字符,已是每次开局固定摩擦 |

## 【硬约束沿用】

- 机制断言先做最小可逆隔离实验,不能安全实验则标假设+写回退 → memory `feedback_verify_mechanism_before_building_on_it`
- commit message 必须中文动宾(§11 + 合并 Gate ⓓ);历史英文前缀已豁免不要去修 → memory `feedback_wuxia_commit_message_chinese_gate`
- 命令名/路径/API 从事实源取,`which` 查空≠未安装 → memory `feedback_identifier_from_source_not_guessed`
- 新建 worktree 默认基于 origin/main,建后必 `git reset --hard main` 对齐 → memory `feedback_bg_worktree_baseref_fresh_diverge`
- 否定式 grep 不是存在性证明,先搜中文/领域词 → memory `feedback_negative_grep_not_proof_of_absence`
- 扫描器验收用固定样例不用总数区间;「采而不用的字段」=漏实现强信号 → memory `feedback_scanner_acceptance_needs_fixture_cases`
- 破坏证红必须在 commit 之后做,还原后必重跑绿 → memory `feedback_break_red_after_commit`
- 推荐不得为省工作量缩水,出推荐前做「工作量无关」自检 → memory `feedback_no_effort_saving_in_recommendations`
- 写完 dart 必 `dart format`(CI 门禁)→ memory `feedback_wuxia_ci_format_gate_not_in_merge_gate`

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测快照;改动代码后**必须重测**,禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出,launch ≠ 成功;**退出码要看归属**(管道后的 `$?` 是末端命令的码)。
- 引用代码现 grep/codegraph 查带 file:line;不确定写「不知道」,不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】(与置顶契约呼应)

读完上述清单后先提交一份报告,**不动代码**:

1. **防装读要求**:须引用本清单里**不存在**的原文——PROGRESS.md 顶段条目的**原文标题行与日期**,以及 `docs/sessions/2026-08-08_001237_工作流v2与收账_main.md`「重要决策」小节的**原文首条**。只复述本清单已有信息不算完成。
2. 报告【开局动作】第 3、4 步结果:在途分支情况 + HEAD 校验判定(有效 / 作废)。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`(Step 0-4 为 canonical 流程,此处不复述)。
