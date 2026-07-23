# 新会话开局清单（交接时间 2026-07-23 20:19 · HEAD 5860135d）

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

Ch15「关山一程」spec 已八项全按推荐**拍板冻结**（绝顶段收官章·main `aae51d7d` 起草 + `5860135d` 冻结），同会话 webp 清账 PR #66 MERGED（Ch14 11 图省 16.1M）；HEAD 5860135d = origin/main、树净、worktree/分支全清。新会话任务 = **Ch15 实装批**。

开局动作：
1. 读 PROGRESS.md 顶段（Ch15 spec 条 + webp 清账条）
2. 读 docs/sessions/2026-07-23_2019_Ch15spec拍板.md
3. 读 **docs/spec/2026-07-23-ch15-guanshan-yicheng-design.md 全文**（实装唯一依据·已冻结）
4. git pull --rebase --autostash
5. 选读 memory：reference_anti_hallucination（固定）+ feedback_wuxia_add_mainline_chapter_reconcile（~26 站点清单·必读）+ feedback_wuxia_release_cap_raise_reconcile（cap 33→35 四站点）+ feedback_break_red_after_commit + feedback_stages_yaml_edit_direction

【环境快照】
- HEAD 5860135d（= origin/main · 树净 · 上会话 main 新增 5 commit 全 push — 2026-07-23 20:19 现跑实证）
- targeted 五域（asset/art_tone/webp/pubspec/avatar）30 pass/0 fail（EXIT=0）+ analyze 0（2026-07-23 上会话主 checkout 实测）；全量基线 4652/0（2026-07-23 Ch14 实装会话实测记录·其后三批均自包含按 §8.0 未跑全量）
- 主线 14 章 70 关（cap 33=绝顶·圆熟）美术全齐+全库 webp 化 · Ch15 spec 冻结零待决 · kimi 2026-07-26 10:10 前配额不可用（派单走 Claude/codex）

【下波候选】
| # | 任务 | 工具/模型 | 预估时长 | 备注 |
|---|------|----------|----------|------|
| 1 | Ch15「关山一程」实装批（推荐） | Claude coupled xhigh | ~3-4h | spec 冻结零待决项·整章一次做完（5 关+真解孤城闭+13 叙事+~26 reconcile+cap 33→35）·加章=跨切面批末全量必跑 |
| 2 | battle-ui-v2 阶段 5（Windows 缩放） | codex | 随批 | plan 2026-07-19 既定末段·与 1 无依赖可并行 |
| 3 | Ch14 叙事 lore 加厚（5102→~6300 字） | Claude | ~30min | 可选质量项非必需 |

【硬约束沿用】
- 红线：末 Boss **59500 < 60000** / 孤城闭 mult 4800 ≤ 8000 / 敌攻 ≤1850（参照 ≤2000）/ 三系锁死 / 在线=离线
- 破坏证红（mult 9000>8000 RED→还原绿）必须在 **commit 后**做；测试与 commit 用 && 不用 ;
- flutter test 禁裸接管道取结果：> file 2>&1; echo EXIT=$? 显式取码
- 合并纪律：draft PR 审 diff 后 --no-ff；numbers.yaml cap/GDD §8.1 改动已由 spec 拍板授权，按 spec 范围内改
- reconcile 勿漏：readable_tempo 终章门槛 14_05→15_05 / idle_horizon 测试名 stale（Lv106/余量715 字样）顺修 / skill 计数 253→254 三处+GDD 字串

【防幻觉守则】
- 本清单【环境快照】数字是 2026-07-23 上会话实测快照；新会话改动代码后必须重新实测，禁转抄。
- 报「完成/已修复/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line（spec 行号为 2026-07-23 实测，实装时重核防 drift）；不确定写「不知道」。
- 完整守则见 memory reference_anti_hallucination。

【先报告】
读完上述清单后：1. 报告 PROGRESS/session 记录/spec 关键信息 2. 确认环境状态（HEAD/树净/同步） 3. 不要直接动代码。
