# 新会话开工提示词（交接时间：2026-07-25 08:34 · HEAD 5dda32df）

> 本文件由 /handoff 覆盖式维护。新会话用户说「开工」= 读本文件按其执行；动手前先核头部 HEAD 与 git 实况，漂移先报告再动。

---

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

Ch16「凉州词」宗师段首章实装批全链闭环（PR #71 --no-ff MERGED·批 commit `5441ea3d` 经 merge `a5d6ddba` 进 main·handoff docs `5dda32df`）。
主线 16 章 80 关全交付，cap 38（zongShi cross-tier），宗师段 1/3 落地。主 checkout main@`5dda32df` = origin/main
树净、载体全清。新会话任务 = 下波候选择一开工。

开局动作：
1. 读 PROGRESS.md 顶段 2026-07-24 Ch16 条
2. 读 docs/sessions/2026-07-24_2220_Ch16凉州词实装.md（spec 证伪口径+相位配法+踩坑三条）
3. git pull --rebase --autostash
4. 选读 memory：reference_anti_hallucination（固定）+ 候选 1 加读
   reference_codex_image_gen_art_pipeline + feedback_visual_acceptance；候选 2 加读
   feedback_wuxia_add_mainline_chapter_reconcile + feedback_wuxia_release_cap_raise_reconcile
   （within-tier 38→40 判据）+ feedback_multi_anchor_test_actual_attribution

【环境快照】
- HEAD `5dda32df`（= origin/main · 树净 · 本会话 main +2 commits：merge `a5d6ddba` + docs `5dda32df`，
  批 commit `5441ea3d` 经 merge 进入 · 全 push — 2026-07-25 08:34 现跑实证）
- analyze 0（handoff 时主 checkout 现测）；全量 **4654/0** EXIT=0（2026-07-24 22:10 合并态实测·其后仅 docs 两文件）
- 主线 16 章 80 关·cap 38·首通 Lv97/全内容 Lv115（逐值实测）·Ch16 11 图缺走 errorBuilder
  （known_missing 已登记 liangzhou_* 5 敌+chapter_16_cover+narrative_16_01..05）·BACKLOG §二两项可派
- kimi 2026-07-26 10:10 前配额不可用（派单走 Claude/codex）
- **网络注意**：GitHub 直连 07-24 22:20 起间歇 reset；sing-box 已启动；push 失败时用
  `env https_proxy=http://127.0.0.1:2334 git push`（本会话实测通，hook 清代理后的备用通道）

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | Ch16 11 图 codex image_gen 专批（推荐） | codex+Claude 终判 | ~1h | 合并后美术批惯例·销已知风险①·沿 Ch11-15 配方（参考锚 sips 解码防 webp-in-png·脚底校准·Claude 视觉终判 11/11 逐图） |
| 2 | Ch17「沙海纵深」实装批 | Claude xhigh 专会话 | ~3.5-4h | spec §8 前瞻已定方向·章级细化随批终拍；灵巧主题·末 Boss 单窗口 0.20 机制教学·feng_juan 收编+夜雨残页·cap 38→40 within-tier |
| 3 | battle-ui-v2 阶段 5（Windows 缩放） | codex | 随批 | BACKLOG §二#1·证据留 repo 内非 gitignored |
| 4 | 中文门禁豁免口径拍板 | 用户拍板+Claude 轻批 | ~10min | BACKLOG §一#10 |

【硬约束沿用】
- Ch17 实装依据 = spec §8 前瞻；**「敌招 9 招新写」按 Ch16 证伪口径读**：tier6 敌招池 = skills.yaml
  失传神功心法招 9 门已存在（心法招无 tier 字段勿按 tier:6 grep 盘点），沿 Ch13-16 惯例复用零新增
- Ch17 末 Boss 相位直接沿 16_05 **unlockSkillIds 配法**（招同时在 skillIds 过红线①+相位 unlockSkillIds
  受击即推蓄力；AI 自选路径在高 cap nearMax 速度碾压下不可见，勿走回 15_05 纯 chargeSkillId 老配法）
- **idle_horizon s1 45.6 天/下沿 45 贴线，Ch17 扩缺口必破必重校**（三贴线 s3 45/s4 6/F 25 本批已重校）
- flutter test 禁裸接管道：`> file 2>&1; echo EXIT=$?` 显式取码；破坏证红在 commit 后做；
  计数断言 grep 双形态：`hasLength(N)` + `length, N`（本批 game_repository_test 裸值断言漏网实锤）
- 合并纪律：draft PR 审 diff 后 --no-ff；合并后主 checkout build_runner+analyze+全量复验
- 美术批合并后惯例跟进 webp 清账小批（Ch15 三批全链先例）

【防幻觉守则】
- 本提示词【环境快照】数字是 2026-07-25 08:34 交接实测快照；新会话改动后必重新实测，禁转抄。
- 报「完成/已修复/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」。
- 完整守则见 memory reference_anti_hallucination。

【先报告】
读完上述清单后：1. 报告 PROGRESS 顶段与 session 记录关键信息 2. 确认环境状态（HEAD/树净/同步）
3. 不要直接动代码。
