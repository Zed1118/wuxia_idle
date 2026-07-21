# NEXT — 交接(2026-07-21 23:52 · Ch12 已合 main · HEAD 26c3578f)

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）· Zed1118/wuxia_idle · Mac 单端 · 1.0 长线打磨期

一句话背景：Ch12「名下之实」一流第三章已实装并合 main（一流三章 Ch10-12 收官）。**后续任务由 codex/kimi 等工具推进，Claude 留调度/Gate/红线把关。**

## 开局动作
1. 读 PROGRESS.md 顶段「2026-07-21 Ch12 实装」条
2. `git pull --rebase --autostash`（核 HEAD 26c3578f 未漂移）
3. 选读 memory：`reference_codex_image_gen_art_pipeline`（立绘）/ `reference_cli_dispatch_pipeline`（派单）/ `feedback_dispatch_first_orchestrator`（调度）/ `reference_anti_hallucination`

## 环境快照
- 主 checkout HEAD `26c3578f`（= origin/main · Ch12 已 push · 树净）
- analyze **0** · 全量 `flutter test --no-pub` **4618/0**（2026-07-21 合并后主 checkout 实测 · build_runner 68 outputs 无 schema 变更）
- Ch12 draft PR #48 已合 · worktree `ch12-impl` + 分支 `worktree-ch12-impl` 待清（本会话收尾会清）

## 下波候选（按依赖/工具排 · 标推荐）
| # | 任务 | 工具 | 时长 | 备注 |
|---|------|------|------|------|
| 1 | Ch12 11 立绘出图 + 接线（**推荐首发**） | codex image_gen | 随批 | 5 敌(撑篙翁/巷陌拳师/挑山客/守炉铁匠/无名客)+1 封面+5 剧情背景 · 脚底 fraction 校准 + 色键抠图 + 透明注册 · 清 `known_missing_assets` Ch12 段 11 行 · 沿 Ch10/11 配方 |
| 2 | Ch12 立绘接线守卫测复验 | kimi/opus high | ~15min | asset_audit+art_tone+webp+pubspec+character_avatar ~30 测 · **Claude 视觉 gate 逐图终判**（闸门保留） |
| 3 | 绝顶段 spec 起草 | opus xhigh | ~1-2h | 承止水印/铜符 motif（一流三章已收官）· 绝顶 = jueDing · cap 28→? · 复用 vs 新招需拍板 |
| 4 | mount_deferred 招最终处置 | opus（拍板） | — | `feng_juan` 真解 + `jin_gang/guan_shan` fragment · 收编绝顶段 / 专门 review / 否决 |

## 硬约束沿用
- 加章 reconcile 配方 memory `feedback_wuxia_add_mainline_chapter_reconcile`（Ch12 新增 4 漏站点待补入：progression_release_budget 第二 test 级联 / idle_horizon 缺口 / chapter_list widget viewport / game_repo skill breakdown 注释）。
- cap within-tier 抬见 `feedback_wuxia_release_cap_raise_reconcile`；**合并 schema/内容批后主 checkout 必先 build_runner 再测**。
- 立绘缺图走 `known_missing_assets` errorBuilder 兜底（tracked）；codex 出图配方 `reference_codex_image_gen_art_pipeline`。
- 红线：Boss hp<60000 / 装备攻击<2000 / 招式 mult≤8000 / 三系锁死 / 在线=离线；**显示级 Lv1-490 纯展示不触红线**（Ch12 全内容已 Lv103·用户拍板接受）。

## 先报告
读完清单后：1. 报告 PROGRESS + 环境实况（HEAD/树净/同步）2. 派 codex 立绘前先核 Ch10/11 立绘配方 + `known_missing_assets` Ch12 现状 3. 对齐方向后再动，勿直接改生产码。
