# NEXT — 新会话开局清单（交接 2026-07-19 20:35 · HEAD 见下）

项目：挂机武侠（/Users/a10506/Desktop/Projects/挂机武侠）

三端调度进行时。本会话职责=调度指挥+把关收账，代码执行下放（memory feedback_dispatch_first_orchestrator）。完整背景读 docs/sessions/2026-07-19_2013_三端调度.md。

## 开局动作
1. 读 PROGRESS.md 顶段 + docs/sessions/2026-07-19_2013_三端调度.md
2. git pull --rebase --autostash；核对本文件头部 HEAD 与 git 实况，漂移先报告
3. 选读 memory：reference_anti_hallucination + feedback_dispatch_first_orchestrator + reference_cli_dispatch_pipeline
4. 重挂 commit 侦听器（bg until 循环 60s 查两执行端分支 tip，变化退出推进度，30min 心跳）+ 出首个双端进度条

## 环境快照（2026-07-19 20:35 实测）
- HEAD `95d6d0b3` 后 +1 NEXT commit（写入本文件时现跑核对）；与 origin 同步
- 全量 4457/0（17 时合并态实测）/ analyze 0（20:14 现跑）
- **codex 在途**：`codex/battle-ui-v2-fidelity-85` @ `c6a9a95f [BLOCKED] 阶段3 人物融合对照待用户拍板`（B=22.5/25 D=12.5/15 全过线·对照图已弹用户待终拍）。resume：`cd 项目根 && codex exec resume -c sandbox_mode='"danger-full-access"' 019f7935-f1ed-7661-b461-15deaa7dd2fd "<指令>"`
- **拍板队列待传 codex**：A 案=自动观战案台统一七签骨架（压暗+当前签轮转亮起），终拍通过后随阶段 4（顶栏题签/血条字阶/初战题字压暗）一并下发
- **kimi 异常**：测试质量批 run 被 killed（20:30 前后，原因待用户确认），分支 `kimi/test-quality-20260719` 零 commit，worktree 已预热完好。重发单据：`docs/superpowers/plans/2026-07-19-kimi-test-quality-dispatch.md`（cd worktree && ~/.kimi-code/bin/kimi -p "$(cat 单据)"；或先试 `kimi -c` 续目录会话）
- 留置勿清：`build/visual_acceptance/battle_ui_v2_85_sample/`（阶段2/3 证据）+ 两份 battle-ui 规划文档 untracked

## 下波候选
| # | 任务 | 预估 | 备注 |
|---|------|------|------|
| 1 | 等用户终拍阶段 3 → resume codex 传 A 案+阶段 4（推荐） | 15min 调度 | 视觉主线，用户最关注 |
| 2 | kimi 测试质量批重发/续跑（问用户 kill 原因后） | 5min 调度 | 单据已归档，worktree 预热完好 |
| 3 | 4A dispersionInternalForcePenalty 字段清理 | 20-30min | Claude 域小活已解锁 |

## 硬约束沿用
- 交付以 git tip 前缀为唯一真相源；验证数字独立复跑不采信自报；5B push 授权（全量绿+analyze 0）
- 每条消息末尾附双端进度条；执行端空闲主动提议派单；弹图用 open + osascript activate Preview
- 防幻觉：快照数字改动后必重测禁转抄；报完成前必贴验证输出；完整守则 memory reference_anti_hallucination

## 先报告
1. 报告双端在途状态与拍板队列 2. 确认环境（status -sb + worktree list + 两 tip）3. 重挂侦听器出进度条 4. 不动代码，等终拍/侦听器/用户指令。
