# NEXT — 交接（2026-07-22 晨批收账完毕 · 夜批 6 PR 全合 main · 合并批顶 c142d439 + 收尾 docs commit 已推 origin）

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）· Zed1118/wuxia_idle · Mac 单端 · 1.0 长线打磨期

一句话背景：夜批 6 draft PR（#49-#54）已全部 Gate 审+独立复查后 --no-ff 合 main 并复验推送；mount_deferred 已拍 **A2+B1**；**Ch13 spec §10 六项拍板菜单已出等用户回复**——用户回拍板即开 Ch13 实装批。

## 开局动作
1. 读 PROGRESS.md 顶段（07-22 收账条）
2. `git pull --rebase --autostash`（核 HEAD 与 origin 一致）
3. 若用户已回 Ch13 拍板 → 读 `docs/spec/2026-07-22-ch13-jueding-design.md` + `docs/audit/2026-07-22_mount_deferred_disposition_analysis.md` + memory `feedback_wuxia_add_mainline_chapter_reconcile`，升 xhigh 开实装批
4. 若未回 → 从下波候选表挑独立项

## 环境快照（2026-07-22 收账实测）
- main = origin/main · 树净 · 6 PR 全 MERGED · 4 worktree + 6 分支（双端）已清
- build_runner 68 outputs · analyze 0 · format 门禁 1287 文件 0 changed · 全量 `flutter test --no-pub` **4626/0**（基线 4618 + #53 新 8 用例）
- Ch12 美术闭环（11 图入库 · known_missing Ch12 段清零 · 派单书/报告留档 docs/handoff）；断魂庄断线续战 UI 已接线（P0 活锁销账）

## 下波候选
| # | 任务 | 档位 | 依赖 | 备注 |
|---|------|------|------|------|
| 1 | **Ch13「绝顶段首章」实装批**（含 cap cross-tier 全套 + A2+B1 挂载子集一并收） | xhigh | 等用户 §10 拍板 | spec+分析已合 main · **推荐** |
| 2 | Ch10-12 33 图 webp 转码批（~30MB 可省） | high | 无 | `tool/convert_assets_webp.py` 幂等复用 |
| 3 | flaky 根因（`apply_victory_resolution_test` 未固定 DefaultRng） | high | 无 | 两轮审查在案 |
| 4 | 07-21 审查 P1 清单（占用契约 5 消费者/远征三件套/saveDataId 混用等） | high | 无 | 桌面两份报告 |

## 拍定备忘（2026-07-22 用户拍板）
- **mount_deferred = A2+B1**：jin_gang/guan_shan 塔 15/20 残页 remount（塔残页空位实测 4 个：15/20/25/30，25/30 留给 jing_hong/ma_ta 类）+ shi_dang 收编绝顶段（Ch13 批先补标、Ch14/15 压场章挂载）+ yang_guan 补标 deferred 留宗师段 + fu_mai 只补注释 + feng_juan 待 Ch13 主题（§10 #6）定后再决；顺手修 `stages.yaml:1521` 腐注。
- 实装载体：并入 Ch13 实装批一次收挂载完备面（cap cross-tier 触发红线⑦，同批处理最省 churn）。

## 硬约束沿用
- 合并纪律：draft PR 审 diff 后 --no-ff；内容/schema 批后主 checkout 必先 build_runner 再测（.g.dart gitignored）
- 红线：Boss hp<60000 / 装备攻击≤2000 / 招式 mult≤8000 / 三系锁死 / 在线=离线；Ch13 真解必 tier5（jiangHuMiChuan 档）
- 受保护文件（GDD/CLAUDE/numbers.yaml/data_schema/IDS_REGISTRY）改前需确认
- Ch13 实装先全 Phase-0 grep 复定 spec 行号（spec 自注 2026-07-21/22 grep · 防 drift）

## 先报告
开工先：1. 核 HEAD/树/PR 态与本文件一致 2. 若用户已回拍板，先复述拍板结果再动 3. 实装批动手前出 §8.0 plan 文件。不要直接动代码。
