# NEXT — 交接（2026-07-22 日批收账清账 · HEAD 21c75214）

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）· Zed1118/wuxia_idle · Mac 单端 · 1.0 长线打磨期

一句话背景：日批五 PR（#55-#59）收账清账完毕——全合 main 并 push，批末终验 4647/4647 · analyze 0 · format 0 changed；拍板 4 项已拍 3（①接受 ②schema ③确认）+ ④留议。新会话任务 = 下波候选派单。

## 开局动作
1. 读 PROGRESS.md 顶段（日批收账条：验证口径/拍板结果/挂账全在）
2. 读 BACKLOG.md §一 §二（待拍板 #8 rngProvider 留议；已解锁 5 项含 P1-5.2 schema 批/Ch13 美术/Ch14 spec/散功接契约）
3. `git pull --rebase --autostash`
4. 选读 memory：`feedback_wuxia_add_mainline_chapter_reconcile`（启动 Ch14 实装时）/ `reference_codex_image_gen_art_pipeline`（派 Ch13 美术时）

## 环境快照（2026-07-22 收账会话现跑实测）
- HEAD `21c75214`（= origin/main · 已 push · 树净度以现跑 `git status` 为准）
- 批末终验：build_runner 68 outputs · analyze 0 · format 1284 文件 0 changed · 全量 **4647 pass/0 fail**（EXIT=0）
- assets 93MB（webp 清账后）；PR #55/56/57/59 MERGED、#58 CLOSED（rebase 所致·已注明合并 commit `21462867`）
- worktree 0 · kimi 分支 0（本地+远端全清）

## 下波候选（按 BACKLOG §二）
| # | 任务 | 备注 |
|---|------|------|
| 1 | P1-5.2 战败持久化 schema 批（已拍定加字段） | [schema] 批·build_runner+全量·**推荐**——拍板项落地 |
| 2 | Ch13 美术 11 图 codex image_gen 派单 | known_missing +11 已登记·Ch13 美术闭环 |
| 3 | Ch14 spec 起草 | 承 Ch13 卷尾 hook·shi_dang 收编位 |
| 4 | 散功 dispel_service 接占用契约（+recall 假 recap） | #58 Gate 新发现·P2 批 |

## 硬约束沿用
- 合并纪律：draft PR 审 diff 后 `--no-ff`；内容/schema 批后主 checkout **必先 build_runner 再测**
- 红线：Boss hp<60000 / 装备攻击≤2000 / 招式 mult≤8000 / 三系锁死 / 在线=离线；显示级 Lv ≤106 + 结晶 <6 件已终拍
- 受保护文件（GDD/CLAUDE/numbers.yaml/data_schema/IDS_REGISTRY）改前需确认
- 已知 flaky：#55 分支曾现全量 1 例失败未捕获用例名（连跑全绿·同 PR body 记录），再现身必抓名字

## 先报告
读完上述清单后：1. 报告 PROGRESS/BACKLOG 关键信息 2. 确认环境状态（HEAD/树净/同步）3. 不要直接动代码。
