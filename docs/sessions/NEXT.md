# 新会话开工提示词（交接时间：2026-07-25 12:44 · HEAD 34fa6a2e）

> 本文件由 /handoff 覆盖式维护。新会话用户说「开工」= 读本文件按其执行；动手前先核头部 HEAD 与 git 实况，漂移先报告再动。

---

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

Ch16「凉州词」美术 11 图已出齐接线并合 main（PR #72 `27b6d96d`），收账已合（PR #73 `34fa6a2e`）；
known_missing **全表清零**。中文散写 CI 门禁已实装但**未合**（PR #74 `455c3066`·分支 `zh-literal-gate`·worktree 保留）。
主 checkout main@`34fa6a2e` = origin/main、树净。

开局动作：
1. 读 PROGRESS.md 顶段 2026-07-25 Ch16 美术条
2. 读 docs/sessions/2026-07-25_1244_Ch16美术与中文门禁.md
3. git pull --rebase --autostash
4. 选读 memory：reference_anti_hallucination（固定）+ 候选 1 加读
   feedback_wuxia_sweep_rare_bonus_flaky_drop_count + feedback_wuxia_rngprovider_vs_dartmath_random；
   候选 3 加读 reference_codex_image_gen_art_pipeline；候选 4 加读
   feedback_wuxia_add_mainline_chapter_reconcile + feedback_wuxia_release_cap_raise_reconcile

【环境快照】
- HEAD `34fa6a2e`（= origin/main·树净·本会话 main +2 merge：PR #72 + #73·全 push
  — 2026-07-25 12:44 现跑 `git rev-parse` 实证）
- 主 checkout 实测：analyze **0**；全量 **4654 pass / 0 fail**（EXIT=0·`-1` 0 处·不含未合的门禁批）
- 门禁批 `zh-literal-gate` 侧实测：全量 **4656/0**（+2 guard）、analyze 0、双 guard 破坏证红闭环
- 主线 16 章 80 关·cap 38·美术全补齐（known_missing 非注释行 0）
- **CI 有约 5-6.5% 概率无故变红**（稀有彩头，见硬约束），重跑即绿，别误判为回归
- kimi 2026-07-26 10:10 前配额不可用（派单走 Claude/codex）

【下波候选】

| # | 任务 | 模型 | 预估时长 | 备注 |
|---|------|------|----------|------|
| 1 | 修 CI 随机红根因（BACKLOG §一#8）（推荐） | opus high | ~40min | 面小价值高：每个 PR 都被 5-6.5% 概率浪费一次 22min CI；根因已定位到 `stage_entry_flow.dart:826`，两条修法已写进 BACKLOG |
| 2 | 合 PR #74 + 拍板 §一#12（第 4 集中 sink） | 用户拍板 + opus 轻批 | ~20min | 门禁已绿待审；拍完可顺手把 6 条格式化片段移出 allowlist |
| 3 | webp 清账小批（Ch16 11 图 17M） | opus high | ~30min | 沿 #63/#66/#70 先例，`convert_assets_webp.py` 幂等 |
| 4 | Ch17「沙海纵深」实装批 | opus **xhigh** 专会话 | ~3.5-4h | spec §8 前瞻已定向；idle_horizon s1 45.6/下沿 45 贴线必破须重校 |
| 5 | 中文散写存量 31 条清理（§二#3） | opus high | ~1-1.5h | 依赖候选 2 的拍板结果（E 类去向） |

【硬约束沿用】
- **CI 红先证伪再修**：`sweep_settlement_test` 的 `equipmentDrops` Expected 1 Actual 2 = 已知
  flaky（稀有彩头 5%+1.5% 额外发装备），重跑绿即可；别当回归改代码。
- flutter test 禁裸接管道：`> file 2>&1; echo EXIT=$?` 显式取码；**破坏证红在 commit 后做**。
- Edit dart 文件 commit 前必 `dart format`（CI format gate 先于测试）。
- 合并纪律：draft PR 审 diff 后 --no-ff；合并后主 checkout build_runner + analyze + 复验。
- 写 AST 工具前现查 analyzer 9.0.0 源码（`NamedType` 是 `Token name` 不是 `name2`）。

【防幻觉守则】
- 本提示词【环境快照】数字是 2026-07-25 12:44 主 checkout 实测快照；新会话改动后必重新实测，禁转抄。
- 报「完成/已修复/全绿」前必跑验证并贴输出，launch ≠ 成功。
- 引用代码现 grep/codegraph 查带 file:line；不确定写「不知道」。
- 完整守则见 memory `reference_anti_hallucination`。

【先报告】
读完上述清单后：1. 报告 PROGRESS 顶段与 session 记录关键信息 2. 确认环境状态（HEAD/树净/同步/PR #74 状态）
3. 不要直接动代码。
