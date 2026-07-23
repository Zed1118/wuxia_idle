项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

Ch14 美术 11 图接线已合 main（PR #65 MERGED·codex image_gen 专批零返修·known_missing 全表归零），主线 14 章 70 关美术全齐；HEAD 3b00e96c = origin/main、树净、worktree/分支全清。新会话任务 = 下波候选派单（推荐 Ch15 spec）。

开局动作：
1. 读 PROGRESS.md 顶段（Ch14 美术接线收账条）
2. 读 docs/sessions/2026-07-23_1636_Ch14美术接线.md
3. git pull --rebase --autostash
4. 选读 memory：reference_anti_hallucination（固定）+ feedback_spec_writing_checklist（Ch15 spec 前 reality check）+ feedback_wuxia_add_mainline_chapter_reconcile（Ch15 spec/实装站点清单）+ reference_codex_image_gen_art_pipeline（派美术批时·已含 sips 解码新步骤）

【环境快照】
- HEAD 3b00e96c（= origin/main · 树净 · 本会话 main 新增 4 commit 含 merge 带入，全 push — 2026-07-23 16:36 现跑实证；NEXT.md 自身 commit 后差一个属体例固有偏移，开局以 git 实况为准）
- 合并态 targeted（asset/art_tone/webp/pubspec/avatar 五域）30 pass/0 fail（EXIT=0）+ analyze 0（2026-07-23 本会话实测）；全量基线 4652/0（2026-07-23 上会话实测记录·本批自包含资产接线按 §8.0 未跑全量）
- 主线 14 章 70 关（cap 33 = 绝顶·圆熟）· known_missing 全表归零 · kimi 本计费周期配额尽（403）派单走 codex/Claude

【下波候选】
| # | 任务 | 工具/模型 | 预估时长 | 备注 |
|---|------|----------|----------|------|
| 1 | Ch15 spec 起草（推荐） | Claude xhigh | ~1h | 绝顶段收官·cap 33→35 dengFeng 封顶·末 Boss HP 头寸仅 ~59500 需精算·承「下山西行赴更远的约」+ yang_guan 阳关伏笔双 hook |
| 2 | battle-ui-v2 阶段 5（Windows 缩放） | codex | 随批 | plan 2026-07-19 既定末段 |
| 3 | webp 清账小批（11 图 18M→~9M） | Claude/codex | ~20min | 沿 #63 配方 q80 保 .png 名·顺清 build/dispatch/ch14_art_out+ref |
| 4 | Ch14 叙事 lore 加厚（5102→~6300 字） | Claude | ~30min | 可选质量项非必需 |

【硬约束沿用】
- 合并纪律：draft PR 审 diff 后 --no-ff；schema 批合并后主 checkout 必先 build_runner 再测
- 红线：Boss hp<60000（Ch15 末 Boss 头寸仅 ~59500·spec 阶段必精算）/ 装备攻击≤2000 / mult≤8000 / 三系锁死 / 在线=离线
- flutter test 禁裸接管道取结果：> file 2>&1; echo EXIT=$? 显式取码
- 受保护文件（GDD/CLAUDE/numbers.yaml/data_schema/IDS_REGISTRY）改前需 spec 拍板或 ask
- 参考锚喂 codex 前先 sips 解码真 PNG（库内图已 webp 化）

【防幻觉守则】
- 本提示词【环境快照】数字是 2026-07-23 会话实测快照；新会话改动代码后必须重新实测，禁转抄。
- 报「完成/已修复/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」。
- 完整守则见 memory reference_anti_hallucination。

【先报告】
读完上述清单后：1. 报告 PROGRESS/session 记录关键信息 2. 确认环境状态（HEAD/树净/同步） 3. 不要直接动代码。
