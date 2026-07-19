# NEXT — 新会话开局清单（首落盘 2026-07-19 20:35 · 21:35 三端调度会话刷新）

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

三端调度进行时。本会话职责=调度指挥+把关收账，代码执行下放（memory feedback_dispatch_first_orchestrator）。完整背景读 docs/sessions/2026-07-19_2013_三端调度.md。

## 开局动作
1. 读 PROGRESS.md 顶段 + docs/sessions/2026-07-19_2013_三端调度.md + 根目录 BACKLOG.md（任务储备总账）
2. git pull --rebase --autostash；核对本文件头部 HEAD 与 git 实况，漂移先报告
3. 选读 memory：reference_anti_hallucination + feedback_dispatch_first_orchestrator + reference_cli_dispatch_pipeline
4. 重挂 commit 侦听器（bg until 循环 60s 查两执行端分支 tip，变化退出推进度，30min 心跳）+ 出首个双端进度条

## 环境快照（2026-07-19 21:35 刷新）
- HEAD `392a1fb1`（BACKLOG 总账建账；其父 34af0748=NEXT 首落盘）；与 origin 同步
- 全量 4457/0（17 时合并态实测）/ analyze 0（20:14 现跑）；**任务储备已归一 → 根目录 `BACKLOG.md`**（待拍板/可派/锁死/方向级四段，收账随 PROGRESS 同步更新）
- **codex 在途**：`codex/battle-ui-v2-fidelity-85` @ `14bbd02e`——阶段 3 已终拍通过（1A），A 案+阶段 4 已 21:0x resume 下发，三切片已 commit（17cc9902 七签案台统一 / c440ae88 HUD 字体层级 / 14bbd02e 题字特效饱和度），剩 Gate 双视口证据+冻结，交付 tip=`[READY] 阶段4+A案交付`。resume：`cd 项目根 && codex exec resume -c sandbox_mode='"danger-full-access"' 019f7935-f1ed-7661-b461-15deaa7dd2fd "<指令>"`
- **kimi 在途**：`kimi/test-quality-20260719` @ `8b2d559f`——20:30 首发被杀后重发复活产 2 commits（Isar 原生库下载竞逐 flaky 根治+连带修复），20:47 单口令答完即退未打 READY，**21:35 已 `-c -p` 续跑核对补完中，勿再重发**（会双进程撞 worktree）
- A 案已下发销账；全部拍板队列统一见 `BACKLOG.md` §一
- 留置勿清：`build/visual_acceptance/battle_ui_v2_85_sample/` + `battle_ui_v2_85/stage3_gate/` 证据 + 两份 battle-ui 规划文档 untracked

## 下波候选
| # | 任务 | 预估 | 备注 |
|---|------|------|------|
| 1 | 收 codex [READY] 账（§8.2 Gate+视觉终判+合并，推荐） | 45-60min | 视觉主线收口；与 #2 合并期统排冲突拓扑 |
| 2 | 收 kimi [READY] 账（§8.2 Gate+合并） | 30min | 批末全量+5B push 与 #1 同批 |
| 3 | 4A dispersionInternalForcePenalty 字段清理 | 20-30min | BACKLOG §二 #1，Claude 域 |
| 4 | 下波方向拍板（Ch9 spec / 美术批 / 具名装备） | 讨论 | BACKLOG §一/§四 |

## 硬约束沿用
- 交付以 git tip 前缀为唯一真相源；验证数字独立复跑不采信自报；5B push 授权（全量绿+analyze 0）
- 每条消息末尾附双端进度条；执行端空闲主动提议派单；弹图用 open + osascript activate Preview
- 防幻觉：快照数字改动后必重测禁转抄；报完成前必贴验证输出；完整守则 memory reference_anti_hallucination

## 先报告
1. 报告双端在途状态与拍板队列 2. 确认环境（status -sb + worktree list + 两 tip）3. 重挂侦听器出进度条 4. 不动代码，等 [READY]/侦听器/用户指令。
