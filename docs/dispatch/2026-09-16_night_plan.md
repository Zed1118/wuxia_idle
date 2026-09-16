# 2026-09-16 夜批总计划（Codex 双单 · Claude 监督）

> 只记调度与状态，**不宣称任务完成**；交付状态最高事实源 = git（tip `[READY]`/`[BLOCKED]` + worktree 干净）。任何唤醒从本文件重建上下文。

## 授权与边界（用户 2026-09-16 23:4x 口头：「写一个今晚的挂机任务流给 codex 去跑，你监督，8 小时，我睡觉」）

- 时长 8h：2026-09-16 ~23:55 → 2026-09-17 ~07:55 CST；执行端 06:00 后不开新目标，06:00–07:55 留给复核/收尾。
- 任务范围：用户委托协调者选题；只选 🟢/🟡 级（行为保持的结构整改 + 只读审计），🔴 级（数值/闸门/塔层/schema/删配置/真档/main）一律不派。
- allow-merge = **no**（不合 main；链 `codex/p2-player-flow-20260910` 亦不在夜里合，READY 分支留给早报拍板）；allow-push = **no**（协调者仅可把执行端分支 push 到 origin 同名分支做备份，不推 main/链）。
- 沿用红线：不动主 checkout 4 个用户文件；不删 `review-followup-20260912`（locked）及在途 worktree；真实存档不碰；一律简体中文。

## 门禁记录（preflight 2026-09-16 23:52 dry-run = BLOCKED 4 项，协调者证伪后开工）

| 项 | 门禁值 | 实测证伪 | 处置 |
|---|---|---|---|
| wip_running / wip_ready | 43 / 59 | 107 本地分支里 71 条内容已在链上、28 条是台账 ③ 未合入 worktree、8 条无 worktree 历史分支；真实在跑 WIP = 0 | 不清分支凑门禁，列入早报菜单 |
| blocked_decisions | 4 个 `[BLOCKED]` 分支 + 池 P13 | 均为 08-26～28 文档类分支（台账 ③），已待用户拍板，与今晚任务无关 | 不动 |
| worktree_clean | 主 checkout、m4-54aed-worktree 脏 | 主 checkout = 4 个用户文件（设计如此）；后者是 Codex 09-13 证据目录（保留名单） | 今晚不碰两者 |

🟡 流程级代拍：在用户明确下令夜批的前提下带记录开工；早报可推翻。

## 派单

| 单 | 分支 / worktree | 派单包（冻结于协调者分支 commit，见 git） | 目标序列 | 日志 |
|---|---|---|---|---|
| A 代码 | `codex/night-a-structural-20260916` @ `~/Documents/Codex/2026-09-16/night-A/wt` | `docs/dispatch/2026-09-16_night_A_结构整改.md` | A-1 numbers_config fail-fast → A-2 结算迁 application → A-3 时钟/随机源收口 → A-4 reducer golden（弹性尾） | `~/Documents/Codex/2026-09-16/night-A/dispatch.log` |
| B 审计 | `codex/night-b-governance-20260916` @ `~/Documents/Codex/2026-09-16/night-B/wt` | `docs/dispatch/2026-09-16_night_B_治理审计.md` | B-1 登记簿 167 条三分类 → B-2 numbers.yaml 零引用 key → B-3 21 条文档分支价值评估 → B-4 M 门 blocker 漂移（弹性尾） | `~/Documents/Codex/2026-09-16/night-B/dispatch.log` |

基线 = 链 tip `c307b3ffcb155af58d4efb9179e36453297b1360`。A/B 文件域不相交（A：lib/test/docs/audit 两份残留表；B：docs/audit 三份新表 + tools/audit）。两单均 `caffeinate -i` 包裹、`-s workspace-write --add-dir <主仓>/.git`、network on。

## 巡检 SOP（cron 每 ~45 min 一次；撞配额则下个点自动重试）

1. `tail -5` 两份 dispatch.log；`git -C <wt> log -1 --format='%h %ci %s'` 看 tip 是否推进；`git -C <wt> status --short | wc -l`。
2. 15 min 内 log 零增长且 tip 不动 → 判挂死：查 `ps -p <pid>`；进程存活但无输出再等一轮；进程已退出且 tip 非 `[READY]/[BLOCKED]` → 按 `codex exec resume <session-id>` 续跑一次（session id 从 log 头部取），只续一次。
3. 首件抽检：A-1 首个 commit 落地即 `flutter analyze` + 新守卫测试单跑；B-1 首个 commit 抽 3 行证据复核。系统性跑偏 → SIGINT 停单、纠偏重派。
4. tip 出现 `[READY]`：跑 `~/.claude/skills/afk/scripts/gate.sh <wt> c307b3ff… <tip> --receipt <receipt路径>`（B 单加 `--skip-full`），结果写进本文件「进度」段；**不合并**。
5. 06:00 后：不再 resume；07:00 起写早报。

## 进度（协调者维护，逐条时间戳）

- 23:55 派单包落盘并 commit；建 worktree + 预热 A；发单。
