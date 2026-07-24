# NEXT — 新会话开局提示词(2026-07-24 18:51 交接·主 checkout HEAD 91d749bd)

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

三批全部闭环收账：Ch15「关山一程」整章实装(PR #67)+美术 11 图接线(PR #68)+真相源收口/死配置清理(PR #69·外审 07-24 triage 落地)全合 main。主线 15 章 75 关全交付、cap 35 绝顶段收束、GDD v1.24 当前状态块制上线。主 checkout main@`91d749bd` = origin/main 树净、载体全清。新会话任务 = 下波候选择一开工。

开局动作：
1. 读 PROGRESS.md 顶三段 2026-07-24 条
2. 读 docs/sessions/2026-07-24_1851_三批收账.md（决策理由+踩坑三条）
3. git pull --rebase --autostash
4. 选读 memory：reference_anti_hallucination（固定）+ feedback_wuxia_add_mainline_chapter_reconcile（含新站点「GDD 当前状态块」）+ 候选 1 加读 feedback_visual_check_real_target_bg（webp 批抽测配方在 #63/#66 PROGRESS 条）

【环境快照】
- HEAD `91d749bd`（= origin/main · 树净 · 本会话 main +10 commits 全 push — 2026-07-24 18:51 现跑实证）
- analyze 0（18:51 实测）；全量 **4654/0** EXIT=0（2026-07-24 合并态主 checkout 实测·其后仅 docs commit）
- 主线 15 章 75 关（内容+美术全交付）·cap 35·GDD v1.24 状态块制+truth_source_guard 守卫测
- Ch15 11 图真 PNG ~18.9M 待 webp；kimi 2026-07-26 10:10 前配额不可用（派单走 Claude/codex）

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | webp 清账小批：Ch15 11 图 18.9M 转码（推荐） | Claude opus high | ~15-20min | 沿 #63/#66 幂等脚本 `convert_assets_webp.py` q80 保 .png 名·抽测脚底 fraction 与 avatar 基线零差+四角 alpha·完整闭环 Ch15 |
| 2 | battle-ui-v2 阶段 5 重建（Windows 缩放） | codex | 随批 | BACKLOG §二#1·新载体·证据留 repo 内非 gitignored（外审教训） |
| 3 | 宗师段主线 spec（Ch16+） | Claude xhigh 专会话 | 专会话 | 先拍 BACKLOG §一#9 HP 头寸机制层方向·yang_guan/feng_juan 两 deferred 归此段 |
| 4 | 中文散写门禁豁免口径拍板 | 用户拍板+Claude 轻批 | ~10min | BACKLOG §一#10·拍定注释/StateError/debug fixture 豁免与否再实装 CI allowlist |

【硬约束沿用】
- webp 批口径：q80 保 .png 名幂等转码；抽测立绘脚底 fraction 与 `character_avatar.dart` 校准基线零差+四角 alpha 全 0（值变=转码破 alpha,回退）
- 加章/改 cap 必更 GDD 头部「当前状态块」——truth_source_guard_test 自动拦 cap/章关数,实测锚(Lv93/Lv112)手更
- flutter test 禁裸接管道：`> file 2>&1; echo EXIT=$?` 显式取码
- 合并纪律：draft PR 审 diff 后 --no-ff；合并后主 checkout analyze+targeted(资产批)/全量(跨切面批)复验
- idle_horizon s3 50.7/下沿 50、s4 7.0/下沿 7.0 双贴线——Ch16 扩章必破必重校

【防幻觉守则】
- 本提示词【环境快照】数字是 2026-07-24 18:51 交接实测快照；新会话改动后必重新实测，禁转抄。
- 报「完成/已修复/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」。
- 完整守则见 memory reference_anti_hallucination。

【先报告】
读完上述清单后：1. 报告 PROGRESS 顶三段与 session 记录关键信息 2. 确认环境状态（HEAD/树净/同步） 3. 不要直接动代码。
