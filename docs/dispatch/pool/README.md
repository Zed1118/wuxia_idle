# 滚动单池(跨夜不清空,水位 ≥3;收账销已做补新拍)
| 单 | 端 | 状态 |
|---|---|---|
| ~~P1~~ 资源总览接 MaterialSourceSheet **2026-08-07 试跑批 kimi 消化合入(789d0f4d)** | kimi | 已销 |
| P2 真机录屏验收管线准备(CGEvent 打局+screencapture 录屏+关键帧;首用例塔 42,下批真机位) | Claude | 待发 |
| P3 checklist E 段 reconcile(BGM 8 轨已实装未勾等 stale 批注) | Claude/捎带 | 待发 |
| P4 Q2/A1 审计脚本入仓补齐可复现性(2026-08-07 夜抽验 3 条全中、两报告结论已确认成立并合入 main;**缺的只是脚本**——叶字段提取/消费扫描留在 `/tmp/q2/`、字段读写扫描留在 `/tmp/a1_audit/`,致 8/7/21 与 44/14 五个计数不可一键复跑。顺带按当前 main 重新定位 numbers.yaml 行号:报告写 `:1917` 现为 `:1954`) | qoderclicn 或 pi | 待发 |
| ~~P5~~ PROGRESS.md 瘦身 **2026-08-08 夜批 Claude 做完(110 行 79623B → 100 行 58468B,压缩 11 条旧条目)** | Claude | 已销 |
| ~~P6~~ 死链扫描器准确率标注验证 **2026-08-08 夜批 pi 交付并合入(precision 95.0%/recall 100%/一致率 88/90,查出两处系统性假阳)** | pi | 已销 |
| P7 死链扫描器假阳修复合并拍板(**代码已写好并验证,只差你点头**:修复提案+完整补丁在 `docs/dispatch/reports/2026-08-08_scanner_fp_fix_proposal.md`;实测死链 940→909、工作树漂移 17→0、既有 10 类样例仍 10/10。🟡 级故未合) | 用户拍板 | 待拍 |
| P8 死链扫描器引真实 git fixture 的测试(P7 的最大缺口:现有 10 类样例 mock 了 `git_ls_files`/`git_check_ignore`,而 P6 查出的两个 bug 恰恰活在**未被 mock 的真实 git 行为**里,沿用同体例加样例测不出、加了也是假绿) | qoderclicn 或 kimi | 待发 |
| P9 `/afk` 工作流 v2 三处门禁缺口(2026-08-08 首跑实测:① preflight `blocked_decisions` 只认分支 tip 的 `[BLOCKED]` 前缀,卡用户拍板但没打标记的分支被漏报为「待拍板=无」;② `approved_tasks` 用池文本子串匹配,在途分支收口类工作无法表达,硬塞短 ID 会被 `README` 之类误匹配;③ `doctor --json` 不透出 `dispatch_template` 字段,skill 文档却说「按 doctor --json 给出的 dispatch_template 发单」) | Claude | 待发 |
