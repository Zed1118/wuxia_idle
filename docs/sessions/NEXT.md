# NEXT — 交接（2026-07-23 13:20 · Ch14 实装收账 · HEAD b624d449）

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）· Zed1118/wuxia_idle · Mac 单端 · 1.0 长线打磨期

一句话背景：Ch14「山外来客」整章实装已合 main（PR #64 MERGED·kimi 403 中断后 Claude 接手续做），主线 14 章 70 关、绝顶段 2/3；工作树净、与 origin 同步、worktree/分支全清。新会话任务 = 下波候选派单。

开局动作：
1. 读 PROGRESS.md 顶段（Ch14 实装收账条：执行历程/验证口径/已知风险全在）
2. 读 docs/sessions/2026-07-23_1320_Ch14实装.md（决策理由+踩坑）
3. `git pull --rebase --autostash`（核 HEAD b624d449 未漂移）
4. 选读 memory：reference_anti_hallucination（固定）+ feedback_multi_anchor_test_actual_attribution（实测型钉值回填必读）+ reference_codex_image_gen_art_pipeline（派美术批时）+ feedback_wuxia_add_mainline_chapter_reconcile（启动 Ch15 实装时）

【环境快照】
- HEAD `b624d449`（= origin/main · 树净 · 本会话 main 新增 8 commit 含 merge 带入，全 push — 2026-07-23 13:20 现跑 rev-parse）
- 主 checkout 实测（2026-07-23 本会话合并态）：analyze **0** · 全量 **4652 pass/0 fail**（EXIT=0 显式取码）
- 主线 14 章 70 关（cap 33 = 绝顶·圆熟）· PR #60-64 全 MERGED · known_missing 仅 Ch14 11 图（xiliang_* 5 敌+cover+5 背景）
- kimi 本计费周期配额尽（403），刷新前派单走 codex/Claude

【下波候选】（按 BACKLOG §二）
| # | 任务 | 工具/模型 | 预估时长 | 备注 |
|---|------|----------|----------|------|
| 1 | Ch14 美术 11 图 codex image_gen 专批（推荐） | codex 派单+Claude 终判 | ~1.5h | 视觉闭环快·无依赖·不受 kimi 配额影响·沿 Ch11-13 配方 |
| 2 | Ch15 spec 起草（绝顶段收官·cap 33→35 dengFeng 封顶） | Claude xhigh | ~1h | 承「下山西行赴更远的约」hook·末 Boss HP 头寸仅 ~59500 需精算 |
| 3 | battle-ui-v2 阶段 5（Windows 100%/125%/150% 缩放） | codex | 随批 | plan 2026-07-19 既定末段 |
| 4 | Ch14 叙事 lore 加厚（5102→~6300 字·可选） | Claude | ~30min | 质量项非必需 |

【硬约束沿用】
- 合并纪律：draft PR 审 diff 后 `--no-ff`；schema 批合并后主 checkout 必先 build_runner 再测（Ch14 批无 schema 故免）
- 红线：Boss hp<60000（**Ch15 末 Boss 头寸仅 ~59500·spec 阶段必精算**）/ 装备攻击≤2000 / mult≤8000 / 三系锁死 / 在线=离线
- flutter test 禁裸接管道取结果：`> file 2>&1; echo EXIT=$?` 显式取码（本会话管道吞码实锤）
- 受保护文件（GDD/CLAUDE/numbers.yaml/data_schema/IDS_REGISTRY）改前需 spec 拍板或 ask

【防幻觉守则】
- 本提示词【环境快照】数字是 2026-07-23 会话实测快照；新会话改动代码后必须重新实测，禁转抄。
- 报「完成/已修复/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line;不确定写「不知道」。
- 完整守则见 memory reference_anti_hallucination。

【先报告】
读完上述清单后：1. 报告 PROGRESS/session 记录关键信息 2. 确认环境状态（HEAD/树净/同步） 3. 不要直接动代码。
