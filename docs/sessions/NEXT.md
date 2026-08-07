# 新会话开局清单

> 交接时间:2026-08-07 19:45 · 工作收口于 HEAD `4fa7c854` · 与 origin 同步,工作树干净,worktree 已全清只剩 main
> 本清单自身的落盘 commit 排在 `4fa7c854` 之后,故实际 HEAD 会比它新 1-2 个纯文档 commit——**这不是漂移**,判据见【开局动作】第 4 步。

## 【本会话契约】(置顶,最高优先级)

- **模式:只读**
- **只读模式**:完成【开局动作】并提交【先报告】后,等用户指令才可动代码。
- **范围围栏**:只做用户选定的任务。过程中发现的其他问题分两类处置——
  - **非阻塞型**(不影响当前任务正确性)→ 记入 `BACKLOG.md`,附 file:line 与复现步骤,**不动代码**;
  - **阻塞型**(当前任务建立在它之上,不修就是在错地基上盖楼)→ **停下报告**,不要记了账继续干。
- **拍板点**(设计取舍、多方案选型、观感判断):只读模式下停下列选项等用户,**禁代拍**。
  > ⚠ 上一会话在此失守:用户全程在线却连续代拍七项,含产品语义与 UI 决策,外评「用户决策治理」仅 35/100。本轮不得重演。
- **在制品上限**:若本会话转多端派发,并发上限 = 2 执行 + 1 评审;上一项未验收不滚动续派。指标看「几个任务已独立复核并合并」,不看「几个端在跑」。→ memory `feedback_wip_limit_over_executor_utilization`

项目:挂机武侠(`/Users/a10506/Desktop/Projects/挂机武侠`)

上一会话跑了五端并发挂机批,中途被用户叫停复盘(外评 67/100)。成果有价值但**本批未闭环**:三份审计交付未复核、一份工具有实锤缺陷、稀有度实装卡在产品拍板点。本会话首要任务是关掉这些敞口,不是开新战线。

## 【开局动作】

1. 读 PROGRESS.md 顶段「2026-08-07 挂机批(五端并发)+ 中止复盘」
2. 读 `docs/sessions/2026-08-07_1930_挂机批复盘.md`
3. `git worktree list` + `git branch --list` :确认在途分支。**本轮有 6 个未合分支续传**(见【环境快照】),PROGRESS.md 只反映 main,别在不知情下重做。
4. `git pull --rebase --autostash`,然后校验本清单是否仍有效:

   ```bash
   git merge-base --is-ancestor 4fa7c854 HEAD && echo ANCESTOR_OK
   git status -sb | head -1
   ```

   - `ANCESTOR_OK` **且**与 origin 同步 → 快照有效,继续。(HEAD 比 `4fa7c854` 新几个纯文档 commit 属正常,**不是**漂移)
   - `--is-ancestor` 不成立 → **快照作废**:停下报告差异,重测 analyze/test 基线,禁转抄下方数字。
5. 选读 memory:`reference_anti_hallucination`(固定)+ `feedback_negative_grep_not_proof_of_absence` / `feedback_wip_limit_over_executor_utilization` / `feedback_scanner_acceptance_needs_fixture_cases` / `feedback_no_effort_saving_in_recommendations` / `feedback_break_red_after_commit`

## 【环境快照】(2026-08-07 主 checkout 实测,改动代码后必重测禁转抄)

- HEAD `4fa7c854`(本次 session 26 commit / 4 merge,**已 push**)
- `flutter analyze` → **No issues found**,4.8s|主 checkout 实测
- 全量 `flutter test --no-pub` → **4886 pass / 0 fail**,exit 0|主 checkout 实测
  - **守恒核对**:= 上轮基线 4886 + main 侧新增 **0**。本会话新增的 6 个测(`test/data/numbers_config_rarity_test.dart`)在**未合并**的 `worktree-claude-rarity` 分支上,该分支自测 4892/0(=4886+6),逐值吻合。
- CI:run 31169857460 对**终态 SHA `4fa7c854`** 已 success(非旧 SHA)
- **在途分支(6 个,worktree 目录已删,`git worktree add .claude/worktrees/<n> <branch>` 可重建)**:

  | 分支 | 内容 | 状态 |
  |---|---|---|
  | `worktree-claude-rarity` | 稀有度派生实装 3 commit | analyze 0 / 全量 4892·0 / 破坏证红全过,**卡产品拍板** |
  | `kimi/night-goals-0807` | 假绿抽查 12 commit / 12 测试文件,6/7 目标 | WIP 未打 [READY],§8.3 不可合 |
  | `qoder/config-bypass-audit` | Q2 报告(背离 8 / 部分 7 / 休眠 21) | **数字未复核,脚本在 /tmp 未入仓** |
  | `pi/dead-field-audit` | A1 报告(44 只写不读 + 14 仅 debug) | 同上;且 `Character.rarity` 结论已被 rarity 分支**基线漂移** |
  | `cb/doc-link-scan-tool` | L1-D 死链扫描器 | **缺陷实锤不可合**,详下 |
  | `codex/taohua-art-0807` | 仅自测报告(图不在 git) | 图已出仓,见下 |

- **C2 美术已持久化出仓**:`~/Desktop/Projects/挂机武侠素材/桃花岛美术候选_20260807/`——23 张成品(A 图标 14×256²RGBA / B 卡背景 7×1408×864 / C 入口图 2×1456×816)+ 4 张中间件 + `清单_MANIFEST.md`(含 md5 与待选/已选/淘汰状态列)+ `contact_sheet.png`;**D 类背景候选 2 张未做**
- **L1-D 缺陷定位**:`tools/doc_link_scan.py` md 链接分支存 `{"target": path, "raw": "[text](path)"}`,主流程 `:477` 拿 `ref["raw"]` 去 `clean_target` → 带 `[]` 被判模板占位跳过 → **所有 md 链接静默漏扫**,采集的 `target` 字段根本没用到

## 【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 拍稀有度三问并收口 `worktree-claude-rarity`(推荐) | opus | 20-40min | 唯一被完整验证过的实装分支,且含真 bug 修复(`Character.rarity` `late` 无默认致 65 处构造点抛 LateInitializationError,含生产 `visual_route_host.dart:3182`);三问=出生档位是否固定 / 静态叙事角色是否适用概率分布 / 哪些界面展示 |
| 2 | 修 L1-D raw/target 根因 + 补按引用类型固定样例测试 | sonnet | 40-60min | 缺陷已定位到行,修完须重跑并比对分类计数 |
| 3 | Q2/A1 脚本化后在当前 main 重验 | opus | 60-90min | 8 / 44 两个数字当前不可复现;A1 存基线漂移须重扫 |
| 4 | kimi 分支逐目标标完成态 + targeted 后评合并 | opus | 40-60min | 12 测试文件,须逐文件确认 All tests passed 出现次数 |
| 5 | C2 补 D 类 2 张背景候选,或缩单收口 | codex | 20min | 需先目检 contact sheet 定 A 类图标 21px 可读性 |

## 【硬约束沿用】

- 否定式 grep 不是存在性证明;先搜中文/领域词找代码真实命名 → memory `feedback_negative_grep_not_proof_of_absence`
- 在制品上限优先于执行端利用率;READY≠完成需查基线漂移 → memory `feedback_wip_limit_over_executor_utilization`
- 扫描器验收用固定样例不用总数区间;「采集了却不用的字段」=漏实现强信号 → memory `feedback_scanner_acceptance_needs_fixture_cases`
- 推荐不得为省工作量缩水;出推荐前做「工作量无关」自检 → memory `feedback_no_effort_saving_in_recommendations`
- 破坏证红必须在 commit 之后做,还原后必重跑绿 → memory `feedback_break_red_after_commit`
- 数值/schema/红线(numbers.yaml/GDD/strings)执行端禁区,Claude 收口 → memory `feedback_night_batch_dispatch_protocol`
- 写完 dart 必 `dart format`(CI 门禁);Gate 复核加 ⓔ format → memory `feedback_wuxia_ci_format_gate_not_in_merge_gate`
- 验分支改动用三点 `main...branch`;`--name-only` 转义中文名须 `-c core.quotepath=false` → memory `feedback_chinese_path_shell_pitfalls`

## 【防幻觉守则】

- 本清单【环境快照】的数字是上一会话实测的快照;改动代码后**必须重测**,禁转抄。
- 报「完成/已修复/0 引用/全绿」前必跑验证并贴输出,launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line;不确定写「不知道」,不凭记忆硬答。
- 完整守则见 memory `reference_anti_hallucination`。

## 【先报告】(与置顶契约呼应)

读完上述清单后先提交一份报告,**不动代码**:

1. **防装读要求**:须引用本清单里**不存在**的原文——PROGRESS.md 顶段条目的**原文标题行与日期**,以及 `docs/sessions/2026-08-07_1930_挂机批复盘.md`「下一步建议」小节的**原文首条**。只复述本清单已有信息不算完成。
2. 报告【开局动作】第 3、4 步结果:在途分支情况 + HEAD 校验判定(有效 / 作废)。
3. 等指令。

## 【收尾】

会话结束前跑 `/handoff`(Step 0-4 为 canonical 流程,此处不复述)。
